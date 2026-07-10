-- =============================================================================
-- Migration 00005: create_chats
-- Zweck: Chat-Infrastruktur (Gruppenchat + Direct Messages) inkl. Realtime.
-- Betrifft: chats, chat_participants, messages
-- =============================================================================
CREATE TYPE public.chat_type AS ENUM ('activity_group', 'direct');

CREATE TABLE public.chats (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type                    public.chat_type NOT NULL,
    activity_id             UUID REFERENCES public.activities (id) ON DELETE CASCADE,
    activity_interest_id    UUID REFERENCES public.activity_interests (id) ON DELETE SET NULL,
    title                   TEXT NOT NULL,
    last_message_at         TIMESTAMPTZ,
    last_message_preview    TEXT,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chats_activity_group_requires_activity
        CHECK (type <> 'activity_group' OR activity_id IS NOT NULL),
    CONSTRAINT chats_dm_requires_activity
        CHECK (type <> 'direct' OR activity_id IS NOT NULL)
);

CREATE UNIQUE INDEX chats_one_group_per_activity_idx
    ON public.chats (activity_id)
    WHERE type = 'activity_group';

CREATE UNIQUE INDEX chats_one_dm_per_interest_idx
    ON public.chats (activity_interest_id)
    WHERE type = 'direct' AND activity_interest_id IS NOT NULL;

CREATE INDEX chats_activity_id_idx ON public.chats (activity_id);
CREATE INDEX chats_last_message_at_idx ON public.chats (last_message_at DESC NULLS LAST);

CREATE TRIGGER chats_updated_at
    BEFORE UPDATE ON public.chats
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- ============================================================
-- chat_participants
-- ============================================================

CREATE TABLE public.chat_participants (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id         UUID NOT NULL REFERENCES public.chats (id) ON DELETE CASCADE,
    profile_id      UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_read_at    TIMESTAMPTZ,
    CONSTRAINT chat_participants_unique UNIQUE (chat_id, profile_id)
);

CREATE INDEX chat_participants_profile_id_idx ON public.chat_participants (profile_id);
CREATE INDEX chat_participants_chat_id_idx ON public.chat_participants (chat_id);

-- ============================================================
-- messages
-- ============================================================

CREATE TABLE public.messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id         UUID NOT NULL REFERENCES public.chats (id) ON DELETE CASCADE,
    sender_id       UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
    content         TEXT NOT NULL CHECK (CHAR_LENGTH(content) BETWEEN 1 AND 4000),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    edited_at       TIMESTAMPTZ,
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX messages_chat_id_created_at_idx
    ON public.messages (chat_id, created_at DESC);

-- Realtime: vollständige Zeilen für Postgres Changes
ALTER TABLE public.messages REPLICA IDENTITY FULL;

-- ============================================================
-- Hilfsfunktionen
-- ============================================================

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
    );
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

    -- Gruppenchat erst ab 2 Teilnehmern (Host + mindestens 1 weiterer)
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

CREATE OR REPLACE FUNCTION public.sync_activity_group_chat_on_participant()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    PERFORM public.ensure_activity_group_chat(NEW.activity_id);
    RETURN NEW;
END;
$$;

CREATE TRIGGER activity_participants_sync_group_chat
    AFTER INSERT ON public.activity_participants
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_activity_group_chat_on_participant();

CREATE OR REPLACE FUNCTION public.update_chat_last_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE public.chats
    SET last_message_at = NEW.created_at,
        last_message_preview = LEFT(NEW.content, 120),
        updated_at = NOW()
    WHERE id = NEW.chat_id;

    RETURN NEW;
END;
$$;

CREATE TRIGGER messages_update_chat_preview
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.update_chat_last_message();

-- ============================================================
-- RPC: start_dm_chat (Host ↔ Interessent vor Zusage)
-- ============================================================

