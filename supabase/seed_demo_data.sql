-- ============================================================
-- Demo-Daten für Circle (Entdecken, Freunde, Bekannte, Partner)
-- ============================================================
--
-- 1. In der App registrieren / einloggen
-- 2. Deine User-ID holen:
--      SELECT id, email FROM auth.users ORDER BY created_at DESC LIMIT 5;
-- 3. Im SQL Editor ausführen:
--      SELECT public.seed_demo_data('eb0f85c8-18ad-4770-8c14-a5a862fcd572');
--    (oder eigene UUID aus auth.users)
--
-- Erneut ausführen überschreibt Demo-Aktivitäten (idempotent).

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
GRANT USAGE ON SCHEMA extensions TO postgres, service_role;

-- Feste Demo-User-IDs
-- Lea (Freundin), Max (Freund), Sara (Bekannte), Tom (Fremder), KartCenter (Partner)

CREATE OR REPLACE FUNCTION public._seed_demo_user(
    p_id UUID,
    p_email TEXT,
    p_username TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
BEGIN
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        recovery_sent_at,
        last_sign_in_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        email_change,
        email_change_token_new,
        recovery_token
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        p_id,
        'authenticated',
        'authenticated',
        p_email,
        crypt('demo1234', gen_salt('bf'::text)),
        NOW(),
        NOW(),
        NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        jsonb_build_object('username', p_username),
        NOW(),
        NOW(),
        '',
        '',
        '',
        ''
    )
    ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.profiles (id, username)
    VALUES (p_id, p_username)
    ON CONFLICT (id) DO UPDATE SET username = EXCLUDED.username;
END;
$$;

