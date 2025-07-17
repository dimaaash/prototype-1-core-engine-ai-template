-- Migration: create_platform_integrations_table (DOWN)
-- Service: platform
-- Description: Drop platform integration and synchronization tables

-- Drop indexes first
DROP INDEX IF EXISTS idx_platform_webhook_deliveries_delivered_at;
DROP INDEX IF EXISTS idx_platform_webhook_deliveries_event_type;
DROP INDEX IF EXISTS idx_platform_webhook_deliveries_status;
DROP INDEX IF EXISTS idx_platform_webhook_deliveries_webhook_id;
DROP INDEX IF EXISTS idx_platform_webhook_deliveries_tenant_id;

DROP INDEX IF EXISTS idx_platform_webhooks_status;
DROP INDEX IF EXISTS idx_platform_webhooks_active;
DROP INDEX IF EXISTS idx_platform_webhooks_integration_id;
DROP INDEX IF EXISTS idx_platform_webhooks_tenant_id;

DROP INDEX IF EXISTS idx_platform_sync_records_status;
DROP INDEX IF EXISTS idx_platform_sync_records_external_id;
DROP INDEX IF EXISTS idx_platform_sync_records_entity;
DROP INDEX IF EXISTS idx_platform_sync_records_integration_id;
DROP INDEX IF EXISTS idx_platform_sync_records_job_id;
DROP INDEX IF EXISTS idx_platform_sync_records_tenant_id;

DROP INDEX IF EXISTS idx_platform_sync_jobs_type;
DROP INDEX IF EXISTS idx_platform_sync_jobs_scheduled_at;
DROP INDEX IF EXISTS idx_platform_sync_jobs_status;
DROP INDEX IF EXISTS idx_platform_sync_jobs_integration_id;
DROP INDEX IF EXISTS idx_platform_sync_jobs_tenant_id;

DROP INDEX IF EXISTS idx_platform_integrations_next_sync;
DROP INDEX IF EXISTS idx_platform_integrations_sync_enabled;
DROP INDEX IF EXISTS idx_platform_integrations_enabled;
DROP INDEX IF EXISTS idx_platform_integrations_status;
DROP INDEX IF EXISTS idx_platform_integrations_provider;
DROP INDEX IF EXISTS idx_platform_integrations_type;
DROP INDEX IF EXISTS idx_platform_integrations_tenant_id;

-- Drop triggers
DROP TRIGGER IF EXISTS trigger_platform_webhooks_updated_at ON platform_webhooks;
DROP TRIGGER IF EXISTS trigger_platform_sync_jobs_updated_at ON platform_sync_jobs;
DROP TRIGGER IF EXISTS trigger_platform_integrations_updated_at ON platform_integrations;

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS platform_webhook_deliveries;
DROP TABLE IF EXISTS platform_webhooks;
DROP TABLE IF EXISTS platform_sync_records;
DROP TABLE IF EXISTS platform_sync_jobs;
DROP TABLE IF EXISTS platform_integrations;
