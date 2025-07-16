# Go Factory Platform Example

This example demonstrates how to use the Go Factory Platform to generate a complete Go microservice.

## Overview

The platform consists of 4 main services that work together:

1. **Building Blocks Service** (Port 8081) - Provides primitive Go code concepts
2. **Template Service** (Port 8082) - Manages code generation templates  
3. **Generator Service** (Port 8083) - Uses Visitor pattern to generate code
4. **Compiler Builder Service** (Port 8084) - Writes files and compiles projects

## Example: Generating a User Service

### 1. Create Building Blocks

```bash
# Create a variable building block
curl -X POST http://localhost:8081/api/v1/building-blocks/variable \
  -H "Content-Type: application/json" \
  -d '{
    "name": "userID",
    "type": "string",
    "default_value": ""
  }'
```

### 2. Create Templates

```bash
# Create repository template
curl -X POST http://localhost:8082/api/v1/templates/repository \
  -H "Content-Type: application/json" \
  -d '{
    "name": "UserRepository",
    "entity_name": "User"
  }'

# Create service template  
curl -X POST http://localhost:8082/api/v1/templates/service \
  -H "Content-Type: application/json" \
  -d '{
    "name": "UserService",
    "entity_name": "User"
  }'

# Create handler template
curl -X POST http://localhost:8082/api/v1/templates/handler \
  -H "Content-Type: application/json" \
  -d '{
    "name": "UserHandler", 
    "entity_name": "User"
  }'
```

### 3. Generate Complete Entity

```bash
# Generate all components for User entity
curl -X POST http://localhost:8083/api/v1/generate/entity \
  -H "Content-Type: application/json" \
  -d '{
    "entity_name": "User",
    "module_path": "example.com/user-service", 
    "output_path": "./generated/user-service"
  }'
```

This will generate:
- `internal/domain/user.go` - User model with fields
- `internal/infrastructure/repository/user_repository.go` - Repository implementation
- `internal/application/user_service.go` - Business logic service
- `internal/interfaces/http/handlers/user_handler.go` - HTTP handlers

## How the Visitor Pattern Works

The Generator Service uses the Visitor pattern to process different code elements:

1. **CodeElement Interface** - All code elements implement Accept(visitor)
2. **CodeElementVisitor Interface** - Defines visit methods for each element type
3. **CodeGenerationVisitor** - Concrete visitor that generates code
4. **Elements** - RepositoryElement, ServiceElement, HandlerElement, etc.

### Flow:
1. Generator receives generation request with elements
2. Creates CodeGenerationVisitor with template client
3. Each element calls Accept(visitor) 
4. Visitor calls appropriate visit method (VisitRepository, VisitService, etc.)
5. Visitor accumulates generated files
6. Files are sent to Compiler Builder Service

## Running the Example

```bash
# Start all services
make build-all
make run-all

# Run the example
chmod +x examples/usage.sh
./examples/usage.sh
```

## Generated Project Structure

```
generated/user-service/
├── internal/
│   ├── domain/
│   │   └── user.go
│   ├── application/  
│   │   └── user_service.go
│   ├── infrastructure/
│   │   └── repository/
│   │       └── user_repository.go
│   └── interfaces/
│       └── http/
│           └── handlers/
│               └── user_handler.go
└── go.mod
```
