-- PostGIS für GPS/Geo-Queries
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

GRANT USAGE ON SCHEMA extensions TO postgres, anon, authenticated, service_role;
