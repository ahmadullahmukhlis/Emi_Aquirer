CREATE TABLE IF NOT EXISTS payment_transactions (
  id VARCHAR(64) PRIMARY KEY, channel VARCHAR(32) NOT NULL, operation_type VARCHAR(64) NOT NULL,
  request_id VARCHAR(128) NOT NULL, idempotency_key VARCHAR(256) NOT NULL, merchant_id VARCHAR(128) NOT NULL,
  terminal_id VARCHAR(128), amount_minor BIGINT, currency VARCHAR(3) NOT NULL, status VARCHAR(32) NOT NULL,
  response_code VARCHAR(16) NOT NULL, stan VARCHAR(16) NOT NULL, rrn VARCHAR(32), original_transaction_id VARCHAR(64),
  iso_snapshot VARCHAR(4000) NOT NULL, created_at TIMESTAMP NOT NULL, updated_at TIMESTAMP NOT NULL,
  CONSTRAINT uk_payment_channel_idempotency UNIQUE(channel, idempotency_key)
);
CREATE TABLE IF NOT EXISTS payment_transaction_events (
  id VARCHAR(64) PRIMARY KEY, transaction_id VARCHAR(64) NOT NULL, status VARCHAR(32) NOT NULL,
  event_type VARCHAR(64) NOT NULL, detail VARCHAR(500) NOT NULL, correlation_id VARCHAR(128), created_at TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_payment_events_transaction ON payment_transaction_events(transaction_id, created_at);
CREATE TABLE IF NOT EXISTS reversal_jobs (
  id VARCHAR(64) PRIMARY KEY, original_transaction_id VARCHAR(64) NOT NULL UNIQUE, status VARCHAR(32) NOT NULL,
  attempts INTEGER NOT NULL, next_attempt_at TIMESTAMP, last_error VARCHAR(1000), resolved_at TIMESTAMP
);
CREATE TABLE IF NOT EXISTS settlement_batches (
  id VARCHAR(128) PRIMARY KEY, merchant_id VARCHAR(128) NOT NULL, business_date DATE NOT NULL, transaction_count INTEGER NOT NULL,
  gross_minor BIGINT NOT NULL, refund_minor BIGINT NOT NULL, fee_minor BIGINT NOT NULL, net_minor BIGINT NOT NULL,
  status VARCHAR(32) NOT NULL, created_at TIMESTAMP NOT NULL, paid_out_at TIMESTAMP,
  CONSTRAINT uk_settlement_merchant_date UNIQUE(merchant_id, business_date)
);
CREATE TABLE IF NOT EXISTS reconciliation_imports (
  id VARCHAR(64) PRIMARY KEY, source_name VARCHAR(256) NOT NULL, checksum VARCHAR(256) NOT NULL,
  business_date VARCHAR(32) NOT NULL, created_at TIMESTAMP NOT NULL
);
CREATE TABLE IF NOT EXISTS reconciliation_exceptions (
  id VARCHAR(64) PRIMARY KEY, transaction_id VARCHAR(64), status VARCHAR(32) NOT NULL,
  detail VARCHAR(1000) NOT NULL, assigned_to VARCHAR(128), resolved_at TIMESTAMP, created_at TIMESTAMP NOT NULL
);
