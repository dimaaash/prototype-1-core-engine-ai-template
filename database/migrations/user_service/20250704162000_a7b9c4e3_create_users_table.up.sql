-- Migration: create_users_table
-- Service: user
-- Description: Create user management tables

-- Users table - Core user management
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    avatar_url VARCHAR(500),
    status status_enum NOT NULL DEFAULT 'active',
    email_verified_at TIMESTAMP WITH TIME ZONE,
    phone_verified_at TIMESTAMP WITH TIME ZONE,
    last_login_at TIMESTAMP WITH TIME ZONE,
    password_changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP WITH TIME ZONE,
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    version INTEGER DEFAULT 1,
    UNIQUE(tenant_id, email),
    CONSTRAINT valid_email CHECK (validate_email(email)),
    CONSTRAINT valid_phone CHECK (phone IS NULL OR validate_phone(phone))
);

-- Note: User role assignments are handled by auth_user_roles table in auth_service

-- User profiles for extended information
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    job_title VARCHAR(100),
    department VARCHAR(100),
    manager_id UUID REFERENCES users(id),
    employee_id VARCHAR(50),
    hire_date DATE,
    timezone VARCHAR(50) DEFAULT 'UTC',
    locale VARCHAR(10) DEFAULT 'en-US',
    date_format VARCHAR(20) DEFAULT 'MM/DD/YYYY',
    time_format VARCHAR(10) DEFAULT '12h',
    currency currency_code DEFAULT 'USD',
    address JSONB, -- {street, city, state, postal_code, country}
    emergency_contact JSONB, -- {name, phone, relationship}
    skills JSONB DEFAULT '[]',
    certifications JSONB DEFAULT '[]',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1
);

-- User activity log for audit trail
CREATE TABLE user_activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    activity_type VARCHAR(50) NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    action VARCHAR(50) NOT NULL,
    description TEXT,
    metadata JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    location JSONB, -- {country, region, city, lat, lng}
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Email verification tokens
CREATE TABLE user_email_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    verified_at TIMESTAMP WITH TIME ZONE,
    attempts INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_verification_email CHECK (validate_email(email))
);

-- Phone verification tokens
CREATE TABLE user_phone_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    phone VARCHAR(20) NOT NULL,
    verification_code VARCHAR(10) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    verified_at TIMESTAMP WITH TIME ZONE,
    attempts INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_verification_phone CHECK (validate_phone(phone))
);

-- User invitations for team management
CREATE TABLE user_invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    invited_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID REFERENCES auth_roles(id) ON DELETE SET NULL,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    accepted_at TIMESTAMP WITH TIME ZONE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL, -- Set when invitation is accepted
    message TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_invitation_email CHECK (validate_email(email))
);

-- User preferences and settings
CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    category VARCHAR(50) NOT NULL, -- notification, ui, security, etc.
    setting_key VARCHAR(100) NOT NULL,
    setting_value JSONB NOT NULL,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    UNIQUE(user_id, category, setting_key)
);

-- User teams/groups for organization
CREATE TABLE user_teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    team_lead_id UUID REFERENCES users(id) ON DELETE SET NULL,
    department VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    UNIQUE(tenant_id, name)
);

