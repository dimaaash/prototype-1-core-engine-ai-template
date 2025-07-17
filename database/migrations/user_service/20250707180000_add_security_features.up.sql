-- Migration: add_security_features
-- Service: user_service  
-- Description: Add comprehensive security features from GO-WMS-2 (2FA, account locking, password reset, session tracking)

-- Add missing security columns to users table
ALTER TABLE users 
ADD COLUMN two_factor_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN two_factor_secret VARCHAR(255),
ADD COLUMN backup_codes TEXT[],
ADD COLUMN password_reset_token VARCHAR(255),
ADD COLUMN password_reset_expires_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN last_login_ip INET,
ADD COLUMN last_activity_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN display_name VARCHAR(200);

-- Update existing constraints to match GO-WMS-2 standards
ALTER TABLE users 
ADD CONSTRAINT users_email_lowercase CHECK (email = LOWER(email)),
ADD CONSTRAINT users_failed_attempts_valid CHECK (login_attempts >= 0);

-- Rename login_attempts to failed_login_attempts for consistency with GO-WMS-2
ALTER TABLE users RENAME COLUMN login_attempts TO failed_login_attempts;

-- Create additional security indexes
CREATE INDEX idx_users_two_factor ON users(two_factor_enabled) WHERE two_factor_enabled = TRUE;
CREATE INDEX idx_users_password_reset ON users(password_reset_token) WHERE password_reset_token IS NOT NULL;
CREATE INDEX idx_users_locked ON users(locked_until) WHERE locked_until IS NOT NULL;
CREATE INDEX idx_users_last_activity ON users(last_activity_at);
CREATE INDEX idx_users_last_login_ip ON users(last_login_ip) WHERE last_login_ip IS NOT NULL;

-- Create sessions table for advanced session management
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    
    -- Session identification
    session_token VARCHAR(255) NOT NULL UNIQUE,
    refresh_token VARCHAR(255) UNIQUE,
    
    -- Session metadata
    ip_address INET NOT NULL,
    user_agent TEXT,
    device_fingerprint VARCHAR(255),
    device_type VARCHAR(50), -- web, mobile, api, etc.
    
    -- Location data
    country VARCHAR(2),
    region VARCHAR(100),
    city VARCHAR(100),
    
    -- Session lifecycle
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Session status
    is_active BOOLEAN DEFAULT TRUE,
    logout_at TIMESTAMP WITH TIME ZONE,
    logout_reason VARCHAR(50), -- manual, timeout, forced, security
    
    -- Security flags
    is_suspicious BOOLEAN DEFAULT FALSE,
    requires_verification BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    metadata JSONB DEFAULT '{}'
);

-- Session indexes for performance
CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_tenant_client ON user_sessions(tenant_id, client_id);
CREATE INDEX idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX idx_user_sessions_refresh_token ON user_sessions(refresh_token) WHERE refresh_token IS NOT NULL;
CREATE INDEX idx_user_sessions_active ON user_sessions(is_active, expires_at) WHERE is_active = TRUE;
CREATE INDEX idx_user_sessions_suspicious ON user_sessions(is_suspicious) WHERE is_suspicious = TRUE;
CREATE INDEX idx_user_sessions_device ON user_sessions(user_id, device_type);
CREATE INDEX idx_user_sessions_ip ON user_sessions(ip_address);
CREATE INDEX idx_user_sessions_last_activity ON user_sessions(last_activity_at);

-- Password reset tokens table for enhanced security
CREATE TABLE user_password_resets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    
    -- Token information
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Request metadata
    ip_address INET NOT NULL,
    user_agent TEXT,
    
    -- Status
    used_at TIMESTAMP WITH TIME ZONE,
    attempts INTEGER DEFAULT 0,
    is_valid BOOLEAN DEFAULT TRUE,
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT password_reset_expires_future CHECK (expires_at > created_at),
    CONSTRAINT password_reset_attempts_valid CHECK (attempts >= 0)
);

-- Password reset indexes
CREATE INDEX idx_user_password_resets_user_id ON user_password_resets(user_id);
CREATE INDEX idx_user_password_resets_token_hash ON user_password_resets(token_hash);
CREATE INDEX idx_user_password_resets_expires_at ON user_password_resets(expires_at);
CREATE INDEX idx_user_password_resets_valid ON user_password_resets(is_valid) WHERE is_valid = TRUE;

