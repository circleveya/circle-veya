-- =============================================================================
-- Migration 00021: my_activities
-- Zweck: Nur selbst erstellte oder zugesagte Aktivitäten (keine Interests).
-- Betrifft: RPC my_activities
-- =============================================================================
CREATE OR REPLACE FUNCTION public.my_activities(
    p_limit INT DEFAULT 100,
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
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
#variable_conflict use_column
DECLARE
    v_viewer_id UUID := auth.uid();
    v_limit INT := GREATEST(COALESCE(p_limit, 100), 1);
    v_offset INT := GREATEST(COALESCE(p_offset, 0), 0);
BEGIN
    IF v_viewer_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

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
        NULL::DOUBLE PRECISION AS distance_km,
        'friend'::TEXT AS visible_as,
        CASE
            WHEN a.host_id = v_viewer_id THEN 'host'
            ELSE 'joined'
        END AS viewer_action,
        a.is_sponsored,
        (a.is_sponsored AND p.user_type = 'company') AS is_featured,
        a.image_url,
        a.source,
        a.external_url,
        a.created_at,
        ARRAY[]::TEXT[] AS participant_avatar_urls
    FROM public.activities a
    JOIN public.profiles p ON p.id = a.host_id
    WHERE a.status <> 'cancelled'
      AND COALESCE(a.source, 'user') <> 'external'
      AND (
          a.host_id = v_viewer_id
          OR EXISTS (
              SELECT 1
              FROM public.activity_participants ap
              WHERE ap.activity_id = a.id
                AND ap.profile_id = v_viewer_id
                AND ap.joined_via IN ('direct', 'interest_accepted')
          )
      )
    ORDER BY
        CASE WHEN a.host_id = v_viewer_id THEN 0 ELSE 1 END,
        a.date_time ASC NULLS LAST,
        a.created_at DESC
    LIMIT v_limit
    OFFSET v_offset;
END;
$$;

GRANT EXECUTE ON FUNCTION public.my_activities(INT, INT) TO authenticated;
