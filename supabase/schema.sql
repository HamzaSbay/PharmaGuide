-- Enable PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. profiles
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    cnop_id TEXT UNIQUE NOT NULL,
    pharmacy_name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. master_drugs
CREATE TABLE IF NOT EXISTS master_drugs (
    id TEXT PRIMARY KEY,
    brand_name TEXT NOT NULL,
    dci_name TEXT NOT NULL,
    dosage TEXT,
    form TEXT,
    pct_code TEXT UNIQUE,
    category TEXT,
    arabic_name TEXT,
    aliases TEXT[],
    requires_prescription BOOLEAN DEFAULT FALSE,
    is_cnam_reimbursable BOOLEAN DEFAULT FALSE,
    is_blacklisted BOOLEAN DEFAULT FALSE,
    side_effects TEXT,
    contraindications TEXT,
    interactions TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. pharmacies
CREATE TABLE IF NOT EXISTS pharmacies (
    id TEXT PRIMARY KEY,
    cnop_id TEXT UNIQUE,
    name TEXT NOT NULL,
    address TEXT,
    governorate TEXT NOT NULL,
    phone TEXT,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    accepts_cnam BOOLEAN DEFAULT FALSE,
    is_garde BOOLEAN DEFAULT FALSE,
    is_open BOOLEAN DEFAULT TRUE,
    owner_id UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. inventories
CREATE TABLE IF NOT EXISTS inventories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pharmacy_id TEXT REFERENCES pharmacies(id) ON DELETE CASCADE,
    drug_id TEXT REFERENCES master_drugs(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 0,
    in_stock BOOLEAN DEFAULT TRUE,
    last_updated TIMESTAMPTZ DEFAULT now(),
    UNIQUE(pharmacy_id, drug_id)
);

-- 5. reservations
CREATE TABLE IF NOT EXISTS reservations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id TEXT NOT NULL,
    patient_phone TEXT,
    pharmacy_id TEXT REFERENCES pharmacies(id),
    drug_id TEXT REFERENCES master_drugs(id),
    prescription_url TEXT,
    status TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING','CONFIRMED','COLLECTED','EXPIRED','DECLINED')),
    created_at TIMESTAMPTZ DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL,
    confirmed_at TIMESTAMPTZ
);

-- 6. b2b_requests
CREATE TABLE IF NOT EXISTS b2b_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_pharmacy_id TEXT REFERENCES pharmacies(id),
    to_pharmacy_id TEXT REFERENCES pharmacies(id),
    drug_id TEXT REFERENCES master_drugs(id),
    quantity INTEGER DEFAULT 1,
    status TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING','APPROVED','REJECTED','COMPLETED')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 7. garde_shifts
CREATE TABLE IF NOT EXISTS garde_shifts (
    id TEXT PRIMARY KEY,
    pharmacy_id TEXT REFERENCES pharmacies(id),
    pharmacy_name TEXT,
    shift_type TEXT CHECK (shift_type IN ('NUIT','DIMANCHE_FERIE','JOUR')),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    governorate TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS pharmacies_location_idx ON pharmacies USING GIST(location);
CREATE INDEX IF NOT EXISTS inventories_pharmacy_drug_idx ON inventories(pharmacy_id, drug_id);
CREATE INDEX IF NOT EXISTS reservations_pharmacy_status_idx ON reservations(pharmacy_id, status);

-- RPC Function
CREATE OR REPLACE FUNCTION find_nearby_pharmacies_with_stock(
  target_drug_id TEXT,
  user_lat DOUBLE PRECISION,
  user_lng DOUBLE PRECISION,
  max_distance_km DOUBLE PRECISION DEFAULT 15.0,
  filter_cnam BOOLEAN DEFAULT FALSE,
  filter_garde BOOLEAN DEFAULT FALSE
) RETURNS TABLE (
    pharmacy_id TEXT,
    name TEXT,
    address TEXT,
    governorate TEXT,
    phone TEXT,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    accepts_cnam BOOLEAN,
    is_garde BOOLEAN,
    is_open BOOLEAN,
    distance_km DOUBLE PRECISION,
    stock_quantity INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id AS pharmacy_id,
    p.name,
    p.address,
    p.governorate,
    p.phone,
    ST_Y(p.location::geometry) AS lat,
    ST_X(p.location::geometry) AS lng,
    p.accepts_cnam,
    p.is_garde,
    p.is_open,
    (ST_Distance(p.location, ST_MakePoint(user_lng, user_lat)::geography) / 1000.0) AS distance_km,
    i.quantity AS stock_quantity
  FROM pharmacies p
  JOIN inventories i ON p.id = i.pharmacy_id
  WHERE i.drug_id = target_drug_id
    AND i.in_stock = true
    AND i.quantity > 0
    AND ST_Distance(p.location, ST_MakePoint(user_lng, user_lat)::geography) <= (max_distance_km * 1000)
    AND (filter_cnam = false OR p.accepts_cnam = true)
    AND (filter_garde = false OR p.is_garde = true)
  ORDER BY distance_km ASC
  LIMIT 20;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS Setup
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE master_drugs ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacies ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventories ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE b2b_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE garde_shifts ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- profiles
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- master_drugs
CREATE POLICY "Drugs are viewable by everyone" ON master_drugs FOR SELECT USING (true);

-- pharmacies
CREATE POLICY "Pharmacies are viewable by everyone" ON pharmacies FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert pharmacies" ON pharmacies FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update pharmacies" ON pharmacies FOR UPDATE TO authenticated USING (true);

-- inventories
CREATE POLICY "Inventories are viewable by everyone" ON inventories FOR SELECT USING (true);
CREATE POLICY "Authenticated users can modify inventories" ON inventories FOR ALL TO authenticated USING (true);

-- reservations
CREATE POLICY "Reservations are viewable by everyone" ON reservations FOR SELECT USING (true);
CREATE POLICY "Anyone can insert reservations" ON reservations FOR INSERT WITH CHECK (true);
CREATE POLICY "Authenticated users can update reservations" ON reservations FOR UPDATE TO authenticated USING (true);

-- b2b_requests
CREATE POLICY "Authenticated users can manage b2b requests" ON b2b_requests FOR ALL TO authenticated USING (true);

-- garde_shifts
CREATE POLICY "Garde shifts are viewable by everyone" ON garde_shifts FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert garde shifts" ON garde_shifts FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated users can update garde shifts" ON garde_shifts FOR UPDATE TO authenticated USING (true);


-- Auto-expire trigger for reservations older than 2 hours
CREATE OR REPLACE FUNCTION check_reservation_expiration() RETURNS trigger AS $$
BEGIN
    IF NEW.status = 'PENDING' AND NEW.expires_at < now() THEN
        NEW.status = 'EXPIRED';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_reservation_expiration
BEFORE UPDATE ON reservations
FOR EACH ROW
EXECUTE FUNCTION check_reservation_expiration();
