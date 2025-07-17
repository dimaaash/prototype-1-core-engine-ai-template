-- Migration: add_multi_client_support
-- Service: user_service  
-- Description: Add multi-client support to user service tables

-- Add client_id to users table
ALTER TABLE users 
ADD COLUMN client_id UUID REFERENCES clients(id) ON DELETE CASCADE;

-- Add client_id to user_profiles table
ALTER TABLE user_profiles 
ADD COLUMN client_id UUID REFERENCES clients(id) ON DELETE CASCADE;

-- Add client_id to user_activities table
ALTER TABLE user_activities 
ADD COLUMN client_id UUID REFERENCES clients(id) ON DELETE CASCADE;

-- Add client_id to user_email_verifications table
ALTER TABLE user_email_verifications 
ADD COLUMN client_id UUID REFERENCES clients(id) ON DELETE CASCADE;

-- Add client_id to user_phone_verifications table
ALTER TABLE user_phone_verifications 
ADD COLUMN client_id UUID REFERENCES clients(id) ON DELETE CASCADE;

-- Add client_id to user_invitations table
ALTER TABLE user_invitations 
ADD COLUMN client_id UUID REFERENCES clients(id) ON DELETE CASCADE;

-- Add client_id to user_settings table
ALTER TABLE user_settings 
ADD COLUMN client_id UUID REFERENCES clients(id) ON DELETE CASCADE;

-- Add client_id to user_teams table
ALTER TABLE user_teams 
ADD COLUMN client_id UUID REFERENCES clients(id) ON DELETE CASCADE;

-- Update unique constraints to include client_id scope

-- Update users unique constraint (tenant + client + email)
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_tenant_id_email_key;
ALTER TABLE users ADD CONSTRAINT users_tenant_client_email_unique 
    UNIQUE(tenant_id, client_id, email);

-- Update user_teams unique constraint (tenant + client + name)
ALTER TABLE user_teams DROP CONSTRAINT IF EXISTS user_teams_tenant_id_name_key;
ALTER TABLE user_teams ADD CONSTRAINT user_teams_tenant_client_name_unique 
    UNIQUE(tenant_id, client_id, name);

-- Update user_settings unique constraint (user + client + category + key)
ALTER TABLE user_settings DROP CONSTRAINT IF EXISTS user_settings_user_id_category_setting_key_key;
ALTER TABLE user_settings ADD CONSTRAINT user_settings_user_client_category_key_unique 
    UNIQUE(user_id, client_id, category, setting_key);

-- Create new indexes for client-scoped queries
CREATE INDEX idx_users_tenant_client_id ON users(tenant_id, client_id);
CREATE INDEX idx_users_client_id ON users(client_id);
CREATE INDEX idx_users_client_status ON users(client_id, status);

CREATE INDEX idx_user_profiles_client_id ON user_profiles(client_id);
CREATE INDEX idx_user_profiles_tenant_client_id ON user_profiles(tenant_id, client_id);

CREATE INDEX idx_user_activities_client_id ON user_activities(client_id);
CREATE INDEX idx_user_activities_tenant_client_id ON user_activities(tenant_id, client_id);

CREATE INDEX idx_user_email_verifications_client_id ON user_email_verifications(client_id);

CREATE INDEX idx_user_phone_verifications_client_id ON user_phone_verifications(client_id);

CREATE INDEX idx_user_invitations_client_id ON user_invitations(client_id);
CREATE INDEX idx_user_invitations_tenant_client_id ON user_invitations(tenant_id, client_id);

CREATE INDEX idx_user_settings_client_id ON user_settings(client_id);
CREATE INDEX idx_user_settings_tenant_client_id ON user_settings(tenant_id, client_id);

CREATE INDEX idx_user_teams_client_id ON user_teams(client_id);
CREATE INDEX idx_user_teams_tenant_client_id ON user_teams(tenant_id, client_id);

-- Set default client_id for existing records based on system client
-- First, get the default client ID from the system tenant
DO $$
DECLARE 
    default_client_id UUID;
    system_tenant_id UUID;
BEGIN
    -- Get system tenant ID
    SELECT id INTO system_tenant_id FROM tenants WHERE slug = 'system';
    
    -- Get default client ID  
    SELECT id INTO default_client_id FROM clients 
    WHERE tenant_id = system_tenant_id AND code = 'DEFAULT';
    
    -- Only proceed if we found the default client
    IF default_client_id IS NOT NULL THEN
        -- Update existing users records
        UPDATE users SET client_id = default_client_id WHERE client_id IS NULL;
        
        -- Update existing user_profiles records
        UPDATE user_profiles SET client_id = default_client_id WHERE client_id IS NULL;
        
        -- Update existing user_activities records
        UPDATE user_activities SET client_id = default_client_id WHERE client_id IS NULL;
        
        -- Update existing user_email_verifications records
        UPDATE user_email_verifications SET client_id = default_client_id WHERE client_id IS NULL;
        
        -- Update existing user_phone_verifications records
        UPDATE user_phone_verifications SET client_id = default_client_id WHERE client_id IS NULL;
        
        -- Update existing user_invitations records
        UPDATE user_invitations SET client_id = default_client_id WHERE client_id IS NULL;
        
        -- Update existing user_settings records
        UPDATE user_settings SET client_id = default_client_id WHERE client_id IS NULL;
        
        -- Update existing user_teams records
        UPDATE user_teams SET client_id = default_client_id WHERE client_id IS NULL;
        
        RAISE NOTICE 'Updated existing records with default client_id: %', default_client_id;
    ELSE
        RAISE WARNING 'Default client not found - manual client_id assignment required';
    END IF;
END $$;

