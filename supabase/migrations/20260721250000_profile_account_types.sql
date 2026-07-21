-- Account types: standard (user), event (organizer/business), company (legacy), dev (app owner)

DO $$ BEGIN
  ALTER TYPE public.user_type ADD VALUE IF NOT EXISTS 'event';
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TYPE public.user_type ADD VALUE IF NOT EXISTS 'dev';
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Signup: optional user_type in auth metadata (standard | event | company). Never self-assign "dev".
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_username TEXT;
  v_type_raw TEXT;
  v_user_type public.user_type := 'standard';
BEGIN
  v_username := COALESCE(
    NEW.raw_user_meta_data ->> 'username',
    SPLIT_PART(NEW.email, '@', 1)
  );

  WHILE EXISTS (SELECT 1 FROM public.profiles WHERE username = v_username) LOOP
    v_username := v_username || '_' || SUBSTRING(NEW.id::TEXT, 1, 4);
  END LOOP;

  v_type_raw := lower(trim(COALESCE(NEW.raw_user_meta_data ->> 'user_type', 'standard')));
  IF v_type_raw IN ('event', 'company') THEN
    v_user_type := v_type_raw::public.user_type;
  ELSE
    v_user_type := 'standard';
  END IF;

  INSERT INTO public.profiles (id, username, user_type)
  VALUES (NEW.id, v_username, v_user_type);

  PERFORM public.ensure_user_stats(NEW.id);

  RETURN NEW;
END;
$function$;

-- Prevent elevating/downgrading to/from "dev" via normal profile updates
CREATE OR REPLACE FUNCTION public.protect_profile_user_type()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.user_type IS DISTINCT FROM OLD.user_type THEN
    IF OLD.user_type = 'dev' OR NEW.user_type = 'dev' THEN
      RAISE EXCEPTION 'Developer-Status kann nicht geändert werden';
    END IF;
    -- Nur standard <-> event/company erlauben
    IF NEW.user_type NOT IN ('standard', 'event', 'company') THEN
      RAISE EXCEPTION 'Ungültiger Profiltyp';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_protect_user_type ON public.profiles;
CREATE TRIGGER profiles_protect_user_type
  BEFORE UPDATE OF user_type ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_profile_user_type();

-- Sponsored activities: Event-Profile + Dev
CREATE OR REPLACE FUNCTION public.enforce_sponsored_only_for_company()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NEW.is_sponsored IS TRUE THEN
    IF NOT EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = NEW.host_id
        AND p.user_type IN ('company', 'event', 'dev')
    ) THEN
      RAISE EXCEPTION
        'Nur Event-Profile können gesponserte Aktivitäten erstellen';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- Mark app owner as Developer
UPDATE public.profiles
SET user_type = 'dev'
WHERE lower(username) = 'circleveya'
  AND user_type IS DISTINCT FROM 'dev';

-- Optional helper for clients
CREATE OR REPLACE FUNCTION public.is_event_organizer_type(p_type public.user_type)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT p_type IN ('company', 'event', 'dev');
$$;

GRANT EXECUTE ON FUNCTION public.is_event_organizer_type(public.user_type) TO authenticated;

NOTIFY pgrst, 'reload schema';
