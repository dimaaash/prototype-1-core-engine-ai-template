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

#### 5. **Project Structure Service** (Port 8085) - **NEW: Implemented**
- Creates standard Go project layouts and directory structures
- Manages project templates for different types (microservice, CLI, library, API, worker)
- Generates boilerplate files (go.mod, main.go, Dockerfile, Makefile, README.md)
- Validates project structures against Go conventions
- **Key Features**: Project structure creation, template management, Go standards validation

### 🚧 Future Services (Empty Structure)
- **Orchestrator Service** - Will coordinate complex multi-service operations
- **AI Vertex Service** - Will provide AI-powered code generation

### ✅ **Architecture Enhancement: Project Structure Service (Port 8085) - IMPLEMENTED**

The Project Structure Service has been successfully implemented and addresses the architectural gap identified earlier.

#### **Service Responsibilities:**
- **Project Layout Creation**: Creates standard Go project layouts (microservice, CLI, library, API, worker)
- **Template Management**: Manages reusable project structure templates
- **Boilerplate Generation**: Generates essential files (go.mod, main.go, Dockerfile, Makefile, README.md, .gitignore)
- **Structure Validation**: Validates existing projects against Go conventions
- **Standards Compliance**: Ensures generated projects follow Go community standards

#### **Enhanced Service Flow:**
```
Building Blocks → Template → Generator → Project Structure → Compiler Builder
    (8081)        (8082)     (8083)      (8085)            (8084)
```

#### **API Endpoints:**
- `POST /api/v1/projects/create` - Create and write project structure in one step
- `POST /api/v1/projects/structure` - Create project structure definition
- `POST /api/v1/projects/structure/write` - Write structure to filesystem
- `POST /api/v1/projects/validate` - Validate existing project structure
- `GET /api/v1/projects/types` - List available project types
- `GET /api/v1/projects/standards` - Get Go project standards and conventions
- `POST /api/v1/templates` - Create project template
- `GET /api/v1/templates` - List project templates

#### **Benefits Achieved:**
✅ **Better Separation of Concerns**: Each service has a single responsibility  
✅ **Reusable Project Templates**: Support for multiple Go project types  
✅ **Standard Layouts**: Follows Go community conventions (golang-standards/project-layout)  
✅ **Template-Driven**: YAML-based project structure definitions  
✅ **Enhanced Scalability**: Easier to extend and maintain

#### **Example Usage:**
```bash
# Create a microservice project structure
curl -X POST http://localhost:8085/api/v1/projects/create \
  -H "Content-Type: application/json" \
  -d '{
    "name": "user-service",
    "module_name": "github.com/company/user-service", 
    "output_path": "./generated/user-service",
    "project_type": "microservice",
    "include_gitignore": true,
    "include_readme": true,
    "include_dockerfile": true,
    "include_makefile": true
  }'
```

This generates a complete Go microservice with proper directory structure, essential files, and follows Go best practices.

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
│   ├── project-structure-service/    # Port 8085 - Project structure & templates
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

## 🔄 Example Workflow: Complete Code Generation Pipeline

The `examples/example-workflow.sh` script demonstrates a complete end-to-end code generation workflow that showcases all four microservices working together. Here's a detailed breakdown of each step:

### Step 1: Fetching Available Building Blocks
```bash
# GET http://localhost:8081/api/v1/building-blocks/primitives
```

**Purpose**: Discovers available Go code primitives that can be used as building blocks for code generation.

**What happens**:
- Queries the Building Blocks Service for all available primitives
- Returns basic Go constructs like structs, functions, variables, interfaces
- Each building block includes templates and parameter definitions
- Validates that the building blocks service is running and responsive

