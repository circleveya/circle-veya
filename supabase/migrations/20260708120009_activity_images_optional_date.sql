-- ============================================================
-- Optionales Datum, Aktivitätsbild, Discover-Fix
-- ============================================================

ALTER TABLE public.activities
    ADD COLUMN IF NOT EXISTS image_url TEXT;

ALTER TABLE public.activities
    ALTER COLUMN date_time DROP NOT NULL;

-- Storage: Aktivitäts-Titelbilder
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'activity-images',
    'activity-images',
    true,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Aktivitätsbilder öffentlich lesbar" ON storage.objects;
CREATE POLICY "Aktivitätsbilder öffentlich lesbar"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'activity-images');

DROP POLICY IF EXISTS "User lädt Aktivitätsbild hoch" ON storage.objects;
CREATE POLICY "User lädt Aktivitätsbild hoch"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'activity-images'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

DROP POLICY IF EXISTS "User aktualisiert Aktivitätsbild" ON storage.objects;
CREATE POLICY "User aktualisiert Aktivitätsbild"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'activity-images'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- discover_activities: flexibles Datum + Bild-URL
-- Rückgabetyp ändert sich (image_url) → alte Signatur zuerst droppen
DROP FUNCTION IF EXISTS public.discover_activities(
    DOUBLE PRECISION,
    DOUBLE PRECISION,
    public.location_type,
    public.weather_condition
);

CREATE OR REPLACE FUNCTION public.discover_activities(
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_location_type public.location_type DEFAULT NULL,
    p_weather_condition public.weather_condition DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    host_id UUID,
    host_username TEXT,
    host_is_company BOOLEAN,
    title TEXT,
    description TEXT,
    max_participants INT,
    current_participants INT,
    date_time TIMESTAMPTZ,
    location_type public.location_type,
    weather_condition public.weather_condition,
    location_name TEXT,
    distance_km DOUBLE PRECISION,
    visible_as TEXT,
    viewer_action TEXT,
    is_sponsored BOOLEAN,
    is_featured BOOLEAN,
    image_url TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    v_viewer_id UUID := auth.uid();
    v_viewer_point GEOGRAPHY;
BEGIN
    IF v_viewer_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    v_viewer_point := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::GEOGRAPHY;

    UPDATE public.profiles
    SET location = v_viewer_point,
        updated_at = NOW()
    WHERE id = v_viewer_id;

    RETURN QUERY
    SELECT
        a.id,
        a.host_id,
        p.username AS host_username,
        (p.user_type = 'company') AS host_is_company,
        a.title,
        a.description,
        a.max_participants,
        a.current_participants,
        a.date_time,
        a.location_type,
        a.weather_condition,
        a.location_name,
        CASE
            WHEN a.location_geo IS NOT NULL THEN
                ST_Distance(a.location_geo, v_viewer_point) / 1000.0
            ELSE NULL
        END AS distance_km,
        CASE
            WHEN public.is_friend(v_viewer_id, a.host_id) THEN 'friend'
            WHEN public.is_acquaintance(v_viewer_id, a.host_id) THEN 'acquaintance'
            ELSE 'stranger'
        END AS visible_as,
        CASE
            WHEN a.host_id = v_viewer_id THEN 'host'
            WHEN public.is_activity_participant(a.id, v_viewer_id) THEN 'joined'
            WHEN public.has_pending_interest(a.id, v_viewer_id) THEN 'interest_pending'
            WHEN a.status = 'full' OR public.activity_is_full(a.id) THEN 'full'
            WHEN public.is_friend(v_viewer_id, a.host_id)
                 AND a.visible_to_friends THEN 'direct_join'
            WHEN public.is_acquaintance(v_viewer_id, a.host_id)
                 AND a.visible_to_acquaintances THEN 'interest'
            WHEN a.visible_to_strangers
                 AND a.location_geo IS NOT NULL
                 AND ST_DWithin(
                     a.location_geo,
                     v_viewer_point,
                     a.discovery_radius_km * 1000
                 )
                 AND NOT public.is_friend(v_viewer_id, a.host_id)
                 AND NOT public.is_acquaintance(v_viewer_id, a.host_id) THEN 'interest'
            ELSE 'none'
        END AS viewer_action,
        a.is_sponsored,
        (a.is_sponsored AND p.user_type = 'company') AS is_featured,
        a.image_url
    FROM public.activities a
    JOIN public.profiles p ON p.id = a.host_id
    WHERE a.status IN ('open', 'full')
      AND (a.date_time IS NULL OR a.date_time > NOW())
      AND a.host_id <> v_viewer_id
      AND public.can_view_activity(a.id, v_viewer_id)
      AND (p_location_type IS NULL OR a.location_type = p_location_type)
      AND (p_weather_condition IS NULL OR a.weather_condition = p_weather_condition)
    ORDER BY
        (a.is_sponsored AND p.user_type = 'company') DESC,
        a.date_time ASC NULLS LAST;
END;
$$;

-- Teilnehmerzähler nach Join korrigieren (Sync mit Tabelle)
CREATE OR REPLACE FUNCTION public.join_activity_direct(p_activity_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_viewer_id UUID := auth.uid();
    v_host_id UUID;
    v_visible_to_friends BOOLEAN;
    v_new_count INT;
BEGIN
    IF v_viewer_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    SELECT host_id, visible_to_friends
    INTO v_host_id, v_visible_to_friends
    FROM public.activities
    WHERE id = p_activity_id
      AND status IN ('open', 'full');

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Aktivität nicht gefunden oder nicht offen';
    END IF;

    IF NOT v_visible_to_friends THEN
        RAISE EXCEPTION 'Direktzusage für Freunde nicht aktiviert';
    END IF;

    IF NOT public.is_friend(v_viewer_id, v_host_id) THEN
        RAISE EXCEPTION 'Nur Freunde können direkt zusagen';
    END IF;

    IF public.is_activity_participant(p_activity_id, v_viewer_id) THEN
        RAISE EXCEPTION 'Bereits Teilnehmer';
    END IF;

    IF public.activity_is_full(p_activity_id) THEN
        RAISE EXCEPTION 'Aktivität ist voll';
    END IF;

    INSERT INTO public.activity_participants (activity_id, profile_id, joined_via)
    VALUES (p_activity_id, v_viewer_id, 'direct');

    SELECT COUNT(*)::INT INTO v_new_count
    FROM public.activity_participants
    WHERE activity_id = p_activity_id;

    UPDATE public.activities
    SET current_participants = v_new_count,
        status = CASE
            WHEN max_participants IS NOT NULL AND v_new_count >= max_participants
                THEN 'full'::public.activity_status
            ELSE 'open'::public.activity_status
        END
    WHERE id = p_activity_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.discover_activities(
    DOUBLE PRECISION,
    DOUBLE PRECISION,
    public.location_type,
    public.weather_condition
) TO authenticated;