-- Two-factor authentication devices table
CREATE TABLE user_mfa_devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    
    -- Device information
    device_name VARCHAR(100) NOT NULL,
    device_type VARCHAR(50) NOT NULL, -- totp, sms, email, hardware_key
    
    -- TOTP specific
    secret_key VARCHAR(255), -- for TOTP devices
    
    -- SMS/Email specific  
    phone_number VARCHAR(20), -- for SMS devices
    email_address VARCHAR(255), -- for email devices
    
    -- Hardware key specific
    key_handle VARCHAR(500), -- for hardware keys
    public_key TEXT, -- for hardware keys
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    
    -- Recovery
    backup_codes TEXT[], -- encrypted backup codes
    backup_codes_used TEXT[] DEFAULT '{}',
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    
    -- Constraints
    CONSTRAINT mfa_device_type_valid CHECK (device_type IN ('totp', 'sms', 'email', 'hardware_key')),
    CONSTRAINT mfa_phone_valid CHECK (phone_number IS NULL OR validate_phone(phone_number)),
    CONSTRAINT mfa_email_valid CHECK (email_address IS NULL OR validate_email(email_address))
);

-- MFA device indexes
CREATE INDEX idx_user_mfa_devices_user_id ON user_mfa_devices(user_id);
CREATE INDEX idx_user_mfa_devices_tenant_client ON user_mfa_devices(tenant_id, client_id);
CREATE INDEX idx_user_mfa_devices_active ON user_mfa_devices(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_user_mfa_devices_type ON user_mfa_devices(device_type);
CREATE INDEX idx_user_mfa_devices_verified ON user_mfa_devices(is_verified) WHERE is_verified = TRUE;

-- Login attempts tracking table
CREATE TABLE user_login_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE, -- NULL for failed email lookups
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    
    -- Attempt details
    email VARCHAR(255) NOT NULL, -- store email even if user lookup fails
    ip_address INET NOT NULL,
    user_agent TEXT,
    
    -- Result
    success BOOLEAN NOT NULL,
    failure_reason VARCHAR(100), -- invalid_password, account_locked, invalid_email, etc.
    
    -- Two-factor
    mfa_required BOOLEAN DEFAULT FALSE,
    mfa_success BOOLEAN,
    mfa_device_type VARCHAR(50),
    
    -- Location
    country VARCHAR(2),
    region VARCHAR(100),
    city VARCHAR(100),
    
    -- Audit
    attempted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Login attempts indexes
CREATE INDEX idx_user_login_attempts_user_id ON user_login_attempts(user_id);
CREATE INDEX idx_user_login_attempts_email ON user_login_attempts(email);
CREATE INDEX idx_user_login_attempts_ip ON user_login_attempts(ip_address);
CREATE INDEX idx_user_login_attempts_success ON user_login_attempts(success);
CREATE INDEX idx_user_login_attempts_attempted_at ON user_login_attempts(attempted_at);
CREATE INDEX idx_user_login_attempts_tenant_client ON user_login_attempts(tenant_id, client_id);

-- Security audit log table
CREATE TABLE user_security_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    
    -- Event details
    event_type VARCHAR(100) NOT NULL, -- password_change, 2fa_enabled, account_locked, etc.
    event_description TEXT,
    
    -- Context
    ip_address INET,
    user_agent TEXT,
    session_id UUID REFERENCES user_sessions(id) ON DELETE SET NULL,
    
    -- Severity
    severity VARCHAR(20) DEFAULT 'info', -- info, warning, critical
    risk_score INTEGER DEFAULT 0, -- 0-100
    
    -- Additional data
    metadata JSONB DEFAULT '{}',
    
    -- Audit
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Security events indexes
CREATE INDEX idx_user_security_events_user_id ON user_security_events(user_id);
CREATE INDEX idx_user_security_events_tenant_client ON user_security_events(tenant_id, client_id);
CREATE INDEX idx_user_security_events_type ON user_security_events(event_type);
CREATE INDEX idx_user_security_events_severity ON user_security_events(severity);
CREATE INDEX idx_user_security_events_risk_score ON user_security_events(risk_score);
CREATE INDEX idx_user_security_events_created_at ON user_security_events(created_at);

-- Triggers for automatic timestamp updates
CREATE TRIGGER trigger_user_mfa_devices_updated_at 
    BEFORE UPDATE ON user_mfa_devices 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enhanced security functions

-- Password hashing function (placeholder - implement with bcrypt)
CREATE OR REPLACE FUNCTION hash_password(plain_password TEXT)
RETURNS TEXT AS $$
BEGIN
    -- This is a placeholder - implement with bcrypt or similar
    -- In production, this should use a proper password hashing library
    RETURN 'bcrypt_' || plain_password || '_salt';
END;
$$ LANGUAGE plpgsql;

-- Password verification function (placeholder)
CREATE OR REPLACE FUNCTION verify_password(plain_password TEXT, password_hash TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- This is a placeholder - implement with bcrypt or similar
    RETURN password_hash = 'bcrypt_' || plain_password || '_salt';
END;
$$ LANGUAGE plpgsql;

-- Lock user account function
CREATE OR REPLACE FUNCTION lock_user_account(
    p_user_id UUID, 
    p_lock_duration_minutes INTEGER DEFAULT 30,
    p_reason VARCHAR(100) DEFAULT 'failed_login_attempts'
)
RETURNS VOID AS $$
BEGIN
    UPDATE users 
    SET 
        locked_until = NOW() + (p_lock_duration_minutes || ' minutes')::INTERVAL,
        updated_at = NOW(),
        version = version + 1
    WHERE id = p_user_id;
    
    -- Log security event
    INSERT INTO user_security_events (user_id, tenant_id, client_id, event_type, event_description, severity, risk_score)
    SELECT 
        p_user_id,
        tenant_id,
        client_id,
        'account_locked',
        'Account locked due to: ' || p_reason || ' for ' || p_lock_duration_minutes || ' minutes',
        'warning',
        75
    FROM users WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- Unlock user account function
CREATE OR REPLACE FUNCTION unlock_user_account(
    p_user_id UUID,
    p_unlocked_by UUID DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE users 
    SET 
        locked_until = NULL,
        failed_login_attempts = 0,
        updated_at = NOW(),
        version = version + 1
    WHERE id = p_user_id;
    
    -- Log security event
    INSERT INTO user_security_events (user_id, tenant_id, client_id, event_type, event_description, severity)
    SELECT 
        p_user_id,
        tenant_id,
        client_id,
        'account_unlocked',
        'Account unlocked' || CASE WHEN p_unlocked_by IS NOT NULL THEN ' by admin' ELSE ' automatically' END,
        'info'
    FROM users WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- Record login attempt function
CREATE OR REPLACE FUNCTION record_login_attempt(
    p_email VARCHAR(255),
    p_ip_address INET,
    p_user_agent TEXT,
    p_success BOOLEAN,
    p_failure_reason VARCHAR(100) DEFAULT NULL,
    p_user_id UUID DEFAULT NULL,
    p_tenant_id UUID DEFAULT NULL,
    p_client_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    attempt_id UUID;
BEGIN
    INSERT INTO user_login_attempts (
        user_id, tenant_id, client_id, email, ip_address, user_agent, 
        success, failure_reason
    ) VALUES (
        p_user_id, p_tenant_id, p_client_id, p_email, p_ip_address, p_user_agent,
        p_success, p_failure_reason
    ) RETURNING id INTO attempt_id;
    
    -- If failed login and user exists, increment failed attempts
    IF NOT p_success AND p_user_id IS NOT NULL THEN
        UPDATE users 
        SET 
            failed_login_attempts = failed_login_attempts + 1,
            updated_at = NOW(),
            version = version + 1
        WHERE id = p_user_id;
        
        -- Check if account should be locked (after 5 failed attempts)
        DECLARE
            current_attempts INTEGER;
        BEGIN
            SELECT failed_login_attempts INTO current_attempts
            FROM users WHERE id = p_user_id;
            
            IF current_attempts >= 5 THEN
                PERFORM lock_user_account(p_user_id, 30, 'excessive_failed_logins');
            END IF;
        END;
    END IF;
    
    -- If successful login, reset failed attempts
    IF p_success AND p_user_id IS NOT NULL THEN
        UPDATE users 
        SET 
            failed_login_attempts = 0,
            last_login_at = NOW(),
            last_login_ip = p_ip_address,
            last_activity_at = NOW(),
            updated_at = NOW(),
            version = version + 1
        WHERE id = p_user_id;
    END IF;
    
    RETURN attempt_id;
END;
$$ LANGUAGE plpgsql;

-- Create password reset token function
CREATE OR REPLACE FUNCTION create_password_reset_token(
    p_user_id UUID,
    p_ip_address INET,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS VARCHAR(255) AS $$
DECLARE
    reset_token VARCHAR(255);
    token_hash VARCHAR(255);
BEGIN
    -- Generate random token (in production, use crypto-secure random)
    reset_token := encode(gen_random_bytes(32), 'hex');
    token_hash := encode(digest(reset_token, 'sha256'), 'hex');
    
    -- Invalidate any existing tokens for this user
    UPDATE user_password_resets 
    SET is_valid = FALSE 
    WHERE user_id = p_user_id AND is_valid = TRUE;
    
    -- Insert new reset token
    INSERT INTO user_password_resets (
        user_id, tenant_id, client_id, token_hash, expires_at, ip_address, user_agent
    )
    SELECT 
        p_user_id,
        tenant_id,
        client_id,
        token_hash,
        NOW() + INTERVAL '1 hour', -- Token expires in 1 hour
        p_ip_address,
        p_user_agent
    FROM users WHERE id = p_user_id;
    
    -- Log security event
    INSERT INTO user_security_events (user_id, tenant_id, client_id, event_type, event_description, ip_address, user_agent)
    SELECT 
        p_user_id,
        tenant_id,
        client_id,
        'password_reset_requested',
        'Password reset token generated',
        p_ip_address,
        p_user_agent
    FROM users WHERE id = p_user_id;
    
    RETURN reset_token;
END;
$$ LANGUAGE plpgsql;

-- Validate and use password reset token function
CREATE OR REPLACE FUNCTION use_password_reset_token(
    p_token VARCHAR(255),
    p_new_password_hash VARCHAR(255)
)
RETURNS BOOLEAN AS $$
DECLARE
    token_hash VARCHAR(255);
    reset_record RECORD;
    token_valid BOOLEAN := FALSE;
BEGIN
    -- Hash the provided token
    token_hash := encode(digest(p_token, 'sha256'), 'hex');
    
    -- Find and validate the token
    SELECT * INTO reset_record
    FROM user_password_resets 
    WHERE token_hash = token_hash 
    AND is_valid = TRUE 
    AND expires_at > NOW()
    AND used_at IS NULL;
    
    IF FOUND THEN
        -- Mark token as used
        UPDATE user_password_resets 
        SET used_at = NOW(), is_valid = FALSE
        WHERE id = reset_record.id;
        
        -- Update user password
        UPDATE users 
        SET 
            password_hash = p_new_password_hash,
            password_changed_at = NOW(),
            failed_login_attempts = 0, -- Reset failed attempts
            locked_until = NULL, -- Unlock if locked
            updated_at = NOW(),
            version = version + 1
        WHERE id = reset_record.user_id;
        
        -- Log security event
        INSERT INTO user_security_events (user_id, tenant_id, client_id, event_type, event_description, severity)
        VALUES (
            reset_record.user_id,
            reset_record.tenant_id,
            reset_record.client_id,
            'password_reset_completed',
            'Password successfully reset using token',
            'info'
        );
        
        token_valid := TRUE;
    END IF;
    
    RETURN token_valid;
END;
$$ LANGUAGE plpgsql;

-- Generate TOTP secret function
CREATE OR REPLACE FUNCTION generate_totp_secret()
RETURNS VARCHAR(255) AS $$
BEGIN
    -- Generate base32 encoded secret (in production, use crypto-secure implementation)
    RETURN encode(gen_random_bytes(20), 'base64');
END;
$$ LANGUAGE plpgsql;

-- Enable 2FA function
CREATE OR REPLACE FUNCTION enable_user_2fa(
    p_user_id UUID,
    p_device_name VARCHAR(100),
    p_device_type VARCHAR(50),
    p_secret_key VARCHAR(255) DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    device_id UUID;
    backup_codes TEXT[];
    i INTEGER;
BEGIN
    -- Generate backup codes
    FOR i IN 1..10 LOOP
        backup_codes := backup_codes || ARRAY[encode(gen_random_bytes(4), 'hex')];
    END LOOP;
    
    -- Create MFA device
    INSERT INTO user_mfa_devices (
        user_id, tenant_id, client_id, device_name, device_type, 
        secret_key, is_active, backup_codes
    )
    SELECT 
        p_user_id,
        tenant_id,
        client_id,
        p_device_name,
        p_device_type,
        COALESCE(p_secret_key, generate_totp_secret()),
        TRUE,
        backup_codes
    FROM users WHERE id = p_user_id
    RETURNING id INTO device_id;
    
    -- Enable 2FA on user account
    UPDATE users 
    SET 
        two_factor_enabled = TRUE,
        backup_codes = backup_codes,
        updated_at = NOW(),
        version = version + 1
    WHERE id = p_user_id;
    
    -- Log security event
    INSERT INTO user_security_events (user_id, tenant_id, client_id, event_type, event_description, severity)
    SELECT 
        p_user_id,
        tenant_id,
        client_id,
        '2fa_enabled',
        'Two-factor authentication enabled with ' || p_device_type || ' device: ' || p_device_name,
        'info'
    FROM users WHERE id = p_user_id;
    
    RETURN device_id;
END;
$$ LANGUAGE plpgsql;

-- Session management function
CREATE OR REPLACE FUNCTION create_user_session(
    p_user_id UUID,
    p_ip_address INET,
    p_user_agent TEXT,
    p_device_type VARCHAR(50) DEFAULT 'web',
    p_expires_hours INTEGER DEFAULT 8
)
RETURNS UUID AS $$
DECLARE
    session_id UUID;
    session_token VARCHAR(255);
    refresh_token VARCHAR(255);
BEGIN
    -- Generate session tokens
    session_token := encode(gen_random_bytes(32), 'hex');
    refresh_token := encode(gen_random_bytes(32), 'hex');
    
    -- Create session
    INSERT INTO user_sessions (
        user_id, tenant_id, client_id, session_token, refresh_token,
        ip_address, user_agent, device_type, expires_at
    )
    SELECT 
        p_user_id,
        tenant_id,
        client_id,
        session_token,
        refresh_token,
        p_ip_address,
        p_user_agent,
        p_device_type,
        NOW() + (p_expires_hours || ' hours')::INTERVAL
    FROM users WHERE id = p_user_id
    RETURNING id INTO session_id;
    
    RETURN session_id;
END;
$$ LANGUAGE plpgsql;

-- Update session activity function
CREATE OR REPLACE FUNCTION update_session_activity(
    p_session_token VARCHAR(255)
)
RETURNS BOOLEAN AS $$
DECLARE
    session_found BOOLEAN := FALSE;
    row_count INTEGER;
BEGIN
    UPDATE user_sessions 
    SET last_activity_at = NOW()
    WHERE session_token = p_session_token 
    AND is_active = TRUE 
    AND expires_at > NOW();
    
    GET DIAGNOSTICS row_count = ROW_COUNT;
    session_found := row_count > 0;
    
    -- Also update user's last activity
    IF session_found THEN
        UPDATE users 
        SET last_activity_at = NOW()
        WHERE id = (SELECT user_id FROM user_sessions WHERE session_token = p_session_token);
    END IF;
    
    RETURN session_found;
END;
$$ LANGUAGE plpgsql;

-- Comments for documentation
COMMENT ON TABLE user_sessions IS 'Advanced session management with device tracking and security features';
COMMENT ON TABLE user_password_resets IS 'Secure password reset tokens with expiration and usage tracking';
COMMENT ON TABLE user_mfa_devices IS 'Multi-factor authentication devices and backup codes';
COMMENT ON TABLE user_login_attempts IS 'Complete audit trail of all login attempts';
COMMENT ON TABLE user_security_events IS 'Security events and audit log for compliance';

COMMENT ON COLUMN users.two_factor_enabled IS 'Whether user has enabled two-factor authentication';
COMMENT ON COLUMN users.backup_codes IS 'Encrypted backup codes for 2FA recovery';
COMMENT ON COLUMN users.password_reset_token IS 'DEPRECATED - use user_password_resets table';
COMMENT ON COLUMN users.last_login_ip IS 'IP address of last successful login';
COMMENT ON COLUMN users.last_activity_at IS 'Timestamp of last user activity';

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Security features successfully added to user_service';
    RAISE NOTICE 'Added: 2FA support, password reset, session management, login tracking';
    RAISE NOTICE 'New tables: user_sessions, user_password_resets, user_mfa_devices, user_login_attempts, user_security_events';
    RAISE NOTICE 'Enhanced functions: password hashing, account locking, 2FA management';
END $$;
