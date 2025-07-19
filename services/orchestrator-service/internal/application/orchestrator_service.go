package application

import (
	"fmt"
	"strings"
	"time"

	"go-factory-platform/services/orchestrator-service/internal/domain"
)

// OrchestratorService handles the conversion from user specifications to generator payloads
type OrchestratorService struct {
}

// NewOrchestratorService creates a new orchestrator service
func NewOrchestratorService() *OrchestratorService {
	return &OrchestratorService{}
}

// OrchestrateMicroservice converts a project specification to a generator payload
func (s *OrchestratorService) OrchestrateMicroservice(spec *domain.ProjectSpecification) (*domain.OrchestrationResult, error) {
	startTime := time.Now()

	result := &domain.OrchestrationResult{
		ID:          fmt.Sprintf("orch_%d", time.Now().UnixNano()),
		ProjectSpec: *spec,
		CreatedAt:   time.Now(),
	}

	// Convert specification to generator payload
	payload, err := s.convertToGeneratorPayload(spec)
	if err != nil {
		result.Success = false
		result.ErrorMessage = err.Error()
		return result, err
	}

	// Convert to generator service format
	generationRequest, err := s.convertToGenerationRequest(spec, payload)
	if err != nil {
		result.Success = false
		result.ErrorMessage = err.Error()
		return result, err
	}

	result.GeneratorPayload = *payload
	result.GenerationRequest = *generationRequest
	result.Success = true
	result.GeneratedFiles = len(payload.Elements)
	result.ProcessingTime = time.Since(startTime)

	return result, nil
}

// convertToGeneratorPayload converts a project specification to a generator payload
func (s *OrchestratorService) convertToGeneratorPayload(spec *domain.ProjectSpecification) (*domain.GeneratorPayload, error) {
	payload := &domain.GeneratorPayload{
		OutputPath: spec.OutputPath,
		ModulePath: spec.ModulePath,
		Elements:   []domain.CodeElement{},
	}

	// Process each entity
	for _, entity := range spec.Entities {
		elements, err := s.generateEntityElements(entity, spec)
		if err != nil {
			return nil, fmt.Errorf("failed to generate elements for entity %s: %w", entity.Name, err)
		}
		payload.Elements = append(payload.Elements, elements...)
	}

	return payload, nil
}

// convertToGenerationRequest converts a generator payload to the format expected by the generator service
func (s *OrchestratorService) convertToGenerationRequest(spec *domain.ProjectSpecification, payload *domain.GeneratorPayload) (*domain.GenerationRequest, error) {
	// Convert CodeElement structs to map[string]interface{} for the generator service
	elements := make([]map[string]interface{}, len(payload.Elements))
	for i, element := range payload.Elements {
		elementMap := map[string]interface{}{
			"type":    element.Type,
			"name":    element.Name,
			"package": element.Package,
		}

		if len(element.Fields) > 0 {
			elementMap["fields"] = element.Fields
		}
		if len(element.Parameters) > 0 {
			elementMap["parameters"] = element.Parameters
		}
		if len(element.Returns) > 0 {
			elementMap["returns"] = element.Returns
		}
		if element.Body != "" {
			elementMap["body"] = element.Body
		}
		if len(element.Methods) > 0 {
			elementMap["methods"] = element.Methods
		}
		if len(element.Metadata) > 0 {
			elementMap["metadata"] = element.Metadata
		}

		elements[i] = elementMap
	}

	request := &domain.GenerationRequest{
		ID:              fmt.Sprintf("gen_%d", time.Now().UnixNano()),
		Elements:        elements,
		ModulePath:      spec.ModulePath,
		OutputPath:      spec.OutputPath,
		PackageName:     "main", // Default package name
		TemplateService: "http://localhost:8082",
		CompilerService: "http://localhost:8084",
		Parameters:      make(map[string]string),
	}

	return request, nil
}

// generateEntityElements generates all code elements for an entity based on its features
func (s *OrchestratorService) generateEntityElements(entity domain.EntitySpecification, spec *domain.ProjectSpecification) ([]domain.CodeElement, error) {
	var elements []domain.CodeElement

	// 1. Always generate the struct/model
	structElement := s.generateStructElement(entity)
	elements = append(elements, structElement)

	// 2. Generate constructor function
	constructorElement := s.generateConstructorElement(entity)
	elements = append(elements, constructorElement)

	// 3. Generate elements based on features
	for _, feature := range entity.Features {
		switch feature {
		case "crud", "repository":
			// Generate repository interface
			repoInterface := s.generateRepositoryInterface(entity)
			elements = append(elements, repoInterface)

		case "validation":
			// Generate validation function
			validationFunc := s.generateValidationFunction(entity)
			elements = append(elements, validationFunc)

		case "rest_api", "handler":
			// Generate service function for business logic
			serviceFunc := s.generateServiceFunction(entity)
			elements = append(elements, serviceFunc)
		}
	}

	return elements, nil
}

