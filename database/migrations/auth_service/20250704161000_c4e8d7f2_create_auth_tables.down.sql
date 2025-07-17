-- Rollback: create_auth_tables
-- Service: auth

-- Drop triggers
DROP TRIGGER IF EXISTS trigger_auth_permissions_updated_at ON auth_permissions;
DROP TRIGGER IF EXISTS trigger_auth_roles_updated_at ON auth_roles;
DROP TRIGGER IF EXISTS trigger_auth_user_roles_updated_at ON auth_user_roles;
DROP TRIGGER IF EXISTS trigger_auth_user_permissions_updated_at ON auth_user_permissions;
DROP TRIGGER IF EXISTS trigger_auth_mfa_devices_updated_at ON auth_mfa_devices;
DROP TRIGGER IF EXISTS trigger_auth_oauth_providers_updated_at ON auth_oauth_providers;

-- Drop tables (in reverse order of creation)
DROP TABLE IF EXISTS auth_user_oauth;
DROP TABLE IF EXISTS auth_oauth_providers;
DROP TABLE IF EXISTS auth_security_events;
DROP TABLE IF EXISTS auth_mfa_devices;
DROP TABLE IF EXISTS auth_password_resets;
DROP TABLE IF EXISTS auth_sessions;
DROP TABLE IF EXISTS auth_user_permissions;
DROP TABLE IF EXISTS auth_user_roles;
DROP TABLE IF EXISTS auth_role_permissions;
DROP TABLE IF EXISTS auth_roles;
DROP TABLE IF EXISTS auth_permissions;
