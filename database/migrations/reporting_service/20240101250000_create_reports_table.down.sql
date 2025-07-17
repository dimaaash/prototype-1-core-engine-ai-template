-- Migration: create_reports_table (DOWN)
-- Service: reporting
-- Description: Drop reporting and analytics system tables

-- Drop indexes first
DROP INDEX IF EXISTS idx_report_analytics_user_id;
DROP INDEX IF EXISTS idx_report_analytics_event_date;
DROP INDEX IF EXISTS idx_report_analytics_event_type;
DROP INDEX IF EXISTS idx_report_analytics_dashboard_id;
DROP INDEX IF EXISTS idx_report_analytics_report_id;
DROP INDEX IF EXISTS idx_report_analytics_tenant_id;

DROP INDEX IF EXISTS idx_dashboard_widgets_visible;
DROP INDEX IF EXISTS idx_dashboard_widgets_report_id;
DROP INDEX IF EXISTS idx_dashboard_widgets_type;
DROP INDEX IF EXISTS idx_dashboard_widgets_dashboard_id;

DROP INDEX IF EXISTS idx_dashboards_created_by;
DROP INDEX IF EXISTS idx_dashboards_default;
DROP INDEX IF EXISTS idx_dashboards_active;
DROP INDEX IF EXISTS idx_dashboards_tenant_id;

DROP INDEX IF EXISTS idx_report_schedules_frequency;
DROP INDEX IF EXISTS idx_report_schedules_next_run;
DROP INDEX IF EXISTS idx_report_schedules_active;
DROP INDEX IF EXISTS idx_report_schedules_definition_id;
DROP INDEX IF EXISTS idx_report_schedules_tenant_id;

DROP INDEX IF EXISTS idx_report_instances_requested_by;
DROP INDEX IF EXISTS idx_report_instances_started_at;
DROP INDEX IF EXISTS idx_report_instances_execution_type;
DROP INDEX IF EXISTS idx_report_instances_status;
DROP INDEX IF EXISTS idx_report_instances_definition_id;
DROP INDEX IF EXISTS idx_report_instances_tenant_id;

DROP INDEX IF EXISTS idx_report_definitions_created_by;
DROP INDEX IF EXISTS idx_report_definitions_scheduled;
DROP INDEX IF EXISTS idx_report_definitions_system;
DROP INDEX IF EXISTS idx_report_definitions_active;
DROP INDEX IF EXISTS idx_report_definitions_category;
DROP INDEX IF EXISTS idx_report_definitions_type;
DROP INDEX IF EXISTS idx_report_definitions_tenant_id;

-- Drop triggers
DROP TRIGGER IF EXISTS trigger_dashboard_widgets_updated_at ON dashboard_widgets;
DROP TRIGGER IF EXISTS trigger_dashboards_updated_at ON dashboards;
DROP TRIGGER IF EXISTS trigger_report_schedules_updated_at ON report_schedules;
DROP TRIGGER IF EXISTS trigger_report_instances_updated_at ON report_instances;
DROP TRIGGER IF EXISTS trigger_report_definitions_updated_at ON report_definitions;

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS report_analytics;
DROP TABLE IF EXISTS dashboard_widgets;
DROP TABLE IF EXISTS dashboards;
DROP TABLE IF EXISTS report_schedules;
DROP TABLE IF EXISTS report_instances;
DROP TABLE IF EXISTS report_definitions;
