-- Migration: create_reports_table
-- Service: reporting
-- Description: Create reporting and analytics system tables

-- Report definitions for customizable reports
CREATE TABLE report_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    report_name VARCHAR(100) NOT NULL,
    report_type VARCHAR(50) NOT NULL CHECK (report_type IN ('summary', 'detail', 'analytical', 'operational', 'compliance', 'custom')),
    category VARCHAR(50) NOT NULL CHECK (category IN ('orders', 'inventory', 'financial', 'operational', 'customer', 'product', 'warehouse', 'performance')),
    
    -- Report configuration
    is_active BOOLEAN DEFAULT true,
    is_system BOOLEAN DEFAULT false, -- System reports cannot be deleted
    access_level VARCHAR(20) DEFAULT 'tenant' CHECK (access_level IN ('system', 'tenant', 'user', 'public')),
    
    -- Data source configuration
    data_sources JSONB NOT NULL DEFAULT '[]', -- Tables/views to query
    query_template TEXT, -- SQL template for data retrieval
    parameters JSONB DEFAULT '{}', -- Report parameters configuration
    
    -- Visualization configuration
    visualization_type VARCHAR(50) DEFAULT 'table' CHECK (visualization_type IN ('table', 'chart', 'graph', 'dashboard', 'pivot', 'custom')),
    chart_config JSONB DEFAULT '{}', -- Chart-specific configuration
    columns_config JSONB DEFAULT '{}', -- Column definitions and formatting
    
    -- Grouping and aggregation
    group_by_fields JSONB DEFAULT '[]',
    aggregate_fields JSONB DEFAULT '[]',
    sort_configuration JSONB DEFAULT '[]',
    filter_configuration JSONB DEFAULT '{}',
    
    -- Scheduling and automation
    is_scheduled BOOLEAN DEFAULT false,
    schedule_config JSONB DEFAULT '{}', -- Cron expression, frequency, etc.
    auto_refresh_minutes INTEGER,
    
    -- Performance optimization
    cache_duration_minutes INTEGER DEFAULT 60,
    enable_caching BOOLEAN DEFAULT true,
    estimated_runtime_seconds INTEGER,
    
    -- Report metadata
    description TEXT,
    tags JSONB DEFAULT '[]',
    version INTEGER DEFAULT 1,
    
    -- Permissions
    created_by UUID REFERENCES users(id),
    shared_with JSONB DEFAULT '[]', -- User/role sharing configuration
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tenant_id, report_name)
);

-- Report instances for tracking report executions
CREATE TABLE report_instances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    report_definition_id UUID NOT NULL REFERENCES report_definitions(id) ON DELETE CASCADE,
    instance_name VARCHAR(255),
    
    -- Execution details
    execution_type VARCHAR(20) DEFAULT 'manual' CHECK (execution_type IN ('manual', 'scheduled', 'automated', 'api')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'completed', 'failed', 'cancelled')),
    
    -- Parameters and filters
    parameters JSONB DEFAULT '{}', -- Actual parameter values used
    filters JSONB DEFAULT '{}', -- Applied filters
    date_range JSONB DEFAULT '{}', -- Report date range
    
    -- Execution timing
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    execution_time_seconds INTEGER,
    
    -- Results
    record_count INTEGER,
    file_path VARCHAR(500), -- Path to generated report file
    file_format VARCHAR(20), -- pdf, excel, csv, json
    file_size_bytes BIGINT,
    
    -- Performance metrics
    query_time_seconds INTEGER,
    generation_time_seconds INTEGER,
    cache_used BOOLEAN DEFAULT false,
    
    -- Error handling
    error_message TEXT,
    error_details JSONB,
    
    -- User tracking
    requested_by UUID REFERENCES users(id),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Report schedules for automated report generation
