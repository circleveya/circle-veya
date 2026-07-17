-- get_activity_detail uses public.connections with status friend/acquaintance
CREATE OR REPLACE FUNCTION public.get_activity_detail(p_activity_id UUID)
RETURNS TABLE (
    id UUID,
    host_id UUID,
    host_username TEXT,
    host_is_company BOOLEAN,
    host_avatar_url TEXT,
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
    source_event_id TEXT,
    source_event_title TEXT,
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
        p.avatar_url AS host_avatar_url,
        a.title,
        a.description,
        a.max_participants,
        a.current_participants,
        a.date_time,
        a.location_type,
        a.weather_condition,
        a.location_name,
        NULL::DOUBLE PRECISION AS distance_km,
        CASE
            WHEN a.host_id = v_viewer_id THEN 'friend'
            WHEN EXISTS (
                SELECT 1 FROM public.connections c
                WHERE c.status = 'friend'
                  AND ((c.user_id_1 = v_viewer_id AND c.user_id_2 = a.host_id)
                    OR (c.user_id_2 = v_viewer_id AND c.user_id_1 = a.host_id))
            ) THEN 'friend'
            WHEN EXISTS (
                SELECT 1 FROM public.connections c
                WHERE c.status = 'acquaintance'
                  AND ((c.user_id_1 = v_viewer_id AND c.user_id_2 = a.host_id)
                    OR (c.user_id_2 = v_viewer_id AND c.user_id_1 = a.host_id))
            ) THEN 'acquaintance'
            ELSE 'stranger'
        END::TEXT AS visible_as,
        CASE
            WHEN a.host_id = v_viewer_id THEN 'host'
            WHEN EXISTS (
                SELECT 1 FROM public.activity_participants ap
                WHERE ap.activity_id = a.id AND ap.profile_id = v_viewer_id
            ) THEN 'joined'
            WHEN COALESCE(a.source, 'user') = 'external' THEN 'external_link'
            WHEN a.visible_to_strangers OR EXISTS (
                SELECT 1 FROM public.connections c
                WHERE c.status IN ('friend', 'acquaintance')
                  AND ((c.user_id_1 = v_viewer_id AND c.user_id_2 = a.host_id)
                    OR (c.user_id_2 = v_viewer_id AND c.user_id_1 = a.host_id))
            ) THEN
                CASE WHEN a.max_participants IS NOT NULL
                          AND a.current_participants >= a.max_participants
                     THEN 'none' ELSE 'direct_join' END
            ELSE 'interest'
        END::TEXT AS viewer_action,
        a.is_sponsored,
        (a.is_sponsored AND p.user_type = 'company') AS is_featured,
        a.image_url,
        a.source,
        a.external_url,
        a.source_event_id,
        a.source_event_title,
        a.created_at,
        ARRAY[]::TEXT[] AS participant_avatar_urls
    FROM public.activities a
    JOIN public.profiles p ON p.id = a.host_id
    WHERE a.id = p_activity_id
      AND a.status <> 'cancelled'
      AND (
        a.host_id = v_viewer_id
        OR EXISTS (
          SELECT 1 FROM public.activity_participants ap
          WHERE ap.activity_id = a.id AND ap.profile_id = v_viewer_id
        )
        OR EXISTS (
          SELECT 1 FROM public.activity_interests ai
          WHERE ai.activity_id = a.id AND ai.profile_id = v_viewer_id
        )
        OR a.visible_to_strangers
        OR (
          a.visible_to_friends AND EXISTS (
            SELECT 1 FROM public.connections c
            WHERE c.status = 'friend'
              AND ((c.user_id_1 = v_viewer_id AND c.user_id_2 = a.host_id)
                OR (c.user_id_2 = v_viewer_id AND c.user_id_1 = a.host_id))
          )
        )
        OR (
          a.visible_to_acquaintances AND EXISTS (
            SELECT 1 FROM public.connections c
            WHERE c.status IN ('friend', 'acquaintance')
              AND ((c.user_id_1 = v_viewer_id AND c.user_id_2 = a.host_id)
                OR (c.user_id_2 = v_viewer_id AND c.user_id_1 = a.host_id))
          )
        )
      )
    LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_activity_detail(UUID) TO authenticated;
