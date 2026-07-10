-- =============================================================================
-- Migration 00019: external_events_cache_and_cleanup
-- Zweck: Eventfrog-Cache-Tabelle; migriert und entfernt externe Rows aus activities.
-- Betrifft: external_events (neu), activities (Cleanup), Indizes, sync_log-Spalten
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.external_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider TEXT NOT NULL DEFAULT 'eventfrog',
  external_id TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  city TEXT,
  location_name TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  location_geo GEOGRAPHY(POINT, 4326),
  image_url TEXT,
  external_url TEXT NOT NULL,
  raw_data JSONB,
  is_cancelled BOOLEAN NOT NULL DEFAULT false,
  synced_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT external_events_title_len CHECK (char_length(title) >= 1 AND char_length(title) <= 200),
  CONSTRAINT external_events_provider_id_unique UNIQUE (provider, external_id)
);

COMMENT ON TABLE public.external_events IS
  'Cache für externe Events (Eventfrog). Entdecken liest hierher – nicht aus activities.';

CREATE INDEX IF NOT EXISTS external_events_start_date_idx
  ON public.external_events (start_date ASC NULLS LAST);
CREATE INDEX IF NOT EXISTS external_events_city_idx
  ON public.external_events (city);
CREATE INDEX IF NOT EXISTS external_events_city_start_idx
  ON public.external_events (city, start_date ASC NULLS LAST)
  WHERE is_cancelled = false;
CREATE INDEX IF NOT EXISTS external_events_active_idx
  ON public.external_events (start_date ASC NULLS LAST)
  WHERE is_cancelled = false;
CREATE INDEX IF NOT EXISTS external_events_location_geo_idx
  ON public.external_events USING GIST (location_geo);
CREATE INDEX IF NOT EXISTS external_events_synced_at_idx
  ON public.external_events (synced_at DESC);

CREATE INDEX IF NOT EXISTS activities_discover_user_idx
  ON public.activities (status, date_time ASC NULLS LAST)
  WHERE source = 'user' AND status IN ('open', 'full');
CREATE INDEX IF NOT EXISTS activities_source_status_idx
  ON public.activities (source, status);
CREATE INDEX IF NOT EXISTS messages_sender_id_idx ON public.messages (sender_id);
CREATE INDEX IF NOT EXISTS reviews_reviewer_id_idx ON public.reviews (reviewer_id);
