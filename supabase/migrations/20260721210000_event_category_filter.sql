-- Event categories for discover filter (Eventfrog-style Rubriken)

ALTER TABLE public.external_events
  ADD COLUMN IF NOT EXISTS category TEXT,
  ADD COLUMN IF NOT EXISTS category_label TEXT,
  ADD COLUMN IF NOT EXISTS rubric_id TEXT;

CREATE INDEX IF NOT EXISTS external_events_category_idx
  ON public.external_events (category)
  WHERE category IS NOT NULL;

COMMENT ON COLUMN public.external_events.category IS
  'Canonical category key for filtering (concerts, parties, theater, …)';
COMMENT ON COLUMN public.external_events.category_label IS
  'Human-readable category label (e.g. Eventfrog rubric title)';
COMMENT ON COLUMN public.external_events.rubric_id IS
  'Eventfrog rubricId for the event';

-- Keyword backfill so filtering works before the next Eventfrog sync
UPDATE public.external_events e
SET
  category = inferred.key,
  category_label = inferred.label
FROM (
  SELECT
    id,
    CASE
      WHEN haystack ~ '(konzert|concert|live\\s*music|band\\b|gig\\b)' THEN 'concerts'
      WHEN haystack ~ '(party|club|disco|techno|rave|nightlife|dj\\b)' THEN 'parties'
      WHEN haystack ~ '(festival|open\\s*air|volksfest|stadtfest)' THEN 'festivals'
      WHEN haystack ~ '(theater|theatre|bühne|schauspiel|musical)' THEN 'theater'
      WHEN haystack ~ '(comedy|kabarett|stand[- ]?up|improvisation)' THEN 'comedy'
      WHEN haystack ~ '(sport|fitness|yoga|lauf|match|tennis|fussball|fußball|schwimmen)' THEN 'sport'
      WHEN haystack ~ '(kinder|kids|familie|family|jugend)' THEN 'kids'
      WHEN haystack ~ '(kurs|seminar|workshop|vortrag|schulung)' THEN 'courses'
      WHEN haystack ~ '(markt|messe|flohmarkt|jahrmarkt)' THEN 'markets'
      WHEN haystack ~ '(oper|klassik|ballett|orchester|philharmon)' THEN 'classic'
      WHEN haystack ~ '(wander|ausflug|freizeit|museum|führung|natur)' THEN 'leisure'
      ELSE 'other'
    END AS key,
    CASE
      WHEN haystack ~ '(konzert|concert|live\\s*music|band\\b|gig\\b)' THEN 'Konzerte'
      WHEN haystack ~ '(party|club|disco|techno|rave|nightlife|dj\\b)' THEN 'Parties'
      WHEN haystack ~ '(festival|open\\s*air|volksfest|stadtfest)' THEN 'Festivals'
      WHEN haystack ~ '(theater|theatre|bühne|schauspiel|musical)' THEN 'Theater & Bühne'
      WHEN haystack ~ '(comedy|kabarett|stand[- ]?up|improvisation)' THEN 'Comedy'
      WHEN haystack ~ '(sport|fitness|yoga|lauf|match|tennis|fussball|fußball|schwimmen)' THEN 'Sport & Fitness'
      WHEN haystack ~ '(kinder|kids|familie|family|jugend)' THEN 'Kinder & Familie'
      WHEN haystack ~ '(kurs|seminar|workshop|vortrag|schulung)' THEN 'Kurse & Seminare'
      WHEN haystack ~ '(markt|messe|flohmarkt|jahrmarkt)' THEN 'Märkte & Messen'
      WHEN haystack ~ '(oper|klassik|ballett|orchester|philharmon)' THEN 'Klassik & Oper'
      WHEN haystack ~ '(wander|ausflug|freizeit|museum|führung|natur)' THEN 'Freizeit & Ausflüge'
      ELSE 'Sonstiges'
    END AS label
  FROM (
    SELECT
      id,
      lower(coalesce(title, '') || ' ' || coalesce(description, '')) AS haystack
    FROM public.external_events
    WHERE category IS NULL
  ) src
) inferred
WHERE e.id = inferred.id
  AND e.category IS NULL;

CREATE OR REPLACE FUNCTION public.get_activities_by_distance(
  user_lat double precision,
  user_long double precision,
  max_dist_meters double precision DEFAULT NULL,
  p_limit integer DEFAULT 12,
  p_offset integer DEFAULT 0,
  p_date_from timestamp with time zone DEFAULT NULL,
  p_date_to timestamp with time zone DEFAULT NULL,
  p_city text DEFAULT NULL,
  p_category text DEFAULT NULL
)
RETURNS TABLE(
  id uuid,
  title text,
  start_date timestamp with time zone,
  end_date timestamp with time zone,
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
  total_count bigint,
  category text,
  category_label text
)
LANGUAGE sql
STABLE
SET search_path TO 'public', 'extensions'
AS $function$
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
      e.category,
      e.category_label,
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
      AND (
        p_category IS NULL
        OR length(trim(p_category)) = 0
        OR lower(trim(p_category)) IN ('all', 'alle', 'allen')
        OR e.category = lower(trim(p_category))
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
    c.total_count,
    w.category,
    w.category_label
  FROM with_distance w
  CROSS JOIN counted c
  ORDER BY w.start_date ASC NULLS LAST, w.distance_meters ASC NULLS LAST
  LIMIT GREATEST(p_limit, 1)
  OFFSET GREATEST(p_offset, 0);
$function$;

GRANT EXECUTE ON FUNCTION public.get_activities_by_distance(
  double precision, double precision, double precision, integer, integer,
  timestamp with time zone, timestamp with time zone, text, text
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_activities_by_distance(
  double precision, double precision, double precision, integer, integer,
  timestamp with time zone, timestamp with time zone, text, text
) TO anon;
