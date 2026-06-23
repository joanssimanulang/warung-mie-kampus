-- ============================================================
-- Warung Gemes - Complete Database Export
-- Generated: 2026-05-23
-- Target: Supabase project (jalankan di SQL Editor Supabase)
-- ============================================================
-- Berisi: schema lengkap (tables, enums, functions, RLS) + data existing
-- (menus, tables, user_roles, orders, order_items)
-- ============================================================

-- ===================== ENUMS =====================
DO $$ BEGIN
  CREATE TYPE public.app_role AS ENUM ('superadmin', 'admin');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.location_type AS ENUM ('kantin', 'ruangan');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.order_status AS ENUM ('menunggu', 'diproses', 'selesai');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.payment_status AS ENUM ('menunggu_pembayaran', 'dibayar', 'gagal');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ===================== FUNCTIONS =====================
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

-- ===================== TABLES =====================
CREATE TABLE IF NOT EXISTS public.menus (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  image_url text,
  price numeric NOT NULL,
  is_available boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.rooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  building text,
  floor text,
  notes text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.tables (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  label text NOT NULL,
  notes text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_name text NOT NULL,
  whatsapp text NOT NULL,
  table_number text,
  room_id uuid REFERENCES public.rooms(id),
  location_type public.location_type NOT NULL DEFAULT 'kantin',
  total_price numeric NOT NULL,
  status public.order_status NOT NULL DEFAULT 'menunggu',
  payment_status public.payment_status NOT NULL DEFAULT 'menunggu_pembayaran',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  menu_id uuid REFERENCES public.menus(id),
  menu_name text NOT NULL,
  unit_price numeric NOT NULL,
  quantity integer NOT NULL,
  subtotal numeric NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  role public.app_role NOT NULL,
  email text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role);
$$;

CREATE OR REPLACE FUNCTION public.is_admin_or_super(_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role IN ('admin','superadmin'));
$$;

-- ===================== TRIGGERS =====================
DROP TRIGGER IF EXISTS trg_menus_updated ON public.menus;
CREATE TRIGGER trg_menus_updated BEFORE UPDATE ON public.menus
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS trg_rooms_updated ON public.rooms;
CREATE TRIGGER trg_rooms_updated BEFORE UPDATE ON public.rooms
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS trg_tables_updated ON public.tables;
CREATE TRIGGER trg_tables_updated BEFORE UPDATE ON public.tables
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

DROP TRIGGER IF EXISTS trg_orders_updated ON public.orders;
CREATE TRIGGER trg_orders_updated BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- ===================== RLS =====================
ALTER TABLE public.menus       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tables      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles  ENABLE ROW LEVEL SECURITY;

-- menus
CREATE POLICY "Anyone can view menus" ON public.menus FOR SELECT USING (true);
CREATE POLICY "Admin can insert menus" ON public.menus FOR INSERT TO authenticated WITH CHECK (public.is_admin_or_super(auth.uid()));
CREATE POLICY "Admin can update menus" ON public.menus FOR UPDATE TO authenticated USING (public.is_admin_or_super(auth.uid()));
CREATE POLICY "Admin can delete menus" ON public.menus FOR DELETE TO authenticated USING (public.is_admin_or_super(auth.uid()));

-- rooms
CREATE POLICY "Anyone can view rooms" ON public.rooms FOR SELECT USING (true);
CREATE POLICY "Admin can insert rooms" ON public.rooms FOR INSERT TO authenticated WITH CHECK (public.is_admin_or_super(auth.uid()));
CREATE POLICY "Admin can update rooms" ON public.rooms FOR UPDATE TO authenticated USING (public.is_admin_or_super(auth.uid()));
CREATE POLICY "Admin can delete rooms" ON public.rooms FOR DELETE TO authenticated USING (public.is_admin_or_super(auth.uid()));

-- tables
CREATE POLICY "Anyone can view tables" ON public.tables FOR SELECT USING (true);
CREATE POLICY "Admin can insert tables" ON public.tables FOR INSERT TO authenticated WITH CHECK (public.is_admin_or_super(auth.uid()));
CREATE POLICY "Admin can update tables" ON public.tables FOR UPDATE TO authenticated USING (public.is_admin_or_super(auth.uid()));
CREATE POLICY "Admin can delete tables" ON public.tables FOR DELETE TO authenticated USING (public.is_admin_or_super(auth.uid()));

-- orders
CREATE POLICY "Anyone can read orders" ON public.orders FOR SELECT USING (true);
CREATE POLICY "Anyone can create orders" ON public.orders FOR INSERT WITH CHECK (true);
CREATE POLICY "Admin can update orders" ON public.orders FOR UPDATE TO authenticated USING (public.is_admin_or_super(auth.uid()));
CREATE POLICY "Admin can delete orders" ON public.orders FOR DELETE TO authenticated USING (public.is_admin_or_super(auth.uid()));

-- order_items
CREATE POLICY "Anyone can read order_items" ON public.order_items FOR SELECT USING (true);
CREATE POLICY "Anyone can insert order_items" ON public.order_items FOR INSERT WITH CHECK (true);
CREATE POLICY "Admin can delete order_items" ON public.order_items FOR DELETE TO authenticated USING (public.is_admin_or_super(auth.uid()));

-- user_roles
CREATE POLICY "Users can view their own roles" ON public.user_roles FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Superadmin can view all roles" ON public.user_roles FOR SELECT TO authenticated USING (public.has_role(auth.uid(), 'superadmin'));
CREATE POLICY "Superadmin can insert roles" ON public.user_roles FOR INSERT TO authenticated WITH CHECK (public.has_role(auth.uid(), 'superadmin'));
CREATE POLICY "Superadmin can update roles" ON public.user_roles FOR UPDATE TO authenticated USING (public.has_role(auth.uid(), 'superadmin'));
CREATE POLICY "Superadmin can delete roles" ON public.user_roles FOR DELETE TO authenticated USING (public.has_role(auth.uid(), 'superadmin'));

-- ===================== STORAGE BUCKET =====================
INSERT INTO storage.buckets (id, name, public)
VALUES ('menu-images', 'menu-images', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Public read menu images" ON storage.objects FOR SELECT USING (bucket_id = 'menu-images');
CREATE POLICY "Admin upload menu images" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'menu-images' AND public.is_admin_or_super(auth.uid()));
CREATE POLICY "Admin update menu images" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'menu-images' AND public.is_admin_or_super(auth.uid()));
CREATE POLICY "Admin delete menu images" ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'menu-images' AND public.is_admin_or_super(auth.uid()));

