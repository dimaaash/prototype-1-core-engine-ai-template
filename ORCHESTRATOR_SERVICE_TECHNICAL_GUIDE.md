# Enhanced Orchestrator Service - Technical Implementation Guide

## 🏗️ Architecture Overview

The enhanced orchestrator service transforms simple project specifications into sophisticated, production-ready code generation requests. It acts as an intelligent middleware layer that understands project types, entity relationships, and development best practices.

```
Input: Project Specification (JSON)
   ↓
Enhanced Orchestrator Service
   ├── Project Type Analysis
   ├── Entity Enhancement
   ├── Relationship Processing
   ├── Feature Merging
   └── Payload Generation
   ↓
Output: Enhanced Generation Request
```

## 🔧 Core Components

### 1. Enhanced Domain Models

#### EntitySpecification Structure
```go
type EntitySpecification struct {
    Name          string                       `json:"name"`
    Fields        []FieldSpecification         `json:"fields"`
    Relationships []RelationshipSpecification  `json:"relationships,omitempty"`
    Constraints   []ConstraintSpecification    `json:"constraints,omitempty"`
    Indexes       []IndexSpecification         `json:"indexes,omitempty"`
    Commands      []CommandSpecification       `json:"commands,omitempty"`
    Endpoints     []EndpointSpecification      `json:"endpoints,omitempty"`
    Features      []string                     `json:"features,omitempty"`
}
```

#### Advanced Field Specifications
```go
type FieldSpecification struct {
    Name        string            `json:"name"`
    Type        string            `json:"type"`
    Required    bool              `json:"required,omitempty"`
    Unique      bool              `json:"unique,omitempty"`
    Nullable    bool              `json:"nullable,omitempty"`
    Min         *int              `json:"min,omitempty"`
    Max         *int              `json:"max,omitempty"`
    Default     string            `json:"default,omitempty"`
    Validation  []string          `json:"validation,omitempty"`
    Format      string            `json:"format,omitempty"`
    Enum        []string          `json:"enum,omitempty"`
    Reference   string            `json:"reference,omitempty"`
    Description string            `json:"description,omitempty"`
    Tags        map[string]string `json:"tags,omitempty"`
    Options     map[string]string `json:"options,omitempty"`
}
```

### 2. Relationship System

#### Relationship Types Supported
1. **One-to-One**: Single entity reference
2. **One-to-Many**: Parent with multiple children
3. **Many-to-One**: Multiple entities referencing single parent
4. **Many-to-Many**: Bi-directional relationships with join tables

#### RelationshipSpecification
```go
type RelationshipSpecification struct {
    Name        string `json:"name"`
    Type        string `json:"type"`   // "one_to_one", "one_to_many", "many_to_many"
    Target      string `json:"target"` // Target entity name
    ForeignKey  string `json:"foreign_key,omitempty"`
    JoinTable   string `json:"join_table,omitempty"`
    OnDelete    string `json:"on_delete,omitempty"`  // "cascade", "set_null", "restrict"
    OnUpdate    string `json:"on_update,omitempty"`
    Description string `json:"description,omitempty"`
}
```

#### Example: Order-OrderItem Relationship
```json
{
  "name": "Order",
  "relationships": [
    {
      "name": "order_items",
      "type": "one_to_many",
      "target": "OrderItem",
      "foreign_key": "order_id",
      "on_delete": "cascade",
      "description": "Order has many items"
    }
  ]
}
```

### 3. Constraint System

#### Supported Constraint Types
- **Unique**: Ensures field uniqueness
- **Check**: Custom SQL validation expressions
- **Foreign Key**: Referential integrity
- **Primary Key**: Unique identifiers

#### ConstraintSpecification
```go
type ConstraintSpecification struct {
    Name        string   `json:"name"`
    Type        string   `json:"type"`
    Fields      []string `json:"fields"`
    Expression  string   `json:"expression,omitempty"`
    Reference   string   `json:"reference,omitempty"`
    Description string   `json:"description,omitempty"`
}
```

#### Example: Complex Constraints
```json
{
  "constraints": [
    {
      "name": "unique_email",
      "type": "unique",
      "fields": ["Email"]
    },
    {
      "name": "positive_amount",
      "type": "check",
      "fields": ["TotalAmount"],
      "expression": "total_amount >= 0"
    }
  ]
}
```

