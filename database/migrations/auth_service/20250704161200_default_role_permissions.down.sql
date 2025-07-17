-- Migration: default_role_permissions (down)
-- Service: auth
-- Description: Remove default role permissions

-- Remove all role-permission assignments for system roles
DELETE FROM auth_role_permissions 
WHERE role_id IN (
    SELECT id FROM auth_roles WHERE is_system_role = TRUE
);