-- Make client_id NOT NULL after setting defaults
ALTER TABLE users ALTER COLUMN client_id SET NOT NULL;
ALTER TABLE user_profiles ALTER COLUMN client_id SET NOT NULL;
ALTER TABLE user_activities ALTER COLUMN client_id SET NOT NULL;
ALTER TABLE user_email_verifications ALTER COLUMN client_id SET NOT NULL;
ALTER TABLE user_phone_verifications ALTER COLUMN client_id SET NOT NULL;
ALTER TABLE user_invitations ALTER COLUMN client_id SET NOT NULL;
ALTER TABLE user_settings ALTER COLUMN client_id SET NOT NULL;
ALTER TABLE user_teams ALTER COLUMN client_id SET NOT NULL;

-- Update audit logging function to include client_id
CREATE OR REPLACE FUNCTION log_user_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM log_audit_entry(
            NEW.tenant_id,
            NEW.client_id, -- Now includes client_id
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
            NEW.client_id, -- Now includes client_id
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
            OLD.client_id, -- Now includes client_id
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

-- Create helper functions for multi-client user management

-- Function to get users by client
CREATE OR REPLACE FUNCTION get_users_by_client(
    p_tenant_id UUID,
    p_client_id UUID,
    p_status status_enum DEFAULT NULL,
    p_limit INTEGER DEFAULT 100,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    email VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    status status_enum,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.email,
        u.first_name,
        u.last_name,
        u.status,
        u.last_login_at,
        u.created_at
    FROM users u
    WHERE u.tenant_id = p_tenant_id 
    AND u.client_id = p_client_id
    AND (p_status IS NULL OR u.status = p_status)
    AND u.deleted_at IS NULL
    ORDER BY u.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- Function to move user between clients (within same tenant)
CREATE OR REPLACE FUNCTION move_user_to_client(
    p_user_id UUID,
    p_new_client_id UUID,
    p_moved_by UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    user_tenant_id UUID;
    old_client_id UUID;
    new_client_tenant_id UUID;
BEGIN
    -- Get user's current tenant and client
    SELECT tenant_id, client_id INTO user_tenant_id, old_client_id
    FROM users WHERE id = p_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'User not found: %', p_user_id;
    END IF;
    
    -- Verify new client exists and belongs to same tenant
    SELECT tenant_id INTO new_client_tenant_id
    FROM clients WHERE id = p_new_client_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Client not found: %', p_new_client_id;
    END IF;
    
    IF new_client_tenant_id != user_tenant_id THEN
        RAISE EXCEPTION 'Cannot move user to client in different tenant';
    END IF;
    
    -- Update user's client_id
    UPDATE users SET 
        client_id = p_new_client_id,
        updated_at = NOW(),
        version = version + 1
    WHERE id = p_user_id;
    
    -- Update related records
    UPDATE user_profiles SET client_id = p_new_client_id WHERE user_id = p_user_id;
    UPDATE user_activities SET client_id = p_new_client_id WHERE user_id = p_user_id;
    UPDATE user_email_verifications SET client_id = p_new_client_id WHERE user_id = p_user_id;
    UPDATE user_phone_verifications SET client_id = p_new_client_id WHERE user_id = p_user_id;
    UPDATE user_settings SET client_id = p_new_client_id WHERE user_id = p_user_id;
    
    -- Log the move
    PERFORM log_audit_entry(
        user_tenant_id,
        p_new_client_id,
        p_moved_by,
        'user',
        'user',
        p_user_id,
        'client_move',
        jsonb_build_object('old_client_id', old_client_id),
        jsonb_build_object('new_client_id', p_new_client_id),
        jsonb_build_object('moved_by', p_moved_by)
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to get client statistics  
CREATE OR REPLACE FUNCTION get_client_user_stats(
    p_tenant_id UUID,
    p_client_id UUID
)
RETURNS TABLE (
    total_users BIGINT,
    active_users BIGINT,
    inactive_users BIGINT,
    pending_users BIGINT,
    users_with_profiles BIGINT,
    recent_logins_7d BIGINT,
    pending_invitations BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) FILTER (WHERE u.deleted_at IS NULL) as total_users,
        COUNT(*) FILTER (WHERE u.status = 'active' AND u.deleted_at IS NULL) as active_users,
        COUNT(*) FILTER (WHERE u.status = 'inactive' AND u.deleted_at IS NULL) as inactive_users,
        COUNT(*) FILTER (WHERE u.status = 'pending' AND u.deleted_at IS NULL) as pending_users,
        COUNT(up.id) as users_with_profiles,
        COUNT(*) FILTER (WHERE u.last_login_at > NOW() - INTERVAL '7 days' AND u.deleted_at IS NULL) as recent_logins_7d,
        (SELECT COUNT(*) FROM user_invitations 
         WHERE tenant_id = p_tenant_id AND client_id = p_client_id 
         AND accepted_at IS NULL AND expires_at > NOW()) as pending_invitations
    FROM users u
    LEFT JOIN user_profiles up ON u.id = up.user_id
    WHERE u.tenant_id = p_tenant_id 
    AND u.client_id = p_client_id;
END;
$$ LANGUAGE plpgsql;

-- Add comments to document the multi-client support
COMMENT ON COLUMN users.client_id IS 'Client organization within tenant for multi-client support';
COMMENT ON COLUMN user_profiles.client_id IS 'Client organization for profile scoping';
COMMENT ON COLUMN user_activities.client_id IS 'Client organization for activity logging';
COMMENT ON COLUMN user_teams.client_id IS 'Client organization for team scoping';

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Multi-client support successfully added to user_service';
    RAISE NOTICE 'All user tables now include client_id for proper isolation';
    RAISE NOTICE 'Helper functions created for multi-client user management';
END $$;
