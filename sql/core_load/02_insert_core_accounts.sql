TRUNCATE TABLE core.accounts RESTART IDENTITY CASCADE;

INSERT INTO core.accounts (
    id,
    user_id,
    account_number,
    account_type,
    balance,
    available_balance,
    currency,
    daily_limit,
    monthly_limit,
    status,
    is_primary,
    opened_date,
    last_activity,
    created_at,
    updated_at
)
SELECT
    NULLIF(a.id, '')::bigint,
    NULLIF(a.user_id, '')::bigint,
    a.account_number,
    a.account_type,
    NULLIF(a.balance, '')::numeric(14,2),
    NULLIF(a.available_balance, '')::numeric(14,2),
    COALESCE(NULLIF(a.currency, ''), 'MRU'),
    NULLIF(a.daily_limit, '')::numeric(14,2),
    NULLIF(a.monthly_limit, '')::numeric(14,2),
    a.status,
    CASE 
        WHEN a.is_primary = 'true' THEN true
        WHEN a.is_primary = 'false' THEN false
        ELSE false
    END,
    NULLIF(a.opened_date, '')::date,
    NULLIF(a.last_activity, '')::timestamp,
    NULLIF(a.created_at, '')::timestamp,
    NULLIF(a.updated_at, '')::timestamp
FROM staging.accounts a
JOIN core.users u
ON NULLIF(a.user_id, '')::bigint = u.id
WHERE a.id IS NOT NULL
AND a.id <> ''
AND a.user_id IS NOT NULL
AND a.user_id <> ''
AND a.account_number IS NOT NULL
AND a.account_number <> ''
ON CONFLICT (id) DO NOTHING;