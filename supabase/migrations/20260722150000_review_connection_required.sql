-- Bewertungen: Privatpersonen nur für Freunde/Bekannte, Firmen für alle

CREATE OR REPLACE FUNCTION public.can_review_profile(
    p_reviewer_id UUID,
    p_target_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_type public.user_type;
BEGIN
    IF p_reviewer_id IS NULL OR p_target_id IS NULL THEN
        RETURN FALSE;
    END IF;

    IF p_reviewer_id = p_target_id THEN
        RETURN FALSE;
    END IF;

    SELECT user_type INTO v_user_type
    FROM public.profiles
    WHERE id = p_target_id;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF public.is_business_profile_type(v_user_type) THEN
        RETURN TRUE;
    END IF;

    RETURN public.is_friend(p_reviewer_id, p_target_id)
        OR public.is_acquaintance(p_reviewer_id, p_target_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.upsert_profile_review(
    p_target_user_id UUID,
    p_rating SMALLINT,
    p_comment TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_reviewer_id UUID := auth.uid();
    v_comment TEXT;
BEGIN
    IF v_reviewer_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    IF p_rating IS NULL OR p_rating < 1 OR p_rating > 5 THEN
        RAISE EXCEPTION 'Bewertung muss zwischen 1 und 5 liegen';
    END IF;

    IF NOT public.can_review_profile(v_reviewer_id, p_target_user_id) THEN
        RAISE EXCEPTION 'Du kannst dieses Profil nicht bewerten';
    END IF;

    v_comment := NULLIF(TRIM(COALESCE(p_comment, '')), '');

    INSERT INTO public.reviews (target_user_id, reviewer_id, rating, comment)
    VALUES (p_target_user_id, v_reviewer_id, p_rating, v_comment)
    ON CONFLICT (target_user_id, reviewer_id)
    DO UPDATE SET
        rating = EXCLUDED.rating,
        comment = EXCLUDED.comment;
END;
$$;

GRANT EXECUTE ON FUNCTION public.upsert_profile_review(UUID, SMALLINT, TEXT) TO authenticated;

DROP POLICY IF EXISTS "Eigene Reviews schreiben" ON public.reviews;
CREATE POLICY "Eigene Reviews schreiben"
    ON public.reviews FOR INSERT TO authenticated
    WITH CHECK (
        reviewer_id = auth.uid()
        AND public.can_review_profile(auth.uid(), target_user_id)
    );

DROP POLICY IF EXISTS "Eigene Reviews bearbeiten" ON public.reviews;
CREATE POLICY "Eigene Reviews bearbeiten"
    ON public.reviews FOR UPDATE TO authenticated
    USING (reviewer_id = auth.uid())
    WITH CHECK (
        reviewer_id = auth.uid()
        AND public.can_review_profile(auth.uid(), target_user_id)
    );

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
  profile_private BOOLEAN,
  can_view_full_profile BOOLEAN,
  can_review BOOLEAN,
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
  v_can_view BOOLEAN;
BEGIN
  v_can_view := public.can_view_full_profile(v_me, p_profile_id);

  RETURN QUERY
  SELECT
    p.id,
    p.username,
    p.avatar_url,
    p.cover_url,
    CASE WHEN v_can_view THEN p.bio ELSE NULL END AS bio,
    CASE WHEN v_can_view THEN p.age ELSE NULL END AS age,
    CASE
      WHEN v_can_view THEN p.interests
      ELSE ARRAY[]::TEXT[]
    END AS interests,
    p.user_type,
    p.is_premium,
    p.is_founder,
    p.gallery_public,
    p.profile_private,
    v_can_view AS can_view_full_profile,
    CASE
      WHEN v_me IS NULL OR v_me = p_profile_id THEN FALSE
      ELSE public.can_review_profile(v_me, p_profile_id)
    END AS can_review,
    CASE
      WHEN v_can_view AND NOT public.is_business_profile_type(p.user_type)
      THEN COALESCE(us.level, 1)::INTEGER
      ELSE NULL
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
