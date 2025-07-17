-- Migration: add_security_features (DOWN)
-- Service: user_service  
-- Description: Remove security features enhancement

-- Drop security functions
DROP FUNCTION IF EXISTS update_session_activity(VARCHAR(255));
DROP FUNCTION IF EXISTS create_user_session(UUID, INET, TEXT, VARCHAR(50), INTEGER);
DROP FUNCTION IF EXISTS enable_user_2fa(UUID, VARCHAR(100), VARCHAR(50), VARCHAR(255));
DROP FUNCTION IF EXISTS generate_totp_secret();
DROP FUNCTION IF EXISTS use_password_reset_token(VARCHAR(255), VARCHAR(255));
DROP FUNCTION IF EXISTS create_password_reset_token(UUID, INET, TEXT);
DROP FUNCTION IF EXISTS record_login_attempt(VARCHAR(255), INET, TEXT, BOOLEAN, VARCHAR(100), UUID, UUID, UUID);
DROP FUNCTION IF EXISTS unlock_user_account(UUID, UUID);
DROP FUNCTION IF EXISTS lock_user_account(UUID, INTEGER, VARCHAR(100));
DROP FUNCTION IF EXISTS verify_password(TEXT, TEXT);
DROP FUNCTION IF EXISTS hash_password(TEXT);

-- Drop triggers
DROP TRIGGER IF EXISTS trigger_user_mfa_devices_updated_at ON user_mfa_devices;

-- Drop security tables
DROP TABLE IF EXISTS user_security_events;
DROP TABLE IF EXISTS user_login_attempts;
DROP TABLE IF EXISTS user_mfa_devices;
DROP TABLE IF EXISTS user_password_resets;
DROP TABLE IF EXISTS user_sessions;

-- Drop security indexes from users table
DROP INDEX IF EXISTS idx_users_last_login_ip;
DROP INDEX IF EXISTS idx_users_last_activity;
DROP INDEX IF EXISTS idx_users_locked;
DROP INDEX IF EXISTS idx_users_password_reset;
DROP INDEX IF EXISTS idx_users_two_factor;

-- Remove security constraints
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_failed_attempts_valid;
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_email_lowercase;

-- Rename column back
ALTER TABLE users RENAME COLUMN failed_login_attempts TO login_attempts;

-- Remove security columns from users table
ALTER TABLE users 
DROP COLUMN IF EXISTS display_name,
DROP COLUMN IF EXISTS last_activity_at,
DROP COLUMN IF EXISTS last_login_ip,
DROP COLUMN IF EXISTS password_reset_expires_at,
DROP COLUMN IF EXISTS password_reset_token,
DROP COLUMN IF EXISTS backup_codes,
DROP COLUMN IF EXISTS two_factor_secret,
DROP COLUMN IF EXISTS two_factor_enabled;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Security features successfully removed from user_service';
    RAISE NOTICE 'Removed: 2FA support, password reset, session management, login tracking';
    RAISE NOTICE 'Dropped tables: user_sessions, user_password_resets, user_mfa_devices, user_login_attempts, user_security_events';
END $$;
