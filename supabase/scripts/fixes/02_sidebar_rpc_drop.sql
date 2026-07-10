-- =============================================================================
-- Script: 02_sidebar_rpc_drop.sql
-- Zweck: fixes
-- Zweck: Droppt Sidebar-RPCs bei Rückgabetyp-Konflikt (42P13), vor Neu-Deploy.
-- Betrifft: get_online_friends, get_trending_activities, get_recommended_activities
-- Wann: Vor erneut-Ausführen von migrations/…130014_sidebar_rpc_functions.sql
-- =============================================================================

DROP FUNCTION IF EXISTS public.get_online_friends();
DROP FUNCTION IF EXISTS public.get_trending_activities(INT);
DROP FUNCTION IF EXISTS public.get_recommended_activities(INT);

-- Anschliessend ausführen:
-- supabase/migrations/20260708130014_sidebar_rpc_functions.sql

NOTIFY pgrst, 'reload schema';
