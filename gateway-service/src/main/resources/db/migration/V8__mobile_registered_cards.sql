CREATE TABLE mobile_registered_cards (
    id VARCHAR(64) PRIMARY KEY,
    owner_id VARCHAR(128) NOT NULL,
    provider_token VARCHAR(255) NOT NULL UNIQUE,
    masked_pan VARCHAR(32) NOT NULL,
    brand VARCHAR(32) NOT NULL,
    holder_name VARCHAR(128) NOT NULL,
    expiry_month INT NOT NULL,
    expiry_year INT NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_mobile_cards_owner_active ON mobile_registered_cards(owner_id, active);
