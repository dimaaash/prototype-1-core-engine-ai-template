package domain

import (
	"context"
	"time"
)

// CodeElement represents any code element that can accept a visitor
type CodeElement interface {
	Accept(visitor CodeElementVisitor) error
	GetType() string
	GetName() string
}

// CodeElementVisitor defines operations that can be performed on code elements
type CodeElementVisitor interface {
	VisitRepository(ctx context.Context, element *RepositoryElement) error
	VisitService(ctx context.Context, element *ServiceElement) error
	VisitHandler(ctx context.Context, element *HandlerElement) error
	VisitModel(ctx context.Context, element *ModelElement) error
	VisitInterface(ctx context.Context, element *InterfaceElement) error
	VisitStruct(ctx context.Context, element *StructElement) error
	VisitFunction(ctx context.Context, element *FunctionElement) error
}

// RepositoryElement represents a repository code element
type RepositoryElement struct {
	Name       string            `json:"name"`
	EntityName string            `json:"entity_name"`
	Package    string            `json:"package"`
	Methods    []string          `json:"methods"`
	Parameters map[string]string `json:"parameters"`
	Metadata   map[string]string `json:"metadata"`
}

func (r *RepositoryElement) Accept(visitor CodeElementVisitor) error {
	return visitor.VisitRepository(context.Background(), r)
}

func (r *RepositoryElement) GetType() string { return "repository" }
func (r *RepositoryElement) GetName() string { return r.Name }

// ServiceElement represents a service code element
type ServiceElement struct {
	Name       string            `json:"name"`
	EntityName string            `json:"entity_name"`
	Package    string            `json:"package"`
	Methods    []string          `json:"methods"`
	Parameters map[string]string `json:"parameters"`
	Metadata   map[string]string `json:"metadata"`
}

func (s *ServiceElement) Accept(visitor CodeElementVisitor) error {
	return visitor.VisitService(context.Background(), s)
}

func (s *ServiceElement) GetType() string { return "service" }
func (s *ServiceElement) GetName() string { return s.Name }

// HandlerElement represents a handler code element
type HandlerElement struct {
	Name       string            `json:"name"`
	EntityName string            `json:"entity_name"`
	Package    string            `json:"package"`
	Routes     []string          `json:"routes"`
	Parameters map[string]string `json:"parameters"`
	Metadata   map[string]string `json:"metadata"`
}

func (h *HandlerElement) Accept(visitor CodeElementVisitor) error {
	return visitor.VisitHandler(context.Background(), h)
}

func (h *HandlerElement) GetType() string { return "handler" }
func (h *HandlerElement) GetName() string { return h.Name }

// ModelElement represents a model code element
type ModelElement struct {
	Name       string            `json:"name"`
	Package    string            `json:"package"`
	Fields     []FieldElement    `json:"fields"`
	Parameters map[string]string `json:"parameters"`
	Metadata   map[string]string `json:"metadata"`
}

func (m *ModelElement) Accept(visitor CodeElementVisitor) error {
	return visitor.VisitModel(context.Background(), m)
}

func (m *ModelElement) GetType() string { return "model" }
func (m *ModelElement) GetName() string { return m.Name }

// InterfaceElement represents an interface code element
type InterfaceElement struct {
	Name       string            `json:"name"`
	Package    string            `json:"package"`
	Methods    []MethodElement   `json:"methods"`
	Parameters map[string]string `json:"parameters"`
	Metadata   map[string]string `json:"metadata"`
}

func (i *InterfaceElement) Accept(visitor CodeElementVisitor) error {
	return visitor.VisitInterface(context.Background(), i)
}

func (i *InterfaceElement) GetType() string { return "interface" }
func (i *InterfaceElement) GetName() string { return i.Name }

// StructElement represents a struct code element
type StructElement struct {
	Name       string            `json:"name"`
	Package    string            `json:"package"`
	Fields     []FieldElement    `json:"fields"`
	Parameters map[string]string `json:"parameters"`
	Metadata   map[string]string `json:"metadata"`
}

func (s *StructElement) Accept(visitor CodeElementVisitor) error {
	return visitor.VisitStruct(context.Background(), s)
}

func (s *StructElement) GetType() string { return "struct" }
func (s *StructElement) GetName() string { return s.Name }

// FunctionElement represents a function code element
type FunctionElement struct {
	Name       string             `json:"name"`
	Package    string             `json:"package"`
	Parameters []ParameterElement `json:"parameters"`
	Returns    []ReturnElement    `json:"returns"`
	Body       string             `json:"body"`
	Metadata   map[string]string  `json:"metadata"`
}

func (f *FunctionElement) Accept(visitor CodeElementVisitor) error {
	return visitor.VisitFunction(context.Background(), f)
}

