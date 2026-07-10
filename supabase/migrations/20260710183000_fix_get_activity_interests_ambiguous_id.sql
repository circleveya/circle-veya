-- Fix: column reference "id" is ambiguous in get_activity_interests
-- (RETURNS TABLE id vs activities.id in host check).

CREATE OR REPLACE FUNCTION public.get_activity_interests(p_activity_id UUID)
RETURNS TABLE (
    id UUID,
    profile_id UUID,
    username TEXT,
    avatar_url TEXT,
    message TEXT,
    status public.interest_status,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.activities a
        WHERE a.id = p_activity_id AND a.host_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Nur der Host kann Interessenten sehen';
    END IF;

    RETURN QUERY
    SELECT
        ai.id,
        ai.profile_id,
        p.username,
        p.avatar_url,
        ai.message,
        ai.status,
        ai.created_at
    FROM public.activity_interests ai
    JOIN public.profiles p ON p.id = ai.profile_id
    WHERE ai.activity_id = p_activity_id
    ORDER BY ai.created_at ASC;
END;
$$;
