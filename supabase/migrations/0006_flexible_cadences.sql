-- 0006_flexible_cadences.sql
-- Allow more billing/renewal cadences than monthly/yearly (e.g. a house-council bill
-- billed every 2 months). Relax the cost_period and renewal_repeat checks to the full
-- set: weekly · monthly · every_two_months · quarterly · every_six_months · yearly.

alter table public.tiles drop constraint if exists tiles_cost_period_check;
alter table public.tiles add constraint tiles_cost_period_check
  check (cost_period in (
    'weekly', 'monthly', 'every_two_months', 'quarterly', 'every_six_months', 'yearly'
  ));

alter table public.tiles drop constraint if exists tiles_renewal_repeat_check;
alter table public.tiles add constraint tiles_renewal_repeat_check
  check (renewal_repeat in (
    'weekly', 'monthly', 'every_two_months', 'quarterly', 'every_six_months', 'yearly'
  ));