func (f *FunctionElement) GetType() string { return "function" }
func (f *FunctionElement) GetName() string { return f.Name }

// Supporting types
type FieldElement struct {
	Name string `json:"name"`
	Type string `json:"type"`
	Tags string `json:"tags,omitempty"`
}

type MethodElement struct {
	Name       string             `json:"name"`
	Parameters []ParameterElement `json:"parameters"`
	Returns    []ReturnElement    `json:"returns"`
}

type ParameterElement struct {
	Name string `json:"name"`
	Type string `json:"type"`
}

type ReturnElement struct {
	Type string `json:"type"`
}

// GeneratedFile represents a generated code file
type GeneratedFile struct {
	Path    string `json:"path"`
	Content string `json:"content"`
	Package string `json:"package"`
	Type    string `json:"type"`
	Size    int64  `json:"size"`
}

// CodeAccumulator accumulates generated code files
type CodeAccumulator struct {
	Files     []GeneratedFile   `json:"files"`
	Metadata  map[string]string `json:"metadata"`
	CreatedAt time.Time         `json:"created_at"`
}

// AddFile adds a generated file to the accumulator
func (a *CodeAccumulator) AddFile(file GeneratedFile) {
	a.Files = append(a.Files, file)
}

// GetFilesByType returns files of a specific type
func (a *CodeAccumulator) GetFilesByType(fileType string) []GeneratedFile {
	var result []GeneratedFile
	for _, file := range a.Files {
		if file.Type == fileType {
			result = append(result, file)
		}
	}
	return result
}

// GetTotalSize returns the total size of all files
func (a *CodeAccumulator) GetTotalSize() int64 {
	var total int64
	for _, file := range a.Files {
		total += file.Size
	}
	return total
}

// GenerationRequest represents a code generation request
type GenerationRequest struct {
	ID              string                   `json:"id"`
	Elements        []CodeElement            `json:"-"`        // Excluded from JSON
	RawElements     []map[string]interface{} `json:"elements"` // For JSON unmarshaling
	ModulePath      string                   `json:"module_path"`
	OutputPath      string                   `json:"output_path"`
	PackageName     string                   `json:"package_name"`
	TemplateService string                   `json:"template_service_url"`
	CompilerService string                   `json:"compiler_service_url"`
	Parameters      map[string]string        `json:"parameters"`
	CreatedAt       time.Time                `json:"created_at"`
}

// ParseElements converts raw elements to concrete CodeElement types
func (r *GenerationRequest) ParseElements() error {
	r.Elements = make([]CodeElement, 0, len(r.RawElements))

	for _, rawElement := range r.RawElements {
		elementType, ok := rawElement["type"].(string)
		if !ok {
			continue // Skip elements without type
		}

		var element CodeElement
		switch elementType {
		case "model":
			element = parseModelElement(rawElement)
		case "repository":
			element = parseRepositoryElement(rawElement)
		case "service":
			element = parseServiceElement(rawElement)
		case "handler":
			element = parseHandlerElement(rawElement)
		case "interface":
			element = parseInterfaceElement(rawElement)
		case "struct":
			element = parseStructElement(rawElement)
		case "function":
			element = parseFunctionElement(rawElement)
		default:
			continue // Skip unknown types
		}

		if element != nil {
			r.Elements = append(r.Elements, element)
		}
	}

	return nil
}

// Helper functions to parse different element types
func parseModelElement(raw map[string]interface{}) *ModelElement {
	element := &ModelElement{}

	if name, ok := raw["name"].(string); ok {
		element.Name = name
	}
	if pkg, ok := raw["package"].(string); ok {
		element.Package = pkg
	}

	// Parse fields
	if fieldsRaw, ok := raw["fields"].([]interface{}); ok {
		for _, fieldRaw := range fieldsRaw {
			if fieldMap, ok := fieldRaw.(map[string]interface{}); ok {
				field := FieldElement{}
				if name, ok := fieldMap["name"].(string); ok {
					field.Name = name
				}
				if typ, ok := fieldMap["type"].(string); ok {
					field.Type = typ
				}
				if tags, ok := fieldMap["tags"].(string); ok {
					field.Tags = tags
				}
				element.Fields = append(element.Fields, field)
			}
		}
	}

	// Parse metadata
	if metadataRaw, ok := raw["metadata"].(map[string]interface{}); ok {
		element.Metadata = make(map[string]string)
		for k, v := range metadataRaw {
			if str, ok := v.(string); ok {
				element.Metadata[k] = str
			}
		}
	}

	return element
}

