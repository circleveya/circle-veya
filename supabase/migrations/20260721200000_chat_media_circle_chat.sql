-- Rich chat media, per-user wallpaper, circle-group chats & post permissions

-- 1) Circle groups: who may post in the group chat
ALTER TABLE public.circle_groups
  ADD COLUMN IF NOT EXISTS members_can_post BOOLEAN NOT NULL DEFAULT TRUE;

-- 2) Chats: link to circle groups + new chat type
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'chat_type' AND e.enumlabel = 'circle_group'
  ) THEN
    ALTER TYPE public.chat_type ADD VALUE 'circle_group';
  END IF;
END $$;

ALTER TABLE public.chats
  ADD COLUMN IF NOT EXISTS circle_group_id UUID REFERENCES public.circle_groups(id) ON DELETE CASCADE;

CREATE UNIQUE INDEX IF NOT EXISTS chats_circle_group_unique
  ON public.chats (circle_group_id)
  WHERE circle_group_id IS NOT NULL;

-- 3) Messages: media support
ALTER TABLE public.messages
  ADD COLUMN IF NOT EXISTS message_type TEXT NOT NULL DEFAULT 'text'
    CHECK (message_type = ANY (ARRAY['text'::text, 'image'::text, 'gif'::text])),
  ADD COLUMN IF NOT EXISTS media_url TEXT;

-- 4) Per-user wallpaper (only that participant sees it)
ALTER TABLE public.chat_participants
  ADD COLUMN IF NOT EXISTS wallpaper_url TEXT;

-- 5) Storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  (
    'chat-media',
    'chat-media',
    true,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
  ),
  (
    'chat-wallpapers',
    'chat-wallpapers',
    true,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp']
  )
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Chat media lesen" ON storage.objects;
CREATE POLICY "Chat media lesen"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'chat-media');

DROP POLICY IF EXISTS "Chat media hochladen" ON storage.objects;
CREATE POLICY "Chat media hochladen"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'chat-media'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Chat media updaten" ON storage.objects;
CREATE POLICY "Chat media updaten"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'chat-media'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Chat wallpapers lesen" ON storage.objects;
CREATE POLICY "Chat wallpapers lesen"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'chat-wallpapers');

DROP POLICY IF EXISTS "Chat wallpapers hochladen" ON storage.objects;
CREATE POLICY "Chat wallpapers hochladen"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'chat-wallpapers'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Chat wallpapers updaten" ON storage.objects;
CREATE POLICY "Chat wallpapers updaten"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'chat-wallpapers'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Chat wallpapers löschen" ON storage.objects;
CREATE POLICY "Chat wallpapers löschen"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'chat-wallpapers'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
