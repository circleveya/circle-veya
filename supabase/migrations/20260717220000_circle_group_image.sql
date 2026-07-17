-- Circle group profile image + invite member counting fix
ALTER TABLE public.circle_groups
  ADD COLUMN IF NOT EXISTS image_url TEXT;

-- See remote migration circle_group_image_v2 for full RPC/storage setup.
