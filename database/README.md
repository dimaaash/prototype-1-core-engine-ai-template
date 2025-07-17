# Database Migrations

## Structure

Each microservice has its own migration directory under `database/migrations/`:

- `core/` - Core database setup, extensions, and shared functions
- `tenant_service/` - Multi-tenancy management
- `auth_service/` - Authentication & authorization  
- `user_service/` - User management
- `notification_service/` - Notifications & alerts
- `reporting_service/` - Analytics & reporting

## Migration Files

Migration files follow the naming convention:
```
YYYYMMDDHHMMSS_XXXXXXXX_migration_name.up.sql
YYYYMMDDHHMMSS_XXXXXXXX_migration_name.down.sql
```

Where XXXXXXXX is an 8-character UUID prefix for uniqueness.

Example:
```
20240101120000_a1b2c3d4_create_tenants_table.up.sql
20240101120000_a1b2c3d4_create_tenants_table.down.sql
```

## Usage

### Create a new migration
```bash
go run ./cmd/migrator -action=create -service=tenant -name=create_tenants_table
```

### Run migrations
```bash
# Run all migrations for all services
go run ./cmd/migrator -action=up -service=all

# Run migrations for specific service
go run ./cmd/migrator -action=up -service=tenant

# Rollback migrations for specific service
go run ./cmd/migrator -action=down -service=tenant
```

### Using the helper script
```bash
# Create migration
./scripts/migrate.sh --action=create --service=tenant --name=create_tenants_table

# Run migrations
./scripts/migrate.sh --action=up --service=all

# Rollback migrations
./scripts/migrate.sh --action=down --service=tenant
```

## Service Dependencies

Some services depend on others and should be migrated in order:

0. **Core Setup**: core (database extensions, functions, shared types)
1. **Foundation Services**: tenant, auth
2. **Core Services**: user,
3. **Building-Block Services**: 
4. **Template Services**:
5. **Project-Structure Services:
6. **Generator Services:
7. **Compiler-Builder Services:
8. **Orchestrator Services:
9. **AI-Vertex Services:
10. **Integration Services**: platform, notification, reporting

When running `--service=all`, migrations are executed in dependency order.

## Microservice Categories

### Core Services (Foundation)
- **tenant_service**: Multi-tenant infrastructure, tenant isolation
- **auth_service**: Authentication, authorization, roles, permissions
- **user_service**: User management, profiles, preferences

### Integration Services
- **platform_service**: Our GO-factory platform
- **notification_service**: Email, SMS, webhooks, alerts
- **reporting_service**: Analytics, dashboards, KPIs

## Development Guidelines

1. **Always create both UP and DOWN migrations** - Every migration must be reversible
2. **Use transactions** - Wrap complex migrations in transactions for atomicity
3. **Test migrations** - Test both up and down migrations before committing
4. **Follow naming conventions** - Use descriptive names for migrations
5. **Consider dependencies** - Some services depend on tables from other services
6. **Use UUID prefixes** - Migration tool automatically adds UUID prefixes for uniqueness
