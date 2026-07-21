-- Marketing / Marke team role (staff-only, not self-assignable at signup)

DO $$ BEGIN
  ALTER TYPE public.user_type ADD VALUE IF NOT EXISTS 'marketing';
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE OR REPLACE FUNCTION public.protect_profile_user_type()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND NEW.user_type IS DISTINCT FROM OLD.user_type THEN
    IF OLD.user_type IN ('dev', 'marketing') OR NEW.user_type IN ('dev', 'marketing') THEN
      RAISE EXCEPTION 'Team-Status (Dev/Marke) kann nicht geändert werden';
    END IF;
    IF NEW.user_type NOT IN ('standard', 'event', 'company') THEN
      RAISE EXCEPTION 'Ungültiger Profiltyp';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_protect_user_type ON public.profiles;

UPDATE public.profiles
SET user_type = 'marketing'
WHERE lower(username) = 'don'
  AND user_type IS DISTINCT FROM 'marketing';

CREATE TRIGGER profiles_protect_user_type
  BEFORE UPDATE OF user_type ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_profile_user_type();

NOTIFY pgrst, 'reload schema';
