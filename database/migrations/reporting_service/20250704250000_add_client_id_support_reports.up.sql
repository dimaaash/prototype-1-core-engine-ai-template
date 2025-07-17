-- Migration: add_client_id_support_reports
-- Service: reporting
-- Description: Add client_id support to reporting tables for multi-client architecture

-- Add client_id to report_definitions table
ALTER TABLE report_definitions 
    ADD COLUMN client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE;

-- Update unique constraint to include client_id
ALTER TABLE report_definitions 
    DROP CONSTRAINT report_definitions_tenant_id_report_name_key;

ALTER TABLE report_definitions 
    ADD CONSTRAINT report_definitions_client_name_unique 
    UNIQUE (tenant_id, client_id, report_name);

-- Add client_id to report_instances table
ALTER TABLE report_instances 
    ADD COLUMN client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE;

-- Add client_id to report_schedules table
ALTER TABLE report_schedules 
    ADD COLUMN client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE;

-- Update unique constraint to include client_id
ALTER TABLE report_schedules 
    DROP CONSTRAINT report_schedules_tenant_id_schedule_name_key;

ALTER TABLE report_schedules 
    ADD CONSTRAINT report_schedules_client_name_unique 
    UNIQUE (tenant_id, client_id, schedule_name);

-- Add client_id to dashboards table
ALTER TABLE dashboards 
    ADD COLUMN client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE;

-- Update unique constraint to include client_id
ALTER TABLE dashboards 
    DROP CONSTRAINT dashboards_tenant_id_dashboard_name_key;

ALTER TABLE dashboards 
    ADD CONSTRAINT dashboards_client_name_unique 
    UNIQUE (tenant_id, client_id, dashboard_name);

-- Add client_id to report_analytics table
ALTER TABLE report_analytics 
    ADD COLUMN client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE;

-- Add client_id indexes for performance
CREATE INDEX idx_report_definitions_client_id ON report_definitions(client_id);
CREATE INDEX idx_report_instances_client_id ON report_instances(client_id);
CREATE INDEX idx_report_schedules_client_id ON report_schedules(client_id);
CREATE INDEX idx_dashboards_client_id ON dashboards(client_id);
CREATE INDEX idx_report_analytics_client_id ON report_analytics(client_id);
