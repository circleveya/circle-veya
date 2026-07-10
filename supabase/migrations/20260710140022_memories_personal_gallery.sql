-- =============================================================================
-- Migration 00022: memories_personal_gallery
-- Zweck: Erinnerungen = nur abgeschlossene eigene Aktivitäten, nur eigene Fotos.
-- Betrifft: get_past_activities_for_gallery, get_activity_photos, RLS
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_past_activities_for_gallery()
RETURNS TABLE (
    id UUID,
    title TEXT,
    date_time TIMESTAMPTZ,
    location_name TEXT,
    is_host BOOLEAN,
    photo_count BIGINT,
    can_upload BOOLEAN
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
        public.can_upload_activity_photo(a.id) AS can_upload
    FROM public.activities a
    JOIN public.activity_participants ap
      ON ap.activity_id = a.id
     AND ap.profile_id = v_user_id
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

CREATE OR REPLACE FUNCTION public.get_activity_photos(p_activity_id UUID)
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
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    IF NOT (
        public.is_activity_participant(p_activity_id, v_user_id)
        AND public.activity_is_past(p_activity_id)
    ) THEN
        RAISE EXCEPTION 'Keine Berechtigung für diese Erinnerung';
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
      AND ph.uploader_id = v_user_id
    ORDER BY ph.created_at DESC;
END;
$$;

DROP POLICY IF EXISTS "Galerie lesen bei sichtbarer oder eigener Teilnahme" ON public.activity_photos;

CREATE POLICY "Eigene Erinnerungsfotos lesen"
    ON public.activity_photos
    FOR SELECT
    TO authenticated
    USING (uploader_id = auth.uid());
