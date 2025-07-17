-- Migration: create_auth_tables
-- Service: auth
-- Description: Create enhanced authentication and authorization tables with advanced RBAC

-- Enhanced permissions table for granular access control
CREATE TABLE auth_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Permission identification
    name VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(200) NOT NULL,
    description TEXT,
    
    -- Permission categorization
    service VARCHAR(50) NOT NULL,
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    
    -- Permission characteristics
    is_system_permission BOOLEAN DEFAULT TRUE,
    is_dangerous BOOLEAN DEFAULT FALSE,
    requires_approval BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    
    -- Constraints
    CONSTRAINT auth_permissions_name_format CHECK (name ~ '^[a-z]+\.[a-z_]+\.[a-z_]+$'),
    CONSTRAINT auth_permissions_service_not_empty CHECK (length(trim(service)) > 0),
    CONSTRAINT auth_permissions_resource_not_empty CHECK (length(trim(resource)) > 0),
    CONSTRAINT auth_permissions_action_not_empty CHECK (length(trim(action)) > 0)
);

-- Enhanced roles table with hierarchy support
CREATE TABLE auth_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    
    -- Basic information
    name VARCHAR(100) NOT NULL,
    display_name VARCHAR(200),
    description TEXT,
    
    -- Role hierarchy
    parent_role_id UUID REFERENCES auth_roles(id) ON DELETE SET NULL,
    role_level INTEGER DEFAULT 1,
    
    -- Role characteristics
    is_system_role BOOLEAN DEFAULT FALSE,
    is_admin_role BOOLEAN DEFAULT FALSE,
    is_default_role BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Permissions inheritance
    inherit_permissions BOOLEAN DEFAULT TRUE,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    
    -- Constraints
    CONSTRAINT auth_roles_name_not_empty CHECK (length(trim(name)) > 0),
    CONSTRAINT auth_roles_name_format CHECK (name ~ '^[a-zA-Z0-9_-]+$'),
    CONSTRAINT auth_roles_level_positive CHECK (role_level > 0),
    CONSTRAINT auth_roles_system_client CHECK (
        (is_system_role = TRUE AND client_id IS NULL) OR 
        (is_system_role = FALSE)
    ),
    
    -- Unique constraint for tenant/client-scoped role names
    UNIQUE(tenant_id, client_id, name)
);

-- Enhanced role permissions junction table
CREATE TABLE auth_role_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id UUID NOT NULL REFERENCES auth_roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES auth_permissions(id) ON DELETE CASCADE,
    
    -- Assignment metadata
    granted_by UUID, -- References users(id) - constraint added later
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Conditional access
    conditions JSONB DEFAULT '{}',
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Unique constraint to prevent duplicate assignments
    UNIQUE(role_id, permission_id)
);

-- User role assignments table
CREATE TABLE auth_user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL, -- References users(id) - constraint added later
    role_id UUID NOT NULL REFERENCES auth_roles(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    
    -- Assignment metadata
    assigned_by UUID, -- References users(id) - constraint added later
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    
    -- Constraints
    CONSTRAINT auth_user_roles_expiry_valid CHECK (expires_at IS NULL OR expires_at > assigned_at),
    
    -- Unique constraint to prevent duplicate assignments
    UNIQUE(user_id, role_id, tenant_id, client_id)
);

-- Direct user permissions table (for exceptional cases)
CREATE TABLE auth_user_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL, -- References users(id) - constraint added later
    permission_id UUID NOT NULL REFERENCES auth_permissions(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    
    -- Assignment metadata
    granted_by UUID, -- References users(id) - constraint added later
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    reason TEXT,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    
    -- Constraints
    CONSTRAINT auth_user_permissions_expiry_valid CHECK (expires_at IS NULL OR expires_at > granted_at),
    CONSTRAINT auth_user_permissions_reason_required CHECK (
        reason IS NULL OR length(trim(reason)) > 0
    ),
    
    -- Unique constraint to prevent duplicate assignments
    UNIQUE(user_id, permission_id, tenant_id, client_id)
);

