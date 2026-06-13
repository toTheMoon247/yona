-- Renewal recurrence: how often the renewal date repeats (null = one-time).
-- Run once in the Supabase SQL Editor on the existing project.

alter table public.tiles
  add column if not exists renewal_repeat text check (renewal_repeat in ('monthly', 'yearly'));
