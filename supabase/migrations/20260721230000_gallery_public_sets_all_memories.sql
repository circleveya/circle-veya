-- When enabling gallery_public, mark all past memories as public

CREATE OR REPLACE FUNCTION public.update_my_gallery_public(p_public boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nicht authentifiziert';
  END IF;

  UPDATE public.profiles
  SET gallery_public = COALESCE(p_public, FALSE)
  WHERE id = v_user_id;

  -- Master-Schalter an: alle eigenen vergangenen Erinnerungen öffentlich
  IF COALESCE(p_public, FALSE) THEN
    INSERT INTO public.gallery_memory_settings (profile_id, activity_id, is_public, updated_at)
    SELECT
      v_user_id,
      a.id,
      TRUE,
      NOW()
    FROM public.activities a
    JOIN public.activity_participants ap
      ON ap.activity_id = a.id
     AND ap.profile_id = v_user_id
    WHERE a.date_time IS NOT NULL
      AND a.date_time < NOW()
      AND a.status <> 'cancelled'
      AND COALESCE(a.source, 'user') <> 'external'
      AND (
        a.host_id = v_user_id
        OR ap.joined_via IN ('direct', 'interest_accepted', 'host')
      )
    ON CONFLICT (profile_id, activity_id)
    DO UPDATE SET
      is_public = TRUE,
      updated_at = NOW();
  END IF;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.update_my_gallery_public(boolean) TO authenticated;

NOTIFY pgrst, 'reload schema';
