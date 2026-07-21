-- Weekly (Monday) & monthly (1st) challenge resets

ALTER TABLE public.user_challenges
  ADD COLUMN IF NOT EXISTS reset_cadence TEXT NOT NULL DEFAULT 'none',
  ADD COLUMN IF NOT EXISTS period_key TEXT;

COMMENT ON COLUMN public.user_challenges.reset_cadence IS
  'weekly = reset Monday; monthly = reset on 1st; none = one-off';
COMMENT ON COLUMN public.user_challenges.period_key IS
  'Current period id (e.g. 2026-W30 or 2026-07)';

-- Europe/Zurich calendar helpers
CREATE OR REPLACE FUNCTION public.challenge_period_key(p_cadence TEXT)
RETURNS TEXT
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $$
  SELECT CASE lower(COALESCE(p_cadence, 'none'))
    WHEN 'weekly' THEN to_char((NOW() AT TIME ZONE 'Europe/Zurich')::date, 'IYYY-"W"IW')
    WHEN 'monthly' THEN to_char((NOW() AT TIME ZONE 'Europe/Zurich')::date, 'YYYY-MM')
    ELSE 'ongoing'
  END;
$$;

CREATE OR REPLACE FUNCTION public.refresh_user_challenge_periods(p_profile_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_week TEXT := public.challenge_period_key('weekly');
  v_month TEXT := public.challenge_period_key('monthly');
BEGIN
  IF p_profile_id IS NULL THEN
    RETURN;
  END IF;

  UPDATE public.user_challenges
  SET
    progress = 0,
    is_active = TRUE,
    period_key = v_week
  WHERE profile_id = p_profile_id
    AND reset_cadence = 'weekly'
    AND period_key IS DISTINCT FROM v_week;

  UPDATE public.user_challenges
  SET
    progress = 0,
    is_active = TRUE,
    period_key = v_month
  WHERE profile_id = p_profile_id
    AND reset_cadence = 'monthly'
    AND period_key IS DISTINCT FROM v_month;

  -- Ensure period_key is set for brand-new rows
  UPDATE public.user_challenges
  SET period_key = public.challenge_period_key(reset_cadence)
  WHERE profile_id = p_profile_id
    AND period_key IS NULL
    AND reset_cadence IN ('weekly', 'monthly');
END;
$$;

-- Backfill cadence for existing challenges
UPDATE public.user_challenges
SET
  reset_cadence = CASE challenge_type
    WHEN 'weekly' THEN 'weekly'
    WHEN 'monthly' THEN 'monthly'
    WHEN 'social' THEN 'monthly'
    WHEN 'sport' THEN 'monthly'
    ELSE 'none'
  END,
  period_key = COALESCE(
    period_key,
    CASE challenge_type
      WHEN 'weekly' THEN public.challenge_period_key('weekly')
      WHEN 'monthly' THEN public.challenge_period_key('monthly')
      WHEN 'social' THEN public.challenge_period_key('monthly')
      WHEN 'sport' THEN public.challenge_period_key('monthly')
      ELSE 'ongoing'
    END
  ),
  title = CASE
    WHEN challenge_type = 'social' AND title = 'Neue Freunde treffen'
      THEN '4 neue Freunde diesen Monat'
    WHEN challenge_type = 'sport' AND title = 'Sport-Challenge'
      THEN '10 Sport-Aktivitäten diesen Monat'
    ELSE title
  END,
  description = CASE
    WHEN challenge_type = 'weekly'
      THEN 'Nimm diese Woche an Aktivitäten teil oder erstelle eigene. Reset jeden Montag.'
    WHEN challenge_type = 'social'
      THEN 'Schließe diesen Monat neue Freundschaften. Reset am 1. des Monats.'
    WHEN challenge_type = 'sport'
      THEN 'Nimm diesen Monat an Sport-/Outdoor-Aktivitäten teil. Reset am 1. des Monats.'
    WHEN challenge_type = 'monthly'
      THEN 'Nimm diesen Monat an Aktivitäten teil. Reset am 1. des Monats.'
    ELSE description
  END,
  how_to = CASE
    WHEN challenge_type = 'weekly'
      THEN 'Erstelle oder nimm an Aktivitäten teil – zählt diese Woche (Reset Montag).'
    WHEN challenge_type = 'social'
      THEN 'Schließe neue Freundschaften – zählt diesen Monat (Reset am 1.).'
    WHEN challenge_type = 'sport'
      THEN 'Nimm an Sport-/Outdoor-Aktivitäten teil – zählt diesen Monat (Reset am 1.).'
    WHEN challenge_type = 'monthly'
      THEN 'Erstelle oder nimm an Aktivitäten teil – zählt diesen Monat (Reset am 1.).'
    ELSE how_to
  END;

-- Add monthly activity challenge for users who don't have one yet
INSERT INTO public.user_challenges (
  profile_id, title, progress, target, challenge_type, xp_reward,
  reset_cadence, period_key, description, how_to, is_active
)
SELECT
  us.profile_id,
  '5 Aktivitäten diesen Monat',
  0,
  5,
  'monthly',
  250,
  'monthly',
  public.challenge_period_key('monthly'),
  'Nimm diesen Monat an Aktivitäten teil oder erstelle eigene. Reset am 1. des Monats.',
  'Erstelle oder nimm an Aktivitäten teil – zählt diesen Monat (Reset am 1.).',
  TRUE
FROM public.user_stats us
WHERE NOT EXISTS (
  SELECT 1
  FROM public.user_challenges uc
  WHERE uc.profile_id = us.profile_id
    AND uc.challenge_type = 'monthly'
);

CREATE OR REPLACE FUNCTION public.ensure_user_stats(p_profile_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  INSERT INTO public.user_stats (profile_id)
  VALUES (p_profile_id)
  ON CONFLICT (profile_id) DO NOTHING;

  IF NOT EXISTS (
    SELECT 1 FROM public.user_challenges WHERE profile_id = p_profile_id
  ) THEN
    INSERT INTO public.user_challenges (
      profile_id, title, progress, target, challenge_type, xp_reward,
      reset_cadence, period_key, description, how_to
    )
    VALUES
      (
        p_profile_id,
        '3 Aktivitäten diese Woche',
        0, 3, 'weekly', 150,
        'weekly', public.challenge_period_key('weekly'),
        'Nimm diese Woche an Aktivitäten teil oder erstelle eigene. Reset jeden Montag.',
        'Erstelle oder nimm an Aktivitäten teil – zählt diese Woche (Reset Montag).'
      ),
      (
        p_profile_id,
        '5 Aktivitäten diesen Monat',
        0, 5, 'monthly', 250,
        'monthly', public.challenge_period_key('monthly'),
        'Nimm diesen Monat an Aktivitäten teil oder erstelle eigene. Reset am 1. des Monats.',
        'Erstelle oder nimm an Aktivitäten teil – zählt diesen Monat (Reset am 1.).'
      ),
      (
        p_profile_id,
        '4 neue Freunde diesen Monat',
        0, 4, 'social', 200,
        'monthly', public.challenge_period_key('monthly'),
        'Schließe diesen Monat neue Freundschaften. Reset am 1. des Monats.',
        'Schließe neue Freundschaften – zählt diesen Monat (Reset am 1.).'
      ),
      (
        p_profile_id,
        '10 Sport-Aktivitäten diesen Monat',
        0, 10, 'sport', 300,
        'monthly', public.challenge_period_key('monthly'),
        'Nimm diesen Monat an Sport-/Outdoor-Aktivitäten teil. Reset am 1. des Monats.',
        'Nimm an Sport-/Outdoor-Aktivitäten teil – zählt diesen Monat (Reset am 1.).'
      );
  END IF;

  PERFORM public.refresh_user_challenge_periods(p_profile_id);
END;
$$;

DROP FUNCTION IF EXISTS public.get_user_level_stats();

CREATE OR REPLACE FUNCTION public.get_user_level_stats()
RETURNS TABLE(
  level integer,
  current_xp integer,
  xp_for_next_level integer,
  challenge_id uuid,
  challenge_title text,
  challenge_progress integer,
  challenge_target integer,
  challenge_xp_reward integer,
  challenge_type text,
  challenge_description text,
  challenge_how_to text,
  challenge_reset_cadence text,
  challenge_period_key text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
#variable_conflict use_column
DECLARE
  v_me UUID := auth.uid();
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  PERFORM public.ensure_user_stats(v_me);

  RETURN QUERY
  SELECT
    us.level,
    us.xp,
    us.xp_needed,
    uc.id,
    uc.title,
    uc.progress,
    uc.target,
    uc.xp_reward,
    uc.challenge_type,
    uc.description,
    uc.how_to,
    uc.reset_cadence,
    uc.period_key
  FROM public.user_stats us
  LEFT JOIN public.user_challenges uc
    ON uc.profile_id = us.profile_id AND uc.is_active = true
  WHERE us.profile_id = v_me
  ORDER BY
    CASE uc.reset_cadence
      WHEN 'weekly' THEN 0
      WHEN 'monthly' THEN 1
      ELSE 2
    END,
    uc.created_at;
END;
$function$;

-- Activity create: bump weekly + monthly (+ sport monthly)
CREATE OR REPLACE FUNCTION public.on_activity_created_award_xp()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  PERFORM public.ensure_user_stats(NEW.host_id);
  PERFORM public.award_xp(NEW.host_id, 50);

  UPDATE public.user_challenges
  SET progress = LEAST(progress + 1, target)
  WHERE profile_id = NEW.host_id
    AND is_active = true
    AND challenge_type IN ('weekly', 'monthly', 'sport');

  RETURN NEW;
END;
$$;

-- Join activity: also progress weekly/monthly challenges
CREATE OR REPLACE FUNCTION public.on_participant_join_award_xp()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_host_id UUID;
BEGIN
  PERFORM public.ensure_user_stats(NEW.profile_id);
  PERFORM public.award_xp(NEW.profile_id, 30);

  SELECT host_id INTO v_host_id
  FROM public.activities
  WHERE activities.id = NEW.activity_id;

  IF v_host_id IS NOT NULL AND v_host_id <> NEW.profile_id THEN
    PERFORM public.award_xp(v_host_id, 10);
  END IF;

  -- Don't double-count host's own participation row if any
  IF v_host_id IS DISTINCT FROM NEW.profile_id THEN
    UPDATE public.user_challenges
    SET progress = LEAST(progress + 1, target)
    WHERE profile_id = NEW.profile_id
      AND is_active = true
      AND challenge_type IN ('weekly', 'monthly', 'sport');
  END IF;

  RETURN NEW;
END;
$$;

-- Social challenge progress when friendship is established
CREATE OR REPLACE FUNCTION public.on_friendship_challenge_progress()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.status::text = 'friend'
     AND (TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM NEW.status) THEN
    PERFORM public.ensure_user_stats(NEW.user_id_1);
    PERFORM public.ensure_user_stats(NEW.user_id_2);

    UPDATE public.user_challenges
    SET progress = LEAST(progress + 1, target)
    WHERE profile_id IN (NEW.user_id_1, NEW.user_id_2)
      AND is_active = true
      AND challenge_type = 'social';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS connections_challenge_on_friend ON public.connections;
CREATE TRIGGER connections_challenge_on_friend
  AFTER INSERT OR UPDATE OF status ON public.connections
  FOR EACH ROW
  EXECUTE FUNCTION public.on_friendship_challenge_progress();

-- After claiming reward, periodic challenges stay inactive until next period reset
CREATE OR REPLACE FUNCTION public.complete_user_challenge(p_challenge_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_uid UUID := auth.uid();
  v_progress INT;
  v_target INT;
  v_xp INT;
  v_active BOOLEAN;
  v_profile UUID;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  -- Refresh periods first so stale completed challenges can reopen
  PERFORM public.refresh_user_challenge_periods(v_uid);

  SELECT profile_id, progress, target, xp_reward, is_active
  INTO v_profile, v_progress, v_target, v_xp, v_active
  FROM public.user_challenges
  WHERE id = p_challenge_id;

  IF v_profile IS NULL OR v_profile <> v_uid THEN
    RAISE EXCEPTION 'Challenge nicht gefunden';
  END IF;

  IF NOT COALESCE(v_active, FALSE) THEN
    RAISE EXCEPTION 'Challenge bereits abgeschlossen – kommt in der nächsten Periode wieder';
  END IF;

  IF v_progress < v_target THEN
    RAISE EXCEPTION 'Challenge noch nicht erfüllt';
  END IF;

  PERFORM public.award_xp(v_uid, COALESCE(v_xp, 100));

  UPDATE public.user_challenges
  SET is_active = FALSE
  WHERE id = p_challenge_id;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.challenge_period_key(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.refresh_user_challenge_periods(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_level_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION public.complete_user_challenge(UUID) TO authenticated;

NOTIFY pgrst, 'reload schema';
