-- Migration: add_client_id_support_platform_integrations
-- Service: platform
-- Description: Rollback client_id support from platform integration tables

-- Drop client_id indexes
DROP INDEX IF EXISTS idx_platform_webhook_deliveries_client_id;
DROP INDEX IF EXISTS idx_platform_webhooks_client_id;
DROP INDEX IF EXISTS idx_platform_sync_records_client_id;
DROP INDEX IF EXISTS idx_platform_sync_jobs_client_id;
DROP INDEX IF EXISTS idx_platform_integrations_client_id;

-- Drop unique constraints
ALTER TABLE platform_webhook_deliveries 
    DROP CONSTRAINT IF EXISTS platform_webhooks_client_url_unique;

ALTER TABLE platform_webhooks 
    DROP CONSTRAINT IF EXISTS platform_webhooks_client_url_unique;

ALTER TABLE platform_sync_records 
    DROP CONSTRAINT IF EXISTS platform_sync_records_client_external_unique;

-- Remove client_id columns
ALTER TABLE platform_webhook_deliveries DROP COLUMN IF EXISTS client_id;
ALTER TABLE platform_webhooks DROP COLUMN IF EXISTS client_id;
ALTER TABLE platform_sync_records DROP COLUMN IF EXISTS client_id;
ALTER TABLE platform_sync_jobs DROP COLUMN IF EXISTS client_id;

-- Restore original unique constraint
ALTER TABLE platform_integrations 
    DROP CONSTRAINT IF EXISTS platform_integrations_client_integration_unique;

ALTER TABLE platform_integrations 
    ADD CONSTRAINT platform_integrations_tenant_id_integration_name_key 
    UNIQUE (tenant_id, integration_name);

ALTER TABLE platform_integrations DROP COLUMN IF EXISTS client_id;
