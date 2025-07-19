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
	publicTemplateRepo  domain.PublicTemplateRepository
	buildingBlockClient domain.BuildingBlockClient
}

// NewTemplateApplicationService creates a new template application service
func NewTemplateApplicationService(
	templateService domain.TemplateService,
	publicTemplateRepo domain.PublicTemplateRepository,
	buildingBlockClient domain.BuildingBlockClient,
) *TemplateApplicationService {
	return &TemplateApplicationService{
		templateService:     templateService,
		publicTemplateRepo:  publicTemplateRepo,
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

// CreateRepositoryTemplate creates a repository template by reading from database
func (s *TemplateApplicationService) CreateRepositoryTemplate(name, entityName string) (*domain.Template, error) {
	// Get template from public templates database
	publicTemplate, err := s.publicTemplateRepo.GetBySlug("go-repository-pattern-public")
	if err != nil {
		return nil, fmt.Errorf("failed to get repository template from database: %w", err)
	}

	// Increment usage count
	if err := s.publicTemplateRepo.IncrementUsageCount(publicTemplate.ID); err != nil {
		// Log error but don't fail the request
		fmt.Printf("Warning: failed to increment usage count for template %s: %v\n", publicTemplate.ID, err)
	}

	// Convert PublicTemplate to Template domain model
	template := &domain.Template{
		ID:          fmt.Sprintf("tmpl_%d", time.Now().UnixNano()),
		Name:        name,
		Category:    domain.CategoryRepository,
		Description: fmt.Sprintf("Repository template for %s entity", entityName),
		Content:     publicTemplate.Content,
		Parameters: []domain.Parameter{
			{Name: "EntityName", Type: "string", Description: "Name of the entity", Required: true},
			{Name: "EntityVarName", Type: "string", Description: "Variable name for the entity", Required: true},
			{Name: "ModulePath", Type: "string", Description: "Go module path", Required: true},
		},
		Examples:  []string{fmt.Sprintf("Repository for %s entity with CRUD operations", entityName)},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	return template, s.CreateTemplate(template)
}

// CreateServiceTemplate creates a service template by reading from database
func (s *TemplateApplicationService) CreateServiceTemplate(name, entityName string) (*domain.Template, error) {
	// Get template from public templates database
	publicTemplate, err := s.publicTemplateRepo.GetBySlug("go-application-service-public")
	if err != nil {
		return nil, fmt.Errorf("failed to get service template from database: %w", err)
	}

	// Increment usage count
	if err := s.publicTemplateRepo.IncrementUsageCount(publicTemplate.ID); err != nil {
		// Log error but don't fail the request
		fmt.Printf("Warning: failed to increment usage count for template %s: %v\n", publicTemplate.ID, err)
	}

	// Convert PublicTemplate to Template domain model
	template := &domain.Template{
		ID:          fmt.Sprintf("tmpl_%d", time.Now().UnixNano()),
		Name:        name,
		Category:    domain.CategoryService,
		Description: fmt.Sprintf("Service template for %s entity", entityName),
		Content:     publicTemplate.Content,
		Parameters: []domain.Parameter{
			{Name: "EntityName", Type: "string", Description: "Name of the entity", Required: true},
			{Name: "EntityVarName", Type: "string", Description: "Variable name for the entity", Required: true},
			{Name: "ModulePath", Type: "string", Description: "Go module path", Required: true},
		},
		Examples:  []string{fmt.Sprintf("Service for %s entity with business logic", entityName)},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	return template, s.CreateTemplate(template)
}

// CreateHandlerTemplate creates a handler template by reading from database
func (s *TemplateApplicationService) CreateHandlerTemplate(name, entityName string) (*domain.Template, error) {
	// Get template from public templates database
	publicTemplate, err := s.publicTemplateRepo.GetBySlug("go-gin-http-handler-public")
	if err != nil {
		return nil, fmt.Errorf("failed to get handler template from database: %w", err)
	}

	// Increment usage count
	if err := s.publicTemplateRepo.IncrementUsageCount(publicTemplate.ID); err != nil {
		// Log error but don't fail the request
		fmt.Printf("Warning: failed to increment usage count for template %s: %v\n", publicTemplate.ID, err)
	}

	// Convert PublicTemplate to Template domain model
	template := &domain.Template{
		ID:          fmt.Sprintf("tmpl_%d", time.Now().UnixNano()),
		Name:        name,
		Category:    domain.CategoryHandler,
		Description: fmt.Sprintf("HTTP handler template for %s entity", entityName),
		Content:     publicTemplate.Content,
		Parameters: []domain.Parameter{
			{Name: "EntityName", Type: "string", Description: "Name of the entity", Required: true},
			{Name: "EntityVarName", Type: "string", Description: "Variable name for the entity", Required: true},
			{Name: "EntityNameLower", Type: "string", Description: "Lowercase entity name for routes", Required: true},
			{Name: "ModulePath", Type: "string", Description: "Go module path", Required: true},
		},
		Examples:  []string{fmt.Sprintf("HTTP handlers for %s entity CRUD operations", entityName)},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	return template, s.CreateTemplate(template)
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
