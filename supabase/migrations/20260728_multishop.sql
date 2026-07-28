-- =========================================================================
-- Multi-Shop: EINE Datenbank für mehrere Shops (munsby, teelab, …).
--
-- Ziel: ein zentraler Admin sieht/filtert alle Bestellungen aller Shops.
-- Bestehende Daten gehören zu 'munsby'. Neue Shops bekommen eine eigene
-- shop-Kennung, eigenes Bestellnummern-Präfix und eigene Produkte.
--
-- NICHT-DESTRUKTIV: nur ADD COLUMN (mit Default) + CREATE OR REPLACE.
-- Auf der bestehenden munsby-Supabase auszuführen (SQL-Editor). Danach in
-- die munsby-Migrations aufnehmen.
-- =========================================================================

-- ---- 1) Shop-Register: Name + Bestellnummern-Präfix pro Shop -------------
create table if not exists shops (
  shop         text primary key,
  name         text not null,
  order_prefix text not null,
  created_at   timestamptz not null default now()
);

insert into shops (shop, name, order_prefix) values
  ('munsby', 'Creative Lab Munsby', 'CLM'),
  ('teelab', 'TeeLab',              'TL')
on conflict (shop) do nothing;

-- ---- 2) shop-Spalte auf die relevanten Tabellen -------------------------
-- Default 'munsby' -> alle bestehenden Zeilen bleiben munsby.
alter table categories add column if not exists shop text not null default 'munsby' references shops (shop);
alter table products   add column if not exists shop text not null default 'munsby' references shops (shop);
alter table orders     add column if not exists shop text not null default 'munsby' references shops (shop);

create index if not exists products_shop_status_idx on products (shop, status, created_at desc);
create index if not exists orders_shop_created_idx   on orders   (shop, created_at desc);

-- slug pro Shop eindeutig (statt global) – zwei Shops dürfen 'classic' haben.
alter table products   drop constraint if exists products_slug_key;
alter table categories drop constraint if exists categories_slug_key;
create unique index if not exists products_shop_slug_key   on products   (shop, slug);
create unique index if not exists categories_shop_slug_key on categories (shop, slug);

-- ---- 3) Bestand nur wo nötig führen -------------------------------------
-- Munsby verkauft Unikate (track_stock=true). TeeLab druckt on demand ->
-- track_stock=false, keine Reservierung, kein "ausverkauft".
alter table products add column if not exists track_stock boolean not null default true;

-- ---- 4) Bestellzähler pro (shop, jahr) ----------------------------------
alter table order_counters add column if not exists shop text not null default 'munsby' references shops (shop);
alter table order_counters drop constraint if exists order_counters_pkey;
alter table order_counters add  primary key (shop, jahr);

-- ---- 5) Bestellnummer pro Shop: <PRÄFIX>-<JAHR>-<NNNN> -------------------
create or replace function next_order_number(p_shop text) returns text
language plpgsql as $$
declare
  j   int := extract(year from now())::int;
  n   int;
  pfx text;
begin
  select order_prefix into pfx from shops where shop = p_shop;
  if pfx is null then
    raise exception 'UNBEKANNTER_SHOP:%', p_shop;
  end if;
  insert into order_counters (shop, jahr, zaehler) values (p_shop, j, 1)
  on conflict (shop, jahr) do update set zaehler = order_counters.zaehler + 1
  returning zaehler into n;
  return pfx || '-' || j || '-' || lpad(n::text, 4, '0');
end $$;

-- ---- 6) reserve_stock: track_stock beachten -----------------------------
create or replace function reserve_stock(p_items jsonb) returns void
language plpgsql as $$
declare
  it        record;
  v_active  boolean;
  v_tracked boolean;
