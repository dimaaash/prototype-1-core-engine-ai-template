-- Migration: rbac_functions (down)
-- Service: auth
-- Description: Remove RBAC functions

-- Drop the constraint first
ALTER TABLE auth_roles DROP CONSTRAINT IF EXISTS auth_roles_no_circular_hierarchy;

-- Drop all RBAC functions
DROP FUNCTION IF EXISTS check_role_hierarchy_circular(UUID, UUID);
DROP FUNCTION IF EXISTS assign_permission_to_role(UUID, UUID, UUID, JSONB);
DROP FUNCTION IF EXISTS remove_permission_from_role(UUID, UUID);
DROP FUNCTION IF EXISTS assign_role_to_user(UUID, UUID, UUID, UUID, UUID, TIMESTAMP WITH TIME ZONE);
DROP FUNCTION IF EXISTS remove_role_from_user(UUID, UUID, UUID, UUID);
DROP FUNCTION IF EXISTS grant_permission_to_user(UUID, UUID, UUID, UUID, UUID, TIMESTAMP WITH TIME ZONE, TEXT);
DROP FUNCTION IF EXISTS revoke_permission_from_user(UUID, UUID, UUID, UUID);
DROP FUNCTION IF EXISTS get_user_permissions(UUID, UUID, UUID);
DROP FUNCTION IF EXISTS user_has_permission(UUID, VARCHAR(100), UUID, UUID);
DROP FUNCTION IF EXISTS get_user_roles_with_hierarchy(UUID, UUID, UUID);
DROP FUNCTION IF EXISTS cleanup_expired_assignments();
DROP FUNCTION IF EXISTS bulk_assign_permissions_to_role(VARCHAR(100), UUID, TEXT[], UUID);
DROP FUNCTION IF EXISTS schedule_auth_cleanup();
