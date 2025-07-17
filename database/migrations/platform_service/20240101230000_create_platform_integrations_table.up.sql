-- Migration: create_platform_integrations_table
-- Service: platform
-- Description: Create platform integration and synchronization tables

-- Platform integration configurations
CREATE TABLE platform_integrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    integration_name VARCHAR(100) NOT NULL,
    platform_type VARCHAR(50) NOT NULL CHECK (platform_type IN ('ecommerce', 'marketplace', 'erp', 'crm', 'shipping', 'payment', 'accounting', 'analytics')),
    platform_provider VARCHAR(100) NOT NULL, -- shopify, woocommerce, amazon, etc.
    
    -- Connection configuration
    connection_type VARCHAR(50) DEFAULT 'rest_api' CHECK (connection_type IN ('rest_api', 'graphql', 'soap', 'ftp', 'sftp', 'webhook', 'database')),
    base_url VARCHAR(500),
    api_version VARCHAR(20),
    
    -- Authentication
    auth_type VARCHAR(50) CHECK (auth_type IN ('api_key', 'oauth2', 'basic_auth', 'bearer_token', 'certificate', 'none')),
    auth_config JSONB DEFAULT '{}', -- Encrypted authentication details
    
    -- Integration status and health
    status VARCHAR(50) DEFAULT 'inactive' CHECK (status IN ('active', 'inactive', 'error', 'suspended', 'maintenance')),
    is_enabled BOOLEAN DEFAULT true,
    health_status VARCHAR(20) DEFAULT 'unknown' CHECK (health_status IN ('healthy', 'warning', 'error', 'unknown')),
    last_health_check TIMESTAMP WITH TIME ZONE,
    
    -- Sync configuration
    sync_frequency_minutes INTEGER DEFAULT 60,
    sync_enabled BOOLEAN DEFAULT true,
    last_sync_at TIMESTAMP WITH TIME ZONE,
    next_sync_at TIMESTAMP WITH TIME ZONE,
    
    -- Data mapping and transformation
    field_mappings JSONB DEFAULT '{}', -- Field mapping configuration
    data_transformation_rules JSONB DEFAULT '{}', -- Transformation rules
    -- default_warehouse_id UUID REFERENCES warehouses(id), -- Commented out - not applicable for Go Factory Platform
    
    -- Rate limiting and performance
    rate_limit_requests_per_minute INTEGER DEFAULT 60,
    timeout_seconds INTEGER DEFAULT 30,
    retry_attempts INTEGER DEFAULT 3,
    retry_delay_seconds INTEGER DEFAULT 5,
    
    -- Monitoring and alerting
    enable_monitoring BOOLEAN DEFAULT true,
    alert_on_errors BOOLEAN DEFAULT true,
    alert_threshold_errors INTEGER DEFAULT 5,
    alert_threshold_minutes INTEGER DEFAULT 15,
    
    
    -- Additional settings
    custom_configuration JSONB DEFAULT '{}',
    notes TEXT,
    
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    UNIQUE(tenant_id, integration_name)
);

-- Platform sync jobs for tracking synchronization tasks
CREATE TABLE platform_sync_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    integration_id UUID NOT NULL REFERENCES platform_integrations(id) ON DELETE CASCADE,
    job_type VARCHAR(50) NOT NULL CHECK (job_type IN ('full_sync', 'incremental_sync', 'real_time_sync', 'manual_sync', 'retry_sync')),
    sync_direction VARCHAR(20) DEFAULT 'import' CHECK (sync_direction IN ('import', 'export', 'bidirectional')),
    
    -- Job configuration
    sync_entities JSONB NOT NULL DEFAULT '[]', -- ['orders', 'products', 'inventory']
    sync_parameters JSONB DEFAULT '{}',
    sync_filters JSONB DEFAULT '{}',
    
    -- Job status and progress
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'completed', 'failed', 'cancelled', 'paused')),
    progress_percentage DECIMAL(5,2) DEFAULT 0,
    
    -- Job timing
    scheduled_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    
    -- Job results
    records_processed INTEGER DEFAULT 0,
    records_succeeded INTEGER DEFAULT 0,
    records_failed INTEGER DEFAULT 0,
    records_skipped INTEGER DEFAULT 0,
    
    -- Error handling
    error_count INTEGER DEFAULT 0,
    last_error TEXT,
    error_details JSONB DEFAULT '{}',
    
    -- Performance metrics
    api_calls_made INTEGER DEFAULT 0,
    data_transferred_bytes BIGINT DEFAULT 0,
    average_response_time_ms INTEGER DEFAULT 0,
    
    -- Triggering and execution
    triggered_by VARCHAR(50) DEFAULT 'scheduler' CHECK (triggered_by IN ('scheduler', 'webhook', 'manual', 'retry', 'system')),
    triggered_by_user_id UUID REFERENCES users(id),
    
    -- Job metadata
    job_metadata JSONB DEFAULT '{}',
    logs_url VARCHAR(500),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Platform sync records for tracking individual record synchronization
CREATE TABLE platform_sync_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    sync_job_id UUID NOT NULL REFERENCES platform_sync_jobs(id) ON DELETE CASCADE,
    integration_id UUID NOT NULL REFERENCES platform_integrations(id) ON DELETE CASCADE,
    
    -- Record identification
    entity_type VARCHAR(50) NOT NULL, -- order, product, inventory, customer
    entity_id UUID, -- Local entity ID
    external_id VARCHAR(255), -- External platform ID
    
    -- Sync details
    sync_direction VARCHAR(20) NOT NULL CHECK (sync_direction IN ('import', 'export')),
    sync_action VARCHAR(20) NOT NULL CHECK (sync_action IN ('create', 'update', 'delete', 'skip')),
    sync_status VARCHAR(20) NOT NULL CHECK (sync_status IN ('pending', 'success', 'failed', 'skipped')),
    
    -- Data comparison
    local_data JSONB,
    external_data JSONB,
    transformed_data JSONB,
    data_hash VARCHAR(64), -- For change detection
    
    -- Error and validation
    error_message TEXT,
    validation_errors JSONB DEFAULT '[]',
    conflict_resolution VARCHAR(50), -- how conflicts were resolved
    
    -- Timing
    processed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    retry_count INTEGER DEFAULT 0,
    next_retry_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Platform webhooks for real-time event handling
