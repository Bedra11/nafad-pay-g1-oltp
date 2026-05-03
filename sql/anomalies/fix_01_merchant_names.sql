-- ============================================================
-- FIX 1 : Merchant names contain "undefined" prefix
-- Root cause : JavaScript undefined concatenated during seed
-- Solution   : Replace with category label derived from category_code
-- Run        : docker exec -i nafadpay-postgres psql -U admin -d nafadpay < fix_01_merchant_names.sql
-- ============================================================

-- Option A – one-liner regex (fastest, no per-row listing needed)
-- Replaces "undefined " with the French category label based on category_code FK
UPDATE core.merchants
SET name = REPLACE(name, 'undefined ',
    CASE category_code
        WHEN 'ALM' THEN 'Alimentation '
        WHEN 'RST' THEN 'Restaurant '
        WHEN 'TRN' THEN 'Transport '
        WHEN 'TEL' THEN 'Télécom '
        WHEN 'CRB' THEN 'Carburant '
        WHEN 'SAN' THEN 'Santé '
        WHEN 'HAB' THEN 'Habillement '
        WHEN 'ELC' THEN 'Électronique '
        WHEN 'BTP' THEN 'BTP '
        WHEN 'EDU' THEN 'Éducation '
        WHEN 'SRV' THEN 'Services '
        WHEN 'HTL' THEN 'Hôtellerie '
        WHEN 'AUT' THEN 'Autres '
        ELSE ''
    END
)
WHERE name LIKE 'undefined %';

-- Verify – should return 0 rows after fix
SELECT COUNT(*) AS still_broken
FROM core.merchants
WHERE name LIKE 'undefined %';

-- Preview sample
SELECT code, category_code, name
FROM core.merchants
ORDER BY category_code, name
LIMIT 20;
