-- Migration: add_user_foreign_keys (down)
-- Service: auth
-- Description: Remove foreign key constraints to users table

-- Drop foreign key constraints for user references in auth tables
ALTER TABLE auth_role_permissions 
DROP CONSTRAINT IF EXISTS fk_auth_role_permissions_granted_by;

ALTER TABLE auth_user_roles 
DROP CONSTRAINT IF EXISTS fk_auth_user_roles_user_id;

ALTER TABLE auth_user_roles 
DROP CONSTRAINT IF EXISTS fk_auth_user_roles_assigned_by;

ALTER TABLE auth_user_permissions 
DROP CONSTRAINT IF EXISTS fk_auth_user_permissions_user_id;

ALTER TABLE auth_user_permissions 
DROP CONSTRAINT IF EXISTS fk_auth_user_permissions_granted_by;

ALTER TABLE auth_sessions 
DROP CONSTRAINT IF EXISTS fk_auth_sessions_user_id;

ALTER TABLE auth_password_resets 
DROP CONSTRAINT IF EXISTS fk_auth_password_resets_user_id;

ALTER TABLE auth_mfa_devices 
DROP CONSTRAINT IF EXISTS fk_auth_mfa_devices_user_id;

ALTER TABLE auth_user_oauth 
DROP CONSTRAINT IF EXISTS fk_auth_user_oauth_user_id;
