-- Migration: rbac_functions
-- Service: auth
-- Description: Create advanced RBAC functions and business logic

-- Function to check for circular role hierarchy
CREATE OR REPLACE FUNCTION check_role_hierarchy_circular(role_id UUID, parent_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    current_parent UUID;
    max_depth INTEGER := 10;
    depth INTEGER := 0;
BEGIN
    current_parent := parent_id;
    
    WHILE current_parent IS NOT NULL AND depth < max_depth LOOP
        IF current_parent = role_id THEN
            RETURN TRUE; -- Circular reference found
        END IF;
        
        SELECT parent_role_id INTO current_parent 
        FROM auth_roles 
        WHERE id = current_parent;
        
        depth := depth + 1;
    END LOOP;
    
    RETURN FALSE; -- No circular reference
END;
$$ LANGUAGE plpgsql;

-- Add constraint to prevent circular hierarchy
ALTER TABLE auth_roles 
ADD CONSTRAINT auth_roles_no_circular_hierarchy 
CHECK (NOT check_role_hierarchy_circular(id, parent_role_id));

-- Function to assign permission to role
CREATE OR REPLACE FUNCTION assign_permission_to_role(
    p_role_id UUID,
    p_permission_id UUID,
    p_granted_by UUID DEFAULT NULL,
    p_conditions JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    assignment_id UUID;
BEGIN
    INSERT INTO auth_role_permissions (role_id, permission_id, granted_by, conditions)
    VALUES (p_role_id, p_permission_id, p_granted_by, p_conditions)
    ON CONFLICT (role_id, permission_id) DO UPDATE SET
        granted_by = EXCLUDED.granted_by,
        granted_at = NOW(),
        conditions = EXCLUDED.conditions
    RETURNING id INTO assignment_id;
    
    RETURN assignment_id;
END;
$$ LANGUAGE plpgsql;

-- Function to remove permission from role
CREATE OR REPLACE FUNCTION remove_permission_from_role(
    p_role_id UUID,
    p_permission_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM auth_role_permissions 
    WHERE role_id = p_role_id AND permission_id = p_permission_id;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count > 0;
END;
$$ LANGUAGE plpgsql;

-- Function to assign role to user
CREATE OR REPLACE FUNCTION assign_role_to_user(
    p_user_id UUID,
    p_role_id UUID,
    p_tenant_id UUID,
    p_client_id UUID DEFAULT NULL,
    p_assigned_by UUID DEFAULT NULL,
    p_expires_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    assignment_id UUID;
BEGIN
    -- Validate that user belongs to the tenant/client
    IF NOT EXISTS (
        SELECT 1 FROM users 
        WHERE id = p_user_id 
        AND tenant_id = p_tenant_id
    ) THEN
        RAISE EXCEPTION 'User does not belong to the specified tenant';
    END IF;
    
    -- Validate that role belongs to the tenant/client
    IF NOT EXISTS (
        SELECT 1 FROM auth_roles 
        WHERE id = p_role_id 
        AND tenant_id = p_tenant_id 
        AND (p_client_id IS NULL OR client_id = p_client_id OR client_id IS NULL)
    ) THEN
        RAISE EXCEPTION 'Role does not belong to the specified tenant/client';
    END IF;
    
    INSERT INTO auth_user_roles (user_id, role_id, tenant_id, client_id, assigned_by, expires_at)
    VALUES (p_user_id, p_role_id, p_tenant_id, p_client_id, p_assigned_by, p_expires_at)
    ON CONFLICT (user_id, role_id, tenant_id, client_id) DO UPDATE SET
        assigned_by = EXCLUDED.assigned_by,
        assigned_at = NOW(),
        expires_at = EXCLUDED.expires_at,
        is_active = TRUE,
        updated_at = NOW(),
        version = auth_user_roles.version + 1
    RETURNING id INTO assignment_id;
    
    RETURN assignment_id;
END;
$$ LANGUAGE plpgsql;

-- Function to remove role from user
CREATE OR REPLACE FUNCTION remove_role_from_user(
    p_user_id UUID,
    p_role_id UUID,
    p_tenant_id UUID,
    p_client_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE auth_user_roles 
    SET is_active = FALSE,
        updated_at = NOW(),
        version = version + 1
    WHERE user_id = p_user_id 
    AND role_id = p_role_id 
    AND tenant_id = p_tenant_id 
    AND (p_client_id IS NULL OR client_id = p_client_id);
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count > 0;
END;
$$ LANGUAGE plpgsql;

-- Function to grant permission directly to user
CREATE OR REPLACE FUNCTION grant_permission_to_user(
    p_user_id UUID,
    p_permission_id UUID,
    p_tenant_id UUID,
    p_client_id UUID DEFAULT NULL,
    p_granted_by UUID DEFAULT NULL,
    p_expires_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_reason TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    assignment_id UUID;
BEGIN
    -- Validate that user belongs to the tenant/client
    IF NOT EXISTS (
        SELECT 1 FROM users 
        WHERE id = p_user_id 
        AND tenant_id = p_tenant_id
    ) THEN
        RAISE EXCEPTION 'User does not belong to the specified tenant';
    END IF;
    
    INSERT INTO auth_user_permissions (
        user_id, permission_id, tenant_id, client_id, 
        granted_by, expires_at, reason
    )
    VALUES (
        p_user_id, p_permission_id, p_tenant_id, p_client_id,
        p_granted_by, p_expires_at, p_reason
    )
    ON CONFLICT (user_id, permission_id, tenant_id, client_id) DO UPDATE SET
        granted_by = EXCLUDED.granted_by,
        granted_at = NOW(),
        expires_at = EXCLUDED.expires_at,
        reason = EXCLUDED.reason,
        is_active = TRUE,
        updated_at = NOW(),
        version = auth_user_permissions.version + 1
    RETURNING id INTO assignment_id;
    
    RETURN assignment_id;
END;
$$ LANGUAGE plpgsql;

-- Function to revoke permission from user
CREATE OR REPLACE FUNCTION revoke_permission_from_user(
    p_user_id UUID,
    p_permission_id UUID,
    p_tenant_id UUID,
    p_client_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE auth_user_permissions 
    SET is_active = FALSE,
        updated_at = NOW(),
        version = version + 1
    WHERE user_id = p_user_id 
    AND permission_id = p_permission_id 
    AND tenant_id = p_tenant_id 
    AND (p_client_id IS NULL OR client_id = p_client_id);
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count > 0;
END;
$$ LANGUAGE plpgsql;

-- Function to get user effective permissions
CREATE OR REPLACE FUNCTION get_user_permissions(
    p_user_id UUID,
    p_tenant_id UUID,
    p_client_id UUID DEFAULT NULL
)
RETURNS TABLE(permission_name VARCHAR(100)) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT p.name
    FROM auth_permissions p
    JOIN auth_role_permissions rp ON p.id = rp.permission_id
    JOIN auth_roles r ON rp.role_id = r.id
    JOIN auth_user_roles ur ON r.id = ur.role_id
    WHERE ur.user_id = p_user_id
    AND ur.tenant_id = p_tenant_id
    AND (p_client_id IS NULL OR ur.client_id = p_client_id OR ur.client_id IS NULL)
    AND ur.is_active = TRUE
    AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
    AND r.is_active = TRUE
    
    UNION
    
    SELECT DISTINCT p.name
    FROM auth_permissions p
    JOIN auth_user_permissions up ON p.id = up.permission_id
    WHERE up.user_id = p_user_id
    AND up.tenant_id = p_tenant_id
    AND (p_client_id IS NULL OR up.client_id = p_client_id)
    AND up.is_active = TRUE
    AND (up.expires_at IS NULL OR up.expires_at > NOW());
END;
$$ LANGUAGE plpgsql;

-- Function to check if user has specific permission
CREATE OR REPLACE FUNCTION user_has_permission(
    p_user_id UUID,
    p_permission_name VARCHAR(100),
    p_tenant_id UUID,
    p_client_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM get_user_permissions(p_user_id, p_tenant_id, p_client_id) 
        WHERE permission_name = p_permission_name
    );
END;
$$ LANGUAGE plpgsql;

-- Function to get user roles with hierarchy
CREATE OR REPLACE FUNCTION get_user_roles_with_hierarchy(
    p_user_id UUID,
    p_tenant_id UUID,
    p_client_id UUID DEFAULT NULL
)
RETURNS TABLE(
    role_id UUID,
    role_name VARCHAR(100),
    role_level INTEGER,
    is_inherited BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    WITH RECURSIVE role_hierarchy AS (
        -- Direct roles
        SELECT 
            r.id,
            r.name,
            r.role_level,
            FALSE as is_inherited
        FROM auth_roles r
        JOIN auth_user_roles ur ON r.id = ur.role_id
        WHERE ur.user_id = p_user_id
        AND ur.tenant_id = p_tenant_id
        AND (p_client_id IS NULL OR ur.client_id = p_client_id)
        AND ur.is_active = TRUE
        AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
        
        UNION ALL
        
        -- Inherited roles through hierarchy
        SELECT 
            parent.id,
            parent.name,
            parent.role_level,
            TRUE as is_inherited
        FROM auth_roles parent
        JOIN role_hierarchy child ON parent.id = child.role_id
        WHERE parent.inherit_permissions = TRUE
        AND parent.is_active = TRUE
    )
    SELECT DISTINCT 
        rh.id,
        rh.name,
        rh.role_level,
        rh.is_inherited
    FROM role_hierarchy rh
    ORDER BY rh.role_level, rh.name;
END;
$$ LANGUAGE plpgsql;

-- Function to cleanup expired assignments
CREATE OR REPLACE FUNCTION cleanup_expired_assignments()
RETURNS INTEGER AS $$
DECLARE
    expired_count INTEGER;
    permission_expired_count INTEGER;
BEGIN
    -- Deactivate expired role assignments
    UPDATE auth_user_roles 
    SET is_active = FALSE,
        updated_at = NOW(),
        version = version + 1
    WHERE expires_at < NOW() 
    AND is_active = TRUE;
    
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    
    -- Deactivate expired permission assignments
    UPDATE auth_user_permissions 
    SET is_active = FALSE,
        updated_at = NOW(),
        version = version + 1
    WHERE expires_at < NOW() 
    AND is_active = TRUE;
    
    GET DIAGNOSTICS permission_expired_count = ROW_COUNT;
    
    RETURN expired_count + permission_expired_count;
END;
$$ LANGUAGE plpgsql;

-- Function to bulk assign permissions to role (for initial setup)
CREATE OR REPLACE FUNCTION bulk_assign_permissions_to_role(
    p_role_name VARCHAR(100),
    p_tenant_id UUID,
    p_permission_patterns TEXT[],
    p_granted_by UUID DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    role_record RECORD;
    permission_record RECORD;
    assigned_count INTEGER := 0;
BEGIN
    -- Get the role
    SELECT id INTO role_record FROM auth_roles 
    WHERE name = p_role_name AND tenant_id = p_tenant_id;
    
    IF role_record.id IS NULL THEN
        RAISE EXCEPTION 'Role % not found for tenant %', p_role_name, p_tenant_id;
    END IF;
    
    -- Assign permissions based on patterns
    FOR i IN 1..array_length(p_permission_patterns, 1) LOOP
        FOR permission_record IN 
            SELECT id FROM auth_permissions 
            WHERE name LIKE p_permission_patterns[i]
        LOOP
            PERFORM assign_permission_to_role(
                role_record.id, 
                permission_record.id, 
                p_granted_by
            );
            assigned_count := assigned_count + 1;
        END LOOP;
    END LOOP;
    
    RETURN assigned_count;
END;
$$ LANGUAGE plpgsql;

-- Create a cleanup job function (can be called by cron or application)
CREATE OR REPLACE FUNCTION schedule_auth_cleanup()
RETURNS INTEGER AS $$
BEGIN
    RETURN cleanup_expired_assignments();
END;
$$ LANGUAGE plpgsql;
