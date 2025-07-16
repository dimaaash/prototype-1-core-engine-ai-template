package domain

import "time"

// BuildingBlockType represents the type of building block
type BuildingBlockType string

const (
	TypeVariable    BuildingBlockType = "variable"
	TypeStruct      BuildingBlockType = "struct"
	TypeInterface   BuildingBlockType = "interface"
	TypeFunction    BuildingBlockType = "function"
	TypeMethod      BuildingBlockType = "method"
	TypeMap         BuildingBlockType = "map"
	TypeSlice       BuildingBlockType = "slice"
	TypeChannel     BuildingBlockType = "channel"
	TypeGoroutine   BuildingBlockType = "goroutine"
	TypeIfStatement BuildingBlockType = "if"
	TypeForLoop     BuildingBlockType = "for"
	TypeSwitch      BuildingBlockType = "switch"
)

// BuildingBlock represents a primitive Go code concept
type BuildingBlock struct {
	ID          string            `json:"id"`
	Type        BuildingBlockType `json:"type"`
	Name        string            `json:"name"`
	Description string            `json:"description"`
	Template    string            `json:"template"`
	Parameters  map[string]string `json:"parameters"`
	Examples    []string          `json:"examples"`
	CreatedAt   time.Time         `json:"created_at"`
	UpdatedAt   time.Time         `json:"updated_at"`
}

// GoType represents a Go data type
type GoType struct {
	Name        string `json:"name"`
	Package     string `json:"package"`
	IsPointer   bool   `json:"is_pointer"`
	IsSlice     bool   `json:"is_slice"`
	IsMap       bool   `json:"is_map"`
	KeyType     string `json:"key_type,omitempty"`
	ElementType string `json:"element_type,omitempty"`
}

// GoVariable represents a Go variable
type GoVariable struct {
	Name         string `json:"name"`
	Type         GoType `json:"type"`
	DefaultValue string `json:"default_value,omitempty"`
	Tags         string `json:"tags,omitempty"`
	Comments     string `json:"comments,omitempty"`
}

// GoStruct represents a Go struct
type GoStruct struct {
	Name        string       `json:"name"`
	Package     string       `json:"package"`
	Fields      []GoVariable `json:"fields"`
	Methods     []GoMethod   `json:"methods"`
	Comments    string       `json:"comments,omitempty"`
	Annotations []string     `json:"annotations,omitempty"`
}

// GoInterface represents a Go interface
type GoInterface struct {
	Name     string     `json:"name"`
	Package  string     `json:"package"`
	Methods  []GoMethod `json:"methods"`
	Comments string     `json:"comments,omitempty"`
}

// GoMethod represents a Go method
type GoMethod struct {
	Name       string       `json:"name"`
	Receiver   *GoVariable  `json:"receiver,omitempty"`
	Parameters []GoVariable `json:"parameters"`
	Returns    []GoType     `json:"returns"`
	Body       string       `json:"body,omitempty"`
	Comments   string       `json:"comments,omitempty"`
}

// GoFunction represents a Go function
type GoFunction struct {
	Name       string       `json:"name"`
	Package    string       `json:"package"`
	Parameters []GoVariable `json:"parameters"`
	Returns    []GoType     `json:"returns"`
	Body       string       `json:"body"`
	Comments   string       `json:"comments,omitempty"`
}

// BuildingBlockService defines the interface for building block operations
type BuildingBlockService interface {
	CreateBuildingBlock(block *BuildingBlock) error
	GetBuildingBlock(id string) (*BuildingBlock, error)
	GetBuildingBlocksByType(blockType BuildingBlockType) ([]*BuildingBlock, error)
	UpdateBuildingBlock(block *BuildingBlock) error
	DeleteBuildingBlock(id string) error
	ListAllBuildingBlocks() ([]*BuildingBlock, error)
}

// CodeElementBuilder defines the interface for building Go code elements
type CodeElementBuilder interface {
	BuildVariable(name, typeName, value string) *GoVariable
	BuildStruct(name, pkg string, fields []GoVariable) *GoStruct
	BuildInterface(name, pkg string, methods []GoMethod) *GoInterface
	BuildFunction(name, pkg string, params []GoVariable, returns []GoType, body string) *GoFunction
	BuildMethod(name string, receiver *GoVariable, params []GoVariable, returns []GoType, body string) *GoMethod
}