CREATE TABLE platform_webhooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    integration_id UUID NOT NULL REFERENCES platform_integrations(id) ON DELETE CASCADE,
    webhook_url VARCHAR(500) NOT NULL,
    
    -- Webhook configuration
    event_types JSONB NOT NULL DEFAULT '[]', -- ['order.created', 'product.updated']
    is_active BOOLEAN DEFAULT true,
    verification_token VARCHAR(255),
    secret_key VARCHAR(255),
    
    -- Webhook status
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'failed', 'suspended')),
    last_delivery_at TIMESTAMP WITH TIME ZONE,
    failure_count INTEGER DEFAULT 0,
    
    -- Delivery configuration
    timeout_seconds INTEGER DEFAULT 30,
    retry_attempts INTEGER DEFAULT 3,
    retry_delay_seconds INTEGER DEFAULT 60,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Platform webhook deliveries for tracking webhook events
CREATE TABLE platform_webhook_deliveries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    webhook_id UUID NOT NULL REFERENCES platform_webhooks(id) ON DELETE CASCADE,
    
    -- Event details
    event_type VARCHAR(100) NOT NULL,
    event_id VARCHAR(255),
    
    -- Delivery attempt
    delivery_status VARCHAR(20) NOT NULL CHECK (delivery_status IN ('pending', 'success', 'failed', 'retrying')),
    attempt_number INTEGER DEFAULT 1,
    
    -- Request and response
    request_headers JSONB DEFAULT '{}',
    request_payload JSONB,
    response_status_code INTEGER,
    response_headers JSONB DEFAULT '{}',
    response_body TEXT,
    
    -- Timing
    delivered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    response_time_ms INTEGER,
    next_retry_at TIMESTAMP WITH TIME ZONE,
    
    -- Error tracking
    error_message TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Comprehensive indexing for platform service
CREATE INDEX idx_platform_integrations_tenant_id ON platform_integrations(tenant_id);
CREATE INDEX idx_platform_integrations_type ON platform_integrations(platform_type);
CREATE INDEX idx_platform_integrations_provider ON platform_integrations(platform_provider);
CREATE INDEX idx_platform_integrations_status ON platform_integrations(status);
CREATE INDEX idx_platform_integrations_enabled ON platform_integrations(is_enabled) WHERE is_enabled = true;
CREATE INDEX idx_platform_integrations_sync_enabled ON platform_integrations(sync_enabled) WHERE sync_enabled = true;
CREATE INDEX idx_platform_integrations_next_sync ON platform_integrations(next_sync_at) WHERE sync_enabled = true;

CREATE INDEX idx_platform_sync_jobs_tenant_id ON platform_sync_jobs(tenant_id);
CREATE INDEX idx_platform_sync_jobs_integration_id ON platform_sync_jobs(integration_id);
CREATE INDEX idx_platform_sync_jobs_status ON platform_sync_jobs(status);
CREATE INDEX idx_platform_sync_jobs_scheduled_at ON platform_sync_jobs(scheduled_at);
CREATE INDEX idx_platform_sync_jobs_type ON platform_sync_jobs(job_type);

CREATE INDEX idx_platform_sync_records_tenant_id ON platform_sync_records(tenant_id);
CREATE INDEX idx_platform_sync_records_job_id ON platform_sync_records(sync_job_id);
CREATE INDEX idx_platform_sync_records_integration_id ON platform_sync_records(integration_id);
CREATE INDEX idx_platform_sync_records_entity ON platform_sync_records(entity_type, entity_id);
CREATE INDEX idx_platform_sync_records_external_id ON platform_sync_records(external_id);
CREATE INDEX idx_platform_sync_records_status ON platform_sync_records(sync_status);

CREATE INDEX idx_platform_webhooks_tenant_id ON platform_webhooks(tenant_id);
CREATE INDEX idx_platform_webhooks_integration_id ON platform_webhooks(integration_id);
CREATE INDEX idx_platform_webhooks_active ON platform_webhooks(is_active) WHERE is_active = true;
CREATE INDEX idx_platform_webhooks_status ON platform_webhooks(status);

CREATE INDEX idx_platform_webhook_deliveries_tenant_id ON platform_webhook_deliveries(tenant_id);
CREATE INDEX idx_platform_webhook_deliveries_webhook_id ON platform_webhook_deliveries(webhook_id);
CREATE INDEX idx_platform_webhook_deliveries_status ON platform_webhook_deliveries(delivery_status);
CREATE INDEX idx_platform_webhook_deliveries_event_type ON platform_webhook_deliveries(event_type);
CREATE INDEX idx_platform_webhook_deliveries_delivered_at ON platform_webhook_deliveries(delivered_at);

-- Triggers
CREATE TRIGGER trigger_platform_integrations_updated_at 
    BEFORE UPDATE ON platform_integrations 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_platform_sync_jobs_updated_at 
    BEFORE UPDATE ON platform_sync_jobs 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_platform_webhooks_updated_at 
    BEFORE UPDATE ON platform_webhooks 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
