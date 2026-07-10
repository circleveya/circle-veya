-- =============================================================================
-- Migration 00001: create_profiles
-- Zweck: Erstellt public.profiles (1:1 zu auth.users) inkl. RLS.
-- Betrifft: ENUM user_type, Tabelle profiles, Trigger updated_at
-- =============================================================================
DO $$ BEGIN
    CREATE TYPE public.user_type AS ENUM ('standard', 'company');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.profiles (
    id              UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
    username        TEXT NOT NULL UNIQUE,
    avatar_url      TEXT,
    bio             TEXT,
    age             SMALLINT CHECK (age IS NULL OR (age >= 13 AND age <= 120)),
    location        GEOGRAPHY(POINT, 4326),
    user_type       public.user_type NOT NULL DEFAULT 'standard',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS profiles_username_idx ON public.profiles (username);
CREATE INDEX IF NOT EXISTS profiles_location_idx ON public.profiles USING GIST (location);

-- updated_at automatisch setzen
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_updated_at ON public.profiles;
CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- Profil bei Sign-Up automatisch anlegen
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

    -- Eindeutigkeit sicherstellen, falls Username bereits vergeben
    WHILE EXISTS (SELECT 1 FROM public.profiles WHERE username = v_username) LOOP
        v_username := v_username || '_' || SUBSTRING(NEW.id::TEXT, 1, 4);
    END LOOP;

    INSERT INTO public.profiles (id, username)
    VALUES (NEW.id, v_username);

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- Row Level Security
-- ============================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Profiles sind für eingeloggte User lesbar" ON public.profiles;
CREATE POLICY "Profiles sind für eingeloggte User lesbar"
    ON public.profiles
    FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "User können nur das eigene Profil bearbeiten" ON public.profiles;
CREATE POLICY "User können nur das eigene Profil bearbeiten"
    ON public.profiles
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "User können nur das eigene Profil löschen" ON public.profiles;
CREATE POLICY "User können nur das eigene Profil löschen"
    ON public.profiles
    FOR DELETE
    TO authenticated
    USING (auth.uid() = id);
