-- Event-Shares in Chats als Rich-Link (WhatsApp-Style)

ALTER TABLE public.messages
  DROP CONSTRAINT IF EXISTS messages_message_type_check;

ALTER TABLE public.messages
  ADD CONSTRAINT messages_message_type_check
  CHECK (message_type = ANY (ARRAY['text', 'image', 'gif', 'activity_share']));

CREATE OR REPLACE FUNCTION public.update_chat_last_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_preview TEXT;
BEGIN
  IF NEW.message_type = 'activity_share' THEN
    BEGIN
      v_preview := COALESCE(
        NULLIF(TRIM(NEW.content::jsonb ->> 'caption'), ''),
        NULLIF(TRIM(NEW.content::jsonb ->> 'title'), ''),
        'Event'
      );
    EXCEPTION WHEN OTHERS THEN
      v_preview := 'Event';
    END;
  ELSIF NEW.message_type IN ('image', 'gif') THEN
    v_preview := CASE
      WHEN NULLIF(TRIM(NEW.content), '') IN ('Bild', 'GIF', ' ') THEN
        CASE NEW.message_type WHEN 'gif' THEN 'GIF' ELSE 'Bild' END
      ELSE LEFT(NEW.content, 120)
    END;
  ELSE
    v_preview := LEFT(NEW.content, 120);
  END IF;

  UPDATE public.chats
  SET last_message_at = NEW.created_at,
      last_message_preview = LEFT(v_preview, 120),
      updated_at = NOW()
  WHERE id = NEW.chat_id;

  RETURN NEW;
END;
$$;

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
  v_activity_id UUID;
  v_title TEXT;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  IF v_type NOT IN ('text', 'image', 'gif', 'activity_share') THEN
    RAISE EXCEPTION 'Ungültiger Nachrichtentyp';
  END IF;

  IF v_type = 'text' AND char_length(v_content) < 1 THEN
    RAISE EXCEPTION 'Nachricht darf nicht leer sein';
  END IF;

  IF v_type = 'activity_share' THEN
    BEGIN
      v_activity_id := (v_content::jsonb ->> 'activity_id')::UUID;
      v_title := NULLIF(TRIM(v_content::jsonb ->> 'title'), '');
    EXCEPTION WHEN OTHERS THEN
      RAISE EXCEPTION 'Ungültige Event-Nachricht';
    END;

    IF v_activity_id IS NULL OR v_title IS NULL THEN
      RAISE EXCEPTION 'Event-Titel oder ID fehlt';
    END IF;
  END IF;

  IF v_type IN ('image', 'gif')
     AND (p_media_url IS NULL OR TRIM(p_media_url) = '') THEN
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
    CASE
      WHEN v_type = 'text' THEN v_content
      WHEN v_type = 'activity_share' THEN v_content
      ELSE COALESCE(NULLIF(v_content, ''), ' ')
    END,
    v_type,
    p_media_url
  )
  RETURNING id INTO v_message_id;

  RETURN v_message_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.send_chat_message(UUID, TEXT, TEXT, TEXT) TO authenticated;
