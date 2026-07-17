-- Circle group management: detail, update, invite, roles, remove

CREATE OR REPLACE FUNCTION public.get_circle_group_detail(p_group_id UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  created_by UUID,
  source_activity_id UUID,
  member_count INT,
  my_role TEXT,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.circle_group_members m
    WHERE m.group_id = p_group_id AND m.profile_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Kein Zugriff auf diesen Kreis';
  END IF;

  RETURN QUERY
  SELECT
    g.id,
    g.name,
    g.description,
    g.created_by,
    g.source_activity_id,
    (SELECT COUNT(*)::INT FROM public.circle_group_members m WHERE m.group_id = g.id),
    cm.role,
    g.created_at
  FROM public.circle_groups g
  JOIN public.circle_group_members cm
    ON cm.group_id = g.id AND cm.profile_id = auth.uid()
  WHERE g.id = p_group_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_circle_group(
  p_group_id UUID,
  p_name TEXT,
  p_description TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  SELECT m.role INTO v_role
  FROM public.circle_group_members m
  WHERE m.group_id = p_group_id AND m.profile_id = auth.uid();

  IF v_role IS NULL OR v_role NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION 'Keine Berechtigung';
  END IF;

  IF trim(COALESCE(p_name, '')) = '' THEN
    RAISE EXCEPTION 'Name erforderlich';
  END IF;

  UPDATE public.circle_groups
  SET
    name = trim(p_name),
    description = NULLIF(trim(COALESCE(p_description, '')), '')
  WHERE id = p_group_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.add_circle_group_members(
  p_group_id UUID,
  p_member_ids UUID[] DEFAULT '{}'
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_role TEXT;
  v_member UUID;
  v_added INT := 0;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  SELECT m.role INTO v_role
  FROM public.circle_group_members m
  WHERE m.group_id = p_group_id AND m.profile_id = auth.uid();

  IF v_role IS NULL OR v_role NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION 'Keine Berechtigung';
  END IF;

  IF p_member_ids IS NOT NULL THEN
    FOREACH v_member IN ARRAY p_member_ids LOOP
      INSERT INTO public.circle_group_members (group_id, profile_id, role)
      VALUES (p_group_id, v_member, 'member')
      ON CONFLICT (group_id, profile_id) DO NOTHING;
      IF FOUND THEN
        v_added := v_added + 1;
      END IF;
    END LOOP;
  END IF;

  RETURN v_added;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_circle_group_member_role(
  p_group_id UUID,
  p_profile_id UUID,
  p_role TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_my_role TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  IF p_role NOT IN ('owner', 'admin', 'member') THEN
    RAISE EXCEPTION 'Ungültige Rolle';
  END IF;

  SELECT m.role INTO v_my_role
  FROM public.circle_group_members m
  WHERE m.group_id = p_group_id AND m.profile_id = auth.uid();

  IF v_my_role IS DISTINCT FROM 'owner' THEN
    RAISE EXCEPTION 'Nur der Owner kann Rollen setzen';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.circle_group_members m
    WHERE m.group_id = p_group_id AND m.profile_id = p_profile_id
  ) THEN
    RAISE EXCEPTION 'Mitglied nicht gefunden';
  END IF;

  IF p_role = 'owner' THEN
    UPDATE public.circle_group_members
    SET role = 'admin'
    WHERE group_id = p_group_id AND role = 'owner';

    UPDATE public.circle_group_members
    SET role = 'owner'
    WHERE group_id = p_group_id AND profile_id = p_profile_id;

    UPDATE public.circle_groups
    SET created_by = p_profile_id
    WHERE id = p_group_id;
  ELSE
    IF p_profile_id = auth.uid() THEN
      RAISE EXCEPTION 'Owner kann die eigene Rolle so nicht ändern';
    END IF;

    UPDATE public.circle_group_members
    SET role = p_role
    WHERE group_id = p_group_id AND profile_id = p_profile_id;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.remove_circle_group_member(
  p_group_id UUID,
  p_profile_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_my_role TEXT;
  v_target_role TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  IF p_profile_id = auth.uid() THEN
    RAISE EXCEPTION 'Du kannst dich nicht selbst entfernen';
  END IF;

  SELECT m.role INTO v_my_role
  FROM public.circle_group_members m
  WHERE m.group_id = p_group_id AND m.profile_id = auth.uid();

  SELECT m.role INTO v_target_role
  FROM public.circle_group_members m
  WHERE m.group_id = p_group_id AND m.profile_id = p_profile_id;

  IF v_target_role IS NULL THEN
    RAISE EXCEPTION 'Mitglied nicht gefunden';
  END IF;

  IF v_my_role = 'owner' THEN
    NULL;
  ELSIF v_my_role = 'admin' AND v_target_role = 'member' THEN
    NULL;
  ELSE
    RAISE EXCEPTION 'Keine Berechtigung';
  END IF;

  DELETE FROM public.circle_group_members
  WHERE group_id = p_group_id AND profile_id = p_profile_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_circle_group_detail(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_circle_group(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.add_circle_group_members(UUID, UUID[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_circle_group_member_role(UUID, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.remove_circle_group_member(UUID, UUID) TO authenticated;
