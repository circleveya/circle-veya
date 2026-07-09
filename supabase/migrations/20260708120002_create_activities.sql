-- ============================================================
-- activities – von Usern erstellte Aktivitäten
-- ============================================================

DO $$ BEGIN
    CREATE TYPE public.weather_category AS ENUM ('indoor', 'outdoor', 'rain');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.activities (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_id                 UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    title                   TEXT NOT NULL CHECK (CHAR_LENGTH(title) BETWEEN 3 AND 120),
    description             TEXT,
    max_participants        INT CHECK (max_participants IS NULL OR max_participants > 0),
    current_participants    INT NOT NULL DEFAULT 0 CHECK (current_participants >= 0),
    date_time               TIMESTAMPTZ NOT NULL,
    location_geo            GEOGRAPHY(POINT, 4326),
    weather_category        public.weather_category NOT NULL DEFAULT 'outdoor',
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT activities_participants_limit
        CHECK (max_participants IS NULL OR current_participants <= max_participants)
);

CREATE INDEX IF NOT EXISTS activities_host_id_idx ON public.activities (host_id);
CREATE INDEX IF NOT EXISTS activities_date_time_idx ON public.activities (date_time);
CREATE INDEX IF NOT EXISTS activities_location_geo_idx ON public.activities USING GIST (location_geo);

DROP TRIGGER IF EXISTS activities_updated_at ON public.activities;
CREATE TRIGGER activities_updated_at
    BEFORE UPDATE ON public.activities
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- Row Level Security
-- ============================================================

ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Aktivitäten sind für eingeloggte User lesbar" ON public.activities;
CREATE POLICY "Aktivitäten sind für eingeloggte User lesbar"
    ON public.activities
    FOR SELECT
    TO authenticated
    USING (true);

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
