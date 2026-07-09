-- ============================================================
-- Phase 3: Sichtbarkeit, Teilnehmer & Interesse-Matching
-- ============================================================

DO $$ BEGIN
    CREATE TYPE public.activity_status AS ENUM ('open', 'full', 'cancelled');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE public.participant_joined_via AS ENUM ('host', 'direct', 'interest_accepted');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE public.interest_status AS ENUM ('pending', 'accepted', 'declined', 'withdrawn');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Sichtbarkeits-Kreise & Status auf activities
ALTER TABLE public.activities
    ADD COLUMN IF NOT EXISTS visible_to_friends BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.activities
    ADD COLUMN IF NOT EXISTS visible_to_acquaintances BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.activities
    ADD COLUMN IF NOT EXISTS visible_to_strangers BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.activities
    ADD COLUMN IF NOT EXISTS discovery_radius_km NUMERIC NOT NULL DEFAULT 20
        CHECK (discovery_radius_km > 0 AND discovery_radius_km <= 200);
ALTER TABLE public.activities
    ADD COLUMN IF NOT EXISTS location_name TEXT;
ALTER TABLE public.activities
    ADD COLUMN IF NOT EXISTS status public.activity_status NOT NULL DEFAULT 'open';

DO $$ BEGIN
    ALTER TABLE public.activities
        ADD CONSTRAINT activities_at_least_one_visibility CHECK (
            visible_to_friends OR visible_to_acquaintances OR visible_to_strangers
        );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- activity_participants
-- ============================================================

CREATE TABLE IF NOT EXISTS public.activity_participants (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id     UUID NOT NULL REFERENCES public.activities (id) ON DELETE CASCADE,
    profile_id      UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    joined_via      public.participant_joined_via NOT NULL,
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT activity_participants_unique UNIQUE (activity_id, profile_id)
);

CREATE INDEX IF NOT EXISTS activity_participants_activity_id_idx
    ON public.activity_participants (activity_id);
CREATE INDEX IF NOT EXISTS activity_participants_profile_id_idx
    ON public.activity_participants (profile_id);

-- ============================================================
-- activity_interests
-- ============================================================

CREATE TABLE IF NOT EXISTS public.activity_interests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_id     UUID NOT NULL REFERENCES public.activities (id) ON DELETE CASCADE,
    profile_id      UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    status          public.interest_status NOT NULL DEFAULT 'pending',
    message         TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    responded_at    TIMESTAMPTZ,
    CONSTRAINT activity_interests_unique UNIQUE (activity_id, profile_id)
);

CREATE INDEX IF NOT EXISTS activity_interests_activity_id_idx
    ON public.activity_interests (activity_id);
CREATE INDEX IF NOT EXISTS activity_interests_profile_id_idx
    ON public.activity_interests (profile_id);

-- ============================================================
-- Hilfsfunktionen: Freundschaft & Bekanntschaft
-- ============================================================

CREATE OR REPLACE FUNCTION public.is_friend(p_user_a UUID, p_user_b UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.connections c
        WHERE c.status = 'friend'
          AND (
              (c.user_id_1 = p_user_a AND c.user_id_2 = p_user_b)
              OR (c.user_id_1 = p_user_b AND c.user_id_2 = p_user_a)
          )
    );
$$;

CREATE OR REPLACE FUNCTION public.is_acquaintance(p_user_a UUID, p_user_b UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.connections c
        WHERE c.status = 'acquaintance'
          AND (
              (c.user_id_1 = p_user_a AND c.user_id_2 = p_user_b)
              OR (c.user_id_1 = p_user_b AND c.user_id_2 = p_user_a)
          )
    );
$$;

