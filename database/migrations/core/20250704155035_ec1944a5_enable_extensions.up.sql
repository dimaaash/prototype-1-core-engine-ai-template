-- Core database extensions and setup
-- This migration enables essential PostgreSQL extensions for the WMS platform

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- Create updated_at function for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.version = OLD.version + 1;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Core audit fields type for consistency across all services
DO $$ BEGIN
    CREATE TYPE audit_fields AS (
        id UUID,
        created_at TIMESTAMP WITH TIME ZONE,
        updated_at TIMESTAMP WITH TIME ZONE,
        version INTEGER
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create common enums used across services
DO $$ BEGIN
    CREATE TYPE status_enum AS ENUM ('active', 'inactive', 'pending', 'suspended', 'archived');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE currency_code AS ENUM (
        'USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'CHF', 'CNY', 'SEK', 'NZD',
        'MXN', 'SGD', 'HKD', 'NOK', 'TRY', 'RUB', 'INR', 'BRL', 'ZAR'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Common weight and dimension units
DO $$ BEGIN
    CREATE TYPE weight_unit AS ENUM ('kg', 'g', 'lb', 'oz', 'ton');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE dimension_unit AS ENUM ('mm', 'cm', 'm', 'in', 'ft');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Temperature units for products requiring temperature control
DO $$ BEGIN
    CREATE TYPE temperature_unit AS ENUM ('celsius', 'fahrenheit', 'kelvin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Common validation functions
CREATE OR REPLACE FUNCTION validate_email(email TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION validate_phone(phone TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Basic phone validation (can be enhanced)
    RETURN phone ~ '^[\+]?[1-9][\d\s\-\(\)]{7,15}$';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION validate_postal_code(postal_code TEXT, country_code TEXT DEFAULT 'US')
RETURNS BOOLEAN AS $$
BEGIN
    -- Basic postal code validation (US format by default)
    CASE country_code
        WHEN 'US' THEN
            RETURN postal_code ~ '^\d{5}(-\d{4})?$';
        WHEN 'CA' THEN
            RETURN postal_code ~ '^[A-Za-z]\d[A-Za-z] \d[A-Za-z]\d$';
        WHEN 'GB' THEN
            RETURN postal_code ~ '^[A-Za-z]{1,2}\d{1,2}[A-Za-z]? \d[A-Za-z]{2}$';
        ELSE
            RETURN LENGTH(postal_code) BETWEEN 3 AND 12;
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- Helper function to generate sequential codes
CREATE OR REPLACE FUNCTION generate_sequential_code(prefix TEXT, sequence_name TEXT, length INTEGER DEFAULT 6)
RETURNS TEXT AS $$
DECLARE
    next_val BIGINT;
    code_suffix TEXT;
BEGIN
    -- Get next value from sequence
    EXECUTE format('SELECT nextval(%L)', sequence_name) INTO next_val;
    
    -- Pad with zeros to specified length
    code_suffix := LPAD(next_val::TEXT, length, '0');
    
    RETURN prefix || code_suffix;
END;
$$ LANGUAGE plpgsql;

-- Common logging table for audit trails
CREATE TABLE IF NOT EXISTS system_audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID,
    client_id UUID,
    user_id UUID,
    service VARCHAR(50) NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    entity_id UUID,
    action VARCHAR(50) NOT NULL,
    old_values JSONB,
    new_values JSONB,
    metadata JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_system_audit_log_tenant_client ON system_audit_log(tenant_id, client_id);
CREATE INDEX idx_system_audit_log_service ON system_audit_log(service);
CREATE INDEX idx_system_audit_log_entity ON system_audit_log(entity_type, entity_id);
CREATE INDEX idx_system_audit_log_action ON system_audit_log(action);
CREATE INDEX idx_system_audit_log_user ON system_audit_log(user_id);
CREATE INDEX idx_system_audit_log_created_at ON system_audit_log(created_at);

-- Function to log audit entries
CREATE OR REPLACE FUNCTION log_audit_entry(
    p_tenant_id UUID,
    p_client_id UUID,
    p_user_id UUID,
    p_service VARCHAR(50),
    p_entity_type VARCHAR(100),
    p_entity_id UUID,
    p_action VARCHAR(50),
    p_old_values JSONB DEFAULT NULL,
    p_new_values JSONB DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    audit_id UUID;
BEGIN
    INSERT INTO system_audit_log (
        tenant_id, client_id, user_id, service, entity_type, entity_id,
        action, old_values, new_values, metadata, ip_address, user_agent
    ) VALUES (
        p_tenant_id, p_client_id, p_user_id, p_service, p_entity_type, p_entity_id,
        p_action, p_old_values, p_new_values, p_metadata, p_ip_address, p_user_agent
    ) RETURNING id INTO audit_id;
    
    RETURN audit_id;
END;
$$ LANGUAGE plpgsql;

-- System configuration table
CREATE TABLE IF NOT EXISTS system_configuration (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key VARCHAR(255) UNIQUE NOT NULL,
    value JSONB NOT NULL,
    description TEXT,
    is_sensitive BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1
);

CREATE INDEX idx_system_configuration_key ON system_configuration(key);
CREATE INDEX idx_system_configuration_sensitive ON system_configuration(is_sensitive);

CREATE TRIGGER trigger_system_configuration_updated_at 
    BEFORE UPDATE ON system_configuration 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default system configurations
INSERT INTO system_configuration (key, value, description) VALUES
('system.version', '"1.0.0"', 'Current system version'),
('system.maintenance_mode', 'false', 'System maintenance mode flag'),
('system.default_currency', '"USD"', 'Default system currency'),
('system.default_timezone', '"UTC"', 'Default system timezone'),
('inventory.low_stock_threshold', '10', 'Default low stock threshold'),
('inventory.enable_negative_stock', 'false', 'Allow negative inventory levels'),
('auth.session_timeout_minutes', '480', 'User session timeout in minutes'),
('auth.max_login_attempts', '5', 'Maximum login attempts before lockout'),
('notifications.email_enabled', 'true', 'Enable email notifications'),
('notifications.sms_enabled', 'false', 'Enable SMS notifications')
ON CONFLICT (key) DO NOTHING;

