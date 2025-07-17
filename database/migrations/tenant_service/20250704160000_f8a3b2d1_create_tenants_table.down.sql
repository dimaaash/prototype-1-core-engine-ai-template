-- Rollback: create_tenants_table
-- Service: tenant

-- Drop triggers
DROP TRIGGER IF EXISTS trigger_tenants_updated_at ON tenants;
DROP TRIGGER IF EXISTS trigger_tenant_configurations_updated_at ON tenant_configurations;
DROP TRIGGER IF EXISTS trigger_tenant_subscriptions_updated_at ON tenant_subscriptions;
DROP TRIGGER IF EXISTS trigger_tenant_domains_updated_at ON tenant_domains;

-- Drop tables (in reverse order of creation)
DROP TABLE IF EXISTS tenant_domains;
DROP TABLE IF EXISTS tenant_subscriptions;
DROP TABLE IF EXISTS tenant_api_keys;
DROP TABLE IF EXISTS tenant_configurations;
DROP TABLE IF EXISTS tenants;
