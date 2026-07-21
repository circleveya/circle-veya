-- Öffentliches Level im Profil (ohne XP/Challenges).

DROP FUNCTION IF EXISTS public.get_profile(uuid);

CREATE OR REPLACE FUNCTION public.get_profile(p_profile_id UUID)
RETURNS TABLE (
  id UUID,
  username TEXT,
  avatar_url TEXT,
  cover_url TEXT,
  bio TEXT,
  age SMALLINT,
  interests TEXT[],
  user_type public.user_type,
  is_premium BOOLEAN,
  gallery_public BOOLEAN,
  level INTEGER
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
#variable_conflict use_column
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.username,
    p.avatar_url,
    p.cover_url,
    p.bio,
    p.age,
    p.interests,
    p.user_type,
    p.is_premium,
    p.gallery_public,
    COALESCE(us.level, 1)::INTEGER AS level
  FROM public.profiles p
  LEFT JOIN public.user_stats us ON us.profile_id = p.id
  WHERE p.id = p_profile_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_profile(uuid) TO authenticated;
