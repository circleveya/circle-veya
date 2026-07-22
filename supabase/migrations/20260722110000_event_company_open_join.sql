-- Event-/Unternehmens-Aktivitäten: offene Direktzusage für alle (ohne Freundes-Check)

-- Bestehende Business-Events auf öffentlich stellen
UPDATE public.activities a
SET
  visible_to_strangers = true,
  visible_to_friends = false,
  visible_to_acquaintances = false
FROM public.profiles p
WHERE p.id = a.host_id
  AND public.is_business_profile_type(p.user_type);

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
    v_host_type public.user_type;
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

    SELECT user_type INTO v_host_type
    FROM public.profiles
    WHERE id = v_activity.host_id;

    IF public.is_business_profile_type(v_host_type) THEN
        RETURN true;
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

CREATE OR REPLACE FUNCTION public.join_activity_direct(p_activity_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_viewer_id UUID := auth.uid();
    v_host_id UUID;
    v_host_type public.user_type;
    v_visible_to_friends BOOLEAN;
    v_new_count INT;
BEGIN
    IF v_viewer_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    SELECT a.host_id, a.visible_to_friends, p.user_type
    INTO v_host_id, v_visible_to_friends, v_host_type
    FROM public.activities a
    JOIN public.profiles p ON p.id = a.host_id
    WHERE a.id = p_activity_id
      AND a.status IN ('open', 'full');

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Aktivität nicht gefunden oder nicht offen';
    END IF;

    IF v_viewer_id = v_host_id THEN
        RAISE EXCEPTION 'Host ist bereits Teilnehmer';
    END IF;

    IF NOT public.is_business_profile_type(v_host_type) THEN
        IF NOT v_visible_to_friends THEN
            RAISE EXCEPTION 'Direktzusage für Freunde nicht aktiviert';
        END IF;

        IF NOT public.is_friend(v_viewer_id, v_host_id) THEN
            RAISE EXCEPTION 'Nur Freunde können direkt zusagen';
        END IF;
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
        OR public.is_business_profile_type(p.user_type)
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

DROP FUNCTION IF EXISTS public.discover_activities(
    DOUBLE PRECISION,
    DOUBLE PRECISION,
    public.location_type,
    public.weather_condition,
    INT,
    INT,
    TIMESTAMPTZ,
    TIMESTAMPTZ
);

CREATE OR REPLACE FUNCTION public.discover_activities(
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION,
    p_location_type public.location_type DEFAULT NULL,
    p_weather_condition public.weather_condition DEFAULT NULL,
    p_limit INT DEFAULT 10,
    p_offset INT DEFAULT 0,
    p_date_from TIMESTAMPTZ DEFAULT NULL,
    p_date_to TIMESTAMPTZ DEFAULT NULL
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
    v_limit INT := GREATEST(COALESCE(p_limit, 10), 1);
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
    SELECT
        a.id,
        a.host_id,
        p.username AS host_username,
        public.is_business_profile_type(p.user_type) AS host_is_company,
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
            WHEN public.is_business_profile_type(p.user_type) THEN 'direct_join'
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
        (a.is_sponsored AND public.is_business_profile_type(p.user_type)) AS is_featured,
        a.image_url,
        a.source,
        a.external_url,
        a.created_at,
        ARRAY[]::TEXT[] AS participant_avatar_urls
    FROM public.activities a
    JOIN public.profiles p ON p.id = a.host_id
    WHERE a.status IN ('open', 'full')
      AND (a.date_time IS NULL OR a.date_time > NOW())
      AND (a.host_id <> v_viewer_id OR a.source = 'external')
      AND public.can_view_activity(a.id, v_viewer_id)
      AND (p_location_type IS NULL OR a.location_type = p_location_type)
      AND (p_weather_condition IS NULL OR a.weather_condition = p_weather_condition)
      AND (p_date_from IS NULL OR a.date_time >= p_date_from)
      AND (p_date_to IS NULL OR a.date_time <= p_date_to)
    ORDER BY
        (a.is_sponsored AND public.is_business_profile_type(p.user_type)) DESC,
        a.date_time ASC NULLS LAST,
        CASE
            WHEN a.location_geo IS NOT NULL THEN
                ST_Distance(a.location_geo, v_viewer_point)
            ELSE NULL
        END ASC NULLS LAST
    LIMIT v_limit
    OFFSET v_offset;
END;
$$;

DROP FUNCTION IF EXISTS public.social_feed_activities(
    DOUBLE PRECISION,
    DOUBLE PRECISION,
    INT,
    INT
);

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

    RETURN QUERY
    WITH circle AS (
        SELECT c.user_id_2 AS profile_id, 'friend'::TEXT AS relation_label
        FROM public.connections c
        WHERE c.user_id_1 = v_viewer_id AND c.status = 'friend'
        UNION
        SELECT c.user_id_1, 'friend'
        FROM public.connections c
        WHERE c.user_id_2 = v_viewer_id AND c.status = 'friend'
        UNION
        SELECT c.user_id_2, 'acquaintance'
        FROM public.connections c
        WHERE c.user_id_1 = v_viewer_id AND c.status = 'acquaintance'
        UNION
        SELECT c.user_id_1, 'acquaintance'
        FROM public.connections c
        WHERE c.user_id_2 = v_viewer_id AND c.status = 'acquaintance'
    ),
    feed_ids AS (
        SELECT DISTINCT a.id AS activity_id, f.relation_label
        FROM public.activities a
        JOIN circle f ON f.profile_id = a.host_id
        WHERE a.status IN ('open', 'full')
          AND (a.date_time IS NULL OR a.date_time > NOW())
        UNION
        SELECT DISTINCT a.id, 'friend'::TEXT
        FROM public.activities a
        JOIN public.activity_participants ap ON ap.activity_id = a.id
        JOIN circle c ON c.profile_id = ap.profile_id
        WHERE a.status IN ('open', 'full')
          AND (a.date_time IS NULL OR a.date_time > NOW())
          AND a.host_id <> v_viewer_id
          AND NOT EXISTS (
              SELECT 1 FROM circle c2 WHERE c2.profile_id = a.host_id
          )
    )
    SELECT
        a.id,
        a.host_id,
        p.username AS host_username,
        public.is_business_profile_type(p.user_type) AS host_is_company,
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
            WHEN public.is_business_profile_type(p.user_type) THEN 'direct_join'
            WHEN public.is_friend(v_viewer_id, a.host_id)
                 AND a.visible_to_friends THEN 'direct_join'
            WHEN public.is_acquaintance(v_viewer_id, a.host_id)
                 AND a.visible_to_acquaintances THEN 'interest'
            WHEN a.visible_to_strangers THEN 'interest'
            ELSE 'none'
        END AS viewer_action,
        a.is_sponsored,
        (a.is_sponsored AND public.is_business_profile_type(p.user_type)) AS is_featured,
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

GRANT EXECUTE ON FUNCTION public.discover_activities(
    DOUBLE PRECISION,
    DOUBLE PRECISION,
    public.location_type,
    public.weather_condition,
    INT,
    INT,
    TIMESTAMPTZ,
    TIMESTAMPTZ
) TO authenticated;

GRANT EXECUTE ON FUNCTION public.join_activity_direct(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_activity_detail(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.social_feed_activities(
    DOUBLE PRECISION,
    DOUBLE PRECISION,
    INT,
    INT
) TO authenticated;

NOTIFY pgrst, 'reload schema';
