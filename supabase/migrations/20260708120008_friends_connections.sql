-- =============================================================================
-- Migration 00008: friends_connections
-- Zweck: Freunde suchen, Anfragen und Verbindungsliste (RPCs).
-- Betrifft: search_profiles, Connection-RPCs
-- =============================================================================
CREATE OR REPLACE FUNCTION public.search_profiles(p_query TEXT)
RETURNS TABLE (
    id UUID,
    username TEXT,
    avatar_url TEXT,
    bio TEXT,
    connection_status TEXT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_me UUID := auth.uid();
BEGIN
    IF v_me IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    IF p_query IS NULL OR LENGTH(TRIM(p_query)) < 2 THEN
        RAISE EXCEPTION 'Mindestens 2 Zeichen für die Suche';
    END IF;

    RETURN QUERY
    SELECT
        p.id,
        p.username,
        p.avatar_url,
        p.bio,
        (
            SELECT c.status::TEXT
            FROM public.connections c
            WHERE (c.user_id_1 = v_me AND c.user_id_2 = p.id)
               OR (c.user_id_2 = v_me AND c.user_id_1 = p.id)
            LIMIT 1
        ) AS connection_status
    FROM public.profiles p
    WHERE p.id <> v_me
      AND p.username ILIKE '%' || TRIM(p_query) || '%'
    ORDER BY p.username
    LIMIT 25;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_my_connections()
RETURNS TABLE (
    profile_id UUID,
    username TEXT,
    avatar_url TEXT,
    bio TEXT,
    status TEXT,
    connected_at TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_me UUID := auth.uid();
BEGIN
    IF v_me IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    RETURN QUERY
    SELECT
        CASE
            WHEN c.user_id_1 = v_me THEN c.user_id_2
            ELSE c.user_id_1
        END AS profile_id,
        p.username,
        p.avatar_url,
        p.bio,
        c.status::TEXT,
        c.created_at
    FROM public.connections c
    JOIN public.profiles p ON p.id = CASE
        WHEN c.user_id_1 = v_me THEN c.user_id_2
        ELSE c.user_id_1
    END
    WHERE c.user_id_1 = v_me OR c.user_id_2 = v_me
    ORDER BY c.status, p.username;
END;
$$;

CREATE OR REPLACE FUNCTION public.add_friend(p_profile_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_me UUID := auth.uid();
    v_u1 UUID;
    v_u2 UUID;
BEGIN
    IF v_me IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    IF p_profile_id = v_me THEN
        RAISE EXCEPTION 'Du kannst dich nicht selbst hinzufügen';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_profile_id) THEN
        RAISE EXCEPTION 'Profil nicht gefunden';
    END IF;

    SELECT np.user_id_1, np.user_id_2
    INTO v_u1, v_u2
    FROM public.normalize_connection_pair(v_me, p_profile_id) np;

    INSERT INTO public.connections (user_id_1, user_id_2, status)
    VALUES (v_u1, v_u2, 'friend')
    ON CONFLICT (user_id_1, user_id_2)
    DO UPDATE SET status = 'friend', updated_at = NOW();
END;
$$;

CREATE OR REPLACE FUNCTION public.add_acquaintance(p_profile_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_me UUID := auth.uid();
    v_u1 UUID;
    v_u2 UUID;
BEGIN
    IF v_me IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    IF p_profile_id = v_me THEN
        RAISE EXCEPTION 'Du kannst dich nicht selbst hinzufügen';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_profile_id) THEN
        RAISE EXCEPTION 'Profil nicht gefunden';
    END IF;

    SELECT np.user_id_1, np.user_id_2
    INTO v_u1, v_u2
    FROM public.normalize_connection_pair(v_me, p_profile_id) np;

    INSERT INTO public.connections (user_id_1, user_id_2, status)
    VALUES (v_u1, v_u2, 'acquaintance')
    ON CONFLICT (user_id_1, user_id_2)
    DO UPDATE SET status = 'acquaintance', updated_at = NOW();
END;
$$;

CREATE OR REPLACE FUNCTION public.remove_connection(p_profile_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_me UUID := auth.uid();
    v_u1 UUID;
    v_u2 UUID;
BEGIN
    IF v_me IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    SELECT np.user_id_1, np.user_id_2
    INTO v_u1, v_u2
    FROM public.normalize_connection_pair(v_me, p_profile_id) np;

    DELETE FROM public.connections
    WHERE user_id_1 = v_u1 AND user_id_2 = v_u2;
END;
$$;

GRANT EXECUTE ON FUNCTION public.search_profiles TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_connections TO authenticated;
GRANT EXECUTE ON FUNCTION public.add_friend TO authenticated;
GRANT EXECUTE ON FUNCTION public.add_acquaintance TO authenticated;
GRANT EXECUTE ON FUNCTION public.remove_connection TO authenticated;