CREATE OR REPLACE FUNCTION public.start_dm_chat(p_interest_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_host_id UUID := auth.uid();
    v_activity_id UUID;
    v_interested_id UUID;
    v_interest_status public.interest_status;
    v_activity_title TEXT;
    v_interested_username TEXT;
    v_chat_id UUID;
BEGIN
    IF v_host_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    SELECT
        ai.activity_id,
        ai.profile_id,
        ai.status,
        a.title
    INTO v_activity_id, v_interested_id, v_interest_status, v_activity_title
    FROM public.activity_interests ai
    JOIN public.activities a ON a.id = ai.activity_id
    WHERE ai.id = p_interest_id
      AND a.host_id = v_host_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Interesse nicht gefunden oder kein Host';
    END IF;

    IF v_interest_status <> 'pending' THEN
        RAISE EXCEPTION 'DM nur bei ausstehendem Interesse möglich';
    END IF;

    SELECT id INTO v_chat_id
    FROM public.chats
    WHERE type = 'direct'
      AND activity_id = v_activity_id
      AND activity_interest_id = p_interest_id;

    IF v_chat_id IS NOT NULL THEN
        RETURN v_chat_id;
    END IF;

    SELECT username INTO v_interested_username
    FROM public.profiles
    WHERE id = v_interested_id;

    INSERT INTO public.chats (
        type,
        activity_id,
        activity_interest_id,
        title
    )
    VALUES (
        'direct',
        v_activity_id,
        p_interest_id,
        COALESCE(v_interested_username, 'DM') || ' · ' || v_activity_title
    )
    RETURNING id INTO v_chat_id;

    INSERT INTO public.chat_participants (chat_id, profile_id)
    VALUES
        (v_chat_id, v_host_id),
        (v_chat_id, v_interested_id);

    RETURN v_chat_id;
END;
$$;

-- ============================================================
-- RPC: get_my_chats
-- ============================================================

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
            LIMIT 1
        ) AS other_username
    FROM public.chats c
    WHERE EXISTS (
        SELECT 1
        FROM public.chat_participants cp
        WHERE cp.chat_id = c.id
          AND cp.profile_id = v_user_id
    )
    ORDER BY COALESCE(c.last_message_at, c.created_at) DESC;
END;
$$;

-- ============================================================
-- RPC: mark_chat_read
-- ============================================================

CREATE OR REPLACE FUNCTION public.mark_chat_read(p_chat_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE public.chat_participants
    SET last_read_at = NOW()
    WHERE chat_id = p_chat_id
      AND profile_id = auth.uid();
END;
$$;

-- ============================================================
-- RPC: get_activity_group_chat_id
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_activity_group_chat_id(p_activity_id UUID)
RETURNS UUID
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_chat_id UUID;
BEGIN
    IF NOT public.is_activity_participant(p_activity_id, auth.uid()) THEN
        RAISE EXCEPTION 'Nur Teilnehmer können den Gruppenchat sehen';
    END IF;

    SELECT c.id INTO v_chat_id
    FROM public.chats c
    WHERE c.activity_id = p_activity_id
      AND c.type = 'activity_group';

    RETURN v_chat_id;
END;
$$;

-- ============================================================
-- Row Level Security
-- ============================================================

ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Chats nur für Teilnehmer lesbar"
    ON public.chats
    FOR SELECT
    TO authenticated
    USING (public.is_chat_participant(id, auth.uid()));

CREATE POLICY "Chat-Teilnehmer nur für Mitglieder lesbar"
    ON public.chat_participants
    FOR SELECT
    TO authenticated
    USING (public.is_chat_participant(chat_id, auth.uid()));

CREATE POLICY "Nachrichten lesen als Chat-Teilnehmer"
    ON public.messages
    FOR SELECT
    TO authenticated
    USING (
        deleted_at IS NULL
        AND public.is_chat_participant(chat_id, auth.uid())
    );

CREATE POLICY "Nachrichten senden als Chat-Teilnehmer"
    ON public.messages
    FOR INSERT
    TO authenticated
    WITH CHECK (
        sender_id = auth.uid()
        AND public.is_chat_participant(chat_id, auth.uid())
    );

CREATE POLICY "Eigene Nachrichten bearbeiten"
    ON public.messages
    FOR UPDATE
    TO authenticated
    USING (sender_id = auth.uid())
    WITH CHECK (sender_id = auth.uid());

-- Realtime Publication
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;

GRANT EXECUTE ON FUNCTION public.start_dm_chat TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_chats TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_chat_read TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_activity_group_chat_id TO authenticated;
