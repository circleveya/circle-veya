-- Direct chats: always show the other participant's current username,
-- and re-activate soft-left participants when reopening a friend chat.

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
        CASE
            WHEN c.type = 'direct' THEN COALESCE(
                (
                    SELECT p.username
                    FROM public.chat_participants cp
                    JOIN public.profiles p ON p.id = cp.profile_id
                    WHERE cp.chat_id = c.id
                      AND cp.profile_id <> v_user_id
                    ORDER BY cp.left_at NULLS FIRST, cp.joined_at
                    LIMIT 1
                ),
                c.title
            )
            ELSE c.title
        END AS title,
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
            ORDER BY cp.left_at NULLS FIRST, cp.joined_at
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

CREATE OR REPLACE FUNCTION public.get_or_create_friend_chat(p_friend_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_friend_username TEXT;
    v_chat_id UUID;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    IF p_friend_id = v_user_id THEN
        RAISE EXCEPTION 'Du kannst dir selbst keine Nachricht senden';
    END IF;

    IF NOT public.is_friend(v_user_id, p_friend_id) THEN
        RAISE EXCEPTION 'Nur mit Freunden können Direktnachrichten gestartet werden';
    END IF;

    SELECT username INTO v_friend_username
    FROM public.profiles
    WHERE id = p_friend_id;

    SELECT c.id INTO v_chat_id
    FROM public.chats c
    WHERE c.type = 'direct'
      AND c.activity_id IS NULL
      AND c.activity_interest_id IS NULL
      AND (
          SELECT COUNT(*)::INT
          FROM public.chat_participants cp
          WHERE cp.chat_id = c.id
      ) = 2
      AND EXISTS (
          SELECT 1
          FROM public.chat_participants cp
          WHERE cp.chat_id = c.id
            AND cp.profile_id = v_user_id
      )
      AND EXISTS (
          SELECT 1
          FROM public.chat_participants cp
          WHERE cp.chat_id = c.id
            AND cp.profile_id = p_friend_id
      )
    LIMIT 1;

    IF v_chat_id IS NOT NULL THEN
        -- Soft-leave rückgängig machen und Titel auf aktuellen Freundesnamen setzen
        UPDATE public.chat_participants
        SET left_at = NULL
        WHERE chat_id = v_chat_id
          AND profile_id IN (v_user_id, p_friend_id)
          AND left_at IS NOT NULL;

        UPDATE public.chats
        SET title = COALESCE(v_friend_username, title)
        WHERE id = v_chat_id;

        RETURN v_chat_id;
    END IF;

    INSERT INTO public.chats (
        type,
        activity_id,
        activity_interest_id,
        title
    )
    VALUES (
        'direct',
        NULL,
        NULL,
        COALESCE(v_friend_username, 'Freund')
    )
    RETURNING id INTO v_chat_id;

    INSERT INTO public.chat_participants (chat_id, profile_id)
    VALUES
        (v_chat_id, v_user_id),
        (v_chat_id, p_friend_id);

    RETURN v_chat_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_my_chats() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_or_create_friend_chat(UUID) TO authenticated;
