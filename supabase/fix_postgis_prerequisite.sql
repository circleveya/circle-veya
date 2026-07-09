-- ============================================================
-- PostGIS-Fix: VOR Migration 00013 / 00014 ausführen
-- Fehler: type "geography" does not exist (42704)
-- ============================================================

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

GRANT USAGE ON SCHEMA extensions TO postgres, anon, authenticated, service_role;

-- Prüfen (sollte "t" zurückgeben):
SELECT postgis_version();
