-- Rollback: create_users_table
-- Service: user

-- Drop triggers
DROP TRIGGER IF EXISTS trigger_users_audit_log ON users;
DROP TRIGGER IF EXISTS trigger_user_profiles_employee_id ON user_profiles;
DROP TRIGGER IF EXISTS trigger_users_updated_at ON users;
DROP TRIGGER IF EXISTS trigger_user_profiles_updated_at ON user_profiles;
DROP TRIGGER IF EXISTS trigger_user_settings_updated_at ON user_settings;
DROP TRIGGER IF EXISTS trigger_user_teams_updated_at ON user_teams;

-- Drop functions
DROP FUNCTION IF EXISTS log_user_changes();
DROP FUNCTION IF EXISTS auto_generate_employee_id();
DROP FUNCTION IF EXISTS generate_employee_id();

-- Drop sequences
DROP SEQUENCE IF EXISTS user_employee_id_seq;

-- Drop tables (in reverse order of creation)
DROP TABLE IF EXISTS user_team_memberships;
DROP TABLE IF EXISTS user_teams;
DROP TABLE IF EXISTS user_settings;
DROP TABLE IF EXISTS user_invitations;
DROP TABLE IF EXISTS user_phone_verifications;
DROP TABLE IF EXISTS user_email_verifications;
DROP TABLE IF EXISTS user_activities;
DROP TABLE IF EXISTS user_profiles;
-- Note: user_roles table is handled by auth_service (auth_user_roles)
DROP TABLE IF EXISTS users;
