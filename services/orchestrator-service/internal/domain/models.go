package domain

import (
	"time"
)

// EntitySpecification represents a high-level entity definition from the user
type EntitySpecification struct {
	Name          string                      `json:"name"`
	Description   string                      `json:"description,omitempty"`
	Fields        []FieldSpecification        `json:"fields"`
	Relationships []RelationshipSpecification `json:"relationships,omitempty"`
	Constraints   []ConstraintSpecification   `json:"constraints,omitempty"`
	Indexes       []IndexSpecification        `json:"indexes,omitempty"`
	Features      []string                    `json:"features"` // ["crud", "validation", "rest_api", "repository", "cache", "events"]
	Options       map[string]string           `json:"options,omitempty"`
}

// FieldSpecification represents a field definition in an entity
type FieldSpecification struct {
	Name        string            `json:"name"`
	Type        string            `json:"type"` // "string", "integer", "email", "timestamp", "boolean", "array", "object"
	Required    bool              `json:"required,omitempty"`
	Unique      bool              `json:"unique,omitempty"`
	Nullable    bool              `json:"nullable,omitempty"`
	Min         *int              `json:"min,omitempty"`
	Max         *int              `json:"max,omitempty"`
	Default     string            `json:"default,omitempty"`
	Validation  []string          `json:"validation,omitempty"` // ["email", "min:3", "max:100", "regex:^[a-zA-Z]+$"]
	Format      string            `json:"format,omitempty"`     // "date", "datetime", "password", "url"
	Enum        []string          `json:"enum,omitempty"`       // Allowed values for enum fields
	Reference   string            `json:"reference,omitempty"`  // Reference to another entity for foreign keys
	Description string            `json:"description,omitempty"`
	Tags        map[string]string `json:"tags,omitempty"` // Additional field tags (db, json, form, etc.)
	Options     map[string]string `json:"options,omitempty"`
}

// RelationshipSpecification represents relationships between entities
type RelationshipSpecification struct {
	Name        string `json:"name"`
	Type        string `json:"type"`   // "one_to_one", "one_to_many", "many_to_many"
	Target      string `json:"target"` // Target entity name
	ForeignKey  string `json:"foreign_key,omitempty"`
	JoinTable   string `json:"join_table,omitempty"` // For many_to_many
	OnDelete    string `json:"on_delete,omitempty"`  // "cascade", "set_null", "restrict"
	OnUpdate    string `json:"on_update,omitempty"`  // "cascade", "set_null", "restrict"
	Description string `json:"description,omitempty"`
}

// ConstraintSpecification represents database constraints
type ConstraintSpecification struct {
	Name        string   `json:"name"`
	Type        string   `json:"type"`                 // "check", "unique", "foreign_key", "primary_key"
	Fields      []string `json:"fields"`               // Fields involved in the constraint
	Expression  string   `json:"expression,omitempty"` // For check constraints
	Reference   string   `json:"reference,omitempty"`  // Referenced table for foreign keys
	Description string   `json:"description,omitempty"`
}

// IndexSpecification represents database indexes
type IndexSpecification struct {
	Name        string   `json:"name"`
	Type        string   `json:"type"`   // "btree", "hash", "gin", "gist"
	Fields      []string `json:"fields"` // Fields to index
	Unique      bool     `json:"unique,omitempty"`
	Partial     string   `json:"partial,omitempty"` // Partial index condition
	Description string   `json:"description,omitempty"`
}

// ProjectSpecification represents the complete project specification from the user
type ProjectSpecification struct {
	Name          string                  `json:"name"`
	Description   string                  `json:"description,omitempty"`
	ModulePath    string                  `json:"module_path"`
	OutputPath    string                  `json:"output_path"`
	ProjectType   string                  `json:"project_type"` // "microservice", "library", "cli", "api", "web", "worker"
	Entities      []EntitySpecification   `json:"entities"`
	Commands      []CommandSpecification  `json:"commands,omitempty"`  // For CLI projects
	Endpoints     []EndpointSpecification `json:"endpoints,omitempty"` // For API projects
	Services      []ServiceSpecification  `json:"services,omitempty"`  // For microservice projects
	Features      []string                `json:"features,omitempty"`  // ["docker", "makefile", "tests", "monitoring", "logging"]
	Dependencies  []string                `json:"dependencies,omitempty"`
	Configuration ProjectConfiguration    `json:"configuration,omitempty"`
	Options       map[string]string       `json:"options,omitempty"`
}

