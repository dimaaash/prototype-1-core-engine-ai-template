package application

import (
	"fmt"
	"text/template"
	"time"

	"go-factory-platform/services/template-service/internal/domain"
)

// TemplateApplicationService implements the business logic for templates
type TemplateApplicationService struct {
	templateService     domain.TemplateService
	buildingBlockClient domain.BuildingBlockClient
}

// NewTemplateApplicationService creates a new template application service
func NewTemplateApplicationService(
	templateService domain.TemplateService,
	buildingBlockClient domain.BuildingBlockClient,
) *TemplateApplicationService {
	return &TemplateApplicationService{
		templateService:     templateService,
		buildingBlockClient: buildingBlockClient,
	}
}

// CreateTemplate creates a new template
func (s *TemplateApplicationService) CreateTemplate(tmpl *domain.Template) error {
	if tmpl.ID == "" {
		// Generate UUID here - for now using timestamp
		tmpl.ID = fmt.Sprintf("tmpl_%d", time.Now().UnixNano())
	}
	tmpl.CreatedAt = time.Now()
	tmpl.UpdatedAt = time.Now()

	// Validate template content
	if err := s.validateTemplateContent(tmpl.Content); err != nil {
		return fmt.Errorf("invalid template content: %w", err)
	}

	return s.templateService.CreateTemplate(tmpl)
}

// GetTemplate retrieves a template by ID
func (s *TemplateApplicationService) GetTemplate(id string) (*domain.Template, error) {
	return s.templateService.GetTemplate(id)
}

// GetTemplatesByCategory retrieves templates by category
func (s *TemplateApplicationService) GetTemplatesByCategory(category domain.TemplateCategory) ([]*domain.Template, error) {
	return s.templateService.GetTemplatesByCategory(category)
}

// ProcessTemplate processes a template request
func (s *TemplateApplicationService) ProcessTemplate(request *domain.TemplateRequest) (*domain.TemplateResult, error) {
	// Get template
	tmpl, err := s.templateService.GetTemplate(request.TemplateID)
	if err != nil {
		return nil, fmt.Errorf("failed to get template: %w", err)
	}

	// Validate parameters
	if err := s.validateParameters(tmpl, request.Parameters); err != nil {
		return nil, fmt.Errorf("invalid parameters: %w", err)
	}

	// Process template
	result, err := s.templateService.ProcessTemplate(request)
	if err != nil {
		return nil, fmt.Errorf("failed to process template: %w", err)
	}

	return result, nil
}

// CreateRepositoryTemplate creates a repository template
func (s *TemplateApplicationService) CreateRepositoryTemplate(name, entityName string) (*domain.Template, error) {
	content := `package repository

import (
	"context"
	"fmt"

	"{{.ModulePath}}/internal/domain"
)

type {{.EntityName}}Repository interface {
	Create(ctx context.Context, {{.EntityVarName}} *domain.{{.EntityName}}) error
	GetByID(ctx context.Context, id string) (*domain.{{.EntityName}}, error)
	Update(ctx context.Context, {{.EntityVarName}} *domain.{{.EntityName}}) error
	Delete(ctx context.Context, id string) error
	List(ctx context.Context) ([]*domain.{{.EntityName}}, error)
}

type {{.EntityVarName}}Repository struct {
	// Add your storage implementation here
}

func New{{.EntityName}}Repository() {{.EntityName}}Repository {
	return &{{.EntityVarName}}Repository{}
}

func (r *{{.EntityVarName}}Repository) Create(ctx context.Context, {{.EntityVarName}} *domain.{{.EntityName}}) error {
	// Implementation here
	return nil
}

func (r *{{.EntityVarName}}Repository) GetByID(ctx context.Context, id string) (*domain.{{.EntityName}}, error) {
	// Implementation here
	return nil, nil
}

func (r *{{.EntityVarName}}Repository) Update(ctx context.Context, {{.EntityVarName}} *domain.{{.EntityName}}) error {
	// Implementation here
	return nil
}

func (r *{{.EntityVarName}}Repository) Delete(ctx context.Context, id string) error {
	// Implementation here
	return nil
}

func (r *{{.EntityVarName}}Repository) List(ctx context.Context) ([]*domain.{{.EntityName}}, error) {
	// Implementation here
	return nil, nil
}`

	parameters := []domain.Parameter{
		{Name: "EntityName", Type: "string", Description: "Name of the entity", Required: true},
		{Name: "EntityVarName", Type: "string", Description: "Variable name for the entity", Required: true},
		{Name: "ModulePath", Type: "string", Description: "Go module path", Required: true},
	}

	tmpl := &domain.Template{
		Name:        name,
		Category:    domain.CategoryRepository,
		Description: fmt.Sprintf("Repository template for %s entity", entityName),
		Content:     content,
		Parameters:  parameters,
		Examples:    []string{fmt.Sprintf("Repository for %s entity with CRUD operations", entityName)},
	}

	return tmpl, s.CreateTemplate(tmpl)
}

