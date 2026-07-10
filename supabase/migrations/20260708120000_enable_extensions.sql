-- =============================================================================
-- Migration 00000: enable_extensions
-- Zweck: Aktiviert PostGIS und pgcrypto fuer Geo- und Crypto-Funktionen.
-- Betrifft: Extensions postgis, pgcrypto; Schema extensions (GRANTs)
-- =============================================================================
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

GRANT USAGE ON SCHEMA extensions TO postgres, anon, authenticated, service_role;
