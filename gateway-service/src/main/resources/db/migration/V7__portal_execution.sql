CREATE TABLE IF NOT EXISTS portal_execution (
    id VARCHAR(255) PRIMARY KEY,
    idempotency_key VARCHAR(255) NOT NULL UNIQUE,
    amount_minor BIGINT NOT NULL,
    currency VARCHAR(255) NOT NULL,
    merchant_id VARCHAR(255) NOT NULL,
    status VARCHAR(255) NOT NULL,
    response_code VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);