**Sample Response**:
```json
[
  {
    "id": "basic-struct",
    "type": "struct",
    "name": "basic-struct",
    "description": "Basic struct template",
    "template": "type {{.Name}} struct {\\n{{range .Fields}}\\t{{.Name}} {{.Type}} `json:\"{{.JsonTag}}\"`\\n{{end}}}",
    "parameters": {"Fields": "ID,Name,Email", "Name": "MyStruct"},
    "examples": ["type User struct { ID int `json:\"id\"` }"]
  }
]
```

### Step 2: Creating a New Template
```bash
# POST http://localhost:8082/api/v1/templates
```

**Purpose**: Creates a reusable template for generating specific Go code patterns.

**What happens**:
- Sends a template definition to the Template Service
- Template includes Go template syntax with placeholders (e.g., `{{.package}}`, `{{.name}}`)
- Defines required parameters for template processing
- Template is stored and can be reused for multiple code generation requests

**Sample Payload**:
```json
{
  "name": "user-struct",
  "description": "Template for creating a User struct",
  "content": "package {{.package}}\\n\\ntype {{.name}} struct {\\n\\tID   int    `json:\"id\"`\\n\\tName string `json:\"name\"`\\n\\tEmail string `json:\"email\"`\\n}",
  "parameters": [
    {"name": "package", "type": "string", "description": "Go package name", "required": true},
    {"name": "name", "type": "string", "description": "Struct name", "required": true}
  ]
}
```

### Step 3: Generating Code Using Visitor Pattern
```bash
# POST http://localhost:8083/api/v1/generate
```

**Purpose**: Uses the Visitor pattern to generate Go code from structured element definitions.

**What happens**:
- Sends element definitions (structs, functions) to the Generator Service
- Generator Service processes each element using the Visitor pattern:
  - Creates `StructElement` and `FunctionElement` objects
  - Each element calls `Accept(visitor)` method
  - `CodeGenerationVisitor` processes each element type with specific visit methods
  - Generates appropriate Go code for each element
  - Automatically detects cross-package references and adds import statements
- Accumulates all generated files in a `CodeAccumulator`
- Returns complete file set with proper package declarations and imports

**Sample Payload**:
```json
{
  "elements": [
    {
      "type": "struct",
      "name": "User",
      "package": "domain",
      "fields": [
        {"name": "ID", "type": "int", "tags": "json:\"id\""},
        {"name": "Name", "type": "string", "tags": "json:\"name\""},
        {"name": "Email", "type": "string", "tags": "json:\"email\""}
      ]
    },
    {
      "type": "function", 
      "name": "NewUser",
      "package": "application",
      "parameters": [
        {"name": "name", "type": "string"},
        {"name": "email", "type": "string"}
      ],
      "returns": [{"type": "*domain.User"}],
      "body": "return &domain.User{Name: name, Email: email}"
    }
  ]
}
```

**Sample Response**:
```json
{
  "accumulator": {
    "files": [
      {
        "path": "internal/domain/user.go",
        "content": "package domain\\n\\n// User represents a User\\ntype User struct {\\n\\tID int `json:\"id\"`\\n\\tName string `json:\"name\"`\\n\\tEmail string `json:\"email\"`\\n}",
        "package": "domain",
        "type": "struct"
      },
      {
        "path": "internal/application/newuser.go", 
        "content": "package application\\n\\nimport (\\n\\t\"go-factory-platform/services/compiler-builder-service/generated/internal/domain\"\\n)\\n\\n// NewUser implements NewUser\\nfunc NewUser(name string, email string) *domain.User {\\n\\treturn &domain.User{Name: name, Email: email}\\n}",
        "package": "application",
        "type": "function"
      }
    ]
  }
}
```

### Step 4: Writing Generated Files to Filesystem
```bash
# POST http://localhost:8084/api/v1/files/write
```

**Purpose**: Takes the accumulated generated files and writes them to the filesystem with proper directory structure.

**What happens**:
- Extracts the generated files from Step 3 response
- Sends files to the Compiler Builder Service
- Service creates the required directory structure (`internal/domain/`, `internal/application/`)
- Writes each file to its designated location
- Maintains proper package hierarchy and file organization
- All files are written to the `generated/` directory for isolation

**Sample Payload**:
```json
{
  "files": [/* files from Step 3 */],
  "output_path": "/path/to/generated",
  "metadata": {
    "workflow": "example-user-service", 
    "generated_at": "2025-07-16T17:04:06Z"
  }
}
```

### Step 5: Compiling the Generated Project
```bash
# POST http://localhost:8084/api/v1/compile
```

**Purpose**: Validates that the generated Go code compiles successfully.

**What happens**:
- Compiler Builder Service runs `go build` on the generated project
- Validates syntax, imports, and type correctness
- Reports compilation success or detailed error messages
- Ensures the generated code follows Go best practices
- Confirms the entire generation workflow produced valid, compilable code

**Sample Response (Success)**:
```json
{
  "project_path": "/path/to/generated",
  "success": true,
  "output": "",
  "build_time": 13248542,
  "metadata": {}
}
```

### 🎯 Key Workflow Benefits

1. **End-to-End Validation**: From building blocks discovery to final compilation
2. **Visitor Pattern Demonstration**: Shows extensible code generation architecture
3. **Microservices Coordination**: Four services working together seamlessly  
4. **Automatic Import Resolution**: Generator detects cross-package dependencies
5. **Proper Package Structure**: Generated code follows Go conventions
6. **Compilation Verification**: Ensures generated code is syntactically correct

### 🚀 Running the Complete Workflow

```bash
# Start all services
./manage.sh start-all

