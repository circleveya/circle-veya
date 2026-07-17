-- Gallery visibility + get_profile/get_user_level_stats updates
-- (applied remotely via MCP as gallery_visibility + get_profile_gallery_public + challenge_detail_v2)

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS gallery_public BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE public.user_challenges
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS how_to TEXT;
