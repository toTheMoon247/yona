-- 0005_optional_url.sql
-- Make a subscription's URL optional: many real subscriptions have no website
-- (building maintenance fee, in-person gym, insurance via an agent). Drop the
-- "url must be non-empty" check; the column stays NOT NULL but may be "".

alter table public.tiles drop constraint if exists tiles_url_check;
