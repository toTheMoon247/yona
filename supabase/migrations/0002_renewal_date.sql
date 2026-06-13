-- Renewal / due date: optional per-tile calendar date (no time).
-- Run once in the Supabase SQL Editor on the existing project.

alter table public.tiles
  add column if not exists renewal_date date;