// generateStructElement generates a struct element from entity specification
func (s *OrchestratorService) generateStructElement(entity domain.EntitySpecification) domain.CodeElement {
	var fields []domain.FieldElement

	// Add ID field if not explicitly defined
	hasID := false
	for _, field := range entity.Fields {
		if strings.ToLower(field.Name) == "id" {
			hasID = true
			break
		}
	}

	if !hasID {
		fields = append(fields, domain.FieldElement{
			Name: "ID",
			Type: "string",
			Tags: `json:"id" db:"id"`,
		})
	}

	// Convert user fields to struct fields
	for _, field := range entity.Fields {
		goType := s.mapFieldType(field.Type)
		tags := s.generateFieldTags(field)

		fields = append(fields, domain.FieldElement{
			Name: s.capitalizeFirst(field.Name),
			Type: goType,
			Tags: tags,
		})
	}

	// Add timestamp fields
	fields = append(fields,
		domain.FieldElement{
			Name: "CreatedAt",
			Type: "time.Time",
			Tags: `json:"created_at" db:"created_at"`,
		},
		domain.FieldElement{
			Name: "UpdatedAt",
			Type: "time.Time",
			Tags: `json:"updated_at" db:"updated_at"`,
		},
	)

	return domain.CodeElement{
		Type:    "struct",
		Name:    entity.Name,
		Package: "domain",
		Fields:  fields,
	}
}

// generateConstructorElement generates a constructor function
func (s *OrchestratorService) generateConstructorElement(entity domain.EntitySpecification) domain.CodeElement {
	var parameters []domain.ParameterElement

	// Add parameters for required fields (excluding ID and timestamps)
	for _, field := range entity.Fields {
		if field.Required && strings.ToLower(field.Name) != "id" {
			parameters = append(parameters, domain.ParameterElement{
				Name: strings.ToLower(field.Name),
				Type: s.mapFieldType(field.Type),
			})
		}
	}

	// Generate constructor body
	body := s.generateConstructorBody(entity, parameters)

	return domain.CodeElement{
		Type:       "function",
		Name:       fmt.Sprintf("New%s", entity.Name),
		Package:    "domain",
		Parameters: parameters,
		Returns: []domain.ReturnElement{
			{Type: fmt.Sprintf("*%s", entity.Name)},
		},
		Body: body,
	}
}

// generateRepositoryInterface generates a repository interface
func (s *OrchestratorService) generateRepositoryInterface(entity domain.EntitySpecification) domain.CodeElement {
	methods := []domain.MethodElement{
		{
			Name: "Create",
			Parameters: []domain.ParameterElement{
				{Name: "ctx", Type: "context.Context"},
				{Name: strings.ToLower(entity.Name), Type: fmt.Sprintf("*%s", entity.Name)},
			},
			Returns: []domain.ReturnElement{{Type: "error"}},
		},
		{
			Name: "GetByID",
			Parameters: []domain.ParameterElement{
				{Name: "ctx", Type: "context.Context"},
				{Name: "id", Type: "string"},
			},
			Returns: []domain.ReturnElement{
				{Type: fmt.Sprintf("*%s", entity.Name)},
				{Type: "error"},
			},
		},
		{
			Name: "Update",
			Parameters: []domain.ParameterElement{
				{Name: "ctx", Type: "context.Context"},
				{Name: strings.ToLower(entity.Name), Type: fmt.Sprintf("*%s", entity.Name)},
			},
			Returns: []domain.ReturnElement{{Type: "error"}},
		},
		{
			Name: "Delete",
			Parameters: []domain.ParameterElement{
				{Name: "ctx", Type: "context.Context"},
				{Name: "id", Type: "string"},
			},
			Returns: []domain.ReturnElement{{Type: "error"}},
		},
		{
			Name: "List",
			Parameters: []domain.ParameterElement{
				{Name: "ctx", Type: "context.Context"},
			},
			Returns: []domain.ReturnElement{
				{Type: fmt.Sprintf("[]*%s", entity.Name)},
				{Type: "error"},
			},
		},
	}

	return domain.CodeElement{
		Type:    "interface",
		Name:    fmt.Sprintf("%sRepository", entity.Name),
		Package: "domain",
		Methods: methods,
	}
}

