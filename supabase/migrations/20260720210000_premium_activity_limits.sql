-- Enforce Free vs Premium activity limits on insert/update.

CREATE OR REPLACE FUNCTION public.enforce_premium_activity_limits()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_is_premium BOOLEAN;
  v_series_count INT;
BEGIN
  SELECT COALESCE(p.is_premium, FALSE)
  INTO v_is_premium
  FROM public.profiles p
  WHERE p.id = NEW.host_id;

  IF NOT FOUND THEN
    v_is_premium := FALSE;
  END IF;

  IF v_is_premium THEN
    IF NEW.discovery_radius_km > 100 THEN
      RAISE EXCEPTION 'Premium: Entdeckungsradius maximal 100 km';
    END IF;

    IF NEW.series_id IS NOT NULL THEN
      SELECT COUNT(*)::INT INTO v_series_count
      FROM public.activities a
      WHERE a.series_id = NEW.series_id
        AND a.host_id = NEW.host_id;

      IF v_series_count >= 12 THEN
        RAISE EXCEPTION 'Premium: maximal 12 Termine pro Serie';
      END IF;
    END IF;
  ELSE
    IF NEW.discovery_radius_km > 20 THEN
      RAISE EXCEPTION 'Free: Entdeckungsradius maximal 20 km (Premium: bis 100 km)';
    END IF;

    IF COALESCE(NEW.is_sponsored, FALSE) THEN
      RAISE EXCEPTION 'Hervorgehobene Aktivitäten sind ein Premium-Feature';
    END IF;

    IF NEW.series_id IS NOT NULL THEN
      SELECT COUNT(*)::INT INTO v_series_count
      FROM public.activities a
      WHERE a.series_id = NEW.series_id
        AND a.host_id = NEW.host_id;

      IF v_series_count >= 2 THEN
        RAISE EXCEPTION 'Free: maximal 2 Termine (Premium: bis 12)';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS activities_enforce_premium_limits ON public.activities;

CREATE TRIGGER activities_enforce_premium_limits
  BEFORE INSERT OR UPDATE OF discovery_radius_km, is_sponsored, series_id, host_id
  ON public.activities
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_premium_activity_limits();
