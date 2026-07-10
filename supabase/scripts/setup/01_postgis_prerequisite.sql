-- =============================================================================
-- Script: 01_postgis_prerequisite.sql
-- Zweck: setup
-- Zweck: Stellt PostGIS + pgcrypto bereit, bevor Geo-Migrationen laufen.
-- Betrifft: Extension postgis, Extension pgcrypto, Schema extensions (GRANTs)
-- Wann: Einmalig im SQL Editor, falls Fehler "type geography does not exist"
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

GRANT USAGE ON SCHEMA extensions TO postgres, anon, authenticated, service_role;

-- Prüfen (sollte eine Versionszeile zurückgeben):
SELECT postgis_version();
