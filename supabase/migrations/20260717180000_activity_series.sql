-- Activity series: multiple occurrences linked by series_id
ALTER TABLE public.activities
  ADD COLUMN IF NOT EXISTS series_id UUID;

CREATE INDEX IF NOT EXISTS activities_series_id_idx
  ON public.activities (series_id)
  WHERE series_id IS NOT NULL;
