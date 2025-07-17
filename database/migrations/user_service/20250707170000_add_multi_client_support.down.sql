-- Migration: add_multi_client_support (DOWN)
-- Service: user_service  
-- Description: Remove multi-client support from user service tables

-- Drop helper functions
DROP FUNCTION IF EXISTS get_client_user_stats(UUID, UUID);
DROP FUNCTION IF EXISTS move_user_to_client(UUID, UUID, UUID);
DROP FUNCTION IF EXISTS get_users_by_client(UUID, UUID, status_enum, INTEGER, INTEGER);

-- Restore original audit logging function without client_id
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

-- Drop client-related indexes
DROP INDEX IF EXISTS idx_users_tenant_client_id;
DROP INDEX IF EXISTS idx_users_client_id;
DROP INDEX IF EXISTS idx_users_client_status;
DROP INDEX IF EXISTS idx_user_profiles_client_id;
DROP INDEX IF EXISTS idx_user_profiles_tenant_client_id;
DROP INDEX IF EXISTS idx_user_activities_client_id;
DROP INDEX IF EXISTS idx_user_activities_tenant_client_id;
DROP INDEX IF EXISTS idx_user_email_verifications_client_id;
DROP INDEX IF EXISTS idx_user_phone_verifications_client_id;
DROP INDEX IF EXISTS idx_user_invitations_client_id;
DROP INDEX IF EXISTS idx_user_invitations_tenant_client_id;
DROP INDEX IF EXISTS idx_user_settings_client_id;
DROP INDEX IF EXISTS idx_user_settings_tenant_client_id;
DROP INDEX IF EXISTS idx_user_teams_client_id;
DROP INDEX IF EXISTS idx_user_teams_tenant_client_id;

-- Restore original unique constraints

-- Restore users unique constraint (tenant + email only)
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_tenant_client_email_unique;
ALTER TABLE users ADD CONSTRAINT users_tenant_id_email_key 
    UNIQUE(tenant_id, email);

-- Restore user_teams unique constraint (tenant + name only)
ALTER TABLE user_teams DROP CONSTRAINT IF EXISTS user_teams_tenant_client_name_unique;
ALTER TABLE user_teams ADD CONSTRAINT user_teams_tenant_id_name_key 
    UNIQUE(tenant_id, name);

-- Restore user_settings unique constraint (user + category + key only)
ALTER TABLE user_settings DROP CONSTRAINT IF EXISTS user_settings_user_client_category_key_unique;
ALTER TABLE user_settings ADD CONSTRAINT user_settings_user_id_category_setting_key_key 
    UNIQUE(user_id, category, setting_key);

-- Remove client_id columns from all tables
ALTER TABLE users DROP COLUMN IF EXISTS client_id;
ALTER TABLE user_profiles DROP COLUMN IF EXISTS client_id;
ALTER TABLE user_activities DROP COLUMN IF EXISTS client_id;
ALTER TABLE user_email_verifications DROP COLUMN IF EXISTS client_id;
ALTER TABLE user_phone_verifications DROP COLUMN IF EXISTS client_id;
ALTER TABLE user_invitations DROP COLUMN IF EXISTS client_id;
ALTER TABLE user_settings DROP COLUMN IF EXISTS client_id;
ALTER TABLE user_teams DROP COLUMN IF EXISTS client_id;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Multi-client support successfully removed from user_service';
    RAISE NOTICE 'All client_id columns and related constraints have been dropped';
    RAISE NOTICE 'Original unique constraints and indexes restored';
END $$;
