package application

import (
	"context"
	"fmt"
	"strings"
	"time"

	"go-factory-platform/services/generator-service/internal/domain"
)

// CodeGenerationVisitor implements the visitor pattern for code generation
type CodeGenerationVisitor struct {
	accumulator    *domain.CodeAccumulator
	templateClient domain.TemplateServiceClient
	modulePath     string
	outputPath     string
	packageName    string
}

// NewCodeGenerationVisitor creates a new code generation visitor
func NewCodeGenerationVisitor(
	templateClient domain.TemplateServiceClient,
	modulePath, outputPath, packageName string,
) *CodeGenerationVisitor {
	return &CodeGenerationVisitor{
		accumulator: &domain.CodeAccumulator{
			Files:     []domain.GeneratedFile{},
			Metadata:  make(map[string]string),
			CreatedAt: time.Now(),
		},
		templateClient: templateClient,
		modulePath:     modulePath,
		outputPath:     outputPath,
		packageName:    packageName,
	}
}

// GetAccumulator returns the code accumulator
func (v *CodeGenerationVisitor) GetAccumulator() *domain.CodeAccumulator {
	return v.accumulator
}

// VisitRepository generates code for a repository element
func (v *CodeGenerationVisitor) VisitRepository(ctx context.Context, element *domain.RepositoryElement) error {
	fmt.Printf("Visiting repository: %s\n", element.Name)

	// Prepare template parameters
	parameters := map[string]string{
		"EntityName":    element.EntityName,
		"EntityVarName": strings.ToLower(element.EntityName),
		"ModulePath":    v.modulePath,
		"PackageName":   element.Package,
	}

	// Merge with element parameters
	for k, v := range element.Parameters {
		parameters[k] = v
	}

	// Process template
	generatedCode, err := v.templateClient.ProcessTemplate(ctx, "repository_template", parameters)
	if err != nil {
		return fmt.Errorf("failed to process repository template: %w", err)
	}

	// Create generated file
	fileName := fmt.Sprintf("%s_repository.go", strings.ToLower(element.EntityName))
	filePath := fmt.Sprintf("internal/infrastructure/repository/%s", fileName)

	file := domain.GeneratedFile{
		Path:    filePath,
		Content: generatedCode,
		Package: element.Package,
		Type:    "repository",
		Size:    int64(len(generatedCode)),
	}

	v.accumulator.AddFile(file)
	return nil
}

// VisitService generates code for a service element
func (v *CodeGenerationVisitor) VisitService(ctx context.Context, element *domain.ServiceElement) error {
	fmt.Printf("Visiting service: %s\n", element.Name)

	// Prepare template parameters
	parameters := map[string]string{
		"EntityName":    element.EntityName,
		"EntityVarName": strings.ToLower(element.EntityName),
		"ModulePath":    v.modulePath,
		"PackageName":   element.Package,
	}

	// Merge with element parameters
	for k, v := range element.Parameters {
		parameters[k] = v
	}

	// Process template
	generatedCode, err := v.templateClient.ProcessTemplate(ctx, "service_template", parameters)
	if err != nil {
		return fmt.Errorf("failed to process service template: %w", err)
	}

	// Create generated file
	fileName := fmt.Sprintf("%s_service.go", strings.ToLower(element.EntityName))
	filePath := fmt.Sprintf("internal/application/%s", fileName)

	file := domain.GeneratedFile{
		Path:    filePath,
		Content: generatedCode,
		Package: element.Package,
		Type:    "service",
		Size:    int64(len(generatedCode)),
	}

	v.accumulator.AddFile(file)
	return nil
}

// VisitHandler generates code for a handler element
func (v *CodeGenerationVisitor) VisitHandler(ctx context.Context, element *domain.HandlerElement) error {
	fmt.Printf("Visiting handler: %s\n", element.Name)

	// Prepare template parameters
	parameters := map[string]string{
		"EntityName":      element.EntityName,
		"EntityVarName":   strings.ToLower(element.EntityName),
		"EntityNameLower": strings.ToLower(element.EntityName),
		"ModulePath":      v.modulePath,
		"PackageName":     element.Package,
	}

	// Merge with element parameters
	for k, v := range element.Parameters {
		parameters[k] = v
	}

	// Process template
	generatedCode, err := v.templateClient.ProcessTemplate(ctx, "handler_template", parameters)
	if err != nil {
		return fmt.Errorf("failed to process handler template: %w", err)
	}

	// Create generated file
	fileName := fmt.Sprintf("%s_handler.go", strings.ToLower(element.EntityName))
	filePath := fmt.Sprintf("internal/interfaces/http/handlers/%s", fileName)

	file := domain.GeneratedFile{
		Path:    filePath,
		Content: generatedCode,
		Package: element.Package,
		Type:    "handler",
		Size:    int64(len(generatedCode)),
	}

	v.accumulator.AddFile(file)
	return nil
}

