-- =========================================================================
-- សាលារៀន ញូវវីសិន (NEW VISION SCHOOL) - INVENTORY MANAGEMENT SYSTEM
-- SUPABASE POSTGRESQL DATABASE SCHEMA & MIGRATION SCRIPT
-- =========================================================================
-- ការណែនាំ៖ 
-- ១. បើកគណនី Supabase -> ជ្រើសរើស Project របស់អ្នក -> ចូលទៅកាន់ "SQL Editor"
-- ២. ចម្លង (Copy) កូដ SQL ទាំងអស់ខាងក្រោមនេះ រួចបិទភ្ជាប់ (Paste) ចូលក្នុង SQL Editor
-- ៣. ចុចប៊ូតុង "Run" ដើម្បីបង្កើតតារាង និងរៀបចំសិទ្ធិទាំងអស់ដោយស្វ័យប្រវត្តិ។
-- =========================================================================

-- ១. បើក Extension UUID ប្រសិនបើមិនទាន់មាន
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ២. តារាងគណនីអ្នកប្រើប្រាស់ និងសិទ្ធិ (App Users & Roles)
CREATE TABLE IF NOT EXISTS app_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('director', 'stock_staff')),
    email TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ៣. តារាងប្រភេទសម្ភារៈ (Categories)
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ៤. តារាងផ្នែក / ដេប៉ាតឺម៉ង់ (Departments)
CREATE TABLE IF NOT EXISTS departments (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ៥. តារាងបុគ្គលិកសាលា (Staff Directory)
CREATE TABLE IF NOT EXISTS staff (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    dept TEXT,
    role TEXT,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ៦. តារាងបញ្ជីស្តុកមេ (Master Items)
CREATE TABLE IF NOT EXISTS items (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT,
    unit TEXT DEFAULT 'ឯកតា',
    initial_stock NUMERIC DEFAULT 0,
    min_stock NUMERIC DEFAULT 5,
    unit_price NUMERIC DEFAULT 0.00,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ៧. តារាងកត់ត្រាទិញទំនិញចូលស្តុក (Stock In / Procurement)
CREATE TABLE IF NOT EXISTS stock_in (
    id TEXT PRIMARY KEY,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    item_id TEXT REFERENCES items(id) ON DELETE SET NULL,
    item_name TEXT NOT NULL,
    category TEXT,
    qty NUMERIC NOT NULL CHECK (qty > 0),
    unit_price NUMERIC DEFAULT 0.00,
    total_cost NUMERIC GENERATED ALWAYS AS (qty * unit_price) STORED,
    supplier TEXT,
    invoice TEXT,
    receiver TEXT,
    created_by TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ៨. តារាងកត់ត្រាស្នើសុំ និងបញ្ចេញសម្ភារៈពីស្តុក (Stock Out / Requests & Dispatches)
CREATE TABLE IF NOT EXISTS stock_out (
    id TEXT PRIMARY KEY,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    item_id TEXT REFERENCES items(id) ON DELETE SET NULL,
    item_name TEXT NOT NULL,
    category TEXT,
    qty NUMERIC NOT NULL CHECK (qty > 0),
    purpose TEXT,
    req_id TEXT,
    req_name TEXT NOT NULL,
    req_dept TEXT,
    appr_id TEXT,
    appr_name TEXT NOT NULL,
    appr_role TEXT,
    status TEXT DEFAULT 'បានអនុម័ត',
    created_by TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ៩. តារាងទទួលសម្ភារៈប្រគល់ត្រឡប់មកវិញ (Asset Returns)
CREATE TABLE IF NOT EXISTS returns (
    id TEXT PRIMARY KEY,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    item_id TEXT REFERENCES items(id) ON DELETE SET NULL,
    item_name TEXT NOT NULL,
    category TEXT,
    qty NUMERIC NOT NULL CHECK (qty > 0),
    staff_name TEXT NOT NULL,
    condition TEXT DEFAULT 'ល្អធម្មតា (Normal / Good)',
    receiver TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =========================================================================
-- បង្កើត INDEXes សម្រាប់បង្កើនល្បឿន Query ស្វែងរកទិន្នន័យ (Performance Tuning)
-- =========================================================================
CREATE INDEX IF NOT EXISTS idx_items_category ON items(category);
CREATE INDEX IF NOT EXISTS idx_stock_in_date ON stock_in(date);
CREATE INDEX IF NOT EXISTS idx_stock_in_item_id ON stock_in(item_id);
CREATE INDEX IF NOT EXISTS idx_stock_out_date ON stock_out(date);
CREATE INDEX IF NOT EXISTS idx_stock_out_item_id ON stock_out(item_id);
CREATE INDEX IF NOT EXISTS idx_stock_out_req_dept ON stock_out(req_dept);
CREATE INDEX IF NOT EXISTS idx_returns_item_id ON returns(item_id);

-- =========================================================================
-- បញ្ចូលគណនីដំបូងសម្រាប់ នាយកសាលា (Director) និង អ្នកបញ្ចូលស្តុក (Stock Staff)
-- =========================================================================
INSERT INTO app_users (username, password, full_name, role, email)
VALUES 
    ('director', 'director123', 'លោកបណ្ឌិត អ៊ុក វណ្ណា (នាយកសាលា)', 'director', 'director@newvision.edu.kh'),
    ('staff', 'staff123', 'បុគ្គលិកទទួលបន្ទុកស្តុក', 'stock_staff', 'stock@newvision.edu.kh')
ON CONFLICT (username) DO UPDATE 
SET full_name = EXCLUDED.full_name, role = EXCLUDED.role;

-- =========================================================================
-- កំណត់ ROW LEVEL SECURITY (RLS) អនុញ្ញាតឱ្យ WEB CLIENT ដំណើរការបានរលូន
-- =========================================================================
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE items ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_in ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_out ENABLE ROW LEVEL SECURITY;
ALTER TABLE returns ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;

-- បង្កើត Policies អនុញ្ញាតការអាន និងសរសេរសម្រាប់ Anon / Authenticated
DROP POLICY IF EXISTS "Public Read Users" ON app_users;
CREATE POLICY "Public Read Users" ON app_users FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow All Items" ON items;
CREATE POLICY "Allow All Items" ON items FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow All Stock In" ON stock_in;
CREATE POLICY "Allow All Stock In" ON stock_in FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow All Stock Out" ON stock_out;
CREATE POLICY "Allow All Stock Out" ON stock_out FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow All Returns" ON returns;
CREATE POLICY "Allow All Returns" ON returns FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow All Categories" ON categories;
CREATE POLICY "Allow All Categories" ON categories FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow All Departments" ON departments;
CREATE POLICY "Allow All Departments" ON departments FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow All Staff" ON staff;
CREATE POLICY "Allow All Staff" ON staff FOR ALL USING (true) WITH CHECK (true);

-- រួចរាល់ដោយជោគជ័យ!
SELECT 'New Vision School Inventory Schema Created Successfully!' as status;