### 4. Index System

#### Index Types Supported
- **B-tree**: Standard ordered indexing
- **Hash**: Equality-based lookups
- **GIN**: Generalized inverted index (JSON, arrays)
- **GIST**: Generalized search tree (geometric data)

#### IndexSpecification
```go
type IndexSpecification struct {
    Name        string   `json:"name"`
    Type        string   `json:"type"`
    Fields      []string `json:"fields"`
    Unique      bool     `json:"unique,omitempty"`
    Partial     string   `json:"partial,omitempty"`
    Description string   `json:"description,omitempty"`
}
```

#### Example: Performance Indexes
```json
{
  "indexes": [
    {
      "name": "idx_customer_status",
      "type": "btree",
      "fields": ["CustomerID", "Status"],
      "description": "Optimize queries by customer and status"
    },
    {
      "name": "idx_search_content",
      "type": "gin",
      "fields": ["SearchableContent"],
      "description": "Full-text search index"
    }
  ]
}
```

## 🎯 Project Type Configurations

### Project Type Mapping System

```go
type ProjectTypeConfig struct {
    Description         string   `json:"description"`
    DefaultFeatures     []string `json:"default_features"`
    RequiredStructure   []string `json:"required_structure"`
    DefaultDependencies []string `json:"default_dependencies"`
}

var ProjectTypeMapping = map[string]ProjectTypeConfig{
    "microservice": {
        Description: "A complete microservice with REST API, database integration, and business logic",
        DefaultFeatures: []string{
            "rest_api", "repository", "service", "validation", 
            "monitoring", "logging", "config"
        },
        RequiredStructure: []string{
            "cmd", "internal/domain", "internal/application", 
            "internal/infrastructure", "internal/interfaces"
        },
        DefaultDependencies: []string{"gin", "gorm", "logrus", "viper"},
    },
    // ... other project types
}
```

### CLI Project Specifications

#### Command System for CLI Projects
```go
type CommandSpecification struct {
    Name        string                 `json:"name"`
    Description string                 `json:"description,omitempty"`
    Usage       string                 `json:"usage,omitempty"`
    Flags       []FlagSpecification    `json:"flags,omitempty"`
    SubCommands []CommandSpecification `json:"sub_commands,omitempty"`
    Handler     string                 `json:"handler,omitempty"`
}

type FlagSpecification struct {
    Name        string `json:"name"`
    Short       string `json:"short,omitempty"`
    Type        string `json:"type"`
    Required    bool   `json:"required,omitempty"`
    Default     string `json:"default,omitempty"`
    Description string `json:"description,omitempty"`
}
```

#### Example CLI Entity
```json
{
  "name": "ConfigFile",
  "commands": [
    {
      "name": "create",
      "description": "Create a new config file",
      "flags": [
        {
          "name": "path",
          "type": "string",
          "required": true,
          "description": "Path to the config file"
        },
        {
          "name": "format",
          "type": "string",
          "default": "json",
          "description": "Format of the config file"
        }
      ]
    }
  ]
}
```

### API Project Specifications

#### Endpoint System for API Projects
```go
type EndpointSpecification struct {
    Path         string                    `json:"path"`
    Method       string                    `json:"method"`
    Summary      string                    `json:"summary,omitempty"`
    Description  string                    `json:"description,omitempty"`
    Parameters   []ParameterSpecification  `json:"parameters,omitempty"`
    RequestType  string                    `json:"request_type,omitempty"`
    ResponseType string                    `json:"response_type,omitempty"`
    Middleware   []string                  `json:"middleware,omitempty"`
}
```

#### Example API Entity
```json
{
  "name": "User",
  "endpoints": [
    {
      "path": "/users",
      "method": "GET",
      "description": "List all users",
      "response_type": "[]User"
    },
    {
      "path": "/users/{id}",
      "method": "GET",
      "description": "Get user by ID",
      "parameters": [
        {
          "name": "id",
          "type": "string",
          "location": "path",
          "required": true
        }
      ],
      "response_type": "User"
    }
  ]
}
```

## 🔄 Enhancement Process Flow

### 1. Project Specification Enhancement

