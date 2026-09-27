CREATE TABLE IF NOT EXISTS aps_response_codes (
  code VARCHAR(16) PRIMARY KEY, description VARCHAR(256) NOT NULL, category VARCHAR(64) NOT NULL,
  retryable BOOLEAN NOT NULL, operations_action VARCHAR(128) NOT NULL
);
