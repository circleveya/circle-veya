-- Founder-Badge (CircleVeya + Don) und get_profile-Erweiterung

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_founder BOOLEAN NOT NULL DEFAULT false;

UPDATE public.profiles
SET is_founder = true
WHERE id = 'eb0f85c8-18ad-4770-8c14-a5a862fcd572'
   OR lower(username) IN ('don', 'circleveya');

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
  is_founder BOOLEAN,
  gallery_public BOOLEAN,
  level INTEGER,
  followed_by_me BOOLEAN,
  follower_count INTEGER
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
#variable_conflict use_column
DECLARE
  v_me UUID := auth.uid();
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
    p.is_founder,
    p.gallery_public,
    CASE
      WHEN public.is_business_profile_type(p.user_type) THEN NULL
      ELSE COALESCE(us.level, 1)::INTEGER
    END AS level,
    EXISTS (
      SELECT 1
      FROM public.company_follows f
      WHERE f.follower_id = v_me AND f.company_id = p.id
    ) AS followed_by_me,
    (
      SELECT COUNT(*)::INTEGER
      FROM public.company_follows f
      WHERE f.company_id = p.id
    ) AS follower_count
  FROM public.profiles p
  LEFT JOIN public.user_stats us ON us.profile_id = p.id
  WHERE p.id = p_profile_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_profile(uuid) TO authenticated;

NOTIFY pgrst, 'reload schema';
