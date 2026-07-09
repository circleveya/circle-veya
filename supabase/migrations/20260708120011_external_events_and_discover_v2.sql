-- ============================================================
-- Externe Events, Profil-Cover, Discover v2
-- ============================================================

ALTER TABLE public.activities
    ADD COLUMN IF NOT EXISTS source TEXT NOT NULL DEFAULT 'user'
        CHECK (source IN ('user', 'external'));

ALTER TABLE public.activities
    ADD COLUMN IF NOT EXISTS external_id TEXT;

ALTER TABLE public.activities
    ADD COLUMN IF NOT EXISTS external_provider TEXT;

ALTER TABLE public.activities
    ADD COLUMN IF NOT EXISTS external_url TEXT;

ALTER TABLE public.activities
    ADD COLUMN IF NOT EXISTS image_source TEXT
        CHECK (image_source IS NULL OR image_source IN (
            'user', 'pexels', 'unsplash', 'fallback', 'external'
        ));

CREATE UNIQUE INDEX IF NOT EXISTS activities_external_unique_idx
    ON public.activities (external_provider, external_id)
    WHERE source = 'external';

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS cover_url TEXT;

-- Externe Events für alle sichtbar (ohne Radius-Check)
CREATE OR REPLACE FUNCTION public.can_view_activity(
    p_activity_id UUID,
    p_viewer_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    v_activity public.activities%ROWTYPE;
    v_distance_km DOUBLE PRECISION;
BEGIN
    SELECT * INTO v_activity
    FROM public.activities
    WHERE id = p_activity_id;

    IF NOT FOUND THEN
        RETURN false;
    END IF;

    IF v_activity.host_id = p_viewer_id THEN
        RETURN true;
    END IF;

    IF v_activity.status = 'cancelled' THEN
        RETURN false;
    END IF;

    IF v_activity.source = 'external' AND v_activity.visible_to_strangers THEN
        RETURN true;
    END IF;

    IF v_activity.visible_to_friends
       AND public.is_friend(p_viewer_id, v_activity.host_id) THEN
        RETURN true;
    END IF;

    IF v_activity.visible_to_acquaintances
       AND public.is_acquaintance(p_viewer_id, v_activity.host_id) THEN
        RETURN true;
    END IF;

    IF v_activity.visible_to_strangers
       AND v_activity.location_geo IS NOT NULL THEN
        SELECT ST_Distance(
            v_activity.location_geo,
            p.location
        ) / 1000.0 INTO v_distance_km
        FROM public.profiles p
        WHERE p.id = p_viewer_id
          AND p.location IS NOT NULL;

        IF v_distance_km IS NOT NULL
           AND v_distance_km <= v_activity.discovery_radius_km THEN
            RETURN true;
        END IF;
    END IF;

    RETURN false;
END;
$$;

-- System-Host für externe Events (Profil manuell anlegen: username = circle_events)
CREATE OR REPLACE FUNCTION public.get_external_events_host_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT id
    FROM public.profiles
    WHERE username = 'circle_events'
    LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.get_external_events_host_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_external_events_host_id() TO service_role;

-- discover_activities v2: source, external_url, created_at
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
    image_url TEXT,
    source TEXT,
    external_url TEXT,
    created_at TIMESTAMPTZ
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
            WHEN a.source = 'external' THEN 'stranger'
            WHEN public.is_friend(v_viewer_id, a.host_id) THEN 'friend'
            WHEN public.is_acquaintance(v_viewer_id, a.host_id) THEN 'acquaintance'
            ELSE 'stranger'
        END AS visible_as,
        CASE
            WHEN a.source = 'external' THEN 'external_link'
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
        a.image_url,
        a.source,
        a.external_url,
        a.created_at
    FROM public.activities a
    JOIN public.profiles p ON p.id = a.host_id
    WHERE a.status IN ('open', 'full')
      AND (a.date_time IS NULL OR a.date_time > NOW())
      AND (a.host_id <> v_viewer_id OR a.source = 'external')
      AND public.can_view_activity(a.id, v_viewer_id)
      AND (p_location_type IS NULL OR a.location_type = p_location_type)
      AND (p_weather_condition IS NULL OR a.weather_condition = p_weather_condition)
    ORDER BY
        (a.is_sponsored AND p.user_type = 'company') DESC,
        (a.source = 'external') DESC,
        a.date_time ASC NULLS LAST;
END;
$$;

GRANT EXECUTE ON FUNCTION public.discover_activities(
    DOUBLE PRECISION,
    DOUBLE PRECISION,
    public.location_type,
    public.weather_condition
) TO authenticated;