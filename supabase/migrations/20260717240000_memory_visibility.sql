-- Per-memory gallery visibility + fix public gallery filtering

CREATE TABLE IF NOT EXISTS public.gallery_memory_settings (
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  activity_id UUID NOT NULL REFERENCES public.activities(id) ON DELETE CASCADE,
  is_public BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (profile_id, activity_id)
);

ALTER TABLE public.gallery_memory_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Eigene Memory-Settings lesen" ON public.gallery_memory_settings;
CREATE POLICY "Eigene Memory-Settings lesen"
  ON public.gallery_memory_settings
  FOR SELECT
  TO authenticated
  USING (profile_id = auth.uid());

DROP POLICY IF EXISTS "Eigene Memory-Settings schreiben" ON public.gallery_memory_settings;
CREATE POLICY "Eigene Memory-Settings schreiben"
  ON public.gallery_memory_settings
  FOR ALL
  TO authenticated
  USING (profile_id = auth.uid())
  WITH CHECK (profile_id = auth.uid());

CREATE OR REPLACE FUNCTION public.set_my_memory_public(
  p_activity_id UUID,
  p_public BOOLEAN
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  IF NOT public.is_activity_participant(p_activity_id, v_user_id) THEN
    RAISE EXCEPTION 'Keine Berechtigung für diese Erinnerung';
  END IF;

  INSERT INTO public.gallery_memory_settings (profile_id, activity_id, is_public, updated_at)
  VALUES (v_user_id, p_activity_id, COALESCE(p_public, FALSE), NOW())
  ON CONFLICT (profile_id, activity_id)
  DO UPDATE SET
    is_public = EXCLUDED.is_public,
    updated_at = NOW();
END;
$$;

GRANT EXECUTE ON FUNCTION public.set_my_memory_public(UUID, BOOLEAN) TO authenticated;

DROP FUNCTION IF EXISTS public.get_past_activities_for_gallery();

CREATE OR REPLACE FUNCTION public.get_past_activities_for_gallery()
RETURNS TABLE (
  id UUID,
  title TEXT,
  date_time TIMESTAMPTZ,
  location_name TEXT,
  is_host BOOLEAN,
  photo_count BIGINT,
  can_upload BOOLEAN,
  is_public BOOLEAN
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  RETURN QUERY
  SELECT
    a.id,
    a.title,
    a.date_time,
    a.location_name,
    (a.host_id = v_user_id) AS is_host,
    (
      SELECT COUNT(*)
      FROM public.activity_photos ph
      WHERE ph.activity_id = a.id
        AND ph.uploader_id = v_user_id
    ) AS photo_count,
    public.can_upload_activity_photo(a.id) AS can_upload,
    COALESCE(gms.is_public, FALSE) AS is_public
  FROM public.activities a
  JOIN public.activity_participants ap
    ON ap.activity_id = a.id
   AND ap.profile_id = v_user_id
  LEFT JOIN public.gallery_memory_settings gms
    ON gms.activity_id = a.id
   AND gms.profile_id = v_user_id
  WHERE a.date_time IS NOT NULL
    AND a.date_time < NOW()
    AND a.status <> 'cancelled'
    AND COALESCE(a.source, 'user') <> 'external'
    AND (
      a.host_id = v_user_id
      OR ap.joined_via IN ('direct', 'interest_accepted', 'host')
    )
  ORDER BY a.date_time DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_past_activities_for_gallery() TO authenticated;

DROP FUNCTION IF EXISTS public.get_public_gallery_for_profile(UUID);

CREATE OR REPLACE FUNCTION public.get_public_gallery_for_profile(p_profile_id UUID)
RETURNS TABLE (
  id UUID,
  title TEXT,
  date_time TIMESTAMPTZ,
  location_name TEXT,
  is_host BOOLEAN,
  photo_count BIGINT,
  can_upload BOOLEAN,
  is_public BOOLEAN
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_viewer_id UUID := auth.uid();
  v_public BOOLEAN;
BEGIN
  IF v_viewer_id IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  SELECT gallery_public INTO v_public
  FROM public.profiles
  WHERE profiles.id = p_profile_id;

  IF v_public IS NOT TRUE THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    a.id,
    a.title,
    a.date_time,
    a.location_name,
    (a.host_id = p_profile_id) AS is_host,
    (
      SELECT COUNT(*)
      FROM public.activity_photos ph
      WHERE ph.activity_id = a.id
        AND ph.uploader_id = p_profile_id
    ) AS photo_count,
    FALSE AS can_upload,
    TRUE AS is_public
  FROM public.activities a
  JOIN public.activity_participants ap
    ON ap.activity_id = a.id
   AND ap.profile_id = p_profile_id
  JOIN public.gallery_memory_settings gms
    ON gms.activity_id = a.id
   AND gms.profile_id = p_profile_id
   AND gms.is_public = TRUE
  WHERE a.date_time IS NOT NULL
    AND a.date_time < NOW()
    AND a.status <> 'cancelled'
    AND COALESCE(a.source, 'user') <> 'external'
    AND (
      a.host_id = p_profile_id
      OR ap.joined_via IN ('direct', 'interest_accepted', 'host')
    )
    AND EXISTS (
      SELECT 1 FROM public.activity_photos ph
      WHERE ph.activity_id = a.id AND ph.uploader_id = p_profile_id
    )
  ORDER BY a.date_time DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_public_gallery_for_profile(UUID) TO authenticated;

-- Photos: eigene Erinnerung ODER öffentliche Erinnerung eines anderen Profils
CREATE OR REPLACE FUNCTION public.get_activity_photos(
  p_activity_id UUID,
  p_owner_id UUID DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  uploader_id UUID,
  uploader_username TEXT,
  public_url TEXT,
  caption TEXT,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_owner_id UUID;
  v_gallery_public BOOLEAN;
  v_memory_public BOOLEAN;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  v_owner_id := COALESCE(p_owner_id, v_user_id);

  IF v_owner_id = v_user_id THEN
    IF NOT (
      public.is_activity_participant(p_activity_id, v_user_id)
      AND public.activity_is_past(p_activity_id)
    ) THEN
      RAISE EXCEPTION 'Keine Berechtigung für diese Erinnerung';
    END IF;
  ELSE
    SELECT gallery_public INTO v_gallery_public
    FROM public.profiles
    WHERE profiles.id = v_owner_id;

    SELECT COALESCE(gms.is_public, FALSE) INTO v_memory_public
    FROM public.gallery_memory_settings gms
    WHERE gms.profile_id = v_owner_id
      AND gms.activity_id = p_activity_id;

    IF v_gallery_public IS NOT TRUE OR v_memory_public IS NOT TRUE THEN
      RAISE EXCEPTION 'Diese Erinnerung ist privat';
    END IF;
  END IF;

  RETURN QUERY
  SELECT
    ph.id,
    ph.uploader_id,
    p.username AS uploader_username,
    ph.public_url,
    ph.caption,
    ph.created_at
  FROM public.activity_photos ph
  JOIN public.profiles p ON p.id = ph.uploader_id
  WHERE ph.activity_id = p_activity_id
    AND ph.uploader_id = v_owner_id
  ORDER BY ph.created_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_activity_photos(UUID, UUID) TO authenticated;
