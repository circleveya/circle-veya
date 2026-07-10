-- Distance-filtered Discover feed for external_events (Eventfrog cache).
-- Entdecken liest external_events (lat/lng + location_geo), nicht activities.

CREATE OR REPLACE FUNCTION public.get_activities_by_distance(
  user_lat double precision,
  user_long double precision,
  max_dist_meters double precision DEFAULT NULL,
  p_limit integer DEFAULT 12,
  p_offset integer DEFAULT 0,
  p_date_from timestamptz DEFAULT NULL,
  p_date_to timestamptz DEFAULT NULL,
  p_city text DEFAULT NULL
)
RETURNS TABLE (
  id uuid,
  title text,
  start_date timestamptz,
  end_date timestamptz,
  city text,
  location_name text,
  image_url text,
  external_url text,
  latitude double precision,
  longitude double precision,
  provider text,
  external_id text,
  distance_meters double precision,
  distance_km double precision,
  total_count bigint
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public, extensions
AS $$
  WITH viewer AS (
    SELECT ST_SetSRID(ST_MakePoint(user_long, user_lat), 4326)::geography AS geom
  ),
  base AS (
    SELECT
      e.id,
      e.title,
      e.start_date,
      e.end_date,
      e.city,
      e.location_name,
      e.image_url,
      e.external_url,
      e.latitude,
      e.longitude,
      e.provider,
      e.external_id,
      CASE
        WHEN e.location_geo IS NOT NULL THEN e.location_geo
        WHEN e.latitude IS NOT NULL AND e.longitude IS NOT NULL THEN
          ST_SetSRID(ST_MakePoint(e.longitude, e.latitude), 4326)::geography
        ELSE NULL
      END AS event_geo
    FROM public.external_events e
    WHERE e.is_cancelled = false
      AND (
        p_date_from IS NOT NULL
        OR p_date_to IS NOT NULL
        OR e.start_date IS NULL
        OR e.start_date >= now()
      )
      AND (p_date_from IS NULL OR e.start_date >= p_date_from)
      AND (p_date_to IS NULL OR e.start_date <= p_date_to)
      AND (
        p_city IS NULL
        OR length(trim(p_city)) = 0
        OR lower(trim(p_city)) = 'gps'
        OR e.city ILIKE ('%' || trim(p_city) || '%')
      )
  ),
  with_distance AS (
    SELECT
      b.*,
      CASE
        WHEN b.event_geo IS NULL THEN NULL
        ELSE ST_Distance(b.event_geo, (SELECT geom FROM viewer))
      END AS distance_meters
    FROM base b
    WHERE
      max_dist_meters IS NULL
      OR (
        b.event_geo IS NOT NULL
        AND ST_DWithin(
          b.event_geo,
          (SELECT geom FROM viewer),
          max_dist_meters
        )
      )
  ),
  counted AS (
    SELECT count(*)::bigint AS total_count FROM with_distance
  )
  SELECT
    w.id,
    w.title,
    w.start_date,
    w.end_date,
    w.city,
    w.location_name,
    w.image_url,
    w.external_url,
    w.latitude,
    w.longitude,
    w.provider,
    w.external_id,
    w.distance_meters,
    CASE
      WHEN w.distance_meters IS NULL THEN NULL
      ELSE w.distance_meters / 1000.0
    END AS distance_km,
    c.total_count
  FROM with_distance w
  CROSS JOIN counted c
  ORDER BY w.start_date ASC NULLS LAST, w.distance_meters ASC NULLS LAST
  LIMIT GREATEST(p_limit, 1)
  OFFSET GREATEST(p_offset, 0);
$$;

COMMENT ON FUNCTION public.get_activities_by_distance(
  double precision, double precision, double precision, integer, integer, timestamptz, timestamptz, text
) IS
  'Entdecken: external_events nach Distanz (ST_DWithin) filtern; max_dist_meters NULL = überall.';

GRANT EXECUTE ON FUNCTION public.get_activities_by_distance(
  double precision, double precision, double precision, integer, integer, timestamptz, timestamptz, text
) TO authenticated, anon, service_role;
