CREATE TABLE IF NOT EXISTS core.merchants (
    id BIGINT PRIMARY KEY,

    code TEXT NOT NULL UNIQUE,
    name TEXT,

    category_code TEXT NOT NULL
        REFERENCES reference.categories(code),

    wilaya_id INTEGER NOT NULL
        REFERENCES reference.wilayas(id),

    status TEXT,

    created_at TIMESTAMP,
    updated_at TIMESTAMP
);