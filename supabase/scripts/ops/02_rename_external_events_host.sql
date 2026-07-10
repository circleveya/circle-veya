-- =============================================================================
-- Script: 02_rename_external_events_host.sql
-- Zweck: ops
-- Zweck: Benennt den System-Host von circle_events nach CircleVeya um.
-- Betrifft: public.profiles, RPC get_external_events_host_id()
-- Wann: Einmalig, falls noch der alte Username "circle_events" existiert
-- =============================================================================

UPDATE public.profiles
SET
    username = 'CircleVeya',
    bio = 'Offizielle Event-Quelle von CircleVeya – Ticketmaster & kuratierte Highlights.'
WHERE username = 'circle_events';

CREATE OR REPLACE FUNCTION public.get_external_events_host_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT id
    FROM public.profiles
    WHERE username = 'CircleVeya'
    LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION public.get_external_events_host_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_external_events_host_id() TO service_role;

-- Prüfen (darf nicht NULL sein):
SELECT id, username, user_type FROM public.profiles WHERE username = 'CircleVeya';
SELECT public.get_external_events_host_id() AS host_id;
