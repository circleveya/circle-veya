-- Chat-Liste: Avatar des Gegenübers / Gruppenbild / Aktivitätsbild

DROP FUNCTION IF EXISTS public.get_my_chats();

CREATE OR REPLACE FUNCTION public.get_my_chats()
RETURNS TABLE (
    id UUID,
    type public.chat_type,
    activity_id UUID,
    circle_group_id UUID,
    title TEXT,
    last_message_at TIMESTAMPTZ,
    last_message_preview TEXT,
    unread_count BIGINT,
    other_username TEXT,
    avatar_url TEXT
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
        c.circle_group_id,
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
        ) AS other_username,
        CASE
            WHEN c.type = 'direct' THEN (
                SELECT p.avatar_url
                FROM public.chat_participants cp
                JOIN public.profiles p ON p.id = cp.profile_id
                WHERE cp.chat_id = c.id
                  AND cp.profile_id <> v_user_id
                ORDER BY cp.left_at NULLS FIRST, cp.joined_at
                LIMIT 1
            )
            WHEN c.type = 'circle_group' THEN (
                SELECT g.image_url
                FROM public.circle_groups g
                WHERE g.id = c.circle_group_id
            )
            WHEN c.type = 'activity_group' THEN (
                SELECT a.image_url
                FROM public.activities a
                WHERE a.id = c.activity_id
            )
            ELSE NULL
        END AS avatar_url
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

GRANT EXECUTE ON FUNCTION public.get_my_chats() TO authenticated;

NOTIFY pgrst, 'reload schema';
