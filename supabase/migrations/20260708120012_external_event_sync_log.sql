-- ============================================================
-- Sync-Log für externe Event-Aggregation
-- ============================================================

CREATE TABLE IF NOT EXISTS public.external_event_sync_log (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    synced_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    providers   TEXT[] NOT NULL DEFAULT '{}',
    fetched     INT NOT NULL DEFAULT 0,
    inserted    INT NOT NULL DEFAULT 0,
    updated     INT NOT NULL DEFAULT 0,
    archived    INT NOT NULL DEFAULT 0,
    errors      JSONB
);

CREATE INDEX IF NOT EXISTS external_event_sync_log_synced_at_idx
    ON public.external_event_sync_log (synced_at DESC);

ALTER TABLE public.external_event_sync_log ENABLE ROW LEVEL SECURITY;

-- Nur Service-Role (Edge Function) schreibt; keine öffentliche Leserechte nötig
COMMENT ON TABLE public.external_event_sync_log IS
    'Protokoll der Edge Function sync-external-events (Cron-Monitoring).';