```go
func (s *OrchestratorService) enhanceProjectSpecification(spec *domain.ProjectSpecification) error {
    // Get project type configuration
    projectConfig, exists := domain.ProjectTypeMapping[spec.ProjectType]
    if !exists {
        return fmt.Errorf("unsupported project type: %s", spec.ProjectType)
    }

    // Merge features
    spec.Features = s.mergeFeatures(spec.Features, projectConfig.DefaultFeatures)

    // Enhance entities based on project type
    for i := range spec.Entities {
        if err := s.enhanceEntityForProjectType(&spec.Entities[i], spec.ProjectType); err != nil {
            return fmt.Errorf("failed to enhance entity %s: %w", spec.Entities[i].Name, err)
        }
    }

    return nil
}
```

### 2. Entity Enhancement by Project Type

```go
func (s *OrchestratorService) enhanceEntityForProjectType(entity *domain.EntitySpecification, projectType string) error {
    switch projectType {
    case "cli":
        // Add CLI-specific enhancements
        if len(entity.Commands) == 0 {
            // Add default commands if none specified
            entity.Commands = s.generateDefaultCLICommands(entity)
        }
    case "api":
        // Add API-specific enhancements
        if len(entity.Endpoints) == 0 {
            // Add default REST endpoints if none specified
            entity.Endpoints = s.generateDefaultAPIEndpoints(entity)
        }
    case "microservice":
        // Add microservice-specific enhancements
        // Ensure proper domain modeling
        s.enhanceForDomainDrivenDesign(entity)
    }
    return nil
}
```

### 3. Feature Merging Logic

```go
func (s *OrchestratorService) mergeFeatures(userFeatures, defaultFeatures []string) []string {
    featureSet := make(map[string]bool)
    
    // Add user-specified features
    for _, feature := range userFeatures {
        featureSet[feature] = true
    }
    
    // Add default features that aren't already specified
    for _, feature := range defaultFeatures {
        if !featureSet[feature] {
            featureSet[feature] = true
        }
    }
    
    // Convert back to slice
    var merged []string
    for feature := range featureSet {
        merged = append(merged, feature)
    }
    
    return merged
}
```

## 📊 Type System Implementation

### Type Mapping Configuration

```go
var TypeMapping = map[string]TypeConfig{
    "string": {
        GoType:      "string",
        Description: "Basic text string",
    },
    "uuid": {
        GoType:      "string",
        Description: "Universally unique identifier",
    },
    "email": {
        GoType:      "string",
        Description: "Email address with validation",
    },
    "decimal": {
        GoType:      "decimal.Decimal",
        Description: "High-precision decimal number",
    },
    "json": {
        GoType:      "json.RawMessage",
        Description: "JSON data structure",
    },
    "timestamp": {
        GoType:      "time.Time",
        Description: "Date and time with timezone",
    },
    // ... 25+ more types
}
```

### Type Conversion Process

```go
func (s *OrchestratorService) convertFieldType(fieldType string) string {
    if typeConfig, exists := domain.TypeMapping[fieldType]; exists {
        return typeConfig.GoType
    }
    return "interface{}" // Fallback for unknown types
}
```

## 🧪 Usage Examples

### Complete Microservice Example

```json
{
  "name": "order-service",
  "module_path": "github.com/company/order-service",
  "output_path": "/tmp/generated/order-service",
  "project_type": "microservice",
  "entities": [
    {
      "name": "Order",
      "fields": [
        {
          "name": "ID",
          "type": "uuid",
          "required": true
        },
        {
          "name": "CustomerID",
          "type": "uuid",
          "required": true
        },
        {
          "name": "Status",
          "type": "enum",
          "enum": ["pending", "processing", "shipped", "delivered"],
          "required": true,
          "default": "pending"
        },
        {
          "name": "TotalAmount",
          "type": "decimal",
          "required": true,
          "validation": ["min:0"]
        }
      ],
      "relationships": [
        {
          "name": "order_items",
          "type": "one_to_many",
          "target": "OrderItem",
          "foreign_key": "order_id",
          "on_delete": "cascade"
        }
      ],
      "constraints": [
        {
          "name": "positive_amount",
          "type": "check",
          "fields": ["TotalAmount"],
          "expression": "total_amount >= 0"
        }
      ],
      "indexes": [
        {
          "name": "idx_customer_status",
          "type": "btree",
          "fields": ["CustomerID", "Status"]
        }
      ]
    }
  ],
  "services": [
    {
      "name": "OrderService",
      "type": "domain",
      "methods": ["CreateOrder", "UpdateOrderStatus", "GetOrderByID"],
      "dependencies": ["OrderRepository", "PaymentService"]
    }
  ],
  "features": [
    "rest_api",
    "repository",
    "service",
    "validation",
    "monitoring",
    "logging",
    "testing"
  ]
}
```

