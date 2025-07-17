-- Migration: create_tenants_table
-- Service: tenant
-- Description: Create multi-tenant infrastructure tables

-- Tenants table - Core multi-tenancy
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    domain VARCHAR(255) UNIQUE,
    status status_enum NOT NULL DEFAULT 'active',
    plan VARCHAR(50) NOT NULL DEFAULT 'basic' CHECK (plan IN ('basic', 'premium', 'enterprise')),
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    version INTEGER DEFAULT 1
);

-- Tenant configurations for flexible settings
CREATE TABLE tenant_configurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    config_key VARCHAR(100) NOT NULL,
    config_value JSONB NOT NULL,
    is_encrypted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    UNIQUE(tenant_id, config_key)
);

-- Tenant API keys for external integrations
CREATE TABLE tenant_api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    key_hash VARCHAR(255) NOT NULL UNIQUE,
    permissions JSONB DEFAULT '[]',
    rate_limit INTEGER DEFAULT 1000, -- requests per hour
    expires_at TIMESTAMP WITH TIME ZONE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    version INTEGER DEFAULT 1
);

-- Tenant subscription plans and billing
CREATE TABLE tenant_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    plan_name VARCHAR(50) NOT NULL,
    billing_cycle VARCHAR(20) DEFAULT 'monthly' CHECK (billing_cycle IN ('monthly', 'yearly', 'custom')),
    price DECIMAL(12,2) NOT NULL,
    currency currency_code DEFAULT 'USD',
    max_users INTEGER,
    max_warehouses INTEGER,
    max_products INTEGER,
    features JSONB DEFAULT '[]',
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    auto_renew BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1
);

-- Tenant domains for custom domain support
CREATE TABLE tenant_domains (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    domain VARCHAR(255) NOT NULL UNIQUE,
    is_primary BOOLEAN DEFAULT false,
    is_verified BOOLEAN DEFAULT false,
    ssl_enabled BOOLEAN DEFAULT false,
    verification_token VARCHAR(255),
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Client organizations within tenants (Multi-Client Support)
-- Each tenant can have multiple client organizations for separate business units
CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    
    -- Basic information
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL,
    description TEXT,
    
    -- Contact information
    contact_name VARCHAR(255),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    
    -- Address
    address_line_1 VARCHAR(255),
    address_line_2 VARCHAR(255),
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(2) DEFAULT 'US',
    
    -- Business information
    tax_id VARCHAR(50),
    business_registration VARCHAR(50),
    industry VARCHAR(100),
    
    -- Settings
    default_currency currency_code DEFAULT 'USD',
    default_timezone VARCHAR(50) DEFAULT 'UTC',
    settings JSONB DEFAULT '{}',
    
    -- Status
    status status_enum DEFAULT 'active',
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    
    -- Constraints
    CONSTRAINT clients_name_not_empty CHECK (length(trim(name)) > 0),
    CONSTRAINT clients_code_not_empty CHECK (length(trim(code)) > 0),
    CONSTRAINT clients_code_format CHECK (code ~ '^[A-Z0-9_-]+$'),
    CONSTRAINT clients_contact_email_valid CHECK (contact_email IS NULL OR validate_email(contact_email)),
    CONSTRAINT clients_contact_phone_valid CHECK (contact_phone IS NULL OR validate_phone(contact_phone)),
    CONSTRAINT clients_postal_code_valid CHECK (postal_code IS NULL OR validate_postal_code(postal_code, country)),
    
    -- Unique constraint for tenant-scoped code
    UNIQUE(tenant_id, code)
);

-- Indexes for performance
CREATE INDEX idx_tenants_slug ON tenants(slug);
CREATE INDEX idx_tenants_domain ON tenants(domain);
CREATE INDEX idx_tenants_status ON tenants(status);
CREATE INDEX idx_tenants_created_at ON tenants(created_at);
CREATE INDEX idx_tenant_configurations_tenant_id ON tenant_configurations(tenant_id);
CREATE INDEX idx_tenant_configurations_key ON tenant_configurations(config_key);
CREATE INDEX idx_tenant_api_keys_tenant_id ON tenant_api_keys(tenant_id);
CREATE INDEX idx_tenant_api_keys_hash ON tenant_api_keys(key_hash);
CREATE INDEX idx_tenant_api_keys_active ON tenant_api_keys(is_active);
CREATE INDEX idx_tenant_subscriptions_tenant_id ON tenant_subscriptions(tenant_id);
CREATE INDEX idx_tenant_subscriptions_expires_at ON tenant_subscriptions(expires_at);
CREATE INDEX idx_tenant_domains_tenant_id ON tenant_domains(tenant_id);
CREATE INDEX idx_tenant_domains_domain ON tenant_domains(domain);
CREATE INDEX idx_tenant_domains_primary ON tenant_domains(is_primary) WHERE is_primary = true;

-- Client indexes for tenant-scoped queries
CREATE INDEX idx_clients_tenant_id ON clients(tenant_id);
CREATE INDEX idx_clients_tenant_code ON clients(tenant_id, code);
CREATE INDEX idx_clients_tenant_status ON clients(tenant_id, status);
CREATE INDEX idx_clients_status ON clients(status);
CREATE INDEX idx_clients_country ON clients(country);
CREATE INDEX idx_clients_industry ON clients(industry) WHERE industry IS NOT NULL;
CREATE INDEX idx_clients_created_at ON clients(created_at);

-- Triggers for automatic timestamp and version updates
CREATE TRIGGER trigger_tenants_updated_at 
    BEFORE UPDATE ON tenants 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_tenant_configurations_updated_at 
    BEFORE UPDATE ON tenant_configurations 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_tenant_subscriptions_updated_at 
    BEFORE UPDATE ON tenant_subscriptions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_tenant_domains_updated_at 
    BEFORE UPDATE ON tenant_domains 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_clients_updated_at 
    BEFORE UPDATE ON clients 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default tenant for system operations
INSERT INTO tenants (name, slug, domain, status, plan, settings) VALUES
('System Tenant', 'system', 'system.local', 'active', 'enterprise', '{"is_system": true}')
ON CONFLICT (slug) DO NOTHING;

-- Insert default system configurations
INSERT INTO tenant_configurations (tenant_id, config_key, config_value) 
SELECT id, 'default_currency', '"USD"' FROM tenants WHERE slug = 'system'
ON CONFLICT (tenant_id, config_key) DO NOTHING;

INSERT INTO tenant_configurations (tenant_id, config_key, config_value) 
SELECT id, 'default_timezone', '"UTC"' FROM tenants WHERE slug = 'system'
ON CONFLICT (tenant_id, config_key) DO NOTHING;

INSERT INTO tenant_configurations (tenant_id, config_key, config_value) 
SELECT id, 'max_file_upload_size', '52428800' FROM tenants WHERE slug = 'system'  -- 50MB
ON CONFLICT (tenant_id, config_key) DO NOTHING;

-- Insert default client for system tenant
INSERT INTO clients (tenant_id, name, code, description, status, default_currency, default_timezone) 
SELECT 
    id, 
    'Default Client', 
    'DEFAULT', 
    'Default client organization for system tenant',
    'active',
    'USD',
    'UTC'
FROM tenants WHERE slug = 'system'
ON CONFLICT (tenant_id, code) DO NOTHING;
