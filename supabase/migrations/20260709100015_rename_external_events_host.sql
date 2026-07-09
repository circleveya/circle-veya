-- System-Host für externe Events: circle_events → CircleVeya

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
