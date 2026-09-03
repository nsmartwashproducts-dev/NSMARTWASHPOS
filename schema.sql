-- ============================================================================
-- N-SMART WASH POS — Supabase database schema
-- ============================================================================
-- Run this once in your Supabase project's SQL Editor (Project > SQL Editor >
-- New query > paste all of this > Run). It creates the three tables the POS
-- app needs, turns on Realtime so every device sees changes instantly, and
-- loads the same starting data that was in the N-SMART WASH Excel workbook
-- (PRODUCTS, POS_SETTINGS and POS_SALES sheets).
--
-- SECURITY NOTE — read this before going live:
-- The policies below allow anyone who has your project URL + anon key (i.e.
-- your sales team, since that's what the app uses) to read and write every
-- row. That's the simplest way to get a shared team tool running fast. If
-- this data becomes sensitive or the app is exposed publicly, add Supabase
-- Auth (email/password or magic link) and tighten these policies to check
-- auth.uid() before write access. Anthropic/Claude cannot host or secure
-- this for you — this file only sets up the database you control.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. TABLES
-- ---------------------------------------------------------------------------

create table if not exists public.products (
  id          text primary key,
  name        text not null,
  volume      text default '',
  price       numeric not null default 0,
  updated_at  timestamptz not null default now()
);

create table if not exists public.sales (
  id          text primary key,
  date        date not null,
  customer    text not null default '',
  product     text not null default '',
  volume      text default '',
  qty         numeric not null default 0,
  price       numeric not null default 0,
  discount    numeric not null default 0,
  net         numeric not null default 0,
  payment     text default '',
  region      text default '',
  district    text default '',
  notes       text default '',
  updated_at  timestamptz not null default now()
);

create table if not exists public.settings (
  id                text primary key default 'default',
  business_name     text default 'N-SMART WASH',
  tagline           text default '',
  currency          text default 'TZS',
  payment_methods   text[] default array['CASH','MOBILE MONEY','BANK','CREDIT'],
  default_region    text default '',
  default_district  text default '',
  updated_at        timestamptz not null default now()
);

-- Keep updated_at fresh automatically on every write.
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_products_touch on public.products;
create trigger trg_products_touch before update on public.products
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_sales_touch on public.sales;
create trigger trg_sales_touch before update on public.sales
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_settings_touch on public.settings;
create trigger trg_settings_touch before update on public.settings
  for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- 2. ROW LEVEL SECURITY  (see security note above)
-- ---------------------------------------------------------------------------

alter table public.products enable row level security;
alter table public.sales    enable row level security;
alter table public.settings enable row level security;

drop policy if exists "team read/write products" on public.products;
create policy "team read/write products" on public.products
  for all using (true) with check (true);

drop policy if exists "team read/write sales" on public.sales;
create policy "team read/write sales" on public.sales
  for all using (true) with check (true);

drop policy if exists "team read/write settings" on public.settings;
create policy "team read/write settings" on public.settings
  for all using (true) with check (true);

-- ---------------------------------------------------------------------------
-- 3. REALTIME  (so every teammate's browser updates live)
-- ---------------------------------------------------------------------------

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname='public' and tablename='products'
  ) then
    alter publication supabase_realtime add table public.products;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname='public' and tablename='sales'
  ) then
    alter publication supabase_realtime add table public.sales;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname='public' and tablename='settings'
  ) then
    alter publication supabase_realtime add table public.settings;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 4. SEED DATA
--    Pulled straight from your uploaded workbook: the PRODUCTS sheet, the
--    POS_SETTINGS sheet, and the 11 historical rows in POS_SALES.
--    Safe to re-run: it upserts, it will not create duplicates.
-- ---------------------------------------------------------------------------

