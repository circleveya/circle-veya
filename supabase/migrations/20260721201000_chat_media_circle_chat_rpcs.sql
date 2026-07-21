-- RPCs: circle group chat, send media messages, wallpaper, members_can_post

CREATE OR REPLACE FUNCTION public.get_or_create_circle_group_chat(p_group_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_chat_id UUID;
  v_title TEXT;
  v_role TEXT;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  SELECT m.role INTO v_role
  FROM public.circle_group_members m
  WHERE m.group_id = p_group_id AND m.profile_id = v_user_id;

  IF v_role IS NULL THEN
    RAISE EXCEPTION 'Kein Mitglied dieses Kreises';
  END IF;

  SELECT c.id INTO v_chat_id
  FROM public.chats c
  WHERE c.circle_group_id = p_group_id
  LIMIT 1;

  IF v_chat_id IS NULL THEN
    SELECT g.name INTO v_title
    FROM public.circle_groups g
    WHERE g.id = p_group_id;

    INSERT INTO public.chats (type, circle_group_id, title)
    VALUES ('circle_group', p_group_id, COALESCE(v_title, 'Kreis-Chat'))
    RETURNING id INTO v_chat_id;
  END IF;

  -- Sync all members into chat_participants
  INSERT INTO public.chat_participants (chat_id, profile_id)
  SELECT v_chat_id, m.profile_id
  FROM public.circle_group_members m
  WHERE m.group_id = p_group_id
  ON CONFLICT (chat_id, profile_id) DO UPDATE
    SET left_at = NULL;

  RETURN v_chat_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_or_create_circle_group_chat(UUID) TO authenticated;

-- Extend update_circle_group with members_can_post
CREATE OR REPLACE FUNCTION public.update_circle_group(
  p_group_id UUID,
  p_name TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_members_can_post BOOLEAN DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_role TEXT;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  SELECT m.role INTO v_role
  FROM public.circle_group_members m
  WHERE m.group_id = p_group_id AND m.profile_id = v_user_id;

  IF v_role IS NULL OR v_role NOT IN ('owner', 'admin') THEN
    RAISE EXCEPTION 'Keine Berechtigung';
  END IF;

  UPDATE public.circle_groups
  SET
    name = COALESCE(NULLIF(TRIM(p_name), ''), name),
    description = CASE
      WHEN p_description IS NULL THEN description
      ELSE NULLIF(TRIM(p_description), '')
    END,
    members_can_post = COALESCE(p_members_can_post, members_can_post)
  WHERE id = p_group_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_circle_group(UUID, TEXT, TEXT, BOOLEAN) TO authenticated;

-- Detail RPC must return members_can_post (drop + recreate)
DROP FUNCTION IF EXISTS public.get_circle_group_detail(UUID);

CREATE OR REPLACE FUNCTION public.get_circle_group_detail(p_group_id UUID)
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  created_by UUID,
  source_activity_id UUID,
  member_count INT,
  my_role TEXT,
  created_at TIMESTAMPTZ,
  image_url TEXT,
  members_can_post BOOLEAN
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.circle_group_members m
    WHERE m.group_id = p_group_id AND m.profile_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'Kein Mitglied dieses Kreises';
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
    g.created_at,
    g.image_url,
    g.members_can_post
  FROM public.circle_groups g
  JOIN public.circle_group_members cm
    ON cm.group_id = g.id AND cm.profile_id = v_user_id
  WHERE g.id = p_group_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_circle_group_detail(UUID) TO authenticated;

DROP FUNCTION IF EXISTS public.get_my_circle_groups();

CREATE OR REPLACE FUNCTION public.get_my_circle_groups()
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  created_by UUID,
  source_activity_id UUID,
  member_count INT,
  my_role TEXT,
  created_at TIMESTAMPTZ,
  image_url TEXT,
  members_can_post BOOLEAN
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
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
    g.created_at,
    g.image_url,
    g.members_can_post
  FROM public.circle_groups g
  JOIN public.circle_group_members cm
    ON cm.group_id = g.id AND cm.profile_id = v_user_id
  ORDER BY g.created_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_circle_groups() TO authenticated;

-- Send message with media + post permission check
CREATE OR REPLACE FUNCTION public.send_chat_message(
  p_chat_id UUID,
  p_content TEXT,
  p_message_type TEXT DEFAULT 'text',
  p_media_url TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_content TEXT := TRIM(COALESCE(p_content, ''));
  v_type TEXT := COALESCE(NULLIF(TRIM(p_message_type), ''), 'text');
  v_message_id UUID;
  v_is_member BOOLEAN;
  v_circle_group_id UUID;
  v_members_can_post BOOLEAN;
  v_role TEXT;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  IF v_type NOT IN ('text', 'image', 'gif') THEN
    RAISE EXCEPTION 'Ungültiger Nachrichtentyp';
  END IF;

  IF v_type = 'text' AND char_length(v_content) < 1 THEN
    RAISE EXCEPTION 'Nachricht darf nicht leer sein';
  END IF;

  IF v_type <> 'text' AND (p_media_url IS NULL OR TRIM(p_media_url) = '') THEN
    RAISE EXCEPTION 'Medien-URL fehlt';
  END IF;

  IF char_length(v_content) > 4000 THEN
    RAISE EXCEPTION 'Nachricht ist zu lang';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.chat_participants cp
    WHERE cp.chat_id = p_chat_id AND cp.profile_id = v_user_id
  ) INTO v_is_member;

  IF NOT v_is_member THEN
    RAISE EXCEPTION 'Keine Berechtigung für diesen Chat';
  END IF;

  UPDATE public.chat_participants
  SET left_at = NULL
  WHERE chat_id = p_chat_id
    AND profile_id = v_user_id
    AND left_at IS NOT NULL;

  SELECT c.circle_group_id INTO v_circle_group_id
  FROM public.chats c
  WHERE c.id = p_chat_id;

  IF v_circle_group_id IS NOT NULL THEN
    SELECT g.members_can_post INTO v_members_can_post
    FROM public.circle_groups g
    WHERE g.id = v_circle_group_id;

    IF v_members_can_post IS NOT TRUE THEN
      SELECT m.role INTO v_role
      FROM public.circle_group_members m
      WHERE m.group_id = v_circle_group_id AND m.profile_id = v_user_id;

      IF v_role IS NULL OR v_role NOT IN ('owner', 'admin') THEN
        RAISE EXCEPTION 'Nur Admins dürfen in diesem Kreis schreiben';
      END IF;
    END IF;
  END IF;

  INSERT INTO public.messages (chat_id, sender_id, content, message_type, media_url)
  VALUES (
    p_chat_id,
    v_user_id,
    CASE WHEN v_type = 'text' THEN v_content ELSE COALESCE(NULLIF(v_content, ''), ' ') END,
    v_type,
    p_media_url
  )
  RETURNING id INTO v_message_id;

  RETURN v_message_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.send_chat_message(UUID, TEXT, TEXT, TEXT) TO authenticated;

-- Keep 2-arg overload working for older clients
CREATE OR REPLACE FUNCTION public.send_chat_message(p_chat_id UUID, p_content TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN public.send_chat_message(p_chat_id, p_content, 'text', NULL);
END;
$$;

GRANT EXECUTE ON FUNCTION public.send_chat_message(UUID, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.set_my_chat_wallpaper(
  p_chat_id UUID,
  p_wallpaper_url TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  IF NOT public.is_chat_participant(p_chat_id, v_user_id) THEN
    RAISE EXCEPTION 'Keine Berechtigung für diesen Chat';
  END IF;

  UPDATE public.chat_participants
  SET wallpaper_url = NULLIF(TRIM(p_wallpaper_url), '')
  WHERE chat_id = p_chat_id AND profile_id = v_user_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.set_my_chat_wallpaper(UUID, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.get_my_chat_wallpaper(p_chat_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_url TEXT;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  SELECT cp.wallpaper_url INTO v_url
  FROM public.chat_participants cp
  WHERE cp.chat_id = p_chat_id
    AND cp.profile_id = v_user_id
    AND cp.left_at IS NULL;

  RETURN v_url;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_chat_wallpaper(UUID) TO authenticated;
