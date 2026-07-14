-- Soft-leave for chats so users can remove them from their list.

ALTER TABLE public.chat_participants
  ADD COLUMN IF NOT EXISTS left_at TIMESTAMPTZ;

CREATE OR REPLACE FUNCTION public.is_chat_participant(
    p_chat_id UUID,
    p_profile_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.chat_participants cp
        WHERE cp.chat_id = p_chat_id
          AND cp.profile_id = p_profile_id
          AND cp.left_at IS NULL
    );
$$;

CREATE OR REPLACE FUNCTION public.get_my_chats()
RETURNS TABLE (
    id UUID,
    type public.chat_type,
    activity_id UUID,
    title TEXT,
    last_message_at TIMESTAMPTZ,
    last_message_preview TEXT,
    unread_count BIGINT,
    other_username TEXT
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
        c.id,
        c.type,
        c.activity_id,
        c.title,
        c.last_message_at,
        c.last_message_preview,
        (
            SELECT COUNT(*)
            FROM public.messages m
            WHERE m.chat_id = c.id
              AND m.deleted_at IS NULL
              AND m.sender_id <> v_user_id
              AND m.created_at > COALESCE(
                  (
                      SELECT cp.last_read_at
                      FROM public.chat_participants cp
                      WHERE cp.chat_id = c.id
                        AND cp.profile_id = v_user_id
                        AND cp.left_at IS NULL
                  ),
                  '1970-01-01'::timestamptz
              )
        ) AS unread_count,
        (
            SELECT p.username
            FROM public.chat_participants cp
            JOIN public.profiles p ON p.id = cp.profile_id
            WHERE cp.chat_id = c.id
              AND cp.profile_id <> v_user_id
              AND cp.left_at IS NULL
            LIMIT 1
        ) AS other_username
    FROM public.chats c
    WHERE EXISTS (
        SELECT 1
        FROM public.chat_participants cp
        WHERE cp.chat_id = c.id
          AND cp.profile_id = v_user_id
          AND cp.left_at IS NULL
    )
    ORDER BY COALESCE(c.last_message_at, c.created_at) DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.leave_chat(p_chat_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := auth.uid();
    v_type public.chat_type;
    v_active_count INT;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM public.chat_participants
        WHERE chat_id = p_chat_id
          AND profile_id = v_uid
          AND left_at IS NULL
    ) THEN
        RAISE EXCEPTION 'Chat nicht gefunden';
    END IF;

    UPDATE public.chat_participants
    SET left_at = NOW()
    WHERE chat_id = p_chat_id
      AND profile_id = v_uid
      AND left_at IS NULL;

    SELECT c.type INTO v_type FROM public.chats c WHERE c.id = p_chat_id;

    SELECT COUNT(*) INTO v_active_count
    FROM public.chat_participants
    WHERE chat_id = p_chat_id AND left_at IS NULL;

    IF v_type = 'direct' AND v_active_count = 0 THEN
        DELETE FROM public.chats WHERE id = p_chat_id;
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.ensure_activity_group_chat(p_activity_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_chat_id UUID;
    v_title TEXT;
    v_participant_count INT;
BEGIN
    SELECT COUNT(*) INTO v_participant_count
    FROM public.activity_participants
    WHERE activity_id = p_activity_id;

    IF v_participant_count < 2 THEN
        RETURN NULL;
    END IF;

    SELECT c.id INTO v_chat_id
    FROM public.chats c
    WHERE c.activity_id = p_activity_id
      AND c.type = 'activity_group';

    IF v_chat_id IS NULL THEN
        SELECT a.title INTO v_title
        FROM public.activities a
        WHERE a.id = p_activity_id;

        INSERT INTO public.chats (type, activity_id, title)
        VALUES ('activity_group', p_activity_id, COALESCE(v_title, 'Gruppenchat'))
        RETURNING id INTO v_chat_id;
    END IF;

    INSERT INTO public.chat_participants (chat_id, profile_id)
    SELECT v_chat_id, ap.profile_id
    FROM public.activity_participants ap
    WHERE ap.activity_id = p_activity_id
    ON CONFLICT (chat_id, profile_id) DO NOTHING;

    RETURN v_chat_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.leave_chat(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_chats() TO authenticated;