insert into public.products (id, name, volume, price) values
  ('p1', 'SABUNI NUSU LTR',           '500ml',  1000),
  ('p2', 'SABUNI LTR MOJA',           '1L',     2000),
  ('p3', 'Multipurpose Liquid Soap',  'Bottle', 0),
  ('p4', 'Shower Jelly',              'Bottle', 0),
  ('p5', 'Shampoo',                   'Bottle', 0),
  ('p6', 'Dish Wash',                 'Bottle', 0),
  ('p7', 'Toilet Cleaner',            'Bottle', 0)
on conflict (id) do update set
  name = excluded.name, volume = excluded.volume, price = excluded.price;

insert into public.settings (id, business_name, tagline, currency, payment_methods, default_region, default_district) values
  ('default', 'N-SMART WASH PRODUCTS', 'Smart people with N-SMART WASH', 'TZS',
   array['CASH','MOBILE MONEY','BANK','CREDIT'], 'DAR ES SALAAM', 'UBUNGO')
on conflict (id) do update set
  business_name = excluded.business_name, tagline = excluded.tagline, currency = excluded.currency,
  payment_methods = excluded.payment_methods, default_region = excluded.default_region,
  default_district = excluded.default_district;

insert into public.sales (id, date, customer, product, volume, qty, price, discount, net, payment, region, district, notes) values
  ('s1',  '2026-08-17', 'NDOGO', 'SABUNI NUSU LTR', '500ml', 6, 1000, 0, 6000,  'CASH', 'DAR ES SALAAM', 'UBUNGO', ''),
  ('s2',  '2026-08-17', 'KUBWA', 'SABUNI LTR MOJA', '1L',    5, 2000, 0, 10000, 'CASH', 'DAR ES SALAAM', 'UBUNGO', ''),
  ('s3',  '2026-08-18', 'KUBWA', 'SABUNI LTR MOJA', '1L',    1, 2000, 0, 2000,  'CASH', 'DAR ES SALAAM', 'UBUNGO', ''),
  ('s4',  '2026-08-19', 'KUBWA', 'SABUNI LTR MOJA', '1L',    2, 2000, 0, 4000,  'CASH', 'DAR ES SALAAM', 'UBUNGO', ''),
  ('s5',  '2026-08-19', 'NDOGO', 'SABUNI NUSU LTR', '500ml', 3, 1000, 0, 3000,  'CASH', 'DAR ES SALAAM', 'UBUNGO', ''),
  ('s6',  '2026-08-20', 'KUBWA', 'SABUNI LTR MOJA', '1L',    1, 2000, 0, 2000,  'CASH', 'DAR ES SALAAM', 'UBUNGO', ''),
  ('s7',  '2026-08-21', 'NDOGO', 'SABUNI NUSU LTR', '500ml', 1, 1000, 0, 1000,  'CASH', 'DAR ES SALAAM', 'UBUNGO', ''),
  ('s8',  '2026-08-25', 'NDOGO', 'SABUNI NUSU LTR', '500ml', 1, 1000, 0, 1000,  'CASH', 'DAR ES SALAAM', 'UBUNGO', ''),
  ('s9',  '2026-08-25', 'KUBWA', 'SABUNI LTR MOJA', '1L',    1, 2000, 0, 2000,  'CASH', 'DAR ES SALAAM', 'UBUNGO', ''),
  ('s10', '2026-08-27', 'KUBWA', 'SABUNI LTR MOJA', '1L',    1, 2000, 0, 2000,  'CASH', 'DAR ES SALAAM', 'UBUNGO', ''),
  ('s11', '2026-08-27', 'NDOGO', 'SABUNI NUSU LTR', '500ml', 2, 1000, 0, 2000,  'CASH', 'DAR ES SALAAM', 'UBUNGO', '')
on conflict (id) do update set
  date=excluded.date, customer=excluded.customer, product=excluded.product, volume=excluded.volume,
  qty=excluded.qty, price=excluded.price, discount=excluded.discount, net=excluded.net,
  payment=excluded.payment, region=excluded.region, district=excluded.district, notes=excluded.notes;

-- Done. Next: open Project Settings > API in Supabase, copy the "Project URL"
-- and the "anon public" key, and paste them into the app's Settings tab
-- under "Database connection".
