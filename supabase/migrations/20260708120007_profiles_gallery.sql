-- =============================================================================
-- Migration 00007: profiles_gallery
-- Zweck: Profil-Interessen und Post-Event-Galerie (Storage-Pfade).
-- Betrifft: profiles.interests, activity_photos
-- =============================================================================
ALTER TABLE public.profiles
    ADD COLUMN interests TEXT[] NOT NULL DEFAULT '{}';

-- ============================================================
-- activity_photos – Event-Galerie (kein Social-Feed)
-- ============================================================

CREATE TABLE public.activity_photos (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id     UUID NOT NULL REFERENCES public.activities (id) ON DELETE CASCADE,
    uploader_id     UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    storage_path    TEXT NOT NULL,
    public_url      TEXT NOT NULL,
    caption         TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX activity_photos_activity_id_idx ON public.activity_photos (activity_id);
CREATE INDEX activity_photos_uploader_id_idx ON public.activity_photos (uploader_id);

-- ============================================================
-- Hilfsfunktionen: Event vorbei & Upload-Berechtigung
-- ============================================================

CREATE OR REPLACE FUNCTION public.activity_is_past(p_activity_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.activities a
        WHERE a.id = p_activity_id
          AND a.date_time < NOW()
          AND a.status <> 'cancelled'
    );
$$;

CREATE OR REPLACE FUNCTION public.can_upload_activity_photo(p_activity_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT
        auth.uid() IS NOT NULL
        AND public.activity_is_past(p_activity_id)
        AND public.is_activity_participant(p_activity_id, auth.uid());
$$;

-- ============================================================
-- RPC: get_profile
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_profile(p_profile_id UUID)
RETURNS TABLE (
    id UUID,
    username TEXT,
    avatar_url TEXT,
    bio TEXT,
    age SMALLINT,
    interests TEXT[],
    user_type public.user_type
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.username,
        p.avatar_url,
        p.bio,
        p.age,
        p.interests,
        p.user_type
    FROM public.profiles p
    WHERE p.id = p_profile_id;
END;
$$;

-- ============================================================
-- RPC: get_past_activities_for_gallery
-- ============================================================

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
            FROM public.activity_photos ap
            WHERE ap.activity_id = a.id
        ) AS photo_count,
        public.can_upload_activity_photo(a.id) AS can_upload
    FROM public.activities a
    JOIN public.activity_participants ap ON ap.activity_id = a.id
    WHERE ap.profile_id = v_user_id
      AND a.date_time < NOW()
      AND a.status <> 'cancelled'
    ORDER BY a.date_time DESC;
END;
$$;

-- ============================================================
-- RPC: get_activity_photos
-- ============================================================

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
BEGIN
    IF NOT public.can_view_activity(p_activity_id, auth.uid())
       AND NOT public.is_activity_participant(p_activity_id, auth.uid()) THEN
        RAISE EXCEPTION 'Keine Berechtigung für diese Galerie';
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
    ORDER BY ph.created_at ASC;
END;
$$;

-- ============================================================
-- RPC: register_activity_photo
-- ============================================================

CREATE OR REPLACE FUNCTION public.register_activity_photo(
    p_activity_id UUID,
    p_storage_path TEXT,
    p_public_url TEXT,
    p_caption TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_photo_id UUID;
BEGIN
    IF NOT public.can_upload_activity_photo(p_activity_id) THEN
        RAISE EXCEPTION 'Upload nur für Teilnehmer vergangener Events möglich';
    END IF;

    INSERT INTO public.activity_photos (
        activity_id,
        uploader_id,
        storage_path,
        public_url,
        caption
    )
    VALUES (
        p_activity_id,
        auth.uid(),
        p_storage_path,
        p_public_url,
        p_caption
    )
    RETURNING id INTO v_photo_id;

    RETURN v_photo_id;
END;
$$;

-- ============================================================
-- Row Level Security
-- ============================================================

ALTER TABLE public.activity_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Galerie lesen bei sichtbarer oder eigener Teilnahme"
    ON public.activity_photos
    FOR SELECT
    TO authenticated
    USING (
        public.can_view_activity(activity_id, auth.uid())
        OR public.is_activity_participant(activity_id, auth.uid())
    );

-- Schreiben nur über register_activity_photo RPC
REVOKE INSERT, UPDATE, DELETE ON public.activity_photos FROM authenticated;

-- ============================================================
-- Supabase Storage Buckets
-- ============================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
    ('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
    ('activity-photos', 'activity-photos', true, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Avatare öffentlich lesbar"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'avatars');

CREATE POLICY "User lädt eigenen Avatar hoch"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'avatars'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "User aktualisiert eigenen Avatar"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'avatars'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "Aktivitätsfotos öffentlich lesbar"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'activity-photos');

CREATE POLICY "Teilnehmer laden Aktivitätsfotos hoch"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'activity-photos'
        AND (storage.foldername(name))[1] ~ '^[0-9a-f-]{36}$'
    );

GRANT EXECUTE ON FUNCTION public.get_profile TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_past_activities_for_gallery TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_activity_photos TO authenticated;
GRANT EXECUTE ON FUNCTION public.register_activity_photo TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_upload_activity_photo TO authenticated;
