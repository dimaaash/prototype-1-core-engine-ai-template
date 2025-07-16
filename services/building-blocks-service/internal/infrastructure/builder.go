package infrastructure

import (
	"go-factory-platform/services/building-blocks-service/internal/domain"
)

// GoCodeElementBuilder implements the CodeElementBuilder interface
type GoCodeElementBuilder struct{}

// NewGoCodeElementBuilder creates a new Go code element builder
func NewGoCodeElementBuilder() *GoCodeElementBuilder {
	return &GoCodeElementBuilder{}
}

// BuildVariable builds a Go variable
func (b *GoCodeElementBuilder) BuildVariable(name, typeName, value string) *domain.GoVariable {
	goType := domain.GoType{
		Name:    typeName,
		Package: "",
	}

	return &domain.GoVariable{
		Name:         name,
		Type:         goType,
		DefaultValue: value,
	}
}

// BuildStruct builds a Go struct
func (b *GoCodeElementBuilder) BuildStruct(name, pkg string, fields []domain.GoVariable) *domain.GoStruct {
	return &domain.GoStruct{
		Name:    name,
		Package: pkg,
		Fields:  fields,
		Methods: []domain.GoMethod{},
	}
}

// BuildInterface builds a Go interface
func (b *GoCodeElementBuilder) BuildInterface(name, pkg string, methods []domain.GoMethod) *domain.GoInterface {
	return &domain.GoInterface{
		Name:    name,
		Package: pkg,
		Methods: methods,
	}
}

// BuildFunction builds a Go function
func (b *GoCodeElementBuilder) BuildFunction(name, pkg string, params []domain.GoVariable, returns []domain.GoType, body string) *domain.GoFunction {
	return &domain.GoFunction{
		Name:       name,
		Package:    pkg,
		Parameters: params,
		Returns:    returns,
		Body:       body,
	}
}

// BuildMethod builds a Go method
func (b *GoCodeElementBuilder) BuildMethod(name string, receiver *domain.GoVariable, params []domain.GoVariable, returns []domain.GoType, body string) *domain.GoMethod {
	return &domain.GoMethod{
		Name:       name,
		Receiver:   receiver,
		Parameters: params,
		Returns:    returns,
		Body:       body,
	}
}
