-- =============================================================================
-- Migration 00020: social_feed_activities
-- Zweck: Feed nur mit Aktivitäten von Freunden/Bekannten (Host oder Teilnehmer).
-- Betrifft: RPC social_feed_activities
-- =============================================================================
CREATE OR REPLACE FUNCTION public.social_feed_activities(
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_limit INT DEFAULT 50,
    p_offset INT DEFAULT 0
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
    v_limit INT := GREATEST(COALESCE(p_limit, 50), 1);
    v_offset INT := GREATEST(COALESCE(p_offset, 0), 0);
BEGIN
    IF v_viewer_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    v_viewer_point := ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::GEOGRAPHY;

    IF v_offset = 0 THEN
        UPDATE public.profiles
        SET location = v_viewer_point,
            updated_at = NOW()
        WHERE profiles.id = v_viewer_id;
    END IF;

    RETURN QUERY
    WITH circle AS (
        SELECT
            CASE
                WHEN c.user_id_1 = v_viewer_id THEN c.user_id_2
                ELSE c.user_id_1
            END AS profile_id,
            c.status AS relation
        FROM public.connections c
        WHERE c.status IN ('friend', 'acquaintance')
          AND (c.user_id_1 = v_viewer_id OR c.user_id_2 = v_viewer_id)
    ),
    feed_ids AS (
        SELECT DISTINCT a.id AS activity_id,
            CASE
                WHEN EXISTS (
                    SELECT 1 FROM circle c
                    WHERE c.relation = 'friend'
                      AND (
                          c.profile_id = a.host_id
                          OR EXISTS (
                              SELECT 1
                              FROM public.activity_participants ap
                              WHERE ap.activity_id = a.id
                                AND ap.profile_id = c.profile_id
                          )
                      )
                ) THEN 'friend'
                ELSE 'acquaintance'
            END AS relation_label
        FROM public.activities a
        WHERE a.status IN ('open', 'full')
          AND COALESCE(a.source, 'user') <> 'external'
          AND (a.date_time IS NULL OR a.date_time > NOW())
          AND a.host_id <> v_viewer_id
          AND (
              EXISTS (
                  SELECT 1 FROM circle c WHERE c.profile_id = a.host_id
              )
              OR EXISTS (
                  SELECT 1
                  FROM public.activity_participants ap
                  JOIN circle c ON c.profile_id = ap.profile_id
                  WHERE ap.activity_id = a.id
              )
          )
    )
    SELECT
        a.id,
        a.host_id,
        p.username AS host_username,
        (p.user_type = 'company') AS host_is_company,
        a.title,
        NULL::TEXT AS description,
        NULL::INT AS max_participants,
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
        f.relation_label AS visible_as,
        CASE
            WHEN public.is_activity_participant(a.id, v_viewer_id) THEN 'joined'
            WHEN public.has_pending_interest(a.id, v_viewer_id) THEN 'interest_pending'
            WHEN a.status = 'full' OR public.activity_is_full(a.id) THEN 'full'
            WHEN public.is_friend(v_viewer_id, a.host_id)
                 AND a.visible_to_friends THEN 'direct_join'
            WHEN public.is_acquaintance(v_viewer_id, a.host_id)
                 AND a.visible_to_acquaintances THEN 'interest'
            WHEN a.visible_to_strangers THEN 'interest'
            ELSE 'none'
        END AS viewer_action,
        a.is_sponsored,
        (a.is_sponsored AND p.user_type = 'company') AS is_featured,
        a.image_url,
        a.source,
        a.external_url,
        a.created_at,
        ARRAY[]::TEXT[] AS participant_avatar_urls
    FROM feed_ids f
    JOIN public.activities a ON a.id = f.activity_id
    JOIN public.profiles p ON p.id = a.host_id
    ORDER BY
        CASE WHEN f.relation_label = 'friend' THEN 0 ELSE 1 END,
        a.date_time ASC NULLS LAST,
        a.created_at DESC
    LIMIT v_limit
    OFFSET v_offset;
END;
$$;

GRANT EXECUTE ON FUNCTION public.social_feed_activities(
    DOUBLE PRECISION,
    DOUBLE PRECISION,
    INT,
    INT
) TO authenticated;