# Run the complete workflow
./examples/example-workflow.sh

# Check generated files
ls -la services/compiler-builder-service/generated/internal/
```

This workflow demonstrates the platform's ability to generate production-ready Go microservice code through a sophisticated, pattern-based approach!

### 🚀 Enhanced Workflow with Project Structure Service

The new `examples/enhanced-workflow.sh` demonstrates the complete integration of all 5 microservices:

#### **Enhanced 5-Step Workflow:**

1. **Project Structure Creation** (Project Structure Service)
   - Creates standard Go project layout
   - Generates boilerplate files (go.mod, main.go, Dockerfile, etc.)
   - Sets up directory structure following Go conventions

2. **Code Generation** (Generator Service)
   - Generates domain models and application logic
   - Uses Visitor pattern for extensible code generation
   - Handles cross-package imports automatically

3. **File Integration** (Compiler Builder Service)
   - Writes generated code into the project structure
   - Maintains proper file organization
   - Integrates new code with existing boilerplate

4. **Structure Validation** (Project Structure Service)
   - Validates the complete project against Go standards
   - Provides recommendations for improvements
   - Ensures project follows best practices

5. **Compilation Verification** (Compiler Builder Service)
   - Compiles the complete project
   - Validates all dependencies and imports
   - Confirms the project is ready for deployment

#### **Running the Enhanced Workflow:**

```bash
# Start all services (including new Project Structure Service)
./manage.sh start-all

# Run the enhanced workflow
./examples/enhanced-workflow.sh

# The workflow creates a complete microservice with:
# - Proper Go project structure
# - Domain models (User struct with fields)
# - Application services (CreateUser function)
# - All boilerplate files (main.go, Dockerfile, Makefile, etc.)
# - Validated structure and successful compilation
```

#### **Generated Project Example:**
```
user-microservice/
├── cmd/server/main.go           # Entry point
├── internal/domain/user.go      # Generated domain model
├── internal/application/        # Generated application logic
├── internal/infrastructure/     # Infrastructure layer
├── pkg/api/                     # API definitions
├── go.mod                       # Module definition
├── Dockerfile                   # Container configuration
├── Makefile                     # Build automation
├── README.md                    # Documentation
└── .gitignore                   # Git ignore rules
```

The enhanced workflow showcases the platform's evolution from individual code generation to complete project creation with proper architecture!

## 🎉 What Makes This Special

1. **Visitor Pattern Implementation**: Demonstrates advanced Go design patterns for extensible code generation
2. **Microservices Coordination**: Shows how services can work together while maintaining independence
3. **Code Accumulation Strategy**: Generator accumulates all files before compilation
4. **Template-Driven Generation**: Flexible, reusable templates for different code patterns
5. **Clean Architecture**: Each service follows domain-driven design principles

The platform successfully demonstrates how the Visitor pattern can be used for sophisticated code generation in a distributed microservices architecture!