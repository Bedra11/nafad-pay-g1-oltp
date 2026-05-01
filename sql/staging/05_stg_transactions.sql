-- ============================================================
-- staging.transaction
--
-- Permissive staging table. All columns TEXT.
-- No constraints. No FK. No UNIQUE. No CHECK.
-- loaded_at is the only metadata column added.
--
-- NOTE: This table intentionally preserves ALL 40 raw columns,
-- including descriptive/denormalized fields (names, labels, codes)
-- that will NOT appear in core.transactions. These are kept here
-- for validation, traceability, and quarantine routing.
-- ============================================================

DROP TABLE IF EXISTS staging.transactions;

CREATE TABLE staging.transactions (
    id                          TEXT,
    reference                   TEXT,
    idempotency_key             TEXT,
    transaction_type            TEXT,
    transaction_type_label      TEXT,
    amount                      TEXT,
    fee                         TEXT,
    total_amount                TEXT,
    currency                    TEXT,
    source_account_id           TEXT,
    source_account_number       TEXT,
    source_user_id              TEXT,
    source_user_name            TEXT,
    destination_account_id      TEXT,
    destination_account_number  TEXT,
    destination_user_id         TEXT,
    destination_user_name       TEXT,
    merchant_id                 TEXT,
    merchant_code               TEXT,
    merchant_name               TEXT,
    agency_id                   TEXT,
    agency_code                 TEXT,
    agency_name                 TEXT,
    agent_id                    TEXT,
    agent_name                  TEXT,
    status                      TEXT,
    failure_reason              TEXT,
    balance_before              TEXT,
    balance_after               TEXT,
    node_id                     TEXT,
    processing_node             TEXT,
    sequence_number             TEXT,
    channel                     TEXT,
    device_type                 TEXT,
    ip_address                  TEXT,
    description                 TEXT,
    transaction_date            TEXT,
    transaction_time            TEXT,
    created_at                  TEXT,
    completed_at                TEXT,
    loaded_at                   TIMESTAMPTZ DEFAULT now()
);
