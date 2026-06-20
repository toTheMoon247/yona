-- 0004_payment_info.sql
-- "How it's paid" per subscription (optional): where it's billed, and optionally the
-- funding method. Store only a card type + last 4 (e.g. "Visa ••1234") — NEVER full
-- card numbers, expiry, or CVV.

alter table public.tiles
  add column if not exists billing_source text
    check (billing_source in ('app_store', 'google_play', 'direct', 'bank', 'other')),
  add column if not exists payment_method text;
