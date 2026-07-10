-- =============================================================================
-- Script: 02_external_events_host.sql
-- Zweck: setup
-- Zweck: Legt den System-Host-Profil-Eintrag "CircleVeya" für externe Events an.
-- Betrifft: public.profiles, RPC get_external_events_host_id()
-- Wann: Nach Anlegen des Auth-Users im Dashboard (UUID unten eintragen)
-- =============================================================================

-- UUID des Auth-Users hier einsetzen:
-- SELECT id, email FROM auth.users WHERE email = 'circle-events@circle.app';

INSERT INTO public.profiles (
    id,
    username,
    user_type,
    bio,
    avatar_url
)
VALUES (
    '00000000-0000-0000-0000-000000000000',  -- ← HIER UUID ERSETZEN
    'CircleVeya',
    'company',
    'Offizielle Event-Quelle von CircleVeya – Ticketmaster & kuratierte Highlights.',
    NULL
)
ON CONFLICT (id) DO UPDATE SET
    username = EXCLUDED.username,
    user_type = EXCLUDED.user_type,
    bio = EXCLUDED.bio;

-- Prüfen:
SELECT public.get_external_events_host_id() AS host_id;
