-- =============================================================================
-- Migration 00013: phase2_phase3_features
-- Zweck: Bugfixes, Gamification, Reviews, Notifications, Premium, Avatare.
-- Betrifft: user_stats, user_challenges, reviews, notifications, discover_activities
-- =============================================================================
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
GRANT USAGE ON SCHEMA extensions TO postgres, anon, authenticated, service_role;

-- ------------------------------------------------------------
-- 1. Bugfix: discover_activities – ambiguous "id" (RETURNS TABLE)
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 1b. RLS activities – INSERT/UPDATE/DELETE für eigene Events
-- ------------------------------------------------------------
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "User können eigene Aktivitäten erstellen" ON public.activities;
CREATE POLICY "User können eigene Aktivitäten erstellen"
    ON public.activities
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = host_id);

DROP POLICY IF EXISTS "Hosts können eigene Aktivitäten bearbeiten" ON public.activities;
CREATE POLICY "Hosts können eigene Aktivitäten bearbeiten"
    ON public.activities
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = host_id)
    WITH CHECK (auth.uid() = host_id);

DROP POLICY IF EXISTS "Hosts können eigene Aktivitäten löschen" ON public.activities;
CREATE POLICY "Hosts können eigene Aktivitäten löschen"
    ON public.activities
    FOR DELETE
    TO authenticated
    USING (auth.uid() = host_id);

DROP POLICY IF EXISTS "Hosts sehen eigene Aktivitäten" ON public.activities;
CREATE POLICY "Hosts sehen eigene Aktivitäten"
    ON public.activities
    FOR SELECT
    TO authenticated
    USING (auth.uid() = host_id);

