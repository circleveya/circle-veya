-- ============================================================
-- Schnellfix: get_online_friends Rückgabetyp-Konflikt (42P13)
-- Einmal im SQL Editor ausführen, dann 00014 erneut starten.
-- ============================================================

DROP FUNCTION IF EXISTS public.get_online_friends();
DROP FUNCTION IF EXISTS public.get_trending_activities(INT);
DROP FUNCTION IF EXISTS public.get_recommended_activities(INT);

-- Anschließend komplette Datei ausführen:
-- supabase/migrations/20260708130014_sidebar_rpc_functions.sql

NOTIFY pgrst, 'reload schema';