// CommandSpecification represents CLI commands for CLI projects
type CommandSpecification struct {
	Name        string                 `json:"name"`
	Description string                 `json:"description,omitempty"`
	Usage       string                 `json:"usage,omitempty"`
	Flags       []FlagSpecification    `json:"flags,omitempty"`
	SubCommands []CommandSpecification `json:"sub_commands,omitempty"`
	Handler     string                 `json:"handler,omitempty"` // Handler function name
}

// FlagSpecification represents CLI flags
type FlagSpecification struct {
	Name        string `json:"name"`
	Short       string `json:"short,omitempty"` // Short flag (e.g., "v" for -v)
	Type        string `json:"type"`            // "string", "bool", "int", "array"
	Required    bool   `json:"required,omitempty"`
	Default     string `json:"default,omitempty"`
	Description string `json:"description,omitempty"`
}

// EndpointSpecification represents REST API endpoints
type EndpointSpecification struct {
	Path        string                   `json:"path"`
	Method      string                   `json:"method"` // "GET", "POST", "PUT", "DELETE", "PATCH"
	Description string                   `json:"description,omitempty"`
	Handler     string                   `json:"handler,omitempty"`
	Middleware  []string                 `json:"middleware,omitempty"`
	Parameters  []ParameterSpecification `json:"parameters,omitempty"`
	Request     *RequestSpecification    `json:"request,omitempty"`
	Response    *ResponseSpecification   `json:"response,omitempty"`
	Security    []string                 `json:"security,omitempty"` // ["jwt", "api_key", "oauth"]
}

// ParameterSpecification represents endpoint parameters
type ParameterSpecification struct {
	Name        string `json:"name"`
	Type        string `json:"type"`      // "path", "query", "header"
	DataType    string `json:"data_type"` // "string", "integer", "boolean"
	Required    bool   `json:"required,omitempty"`
	Description string `json:"description,omitempty"`
}

// RequestSpecification represents request body specification
type RequestSpecification struct {
	ContentType string `json:"content_type"`     // "application/json", "multipart/form-data"
	Schema      string `json:"schema,omitempty"` // Reference to entity or custom schema
	Example     string `json:"example,omitempty"`
}

// ResponseSpecification represents response specification
type ResponseSpecification struct {
	StatusCode  int    `json:"status_code"`
	ContentType string `json:"content_type"`
	Schema      string `json:"schema,omitempty"`
	Example     string `json:"example,omitempty"`
}

// ServiceSpecification represents microservice components
type ServiceSpecification struct {
	Name         string   `json:"name"`
	Type         string   `json:"type"` // "domain", "application", "infrastructure"
	Interface    string   `json:"interface,omitempty"`
	Methods      []string `json:"methods,omitempty"`
	Dependencies []string `json:"dependencies,omitempty"`
	Description  string   `json:"description,omitempty"`
}

// ProjectConfiguration represents project-specific configuration
type ProjectConfiguration struct {
	Server      *ServerConfiguration      `json:"server,omitempty"`
	Database    *DatabaseConfiguration    `json:"database,omitempty"`
	Logging     *LoggingConfiguration     `json:"logging,omitempty"`
	Monitoring  *MonitoringConfiguration  `json:"monitoring,omitempty"`
	Security    *SecurityConfiguration    `json:"security,omitempty"`
	Performance *PerformanceConfiguration `json:"performance,omitempty"`
}

// ServerConfiguration represents server configuration
type ServerConfiguration struct {
	Port       int                `json:"port,omitempty"`
	Host       string             `json:"host,omitempty"`
	TLS        bool               `json:"tls,omitempty"`
	Timeout    string             `json:"timeout,omitempty"`
	Middleware []string           `json:"middleware,omitempty"`
	CORS       *CORSConfiguration `json:"cors,omitempty"`
}

