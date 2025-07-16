# 🏭 Go Factory Platform - Prototype 1 Core Engine AI Template

A sophisticated microservices-based platform for generating, compiling, and managing Go code using AI-enhanced templates and building blocks with the Visitor pattern.

## 🚀 Complete Implementation Summary

### ✅ Implemented Services

#### 1. **Building Blocks Service** (Port 8081)
- Provides primitive Go code concepts (variables, structs, interfaces, functions)
- In-memory storage with full CRUD operations
- REST API for managing building blocks
- **Key Features**: Variable creation, struct building, interface definition

#### 2. **Template Service** (Port 8082) 
- Manages code generation templates using building blocks
- Template categories: repositories, services, handlers, models, DTOs, etc.
- Template processing with parameter substitution
- **Key Features**: Repository/Service/Handler template creation, template processing

#### 3. **Generator Service** (Port 8083) - **Implements Visitor Pattern**
- Uses Visitor pattern for flexible code generation
- Accumulates generated Go code files
- Coordinates with template-service and compiler-builder-service
- **Key Visitor Components**:
  - `CodeElement` interface - All elements implement `Accept(visitor)`
  - `CodeElementVisitor` interface - Defines visit methods
  - `CodeGenerationVisitor` - Generates code and accumulates files
  - Elements: `RepositoryElement`, `ServiceElement`, `HandlerElement`, etc.

#### 4. **Compiler Builder Service** (Port 8084)
- Writes accumulated files to filesystem  
- Compiles and validates Go projects
- Creates project structures
- **Key Features**: File writing, Go compilation, code validation, project creation

### 🚧 Future Services (Empty Structure)
- **Orchestrator Service** - Will coordinate complex multi-service operations
- **AI Vertex Service** - Will provide AI-powered code generation

## 🎯 How the Visitor Pattern Works

1. **Generator receives request** with code elements
2. **Creates CodeGenerationVisitor** with template client
3. **Each element calls `Accept(visitor)`** 
4. **Visitor processes each element type**:
   - `VisitRepository()` - Generates repository code
   - `VisitService()` - Generates service code  
   - `VisitHandler()` - Generates HTTP handlers
   - `VisitModel()` - Generates domain models
5. **Visitor accumulates generated files**
6. **Files sent to Compiler Builder Service** for writing and compilation

## 📁 Project Structure

```
go-factory-platform/
├── services/
│   ├── building-blocks-service/      # Port 8081 - Go primitives
│   ├── template-service/             # Port 8082 - Template management
│   ├── generator-service/            # Port 8083 - Visitor pattern implementation
│   ├── compiler-builder-service/     # Port 8084 - File system & compilation
│   ├── orchestrator-service/         # Future - Workflow coordination
│   └── ai-vertex-service/            # Future - AI-powered generation
├── examples/
│   ├── usage.sh                      # Example usage script
│   └── README.md                     # Detailed examples
├── Makefile                          # Build automation
└── README.md                         # This file
```

## 🚀 Quick Start

### Prerequisites
- Go 1.21 or later
- Make (optional, but recommended)
- curl and jq for API testing

### Running the Platform

#### Option 1: Using the Master Service Manager (Recommended)
```bash
# Start all services
./manage.sh start-all

# Check service status
./manage.sh status-all

# Run example workflow
./examples/example-workflow.sh

# Stop all services
./manage.sh stop-all
```

#### Option 2: Using Make
```bash
# Start all services
make start

# Test the complete workflow
make example

# Stop all services
make stop
```

#### Option 3: Manual Service Management
```bash
# Start services individually
./scripts/building-blocks-service.sh start
./scripts/template-service.sh start
./scripts/generator-service.sh start
./scripts/compiler-builder-service.sh start
```

### Service Management

#### Master Service Manager Commands
The `./manage.sh` script provides comprehensive service management:

