-- Circle Gruppen: manuell + aus gehosteter Aktivität

CREATE TABLE IF NOT EXISTS public.circle_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL CHECK (char_length(trim(name)) BETWEEN 1 AND 80),
  description TEXT,
  created_by UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  source_activity_id UUID REFERENCES public.activities (id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.circle_group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.circle_groups (id) ON DELETE CASCADE,
  profile_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT circle_group_members_unique UNIQUE (group_id, profile_id)
);

CREATE INDEX IF NOT EXISTS circle_groups_created_by_idx ON public.circle_groups (created_by);
CREATE INDEX IF NOT EXISTS circle_groups_source_activity_idx ON public.circle_groups (source_activity_id);
CREATE INDEX IF NOT EXISTS circle_group_members_profile_idx ON public.circle_group_members (profile_id);
CREATE INDEX IF NOT EXISTS circle_group_members_group_idx ON public.circle_group_members (group_id);

ALTER TABLE public.circle_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.circle_group_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Mitglieder lesen Gruppen" ON public.circle_groups;
CREATE POLICY "Mitglieder lesen Gruppen"
  ON public.circle_groups FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.circle_group_members m
      WHERE m.group_id = circle_groups.id AND m.profile_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Mitglieder lesen Member" ON public.circle_group_members;
CREATE POLICY "Mitglieder lesen Member"
  ON public.circle_group_members FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.circle_group_members m
      WHERE m.group_id = circle_group_members.group_id AND m.profile_id = auth.uid()
    )
  );

CREATE OR REPLACE FUNCTION public.get_my_circle_groups()
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
  ORDER BY g.created_at DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_circle_group_members(p_group_id UUID)
RETURNS TABLE (
  profile_id UUID,
  username TEXT,
  avatar_url TEXT,
  role TEXT,
  joined_at TIMESTAMPTZ
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
    RAISE EXCEPTION 'Kein Zugriff auf diese Gruppe';
  END IF;

  RETURN QUERY
  SELECT
    m.profile_id,
    p.username,
    p.avatar_url,
    m.role,
    m.joined_at
  FROM public.circle_group_members m
  JOIN public.profiles p ON p.id = m.profile_id
  WHERE m.group_id = p_group_id
  ORDER BY
    CASE m.role WHEN 'owner' THEN 0 WHEN 'admin' THEN 1 ELSE 2 END,
    m.joined_at ASC;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_circle_group(
  p_name TEXT,
  p_description TEXT DEFAULT NULL,
  p_member_ids UUID[] DEFAULT '{}'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_group_id UUID;
  v_member UUID;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  IF trim(COALESCE(p_name, '')) = '' THEN
    RAISE EXCEPTION 'Gruppenname erforderlich';
  END IF;

  INSERT INTO public.circle_groups (name, description, created_by)
  VALUES (trim(p_name), NULLIF(trim(COALESCE(p_description, '')), ''), v_uid)
  RETURNING id INTO v_group_id;

  INSERT INTO public.circle_group_members (group_id, profile_id, role)
  VALUES (v_group_id, v_uid, 'owner');

  IF p_member_ids IS NOT NULL THEN
    FOREACH v_member IN ARRAY p_member_ids LOOP
      IF v_member IS DISTINCT FROM v_uid THEN
        INSERT INTO public.circle_group_members (group_id, profile_id, role)
        VALUES (v_group_id, v_member, 'member')
        ON CONFLICT (group_id, profile_id) DO NOTHING;
      END IF;
    END LOOP;
  END IF;

  RETURN v_group_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_activity_participants(p_activity_id UUID)
RETURNS TABLE (
  profile_id UUID,
  username TEXT,
  avatar_url TEXT,
  joined_via TEXT,
  joined_at TIMESTAMPTZ
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
    SELECT 1 FROM public.activities a
    WHERE a.id = p_activity_id
      AND (
        a.host_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM public.activity_participants ap
          WHERE ap.activity_id = p_activity_id AND ap.profile_id = auth.uid()
        )
      )
  ) THEN
    RAISE EXCEPTION 'Kein Zugriff auf Teilnehmer';
  END IF;

  RETURN QUERY
  SELECT
    ap.profile_id,
    p.username,
    p.avatar_url,
    ap.joined_via::TEXT,
    ap.joined_at
  FROM public.activity_participants ap
  JOIN public.profiles p ON p.id = ap.profile_id
  WHERE ap.activity_id = p_activity_id
  ORDER BY ap.joined_at ASC;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_circle_group_from_activity(
  p_activity_id UUID,
  p_name TEXT DEFAULT NULL,
  p_include_pending_interests BOOLEAN DEFAULT FALSE
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_host_id UUID;
  v_title TEXT;
  v_group_id UUID;
  v_name TEXT;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  SELECT a.host_id, a.title
  INTO v_host_id, v_title
  FROM public.activities a
  WHERE a.id = p_activity_id AND a.status <> 'cancelled';

  IF v_host_id IS NULL THEN
    RAISE EXCEPTION 'Aktivität nicht gefunden';
  END IF;

  IF v_host_id <> v_uid THEN
    RAISE EXCEPTION 'Nur der Host kann eine Gruppe aus der Aktivität erstellen';
  END IF;

  v_name := COALESCE(NULLIF(trim(COALESCE(p_name, '')), ''), 'Gruppe: ' || v_title);
  IF char_length(v_name) > 80 THEN
    v_name := left(v_name, 80);
  END IF;

  INSERT INTO public.circle_groups (name, description, created_by, source_activity_id)
  VALUES (
    v_name,
    'Aus Aktivität „' || v_title || '“ erstellt',
    v_uid,
    p_activity_id
  )
  RETURNING id INTO v_group_id;

  INSERT INTO public.circle_group_members (group_id, profile_id, role)
  VALUES (v_group_id, v_uid, 'owner');

  INSERT INTO public.circle_group_members (group_id, profile_id, role)
  SELECT v_group_id, ap.profile_id, 'member'
  FROM public.activity_participants ap
  WHERE ap.activity_id = p_activity_id
    AND ap.profile_id <> v_uid
  ON CONFLICT (group_id, profile_id) DO NOTHING;

  INSERT INTO public.circle_group_members (group_id, profile_id, role)
  SELECT v_group_id, ai.profile_id, 'member'
  FROM public.activity_interests ai
  WHERE ai.activity_id = p_activity_id
    AND ai.status = 'accepted'
    AND ai.profile_id <> v_uid
  ON CONFLICT (group_id, profile_id) DO NOTHING;

  IF COALESCE(p_include_pending_interests, FALSE) THEN
    INSERT INTO public.circle_group_members (group_id, profile_id, role)
    SELECT v_group_id, ai.profile_id, 'member'
    FROM public.activity_interests ai
    WHERE ai.activity_id = p_activity_id
      AND ai.status = 'pending'
      AND ai.profile_id <> v_uid
    ON CONFLICT (group_id, profile_id) DO NOTHING;
  END IF;

  RETURN v_group_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_circle_groups() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_circle_group_members(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_circle_group(TEXT, TEXT, UUID[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_activity_participants(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_circle_group_from_activity(UUID, TEXT, BOOLEAN) TO authenticated;
