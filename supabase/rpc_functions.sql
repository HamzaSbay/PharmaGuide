-- ====================================================================
-- PHARMAGUIDE TN: SUPABASE RPC SPATIAL & FUZZY SEARCH FUNCTIONS
-- ====================================================================

-- 1. Spatial Stock Locator Query (PostGIS ST_DWithin & ST_Distance)
CREATE OR REPLACE FUNCTION find_nearby_pharmacies_with_stock(
    p_drug_id UUID,
    p_user_lat DOUBLE PRECISION,
    p_user_lng DOUBLE PRECISION,
    p_radius_km DOUBLE PRECISION DEFAULT 10.0,
    p_requires_cnam BOOLEAN DEFAULT FALSE,
    p_only_garde BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    pharmacy_id UUID,
    cnop_id VARCHAR(50),
    pharmacy_name VARCHAR(255),
    governorate VARCHAR(100),
    municipality VARCHAR(100),
    address TEXT,
    phone_landline VARCHAR(20),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    accepts_cnam BOOLEAN,
    is_garde BOOLEAN,
    distance_km DOUBLE PRECISION,
    stock_quantity INT,
    last_updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
AS $$
DECLARE
    user_point GEOGRAPHY;
BEGIN
    user_point := ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography;

    RETURN QUERY
    SELECT 
        p.id AS pharmacy_id,
        p.cnop_id,
        p.name AS pharmacy_name,
        p.governorate,
        p.municipality,
        p.address,
        p.phone_landline,
        ST_Y(p.location::geometry) AS latitude,
        ST_X(p.location::geometry) AS longitude,
        p.accepts_cnam,
        EXISTS (
            SELECT 1 FROM garde_schedules g 
            WHERE g.pharmacy_id = p.id 
              AND CURRENT_DATE BETWEEN g.start_date AND g.end_date
        ) AS is_garde,
        ROUND((ST_Distance(p.location, user_point) / 1000.0)::numeric, 2)::DOUBLE PRECISION AS distance_km,
        COALESCE(i.quantity, 0) AS stock_quantity,
        i.last_updated_at
    FROM pharmacies p
    JOIN inventory i ON p.id = i.pharmacy_id
    WHERE i.drug_id = p_drug_id
      AND i.quantity > 0
      AND p.status = 'APPROVED'
      AND ST_DWithin(p.location, user_point, p_radius_km * 1000)
      AND (NOT p_requires_cnam OR p.accepts_cnam = TRUE)
      AND (NOT p_only_garde OR EXISTS (
            SELECT 1 FROM garde_schedules g 
            WHERE g.pharmacy_id = p.id 
              AND CURRENT_DATE BETWEEN g.start_date AND g.end_date
      ))
    ORDER BY distance_km ASC;
END;
$$;


-- 2. Fuzzy Drug Search & Generic Alternative Lookup Function
CREATE OR REPLACE FUNCTION search_master_drugs(
    p_query TEXT
)
RETURNS TABLE (
    id UUID,
    brand_name VARCHAR(255),
    dci_name VARCHAR(255),
    dosage VARCHAR(100),
    form VARCHAR(100),
    pct_code VARCHAR(50),
    requires_prescription BOOLEAN,
    similarity_score REAL
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        d.id,
        d.brand_name,
        d.dci_name,
        d.dosage,
        d.form,
        d.pct_code,
        d.requires_prescription,
        GREATEST(
            similarity(d.brand_name, p_query),
            similarity(d.dci_name, p_query)
        ) AS similarity_score
    FROM master_drugs d
    WHERE d.is_blacklisted = FALSE
      AND (
          d.brand_name ILIKE '%' || p_query || '%'
          OR d.dci_name ILIKE '%' || p_query || '%'
          OR similarity(d.brand_name, p_query) > 0.2
          OR similarity(d.dci_name, p_query) > 0.2
      )
    ORDER BY similarity_score DESC, d.brand_name ASC
    LIMIT 20;
END;
$$;
