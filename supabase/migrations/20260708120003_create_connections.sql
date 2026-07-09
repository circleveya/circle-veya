-- ============================================================
-- connections – Beziehungen zwischen Usern (Freunde / Bekannte)
-- ============================================================

DO $$ BEGIN
    CREATE TYPE public.connection_status AS ENUM ('friend', 'acquaintance');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.connections (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id_1   UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    user_id_2   UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    status      public.connection_status NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT connections_no_self_reference CHECK (user_id_1 <> user_id_2),
    CONSTRAINT connections_ordered_pair CHECK (user_id_1 < user_id_2),
    CONSTRAINT connections_unique_pair UNIQUE (user_id_1, user_id_2)
);

CREATE INDEX IF NOT EXISTS connections_user_id_1_idx ON public.connections (user_id_1);
CREATE INDEX IF NOT EXISTS connections_user_id_2_idx ON public.connections (user_id_2);

DROP TRIGGER IF EXISTS connections_updated_at ON public.connections;
CREATE TRIGGER connections_updated_at
    BEFORE UPDATE ON public.connections
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- Hilfsfunktion: normalisiertes User-Paar (kleinere UUID zuerst)
CREATE OR REPLACE FUNCTION public.normalize_connection_pair(
    p_user_a UUID,
    p_user_b UUID
)
RETURNS TABLE (user_id_1 UUID, user_id_2 UUID)
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    IF p_user_a < p_user_b THEN
        RETURN QUERY SELECT p_user_a, p_user_b;
    ELSE
        RETURN QUERY SELECT p_user_b, p_user_a;
    END IF;
END;
$$;

-- ============================================================
-- Row Level Security
-- ============================================================

ALTER TABLE public.connections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "User sehen eigene Verbindungen" ON public.connections;
CREATE POLICY "User sehen eigene Verbindungen"
    ON public.connections
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id_1 OR auth.uid() = user_id_2);

DROP POLICY IF EXISTS "User können Verbindungen erstellen, an denen sie beteiligt sind" ON public.connections;
CREATE POLICY "User können Verbindungen erstellen, an denen sie beteiligt sind"
    ON public.connections
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id_1 OR auth.uid() = user_id_2);

DROP POLICY IF EXISTS "User können eigene Verbindungen aktualisieren" ON public.connections;
CREATE POLICY "User können eigene Verbindungen aktualisieren"
    ON public.connections
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id_1 OR auth.uid() = user_id_2)
    WITH CHECK (auth.uid() = user_id_1 OR auth.uid() = user_id_2);

DROP POLICY IF EXISTS "User können eigene Verbindungen löschen" ON public.connections;
CREATE POLICY "User können eigene Verbindungen löschen"
    ON public.connections
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id_1 OR auth.uid() = user_id_2);