// CreateServiceTemplate creates a service template
func (s *TemplateApplicationService) CreateServiceTemplate(name, entityName string) (*domain.Template, error) {
	content := `package application

import (
	"context"
	"fmt"

	"{{.ModulePath}}/internal/domain"
)

type {{.EntityName}}Service struct {
	repository domain.{{.EntityName}}Repository
}

func New{{.EntityName}}Service(repository domain.{{.EntityName}}Repository) *{{.EntityName}}Service {
	return &{{.EntityName}}Service{
		repository: repository,
	}
}

func (s *{{.EntityName}}Service) Create{{.EntityName}}(ctx context.Context, {{.EntityVarName}} *domain.{{.EntityName}}) error {
	// Business logic here
	if err := s.validate{{.EntityName}}({{.EntityVarName}}); err != nil {
		return fmt.Errorf("validation failed: %w", err)
	}

	return s.repository.Create(ctx, {{.EntityVarName}})
}

func (s *{{.EntityName}}Service) Get{{.EntityName}}(ctx context.Context, id string) (*domain.{{.EntityName}}, error) {
	if id == "" {
		return nil, fmt.Errorf("id cannot be empty")
	}

	return s.repository.GetByID(ctx, id)
}

func (s *{{.EntityName}}Service) Update{{.EntityName}}(ctx context.Context, {{.EntityVarName}} *domain.{{.EntityName}}) error {
	// Business logic here
	if err := s.validate{{.EntityName}}({{.EntityVarName}}); err != nil {
		return fmt.Errorf("validation failed: %w", err)
	}

	return s.repository.Update(ctx, {{.EntityVarName}})
}

func (s *{{.EntityName}}Service) Delete{{.EntityName}}(ctx context.Context, id string) error {
	if id == "" {
		return fmt.Errorf("id cannot be empty")
	}

	return s.repository.Delete(ctx, id)
}

func (s *{{.EntityName}}Service) List{{.EntityName}}s(ctx context.Context) ([]*domain.{{.EntityName}}, error) {
	return s.repository.List(ctx)
}

func (s *{{.EntityName}}Service) validate{{.EntityName}}({{.EntityVarName}} *domain.{{.EntityName}}) error {
	if {{.EntityVarName}} == nil {
		return fmt.Errorf("{{.EntityVarName}} cannot be nil")
	}
	// Add more validation logic here
	return nil
}`

	parameters := []domain.Parameter{
		{Name: "EntityName", Type: "string", Description: "Name of the entity", Required: true},
		{Name: "EntityVarName", Type: "string", Description: "Variable name for the entity", Required: true},
		{Name: "ModulePath", Type: "string", Description: "Go module path", Required: true},
	}

	tmpl := &domain.Template{
		Name:        name,
		Category:    domain.CategoryService,
		Description: fmt.Sprintf("Service template for %s entity", entityName),
		Content:     content,
		Parameters:  parameters,
		Examples:    []string{fmt.Sprintf("Service for %s entity with business logic", entityName)},
	}

	return tmpl, s.CreateTemplate(tmpl)
}