-- User team memberships
CREATE TABLE user_team_memberships (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES user_teams(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member' CHECK (role IN ('member', 'lead', 'admin')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    added_by UUID REFERENCES users(id),
    is_active BOOLEAN DEFAULT true,
    PRIMARY KEY (user_id, team_id)
);

-- Indexes for optimal performance
CREATE INDEX idx_users_tenant_id ON users(tenant_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_last_login ON users(last_login_at);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_deleted_at ON users(deleted_at) WHERE deleted_at IS NOT NULL;

-- Note: User role indexes are in auth_service (auth_user_roles table)

CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX idx_user_profiles_tenant_id ON user_profiles(tenant_id);
CREATE INDEX idx_user_profiles_manager_id ON user_profiles(manager_id);
CREATE INDEX idx_user_profiles_department ON user_profiles(department);

CREATE INDEX idx_user_activities_user_id ON user_activities(user_id);
CREATE INDEX idx_user_activities_tenant_id ON user_activities(tenant_id);
CREATE INDEX idx_user_activities_type ON user_activities(activity_type);
CREATE INDEX idx_user_activities_resource ON user_activities(resource_type, resource_id);
CREATE INDEX idx_user_activities_created_at ON user_activities(created_at);

CREATE INDEX idx_user_email_verifications_user_id ON user_email_verifications(user_id);
CREATE INDEX idx_user_email_verifications_token_hash ON user_email_verifications(token_hash);
CREATE INDEX idx_user_email_verifications_expires_at ON user_email_verifications(expires_at);

CREATE INDEX idx_user_phone_verifications_user_id ON user_phone_verifications(user_id);
CREATE INDEX idx_user_phone_verifications_expires_at ON user_phone_verifications(expires_at);

CREATE INDEX idx_user_invitations_tenant_id ON user_invitations(tenant_id);
CREATE INDEX idx_user_invitations_email ON user_invitations(email);
CREATE INDEX idx_user_invitations_invited_by ON user_invitations(invited_by);
CREATE INDEX idx_user_invitations_token_hash ON user_invitations(token_hash);
CREATE INDEX idx_user_invitations_expires_at ON user_invitations(expires_at);

CREATE INDEX idx_user_settings_user_id ON user_settings(user_id);
CREATE INDEX idx_user_settings_category ON user_settings(category);

CREATE INDEX idx_user_teams_tenant_id ON user_teams(tenant_id);
CREATE INDEX idx_user_teams_lead_id ON user_teams(team_lead_id);
CREATE INDEX idx_user_teams_active ON user_teams(is_active) WHERE is_active = true;

CREATE INDEX idx_user_team_memberships_user_id ON user_team_memberships(user_id);
CREATE INDEX idx_user_team_memberships_team_id ON user_team_memberships(team_id);
CREATE INDEX idx_user_team_memberships_active ON user_team_memberships(is_active) WHERE is_active = true;

-- Triggers for automatic timestamp and version updates
CREATE TRIGGER trigger_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_user_profiles_updated_at 
    BEFORE UPDATE ON user_profiles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_user_settings_updated_at 
    BEFORE UPDATE ON user_settings 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_user_teams_updated_at 
    BEFORE UPDATE ON user_teams 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create sequences for user codes
CREATE SEQUENCE IF NOT EXISTS user_employee_id_seq START 1000;

-- Function to generate employee ID
CREATE OR REPLACE FUNCTION generate_employee_id()
RETURNS TEXT AS $$
BEGIN
    RETURN 'EMP' || LPAD(nextval('user_employee_id_seq')::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate employee ID if not provided
CREATE OR REPLACE FUNCTION auto_generate_employee_id()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.employee_id IS NULL OR NEW.employee_id = '' THEN
        NEW.employee_id := generate_employee_id();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_user_profiles_employee_id 
    BEFORE INSERT ON user_profiles 
    FOR EACH ROW EXECUTE FUNCTION auto_generate_employee_id();

-- Create audit logging triggers
CREATE OR REPLACE FUNCTION log_user_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM log_audit_entry(
            NEW.tenant_id,
            NULL, -- client_id
            NEW.id, -- user_id
            'user',
            'user',
            NEW.id,
            'create',
            NULL,
            to_jsonb(NEW),
            '{"source": "database_trigger"}'::jsonb
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        PERFORM log_audit_entry(
            NEW.tenant_id,
            NULL, -- client_id
            NEW.id, -- user_id
            'user',
            'user',
            NEW.id,
            'update',
            to_jsonb(OLD),
            to_jsonb(NEW),
            '{"source": "database_trigger"}'::jsonb
        );
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        PERFORM log_audit_entry(
            OLD.tenant_id,
            NULL, -- client_id
            OLD.id, -- user_id
            'user',
            'user',
            OLD.id,
            'delete',
            to_jsonb(OLD),
            NULL,
            '{"source": "database_trigger"}'::jsonb
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_users_audit_log 
    AFTER INSERT OR UPDATE OR DELETE ON users 
    FOR EACH ROW EXECUTE FUNCTION log_user_changes();