func parseRepositoryElement(raw map[string]interface{}) *RepositoryElement {
	element := &RepositoryElement{}

	if name, ok := raw["name"].(string); ok {
		element.Name = name
	}
	if entityName, ok := raw["entity_name"].(string); ok {
		element.EntityName = entityName
	}
	if pkg, ok := raw["package"].(string); ok {
		element.Package = pkg
	}

	return element
}

func parseServiceElement(raw map[string]interface{}) *ServiceElement {
	element := &ServiceElement{}

	if name, ok := raw["name"].(string); ok {
		element.Name = name
	}
	if entityName, ok := raw["entity_name"].(string); ok {
		element.EntityName = entityName
	}
	if pkg, ok := raw["package"].(string); ok {
		element.Package = pkg
	}

	return element
}

func parseHandlerElement(raw map[string]interface{}) *HandlerElement {
	element := &HandlerElement{}

	if name, ok := raw["name"].(string); ok {
		element.Name = name
	}
	if entityName, ok := raw["entity_name"].(string); ok {
		element.EntityName = entityName
	}
	if pkg, ok := raw["package"].(string); ok {
		element.Package = pkg
	}

	return element
}

func parseInterfaceElement(raw map[string]interface{}) *InterfaceElement {
	element := &InterfaceElement{}

	if name, ok := raw["name"].(string); ok {
		element.Name = name
	}
	if pkg, ok := raw["package"].(string); ok {
		element.Package = pkg
	}

	return element
}

func parseStructElement(raw map[string]interface{}) *StructElement {
	element := &StructElement{}

	if name, ok := raw["name"].(string); ok {
		element.Name = name
	}
	if pkg, ok := raw["package"].(string); ok {
		element.Package = pkg
	}

	// Parse fields
	if fieldsRaw, ok := raw["fields"].([]interface{}); ok {
		for _, fieldRaw := range fieldsRaw {
			if fieldMap, ok := fieldRaw.(map[string]interface{}); ok {
				field := FieldElement{}
				if name, ok := fieldMap["name"].(string); ok {
					field.Name = name
				}
				if typ, ok := fieldMap["type"].(string); ok {
					field.Type = typ
				}
				if tags, ok := fieldMap["tags"].(string); ok {
					field.Tags = tags
				}
				element.Fields = append(element.Fields, field)
			}
		}
	}

	return element
}

func parseFunctionElement(raw map[string]interface{}) *FunctionElement {
	element := &FunctionElement{}

	if name, ok := raw["name"].(string); ok {
		element.Name = name
	}
	if pkg, ok := raw["package"].(string); ok {
		element.Package = pkg
	}
	if body, ok := raw["body"].(string); ok {
		element.Body = body
	}

	// Parse parameters
	if paramsRaw, ok := raw["parameters"].([]interface{}); ok {
		for _, paramRaw := range paramsRaw {
			if paramMap, ok := paramRaw.(map[string]interface{}); ok {
				param := ParameterElement{}
				if name, ok := paramMap["name"].(string); ok {
					param.Name = name
				}
				if typ, ok := paramMap["type"].(string); ok {
					param.Type = typ
				}
				element.Parameters = append(element.Parameters, param)
			}
		}
	}

	// Parse returns
	if returnsRaw, ok := raw["returns"].([]interface{}); ok {
		for _, retRaw := range returnsRaw {
			if retMap, ok := retRaw.(map[string]interface{}); ok {
				ret := ReturnElement{}
				if typ, ok := retMap["type"].(string); ok {
					ret.Type = typ
				}
				element.Returns = append(element.Returns, ret)
			}
		}
	}

	return element
}

// GenerationResult represents the result of code generation
type GenerationResult struct {
	ID           string          `json:"id"`
	RequestID    string          `json:"request_id"`
	Accumulator  CodeAccumulator `json:"accumulator"`
	Success      bool            `json:"success"`
	ErrorMessage string          `json:"error_message,omitempty"`
	CompletedAt  time.Time       `json:"completed_at"`
}

// GeneratorService defines the interface for the generator service
type GeneratorService interface {
	GenerateCode(ctx context.Context, request *GenerationRequest) (*GenerationResult, error)
	ProcessElements(ctx context.Context, elements []CodeElement, visitor CodeElementVisitor) error
}

// TemplateServiceClient defines the interface for communicating with template-service
type TemplateServiceClient interface {
	ProcessTemplate(ctx context.Context, templateID string, parameters map[string]string) (string, error)
	GetTemplate(ctx context.Context, templateID string) (interface{}, error)
}

// CompilerServiceClient defines the interface for communicating with compiler-builder-service
type CompilerServiceClient interface {
	WriteFiles(ctx context.Context, accumulator *CodeAccumulator, outputPath string) error
	CompileProject(ctx context.Context, projectPath string) error
	ValidateCode(ctx context.Context, files []GeneratedFile) error
}
