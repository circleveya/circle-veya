-- =============================================================================
-- Script: 01_volatile_functions.sql
-- Zweck: fixes
-- Zweck: Setzt RPCs auf VOLATILE, die intern UPDATE ausführen.
-- Betrifft: discover_activities, heartbeat_presence, simulate_premium
-- Wann: Bei Fehler "UPDATE is not allowed in a non-volatile function"
-- =============================================================================

-- 1. discover_activities – speichert Viewer-Standort per UPDATE
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
    created_at TIMESTAMPTZ,
    participant_avatar_urls TEXT[]
)
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
#variable_conflict use_column
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
    WHERE profiles.id = v_viewer_id;

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
        a.created_at,
        (
            SELECT COALESCE(array_agg(sub.avatar_url), ARRAY[]::TEXT[])
            FROM (
                SELECT pr.avatar_url
                FROM public.activity_participants ap
                JOIN public.profiles pr ON pr.id = ap.profile_id
                WHERE ap.activity_id = a.id
                  AND pr.avatar_url IS NOT NULL
                ORDER BY ap.joined_at
                LIMIT 3
            ) sub
        ) AS participant_avatar_urls
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

-- 2. get_user_level_stats – ruft ensure_user_stats (INSERT) auf
DROP FUNCTION IF EXISTS public.get_user_level_stats();

CREATE OR REPLACE FUNCTION public.get_user_level_stats()
RETURNS TABLE (
    level INT,
    current_xp INT,
    xp_for_next_level INT,
    challenge_id UUID,
    challenge_title TEXT,
    challenge_progress INT,
    challenge_target INT,
    challenge_xp_reward INT
)
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
#variable_conflict use_column
DECLARE
    v_me UUID := auth.uid();
BEGIN
    IF v_me IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    PERFORM public.ensure_user_stats(v_me);

    RETURN QUERY
    SELECT
        us.level,
        us.xp,
        us.xp_needed,
        uc.id,
        uc.title,
        uc.progress,
        uc.target,
        uc.xp_reward
    FROM public.user_stats us
    LEFT JOIN public.user_challenges uc
        ON uc.profile_id = us.profile_id AND uc.is_active = true
    WHERE us.profile_id = v_me
    ORDER BY uc.created_at;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_level_stats() TO authenticated;

-- 3. heartbeat_presence & simulate_premium – explizit VOLATILE (Schreibzugriff)
CREATE OR REPLACE FUNCTION public.heartbeat_presence()
RETURNS VOID
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE public.profiles
    SET is_online = true,
        last_seen = NOW()
    WHERE profiles.id = auth.uid();
END;
$$;

CREATE OR REPLACE FUNCTION public.simulate_premium(p_enabled BOOLEAN DEFAULT true)
RETURNS BOOLEAN
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE public.profiles
    SET is_premium = p_enabled
    WHERE profiles.id = auth.uid();

    RETURN p_enabled;
END;
$$;

GRANT EXECUTE ON FUNCTION public.heartbeat_presence() TO authenticated;
GRANT EXECUTE ON FUNCTION public.simulate_premium(BOOLEAN) TO authenticated;

NOTIFY pgrst, 'reload schema';