CREATE OR REPLACE FUNCTION public.activity_is_full(p_activity_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT COALESCE(
        (
            SELECT a.max_participants IS NOT NULL
               AND a.current_participants >= a.max_participants
            FROM public.activities a
            WHERE a.id = p_activity_id
        ),
        false
    );
$$;

CREATE OR REPLACE FUNCTION public.is_activity_participant(
    p_activity_id UUID,
    p_profile_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.activity_participants ap
        WHERE ap.activity_id = p_activity_id
          AND ap.profile_id = p_profile_id
    );
$$;

CREATE OR REPLACE FUNCTION public.has_pending_interest(
    p_activity_id UUID,
    p_profile_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.activity_interests ai
        WHERE ai.activity_id = p_activity_id
          AND ai.profile_id = p_profile_id
          AND ai.status = 'pending'
    );
$$;

-- ============================================================
-- Sichtbarkeitsprüfung
-- ============================================================

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

-- ============================================================
-- Host als Teilnehmer bei Erstellung
-- ============================================================

CREATE OR REPLACE FUNCTION public.add_host_as_participant()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.activity_participants (activity_id, profile_id, joined_via)
    VALUES (NEW.id, NEW.host_id, 'host');

    UPDATE public.activities
    SET current_participants = 1
    WHERE id = NEW.id;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS activities_add_host_participant ON public.activities;
CREATE TRIGGER activities_add_host_participant
    AFTER INSERT ON public.activities
    FOR EACH ROW
    EXECUTE FUNCTION public.add_host_as_participant();

-- ============================================================
-- RPC: discover_activities
-- ============================================================

CREATE OR REPLACE FUNCTION public.discover_activities(
    p_lat DOUBLE PRECISION,
    p_lng DOUBLE PRECISION
)
RETURNS TABLE (
    id UUID,
    host_id UUID,
    host_username TEXT,
    title TEXT,
    description TEXT,
    max_participants INT,
    current_participants INT,
    date_time TIMESTAMPTZ,
    weather_category public.weather_category,
    location_name TEXT,
    distance_km DOUBLE PRECISION,
    visible_as TEXT,
    viewer_action TEXT
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
        a.title,
        a.description,
        a.max_participants,
        a.current_participants,
        a.date_time,
        a.weather_category,
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
        END AS viewer_action
    FROM public.activities a
    JOIN public.profiles p ON p.id = a.host_id
    WHERE a.status = 'open'
      AND a.date_time > NOW()
      AND a.host_id <> v_viewer_id
      AND public.can_view_activity(a.id, v_viewer_id)
    ORDER BY a.date_time ASC;
END;
$$;

-- ============================================================
-- RPC: join_activity_direct (Freunde)
-- ============================================================

CREATE OR REPLACE FUNCTION public.join_activity_direct(p_activity_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_viewer_id UUID := auth.uid();
    v_host_id UUID;
    v_visible_to_friends BOOLEAN;
BEGIN
    IF v_viewer_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    SELECT host_id, visible_to_friends
    INTO v_host_id, v_visible_to_friends
    FROM public.activities
    WHERE id = p_activity_id
      AND status = 'open';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Aktivität nicht gefunden oder nicht offen';
    END IF;

    IF NOT v_visible_to_friends THEN
        RAISE EXCEPTION 'Direktzusage für Freunde nicht aktiviert';
    END IF;

    IF NOT public.is_friend(v_viewer_id, v_host_id) THEN
        RAISE EXCEPTION 'Nur Freunde können direkt zusagen';
    END IF;

    IF public.is_activity_participant(p_activity_id, v_viewer_id) THEN
        RAISE EXCEPTION 'Bereits Teilnehmer';
    END IF;

    IF public.activity_is_full(p_activity_id) THEN
        RAISE EXCEPTION 'Aktivität ist voll';
    END IF;

    INSERT INTO public.activity_participants (activity_id, profile_id, joined_via)
    VALUES (p_activity_id, v_viewer_id, 'direct');

    UPDATE public.activities
    SET current_participants = current_participants + 1,
        status = CASE
            WHEN max_participants IS NOT NULL
                 AND current_participants + 1 >= max_participants THEN 'full'::public.activity_status
            ELSE status
        END
    WHERE id = p_activity_id;
END;
$$;

-- ============================================================
-- RPC: express_activity_interest (Bekannte & Fremde)
-- ============================================================

CREATE OR REPLACE FUNCTION public.express_activity_interest(
    p_activity_id UUID,
    p_message TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_viewer_id UUID := auth.uid();
    v_host_id UUID;
    v_can_interest BOOLEAN := false;
    v_interest_id UUID;
BEGIN
    IF v_viewer_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    SELECT host_id INTO v_host_id
    FROM public.activities
    WHERE id = p_activity_id
      AND status = 'open';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Aktivität nicht gefunden oder nicht offen';
    END IF;

    IF v_host_id = v_viewer_id THEN
        RAISE EXCEPTION 'Host kann kein Interesse bekunden';
    END IF;

    IF public.is_activity_participant(p_activity_id, v_viewer_id) THEN
        RAISE EXCEPTION 'Bereits Teilnehmer';
    END IF;

    IF public.has_pending_interest(p_activity_id, v_viewer_id) THEN
        RAISE EXCEPTION 'Interesse bereits bekundet';
    END IF;

    IF public.activity_is_full(p_activity_id) THEN
        RAISE EXCEPTION 'Aktivität ist voll';
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM public.activities a
        WHERE a.id = p_activity_id
          AND (
              (a.visible_to_acquaintances
               AND public.is_acquaintance(v_viewer_id, a.host_id))
              OR
              (a.visible_to_strangers
               AND public.can_view_activity(p_activity_id, v_viewer_id)
               AND NOT public.is_friend(v_viewer_id, a.host_id)
               AND NOT public.is_acquaintance(v_viewer_id, a.host_id))
          )
    ) INTO v_can_interest;

    IF NOT v_can_interest THEN
        RAISE EXCEPTION 'Keine Berechtigung für Interesse';
    END IF;

    INSERT INTO public.activity_interests (activity_id, profile_id, message)
    VALUES (p_activity_id, v_viewer_id, p_message)
    RETURNING id INTO v_interest_id;

    RETURN v_interest_id;
END;
$$;

-- ============================================================
-- RPC: accept_activity_interest / decline_activity_interest
-- ============================================================

CREATE OR REPLACE FUNCTION public.accept_activity_interest(p_interest_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_host_id UUID := auth.uid();
    v_activity_id UUID;
    v_profile_id UUID;
BEGIN
    SELECT ai.activity_id, ai.profile_id
    INTO v_activity_id, v_profile_id
    FROM public.activity_interests ai
    JOIN public.activities a ON a.id = ai.activity_id
    WHERE ai.id = p_interest_id
      AND ai.status = 'pending'
      AND a.host_id = v_host_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Interesse nicht gefunden';
    END IF;

    IF public.activity_is_full(v_activity_id) THEN
        RAISE EXCEPTION 'Aktivität ist voll';
    END IF;

    UPDATE public.activity_interests
    SET status = 'accepted',
        responded_at = NOW()
    WHERE id = p_interest_id;

    INSERT INTO public.activity_participants (activity_id, profile_id, joined_via)
    VALUES (v_activity_id, v_profile_id, 'interest_accepted');

    UPDATE public.activities
    SET current_participants = current_participants + 1,
        status = CASE
            WHEN max_participants IS NOT NULL
                 AND current_participants + 1 >= max_participants THEN 'full'::public.activity_status
            ELSE status
        END
    WHERE id = v_activity_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.decline_activity_interest(p_interest_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE public.activity_interests ai
    SET status = 'declined',
        responded_at = NOW()
    FROM public.activities a
    WHERE ai.id = p_interest_id
      AND ai.status = 'pending'
      AND a.id = ai.activity_id
      AND a.host_id = auth.uid();

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Interesse nicht gefunden';
    END IF;
END;
$$;

-- ============================================================
-- RPC: get_activity_interests (nur Host)
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_activity_interests(p_activity_id UUID)
RETURNS TABLE (
    id UUID,
    profile_id UUID,
    username TEXT,
    avatar_url TEXT,
    message TEXT,
    status public.interest_status,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.activities
        WHERE id = p_activity_id AND host_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Nur der Host kann Interessenten sehen';
    END IF;

    RETURN QUERY
    SELECT
        ai.id,
        ai.profile_id,
        p.username,
        p.avatar_url,
        ai.message,
        ai.status,
        ai.created_at
    FROM public.activity_interests ai
    JOIN public.profiles p ON p.id = ai.profile_id
    WHERE ai.activity_id = p_activity_id
    ORDER BY ai.created_at ASC;
END;
$$;

-- ============================================================
-- RLS Updates
-- ============================================================

DROP POLICY IF EXISTS "Aktivitäten sind für eingeloggte User lesbar" ON public.activities;
DROP POLICY IF EXISTS "Aktivitäten nur bei Sichtbarkeit lesbar" ON public.activities;

CREATE POLICY "Aktivitäten nur bei Sichtbarkeit lesbar"
    ON public.activities
    FOR SELECT
    TO authenticated
    USING (public.can_view_activity(id, auth.uid()));

ALTER TABLE public.activity_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_interests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Teilnehmer lesen bei sichtbarer Aktivität" ON public.activity_participants;
CREATE POLICY "Teilnehmer lesen bei sichtbarer Aktivität"
    ON public.activity_participants
    FOR SELECT
    TO authenticated
    USING (public.can_view_activity(activity_id, auth.uid()));

DROP POLICY IF EXISTS "Eigene Teilnahme lesen" ON public.activity_participants;
CREATE POLICY "Eigene Teilnahme lesen"
    ON public.activity_participants
    FOR SELECT
    TO authenticated
    USING (profile_id = auth.uid());

DROP POLICY IF EXISTS "Interessen lesen als Host oder eigene" ON public.activity_interests;
CREATE POLICY "Interessen lesen als Host oder eigene"
    ON public.activity_interests
    FOR SELECT
    TO authenticated
    USING (
        profile_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.activities a
            WHERE a.id = activity_id AND a.host_id = auth.uid()
        )
    );

-- Schreibzugriffe nur über SECURITY DEFINER RPCs
REVOKE INSERT, UPDATE, DELETE ON public.activity_participants FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.activity_interests FROM authenticated;

GRANT EXECUTE ON FUNCTION public.discover_activities TO authenticated;
GRANT EXECUTE ON FUNCTION public.join_activity_direct TO authenticated;
GRANT EXECUTE ON FUNCTION public.express_activity_interest TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_activity_interest TO authenticated;
GRANT EXECUTE ON FUNCTION public.decline_activity_interest TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_activity_interests TO authenticated;