// generateValidationFunction generates a validation function
func (s *OrchestratorService) generateValidationFunction(entity domain.EntitySpecification) domain.CodeElement {
	body := s.generateValidationBody(entity)

	return domain.CodeElement{
		Type:    "function",
		Name:    fmt.Sprintf("Validate%s", entity.Name),
		Package: "domain",
		Parameters: []domain.ParameterElement{
			{Name: strings.ToLower(entity.Name), Type: fmt.Sprintf("*%s", entity.Name)},
		},
		Returns: []domain.ReturnElement{{Type: "error"}},
		Body:    body,
	}
}

// generateServiceFunction generates a service function for business logic
func (s *OrchestratorService) generateServiceFunction(entity domain.EntitySpecification) domain.CodeElement {
	body := fmt.Sprintf(`%s := domain.New%s(%s)
	// TODO: Add validation logic
	// TODO: Save to repository
	return %s, nil`,
		strings.ToLower(entity.Name),
		entity.Name,
		s.getConstructorParams(entity),
		strings.ToLower(entity.Name),
	)

	var parameters []domain.ParameterElement
	for _, field := range entity.Fields {
		if field.Required && strings.ToLower(field.Name) != "id" {
			parameters = append(parameters, domain.ParameterElement{
				Name: strings.ToLower(field.Name),
				Type: s.mapFieldType(field.Type),
			})
		}
	}

	return domain.CodeElement{
		Type:       "function",
		Name:       fmt.Sprintf("Create%s", entity.Name),
		Package:    "application",
		Parameters: parameters,
		Returns: []domain.ReturnElement{
			{Type: fmt.Sprintf("*domain.%s", entity.Name)},
			{Type: "error"},
		},
		Body: body,
	}
}

// Helper methods

func (s *OrchestratorService) mapFieldType(userType string) string {
	if goType, exists := domain.TypeMapping[userType]; exists {
		return goType
	}
	return userType // fallback to user-provided type
}

func (s *OrchestratorService) generateFieldTags(field domain.FieldSpecification) string {
	jsonTag := fmt.Sprintf(`json:"%s"`, strings.ToLower(field.Name))
	dbTag := fmt.Sprintf(`db:"%s"`, strings.ToLower(field.Name))

	tags := []string{jsonTag, dbTag}

	// Add validation tags
	if len(field.Validation) > 0 {
		validateTag := fmt.Sprintf(`validate:"%s"`, strings.Join(field.Validation, ","))
		tags = append(tags, validateTag)
	}

	return strings.Join(tags, " ")
}

func (s *OrchestratorService) capitalizeFirst(str string) string {
	if len(str) == 0 {
		return str
	}
	return strings.ToUpper(string(str[0])) + str[1:]
}

func (s *OrchestratorService) generateConstructorBody(entity domain.EntitySpecification, parameters []domain.ParameterElement) string {
	var assignments []string
	assignments = append(assignments, "ID: uuid.New().String()")

	for _, param := range parameters {
		fieldName := s.capitalizeFirst(param.Name)
		assignments = append(assignments, fmt.Sprintf("%s: %s", fieldName, param.Name))
	}

	assignments = append(assignments, "CreatedAt: time.Now()")
	assignments = append(assignments, "UpdatedAt: time.Now()")

	return fmt.Sprintf("return &%s{\n\t\t%s,\n\t}", entity.Name, strings.Join(assignments, ",\n\t\t"))
}

func (s *OrchestratorService) generateValidationBody(entity domain.EntitySpecification) string {
	var validations []string

	for _, field := range entity.Fields {
		if field.Required {
			fieldName := s.capitalizeFirst(field.Name)
			switch field.Type {
			case "string", "email":
				validations = append(validations,
					fmt.Sprintf(`if %s.%s == "" {
		return fmt.Errorf("%s is required")
	}`, strings.ToLower(entity.Name), fieldName, field.Name))
			}
		}

		// Add custom validations
		for _, validation := range field.Validation {
			if validation == "email" {
				fieldName := s.capitalizeFirst(field.Name)
				validations = append(validations,
					fmt.Sprintf(`if !isValidEmail(%s.%s) {
		return fmt.Errorf("invalid email format")
	}`, strings.ToLower(entity.Name), fieldName))
			}
		}
	}

	if len(validations) == 0 {
		return "return nil"
	}

	return strings.Join(validations, "\n\t") + "\n\treturn nil"
}

func (s *OrchestratorService) getConstructorParams(entity domain.EntitySpecification) string {
	var params []string
	for _, field := range entity.Fields {
		if field.Required && strings.ToLower(field.Name) != "id" {
			params = append(params, strings.ToLower(field.Name))
		}
	}
	return strings.Join(params, ", ")
}