-- ------------------------------------------------------------
-- 2. Profile-Erweiterungen: Premium & Online-Status
-- ------------------------------------------------------------
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS is_premium BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS is_online BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- ------------------------------------------------------------
-- 3. Gamification: user_stats & user_challenges
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_stats (
    profile_id  UUID PRIMARY KEY REFERENCES public.profiles (id) ON DELETE CASCADE,
    level       INT NOT NULL DEFAULT 1 CHECK (level >= 1),
    xp          INT NOT NULL DEFAULT 0 CHECK (xp >= 0),
    xp_needed   INT NOT NULL DEFAULT 1000 CHECK (xp_needed > 0),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.user_challenges (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id  UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    title       TEXT NOT NULL,
    progress    INT NOT NULL DEFAULT 0 CHECK (progress >= 0),
    target      INT NOT NULL CHECK (target > 0),
    challenge_type TEXT NOT NULL DEFAULT 'weekly',
    xp_reward   INT NOT NULL DEFAULT 100 CHECK (xp_reward >= 0),
    is_active   BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS user_challenges_profile_id_idx
    ON public.user_challenges (profile_id);

ALTER TABLE public.user_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_challenges ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Eigene Stats lesen" ON public.user_stats;
CREATE POLICY "Eigene Stats lesen"
    ON public.user_stats FOR SELECT TO authenticated
    USING (profile_id = auth.uid());

DROP POLICY IF EXISTS "Eigene Challenges lesen" ON public.user_challenges;
CREATE POLICY "Eigene Challenges lesen"
    ON public.user_challenges FOR SELECT TO authenticated
    USING (profile_id = auth.uid());

CREATE OR REPLACE FUNCTION public.ensure_user_stats(p_profile_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.user_stats (profile_id)
    VALUES (p_profile_id)
    ON CONFLICT (profile_id) DO NOTHING;

    IF NOT EXISTS (
        SELECT 1 FROM public.user_challenges WHERE profile_id = p_profile_id
    ) THEN
        INSERT INTO public.user_challenges (profile_id, title, progress, target, challenge_type, xp_reward)
        VALUES
            (p_profile_id, '3 Aktivitäten diese Woche', 0, 3, 'weekly', 150),
            (p_profile_id, 'Neue Freunde treffen', 0, 4, 'social', 200),
            (p_profile_id, 'Sport-Challenge', 0, 10, 'sport', 300);
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.award_xp(p_profile_id UUID, p_amount INT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_xp INT;
    v_needed INT;
    v_level INT;
BEGIN
    PERFORM public.ensure_user_stats(p_profile_id);

    UPDATE public.user_stats
    SET xp = xp + GREATEST(p_amount, 0),
        updated_at = NOW()
    WHERE profile_id = p_profile_id
    RETURNING xp, xp_needed, level INTO v_xp, v_needed, v_level;

    WHILE v_xp >= v_needed LOOP
        v_xp := v_xp - v_needed;
        v_level := v_level + 1;
        v_needed := v_needed + 500;
    END LOOP;

    UPDATE public.user_stats
    SET xp = v_xp,
        level = v_level,
        xp_needed = v_needed,
        updated_at = NOW()
    WHERE profile_id = p_profile_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.on_activity_created_award_xp()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    PERFORM public.ensure_user_stats(NEW.host_id);
    PERFORM public.award_xp(NEW.host_id, 50);

    UPDATE public.user_challenges
    SET progress = LEAST(progress + 1, target)
    WHERE profile_id = NEW.host_id
      AND is_active = true
      AND challenge_type IN ('weekly', 'sport');

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS activities_award_xp_on_create ON public.activities;
CREATE TRIGGER activities_award_xp_on_create
    AFTER INSERT ON public.activities
    FOR EACH ROW
    WHEN (NEW.source = 'user')
    EXECUTE FUNCTION public.on_activity_created_award_xp();

CREATE OR REPLACE FUNCTION public.on_participant_join_award_xp()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_host_id UUID;
BEGIN
    PERFORM public.ensure_user_stats(NEW.profile_id);
    PERFORM public.award_xp(NEW.profile_id, 30);

    SELECT host_id INTO v_host_id
    FROM public.activities
    WHERE activities.id = NEW.activity_id;

    IF v_host_id IS NOT NULL AND v_host_id <> NEW.profile_id THEN
        PERFORM public.award_xp(v_host_id, 10);
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS participants_award_xp_on_join ON public.activity_participants;
CREATE TRIGGER participants_award_xp_on_join
    AFTER INSERT ON public.activity_participants
    FOR EACH ROW
    WHEN (NEW.joined_via <> 'host')
    EXECUTE FUNCTION public.on_participant_join_award_xp();

-- Stats bei neuem Profil anlegen
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_username TEXT;
BEGIN
    v_username := COALESCE(
        NEW.raw_user_meta_data ->> 'username',
        SPLIT_PART(NEW.email, '@', 1)
    );

    WHILE EXISTS (SELECT 1 FROM public.profiles WHERE username = v_username) LOOP
        v_username := v_username || '_' || SUBSTRING(NEW.id::TEXT, 1, 4);
    END LOOP;

    INSERT INTO public.profiles (id, username)
    VALUES (NEW.id, v_username);

    PERFORM public.ensure_user_stats(NEW.id);

    RETURN NEW;
END;
$$;

-- ------------------------------------------------------------
-- 4. Bewertungen (Reviews)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.reviews (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    target_user_id  UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    reviewer_id     UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    rating          SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment         TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT reviews_unique_per_pair UNIQUE (target_user_id, reviewer_id)
);

CREATE INDEX IF NOT EXISTS reviews_target_user_id_idx
    ON public.reviews (target_user_id);

ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Reviews lesen" ON public.reviews;
CREATE POLICY "Reviews lesen"
    ON public.reviews FOR SELECT TO authenticated
    USING (true);

DROP POLICY IF EXISTS "Eigene Reviews schreiben" ON public.reviews;
CREATE POLICY "Eigene Reviews schreiben"
    ON public.reviews FOR INSERT TO authenticated
    WITH CHECK (reviewer_id = auth.uid() AND target_user_id <> auth.uid());

DROP POLICY IF EXISTS "Eigene Reviews bearbeiten" ON public.reviews;
CREATE POLICY "Eigene Reviews bearbeiten"
    ON public.reviews FOR UPDATE TO authenticated
    USING (reviewer_id = auth.uid())
    WITH CHECK (reviewer_id = auth.uid());

CREATE OR REPLACE FUNCTION public.get_user_rating(p_profile_id UUID)
RETURNS TABLE (avg_rating DOUBLE PRECISION, review_count INT)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT
        COALESCE(AVG(r.rating)::DOUBLE PRECISION, 0),
        COUNT(*)::INT
    FROM public.reviews r
    WHERE r.target_user_id = p_profile_id;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_rating(UUID) TO authenticated;

-- ------------------------------------------------------------
-- 5. Benachrichtigungen
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    title       TEXT NOT NULL,
    message     TEXT NOT NULL,
    type        TEXT NOT NULL DEFAULT 'info',
    is_read     BOOLEAN NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS notifications_user_id_idx
    ON public.notifications (user_id, created_at DESC);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Eigene Notifications lesen" ON public.notifications;
CREATE POLICY "Eigene Notifications lesen"
    ON public.notifications FOR SELECT TO authenticated
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Eigene Notifications aktualisieren" ON public.notifications;
CREATE POLICY "Eigene Notifications aktualisieren"
    ON public.notifications FOR UPDATE TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

CREATE OR REPLACE FUNCTION public.notify_activity_join()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_host_id UUID;
    v_title TEXT;
    v_joiner TEXT;
BEGIN
    IF NEW.joined_via = 'host' THEN
        RETURN NEW;
    END IF;

    SELECT a.host_id, a.title INTO v_host_id, v_title
    FROM public.activities a
    WHERE a.id = NEW.activity_id;

    SELECT username INTO v_joiner
    FROM public.profiles
    WHERE profiles.id = NEW.profile_id;

    INSERT INTO public.notifications (user_id, title, message, type)
    VALUES (
        v_host_id,
        'Neue Teilnahme',
        COALESCE(v_joiner, 'Jemand') || ' nimmt an "' || COALESCE(v_title, 'deiner Aktivität') || '" teil.',
        'activity_join'
    );

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS activity_participants_notify_host ON public.activity_participants;
CREATE TRIGGER activity_participants_notify_host
    AFTER INSERT ON public.activity_participants
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_activity_join();

CREATE OR REPLACE FUNCTION public.notify_nearby_external_event()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
BEGIN
    IF NEW.source <> 'external' OR NEW.location_geo IS NULL THEN
        RETURN NEW;
    END IF;

    INSERT INTO public.notifications (user_id, title, message, type)
    SELECT
        p.id,
        'Neues Event in deiner Nähe',
        '„' || NEW.title || '“ wurde automatisch gefunden.',
        'nearby_event'
    FROM public.profiles p
    WHERE p.location IS NOT NULL
      AND p.id <> NEW.host_id
      AND ST_DWithin(p.location, NEW.location_geo, 30000)
    LIMIT 50;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS activities_notify_nearby_external ON public.activities;
CREATE TRIGGER activities_notify_nearby_external
    AFTER INSERT ON public.activities
    FOR EACH ROW
    WHEN (NEW.source = 'external')
    EXECUTE FUNCTION public.notify_nearby_external_event();

-- Realtime für Notifications
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN undefined_object THEN NULL;
END $$;

-- ------------------------------------------------------------
-- 6. Sidebar-RPCs: Trend, Empfehlungen, Online-Freunde
-- ------------------------------------------------------------
DROP FUNCTION IF EXISTS public.get_trending_activities(INT);
DROP FUNCTION IF EXISTS public.get_recommended_activities(INT);
DROP FUNCTION IF EXISTS public.get_online_friends();

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
    v_viewer_point extensions.geography;
    v_interests TEXT[];
BEGIN
    IF v_viewer_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    SELECT location, interests
    INTO v_viewer_point, v_interests
    FROM public.profiles
    WHERE profiles.id = v_viewer_id;

    RETURN QUERY
    SELECT
        a.id,
        a.title,
        (
            CASE WHEN v_interests IS NOT NULL AND EXISTS (
                SELECT 1 FROM unnest(v_interests) i
                WHERE lower(a.title) LIKE '%' || lower(i) || '%'
                   OR lower(COALESCE(a.description, '')) LIKE '%' || lower(i) || '%'
            ) THEN 3 ELSE 0 END
            + CASE a.location_type
                WHEN 'outdoor' THEN 1
                ELSE 0
              END
            + CASE WHEN a.is_sponsored THEN 2 ELSE 0 END
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
    LIMIT GREATEST(p_limit, 1);
END;
$$;

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

GRANT EXECUTE ON FUNCTION public.get_trending_activities(INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_recommended_activities(INT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_online_friends() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_level_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION public.heartbeat_presence() TO authenticated;
GRANT EXECUTE ON FUNCTION public.simulate_premium(BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION public.ensure_user_stats(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.award_xp(UUID, INT) TO authenticated;

-- get_profile erweitern (cover_url, is_premium)
DROP FUNCTION IF EXISTS public.get_profile(UUID);

CREATE OR REPLACE FUNCTION public.get_profile(p_profile_id UUID)
RETURNS TABLE (
    id UUID,
    username TEXT,
    avatar_url TEXT,
    cover_url TEXT,
    bio TEXT,
    age SMALLINT,
    interests TEXT[],
    user_type public.user_type,
    is_premium BOOLEAN
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
#variable_conflict use_column
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.username,
        p.avatar_url,
        p.cover_url,
        p.bio,
        p.age,
        p.interests,
        p.user_type,
        p.is_premium
    FROM public.profiles p
    WHERE p.id = p_profile_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_profile(UUID) TO authenticated;

-- Bestehende User initialisieren
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT id FROM public.profiles LOOP
        PERFORM public.ensure_user_stats(r.id);
    END LOOP;
END $$;
