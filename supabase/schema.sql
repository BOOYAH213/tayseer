-- Supabase / PostgreSQL schema for Tayseer Al Aga store.
-- Run in Supabase SQL Editor. Enable RLS on every exposed table.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'customer' check (role in ('customer','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name_ar text not null,
  name_en text not null,
  description_ar text not null default '',
  description_en text not null default '',
  category text not null default 'Volkswagen Golf',
  price numeric(12,2) not null check (price >= 0),
  stock integer not null default 0 check (stock >= 0),
  image_url text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists products_active_created_idx on public.products (active, created_at desc);
create index if not exists products_category_idx on public.products (category);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null,
  phone text not null,
  email text,
  status text not null default 'pending' check (status in ('pending','confirmed','shipped','completed','cancelled')),
  total numeric(12,2) not null default 0 check (total >= 0),
  notes text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists orders_created_idx on public.orders (created_at desc);
create index if not exists orders_status_created_idx on public.orders (status, created_at desc);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  quantity integer not null check (quantity > 0),
  unit_price numeric(12,2) not null check (unit_price >= 0)
);
create index if not exists order_items_order_id_idx on public.order_items (order_id);

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists products_touch_updated_at on public.products;
create trigger products_touch_updated_at before update on public.products
for each row execute function public.touch_updated_at();

-- Security-definer helper avoids recursive profile RLS checks.
create or replace function public.is_store_admin()
returns boolean language sql stable security definer set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role = 'admin'
  );
$$;
revoke all on function public.is_store_admin() from public;
grant execute on function public.is_store_admin() to anon, authenticated;

alter table public.profiles enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

drop policy if exists "Users can read own profile" on public.profiles;
create policy "Users can read own profile" on public.profiles
for select to authenticated using (id = (select auth.uid()) or public.is_store_admin());

drop policy if exists "Public can read active products" on public.products;
create policy "Public can read active products" on public.products
for select to anon, authenticated using (active = true or public.is_store_admin());
drop policy if exists "Admins manage products" on public.products;
create policy "Admins manage products" on public.products
for all to authenticated using (public.is_store_admin()) with check (public.is_store_admin());

-- Public can submit an order request. Order details are private to admins.
drop policy if exists "Anyone can submit an order request" on public.orders;
create policy "Anyone can submit an order request" on public.orders
for insert to anon, authenticated with check (status = 'pending' and total >= 0);
drop policy if exists "Admins manage orders" on public.orders;
create policy "Admins manage orders" on public.orders
for all to authenticated using (public.is_store_admin()) with check (public.is_store_admin());

drop policy if exists "Anyone can submit order items" on public.order_items;
create policy "Anyone can submit order items" on public.order_items
for insert to anon, authenticated with check (quantity > 0 and unit_price >= 0);
drop policy if exists "Admins manage order items" on public.order_items;
create policy "Admins manage order items" on public.order_items
for all to authenticated using (public.is_store_admin()) with check (public.is_store_admin());

grant select on public.products to anon, authenticated;
grant insert, update, delete on public.products to authenticated;
grant select on public.profiles to authenticated;
grant insert on public.orders to anon, authenticated;
grant select, update, delete on public.orders to authenticated;
grant insert on public.order_items to anon, authenticated;
grant select, update, delete on public.order_items to authenticated;
