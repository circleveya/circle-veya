-- ============================================================
-- Sidebar-RPCs für Flutter WebRightPanel
-- Behebt PGRST202 (Funktion nicht gefunden)
--
-- Flutter erwartet (sidebar_remote_datasource.dart):
--   get_trending_activities  → activity_id, title, participant_count, source, external_provider
--   get_recommended_activities → activity_id, title, match_score, distance_km
--   get_online_friends       → profile_id, username, avatar_url
--
-- Voraussetzungen: Migrationen 00004+ (can_view_activity, connections),
--                   00007 (profiles.interests), 00011 optional (activities.source)
-- ============================================================

-- Spalten für Online-Status (falls Migration 00013 noch nicht gelaufen)
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS is_online BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Optional: source-Spalte falls 00011 fehlt
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS interests TEXT[] NOT NULL DEFAULT '{}';

ALTER TABLE public.activities
    ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'user';

ALTER TABLE public.activities
    ADD COLUMN IF NOT EXISTS external_provider TEXT;

-- ------------------------------------------------------------
-- 1. Im Trend – sortiert nach activity_participants
-- ------------------------------------------------------------
DROP FUNCTION IF EXISTS public.get_trending_activities(INT);

CREATE OR REPLACE FUNCTION public.get_trending_activities(p_limit INT DEFAULT 3)
RETURNS TABLE (
    activity_id UUID,
    title TEXT,
    participant_count INT,
    source TEXT,
    external_provider TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
    SELECT
        a.id AS activity_id,
        a.title,
        COUNT(ap.id)::INT AS participant_count,
        COALESCE(a.source, 'user') AS source,
        a.external_provider
    FROM public.activities a
    LEFT JOIN public.activity_participants ap ON ap.activity_id = a.id
    WHERE a.status IN ('open', 'full')
      AND (a.date_time IS NULL OR a.date_time > NOW())
      AND public.can_view_activity(a.id, auth.uid())
    GROUP BY a.id, a.title, a.source, a.external_provider, a.created_at
    ORDER BY participant_count DESC, a.created_at DESC
    LIMIT GREATEST(COALESCE(p_limit, 3), 1);
$$;

-- ------------------------------------------------------------
-- 2. Für dich empfohlen – Interessen-Matching (auth.uid())
-- ------------------------------------------------------------
DROP FUNCTION IF EXISTS public.get_recommended_activities(INT);

CREATE OR REPLACE FUNCTION public.get_recommended_activities(p_limit INT DEFAULT 5)
RETURNS TABLE (
    activity_id UUID,
    title TEXT,
    match_score INT,
    distance_km DOUBLE PRECISION
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, extensions
AS $$
#variable_conflict use_column
DECLARE
    v_viewer_id UUID := auth.uid();
    v_viewer_point GEOGRAPHY;
    v_interests TEXT[];
BEGIN
    IF v_viewer_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    SELECT p.location, p.interests
    INTO v_viewer_point, v_interests
    FROM public.profiles p
    WHERE p.id = v_viewer_id;

    RETURN QUERY
    SELECT
        a.id AS activity_id,
        a.title,
        (
            CASE
                WHEN v_interests IS NOT NULL
                 AND cardinality(v_interests) > 0
                 AND EXISTS (
                    SELECT 1
                    FROM unnest(v_interests) AS i(interest)
                    WHERE lower(a.title) LIKE '%' || lower(i.interest) || '%'
                       OR lower(COALESCE(a.description, '')) LIKE '%' || lower(i.interest) || '%'
                       OR lower(a.location_type::TEXT) LIKE '%' || lower(i.interest) || '%'
                )
                THEN 3
                ELSE 0
            END
            + CASE WHEN a.is_sponsored THEN 2 ELSE 0 END
            + CASE WHEN a.location_type = 'outdoor' THEN 1 ELSE 0 END
        )::INT AS match_score,
        CASE
            WHEN v_viewer_point IS NOT NULL AND a.location_geo IS NOT NULL
                THEN ST_Distance(a.location_geo, v_viewer_point) / 1000.0
            ELSE NULL
        END AS distance_km
    FROM public.activities a
    WHERE a.status IN ('open', 'full')
      AND (a.date_time IS NULL OR a.date_time > NOW())
      AND public.can_view_activity(a.id, v_viewer_id)
    ORDER BY match_score DESC, distance_km ASC NULLS LAST, a.created_at DESC
    LIMIT GREATEST(COALESCE(p_limit, 5), 1);
END;
$$;

-- ------------------------------------------------------------
-- 3. Freunde online – is_online = true
-- ------------------------------------------------------------
DROP FUNCTION IF EXISTS public.get_online_friends();

CREATE OR REPLACE FUNCTION public.get_online_friends()
RETURNS TABLE (
    profile_id UUID,
    username TEXT,
    avatar_url TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT
        p.id AS profile_id,
        p.username,
        p.avatar_url
    FROM public.connections c
    JOIN public.profiles p ON p.id = CASE
        WHEN c.user_id_1 = auth.uid() THEN c.user_id_2
        ELSE c.user_id_1
    END
    WHERE c.status = 'friend'
      AND (c.user_id_1 = auth.uid() OR c.user_id_2 = auth.uid())
      AND p.is_online = true
    ORDER BY p.last_seen DESC
    LIMIT 12;
$$;

-- Berechtigungen
GRANT EXECUTE ON FUNCTION public.get_trending_activities(INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_recommended_activities(INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_online_friends() TO authenticated;

-- Schema-Cache aktualisieren (PostgREST)
NOTIFY pgrst, 'reload schema';
