# Go Factory Platform Database Seeder

A comprehensive data seeding tool for the Go Factory Platform, designed to populate the database with realistic test data for development, testing, and demonstration purposes.

## Features

### 🌱 Smart Seeding
- **Dependency Resolution**: Automatically resolves and respects foreign key dependencies between tables
- **Multi-Tenant Support**: Configurable seeding for single or multiple tenants
- **Multi-Client Support**: Handles client-scoped data within tenants
- **Idempotent Operations**: Safe to run multiple times without duplicating data

### 🔧 Flexible Configuration
- **Service-Specific Seeding**: Choose which services to seed
- **Environment-Aware**: Different seeding strategies per environment
- **Dry-Run Mode**: Preview operations without making changes
- **Verbose Logging**: Detailed output for debugging

### 📊 Data Management
- **Structured JSON Data**: Easy-to-maintain seed data files
- **Realistic Test Data**: Comprehensive product catalogs, users, warehouses
- **Audit Trail**: Track all seeding operations with timestamps
- **Clear Operations**: Remove seeded data safely

## Usage

### Basic Commands

```bash
# Seed the database with default settings
go run ./cmd/seeder -action=seed

# Seed specific services only
go run ./cmd/seeder -action=seed -services=tenant,auth,user

# Preview what would be seeded (dry run)
go run ./cmd/seeder -action=seed -dry-run

# Check current seeding status
go run ./cmd/seeder -action=status

# Clear all seeded data
go run ./cmd/seeder -action=clear

# Reset database (clear + seed)
go run ./cmd/seeder -action=reset
```

### Advanced Configuration

```bash
# Multi-tenant seeding
go run ./cmd/seeder -action=seed -tenant-mode=multi -client-mode=multi

# Specific environment
go run ./cmd/seeder -action=seed -env=staging

# Custom database URL
go run ./cmd/seeder -action=seed -db-url="postgresql://user:pass@host:port/db"

# Verbose output
go run ./cmd/seeder -action=seed -verbose
```

### Command-Line Options

| Option | Default | Description |
|--------|---------|-------------|
| `-action` | `seed` | Action to perform: `seed`, `clear`, `reset`, `status` |
| `-db-url` | `$DATABASE_URL` | Database connection string |
| `-seed-path` | `database/seeds` | Path to seed data files |
| `-env` | `development` | Environment: `development`, `staging`, `production` |
| `-tenant-mode` | `single` | Tenant mode: `single`, `multi`, `all` |
| `-client-mode` | `single` | Client mode: `single`, `multi`, `all` |
| `-services` | `all` | Comma-separated service list or `all` |
| `-dry-run` | `false` | Preview without executing |
| `-verbose` | `false` | Enable verbose logging |
| `-help` | `false` | Show help message |

## Seed Data Structure

### Directory Layout

```
database/seeds/
├── tenant/
│   ├── tenants.json
│   └── clients.json
├── auth/
│   └── roles.json
├── user/
│   ├── users.json
│   └── user_roles.json
└──
```

### JSON File Format

Each seed file follows this structure:

```json
{
  "service": "service_name",
  "table": "table_name", 
  "description": "Human-readable description",
  "dependencies": ["other.table", "another.table"],
  "data": [
    {
      "id": "uuid-here",
      "field1": "value1",
      "field2": {
        "nested": "object"
      }
    }
  ]
}
```

### Key Features

- **Dependencies**: Automatic ordering based on foreign key relationships
- **Multi-Tenant Data**: Automatic tenant_id and client_id population
- **UUID Generation**: Automatic ID generation for multi-tenant variations
- **JSON Support**: Rich data types including nested objects and arrays

## Seeded Services

### Core Services
- **tenant**: Tenants and clients for multi-tenancy
- **auth**: Roles and permissions for RBAC
- **user**: Users and role assignments

### Business Services  


### Sample Data Overview

#### Tenants
- **System Tenant**: Default system operations
- **ACME Corporation**: Enterprise tenant with multiple clients
- **Globex Industries**: Standard tenant

#### Users
- **System Admin**: Full system access
- **Development Managers**: Operational management
- **Software Developer**: Day-to-day operations
- **Viewers**: Read-only access


## Multi-Tenant Configuration

### Single Tenant Mode (Default)
```bash
go run ./cmd/seeder -tenant-mode=single -client-mode=single
```
- Uses system tenant and default client
- Fastest seeding option
- Good for development

### Multi-Tenant Mode
```bash
go run ./cmd/seeder -tenant-mode=multi -client-mode=multi
```
- Creates data for all tenants and clients
- Automatically generates unique IDs
- Realistic multi-tenant testing

## Troubleshooting

### Common Issues

1. **Database Connection Errors**
   ```bash
   # Check your DATABASE_URL
   echo $DATABASE_URL
   
   # Test connection manually
   psql $DATABASE_URL -c "SELECT version();"
   ```

2. **Foreign Key Errors**
   - Ensure migrations are up to date
   - Check dependency ordering in JSON files
   - Verify referenced IDs exist

3. **Duplicate Data Errors**
   - Run with `-action=clear` first
   - Check for existing seed_log entries
   - Use `-action=reset` for clean start

### Debugging

```bash
# Verbose output for detailed logging
go run ./cmd/seeder -action=seed -verbose

# Dry run to preview operations
go run ./cmd/seeder -action=seed -dry-run -verbose

# Check current status
go run ./cmd/seeder -action=status
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | System default |

## Development

### Adding New Seed Data

1. Create service directory: `database/seeds/new_service/`
2. Add JSON files with proper dependencies
3. Test with dry run: `go run ./cmd/seeder -services=new_service -dry-run`
4. Run seeding: `go run ./cmd/seeder -services=new_service`

### JSON Schema Validation

Ensure your JSON files follow the required structure:
- `service`: Service name (matches directory)
- `table`: Target table name
- `description`: Human-readable description
- `dependencies`: Array of "service.table" dependencies
- `data`: Array of record objects

### Best Practices

1. **Use Meaningful IDs**: UUIDs should be descriptive when possible
2. **Maintain Dependencies**: Always list table dependencies
3. **Test Incrementally**: Add new services one at a time
4. **Use Realistic Data**: Make test data representative of real use cases
5. **Document Changes**: Update this README when adding new services

## Integration

### CI/CD Usage

```bash
# In your CI pipeline
go run ./cmd/seeder -action=reset -env=staging -services=core
```

### Docker Usage

```bash
# In docker-compose.yml
services:
  seeder:
    build: .
    command: go run ./cmd/seeder -action=seed
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@db:5432/go_factory_platform
    depends_on:
      - db
```

---

For more information about the Go Factory Platform project, see the main [README.md](../../README.md).
