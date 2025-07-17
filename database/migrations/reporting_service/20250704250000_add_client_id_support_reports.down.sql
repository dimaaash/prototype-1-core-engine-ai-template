-- Migration: add_client_id_support_reports
-- Service: reporting
-- Description: Rollback client_id support from reporting tables

-- Drop client_id indexes
DROP INDEX IF EXISTS idx_report_analytics_client_id;
DROP INDEX IF EXISTS idx_dashboards_client_id;
DROP INDEX IF EXISTS idx_report_schedules_client_id;
DROP INDEX IF EXISTS idx_report_instances_client_id;
DROP INDEX IF EXISTS idx_report_definitions_client_id;

-- Restore original unique constraints
ALTER TABLE dashboards 
    DROP CONSTRAINT IF EXISTS dashboards_client_name_unique;

ALTER TABLE dashboards 
    ADD CONSTRAINT dashboards_tenant_id_dashboard_name_key 
    UNIQUE (tenant_id, dashboard_name);

ALTER TABLE report_schedules 
    DROP CONSTRAINT IF EXISTS report_schedules_client_name_unique;

ALTER TABLE report_schedules 
    ADD CONSTRAINT report_schedules_tenant_id_schedule_name_key 
    UNIQUE (tenant_id, schedule_name);

ALTER TABLE report_definitions 
    DROP CONSTRAINT IF EXISTS report_definitions_client_name_unique;

ALTER TABLE report_definitions 
    ADD CONSTRAINT report_definitions_tenant_id_report_name_key 
    UNIQUE (tenant_id, report_name);

-- Remove client_id columns
ALTER TABLE report_analytics DROP COLUMN IF EXISTS client_id;
ALTER TABLE dashboards DROP COLUMN IF EXISTS client_id;
ALTER TABLE report_schedules DROP COLUMN IF EXISTS client_id;
ALTER TABLE report_instances DROP COLUMN IF EXISTS client_id;
ALTER TABLE report_definitions DROP COLUMN IF EXISTS client_id;
