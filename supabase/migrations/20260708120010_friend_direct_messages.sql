-- =============================================================================
-- Migration 00010: friend_direct_messages
-- Zweck: Erlaubt Freund-DMs ohne Aktivitaetsbezug.
-- Betrifft: chats Constraints, DM-RPCs
-- =============================================================================
ALTER TABLE public.chats
    DROP CONSTRAINT IF EXISTS chats_dm_requires_activity;

ALTER TABLE public.chats
    ADD CONSTRAINT chats_dm_requires_context
    CHECK (
        type <> 'direct'
        OR (
            activity_id IS NOT NULL
            AND activity_interest_id IS NOT NULL
        )
        OR (
            activity_id IS NULL
            AND activity_interest_id IS NULL
        )
    );

-- ============================================================
-- RPC: get_or_create_friend_chat
-- ============================================================

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
        RETURN v_chat_id;
    END IF;

    SELECT username INTO v_friend_username
    FROM public.profiles
    WHERE id = p_friend_id;

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

GRANT EXECUTE ON FUNCTION public.get_or_create_friend_chat(UUID) TO authenticated;