-- ============================================================
-- DATA SEED (existing data dari Lovable Cloud)
-- ============================================================

-- ----- MENUS -----
INSERT INTO public.menus (id, name, description, price, image_url, is_available) VALUES
  ('47ef11bc-ee8d-4586-be5e-d610966b6770','Mie Ayam Original','Mie kenyal dengan topping ayam kecap dan pangsit',15000,'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600',true),
  ('e79db366-ea18-4ef4-bf93-dfe761ca3673','Mie Ayam Bakso','Mie ayam ditambah bakso sapi pilihan',18000,'https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?w=600',true),
  ('f54150f1-705b-45cf-a59c-4e30b0bb3032','Mie Yamin Manis','Mie kecap manis dengan ayam suwir, favorit mahasiswa',16000,'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=600',true),
  ('5b30859d-7d7d-4866-8cdd-7c438ffef1a9','Mie Pedas Setan','Level pedas tinggi, cocok buat begadang',17000,'https://images.unsplash.com/photo-1626804475297-41608ea09aeb?w=600',true),
  ('9c9c376d-0a86-439b-a6c3-7b97f4ba8a82','Es Teh Manis','Segar dingin, teman makan mie',5000,'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=600',true),
  ('64bbcf19-7439-4602-8903-2e05601645cc','Es Jeruk','Jeruk peras asli',7000,'https://images.unsplash.com/photo-1546171753-97d7676e4602?w=600',true)