// VisitModel generates code for a model element
func (v *CodeGenerationVisitor) VisitModel(ctx context.Context, element *domain.ModelElement) error {
	fmt.Printf("Visiting model: %s\n", element.Name)

	// Prepare template parameters
	parameters := map[string]string{
		"ModelName":   element.Name,
		"PackageName": element.Package,
		"ModulePath":  v.modulePath,
	}

	// Add fields information
	var fieldsStr strings.Builder
	for _, field := range element.Fields {
		fieldsStr.WriteString(fmt.Sprintf("    %s %s", field.Name, field.Type))
		if field.Tags != "" {
			fieldsStr.WriteString(fmt.Sprintf(" `%s`", field.Tags))
		}
		fieldsStr.WriteString("\n")
	}
	parameters["Fields"] = fieldsStr.String()

	// Merge with element parameters
	for k, v := range element.Parameters {
		parameters[k] = v
	}

	// Create simple model template
	modelTemplate := `package {{.PackageName}}

import (
	"time"
)

// {{.ModelName}} represents the {{.ModelName}} entity
type {{.ModelName}} struct {
{{.Fields}}}

// TableName returns the table name for GORM
func ({{.ModelName}}) TableName() string {
	return "{{.ModelNameLower}}"
}`

	// For now, process template locally since we have a simple case
	generatedCode := modelTemplate
	for k, v := range parameters {
		placeholder := fmt.Sprintf("{{.%s}}", k)
		generatedCode = strings.ReplaceAll(generatedCode, placeholder, v)
	}

	// Also replace ModelNameLower
	generatedCode = strings.ReplaceAll(generatedCode, "{{.ModelNameLower}}", strings.ToLower(element.Name))

	// Create generated file
	fileName := fmt.Sprintf("%s.go", strings.ToLower(element.Name))
	filePath := fmt.Sprintf("internal/domain/%s", fileName)

	file := domain.GeneratedFile{
		Path:    filePath,
		Content: generatedCode,
		Package: element.Package,
		Type:    "model",
		Size:    int64(len(generatedCode)),
	}

	v.accumulator.AddFile(file)
	return nil
}

// VisitInterface generates code for an interface element
func (v *CodeGenerationVisitor) VisitInterface(ctx context.Context, element *domain.InterfaceElement) error {
	fmt.Printf("Visiting interface: %s\n", element.Name)

	// Prepare methods string
	var methodsStr strings.Builder
	for _, method := range element.Methods {
		methodsStr.WriteString(fmt.Sprintf("    %s(", method.Name))

		// Add parameters
		for i, param := range method.Parameters {
			if i > 0 {
				methodsStr.WriteString(", ")
			}
			methodsStr.WriteString(fmt.Sprintf("%s %s", param.Name, param.Type))
		}

		methodsStr.WriteString(")")

		// Add return types
		if len(method.Returns) > 0 {
			methodsStr.WriteString(" ")
			if len(method.Returns) > 1 {
				methodsStr.WriteString("(")
			}
			for i, ret := range method.Returns {
				if i > 0 {
					methodsStr.WriteString(", ")
				}
				methodsStr.WriteString(ret.Type)
			}
			if len(method.Returns) > 1 {
				methodsStr.WriteString(")")
			}
		}

		methodsStr.WriteString("\n")
	}

	// Create interface template
	interfaceTemplate := `package {{.PackageName}}

// {{.InterfaceName}} defines the interface for {{.InterfaceName}}
type {{.InterfaceName}} interface {
{{.Methods}}}`

	// Process template
	parameters := map[string]string{
		"InterfaceName": element.Name,
		"PackageName":   element.Package,
		"Methods":       methodsStr.String(),
	}

	generatedCode := interfaceTemplate
	for k, v := range parameters {
		placeholder := fmt.Sprintf("{{.%s}}", k)
		generatedCode = strings.ReplaceAll(generatedCode, placeholder, v)
	}

	// Create generated file
	fileName := fmt.Sprintf("%s.go", strings.ToLower(element.Name))
	filePath := fmt.Sprintf("internal/domain/%s", fileName)

	file := domain.GeneratedFile{
		Path:    filePath,
		Content: generatedCode,
		Package: element.Package,
		Type:    "interface",
		Size:    int64(len(generatedCode)),
	}

	v.accumulator.AddFile(file)
	return nil
}