-- Enhanced user sessions for session management
CREATE TABLE auth_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL, -- References users(id) - constraint added later
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    refresh_token_hash VARCHAR(255) UNIQUE,
    device_id VARCHAR(255),
    device_name VARCHAR(255),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    refresh_expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT,
    location JSONB, -- {country, city, etc}
    is_active BOOLEAN DEFAULT true,
    logout_reason VARCHAR(50), -- expired, manual, security, etc
    
    -- Security tracking
    failed_attempts INTEGER DEFAULT 0,
    security_flags JSONB DEFAULT '{}',
    
    -- Audit fields
    version INTEGER DEFAULT 1
);

-- Enhanced password reset tokens
CREATE TABLE auth_password_resets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL, -- References users(id) - constraint added later
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used_at TIMESTAMP WITH TIME ZONE,
    ip_address INET,
    user_agent TEXT,
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 5,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT auth_password_resets_attempts_valid CHECK (attempts >= 0 AND attempts <= max_attempts)
);

-- Multi-factor authentication
CREATE TABLE auth_mfa_devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL, -- References users(id) - constraint added later
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    device_type VARCHAR(20) NOT NULL CHECK (device_type IN ('totp', 'sms', 'email', 'backup_codes')),
    device_name VARCHAR(100),
    secret_encrypted TEXT, -- encrypted secret for TOTP
    phone_number VARCHAR(20), -- for SMS
    backup_codes JSONB, -- for backup codes
    is_verified BOOLEAN DEFAULT false,
    is_primary BOOLEAN DEFAULT false,
    verified_at TIMESTAMP WITH TIME ZONE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Security events log
CREATE TABLE auth_security_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL, -- login_success, login_failure, password_change, etc
    severity VARCHAR(20) DEFAULT 'info' CHECK (severity IN ('info', 'warning', 'error', 'critical')),
    description TEXT,
    metadata JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    location JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- OAuth providers for social login
CREATE TABLE auth_oauth_providers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    provider_name VARCHAR(50) NOT NULL, -- google, github, microsoft, etc
    client_id VARCHAR(255) NOT NULL,
    client_secret_encrypted TEXT NOT NULL,
    scopes JSONB DEFAULT '[]',
    is_enabled BOOLEAN DEFAULT true,
    configuration JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tenant_id, provider_name)
);

-- User OAuth connections
CREATE TABLE auth_user_oauth (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL, -- References users(id) - constraint added later
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES auth_oauth_providers(id) ON DELETE CASCADE,
    provider_user_id VARCHAR(255) NOT NULL,
    provider_username VARCHAR(255),
    provider_email VARCHAR(255),
    access_token_encrypted TEXT,
    refresh_token_encrypted TEXT,
    token_expires_at TIMESTAMP WITH TIME ZONE,
    connected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_used_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(provider_id, provider_user_id)
);

-- Comprehensive indexes for optimal performance
CREATE INDEX idx_auth_permissions_service ON auth_permissions(service);
CREATE INDEX idx_auth_permissions_resource ON auth_permissions(resource);
CREATE INDEX idx_auth_permissions_action ON auth_permissions(action);
CREATE INDEX idx_auth_permissions_service_resource ON auth_permissions(service, resource);
CREATE INDEX idx_auth_permissions_dangerous ON auth_permissions(is_dangerous) WHERE is_dangerous = TRUE;
CREATE INDEX idx_auth_permissions_requires_approval ON auth_permissions(requires_approval) WHERE requires_approval = TRUE;

CREATE INDEX idx_auth_roles_tenant_client ON auth_roles(tenant_id, client_id);
CREATE INDEX idx_auth_roles_parent ON auth_roles(parent_role_id);
CREATE INDEX idx_auth_roles_system ON auth_roles(is_system_role);
CREATE INDEX idx_auth_roles_admin ON auth_roles(is_admin_role) WHERE is_admin_role = TRUE;
CREATE INDEX idx_auth_roles_default ON auth_roles(is_default_role, tenant_id, client_id) WHERE is_default_role = TRUE;
CREATE INDEX idx_auth_roles_active ON auth_roles(is_active);
CREATE INDEX idx_auth_roles_level ON auth_roles(role_level);

CREATE INDEX idx_auth_role_permissions_role ON auth_role_permissions(role_id);
CREATE INDEX idx_auth_role_permissions_permission ON auth_role_permissions(permission_id);
CREATE INDEX idx_auth_role_permissions_granted_by ON auth_role_permissions(granted_by);
CREATE INDEX idx_auth_role_permissions_granted_at ON auth_role_permissions(granted_at);

