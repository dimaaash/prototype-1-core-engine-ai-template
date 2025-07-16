package application

import (
	"context"
	"fmt"
	"time"

	"go-factory-platform/services/generator-service/internal/domain"
)

// GeneratorApplicationService implements the core business logic for code generation
type GeneratorApplicationService struct {
	templateClient domain.TemplateServiceClient
	compilerClient domain.CompilerServiceClient
}

// NewGeneratorApplicationService creates a new generator application service
func NewGeneratorApplicationService(
	templateClient domain.TemplateServiceClient,
	compilerClient domain.CompilerServiceClient,
) *GeneratorApplicationService {
	return &GeneratorApplicationService{
		templateClient: templateClient,
		compilerClient: compilerClient,
	}
}

// GenerateCode generates code based on the request using the visitor pattern
func (s *GeneratorApplicationService) GenerateCode(ctx context.Context, request *domain.GenerationRequest) (*domain.GenerationResult, error) {
	fmt.Printf("Starting code generation for request: %s\n", request.ID)

	// Create visitor for code generation
	visitor := NewCodeGenerationVisitor(
		s.templateClient,
		request.ModulePath,
		request.OutputPath,
		request.PackageName,
	)

	// Process each element using the visitor pattern
	if err := s.ProcessElements(ctx, request.Elements, visitor); err != nil {
		return &domain.GenerationResult{
			ID:           fmt.Sprintf("result_%d", time.Now().UnixNano()),
			RequestID:    request.ID,
			Success:      false,
			ErrorMessage: err.Error(),
			CompletedAt:  time.Now(),
		}, nil
	}

	// Get accumulated code
	accumulator := visitor.GetAccumulator()

	// Send accumulated code to compiler service
	if err := s.compilerClient.WriteFiles(ctx, accumulator, request.OutputPath); err != nil {
		return &domain.GenerationResult{
			ID:           fmt.Sprintf("result_%d", time.Now().UnixNano()),
			RequestID:    request.ID,
			Accumulator:  *accumulator,
			Success:      false,
			ErrorMessage: fmt.Sprintf("failed to write files: %v", err),
			CompletedAt:  time.Now(),
		}, nil
	}

	// Validate generated code
	if err := s.compilerClient.ValidateCode(ctx, accumulator.Files); err != nil {
		fmt.Printf("Warning: Code validation failed: %v\n", err)
		// Continue anyway, validation is not critical
	}

	// Attempt to compile the project
	if err := s.compilerClient.CompileProject(ctx, request.OutputPath); err != nil {
		fmt.Printf("Warning: Project compilation failed: %v\n", err)
		// Continue anyway, compilation failure is not critical for generation
	}

	return &domain.GenerationResult{
		ID:          fmt.Sprintf("result_%d", time.Now().UnixNano()),
		RequestID:   request.ID,
		Accumulator: *accumulator,
		Success:     true,
		CompletedAt: time.Now(),
	}, nil
}

// ProcessElements processes code elements using the visitor pattern
func (s *GeneratorApplicationService) ProcessElements(ctx context.Context, elements []domain.CodeElement, visitor domain.CodeElementVisitor) error {
	for i, element := range elements {
		fmt.Printf("Processing element %d/%d: %s (%s)\n", i+1, len(elements), element.GetName(), element.GetType())

		if err := element.Accept(visitor); err != nil {
			return fmt.Errorf("failed to process element %s: %w", element.GetName(), err)
		}
	}
	return nil
}

// CreateRepositoryElement creates a repository element
func (s *GeneratorApplicationService) CreateRepositoryElement(name, entityName, pkg string) *domain.RepositoryElement {
	return &domain.RepositoryElement{
		Name:       name,
		EntityName: entityName,
		Package:    pkg,
		Methods:    []string{"Create", "GetByID", "Update", "Delete", "List"},
		Parameters: make(map[string]string),
		Metadata:   make(map[string]string),
	}
}

// CreateServiceElement creates a service element
func (s *GeneratorApplicationService) CreateServiceElement(name, entityName, pkg string) *domain.ServiceElement {
	return &domain.ServiceElement{
		Name:       name,
		EntityName: entityName,
		Package:    pkg,
		Methods:    []string{"Create", "Get", "Update", "Delete", "List"},
		Parameters: make(map[string]string),
		Metadata:   make(map[string]string),
	}
}

// CreateHandlerElement creates a handler element
func (s *GeneratorApplicationService) CreateHandlerElement(name, entityName, pkg string) *domain.HandlerElement {
	return &domain.HandlerElement{
		Name:       name,
		EntityName: entityName,
		Package:    pkg,
		Routes:     []string{"POST", "GET", "PUT", "DELETE"},
		Parameters: make(map[string]string),
		Metadata:   make(map[string]string),
	}
}

// CreateModelElement creates a model element
func (s *GeneratorApplicationService) CreateModelElement(name, pkg string, fields []domain.FieldElement) *domain.ModelElement {
	return &domain.ModelElement{
		Name:       name,
		Package:    pkg,
		Fields:     fields,
		Parameters: make(map[string]string),
		Metadata:   make(map[string]string),
	}
}

// CreateCompleteEntitySet creates a complete set of elements for an entity (repository, service, handler, model)
func (s *GeneratorApplicationService) CreateCompleteEntitySet(entityName, modulePath string) []domain.CodeElement {
	var elements []domain.CodeElement

	// Create model
	fields := []domain.FieldElement{
		{Name: "ID", Type: "string", Tags: `json:"id" gorm:"primaryKey"`},
		{Name: "Name", Type: "string", Tags: `json:"name" gorm:"not null"`},
		{Name: "CreatedAt", Type: "time.Time", Tags: `json:"created_at"`},
		{Name: "UpdatedAt", Type: "time.Time", Tags: `json:"updated_at"`},
	}

	model := s.CreateModelElement(entityName, "domain", fields)
	elements = append(elements, model)

	// Create repository
	repository := s.CreateRepositoryElement(entityName+"Repository", entityName, "repository")
	elements = append(elements, repository)

	// Create service
	service := s.CreateServiceElement(entityName+"Service", entityName, "application")
	elements = append(elements, service)

	// Create handler
	handler := s.CreateHandlerElement(entityName+"Handler", entityName, "handlers")
	elements = append(elements, handler)

	return elements
}
