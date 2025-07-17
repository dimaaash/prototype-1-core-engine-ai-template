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
```

## Database Seeding

The seeder supports two modes: **JSON Mode** (priority) and **Faker Mode** (fallback).

### JSON Mode - Structured Data Seeding

When JSON seed files exist, the seeder uses them for precise, real-world data:

```bash
# Seed specific service from JSON files
./bin/seeder -services=template-service -verbose

# Seed all services (JSON files take priority)
./bin/seeder -verbose
```

#### JSON File Structure

JSON seed files are located in `database/seeds/{directory}/`:

```
database/seeds/
├── template/              # template-service seeds
│   └── templates.json
├── auth/                  # auth-service seeds  
│   └── roles.json
├── tenant/                # tenant-service seeds
│   └── tenants.json
└── user/                  # user-service seeds
    └── users.json
```

**Service-to-Directory Mapping:**
- `template-service` → `database/seeds/template/`
- `auth-service` → `database/seeds/auth/`  
- `tenant-service` → `database/seeds/tenant/`
- `user-service` → `database/seeds/user/`

The seeder automatically maps service names to their corresponding seed directories.

#### JSON File Format

```json
{
  "service": "template",
  "table": "templates", 
  "description": "Go Factory Platform templates",
  "dependencies": ["template.template_categories", "tenant.tenants"],
  "data": [
    {
      "id": "a1234567-89ab-4def-8123-456789abcdef",
      "tenant_id": "daeb55bf-fe63-4239-8ab2-85528c574619",
      "name": "Go REST API Handler",
      "content": "package handlers...",
      "variables": {
        "HandlerName": {
          "type": "string",
          "description": "Name of the handler struct",
          "required": true,
          "example": "User"
        }
      },
      "dependencies": ["github.com/gin-gonic/gin"],
      "tags": ["go", "gin", "rest", "api"]
    }
  ]
}
```

#### JSONB Field Support

The seeder automatically handles PostgreSQL JSONB columns:
- **Objects**: `variables`, `configuration` → Converted to JSON strings
- **Arrays**: `dependencies`, `tags` → Converted to JSON arrays
- **Mixed Data**: Complex nested structures supported

#### Dynamic Dependency Resolution

JSON files support placeholder values for foreign keys that are resolved at runtime:

```json
{
  "data": [
    {
      "id": "template-001",
      "tenant_id": "__SYSTEM_TENANT__",
      "client_id": "__DEFAULT_CLIENT__",
      "name": "Dynamic Template"
    }
  ]
}
```

**Available Placeholders:**
- `__SYSTEM_TENANT__` - Looks for "System Tenant" by name
- `__FIRST_TENANT__` / `__DEFAULT_TENANT__` - First available tenant
- `__DEFAULT_CLIENT__` - Looks for "Default Client" by name  
- `__FIRST_CLIENT__` - First available client
- `__RANDOM_TENANT__` / `__RANDOM_CLIENT__` - Pseudo-random selection

**Benefits:**
- ✅ **Portable JSON files** across different environments
- ✅ **No manual editing** of UUIDs required
- ✅ **Automatic fallbacks** when specific names don't exist
- ✅ **Clear logging** shows ID resolution in verbose mode

See `database/DYNAMIC_PLACEHOLDERS.md` for complete reference.

### Faker Mode - Generated Test Data

When no JSON files exist, the seeder generates realistic fake data:

```bash
# Generate fake data for services without JSON files
./bin/seeder -services=user-service -verbose
```

#### Generated Data Types

- **Tenants**: Company names, domains, settings
- **Users**: Names, emails, profiles, preferences  
- **Clients**: Organization structures
- **Roles**: Permission sets (when role tables exist)

### Seeding Workflow

1. **JSON Priority**: Check for `database/seeds/{service}/*.json` files
2. **Dependency Resolution**: Process files in dependency order
3. **Data Validation**: Validate foreign keys and constraints
4. **Fallback Mode**: Generate fake data if no JSON files found
5. **Error Handling**: Clear error messages and transaction rollback

### Service-Specific Examples

#### Template Service (JSON Mode)
```bash
# Seeds from database/seeds/template/templates.json with dynamic IDs
./bin/seeder -services=template-service -verbose

# Output:
# 📂 JSON MODE - Seeding from JSON files for service: template-service
# 🔍 Resolving dynamic dependencies...
#   📋 tenant_id: __SYSTEM_TENANT__ → daeb55bf-fe63-4239-8ab2-85528c574619
#   🏢 client_id: __DEFAULT_CLIENT__ → c07e25f7-8f76-470a-a1c5-f286f2309c75
# ✅ Inserted 3 records
```

#### User Service (Faker Mode)  
```bash
# Generates fake users, tenants, clients
./bin/seeder -services=user-service -verbose

# Output:
# 🎭 FAKER MODE - Generating realistic test data
# ✅ Successfully generated and seeded 10 fake user
```

### Mixed Environment Support

Both modes can coexist in the same seeding run:

```bash
# Some services use JSON, others use faker mode
./bin/seeder -services=template-service,user-service -verbose
```

### Creating JSON Seed Files

1. **Create Service Directory**: `mkdir -p database/seeds/{service}`
2. **Create JSON File**: Follow the standard format above
3. **Validate UUIDs**: Ensure foreign keys reference existing records
4. **Test Seeding**: Run seeder in verbose mode to verify
5. **Symlink Setup**: Link service directories: `ln -sf template database/seeds/template-service`

### Troubleshooting

Common issues and solutions:

- **Foreign Key Violations**: Check tenant_id/client_id exist in database
- **Invalid JSON Syntax**: Validate JSON with `jq` or online tools
- **UUID Format Errors**: Ensure UUIDs are exactly 36 characters
- **JSONB Field Issues**: Verify complex objects are properly formatted

### Best Practices

1. **Use JSON for Production Data**: Templates, configurations, reference data
2. **Use Faker for Development**: User accounts, test tenants, bulk data  
3. **Validate Dependencies**: Ensure referenced IDs exist before seeding
4. **Version Control JSON Files**: Track seed data changes in git
5. **Document Data Sources**: Include descriptions in JSON files

# Rollback migrations
./scripts/migrate.sh --action=down --service=tenant
```

## Service Dependencies

Some services depend on others and should be migrated in order:

0. **Core Setup**: core (database extensions, functions, shared types)
1. **Foundation Services**: tenant, auth
2. **Core Services**: user
3. **Building-Block Services**: building-blocks-service
4. **Template Services**: template-service (template management, code generation)
5. **Project-Structure Services**: project-structure-service
6. **Generator Services**: generator-service  
7. **Compiler-Builder Services**: compiler-builder-service
8. **Integration Services**: notification, reporting

When running `--service=all`, migrations are executed in dependency order.

## Microservice Categories

### Core Services (Foundation)
- **tenant_service**: Multi-tenant infrastructure, tenant isolation
- **auth_service**: Authentication, authorization, roles, permissions  
- **user_service**: User management, profiles, preferences

### Go Factory Platform Services
- **template_service**: Template management, versioning, code generation templates
- **building-blocks-service**: Reusable code components and patterns
- **generator-service**: Code generation engine and template processing
- **project-structure-service**: Project scaffolding and structure management
- **compiler-builder-service**: Build system and compilation services

### Integration Services
- **notification_service**: Email, SMS, webhooks, alerts
- **reporting_service**: Analytics, dashboards, KPIs

## Development Guidelines

1. **Always create both UP and DOWN migrations** - Every migration must be reversible
2. **Use transactions** - Wrap complex migrations in transactions for atomicity
3. **Test migrations** - Test both up and down migrations before committing
4. **Follow naming conventions** - Use descriptive names for migrations
5. **Consider dependencies** - Some services depend on tables from other services
6. **Use UUID prefixes** - Migration tool automatically adds UUID prefixes for uniqueness

## Recent Implementations

### Template Service (July 2025)

Successfully implemented comprehensive template management system:

#### Database Schema
- **7 interconnected tables**: templates, template_categories, template_versions, template_usage, template_favorites, template_reviews, template_shares
- **Global/Client-specific support**: Templates can be shared globally or restricted to specific clients
- **Full lifecycle management**: Versioning, usage tracking, reviews, favorites
- **JSONB fields**: variables, configuration, dependencies, tags for flexible metadata

#### Migration Details
- **File**: `database/migrations/template_service/20250717200000_create_template_tables.up.sql`
- **Dependencies**: Requires tenant and client tables
- **Features**: Comprehensive indexing, full-text search, audit trails

#### Seeding Implementation
- **JSON Mode**: Seeds from `database/seeds/template/templates.json`
- **Sample Templates**: Go REST API Handler, Service Interface, Database Model
- **JSONB Support**: Proper handling of complex template metadata
- **Foreign Key Validation**: Uses existing tenant/client IDs

#### Usage Example
```bash
# Run template service migration
./bin/migrator -action=up -service=template_service

# Seed template data
./bin/seeder -services=template-service -verbose

# Verify templates
psql -c "SELECT name, language, framework, is_global FROM templates;"
```