// VisitStruct generates code for a struct element
func (v *CodeGenerationVisitor) VisitStruct(ctx context.Context, element *domain.StructElement) error {
	fmt.Printf("Visiting struct: %s\n", element.Name)

	// Prepare fields string
	var fieldsStr strings.Builder
	for _, field := range element.Fields {
		fieldsStr.WriteString(fmt.Sprintf("\t%s %s", field.Name, field.Type))
		if field.Tags != "" {
			fieldsStr.WriteString(fmt.Sprintf(" `%s`", field.Tags))
		}
		fieldsStr.WriteString("\n")
	}

	// Create struct template
	structTemplate := `package {{.PackageName}}

// {{.StructName}} represents a {{.StructName}}
type {{.StructName}} struct {
{{.Fields}}}`

	// Process template
	parameters := map[string]string{
		"StructName":  element.Name,
		"PackageName": element.Package,
		"Fields":      fieldsStr.String(),
	}

	generatedCode := structTemplate
	for k, v := range parameters {
		placeholder := fmt.Sprintf("{{.%s}}", k)
		generatedCode = strings.ReplaceAll(generatedCode, placeholder, v)
	}

	// Create generated file
	fileName := fmt.Sprintf("%s.go", strings.ToLower(element.Name))
	filePath := fmt.Sprintf("internal/domain/%s", fileName)

	file := domain.GeneratedFile{
		Path:    filePath,
		Content: generatedCode,
		Package: element.Package,
		Type:    "struct",
		Size:    int64(len(generatedCode)),
	}

	v.accumulator.AddFile(file)
	return nil
}

// VisitFunction generates code for a function element
func (v *CodeGenerationVisitor) VisitFunction(ctx context.Context, element *domain.FunctionElement) error {
	fmt.Printf("Visiting function: %s\n", element.Name)

	// Prepare parameters string
	var paramsStr strings.Builder
	for i, param := range element.Parameters {
		if i > 0 {
			paramsStr.WriteString(", ")
		}
		paramsStr.WriteString(fmt.Sprintf("%s %s", param.Name, param.Type))
	}

	// Prepare return types string
	var returnsStr string
	if len(element.Returns) > 0 {
		if len(element.Returns) == 1 {
			returnsStr = element.Returns[0].Type
		} else {
			returnsStr = "("
			for i, ret := range element.Returns {
				if i > 0 {
					returnsStr += ", "
				}
				returnsStr += ret.Type
			}
			returnsStr += ")"
		}
	}

	// Create function template
	functionTemplate := `package {{.PackageName}}

{{.Imports}}

// {{.FunctionName}} {{.Description}}
func {{.FunctionName}}({{.Parameters}}) {{.Returns}} {
	{{.Body}}
}`

	// Detect imports needed based on return types and body
	var imports strings.Builder
	importsNeeded := make(map[string]bool)

	// Check return types for cross-package references
	for _, ret := range element.Returns {
		if strings.Contains(ret.Type, "domain.") && element.Package != "domain" {
			importsNeeded["go-factory-platform/services/compiler-builder-service/generated/internal/domain"] = true
		}
		if strings.Contains(ret.Type, "application.") && element.Package != "application" {
			importsNeeded["go-factory-platform/services/compiler-builder-service/generated/internal/application"] = true
		}
	}

	// Check body for cross-package references
	if strings.Contains(element.Body, "domain.") && element.Package != "domain" {
		importsNeeded["go-factory-platform/services/compiler-builder-service/generated/internal/domain"] = true
	}
	if strings.Contains(element.Body, "application.") && element.Package != "application" {
		importsNeeded["go-factory-platform/services/compiler-builder-service/generated/internal/application"] = true
	}

	// Build imports block if needed
	if len(importsNeeded) > 0 {
		imports.WriteString("import (\n")
		for imp := range importsNeeded {
			imports.WriteString(fmt.Sprintf("\t\"%s\"\n", imp))
		}
		imports.WriteString(")")
	}

	// Process template
	parameters := map[string]string{
		"FunctionName": element.Name,
		"PackageName":  element.Package,
		"Parameters":   paramsStr.String(),
		"Returns":      returnsStr,
		"Body":         element.Body,
		"Description":  fmt.Sprintf("implements %s", element.Name),
		"Imports":      imports.String(),
	}

	generatedCode := functionTemplate
	for k, v := range parameters {
		placeholder := fmt.Sprintf("{{.%s}}", k)
		generatedCode = strings.ReplaceAll(generatedCode, placeholder, v)
	}

	// Create generated file
	fileName := fmt.Sprintf("%s.go", strings.ToLower(element.Name))
	filePath := fmt.Sprintf("internal/application/%s", fileName)

	file := domain.GeneratedFile{
		Path:    filePath,
		Content: generatedCode,
		Package: element.Package,
		Type:    "function",
		Size:    int64(len(generatedCode)),
	}

	v.accumulator.AddFile(file)
	return nil
}
