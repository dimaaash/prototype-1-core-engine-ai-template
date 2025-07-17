# Dynamic Dependency Resolution - Placeholder Reference

The seeder now supports dynamic resolution of foreign key dependencies using placeholder values. This eliminates the need to manually edit JSON seed files with specific IDs.

## Available Placeholders

### Tenant ID Placeholders

| Placeholder | Description | Behavior |
|-------------|-------------|----------|
| `__SYSTEM_TENANT__` | System tenant | Looks for "System Tenant" by name, falls back to first tenant |
| `__FIRST_TENANT__` | First tenant | Uses the first tenant ID from database |
| `__DEFAULT_TENANT__` | Default tenant | Alias for `__FIRST_TENANT__` |
| `__RANDOM_TENANT__` | Random tenant | Pseudo-random selection from available tenants |

### Client ID Placeholders

| Placeholder | Description | Behavior |
|-------------|-------------|----------|
| `__DEFAULT_CLIENT__` | Default client | Looks for "Default Client" by name, falls back to first client |
| `__FIRST_CLIENT__` | First client | Uses the first client ID from database |
| `__RANDOM_CLIENT__` | Random client | Pseudo-random selection from available clients |

## Usage Examples

### Basic Template with Dynamic IDs
```json
{
  "service": "template",
  "table": "templates",
  "description": "Templates with dynamic dependencies",
  "data": [
    {
      "id": "template-001",
      "tenant_id": "__SYSTEM_TENANT__",
      "client_id": null,
      "name": "Global Template",
      "is_global": true
    },
    {
      "id": "template-002", 
      "tenant_id": "__FIRST_TENANT__",
      "client_id": "__DEFAULT_CLIENT__",
      "name": "Client-Specific Template",
      "is_global": false
    }
  ]
}
```

### Mixed Static and Dynamic IDs
```json
{
  "data": [
    {
      "tenant_id": "__SYSTEM_TENANT__",
      "client_id": "specific-client-uuid-here",
      "name": "Mixed ID Template"
    }
  ]
}
```

## Resolution Process

1. **Database Query**: Seeder queries available tenant and client IDs
2. **Placeholder Detection**: Scans JSON records for placeholder strings
3. **Name-Based Lookup**: For specific placeholders like `__SYSTEM_TENANT__`
4. **Fallback Strategy**: Uses first available ID if name lookup fails
5. **Verbose Logging**: Shows resolution in verbose mode

## Benefits

- ✅ **Portable JSON Files**: No need to edit for different environments
- ✅ **Environment Agnostic**: Works across dev/staging/production
- ✅ **Automatic Fallbacks**: Graceful handling when specific names don't exist
- ✅ **Clear Logging**: Verbose mode shows exactly what IDs were resolved
- ✅ **Backward Compatible**: Static IDs still work alongside placeholders

## Error Handling

- **No Tenants**: Fails with clear error message
- **Missing Names**: Falls back to first available ID
- **Invalid Placeholders**: Ignored (treated as static values)
- **Foreign Key Violations**: Standard database error with helpful context

## Best Practices

1. **Use Semantic Names**: `__SYSTEM_TENANT__` vs `__FIRST_TENANT__` 
2. **Document Dependencies**: Specify required entities in JSON comments
3. **Test Different Environments**: Verify placeholders resolve correctly
4. **Mix When Needed**: Combine static and dynamic IDs as appropriate
5. **Verbose Testing**: Always test with `-verbose` flag first

## Future Extensions

- User ID placeholders: `__ADMIN_USER__`, `__FIRST_USER__`
- Role ID placeholders: `__ADMIN_ROLE__`, `__USER_ROLE__`
- Category ID placeholders: `__DEFAULT_CATEGORY__`
- Custom lookup strategies: `__TENANT_BY_DOMAIN__`, `__CLIENT_BY_CODE__`
