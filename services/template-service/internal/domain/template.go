package domain

import (
	"time"
)

// TemplateCategory represents the category of template
type TemplateCategory string

const (
	CategoryRepository  TemplateCategory = "repository"
	CategoryService     TemplateCategory = "service"
	CategoryStorage     TemplateCategory = "storage"
	CategoryAdapter     TemplateCategory = "adapter"
	CategoryValueObject TemplateCategory = "value_object"
	CategoryDTO         TemplateCategory = "dto"
	CategoryUseCase     TemplateCategory = "use_case"
	CategoryHandler     TemplateCategory = "handler"
	CategoryMiddleware  TemplateCategory = "middleware"
	CategoryModel       TemplateCategory = "model"
	CategoryInterface   TemplateCategory = "interface"
)

// Template represents a code generation template
type Template struct {
	ID             string           `json:"id"`
	Name           string           `json:"name"`
	Category       TemplateCategory `json:"category"`
	Description    string           `json:"description"`
	Content        string           `json:"content"`
	Parameters     []Parameter      `json:"parameters"`
	BuildingBlocks []string         `json:"building_blocks"` // IDs of building blocks used
	Examples       []string         `json:"examples"`
	CreatedAt      time.Time        `json:"created_at"`
	UpdatedAt      time.Time        `json:"updated_at"`
}

// Parameter represents a template parameter
type Parameter struct {
	Name         string `json:"name"`
	Type         string `json:"type"`
	Description  string `json:"description"`
	DefaultValue string `json:"default_value,omitempty"`
	Required     bool   `json:"required"`
}

// TemplateRequest represents a request to generate code from a template
type TemplateRequest struct {
	TemplateID  string            `json:"template_id"`
	Parameters  map[string]string `json:"parameters"`
	OutputPath  string            `json:"output_path"`
	PackageName string            `json:"package_name"`
}

// TemplateResult represents the result of template processing
type TemplateResult struct {
	ID            string            `json:"id"`
	RequestID     string            `json:"request_id"`
	TemplateID    string            `json:"template_id"`
	GeneratedCode string            `json:"generated_code"`
	Success       bool              `json:"success"`
	ErrorMessage  string            `json:"error_message,omitempty"`
	Metadata      map[string]string `json:"metadata"`
	CreatedAt     time.Time         `json:"created_at"`
}

// BuildingBlockReference represents a reference to a building block
type BuildingBlockReference struct {
	ID   string `json:"id"`
	Type string `json:"type"`
	Name string `json:"name"`
}

// TemplateService defines the interface for template operations
type TemplateService interface {
	CreateTemplate(template *Template) error
	GetTemplate(id string) (*Template, error)
	GetTemplatesByCategory(category TemplateCategory) ([]*Template, error)
	UpdateTemplate(template *Template) error
	DeleteTemplate(id string) error
	ListAllTemplates() ([]*Template, error)
	ProcessTemplate(request *TemplateRequest) (*TemplateResult, error)
}

// BuildingBlockClient defines the interface for communicating with building-blocks-service
type BuildingBlockClient interface {
	GetBuildingBlock(id string) (*BuildingBlockReference, error)
	GetBuildingBlocksByType(blockType string) ([]*BuildingBlockReference, error)
	GetPrimitiveBlocks() ([]*BuildingBlockReference, error)
}
