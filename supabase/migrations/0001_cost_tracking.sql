-- Cost tracking: optional per-tile cost (amount + monthly/yearly cadence).
-- Run once in the Supabase SQL Editor on the existing project.

alter table public.tiles
  add column if not exists cost_amount numeric(12,2),
  add column if not exists cost_period text check (cost_period in ('monthly', 'yearly'));
