CREATE SCHEMA IF NOT EXISTS core;

CREATE TABLE IF NOT EXISTS core.users (
    id BIGINT PRIMARY KEY,
    nni TEXT NOT NULL UNIQUE,
    phone TEXT NOT NULL,
    full_name TEXT,
    gender TEXT,
    birth_date DATE,
    email TEXT,
    wilaya_id INTEGER NOT NULL REFERENCES reference.wilayas(id),
    status TEXT,
    registration_date TIMESTAMP,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,

    CONSTRAINT chk_users_nni_format CHECK (nni ~ '^[0-9]{10}$'),
    CONSTRAINT chk_users_phone_format CHECK (phone ~ '^\+222[0-9]{8}$')
);