CREATE INDEX idx_auth_user_roles_user ON auth_user_roles(user_id);
CREATE INDEX idx_auth_user_roles_role ON auth_user_roles(role_id);
CREATE INDEX idx_auth_user_roles_tenant_client ON auth_user_roles(tenant_id, client_id);
CREATE INDEX idx_auth_user_roles_active ON auth_user_roles(is_active);
CREATE INDEX idx_auth_user_roles_expires ON auth_user_roles(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX idx_auth_user_roles_assigned_by ON auth_user_roles(assigned_by);

CREATE INDEX idx_auth_user_permissions_user ON auth_user_permissions(user_id);
CREATE INDEX idx_auth_user_permissions_permission ON auth_user_permissions(permission_id);
CREATE INDEX idx_auth_user_permissions_tenant_client ON auth_user_permissions(tenant_id, client_id);
CREATE INDEX idx_auth_user_permissions_active ON auth_user_permissions(is_active);
CREATE INDEX idx_auth_user_permissions_expires ON auth_user_permissions(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX idx_auth_user_permissions_granted_by ON auth_user_permissions(granted_by);

CREATE INDEX idx_auth_sessions_user_id ON auth_sessions(user_id);
CREATE INDEX idx_auth_sessions_tenant_id ON auth_sessions(tenant_id);
CREATE INDEX idx_auth_sessions_token_hash ON auth_sessions(token_hash);
CREATE INDEX idx_auth_sessions_refresh_token ON auth_sessions(refresh_token_hash);
CREATE INDEX idx_auth_sessions_expires_at ON auth_sessions(expires_at);
CREATE INDEX idx_auth_sessions_active ON auth_sessions(is_active) WHERE is_active = true;
CREATE INDEX idx_auth_sessions_device ON auth_sessions(device_id) WHERE device_id IS NOT NULL;

CREATE INDEX idx_auth_password_resets_user_id ON auth_password_resets(user_id);
CREATE INDEX idx_auth_password_resets_token_hash ON auth_password_resets(token_hash);
CREATE INDEX idx_auth_password_resets_expires_at ON auth_password_resets(expires_at);
CREATE INDEX idx_auth_password_resets_used ON auth_password_resets(used_at) WHERE used_at IS NOT NULL;
CREATE INDEX idx_auth_mfa_devices_user_id ON auth_mfa_devices(user_id);
CREATE INDEX idx_auth_mfa_devices_type ON auth_mfa_devices(device_type);
CREATE INDEX idx_auth_security_events_user_id ON auth_security_events(user_id);
CREATE INDEX idx_auth_security_events_tenant_id ON auth_security_events(tenant_id);
CREATE INDEX idx_auth_security_events_type ON auth_security_events(event_type);
CREATE INDEX idx_auth_security_events_created_at ON auth_security_events(created_at);
CREATE INDEX idx_auth_oauth_providers_tenant_id ON auth_oauth_providers(tenant_id);
CREATE INDEX idx_auth_user_oauth_user_id ON auth_user_oauth(user_id);
CREATE INDEX idx_auth_user_oauth_provider_id ON auth_user_oauth(provider_id);

-- Enhanced triggers for automatic updates
CREATE TRIGGER trigger_auth_permissions_updated_at 
    BEFORE UPDATE ON auth_permissions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_auth_roles_updated_at 
    BEFORE UPDATE ON auth_roles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_auth_user_roles_updated_at 
    BEFORE UPDATE ON auth_user_roles 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_auth_user_permissions_updated_at 
    BEFORE UPDATE ON auth_user_permissions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_auth_mfa_devices_updated_at 
    BEFORE UPDATE ON auth_mfa_devices 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_auth_oauth_providers_updated_at 
    BEFORE UPDATE ON auth_oauth_providers 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert comprehensive Go Factory Platform permissions
INSERT INTO auth_permissions (name, display_name, description, service, resource, action, is_dangerous) VALUES
-- Tenant Management
('tenant.tenants.read', 'View Tenants', 'View tenant information', 'tenant', 'tenants', 'read', FALSE),
('tenant.tenants.update', 'Update Tenants', 'Update tenant settings', 'tenant', 'tenants', 'update', TRUE),
('tenant.clients.create', 'Create Clients', 'Create new client organizations', 'tenant', 'clients', 'create', FALSE),
('tenant.clients.read', 'View Clients', 'View client information', 'tenant', 'clients', 'read', FALSE),
('tenant.clients.update', 'Update Clients', 'Update client settings', 'tenant', 'clients', 'update', FALSE),
('tenant.clients.delete', 'Delete Clients', 'Delete client organizations', 'tenant', 'clients', 'delete', TRUE),

-- User Management
('auth.users.create', 'Create Users', 'Create new users', 'auth', 'users', 'create', FALSE),
('auth.users.read', 'View Users', 'View user profiles', 'auth', 'users', 'read', FALSE),
('auth.users.update', 'Update Users', 'Update user profiles', 'auth', 'users', 'update', FALSE),
('auth.users.delete', 'Delete Users', 'Delete users', 'auth', 'users', 'delete', TRUE),
('auth.users.list', 'List Users', 'List all users', 'auth', 'users', 'list', FALSE),
('auth.users.lock', 'Lock Users', 'Lock/unlock user accounts', 'auth', 'users', 'lock', TRUE),
('auth.users.reset_password', 'Reset Password', 'Reset user passwords', 'auth', 'users', 'reset_password', TRUE),

-- Role Management
('auth.roles.create', 'Create Roles', 'Create new roles', 'auth', 'roles', 'create', FALSE),
('auth.roles.read', 'View Roles', 'View role details', 'auth', 'roles', 'read', FALSE),
('auth.roles.update', 'Update Roles', 'Update role permissions', 'auth', 'roles', 'update', TRUE),
('auth.roles.delete', 'Delete Roles', 'Delete roles', 'auth', 'roles', 'delete', TRUE),
('auth.roles.assign', 'Assign Roles', 'Assign roles to users', 'auth', 'roles', 'assign', TRUE),

-- Template Management
('template.templates.create', 'Create Templates', 'Create new code templates', 'template', 'templates', 'create', FALSE),
('template.templates.read', 'View Templates', 'View template details', 'template', 'templates', 'read', FALSE),
('template.templates.update', 'Update Templates', 'Update template content', 'template', 'templates', 'update', FALSE),
('template.templates.delete', 'Delete Templates', 'Delete templates', 'template', 'templates', 'delete', TRUE),
('template.templates.list', 'List Templates', 'List all templates', 'template', 'templates', 'list', FALSE),
('template.templates.publish', 'Publish Templates', 'Publish templates to marketplace', 'template', 'templates', 'publish', FALSE),
('template.templates.fork', 'Fork Templates', 'Create copies of existing templates', 'template', 'templates', 'fork', FALSE),
('template.categories.create', 'Create Categories', 'Create template categories', 'template', 'categories', 'create', FALSE),
('template.categories.read', 'View Categories', 'View template categories', 'template', 'categories', 'read', FALSE),
('template.categories.update', 'Update Categories', 'Update template categories', 'template', 'categories', 'update', FALSE),
('template.categories.delete', 'Delete Categories', 'Delete template categories', 'template', 'categories', 'delete', TRUE),
('template.versions.create', 'Create Versions', 'Create template versions', 'template', 'versions', 'create', FALSE),
('template.versions.read', 'View Versions', 'View template version history', 'template', 'versions', 'read', FALSE),
('template.versions.update', 'Update Versions', 'Update template versions', 'template', 'versions', 'update', FALSE),
('template.versions.delete', 'Delete Versions', 'Delete template versions', 'template', 'versions', 'delete', TRUE),

-- Code Generation
('generator.projects.create', 'Create Projects', 'Create new code generation projects', 'generator', 'projects', 'create', FALSE),
('generator.projects.read', 'View Projects', 'View project details', 'generator', 'projects', 'read', FALSE),
('generator.projects.update', 'Update Projects', 'Update project configuration', 'generator', 'projects', 'update', FALSE),
('generator.projects.delete', 'Delete Projects', 'Delete projects', 'generator', 'projects', 'delete', TRUE),
('generator.projects.list', 'List Projects', 'List all projects', 'generator', 'projects', 'list', FALSE),
('generator.generate.execute', 'Execute Generation', 'Execute code generation', 'generator', 'generate', 'execute', FALSE),
('generator.builds.create', 'Create Builds', 'Create project builds', 'generator', 'builds', 'create', FALSE),
('generator.builds.read', 'View Builds', 'View build details and logs', 'generator', 'builds', 'read', FALSE),
('generator.builds.delete', 'Delete Builds', 'Delete old builds', 'generator', 'builds', 'delete', FALSE),

-- Platform Management
('platform.integrations.create', 'Create Integrations', 'Create new platform integrations', 'platform', 'integrations', 'create', FALSE),
('platform.integrations.read', 'View Integrations', 'View integration details', 'platform', 'integrations', 'read', FALSE),
('platform.integrations.update', 'Update Integrations', 'Update integration settings', 'platform', 'integrations', 'update', FALSE),
('platform.integrations.delete', 'Delete Integrations', 'Delete integrations', 'platform', 'integrations', 'delete', TRUE),
('platform.apis.create', 'Create APIs', 'Create new API endpoints', 'platform', 'apis', 'create', FALSE),
('platform.apis.read', 'View APIs', 'View API documentation', 'platform', 'apis', 'read', FALSE),
('platform.apis.update', 'Update APIs', 'Update API configurations', 'platform', 'apis', 'update', FALSE),
('platform.apis.delete', 'Delete APIs', 'Delete API endpoints', 'platform', 'apis', 'delete', TRUE),

-- Reporting and Analytics
('reporting.generation.read', 'Generation Reports', 'Access code generation reports', 'reporting', 'generation', 'read', FALSE),
('reporting.usage.read', 'Usage Reports', 'Access platform usage reports', 'reporting', 'usage', 'read', FALSE),
('reporting.analytics.read', 'Analytics', 'Access analytics dashboard', 'reporting', 'analytics', 'read', FALSE),
('reporting.audit.read', 'Audit Reports', 'Access audit trail reports', 'reporting', 'audit', 'read', TRUE),
('reporting.reports.export', 'Export Reports', 'Export reports to various formats', 'reporting', 'reports', 'export', FALSE),

-- System Administration
('system.configuration.read', 'View Configuration', 'View system configuration', 'system', 'configuration', 'read', FALSE),
('system.configuration.update', 'Update Configuration', 'Update system settings', 'system', 'configuration', 'update', TRUE),
('system.audit.read', 'View Audit Log', 'View system audit logs', 'system', 'audit', 'read', TRUE),
('system.maintenance.execute', 'System Maintenance', 'Execute maintenance tasks', 'system', 'maintenance', 'execute', TRUE),
('system.admin.access', 'System Administration', 'Full system administration access', 'system', 'admin', 'access', TRUE);

-- Insert default system roles for each tenant
INSERT INTO auth_roles (tenant_id, name, display_name, description, is_system_role, is_admin_role, is_default_role, role_level) 
SELECT 
    t.id,
    'super_admin',
    'Super Administrator', 
    'Full system access with all permissions',
    TRUE,
    TRUE,
    FALSE,
    1
FROM tenants t
ON CONFLICT (tenant_id, client_id, name) DO NOTHING;

INSERT INTO auth_roles (tenant_id, name, display_name, description, is_system_role, is_admin_role, is_default_role, role_level)
SELECT 
    t.id,
    'admin',
    'Administrator',
    'Administrative access with most permissions',
    TRUE,
    TRUE,
    FALSE,
    2
FROM tenants t
ON CONFLICT (tenant_id, client_id, name) DO NOTHING;

INSERT INTO auth_roles (tenant_id, name, display_name, description, is_system_role, is_default_role, role_level)
SELECT 
    t.id,
    'template_manager',
    'Template Manager',
    'Full template management and code generation access',
    TRUE,
    FALSE,
    3
FROM tenants t
ON CONFLICT (tenant_id, client_id, name) DO NOTHING;

INSERT INTO auth_roles (tenant_id, name, display_name, description, is_system_role, is_default_role, role_level)
SELECT 
    t.id,
    'developer',
    'Developer',
    'Code generation and template usage access',
    TRUE,
    FALSE,
    4
FROM tenants t
ON CONFLICT (tenant_id, client_id, name) DO NOTHING;

INSERT INTO auth_roles (tenant_id, name, display_name, description, is_system_role, is_default_role, role_level)
SELECT 
    t.id,
    'user',
    'User',
    'Standard user access',
    TRUE,
    TRUE,
    5
FROM tenants t
ON CONFLICT (tenant_id, client_id, name) DO NOTHING;
