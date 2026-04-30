CREATE SCHEMA IF NOT EXISTS reference;

-- WILAYAS
CREATE TABLE IF NOT EXISTS reference.wilayas (
    id INTEGER PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    capital TEXT,
    latitude NUMERIC,
    longitude NUMERIC,
    population INTEGER,
    economic_weight NUMERIC
);

-- TRANSACTION TYPES
CREATE TABLE IF NOT EXISTS reference.tx_types (
    id INTEGER PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    label TEXT,
    description TEXT,
    requires_destination BOOLEAN,
    requires_merchant BOOLEAN,
    requires_agency BOOLEAN,
    is_credit BOOLEAN
);

-- CATEGORIES
CREATE TABLE IF NOT EXISTS reference.categories (
    id INTEGER PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    mcc TEXT,
    label TEXT,
    description TEXT,
    avg_min NUMERIC,
    avg_max NUMERIC
);