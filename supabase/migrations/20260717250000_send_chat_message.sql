-- Fix: soft-left participants couldn't send messages (RLS via is_chat_participant).
-- send_chat_message re-activates only the sender, then inserts.

CREATE OR REPLACE FUNCTION public.send_chat_message(
  p_chat_id UUID,
  p_content TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_content TEXT := TRIM(p_content);
  v_message_id UUID;
  v_is_member BOOLEAN;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  IF v_content IS NULL OR char_length(v_content) < 1 THEN
    RAISE EXCEPTION 'Nachricht darf nicht leer sein';
  END IF;

  IF char_length(v_content) > 4000 THEN
    RAISE EXCEPTION 'Nachricht ist zu lang';
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM public.chat_participants cp
    WHERE cp.chat_id = p_chat_id
      AND cp.profile_id = v_user_id
  ) INTO v_is_member;

  IF NOT v_is_member THEN
    RAISE EXCEPTION 'Keine Berechtigung für diesen Chat';
  END IF;

  -- Nur den Absender wieder aktivieren (nach soft-leave)
  UPDATE public.chat_participants
  SET left_at = NULL
  WHERE chat_id = p_chat_id
    AND profile_id = v_user_id
    AND left_at IS NOT NULL;

  INSERT INTO public.messages (chat_id, sender_id, content)
  VALUES (p_chat_id, v_user_id, v_content)
  RETURNING id INTO v_message_id;

  RETURN v_message_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.send_chat_message(UUID, TEXT) TO authenticated;