// DatabaseConfiguration represents database configuration
type DatabaseConfiguration struct {
	Type       string             `json:"type,omitempty"` // "postgres", "mysql", "sqlite", "mongodb"
	Host       string             `json:"host,omitempty"`
	Port       int                `json:"port,omitempty"`
	Database   string             `json:"database,omitempty"`
	Migrations bool               `json:"migrations,omitempty"`
	Seeding    bool               `json:"seeding,omitempty"`
	Pooling    *PoolConfiguration `json:"pooling,omitempty"`
}

// LoggingConfiguration represents logging configuration
type LoggingConfiguration struct {
	Level      string   `json:"level,omitempty"`  // "debug", "info", "warn", "error"
	Format     string   `json:"format,omitempty"` // "json", "text"
	Output     []string `json:"output,omitempty"` // ["stdout", "file", "elk"]
	Structured bool     `json:"structured,omitempty"`
}

// MonitoringConfiguration represents monitoring configuration
type MonitoringConfiguration struct {
	Metrics   bool     `json:"metrics,omitempty"`
	Tracing   bool     `json:"tracing,omitempty"`
	Health    bool     `json:"health,omitempty"`
	Profiling bool     `json:"profiling,omitempty"`
	Endpoints []string `json:"endpoints,omitempty"`
}

// SecurityConfiguration represents security configuration
type SecurityConfiguration struct {
	Authentication []string          `json:"authentication,omitempty"` // ["jwt", "oauth", "basic"]
	Authorization  []string          `json:"authorization,omitempty"`  // ["rbac", "abac"]
	Encryption     *EncryptionConfig `json:"encryption,omitempty"`
	RateLimit      *RateLimitConfig  `json:"rate_limit,omitempty"`
}

// PerformanceConfiguration represents performance configuration
type PerformanceConfiguration struct {
	Caching     *CachingConfiguration `json:"caching,omitempty"`
	Compression bool                  `json:"compression,omitempty"`
	Workers     int                   `json:"workers,omitempty"`
	Buffering   *BufferingConfig      `json:"buffering,omitempty"`
}

// Supporting configuration structures
type CORSConfiguration struct {
	Origins []string `json:"origins,omitempty"`
	Methods []string `json:"methods,omitempty"`
	Headers []string `json:"headers,omitempty"`
}

type PoolConfiguration struct {
	MaxOpen     int    `json:"max_open,omitempty"`
	MaxIdle     int    `json:"max_idle,omitempty"`
	MaxLifetime string `json:"max_lifetime,omitempty"`
}

type EncryptionConfig struct {
	Algorithm string `json:"algorithm,omitempty"`
	KeySize   int    `json:"key_size,omitempty"`
}

type RateLimitConfig struct {
	Requests int    `json:"requests,omitempty"`
	Window   string `json:"window,omitempty"`
}

type CachingConfiguration struct {
	Type string `json:"type,omitempty"` // "redis", "memory", "memcached"
	TTL  string `json:"ttl,omitempty"`
	Size int    `json:"size,omitempty"`
}

type BufferingConfig struct {
	Size    int    `json:"size,omitempty"`
	Timeout string `json:"timeout,omitempty"`
}

// GenerationRequest represents the request format expected by the generator service
type GenerationRequest struct {
	ID              string                   `json:"id"`
	Elements        []map[string]interface{} `json:"elements"`
	ModulePath      string                   `json:"module_path"`
	OutputPath      string                   `json:"output_path"`
	PackageName     string                   `json:"package_name"`
	TemplateService string                   `json:"template_service_url"`
	CompilerService string                   `json:"compiler_service_url"`
	Parameters      map[string]string        `json:"parameters"`
}

// GeneratorPayload represents the detailed payload sent to the generator service (legacy)
type GeneratorPayload struct {
	OutputPath string        `json:"output_path"`
	ModulePath string        `json:"module_path"`
	Elements   []CodeElement `json:"elements"`
}

