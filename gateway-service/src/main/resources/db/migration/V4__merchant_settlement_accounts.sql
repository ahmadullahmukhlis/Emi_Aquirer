CREATE TABLE IF NOT EXISTS merchant_settlement_accounts (
  id VARCHAR(64) PRIMARY KEY,
  merchant_id VARCHAR(128) NOT NULL,
  account_reference VARCHAR(256) NOT NULL,
  account_holder_name VARCHAR(256) NOT NULL,
  bank_name VARCHAR(256) NOT NULL,
  masked_account VARCHAR(128) NOT NULL,
  currency VARCHAR(3) NOT NULL,
  payout_schedule VARCHAR(64) NOT NULL,
  status VARCHAR(64) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  CONSTRAINT uq_merchant_settlement_account UNIQUE (merchant_id, account_reference)
);