begin
  for it in
    select (e ->> 'product_id')::uuid as pid, (e ->> 'qty')::int as qty
    from jsonb_array_elements(p_items) e
    order by 1
  loop
    if it.qty is null or it.qty < 1 then
      raise exception 'UNGUELTIGE_MENGE:%', it.pid;
    end if;

    select (status = 'active'), track_stock
      into v_active, v_tracked
      from products where id = it.pid
      for update;

    if not coalesce(v_active, false) then
      raise exception 'AUSVERKAUFT:%', it.pid;   -- inaktiv/unbekannt
    end if;

    if v_tracked then
      update products set stock = stock - it.qty
        where id = it.pid and stock >= it.qty;
      if not found then
        raise exception 'AUSVERKAUFT:%', it.pid; -- Einzelstück vergriffen
      end if;
    end if;
    -- track_stock=false (on demand): keine Reservierung nötig.
  end loop;
end $$;

-- ---- 7) release_stock: nur geführten Bestand zurückgeben ----------------
create or replace function release_stock(p_items jsonb) returns void
language plpgsql as $$
declare it record;
begin
  for it in
    select (e ->> 'product_id')::uuid as pid, (e ->> 'qty')::int as qty
    from jsonb_array_elements(p_items) e order by 1
  loop
    update products set stock = stock + it.qty
      where id = it.pid and track_stock = true;
  end loop;
end $$;

-- ---- 8) create_order: shop mitschreiben ---------------------------------
create or replace function create_order(p_bestellung jsonb, p_positionen jsonb) returns jsonb
language plpgsql as $$
declare
  v_order_id uuid;
  v_nummer   text;
  v_shop     text := coalesce(p_bestellung ->> 'shop', 'munsby');
begin
  perform reserve_stock((
    select jsonb_agg(jsonb_build_object(
      'product_id', e ->> 'product_id',
      'qty',        (e ->> 'qty')::int
    ))
    from jsonb_array_elements(p_positionen) e
  ));

  v_nummer := next_order_number(v_shop);

  insert into orders (
    shop, order_number, email,
    shipping_name, shipping_street, shipping_zip, shipping_city,
    shipping_country, phone, shipping_method,
    shipping_cost_rappen, subtotal_rappen, total_rappen,
    status, note
  ) values (
    v_shop, v_nummer,
    p_bestellung ->> 'email',
    p_bestellung ->> 'shipping_name',
    p_bestellung ->> 'shipping_street',
    p_bestellung ->> 'shipping_zip',
    p_bestellung ->> 'shipping_city',
    coalesce(p_bestellung ->> 'shipping_country', 'CH'),
    p_bestellung ->> 'phone',
    p_bestellung ->> 'shipping_method',
    (p_bestellung ->> 'shipping_cost_rappen')::int,
    (p_bestellung ->> 'subtotal_rappen')::int,
    (p_bestellung ->> 'total_rappen')::int,
    'pending',
    p_bestellung ->> 'note'
  )
  returning id into v_order_id;

  insert into order_items (order_id, product_id, title_snapshot, price_rappen_snapshot, qty)
  select
    v_order_id,
    (e ->> 'product_id')::uuid,
    e ->> 'title_snapshot',
    (e ->> 'price_rappen_snapshot')::int,
    (e ->> 'qty')::int
  from jsonb_array_elements(p_positionen) e;

  return jsonb_build_object('order_id', v_order_id, 'order_number', v_nummer);
end $$;

-- Alte parameterlose Bestellnummer-Funktion wird nicht mehr gebraucht.
drop function if exists next_order_number();

-- ---- 9) Rechte bleiben Server-only (neue Signaturen neu absichern) ------
revoke execute on function next_order_number(text) from public, anon, authenticated;
revoke execute on function reserve_stock(jsonb)    from public, anon, authenticated;
revoke execute on function release_stock(jsonb)    from public, anon, authenticated;
revoke execute on function create_order(jsonb, jsonb) from public, anon, authenticated;

-- HINWEIS: TeeLab-Kategorie + Produkte werden BEWUSST NICHT hier angelegt.
-- Erst muss munbys Frontend/Admin nach shop='munsby' filtern (sonst tauchen
-- TeeLab-Produkte auf munsby.ch auf). Das Seeding liegt in teelab-seed.sql
-- und wird ausgeführt, wenn das TeeLab-Backend scharfgeschaltet wird.
