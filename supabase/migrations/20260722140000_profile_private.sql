-- Privates Profil: Details nur für Owner, Freunde & Bekannte

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS profile_private BOOLEAN NOT NULL DEFAULT FALSE;

CREATE OR REPLACE FUNCTION public.can_view_full_profile(
    p_viewer_id UUID,
    p_profile_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_private BOOLEAN;
BEGIN
    IF p_profile_id IS NULL THEN
        RETURN FALSE;
    END IF;

    IF p_viewer_id IS NOT NULL AND p_viewer_id = p_profile_id THEN
        RETURN TRUE;
    END IF;

    SELECT profile_private INTO v_private
    FROM public.profiles
    WHERE id = p_profile_id;

    IF NOT COALESCE(v_private, FALSE) THEN
        RETURN TRUE;
    END IF;

    IF p_viewer_id IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN public.is_friend(p_viewer_id, p_profile_id)
        OR public.is_acquaintance(p_viewer_id, p_profile_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.update_my_profile_private(p_private BOOLEAN)
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

    UPDATE public.profiles
    SET profile_private = COALESCE(p_private, FALSE)
    WHERE id = v_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_my_profile_private(BOOLEAN) TO authenticated;

DROP FUNCTION IF EXISTS public.get_profile(uuid);

CREATE OR REPLACE FUNCTION public.get_profile(p_profile_id UUID)
RETURNS TABLE (
  id UUID,
  username TEXT,
  avatar_url TEXT,
  cover_url TEXT,
  bio TEXT,
  age SMALLINT,
  interests TEXT[],
  user_type public.user_type,
  is_premium BOOLEAN,
  is_founder BOOLEAN,
  gallery_public BOOLEAN,
  profile_private BOOLEAN,
  can_view_full_profile BOOLEAN,
  level INTEGER,
  followed_by_me BOOLEAN,
  follower_count INTEGER
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
#variable_conflict use_column
DECLARE
  v_me UUID := auth.uid();
  v_can_view BOOLEAN;
BEGIN
  v_can_view := public.can_view_full_profile(v_me, p_profile_id);

  RETURN QUERY
  SELECT
    p.id,
    p.username,
    p.avatar_url,
    p.cover_url,
    CASE WHEN v_can_view THEN p.bio ELSE NULL END AS bio,
    CASE WHEN v_can_view THEN p.age ELSE NULL END AS age,
    CASE
      WHEN v_can_view THEN p.interests
      ELSE ARRAY[]::TEXT[]
    END AS interests,
    p.user_type,
    p.is_premium,
    p.is_founder,
    p.gallery_public,
    p.profile_private,
    v_can_view AS can_view_full_profile,
    CASE
      WHEN v_can_view AND NOT public.is_business_profile_type(p.user_type)
      THEN COALESCE(us.level, 1)::INTEGER
      ELSE NULL
    END AS level,
    EXISTS (
      SELECT 1
      FROM public.company_follows f
      WHERE f.follower_id = v_me AND f.company_id = p.id
    ) AS followed_by_me,
    (
      SELECT COUNT(*)::INTEGER
      FROM public.company_follows f
      WHERE f.company_id = p.id
    ) AS follower_count
  FROM public.profiles p
  LEFT JOIN public.user_stats us ON us.profile_id = p.id
  WHERE p.id = p_profile_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_profile(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_user_rating(p_profile_id UUID)
RETURNS TABLE (avg_rating DOUBLE PRECISION, review_count INT)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.can_view_full_profile(auth.uid(), p_profile_id) THEN
    RETURN QUERY SELECT 0::DOUBLE PRECISION, 0::INT;
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    COALESCE(AVG(r.rating)::DOUBLE PRECISION, 0),
    COUNT(*)::INT
  FROM public.reviews r
  WHERE r.target_user_id = p_profile_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_profile_reviews(p_profile_id UUID)
RETURNS TABLE (
  id UUID,
  target_user_id UUID,
  reviewer_id UUID,
  reviewer_username TEXT,
  reviewer_avatar_url TEXT,
  rating INT,
  comment TEXT,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.can_view_full_profile(auth.uid(), p_profile_id) THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    r.id,
    r.target_user_id,
    r.reviewer_id,
    p.username AS reviewer_username,
    p.avatar_url AS reviewer_avatar_url,
    r.rating,
    r.comment,
    r.created_at
  FROM public.reviews r
  JOIN public.profiles p ON p.id = r.reviewer_id
  WHERE r.target_user_id = p_profile_id
  ORDER BY r.created_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_profile_reviews(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_profile_host_activities(p_host_id UUID)
RETURNS TABLE (
    id UUID,
    host_id UUID,
    title TEXT,
    description TEXT,
    max_participants INT,
    current_participants INT,
    date_time TIMESTAMPTZ,
    location_type public.location_type,
    weather_condition public.weather_condition,
    location_name TEXT,
    is_sponsored BOOLEAN,
    status public.activity_status,
    source TEXT,
    external_url TEXT,
    source_event_id TEXT,
    source_event_title TEXT,
    image_url TEXT,
    created_at TIMESTAMPTZ,
    host_username TEXT,
    host_user_type public.user_type,
    host_avatar_url TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    v_viewer_id UUID := auth.uid();
BEGIN
    IF v_viewer_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    IF NOT public.can_view_full_profile(v_viewer_id, p_host_id) THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        a.id,
        a.host_id,
        a.title,
        a.description,
        a.max_participants,
        a.current_participants,
        a.date_time,
        a.location_type,
        a.weather_condition,
        a.location_name,
        a.is_sponsored,
        a.status,
        a.source,
        a.external_url,
        a.source_event_id,
        a.source_event_title,
        a.image_url,
        a.created_at,
        p.username AS host_username,
        p.user_type AS host_user_type,
        p.avatar_url AS host_avatar_url
    FROM public.activities a
    JOIN public.profiles p ON p.id = a.host_id
    WHERE a.host_id = p_host_id
      AND a.status <> 'cancelled'
      AND public.can_view_activity(a.id, v_viewer_id)
    ORDER BY a.date_time DESC NULLS LAST, a.created_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_profile_host_activities(UUID) TO authenticated;

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

  IF NOT public.can_view_full_profile(v_viewer_id, p_profile_id) THEN
    RETURN;
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
