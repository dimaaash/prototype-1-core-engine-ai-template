# Go Factory Platform Examples

This directory contains examples demonstrating how to use the Go Factory Platform to generate complete Go microservices with validated integration patterns.

## Overview

The platform consists of 5 main services that work together:

1. **Building Blocks Service** (Port 8081) - Provides primitive Go code concepts
2. **Template Service** (Port 8082) - Manages code generation templates  
3. **Generator Service** (Port 8083) - Uses Visitor pattern to generate code
4. **Compiler Builder Service** (Port 8084) - Writes files and compiles projects
5. **Project Structure Service** (Port 8085) - Creates standard Go project layouts

## ✅ Validated Integration Pattern

**Critical Integration Flow**: Template Service → Project Structure Service → Compiler Builder Service

The integration has been validated and documented with proper path coordination fixes applied.

## Available Example Scripts

1. **`integration-validation.sh`** - Comprehensive 5-step validation of service integration
2. **`example-workflow.sh`** - Basic workflow demonstrating the validated integration pattern
3. **`enhanced-workflow.sh`** - Advanced workflow with multiple templates and project validation
4. **`usage.sh`** - Individual service usage examples with integration pattern demonstrations

## Quick Start - Validated Integration

```bash
# Start all services
make build-all  
make run-all

# Run integration validation (recommended first)
chmod +x examples/integration-validation.sh
./examples/integration-validation.sh

# Run basic workflow example
chmod +x examples/example-workflow.sh
./examples/example-workflow.sh
```

## Example: Generating a User Service (Integration Pattern)

### 1. Create Project Structure (REQUIRED FIRST STEP)

```bash
# Create proper Go project layout
curl -X POST http://localhost:8085/api/v1/projects/create \
  -H "Content-Type: application/json" \
  -d '{
    "name": "user-service-example",
    "module_name": "github.com/example/user-service-example",
    "output_path": "/absolute/path/to/generated/user-service-example",
    "project_type": "microservice",
    "include_gitignore": true,
    "include_readme": true,
    "include_dockerfile": true,
    "include_makefile": true
  }'
```

### 2. Create Templates

```bash
# Create template for User model
curl -X POST http://localhost:8082/api/v1/templates \
  -H "Content-Type: application/json" \
  -d '{
    "name": "user-model-template",
    "description": "Template for creating User models",
    "content": "package {{.package}}\n\ntype {{.name}} struct {\n\tID string `json:\"id\"`\n\tName string `json:\"name\"`\n\tEmail string `json:\"email\"`\n}",
    "parameters": [
      {"name": "package", "type": "string", "description": "Package name", "required": true},
      {"name": "name", "type": "string", "description": "Struct name", "required": true}
    ]
  }'
```

### 3. Generate Code and Write to Project (VALIDATED PATTERN)

```bash
# Generate code using templates
GENERATED_FILES=$(curl -s -X POST http://localhost:8083/api/v1/generate \
  -H "Content-Type: application/json" \
  -d '{
    "elements": [
      {
        "type": "struct",
        "name": "User", 
        "package": "domain",
        "fields": [
          {"name": "ID", "type": "string", "tags": "json:\"id\""},
          {"name": "Name", "type": "string", "tags": "json:\"name\""},
          {"name": "Email", "type": "string", "tags": "json:\"email\""}
        ]
      }
    ]
  }' | jq '.accumulator.files')

# Write files to project-specific location (CRITICAL: Use output_path)
curl -X POST http://localhost:8084/api/v1/files/write \
  -H "Content-Type: application/json" \
  -d '{
    "files": '$GENERATED_FILES',
    "output_path": "/absolute/path/to/generated/user-service-example",
    "metadata": {
      "workflow": "user-service-generation",
      "integration_pattern": "validated"
    }
  }'

# Compile the integrated project
curl -X POST http://localhost:8084/api/v1/compile \
  -H "Content-Type: application/json" \
  -d '{"path": "/absolute/path/to/generated/user-service-example"}'
```

## Generated Project Structure (Integration Pattern)

```
generated/user-service-example/
├── cmd/
│   └── server/
│       └── main.go
├── internal/
│   ├── domain/
│   │   └── user.go        # Generated User model
│   ├── application/
│   ├── infrastructure/
│   └── interfaces/
│       └── http/
├── pkg/
├── scripts/
├── .gitignore
├── Dockerfile
├── go.mod
├── Makefile
└── README.md
```

## 🔧 Critical Integration Fixes Applied

The integration validation revealed and fixed a critical path coordination issue:

**Problem**: Compiler Builder Service ignored `output_path` parameter and always wrote to root `/generated` directory

**Solution**: Modified `WriteFiles` and `CompileProject` methods to respect provided paths

**Validation**: All services now coordinate properly with the validated integration pattern

## Running Examples

```bash
# Start all services
make build-all
make run-all

# Run comprehensive integration validation
./examples/integration-validation.sh

# Run individual example workflows  
./examples/example-workflow.sh
./examples/enhanced-workflow.sh
./examples/usage.sh
```

## 🎯 Integration Pattern Summary

1. ✅ **Project Structure Service**: Creates proper Go project layout
2. ✅ **Template Service**: Provides reusable code templates  
3. ✅ **Generator Service**: Generates code using templates and patterns
4. ✅ **Compiler Builder Service**: Writes files to project-specific locations
5. ✅ **Compilation**: Projects compile with integrated structure

**Key Success Factor**: Always specify `output_path` to ensure files are written to the correct project-specific directory, not the global `/generated` folder.
