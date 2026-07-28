-- =========================================================================
-- TeeLab-Produkte in die gemeinsame Supabase (shop='teelab').
--
-- ERST AUSFÜHREN, wenn munsbys Frontend/Admin nach shop='munsby' filtert
-- (sonst erscheinen diese Produkte auf munsby.ch). Feste UUIDs, damit das
-- TeeLab-Frontend (src/data/products.js) sie als product_id referenziert.
-- Voraussetzung: 20260728_multishop.sql wurde ausgeführt.
-- =========================================================================

insert into categories (id, slug, name, sort_order, shop) values
  ('7ee1ab00-0000-4000-8000-0000000000c0', 'golf-tees', 'Golf-Tees', 1, 'teelab')
on conflict (id) do nothing;

-- track_stock=false + is_unique=false: on demand gedruckt, kein "ausverkauft".
insert into products (id, slug, title, category_id, price_rappen, status, shop, track_stock, is_unique, stock) values
  ('7ee1ab00-0000-4000-8000-000000000001', 'fairway-70', 'Fairway 70', '7ee1ab00-0000-4000-8000-0000000000c0',  900, 'active', 'teelab', false, false, 0),
  ('7ee1ab00-0000-4000-8000-000000000002', 'iron-38',    'Iron 38',    '7ee1ab00-0000-4000-8000-0000000000c0',  900, 'active', 'teelab', false, false, 0),
  ('7ee1ab00-0000-4000-8000-000000000003', 'driver-101', 'Driver 101', '7ee1ab00-0000-4000-8000-0000000000c0', 1000, 'active', 'teelab', false, false, 0),
  ('7ee1ab00-0000-4000-8000-000000000004', 'augen-tee',  'Augen-Tee',  '7ee1ab00-0000-4000-8000-0000000000c0', 1400, 'active', 'teelab', false, false, 0),
  ('7ee1ab00-0000-4000-8000-000000000005', 'neon-mix',   'Neon Mix',   '7ee1ab00-0000-4000-8000-0000000000c0', 1200, 'active', 'teelab', false, false, 0)
on conflict (id) do nothing;
