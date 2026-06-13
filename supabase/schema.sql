-- Yona — Supabase schema, RLS, and Storage policies
-- Paste into Supabase Studio → SQL Editor and run once on a fresh project.
-- Idempotent where practical; safe-ish to re-run, but review before re-running on real data.

-- =============================================================================
-- 1. Extensions
-- =============================================================================
create extension if not exists "pgcrypto";  -- for gen_random_uuid()

-- =============================================================================
-- 2. Tables
-- =============================================================================

-- Tiles: one per online account/service the user wants to remember.
create table if not exists public.tiles (
  id          uuid        primary key default gen_random_uuid(),
  user_id     uuid        not null default auth.uid() references auth.users(id) on delete cascade,
  title       text        not null check (length(trim(title)) > 0),
  url         text        not null check (length(trim(url)) > 0),
  logo_url    text,                                   -- resolved once at create/edit
  notes       text,                                   -- Option A: single optional text field
  cost_amount numeric(12,2),                          -- optional cost tracking
  cost_period text check (cost_period in ('monthly', 'yearly')),
  renewal_date date,                                  -- optional renewal/due date
  renewal_repeat text check (renewal_repeat in ('monthly', 'yearly')), -- null = one-time
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists tiles_user_id_idx on public.tiles (user_id);

-- Attachments: documents stored in the Storage bucket, one row per file.
-- user_id is denormalized so RLS / Storage policies stay join-free.
-- RESERVED: created now but NOT used by the MVP app — document attachments are a
-- post-MVP (v1.x) feature. Keeping the table here means v2 needs no migration.
create table if not exists public.attachments (
  id            uuid        primary key default gen_random_uuid(),
  tile_id       uuid        not null references public.tiles(id) on delete cascade,
  user_id       uuid        not null default auth.uid() references auth.users(id) on delete cascade,
  filename      text        not null,
  storage_path  text        not null,                 -- {user_id}/{tile_id}/{uuid}-{filename}
  content_type  text,
  size_bytes    bigint,
  created_at    timestamptz not null default now()
);

create index if not exists attachments_tile_id_idx on public.attachments (tile_id);
create index if not exists attachments_user_id_idx on public.attachments (user_id);

-- =============================================================================
-- 3. updated_at trigger for tiles
-- =============================================================================
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists tiles_set_updated_at on public.tiles;
create trigger tiles_set_updated_at
  before update on public.tiles
  for each row execute function public.set_updated_at();

-- =============================================================================
-- 4. Row-Level Security
-- =============================================================================
alter table public.tiles       enable row level security;
alter table public.attachments enable row level security;

-- tiles: owner-only for all operations.
drop policy if exists "tiles_select_own" on public.tiles;
create policy "tiles_select_own" on public.tiles
  for select using (auth.uid() = user_id);

drop policy if exists "tiles_insert_own" on public.tiles;
create policy "tiles_insert_own" on public.tiles
  for insert with check (auth.uid() = user_id);

drop policy if exists "tiles_update_own" on public.tiles;
create policy "tiles_update_own" on public.tiles
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "tiles_delete_own" on public.tiles;
create policy "tiles_delete_own" on public.tiles
  for delete using (auth.uid() = user_id);

-- attachments: owner-only for all operations.
drop policy if exists "attachments_select_own" on public.attachments;
create policy "attachments_select_own" on public.attachments
  for select using (auth.uid() = user_id);

drop policy if exists "attachments_insert_own" on public.attachments;
create policy "attachments_insert_own" on public.attachments
  for insert with check (auth.uid() = user_id);

drop policy if exists "attachments_update_own" on public.attachments;
create policy "attachments_update_own" on public.attachments
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "attachments_delete_own" on public.attachments;
create policy "attachments_delete_own" on public.attachments
  for delete using (auth.uid() = user_id);

-- =============================================================================
-- 5. Storage bucket + policies   (RESERVED — unused until v2 Documents)
-- =============================================================================
-- Private bucket; objects live at {user_id}/{tile_id}/{uuid}-{filename}.
-- The first path segment is the owner's uid, which every policy checks.
-- Created now so the v2 Documents feature is pure app-code with no migration.

insert into storage.buckets (id, name, public)
values ('documents', 'documents', false)
on conflict (id) do nothing;

-- Owner-only access to objects whose first path segment == auth.uid().
-- storage.foldername(name) returns the path segments as a text[]; [1] is the first.
drop policy if exists "documents_select_own" on storage.objects;
create policy "documents_select_own" on storage.objects
  for select using (
    bucket_id = 'documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "documents_insert_own" on storage.objects;
create policy "documents_insert_own" on storage.objects
  for insert with check (
    bucket_id = 'documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "documents_update_own" on storage.objects;
create policy "documents_update_own" on storage.objects
  for update using (
    bucket_id = 'documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "documents_delete_own" on storage.objects;
create policy "documents_delete_own" on storage.objects
  for delete using (
    bucket_id = 'documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- =============================================================================
-- Done. Reminders (not enforced by SQL):
--   • Register redirect URL  yona://auth-callback  in
--     Authentication → URL Configuration → Redirect URLs.
--   • Enable the Google provider (and Apple later) under Authentication → Providers.
--   • Deleting a tile cascades attachment ROWS but NOT Storage OBJECTS —
--     the app must delete the {user_id}/{tile_id}/ folder on tile delete.
--   • Enforce the 25 MB per-file cap client-side (and optionally on the bucket).
-- =============================================================================