CREATE TABLE report_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    report_definition_id UUID NOT NULL REFERENCES report_definitions(id) ON DELETE CASCADE,
    schedule_name VARCHAR(100) NOT NULL,
    
    -- Schedule configuration
    is_active BOOLEAN DEFAULT true,
    frequency VARCHAR(20) NOT NULL CHECK (frequency IN ('hourly', 'daily', 'weekly', 'monthly', 'quarterly', 'yearly', 'custom')),
    cron_expression VARCHAR(100), -- For custom frequencies
    timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Execution timing
    start_date DATE NOT NULL,
    end_date DATE, -- Optional end date
    next_run_at TIMESTAMP WITH TIME ZONE,
    last_run_at TIMESTAMP WITH TIME ZONE,
    
    -- Report configuration
    parameters JSONB DEFAULT '{}', -- Default parameters for scheduled runs
    output_format VARCHAR(20) DEFAULT 'pdf' CHECK (output_format IN ('pdf', 'excel', 'csv', 'json', 'html')),
    
    -- Delivery configuration
    delivery_method VARCHAR(20) DEFAULT 'email' CHECK (delivery_method IN ('email', 'file_system', 's3', 'ftp', 'api_webhook')),
    delivery_config JSONB DEFAULT '{}', -- Email addresses, file paths, etc.
    
    -- Recipients
    recipients JSONB NOT NULL DEFAULT '[]', -- Email addresses or user IDs
    include_empty_reports BOOLEAN DEFAULT false,
    
    -- Execution tracking
    total_executions INTEGER DEFAULT 0,
    successful_executions INTEGER DEFAULT 0,
    failed_executions INTEGER DEFAULT 0,
    last_success_at TIMESTAMP WITH TIME ZONE,
    last_failure_at TIMESTAMP WITH TIME ZONE,
    consecutive_failures INTEGER DEFAULT 0,
    
    -- Error handling
    max_consecutive_failures INTEGER DEFAULT 3,
    alert_on_failure BOOLEAN DEFAULT true,
    disable_on_max_failures BOOLEAN DEFAULT true,
    
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    UNIQUE(tenant_id, schedule_name)
);

-- Dashboard configurations for interactive reporting
CREATE TABLE dashboards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    dashboard_name VARCHAR(100) NOT NULL,
    
    -- Dashboard configuration
    is_active BOOLEAN DEFAULT true,
    is_default BOOLEAN DEFAULT false,
    access_level VARCHAR(20) DEFAULT 'tenant' CHECK (access_level IN ('system', 'tenant', 'user', 'public')),
    
    -- Layout configuration
    layout_config JSONB NOT NULL DEFAULT '{}', -- Widget positions, sizes, etc.
    theme_config JSONB DEFAULT '{}', -- Colors, fonts, styling
    refresh_interval_seconds INTEGER DEFAULT 300,
    auto_refresh BOOLEAN DEFAULT true,
    
    -- Dashboard metadata
    description TEXT,
    tags JSONB DEFAULT '[]',
    
    -- Permissions and sharing
    created_by UUID REFERENCES users(id),
    shared_with JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    UNIQUE(tenant_id, dashboard_name)
);

-- Dashboard widgets for modular dashboard components
CREATE TABLE dashboard_widgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_id UUID NOT NULL REFERENCES dashboards(id) ON DELETE CASCADE,
    widget_name VARCHAR(100) NOT NULL,
    widget_type VARCHAR(50) NOT NULL CHECK (widget_type IN ('chart', 'table', 'metric', 'gauge', 'map', 'text', 'image', 'custom')),
    
    -- Widget configuration
    report_definition_id UUID REFERENCES report_definitions(id),
    widget_config JSONB NOT NULL DEFAULT '{}', -- Widget-specific configuration
    data_config JSONB DEFAULT '{}', -- Data source and query configuration
    
    -- Layout and appearance
    position_config JSONB NOT NULL DEFAULT '{}', -- x, y, width, height
    style_config JSONB DEFAULT '{}', -- Colors, borders, etc.
    
    -- Widget behavior
    is_visible BOOLEAN DEFAULT true,
    refresh_interval_seconds INTEGER DEFAULT 300,
    cache_duration_minutes INTEGER DEFAULT 60,
    
    -- Performance tracking
    last_refresh_at TIMESTAMP WITH TIME ZONE,
    average_load_time_ms INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1
);

