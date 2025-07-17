-- Migration: add_user_foreign_keys
-- Service: auth
-- Description: Add foreign key constraints to users table after user service is created

-- Add foreign key constraints for user references in auth tables
ALTER TABLE auth_role_permissions 
ADD CONSTRAINT fk_auth_role_permissions_granted_by 
FOREIGN KEY (granted_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE auth_user_roles 
ADD CONSTRAINT fk_auth_user_roles_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE auth_user_roles 
ADD CONSTRAINT fk_auth_user_roles_assigned_by 
FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE auth_user_permissions 
ADD CONSTRAINT fk_auth_user_permissions_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE auth_user_permissions 
ADD CONSTRAINT fk_auth_user_permissions_granted_by 
FOREIGN KEY (granted_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE auth_sessions 
ADD CONSTRAINT fk_auth_sessions_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE auth_password_resets 
ADD CONSTRAINT fk_auth_password_resets_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE auth_mfa_devices 
ADD CONSTRAINT fk_auth_mfa_devices_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE auth_user_oauth 
ADD CONSTRAINT fk_auth_user_oauth_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
