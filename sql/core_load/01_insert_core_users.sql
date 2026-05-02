TRUNCATE TABLE core.users RESTART IDENTITY CASCADE;

INSERT INTO core.users (
    id,
    nni,
    phone,
    full_name,
    gender,
    birth_date,
    email,
    wilaya_id,
    status,
    registration_date,
    created_at,
    updated_at
)
SELECT DISTINCT
    NULLIF(id, '')::bigint,
    nni,
    phone,
    NULLIF(full_name, ''),
    NULLIF(gender, ''),
    NULLIF(birth_date, '')::date,
    NULLIF(email, ''),
    NULLIF(wilaya_id, '')::integer,
    NULLIF(status, ''),
    NULLIF(registration_date, '')::timestamp,
    NULLIF(created_at, '')::timestamp,
    NULLIF(updated_at, '')::timestamp
FROM staging.users
WHERE id IS NOT NULL
AND id <> ''
AND nni ~ '^[0-9]{10}$'
AND phone ~ '^\+222[0-9]{8}$'
AND wilaya_id IS NOT NULL
AND wilaya_id <> ''
ON CONFLICT (id) DO NOTHING;