**Global Commands:**
- `./manage.sh start-all` - Start all services in dependency order
- `./manage.sh stop-all` - Stop all running services
- `./manage.sh restart-all` - Restart all services
- `./manage.sh status-all` - Show status of all services
- `./manage.sh health-all` - Health check for all services
- `./manage.sh logs-all` - Show logs from all services
- `./manage.sh build-all` - Build all services
- `./manage.sh test-all` - Run tests for all services
- `./manage.sh clean-all` - Clean all services

**Individual Service Commands:**
- `./manage.sh start <service>` - Start specific service
- `./manage.sh stop <service>` - Stop specific service
- `./manage.sh status <service>` - Show service status
- `./manage.sh logs <service>` - Show service logs

#### Individual Service Scripts
Each service has its own management script in the `scripts/` directory:
```bash
# Available commands for each service script
./scripts/<service-name>.sh [deps|build|run|start|stop|test|clean|status|logs]
```

#### Make Commands
```bash
# Service management
make start          # Start all services
make stop           # Stop all services
make restart        # Restart all services
make status         # Show service status
make health         # Health check all services

# Development
make build          # Build all services
make test           # Test all services
make clean          # Clean all services
make deps           # Install dependencies

# Individual services
make building-blocks # Start building blocks service
make template       # Start template service
make generator      # Start generator service
make compiler       # Start compiler service

# Examples and testing
make example        # Run complete workflow example
make logs           # Show all service logs
```

### Generate Complete Entity Example
```bash
# Generate complete User microservice
curl -X POST http://localhost:8083/api/v1/generate/entity \
  -H "Content-Type: application/json" \
  -d '{
    "entity_name": "User",
    "module_path": "example.com/user-service",
    "output_path": "./generated/user-service"
  }'
```

This generates a complete Go microservice with:
- Domain model (`internal/domain/user.go`)
- Repository layer (`internal/infrastructure/repository/user_repository.go`) 
- Application service (`internal/application/user_service.go`)
- HTTP handlers (`internal/interfaces/http/handlers/user_handler.go`)

## 🏗️ Architecture Benefits

### Design Patterns Implementation
- **Visitor Pattern**: Flexible code generation that can be extended with new element types
- **Builder Pattern**: Used in building-blocks-service for constructing code elements
- **Template Method**: Used in template-service for different template types
- **Factory Pattern**: Used across services for creating domain objects

### Microservices Architecture
- **Single Responsibility**: Each service has a focused purpose
- **Domain-Driven Design**: Clean architecture with proper separation of concerns
- **Extensible**: Easy to add new templates, building blocks, and generation types
- **Code Accumulation**: Generator collects all files before sending to compiler

### Service Communication Flow
```
Building Blocks ←→ Template Service ←→ Generator Service ←→ Compiler Builder
     (8081)           (8082)              (8083)              (8084)
```

## 🛠️ Development

### Individual Service Development
```bash
# Run individual service
cd services/generator-service
go run cmd/main.go

# Build specific service
make build-generator-service

# Test specific service
make test-generator-service
```

### Adding New Code Elements (Visitor Pattern)
1. Add new element type in `generator-service/internal/domain/visitor.go`
2. Implement `Accept(visitor)` method
3. Add corresponding `Visit*()` method in `CodeElementVisitor`
4. Implement generation logic in `CodeGenerationVisitor`

### Adding New Templates
1. Create template in `template-service`
2. Add template processing logic
3. Update generator service to handle new template types

## 📝 Examples

See `examples/` directory for:
- Complete usage examples
- Step-by-step tutorials
- Generated project samples
- API documentation

## 🎉 What Makes This Special

1. **Visitor Pattern Implementation**: Demonstrates advanced Go design patterns for extensible code generation
2. **Microservices Coordination**: Shows how services can work together while maintaining independence
3. **Code Accumulation Strategy**: Generator accumulates all files before compilation
4. **Template-Driven Generation**: Flexible, reusable templates for different code patterns
5. **Clean Architecture**: Each service follows domain-driven design principles

The platform successfully demonstrates how the Visitor pattern can be used for sophisticated code generation in a distributed microservices architecture!