// CreateHandlerTemplate creates a handler template
func (s *TemplateApplicationService) CreateHandlerTemplate(name, entityName string) (*domain.Template, error) {
	content := `package handlers

import (
	"net/http"

	"{{.ModulePath}}/internal/application"
	"{{.ModulePath}}/internal/domain"

	"github.com/gin-gonic/gin"
)

type {{.EntityName}}Handler struct {
	service *application.{{.EntityName}}Service
}

func New{{.EntityName}}Handler(service *application.{{.EntityName}}Service) *{{.EntityName}}Handler {
	return &{{.EntityName}}Handler{
		service: service,
	}
}

func (h *{{.EntityName}}Handler) Create{{.EntityName}}(c *gin.Context) {
	var {{.EntityVarName}} domain.{{.EntityName}}
	if err := c.ShouldBindJSON(&{{.EntityVarName}}); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.service.Create{{.EntityName}}(c.Request.Context(), &{{.EntityVarName}}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, {{.EntityVarName}})
}

func (h *{{.EntityName}}Handler) Get{{.EntityName}}(c *gin.Context) {
	id := c.Param("id")
	{{.EntityVarName}}, err := h.service.Get{{.EntityName}}(c.Request.Context(), id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, {{.EntityVarName}})
}

func (h *{{.EntityName}}Handler) Update{{.EntityName}}(c *gin.Context) {
	id := c.Param("id")
	var {{.EntityVarName}} domain.{{.EntityName}}
	if err := c.ShouldBindJSON(&{{.EntityVarName}}); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Set ID from URL parameter
	{{.EntityVarName}}.ID = id

	if err := h.service.Update{{.EntityName}}(c.Request.Context(), &{{.EntityVarName}}); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, {{.EntityVarName}})
}

func (h *{{.EntityName}}Handler) Delete{{.EntityName}}(c *gin.Context) {
	id := c.Param("id")
	if err := h.service.Delete{{.EntityName}}(c.Request.Context(), id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusNoContent, nil)
}

func (h *{{.EntityName}}Handler) List{{.EntityName}}s(c *gin.Context) {
	{{.EntityVarName}}s, err := h.service.List{{.EntityName}}s(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, {{.EntityVarName}}s)
}

func (h *{{.EntityName}}Handler) RegisterRoutes(router *gin.Engine) {
	api := router.Group("/api/v1")
	{
		api.POST("/{{.EntityNameLower}}", h.Create{{.EntityName}})
		api.GET("/{{.EntityNameLower}}/:id", h.Get{{.EntityName}})
		api.PUT("/{{.EntityNameLower}}/:id", h.Update{{.EntityName}})
		api.DELETE("/{{.EntityNameLower}}/:id", h.Delete{{.EntityName}})
		api.GET("/{{.EntityNameLower}}", h.List{{.EntityName}}s)
	}
}`

	parameters := []domain.Parameter{
		{Name: "EntityName", Type: "string", Description: "Name of the entity", Required: true},
		{Name: "EntityVarName", Type: "string", Description: "Variable name for the entity", Required: true},
		{Name: "EntityNameLower", Type: "string", Description: "Lowercase entity name for routes", Required: true},
		{Name: "ModulePath", Type: "string", Description: "Go module path", Required: true},
	}

	tmpl := &domain.Template{
		Name:        name,
		Category:    domain.CategoryHandler,
		Description: fmt.Sprintf("HTTP handler template for %s entity", entityName),
		Content:     content,
		Parameters:  parameters,
		Examples:    []string{fmt.Sprintf("HTTP handlers for %s entity CRUD operations", entityName)},
	}

	return tmpl, s.CreateTemplate(tmpl)
}

// validateTemplateContent validates the template content
func (s *TemplateApplicationService) validateTemplateContent(content string) error {
	_, err := template.New("validation").Parse(content)
	return err
}

// validateParameters validates template parameters
func (s *TemplateApplicationService) validateParameters(tmpl *domain.Template, params map[string]string) error {
	for _, param := range tmpl.Parameters {
		if param.Required {
			if _, exists := params[param.Name]; !exists {
				return fmt.Errorf("required parameter %s is missing", param.Name)
			}
		}
	}
	return nil
}
