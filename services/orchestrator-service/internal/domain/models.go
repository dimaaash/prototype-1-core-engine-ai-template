package domain

import (
	"time"
)

// EntitySpecification represents a high-level entity definition from the user
type EntitySpecification struct {
	Name        string               `json:"name"`
	Description string               `json:"description,omitempty"`
	Fields      []FieldSpecification `json:"fields"`
	Features    []string             `json:"features"` // ["crud", "validation", "rest_api", "repository"]
	Options     map[string]string    `json:"options,omitempty"`
}

// FieldSpecification represents a field definition in an entity
type FieldSpecification struct {
	Name        string            `json:"name"`
	Type        string            `json:"type"` // "string", "integer", "email", "timestamp", "boolean"
	Required    bool              `json:"required,omitempty"`
	Unique      bool              `json:"unique,omitempty"`
	Min         *int              `json:"min,omitempty"`
	Max         *int              `json:"max,omitempty"`
	Default     string            `json:"default,omitempty"`
	Validation  []string          `json:"validation,omitempty"` // ["email", "min:3", "max:100"]
	Description string            `json:"description,omitempty"`
	Options     map[string]string `json:"options,omitempty"`
}

// ProjectSpecification represents the complete project specification from the user
type ProjectSpecification struct {
	Name         string                `json:"name"`
	Description  string                `json:"description,omitempty"`
	ModulePath   string                `json:"module_path"`
	OutputPath   string                `json:"output_path"`
	ProjectType  string                `json:"project_type"` // "microservice", "library", "cli"
	Entities     []EntitySpecification `json:"entities"`
	Features     []string              `json:"features,omitempty"` // ["docker", "makefile", "tests"]
	Dependencies []string              `json:"dependencies,omitempty"`
	Options      map[string]string     `json:"options,omitempty"`
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
	"int64":     "int64",
	"float":     "float64",
	"boolean":   "bool",
	"bool":      "bool",
	"email":     "string",
	"timestamp": "time.Time",
	"datetime":  "time.Time",
	"date":      "time.Time",
	"uuid":      "string",
	"id":        "string",
	"text":      "string",
	"json":      "json.RawMessage",
}

// FeatureMapping maps features to implementation details
var FeatureMapping = map[string][]string{
	"crud":       {"repository", "service", "handler"},
	"validation": {"validation_tags", "validation_functions"},
	"rest_api":   {"gin_handlers", "swagger_docs"},
	"repository": {"database_repository"},
	"service":    {"business_logic_service"},
	"handler":    {"http_handlers"},
}
