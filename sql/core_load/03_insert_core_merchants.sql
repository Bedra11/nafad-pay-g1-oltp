TRUNCATE TABLE core.merchants RESTART IDENTITY CASCADE;

INSERT INTO core.merchants (
    id,
    code,
    name,
    category_code,
    wilaya_id,
    status,
    created_at,
    updated_at
)
SELECT
    NULLIF(m.id, '')::bigint,
    m.code,
    NULLIF(m.name, ''),
    m.category_code,
    NULLIF(m.wilaya_id, '')::integer,
    NULLIF(m.status, ''),
    NULLIF(m.created_at, '')::timestamp,
    NULLIF(m.created_at, '')::timestamp
FROM staging.merchants m
WHERE m.id IS NOT NULL
AND m.id <> ''
AND m.code IS NOT NULL
AND m.code <> ''
AND m.category_code IS NOT NULL
AND m.category_code <> ''
AND m.wilaya_id IS NOT NULL
AND m.wilaya_id <> ''
ON CONFLICT (id) DO NOTHING;