-- Report analytics for tracking report usage
CREATE TABLE report_analytics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    report_definition_id UUID REFERENCES report_definitions(id) ON DELETE CASCADE,
    dashboard_id UUID REFERENCES dashboards(id) ON DELETE CASCADE,
    widget_id UUID REFERENCES dashboard_widgets(id) ON DELETE CASCADE,
    
    -- Analytics event
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN ('view', 'export', 'share', 'schedule', 'error')),
    event_date DATE NOT NULL,
    event_hour INTEGER NOT NULL, -- 0-23
    
    -- User and session information
    user_id UUID REFERENCES users(id),
    session_id VARCHAR(100),
    user_agent VARCHAR(500),
    ip_address INET,
    
    -- Performance metrics
    load_time_ms INTEGER,
    query_time_ms INTEGER,
    record_count INTEGER,
    
    -- Event details
    event_details JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tenant_id, report_definition_id, dashboard_id, widget_id, event_type, event_date, event_hour, user_id)
);

-- Comprehensive indexing for reporting service
CREATE INDEX idx_report_definitions_tenant_id ON report_definitions(tenant_id);
CREATE INDEX idx_report_definitions_type ON report_definitions(report_type);
CREATE INDEX idx_report_definitions_category ON report_definitions(category);
CREATE INDEX idx_report_definitions_active ON report_definitions(is_active) WHERE is_active = true;
CREATE INDEX idx_report_definitions_system ON report_definitions(is_system);
CREATE INDEX idx_report_definitions_scheduled ON report_definitions(is_scheduled) WHERE is_scheduled = true;
CREATE INDEX idx_report_definitions_created_by ON report_definitions(created_by);

CREATE INDEX idx_report_instances_tenant_id ON report_instances(tenant_id);
CREATE INDEX idx_report_instances_definition_id ON report_instances(report_definition_id);
CREATE INDEX idx_report_instances_status ON report_instances(status);
CREATE INDEX idx_report_instances_execution_type ON report_instances(execution_type);
CREATE INDEX idx_report_instances_started_at ON report_instances(started_at);
CREATE INDEX idx_report_instances_requested_by ON report_instances(requested_by);

CREATE INDEX idx_report_schedules_tenant_id ON report_schedules(tenant_id);
CREATE INDEX idx_report_schedules_definition_id ON report_schedules(report_definition_id);
CREATE INDEX idx_report_schedules_active ON report_schedules(is_active) WHERE is_active = true;
CREATE INDEX idx_report_schedules_next_run ON report_schedules(next_run_at) WHERE is_active = true;
CREATE INDEX idx_report_schedules_frequency ON report_schedules(frequency);

CREATE INDEX idx_dashboards_tenant_id ON dashboards(tenant_id);
CREATE INDEX idx_dashboards_active ON dashboards(is_active) WHERE is_active = true;
CREATE INDEX idx_dashboards_default ON dashboards(is_default) WHERE is_default = true;
CREATE INDEX idx_dashboards_created_by ON dashboards(created_by);

CREATE INDEX idx_dashboard_widgets_dashboard_id ON dashboard_widgets(dashboard_id);
CREATE INDEX idx_dashboard_widgets_type ON dashboard_widgets(widget_type);
CREATE INDEX idx_dashboard_widgets_report_id ON dashboard_widgets(report_definition_id);
CREATE INDEX idx_dashboard_widgets_visible ON dashboard_widgets(is_visible) WHERE is_visible = true;

CREATE INDEX idx_report_analytics_tenant_id ON report_analytics(tenant_id);
CREATE INDEX idx_report_analytics_report_id ON report_analytics(report_definition_id);
CREATE INDEX idx_report_analytics_dashboard_id ON report_analytics(dashboard_id);
CREATE INDEX idx_report_analytics_event_type ON report_analytics(event_type);
CREATE INDEX idx_report_analytics_event_date ON report_analytics(event_date);
CREATE INDEX idx_report_analytics_user_id ON report_analytics(user_id);

-- Triggers
CREATE TRIGGER trigger_report_definitions_updated_at 
    BEFORE UPDATE ON report_definitions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_report_instances_updated_at 
    BEFORE UPDATE ON report_instances 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_report_schedules_updated_at 
    BEFORE UPDATE ON report_schedules 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_dashboards_updated_at 
    BEFORE UPDATE ON dashboards 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_dashboard_widgets_updated_at 
    BEFORE UPDATE ON dashboard_widgets 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
