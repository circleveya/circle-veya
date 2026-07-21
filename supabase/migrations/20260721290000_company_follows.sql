-- Unternehmen folgen (unidirektional, getrennt von Freunden).

CREATE TABLE IF NOT EXISTS public.company_follows (
  follower_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (follower_id, company_id),
  CONSTRAINT company_follows_no_self CHECK (follower_id <> company_id)
);

CREATE INDEX IF NOT EXISTS company_follows_company_idx
  ON public.company_follows (company_id);

CREATE INDEX IF NOT EXISTS company_follows_follower_idx
  ON public.company_follows (follower_id);

ALTER TABLE public.company_follows ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS company_follows_select ON public.company_follows;
CREATE POLICY company_follows_select ON public.company_follows
  FOR SELECT TO authenticated
  USING (follower_id = auth.uid() OR company_id = auth.uid());

DROP POLICY IF EXISTS company_follows_insert ON public.company_follows;
CREATE POLICY company_follows_insert ON public.company_follows
  FOR INSERT TO authenticated
  WITH CHECK (follower_id = auth.uid());

DROP POLICY IF EXISTS company_follows_delete ON public.company_follows;
CREATE POLICY company_follows_delete ON public.company_follows
  FOR DELETE TO authenticated
  USING (follower_id = auth.uid());

CREATE OR REPLACE FUNCTION public.is_business_profile_type(p_type public.user_type)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT p_type IN ('event', 'company');
$$;

CREATE OR REPLACE FUNCTION public.follow_company(p_company_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_me UUID := auth.uid();
  v_type public.user_type;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;
  IF p_company_id IS NULL OR p_company_id = v_me THEN
    RAISE EXCEPTION 'Ungültiges Unternehmen';
  END IF;

  SELECT user_type INTO v_type FROM public.profiles WHERE id = p_company_id;
  IF v_type IS NULL THEN
    RAISE EXCEPTION 'Profil nicht gefunden';
  END IF;
  IF NOT public.is_business_profile_type(v_type) THEN
    RAISE EXCEPTION 'Nur Event-/Unternehmens-Profile können gefolgt werden';
  END IF;

  INSERT INTO public.company_follows (follower_id, company_id)
  VALUES (v_me, p_company_id)
  ON CONFLICT DO NOTHING;
END;
$$;

CREATE OR REPLACE FUNCTION public.unfollow_company(p_company_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_me UUID := auth.uid();
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  DELETE FROM public.company_follows
  WHERE follower_id = v_me AND company_id = p_company_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_my_followed_companies()
RETURNS TABLE (
  profile_id UUID,
  username TEXT,
  avatar_url TEXT,
  bio TEXT,
  user_type public.user_type,
  followed_at TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_me UUID := auth.uid();
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  RETURN QUERY
  SELECT
    p.id,
    p.username,
    p.avatar_url,
    p.bio,
    p.user_type,
    f.created_at
  FROM public.company_follows f
  JOIN public.profiles p ON p.id = f.company_id
  WHERE f.follower_id = v_me
  ORDER BY f.created_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.follow_company(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.unfollow_company(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_followed_companies() TO authenticated;

-- get_profile: Level + Follow-Status
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

-- Suche: user_type + is_following
DROP FUNCTION IF EXISTS public.search_profiles(text);

CREATE OR REPLACE FUNCTION public.search_profiles(p_query text)
RETURNS TABLE (
  id uuid,
  username text,
  avatar_url text,
  bio text,
  connection_status text,
  user_type public.user_type,
  is_following boolean
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_me UUID := auth.uid();
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  IF p_query IS NULL OR LENGTH(TRIM(p_query)) < 2 THEN
    RAISE EXCEPTION 'Mindestens 2 Zeichen für die Suche';
  END IF;

  RETURN QUERY
  SELECT
    p.id,
    p.username,
    p.avatar_url,
    p.bio,
    (
      SELECT c.status::TEXT
      FROM public.connections c
      WHERE (c.user_id_1 = v_me AND c.user_id_2 = p.id)
         OR (c.user_id_2 = v_me AND c.user_id_1 = p.id)
      LIMIT 1
    ) AS connection_status,
    p.user_type,
    EXISTS (
      SELECT 1 FROM public.company_follows f
      WHERE f.follower_id = v_me AND f.company_id = p.id
    ) AS is_following
  FROM public.profiles p
  WHERE p.id <> v_me
    AND p.username ILIKE '%' || TRIM(p_query) || '%'
  ORDER BY p.username
  LIMIT 25;
END;
$$;

GRANT EXECUTE ON FUNCTION public.search_profiles(text) TO authenticated;
