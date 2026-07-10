-- =============================================================================
-- Migration 00023: activity_source_event
-- Zweck: Event-Übernahme aus Entdecken (Eventfrog) als eigene Aktivität.
-- Betrifft: activities.source_event_*, social_feed_activities, my_activities
-- =============================================================================

ALTER TABLE public.activities
    ADD COLUMN IF NOT EXISTS source_event_id TEXT;

ALTER TABLE public.activities
    ADD COLUMN IF NOT EXISTS source_event_title TEXT;

CREATE INDEX IF NOT EXISTS activities_source_event_id_idx
    ON public.activities (source_event_id)
    WHERE source_event_id IS NOT NULL;
