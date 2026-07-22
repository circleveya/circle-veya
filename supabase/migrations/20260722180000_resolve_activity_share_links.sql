-- Share-Links: stabile Event-ID aufloesen + zusaetzliche Detail-Lookups

CREATE OR REPLACE FUNCTION public.resolve_activity_link_id(p_id UUID)
RETURNS UUID
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_id UUID;
BEGIN
    IF p_id IS NULL THEN
        RETURN NULL;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.activities a
        WHERE a.id = p_id
          AND a.status <> 'cancelled'
    ) THEN
        RETURN p_id;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.external_events e
        WHERE e.id = p_id
          AND COALESCE(e.is_cancelled, FALSE) = FALSE
    ) THEN
        RETURN p_id;
    END IF;

    SELECT a.id INTO v_id
    FROM public.activities a
    WHERE a.source_event_id = p_id::TEXT
      AND a.status <> 'cancelled'
    ORDER BY a.created_at DESC
    LIMIT 1;

    IF v_id IS NOT NULL THEN
        RETURN v_id;
    END IF;

    SELECT a.id INTO v_id
    FROM public.activities a
    JOIN public.external_events e
      ON e.external_id = a.source_event_id
    WHERE e.id = p_id
      AND a.status <> 'cancelled'
    ORDER BY a.created_at DESC
    LIMIT 1;

    IF v_id IS NOT NULL THEN
        RETURN v_id;
    END IF;

    SELECT e.id INTO v_id
    FROM public.external_events e
    WHERE e.external_id = p_id::TEXT
      AND COALESCE(e.is_cancelled, FALSE) = FALSE
    ORDER BY e.start_date ASC NULLS LAST
    LIMIT 1;

    RETURN COALESCE(v_id, p_id);
END;
$$;

GRANT EXECUTE ON FUNCTION public.resolve_activity_link_id(UUID) TO authenticated, anon;

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
    v_link_id UUID := public.resolve_activity_link_id(p_activity_id);
BEGIN
    RETURN QUERY
    SELECT
        a.id,
        a.host_id,
        p.username AS host_username,
        public.is_business_profile_type(p.user_type) AS host_is_company,
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
            WHEN v_viewer_id IS NULL THEN 'stranger'
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
            WHEN v_viewer_id IS NULL THEN
                CASE
                    WHEN COALESCE(a.source, 'user') = 'external' THEN 'external_link'
                    WHEN public.is_business_profile_type(p.user_type) THEN
                        CASE WHEN a.max_participants IS NOT NULL
                                  AND a.current_participants >= a.max_participants
                             THEN 'none' ELSE 'direct_join' END
                    ELSE 'interest'
                END
            WHEN a.host_id = v_viewer_id THEN 'host'
            WHEN EXISTS (
                SELECT 1 FROM public.activity_participants ap
                WHERE ap.activity_id = a.id AND ap.profile_id = v_viewer_id
            ) THEN 'joined'
            WHEN COALESCE(a.source, 'user') = 'external' THEN 'external_link'
            WHEN public.is_business_profile_type(p.user_type) THEN
                CASE WHEN a.max_participants IS NOT NULL
                          AND a.current_participants >= a.max_participants
                     THEN 'none' ELSE 'direct_join' END
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
        (a.is_sponsored AND public.is_business_profile_type(p.user_type)) AS is_featured,
        a.image_url,
        a.source,
        a.external_url,
        a.source_event_id,
        a.source_event_title,
        a.created_at,
        ARRAY[]::TEXT[] AS participant_avatar_urls
    FROM public.activities a
    JOIN public.profiles p ON p.id = a.host_id
    WHERE a.id = v_link_id
      AND a.status <> 'cancelled'
    LIMIT 1;

    IF FOUND THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        e.id,
        COALESCE(public.get_external_events_host_id(), e.id) AS host_id,
        'CircleVeya'::TEXT AS host_username,
        FALSE AS host_is_company,
        NULL::TEXT AS host_avatar_url,
        e.title,
        e.description,
        NULL::INT AS max_participants,
        0::INT AS current_participants,
        e.start_date AS date_time,
        'indoor'::public.location_type AS location_type,
        'sun'::public.weather_condition AS weather_condition,
        COALESCE(NULLIF(TRIM(e.location_name), ''), NULLIF(TRIM(e.city), '')) AS location_name,
        NULL::DOUBLE PRECISION AS distance_km,
        'stranger'::TEXT AS visible_as,
        'external_link'::TEXT AS viewer_action,
        FALSE AS is_sponsored,
        FALSE AS is_featured,
        e.image_url,
        'external'::TEXT AS source,
        e.external_url,
        e.external_id AS source_event_id,
        e.title AS source_event_title,
        e.created_at,
        ARRAY[]::TEXT[] AS participant_avatar_urls
    FROM public.external_events e
    WHERE e.id = v_link_id
      AND COALESCE(e.is_cancelled, FALSE) = FALSE
    LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_activity_detail(UUID) TO authenticated, anon;

NOTIFY pgrst, 'reload schema';
