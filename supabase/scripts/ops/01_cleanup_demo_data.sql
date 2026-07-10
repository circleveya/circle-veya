-- =============================================================================
-- Script: 01_cleanup_demo_data.sql
-- Zweck: ops
-- Zweck: Entfernt Demo-Profile, Seed-Aktivitäten und Demo-Verbindungen.
-- Betrifft: auth.users, public.profiles, public.activities, public.connections
-- Behält: Echte User, System-Host CircleVeya
-- Wann: Einmalig im SQL Editor, falls früher Demo-Seed geladen wurde
-- =============================================================================

BEGIN;

DO $$
DECLARE
    v_demo_users UUID[] := ARRAY[
        'aaaaaaaa-aaaa-4000-8000-000000000001'::UUID,
        'aaaaaaaa-aaaa-4000-8000-000000000002'::UUID,
        'aaaaaaaa-aaaa-4000-8000-000000000003'::UUID,
        'aaaaaaaa-aaaa-4000-8000-000000000004'::UUID,
        'aaaaaaaa-aaaa-4000-8000-000000000005'::UUID
    ];
    v_demo_activities UUID[] := ARRAY[
        'bbbbbbbb-bbbb-4000-8000-000000000001'::UUID,
        'bbbbbbbb-bbbb-4000-8000-000000000002'::UUID,
        'bbbbbbbb-bbbb-4000-8000-000000000003'::UUID,
        'bbbbbbbb-bbbb-4000-8000-000000000004'::UUID,
        'bbbbbbbb-bbbb-4000-8000-000000000005'::UUID,
        'bbbbbbbb-bbbb-4000-8000-000000000006'::UUID
    ];
    v_deleted_activities INT;
    v_deleted_connections INT;
    v_deleted_profiles INT;
    v_deleted_auth INT;
BEGIN
    -- Demo-Aktivitäten (feste IDs + [Demo]-Titel + von Demo-Hosts)
    DELETE FROM public.activities
    WHERE id = ANY (v_demo_activities)
       OR title LIKE '[Demo]%'
       OR host_id = ANY (v_demo_users);

    GET DIAGNOSTICS v_deleted_activities = ROW_COUNT;

    -- Alte externe API-Events (nicht mehr genutzt)
    DELETE FROM public.activities
    WHERE source = 'external'
      AND external_provider IN ('eventbrite', 'ticketmaster', 'circleveya_curated');

    -- Optional: auch kuratierte Demo-Events löschen → Kommentar entfernen:
    -- DELETE FROM public.activities
    -- WHERE source = 'external'
    --   AND external_provider = 'circleveya_curated';

    -- Verbindungen mit Demo-Usern
    DELETE FROM public.connections
    WHERE user_id_1 = ANY (v_demo_users)
       OR user_id_2 = ANY (v_demo_users);

    GET DIAGNOSTICS v_deleted_connections = ROW_COUNT;

    -- Demo-Profile (CASCADE: stats, challenges, reviews, …)
    DELETE FROM public.profiles
    WHERE id = ANY (v_demo_users)
       OR username IN (
           'lea_go', 'max_kick', 'sara_boards', 'tom_berlin', 'kart_center'
       );

    GET DIAGNOSTICS v_deleted_profiles = ROW_COUNT;

    -- Demo-Auth-Accounts
    DELETE FROM auth.users
    WHERE id = ANY (v_demo_users)
       OR email LIKE '%.demo@circle.test';

    GET DIAGNOSTICS v_deleted_auth = ROW_COUNT;

    RAISE NOTICE 'Demo-Cleanup: % Aktivitäten, % Verbindungen, % Profile, % Auth-User gelöscht.',
        v_deleted_activities, v_deleted_connections, v_deleted_profiles, v_deleted_auth;
END $$;

DROP FUNCTION IF EXISTS public.seed_demo_data(UUID);
DROP FUNCTION IF EXISTS public._seed_demo_user(UUID, TEXT, TEXT);

COMMIT;

-- Prüfen (sollte 0 Zeilen liefern):
SELECT username FROM public.profiles
WHERE username IN ('lea_go', 'max_kick', 'sara_boards', 'tom_berlin', 'kart_center');

SELECT title, host_id, source, external_provider
FROM public.activities
WHERE title LIKE '[Demo]%'
   OR host_id IN (
       'aaaaaaaa-aaaa-4000-8000-000000000001',
       'aaaaaaaa-aaaa-4000-8000-000000000002',
       'aaaaaaaa-aaaa-4000-8000-000000000003',
       'aaaaaaaa-aaaa-4000-8000-000000000004',
       'aaaaaaaa-aaaa-4000-8000-000000000005'
   );
