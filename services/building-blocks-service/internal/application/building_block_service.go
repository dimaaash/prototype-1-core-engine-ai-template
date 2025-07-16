package application

import (
	"fmt"
	"time"

	"go-factory-platform/services/building-blocks-service/internal/domain"

	"github.com/google/uuid"
)

// BuildingBlockApplicationService implements the business logic for building blocks
type BuildingBlockApplicationService struct {
	buildingBlockService domain.BuildingBlockService
	codeElementBuilder   domain.CodeElementBuilder
}

// NewBuildingBlockApplicationService creates a new building block application service
func NewBuildingBlockApplicationService(
	buildingBlockService domain.BuildingBlockService,
	codeElementBuilder domain.CodeElementBuilder,
) *BuildingBlockApplicationService {
	return &BuildingBlockApplicationService{
		buildingBlockService: buildingBlockService,
		codeElementBuilder:   codeElementBuilder,
	}
}

// CreateBuildingBlock creates a new building block
func (s *BuildingBlockApplicationService) CreateBuildingBlock(block *domain.BuildingBlock) error {
	if block.ID == "" {
		block.ID = uuid.New().String()
	}
	block.CreatedAt = time.Now()
	block.UpdatedAt = time.Now()

	return s.buildingBlockService.CreateBuildingBlock(block)
}

// GetBuildingBlock retrieves a building block by ID
func (s *BuildingBlockApplicationService) GetBuildingBlock(id string) (*domain.BuildingBlock, error) {
	return s.buildingBlockService.GetBuildingBlock(id)
}

// GetPrimitiveBlocks returns all primitive Go building blocks
func (s *BuildingBlockApplicationService) GetPrimitiveBlocks() ([]*domain.BuildingBlock, error) {
	return s.buildingBlockService.ListAllBuildingBlocks()
}

// CreateVariableBlock creates a variable building block
func (s *BuildingBlockApplicationService) CreateVariableBlock(name, typeName, defaultValue string) (*domain.BuildingBlock, error) {
	template := fmt.Sprintf("var %s %s", "{{.Name}}", "{{.Type}}")
	if defaultValue != "" {
		template = fmt.Sprintf("var %s %s = %s", "{{.Name}}", "{{.Type}}", "{{.DefaultValue}}")
	}

	block := &domain.BuildingBlock{
		ID:          uuid.New().String(),
		Type:        domain.TypeVariable,
		Name:        name,
		Description: fmt.Sprintf("Variable of type %s", typeName),
		Template:    template,
		Parameters: map[string]string{
			"Name":         name,
			"Type":         typeName,
			"DefaultValue": defaultValue,
		},
		Examples:  []string{fmt.Sprintf("var %s %s", name, typeName)},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	return block, s.buildingBlockService.CreateBuildingBlock(block)
}

// CreateStructBlock creates a struct building block
func (s *BuildingBlockApplicationService) CreateStructBlock(name, pkg string, fields []domain.GoVariable) (*domain.BuildingBlock, error) {
	template := `type {{.Name}} struct {
{{range .Fields}}    {{.Name}} {{.Type.Name}} {{.Tags}}
{{end}}}`

	block := &domain.BuildingBlock{
		ID:          uuid.New().String(),
		Type:        domain.TypeStruct,
		Name:        name,
		Description: fmt.Sprintf("Struct %s with %d fields", name, len(fields)),
		Template:    template,
		Parameters: map[string]string{
			"Name":    name,
			"Package": pkg,
		},
		Examples:  []string{fmt.Sprintf("type %s struct { ... }", name)},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	return block, s.buildingBlockService.CreateBuildingBlock(block)
}

// CreateInterfaceBlock creates an interface building block
func (s *BuildingBlockApplicationService) CreateInterfaceBlock(name, pkg string, methods []domain.GoMethod) (*domain.BuildingBlock, error) {
	template := `type {{.Name}} interface {
{{range .Methods}}    {{.Name}}({{range .Parameters}}{{.Name}} {{.Type.Name}}{{end}}) {{range .Returns}}{{.Name}}{{end}}
{{end}}}`

	block := &domain.BuildingBlock{
		ID:          uuid.New().String(),
		Type:        domain.TypeInterface,
		Name:        name,
		Description: fmt.Sprintf("Interface %s with %d methods", name, len(methods)),
		Template:    template,
		Parameters: map[string]string{
			"Name":    name,
			"Package": pkg,
		},
		Examples:  []string{fmt.Sprintf("type %s interface { ... }", name)},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	return block, s.buildingBlockService.CreateBuildingBlock(block)
}

// CreateFunctionBlock creates a function building block
func (s *BuildingBlockApplicationService) CreateFunctionBlock(name, pkg string, params []domain.GoVariable, returns []domain.GoType, body string) (*domain.BuildingBlock, error) {
	template := `func {{.Name}}({{range .Parameters}}{{.Name}} {{.Type.Name}}{{end}}) {{range .Returns}}{{.Name}}{{end}} {
    {{.Body}}
}`

	block := &domain.BuildingBlock{
		ID:          uuid.New().String(),
		Type:        domain.TypeFunction,
		Name:        name,
		Description: fmt.Sprintf("Function %s with %d parameters", name, len(params)),
		Template:    template,
		Parameters: map[string]string{
			"Name":    name,
			"Package": pkg,
			"Body":    body,
		},
		Examples:  []string{fmt.Sprintf("func %s() { ... }", name)},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	return block, s.buildingBlockService.CreateBuildingBlock(block)
}

// BuildGoVariable builds a Go variable using the code element builder
func (s *BuildingBlockApplicationService) BuildGoVariable(name, typeName, value string) *domain.GoVariable {
	return s.codeElementBuilder.BuildVariable(name, typeName, value)
}

// BuildGoStruct builds a Go struct using the code element builder
func (s *BuildingBlockApplicationService) BuildGoStruct(name, pkg string, fields []domain.GoVariable) *domain.GoStruct {
	return s.codeElementBuilder.BuildStruct(name, pkg, fields)
}

// BuildGoInterface builds a Go interface using the code element builder
func (s *BuildingBlockApplicationService) BuildGoInterface(name, pkg string, methods []domain.GoMethod) *domain.GoInterface {
	return s.codeElementBuilder.BuildInterface(name, pkg, methods)
}

// BuildGoFunction builds a Go function using the code element builder
func (s *BuildingBlockApplicationService) BuildGoFunction(name, pkg string, params []domain.GoVariable, returns []domain.GoType, body string) *domain.GoFunction {
	return s.codeElementBuilder.BuildFunction(name, pkg, params, returns, body)
}