// CodeElement represents a code element in the generator payload
type CodeElement struct {
	Type       string                 `json:"type"` // "struct", "function", "interface"
	Name       string                 `json:"name"`
	Package    string                 `json:"package"`
	Fields     []FieldElement         `json:"fields,omitempty"`
	Parameters []ParameterElement     `json:"parameters,omitempty"`
	Returns    []ReturnElement        `json:"returns,omitempty"`
	Body       string                 `json:"body,omitempty"`
	Methods    []MethodElement        `json:"methods,omitempty"`
	Metadata   map[string]interface{} `json:"metadata,omitempty"`
}

// FieldElement represents a struct field
type FieldElement struct {
	Name string `json:"name"`
	Type string `json:"type"`
	Tags string `json:"tags,omitempty"`
}

// ParameterElement represents a function parameter
type ParameterElement struct {
	Name string `json:"name"`
	Type string `json:"type"`
}

// ReturnElement represents a function return value
type ReturnElement struct {
	Type string `json:"type"`
}

// MethodElement represents an interface method
type MethodElement struct {
	Name       string             `json:"name"`
	Parameters []ParameterElement `json:"parameters,omitempty"`
	Returns    []ReturnElement    `json:"returns,omitempty"`
}

// OrchestrationResult represents the result of orchestration
type OrchestrationResult struct {
	ID                string               `json:"id"`
	ProjectSpec       ProjectSpecification `json:"project_spec"`
	GeneratorPayload  GeneratorPayload     `json:"generator_payload"`  // For backward compatibility
	GenerationRequest GenerationRequest    `json:"generation_request"` // New format for generator service
	Success           bool                 `json:"success"`
	ErrorMessage      string               `json:"error_message,omitempty"`
	GeneratedFiles    int                  `json:"generated_files"`
	ProcessingTime    time.Duration        `json:"processing_time"`
	CreatedAt         time.Time            `json:"created_at"`
}

// TypeMapping maps user-friendly types to Go types
var TypeMapping = map[string]string{
	"string":    "string",
	"integer":   "int",
	"int":       "int",
	"int32":     "int32",
	"int64":     "int64",
	"float":     "float64",
	"float32":   "float32",
	"float64":   "float64",
	"boolean":   "bool",
	"bool":      "bool",
	"email":     "string",
	"password":  "string",
	"url":       "string",
	"timestamp": "time.Time",
	"datetime":  "time.Time",
	"date":      "time.Time",
	"time":      "time.Time",
	"uuid":      "string",
	"id":        "string",
	"text":      "string",
	"longtext":  "string",
	"json":      "json.RawMessage",
	"jsonb":     "json.RawMessage",
	"array":     "[]interface{}",
	"slice":     "[]string",
	"map":       "map[string]interface{}",
	"binary":    "[]byte",
	"bytes":     "[]byte",
	"decimal":   "decimal.Decimal",
	"money":     "decimal.Decimal",
	"enum":      "string",
}

// FeatureMapping maps features to implementation details
var FeatureMapping = map[string][]string{
	// Core features
	"crud":        {"repository", "service", "handler", "validation"},
	"validation":  {"validation_tags", "validation_functions", "sanitization"},
	"rest_api":    {"gin_handlers", "swagger_docs", "middleware"},
	"graphql_api": {"graphql_resolvers", "graphql_schema"},
	"grpc_api":    {"grpc_service", "protobuf_definitions"},

	// Data layer
	"repository": {"database_repository", "query_builders"},
	"cache":      {"redis_cache", "memory_cache"},
	"events":     {"event_publisher", "event_subscribers"},
	"migrations": {"database_migrations", "schema_versioning"},

	// Business layer
	"service":   {"business_logic_service", "domain_service"},
	"use_cases": {"application_use_cases", "command_handlers"},
	"workflows": {"workflow_orchestration", "step_definitions"},

	// Infrastructure layer
	"monitoring":    {"metrics", "health_checks", "tracing"},
	"logging":       {"structured_logging", "log_levels"},
	"security":      {"authentication", "authorization", "encryption"},
	"rate_limiting": {"rate_limiter", "throttling"},

	// Integration features
	"messaging":     {"message_queue", "pub_sub"},
	"file_storage":  {"file_upload", "file_management"},
	"notifications": {"email", "sms", "push_notifications"},
	"search":        {"full_text_search", "indexing"},

	// Development features
	"testing":       {"unit_tests", "integration_tests", "test_fixtures"},
	"documentation": {"swagger", "api_docs", "code_comments"},
	"cli":           {"cobra_commands", "flag_parsing"},
	"config":        {"environment_config", "config_validation"},
}

