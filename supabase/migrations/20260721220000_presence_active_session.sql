-- Online only while actively on the site (fresh heartbeat)

CREATE OR REPLACE FUNCTION public.heartbeat_presence()
RETURNS VOID
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  -- Veraltete Sessions sofort bereinigen
  UPDATE public.profiles
  SET is_online = false
  WHERE is_online = true
    AND last_seen < NOW() - INTERVAL '90 seconds'
    AND id <> auth.uid();

  UPDATE public.profiles
  SET is_online = true,
      last_seen = NOW()
  WHERE id = auth.uid();
END;
$$;

CREATE OR REPLACE FUNCTION public.leave_presence()
RETURNS VOID
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN;
  END IF;

  UPDATE public.profiles
  SET is_online = false,
      last_seen = NOW()
  WHERE id = auth.uid();
END;
$$;

CREATE OR REPLACE FUNCTION public.get_online_friends()
RETURNS TABLE (
  profile_id UUID,
  username TEXT,
  avatar_url TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    p.id AS profile_id,
    p.username,
    p.avatar_url
  FROM public.connections c
  JOIN public.profiles p ON p.id = CASE
    WHEN c.user_id_1 = auth.uid() THEN c.user_id_2
    ELSE c.user_id_1
  END
  WHERE c.status = 'friend'
    AND (c.user_id_1 = auth.uid() OR c.user_id_2 = auth.uid())
    AND p.is_online = true
    AND p.last_seen > NOW() - INTERVAL '90 seconds'
  ORDER BY p.last_seen DESC
  LIMIT 12;
$$;

UPDATE public.profiles
SET is_online = false
WHERE is_online = true
  AND last_seen < NOW() - INTERVAL '90 seconds';

GRANT EXECUTE ON FUNCTION public.heartbeat_presence() TO authenticated;
GRANT EXECUTE ON FUNCTION public.leave_presence() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_online_friends() TO authenticated;

NOTIFY pgrst, 'reload schema';