ON CONFLICT (id) DO NOTHING;

-- ----- TABLES (meja kantin) -----
INSERT INTO public.tables (id, label, is_active) VALUES
  ('0a1267d8-0ed4-488b-b03a-5eee9bef0adf','1',true),
  ('d608dfc4-a6b1-43d2-925f-c5af2b8b7c70','2',true),
  ('5cada32e-c133-4f72-99ef-e55519388817','3',true),
  ('c0f7f7d1-e029-4075-8299-b551b360c617','4',true),
  ('0f4dc565-659d-468a-9bd0-931d6dd0d65d','5',true),
  ('22a01494-8d77-4be0-927e-0b6825b3dd36','6',true),
  ('7a6acfc2-95c9-4a4b-b1a9-84a64875e8c2','7',true),
  ('b52c2dfa-52e3-4957-9029-1f0672e9f18d','8',true),
  ('2581fa90-c2b3-4533-a31d-ec3f9c32859f','9',true),
  ('784589cb-bd9d-43bf-8ed2-f679036862fe','10',true)
ON CONFLICT (id) DO NOTHING;

-- ----- ROOMS -----
-- (Belum ada data ruangan. Tambahkan via UI /admin/locations setelah deploy.)

-- ----- USER ROLES -----
-- CATATAN: user_id berikut merujuk ke auth.users di project Supabase LAMA.
-- Setelah signup user baru di project Supabase BARU, ganti user_id di bawah
-- dengan UUID user baru (lihat di Authentication > Users).
INSERT INTO public.user_roles (user_id, role, email) VALUES
  ('bfcf86ec-7c97-4c44-af61-04b5a2a7f01f','superadmin','owner@warung.test')
ON CONFLICT (user_id, role) DO NOTHING;

-- ----- ORDERS (riwayat pesanan) -----
INSERT INTO public.orders (id, customer_name, whatsapp, table_number, total_price, status, payment_status, location_type, room_id, created_at) VALUES
  ('0f17b235-3209-45bf-9813-b330018b3f76','mo','0895346832460','1',30000,'diproses','menunggu_pembayaran','kantin',NULL,'2026-05-11T04:06:53Z'),
  ('69b98ab1-fa76-4b0b-995a-e50fbdd1ca52','ko','895346832460','1',30000,'menunggu','menunggu_pembayaran','kantin',NULL,'2026-05-11T05:11:32Z'),
  ('c4821d95-afbe-4670-b21f-d6a661a05c24','hu','0895346832460','2',15000,'selesai','menunggu_pembayaran','kantin',NULL,'2026-05-18T11:35:28Z')
ON CONFLICT (id) DO NOTHING;

-- ----- ORDER ITEMS -----
INSERT INTO public.order_items (id, order_id, menu_id, menu_name, unit_price, quantity, subtotal) VALUES
  ('4b7b68c2-f0da-4379-9699-96900290b136','0f17b235-3209-45bf-9813-b330018b3f76','47ef11bc-ee8d-4586-be5e-d610966b6770','Mie Ayam Original',15000,2,30000),
  ('baaa716d-2159-44bf-953d-6c4c3218fa1e','69b98ab1-fa76-4b0b-995a-e50fbdd1ca52','47ef11bc-ee8d-4586-be5e-d610966b6770','Mie Ayam Original',15000,2,30000),
  ('6eca4fff-2eed-4a94-aba5-07537ad89fb9','c4821d95-afbe-4670-b21f-d6a661a05c24','47ef11bc-ee8d-4586-be5e-d610966b6770','Mie Ayam Original',15000,1,15000)
ON CONFLICT (id) DO NOTHING;