### API Response Structure

```json
{
  "id": "orch_1752939937878758000",
  "project_spec": {
    // Enhanced project specification
  },
  "generator_payload": {
    "output_path": "/tmp/generated/order-service",
    "module_path": "github.com/company/order-service",
    "elements": [
      {
        "type": "struct",
        "name": "Order",
        "package": "domain",
        "fields": [
          {
            "name": "ID",
            "type": "string",
            "tags": "json:\"id\" db:\"id\" validate:\"required\""
          }
        ]
      }
    ]
  },
  "generation_request": {
    // Complete generation request for downstream services
  },
  "success": true,
  "generated_files": 4,
  "processing_time": 26625,
  "created_at": "2025-07-19T11:45:37.87876-04:00"
}
```

## 🔌 API Integration

### Information Endpoints

#### Get Available Project Types
```bash
GET /api/v1/info/project-types
```

Response:
```json
{
  "count": 6,
  "project_types": {
    "microservice": {
      "description": "A complete microservice with REST API, database integration, and business logic",
      "default_features": ["rest_api", "repository", "service", "validation", "monitoring", "logging", "config"],
      "required_structure": ["cmd", "internal/domain", "internal/application", "internal/infrastructure", "internal/interfaces"],
      "default_dependencies": ["gin", "gorm", "logrus", "viper"]
    }
  }
}
```

#### Get Available Features
```bash
GET /api/v1/info/features
```

#### Get Available Types
```bash
GET /api/v1/info/types
```

### Project-Specific Orchestration

#### CLI Project Orchestration
```bash
POST /api/v1/orchestrate/cli
Content-Type: application/json

{
  "name": "my-cli-tool",
  "module_path": "github.com/example/my-cli-tool",
  "output_path": "/tmp/generated/my-cli-tool",
  "entities": [...],
  "features": ["cli", "config", "logging"]
}
```

#### API Project Orchestration
```bash
POST /api/v1/orchestrate/api
```

#### Microservice Orchestration
```bash
POST /api/v1/orchestrate/microservice
```

## 🚀 Performance Considerations

### Optimization Strategies

1. **Feature Caching**: Project type configurations are cached in memory
2. **Parallel Processing**: Entity enhancements processed concurrently
3. **Lazy Loading**: Complex relationships resolved on-demand
4. **Validation Optimization**: Early validation to prevent expensive processing

### Memory Management

- Efficient struct reuse for large specifications
- Garbage collection friendly object lifecycle
- Streaming JSON processing for large payloads

## 🔍 Debugging and Troubleshooting

### Common Issues

1. **Invalid Relationship Target**: Ensure target entities exist in specification
2. **Constraint Conflicts**: Check for conflicting unique/check constraints
3. **Type Mapping Errors**: Verify field types exist in TypeMapping
4. **Feature Conflicts**: Some features may be mutually exclusive

### Debug Logging

Enable debug logging to trace enhancement process:
```go
log.SetLevel(log.DebugLevel)
```

### Validation Errors

The service provides detailed validation error messages:
```json
{
  "error": "Invalid specification: Entity 'Order' references unknown target 'Customer' in relationship 'customer'"
}
```

## 📈 Monitoring and Metrics

### Key Metrics Tracked

- Orchestration request count by project type
- Average processing time per entity
- Feature usage statistics
- Error rates by validation type

### Health Checks

```bash
GET /health
```

Response:
```json
{
  "service": "orchestrator-service",
  "status": "healthy",
  "timestamp": "2025-07-19T11:40:33-04:00"
}
```

---

This technical guide provides comprehensive documentation for developers working with the enhanced orchestrator service, covering all major components and usage patterns.