CREATE OR REPLACE FUNCTION public.seed_demo_data(p_my_user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
    v_lea UUID := 'aaaaaaaa-aaaa-4000-8000-000000000001';
    v_max UUID := 'aaaaaaaa-aaaa-4000-8000-000000000002';
    v_sara UUID := 'aaaaaaaa-aaaa-4000-8000-000000000003';
    v_tom UUID := 'aaaaaaaa-aaaa-4000-8000-000000000004';
    v_partner UUID := 'aaaaaaaa-aaaa-4000-8000-000000000005';

    v_act_go_kart UUID := 'bbbbbbbb-bbbb-4000-8000-000000000001';
    v_act_fussball UUID := 'bbbbbbbb-bbbb-4000-8000-000000000002';
    v_act_boardgame UUID := 'bbbbbbbb-bbbb-4000-8000-000000000003';
    v_act_konzert UUID := 'bbbbbbbb-bbbb-4000-8000-000000000004';
    v_act_sponsored UUID := 'bbbbbbbb-bbbb-4000-8000-000000000005';
    v_act_my_grill UUID := 'bbbbbbbb-bbbb-4000-8000-000000000006';

    v_pair_1 UUID;
    v_pair_2 UUID;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_my_user_id) THEN
        RAISE EXCEPTION 'User % nicht gefunden. Bitte zuerst in der App registrieren.', p_my_user_id;
    END IF;

    -- Demo-User anlegen
    PERFORM public._seed_demo_user(v_lea, 'lea.demo@circle.test', 'lea_go');
    PERFORM public._seed_demo_user(v_max, 'max.demo@circle.test', 'max_kick');
    PERFORM public._seed_demo_user(v_sara, 'sara.demo@circle.test', 'sara_boards');
    PERFORM public._seed_demo_user(v_tom, 'tom.demo@circle.test', 'tom_berlin');
    PERFORM public._seed_demo_user(v_partner, 'partner.demo@circle.test', 'kart_center');

    UPDATE public.profiles SET
        bio = 'Go-Kart-Fan & Wochenend-Explorerin',
        age = 26,
        user_type = 'standard'
    WHERE id = v_lea;

    UPDATE public.profiles SET
        bio = 'Spielt jeden Samstag Fußball',
        age = 28,
        user_type = 'standard'
    WHERE id = v_max;

    UPDATE public.profiles SET
        bio = 'Liebt Brettspiele und gemütliche Abende',
        age = 24,
        user_type = 'standard'
    WHERE id = v_sara;

    UPDATE public.profiles SET
        bio = 'Neu in Berlin – sucht Leute für Events',
        age = 30,
        user_type = 'standard'
    WHERE id = v_tom;

    UPDATE public.profiles SET
        bio = 'Verifizierter Community Partner für Motorsport-Events',
        age = NULL,
        user_type = 'company'
    WHERE id = v_partner;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'profiles'
          AND column_name = 'interests'
    ) THEN
        UPDATE public.profiles SET interests = ARRAY['Go-Kart', 'Konzerte', 'Fitness'] WHERE id = v_lea;
        UPDATE public.profiles SET interests = ARRAY['Fußball', 'Laufen'] WHERE id = v_max;
        UPDATE public.profiles SET interests = ARRAY['Brettspiele', 'Kaffee'] WHERE id = v_sara;
        UPDATE public.profiles SET interests = ARRAY['Musik', 'Street Food'] WHERE id = v_tom;
        UPDATE public.profiles SET interests = ARRAY['Go-Kart', 'Teamevents', 'B2B'] WHERE id = v_partner;
    END IF;

    -- Verbindungen zu deinem Account
    v_pair_1 := LEAST(p_my_user_id, v_lea);
    v_pair_2 := GREATEST(p_my_user_id, v_lea);
    INSERT INTO public.connections (user_id_1, user_id_2, status)
    VALUES (v_pair_1, v_pair_2, 'friend')
    ON CONFLICT (user_id_1, user_id_2) DO UPDATE SET status = 'friend';

    v_pair_1 := LEAST(p_my_user_id, v_max);
    v_pair_2 := GREATEST(p_my_user_id, v_max);
    INSERT INTO public.connections (user_id_1, user_id_2, status)
    VALUES (v_pair_1, v_pair_2, 'friend')
    ON CONFLICT (user_id_1, user_id_2) DO UPDATE SET status = 'friend';

    v_pair_1 := LEAST(p_my_user_id, v_sara);
    v_pair_2 := GREATEST(p_my_user_id, v_sara);
    INSERT INTO public.connections (user_id_1, user_id_2, status)
    VALUES (v_pair_1, v_pair_2, 'acquaintance')
    ON CONFLICT (user_id_1, user_id_2) DO UPDATE SET status = 'acquaintance';

    -- Alte Demo-Aktivitäten aufräumen
    DELETE FROM public.activity_interests
    WHERE activity_id IN (
        SELECT id FROM public.activities
        WHERE id IN (
            v_act_go_kart, v_act_fussball, v_act_boardgame,
            v_act_konzert, v_act_sponsored, v_act_my_grill
        )
    );

    DELETE FROM public.activity_participants
    WHERE activity_id IN (
        v_act_go_kart, v_act_fussball, v_act_boardgame,
        v_act_konzert, v_act_sponsored, v_act_my_grill
    );

    DELETE FROM public.activities
    WHERE id IN (
        v_act_go_kart, v_act_fussball, v_act_boardgame,
        v_act_konzert, v_act_sponsored, v_act_my_grill
    );

    -- 1) Freundin: Go-Kart – Direkt beitreten, schon Teilnehmer drin
    INSERT INTO public.activities (
        id, host_id, title, description, max_participants, current_participants,
        date_time, location_geo, location_name,
        location_type, weather_condition,
        visible_to_friends, visible_to_acquaintances, visible_to_strangers,
        discovery_radius_km, is_sponsored, status
    ) VALUES (
        v_act_go_kart, v_lea,
        'Go-Kart Rennen am Wochenende',
        'Wir fahren 3 Runden auf der Indoor-Strecke. Anfänger willkommen!',
        8, 0,
        NOW() + INTERVAL '3 days',
        ST_SetSRID(ST_MakePoint(13.3889, 52.5170), 4326)::GEOGRAPHY,
        'Berlin Mitte',
        'indoor', 'sun',
        true, false, false,
        20, false, 'open'
    );

  -- 2) Freund: Fußball – fast voll
    INSERT INTO public.activities (
        id, host_id, title, description, max_participants, current_participants,
        date_time, location_geo, location_name,
        location_type, weather_condition,
        visible_to_friends, visible_to_acquaintances, visible_to_strangers,
        discovery_radius_km, is_sponsored, status
    ) VALUES (
        v_act_fussball, v_max,
        'Fußball im Volkspark',
        '5v5 auf Kunstrasen. Bitte Hallenschuhe mitbringen.',
        10, 0,
        NOW() + INTERVAL '5 days',
        ST_SetSRID(ST_MakePoint(13.4190, 52.4862), 4326)::GEOGRAPHY,
        'Volkspark Friedrichshain',
        'outdoor', 'sun',
        true, false, false,
        20, false, 'open'
    );

    -- 3) Bekannte: Brettspiele – Interesse bekunden
    INSERT INTO public.activities (
        id, host_id, title, description, max_participants, current_participants,
        date_time, location_geo, location_name,
        location_type, weather_condition,
        visible_to_friends, visible_to_acquaintances, visible_to_strangers,
        discovery_radius_km, is_sponsored, status
    ) VALUES (
        v_act_boardgame, v_sara,
        'Brettspiel-Abend',
        'Catan, Azul und was ihr mitbringt. Tee & Snacks sind da.',
        6, 0,
        NOW() + INTERVAL '2 days',
        ST_SetSRID(ST_MakePoint(13.4050, 52.5200), 4326)::GEOGRAPHY,
        'Café Mitte',
        'indoor', 'rain',
        false, true, false,
        20, false, 'open'
    );

    -- 4) Fremder: Konzert – GPS-Radius
    INSERT INTO public.activities (
        id, host_id, title, description, max_participants, current_participants,
        date_time, location_geo, location_name,
        location_type, weather_condition,
        visible_to_friends, visible_to_acquaintances, visible_to_strangers,
        discovery_radius_km, is_sponsored, status
    ) VALUES (
        v_act_konzert, v_tom,
        'Open-Air im Park',
        'Live-Bands, Foodtrucks und Sonnenuntergang.',
        20, 0,
        NOW() + INTERVAL '7 days',
        ST_SetSRID(ST_MakePoint(13.404954, 52.520008), 4326)::GEOGRAPHY,
        'Berlin Mitte',
        'outdoor', 'sun',
        false, false, true,
        30, false, 'open'
    );

    -- 5) Partner: Gesponsert / Featured
    INSERT INTO public.activities (
        id, host_id, title, description, max_participants, current_participants,
        date_time, location_geo, location_name,
        location_type, weather_condition,
        visible_to_friends, visible_to_acquaintances, visible_to_strangers,
        discovery_radius_km, is_sponsored, status
    ) VALUES (
        v_act_sponsored, v_partner,
        'Pro-Kart Training (gesponsert)',
        'Community-Partner Event mit Coach, Timer und Getränkeflat.',
        12, 0,
        NOW() + INTERVAL '4 days',
        ST_SetSRID(ST_MakePoint(13.4280, 52.5100), 4326)::GEOGRAPHY,
        'Kart Center Berlin',
        'indoor', 'sun',
        false, false, true,
        50, true, 'open'
    );

    -- 6) Deine Demo-Aktivität mit Interessenten (Tab „Meine Events“)
    INSERT INTO public.activities (
        id, host_id, title, description, max_participants, current_participants,
        date_time, location_geo, location_name,
        location_type, weather_condition,
        visible_to_friends, visible_to_acquaintances, visible_to_strangers,
        discovery_radius_km, is_sponsored, status
    ) VALUES (
        v_act_my_grill, p_my_user_id,
        '[Demo] Grillabend bei mir',
        'Test-Aktivität mit Interessenten zum Durchklicken.',
        8, 0,
        NOW() + INTERVAL '6 days',
        ST_SetSRID(ST_MakePoint(13.404954, 52.520008), 4326)::GEOGRAPHY,
        'Berlin',
        'outdoor', 'sun',
        true, true, false,
        20, false, 'open'
    );

    -- Teilnehmer für Go-Kart (Host + Max + Tom + du optional nicht)
    INSERT INTO public.activity_participants (activity_id, profile_id, joined_via)
    VALUES
        (v_act_go_kart, v_max, 'direct'),
        (v_act_go_kart, v_tom, 'interest_accepted')
    ON CONFLICT (activity_id, profile_id) DO NOTHING;

    -- Fußball: Host + 5 weitere Teilnehmer → 6/10
    INSERT INTO public.activity_participants (activity_id, profile_id, joined_via)
    VALUES
        (v_act_fussball, v_lea, 'direct'),
        (v_act_fussball, v_sara, 'direct'),
        (v_act_fussball, v_tom, 'direct'),
        (v_act_fussball, v_partner, 'direct'),
        (v_act_fussball, p_my_user_id, 'direct')
    ON CONFLICT (activity_id, profile_id) DO NOTHING;

    -- Interessenten für deinen Grillabend
    INSERT INTO public.activity_interests (activity_id, profile_id, status, message)
    VALUES
        (v_act_my_grill, v_lea, 'pending', 'Ich bringe Salat mit! 🥗'),
        (v_act_my_grill, v_max, 'pending', 'Kann ich den Grill mitbringen?'),
        (v_act_my_grill, v_sara, 'accepted', 'Freue mich drauf!')
    ON CONFLICT (activity_id, profile_id) DO UPDATE
    SET status = EXCLUDED.status, message = EXCLUDED.message;

    -- Teilnehmerzähler aktualisieren (Trigger setzt nur Host = 1)
    UPDATE public.activities a
    SET current_participants = sub.cnt
    FROM (
        SELECT activity_id, COUNT(*)::INT AS cnt
        FROM public.activity_participants
        WHERE activity_id IN (
            v_act_go_kart, v_act_fussball, v_act_boardgame,
            v_act_konzert, v_act_sponsored, v_act_my_grill
        )
        GROUP BY activity_id
    ) sub
    WHERE a.id = sub.activity_id;

    RETURN 'Demo-Daten erstellt: 5 Aktivitäten im Entdecken-Feed + 1 eigene mit Interessenten. App neu laden (Pull-to-refresh).';
END;
$$;

GRANT EXECUTE ON FUNCTION public.seed_demo_data(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.seed_demo_data(UUID) TO service_role;
