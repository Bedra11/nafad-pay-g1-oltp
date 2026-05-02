TRUNCATE TABLE core.agencies RESTART IDENTITY CASCADE;

INSERT INTO core.agencies (
    id,
    code,
    name,
    wilaya_id,
    float_balance,
    tier,
    license_number,
    status,
    created_at,
    updated_at
)
SELECT
    NULLIF(a.id, '')::bigint,
    a.code,
    NULLIF(a.name, ''),
    NULLIF(a.wilaya_id, '')::integer,
    NULLIF(a.float_balance, '')::numeric(14,2),
    NULLIF(a.tier, ''),
    NULLIF(a.license_number, ''),
    NULLIF(a.status, ''),
    NULLIF(a.created_at, '')::timestamp,
    NULLIF(a.created_at, '')::timestamp
FROM staging.agencies a
WHERE a.id IS NOT NULL
AND a.id <> ''
AND a.code IS NOT NULL
AND a.code <> ''
AND a.wilaya_id IS NOT NULL
AND a.wilaya_id <> ''
ON CONFLICT (id) DO NOTHING;