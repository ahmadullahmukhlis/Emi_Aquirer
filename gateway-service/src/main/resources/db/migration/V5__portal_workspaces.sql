ALTER TABLE developer_organizations ADD COLUMN IF NOT EXISTS owner_subject VARCHAR(256);
CREATE TABLE IF NOT EXISTS workspace_memberships (
  id VARCHAR(64) PRIMARY KEY,
  organization_id VARCHAR(64) NOT NULL,
  subject VARCHAR(256) NOT NULL,
  role VARCHAR(32) NOT NULL,
  status VARCHAR(32) NOT NULL,
  invited_by VARCHAR(256),
  created_at TIMESTAMP NOT NULL,
  CONSTRAINT uq_workspace_member UNIQUE (organization_id, subject)
);
