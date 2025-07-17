-- Migration: default_role_permissions
-- Service: auth
-- Description: Assign default permissions to system roles

-- Assign permissions to super_admin role (gets all permissions)
INSERT INTO auth_role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM auth_roles r
CROSS JOIN auth_permissions p
WHERE r.name = 'super_admin' AND r.is_system_role = TRUE
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Assign permissions to admin role (gets most permissions except dangerous ones)
INSERT INTO auth_role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM auth_roles r
CROSS JOIN auth_permissions p
WHERE r.name = 'admin' AND r.is_system_role = TRUE
AND p.is_dangerous = FALSE
AND p.name NOT LIKE 'system.admin.%'
AND p.name NOT LIKE '%.delete'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Assign permissions to template_manager role
INSERT INTO auth_role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM auth_roles r
CROSS JOIN auth_permissions p
WHERE r.name = 'template_manager' AND r.is_system_role = TRUE
AND (
    p.name LIKE 'template.%' OR
    p.name LIKE 'generator.%' OR
    p.name LIKE 'platform.%' OR
    p.name LIKE 'reporting.generation.%' OR
    p.name LIKE 'reporting.usage.%' OR
    p.name LIKE 'reporting.analytics.%'
)
AND p.name NOT LIKE '%.delete'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Assign permissions to developer role
INSERT INTO auth_role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM auth_roles r
CROSS JOIN auth_permissions p
WHERE r.name = 'developer' AND r.is_system_role = TRUE
AND (
    p.name LIKE 'template.templates.read' OR
    p.name LIKE 'template.templates.fork' OR
    p.name LIKE 'template.categories.read' OR
    p.name LIKE 'template.versions.read' OR
    p.name LIKE 'generator.projects.%' OR
    p.name LIKE 'generator.generate.execute' OR
    p.name LIKE 'generator.builds.%' OR
    p.name LIKE 'platform.apis.read' OR
    p.name LIKE 'reporting.generation.read'
)
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Assign basic permissions to user role
INSERT INTO auth_role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM auth_roles r
CROSS JOIN auth_permissions p
WHERE r.name = 'user' AND r.is_system_role = TRUE
AND p.action IN ('read', 'list')
AND p.name NOT LIKE 'auth.%'
AND p.name NOT LIKE 'system.%'
AND p.name NOT LIKE 'reporting.audit.%'
AND p.name NOT LIKE 'tenant.%'
AND (
    p.name LIKE 'template.templates.read' OR
    p.name LIKE 'template.categories.read' OR
    p.name LIKE 'generator.projects.read' OR
    p.name LIKE 'generator.builds.read' OR
    p.name LIKE 'platform.apis.read'
)
ON CONFLICT (role_id, permission_id) DO NOTHING;
