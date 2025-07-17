-- Migration: add_client_id_support_platform_integrations
-- Service: platform
-- Description: Add client_id support to platform integration tables for multi-client architecture

-- Add client_id to platform_integrations table
ALTER TABLE platform_integrations 
    ADD COLUMN client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE;

-- Update unique constraint to include client_id
ALTER TABLE platform_integrations 
    DROP CONSTRAINT platform_integrations_tenant_id_integration_name_key;

ALTER TABLE platform_integrations 
    ADD CONSTRAINT platform_integrations_client_integration_unique 
    UNIQUE (tenant_id, client_id, integration_name);

-- Add client_id to platform_sync_jobs table
ALTER TABLE platform_sync_jobs 
    ADD COLUMN client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE;

-- Add client_id to platform_sync_records table
ALTER TABLE platform_sync_records 
    ADD COLUMN client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE;

-- Add unique constraint for platform_sync_records
ALTER TABLE platform_sync_records 
    ADD CONSTRAINT platform_sync_records_client_external_unique 
    UNIQUE (tenant_id, client_id, sync_job_id, external_id);

-- Add client_id to platform_webhooks table
ALTER TABLE platform_webhooks 
    ADD COLUMN client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE;

-- Add unique constraint for platform_webhooks
ALTER TABLE platform_webhooks 
    ADD CONSTRAINT platform_webhooks_client_url_unique 
    UNIQUE (tenant_id, client_id, webhook_url);

-- Add client_id to platform_webhook_deliveries table
ALTER TABLE platform_webhook_deliveries 
    ADD COLUMN client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE;

-- Add client_id indexes for performance
CREATE INDEX idx_platform_integrations_client_id ON platform_integrations(client_id);
CREATE INDEX idx_platform_sync_jobs_client_id ON platform_sync_jobs(client_id);
CREATE INDEX idx_platform_sync_records_client_id ON platform_sync_records(client_id);
CREATE INDEX idx_platform_webhooks_client_id ON platform_webhooks(client_id);
CREATE INDEX idx_platform_webhook_deliveries_client_id ON platform_webhook_deliveries(client_id);
