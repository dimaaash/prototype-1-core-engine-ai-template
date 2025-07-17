-- Rollback: Core database setup
-- WARNING: This rollback should only be run when completely destroying the database
-- as it will break all services that depend on core types and functions

-- This rollback is designed to be safe and only remove objects that can be safely removed
-- without breaking other services. Most core objects should remain for system stability.

-- Drop system configuration (safe to remove)
DROP TABLE IF EXISTS system_configuration;

-- Drop audit log (safe to remove)
DROP FUNCTION IF EXISTS log_audit_entry(UUID, UUID, UUID, VARCHAR, VARCHAR, UUID, VARCHAR, JSONB, JSONB, JSONB, INET, TEXT);
DROP TABLE IF EXISTS system_audit_log;

-- NOTE: We do NOT drop validation functions or core types in a normal rollback
-- because many other services depend on them. To completely remove core objects,
-- you must first roll back ALL other services that use them.
-- 
-- The following objects are intentionally left in place for system stability:
-- - validate_postal_code, validate_phone, validate_email functions
-- - temperature_unit, dimension_unit, weight_unit, currency_code, status_enum types
-- - update_updated_at_column function
-- - PostgreSQL extensions
--
-- If you need to completely remove all core objects, run this migration
-- only after rolling back ALL other services first.

DO $$
BEGIN
    RAISE NOTICE 'Core rollback completed. Note: Core types and validation functions were preserved for system stability.';
END
$$;

-- Uncomment the following section ONLY if you have rolled back ALL other services
-- and want to completely destroy the core database objects:

/*
-- Drop constraints that depend on validation functions first
DO $$
BEGIN
    -- This would need to be updated based on remaining constraints in the database
    RAISE NOTICE 'Dropping validation constraints...';
END
$$;

-- Drop helper functions
DROP FUNCTION IF EXISTS generate_sequential_code(TEXT, TEXT, INTEGER);
DROP FUNCTION IF EXISTS validate_postal_code(TEXT, TEXT);
DROP FUNCTION IF EXISTS validate_phone(TEXT);
DROP FUNCTION IF EXISTS validate_email(TEXT);

-- Drop common types
DROP TYPE IF EXISTS temperature_unit CASCADE;
DROP TYPE IF EXISTS dimension_unit CASCADE;
DROP TYPE IF EXISTS weight_unit CASCADE;
DROP TYPE IF EXISTS currency_code CASCADE;
DROP TYPE IF EXISTS status_enum CASCADE;
DROP TYPE IF EXISTS audit_fields CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS update_updated_at_column();

-- Drop extensions (be very careful - other databases might use these)
-- DROP EXTENSION IF EXISTS "btree_gin";
-- DROP EXTENSION IF EXISTS "pg_trgm";
-- DROP EXTENSION IF EXISTS "uuid-ossp";
*/

