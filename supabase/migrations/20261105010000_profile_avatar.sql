-- Profile photo from the sign-in provider (e.g. the Google account picture).
-- The app fills it, along with any missing name / phone, right after sign-in.

alter table public.profiles
  add column if not exists avatar_url text;