// ProjectTypeMapping maps project types to their default features and structure
var ProjectTypeMapping = map[string]ProjectTypeConfig{
	"microservice": {
		DefaultFeatures:     []string{"rest_api", "repository", "service", "validation", "monitoring", "logging", "config"},
		RequiredStructure:   []string{"cmd", "internal/domain", "internal/application", "internal/infrastructure", "internal/interfaces"},
		DefaultDependencies: []string{"gin", "gorm", "logrus", "viper"},
	},
	"api": {
		DefaultFeatures:     []string{"rest_api", "validation", "monitoring", "logging", "security"},
		RequiredStructure:   []string{"cmd", "internal/handlers", "internal/middleware", "internal/models"},
		DefaultDependencies: []string{"gin", "jwt-go", "cors"},
	},
	"cli": {
		DefaultFeatures:     []string{"cli", "config", "logging"},
		RequiredStructure:   []string{"cmd", "internal/commands", "internal/config"},
		DefaultDependencies: []string{"cobra", "viper", "logrus"},
	},
	"library": {
		DefaultFeatures:     []string{"testing", "documentation"},
		RequiredStructure:   []string{"pkg", "examples", "docs"},
		DefaultDependencies: []string{},
	},
	"web": {
		DefaultFeatures:     []string{"rest_api", "static_files", "templates", "sessions", "csrf"},
		RequiredStructure:   []string{"cmd", "internal/handlers", "web/static", "web/templates"},
		DefaultDependencies: []string{"gin", "html/template", "sessions"},
	},
	"worker": {
		DefaultFeatures:     []string{"messaging", "queue_processing", "monitoring", "logging"},
		RequiredStructure:   []string{"cmd", "internal/workers", "internal/jobs"},
		DefaultDependencies: []string{"rabbitmq", "redis", "cron"},
	},
}

// ProjectTypeConfig represents configuration for a specific project type
type ProjectTypeConfig struct {
	DefaultFeatures     []string `json:"default_features"`
	RequiredStructure   []string `json:"required_structure"`
	DefaultDependencies []string `json:"default_dependencies"`
	Templates           []string `json:"templates,omitempty"`
}

// ValidationRuleMapping maps validation rules to Go validation tags
var ValidationRuleMapping = map[string]string{
	"required":    "required",
	"email":       "email",
	"min":         "min",
	"max":         "max",
	"len":         "len",
	"alpha":       "alpha",
	"alphanum":    "alphanum",
	"numeric":     "numeric",
	"url":         "url",
	"uuid":        "uuid",
	"json":        "json",
	"base64":      "base64",
	"hexadecimal": "hexadecimal",
	"rgb":         "rgb",
	"rgba":        "rgba",
	"hsl":         "hsl",
	"hsla":        "hsla",
	"color":       "hexcolor|rgb|rgba|hsl|hsla",
}

// RelationshipMapping maps relationship types to implementation details
var RelationshipMapping = map[string]RelationshipConfig{
	"one_to_one": {
		GoTag:          "one2one",
		ForeignKeyTag:  "foreignKey",
		AssociationTag: "association_foreignkey",
	},
	"one_to_many": {
		GoTag:          "has_many",
		ForeignKeyTag:  "foreignKey",
		AssociationTag: "association_foreignkey",
	},
	"many_to_many": {
		GoTag:         "many2many",
		ForeignKeyTag: "foreignKey",
		JoinTableTag:  "join_table",
	},
	"belongs_to": {
		GoTag:          "belongs_to",
		ForeignKeyTag:  "foreignKey",
		AssociationTag: "association_foreignkey",
	},
}

// RelationshipConfig represents configuration for relationship implementation
type RelationshipConfig struct {
	GoTag          string `json:"go_tag"`
	ForeignKeyTag  string `json:"foreign_key_tag"`
	AssociationTag string `json:"association_tag,omitempty"`
	JoinTableTag   string `json:"join_table_tag,omitempty"`
}
