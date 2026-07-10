-- =============================================================================
-- Migration 00006: b2b_partner_filters
-- Zweck: B2B-Partner-Flags und Filter (Ort/Wetter) fuer Discover.
-- Betrifft: ENUM location_type/weather_condition, activities, discover_activities
-- =============================================================================
CREATE TYPE public.location_type AS ENUM ('indoor', 'outdoor');
CREATE TYPE public.weather_condition AS ENUM ('cold', 'rain', 'sun');

-- Alte RPC entfernen (verwendet noch weather_category)
DROP FUNCTION IF EXISTS public.discover_activities(DOUBLE PRECISION, DOUBLE PRECISION);

ALTER TABLE public.activities
    ADD COLUMN location_type public.location_type NOT NULL DEFAULT 'outdoor',
    ADD COLUMN weather_condition public.weather_condition NOT NULL DEFAULT 'sun',
    ADD COLUMN is_sponsored BOOLEAN NOT NULL DEFAULT false;

-- Bestehende weather_category → neue Spalten migrieren
UPDATE public.activities
SET
    location_type = CASE weather_category::text
        WHEN 'indoor' THEN 'indoor'::public.location_type
        ELSE 'outdoor'::public.location_type
    END,
    weather_condition = CASE weather_category::text
        WHEN 'rain' THEN 'rain'::public.weather_condition
        WHEN 'indoor' THEN 'sun'::public.weather_condition
        ELSE 'sun'::public.weather_condition
    END;

ALTER TABLE public.activities DROP COLUMN weather_category;
DROP TYPE public.weather_category;

CREATE INDEX activities_location_type_idx ON public.activities (location_type);
CREATE INDEX activities_weather_condition_idx ON public.activities (weather_condition);
CREATE INDEX activities_is_sponsored_idx ON public.activities (is_sponsored)
    WHERE is_sponsored = true;

-- Nur Community Partner (user_type = company) dürfen sponsern
CREATE OR REPLACE FUNCTION public.enforce_sponsored_only_for_company()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.is_sponsored THEN
        IF NOT EXISTS (
            SELECT 1
            FROM public.profiles p
            WHERE p.id = NEW.host_id
              AND p.user_type = 'company'
        ) THEN
            RAISE EXCEPTION
                'Nur Community Partner (user_type = company) können gesponserte Aktivitäten erstellen';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER activities_enforce_sponsored
    BEFORE INSERT OR UPDATE OF is_sponsored, host_id ON public.activities
    FOR EACH ROW
    EXECUTE FUNCTION public.enforce_sponsored_only_for_company();

-- ============================================================
-- RPC: discover_activities (Filter + Featured/Sponsored Ranking)
-- ============================================================

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
    is_featured BOOLEAN
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
        (a.is_sponsored AND p.user_type = 'company') AS is_featured
    FROM public.activities a
    JOIN public.profiles p ON p.id = a.host_id
    WHERE a.status = 'open'
      AND a.date_time > NOW()
      AND a.host_id <> v_viewer_id
      AND public.can_view_activity(a.id, v_viewer_id)
      AND (p_location_type IS NULL OR a.location_type = p_location_type)
      AND (p_weather_condition IS NULL OR a.weather_condition = p_weather_condition)
    ORDER BY
        (a.is_sponsored AND p.user_type = 'company') DESC,
        a.date_time ASC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.discover_activities(
    DOUBLE PRECISION,
    DOUBLE PRECISION,
    public.location_type,
    public.weather_condition
) TO authenticated;
