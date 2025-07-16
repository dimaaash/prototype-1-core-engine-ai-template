package infrastructure

import (
	"fmt"
	"sync"
	"time"

	"go-factory-platform/services/building-blocks-service/internal/domain"

	"github.com/google/uuid"
)

// InMemoryBuildingBlockRepository implements BuildingBlockService using in-memory storage
type InMemoryBuildingBlockRepository struct {
	blocks map[string]*domain.BuildingBlock
	mutex  sync.RWMutex
}

// NewInMemoryBuildingBlockRepository creates a new in-memory repository with default primitives
func NewInMemoryBuildingBlockRepository() *InMemoryBuildingBlockRepository {
	repo := &InMemoryBuildingBlockRepository{
		blocks: make(map[string]*domain.BuildingBlock),
	}

	// Initialize with default primitive building blocks
	repo.initializeDefaultPrimitives()

	return repo
}

// initializeDefaultPrimitives adds default primitive building blocks
func (r *InMemoryBuildingBlockRepository) initializeDefaultPrimitives() {
	now := time.Now()

	primitives := []*domain.BuildingBlock{
		{
			ID:          uuid.New().String(),
			Type:        domain.TypeVariable,
			Name:        "string-variable",
			Description: "String variable declaration",
			Template:    "var {{.Name}} string{{if .DefaultValue}} = \"{{.DefaultValue}}\"{{end}}",
			Parameters: map[string]string{
				"Name":         "myString",
				"DefaultValue": "",
			},
			Examples:  []string{"var name string", "var greeting string = \"Hello\""},
			CreatedAt: now,
			UpdatedAt: now,
		},
		{
			ID:          uuid.New().String(),
			Type:        domain.TypeVariable,
			Name:        "int-variable",
			Description: "Integer variable declaration",
			Template:    "var {{.Name}} int{{if .DefaultValue}} = {{.DefaultValue}}{{end}}",
			Parameters: map[string]string{
				"Name":         "myInt",
				"DefaultValue": "0",
			},
			Examples:  []string{"var count int", "var age int = 25"},
			CreatedAt: now,
			UpdatedAt: now,
		},
		{
			ID:          uuid.New().String(),
			Type:        domain.TypeVariable,
			Name:        "bool-variable",
			Description: "Boolean variable declaration",
			Template:    "var {{.Name}} bool{{if .DefaultValue}} = {{.DefaultValue}}{{end}}",
			Parameters: map[string]string{
				"Name":         "myBool",
				"DefaultValue": "false",
			},
			Examples:  []string{"var isActive bool", "var isEnabled bool = true"},
			CreatedAt: now,
			UpdatedAt: now,
		},
		{
			ID:          uuid.New().String(),
			Type:        domain.TypeStruct,
			Name:        "basic-struct",
			Description: "Basic struct template",
			Template:    "type {{.Name}} struct {\n{{range .Fields}}\t{{.Name}} {{.Type}} `json:\"{{.JsonTag}}\"`\n{{end}}}",
			Parameters: map[string]string{
				"Name":   "MyStruct",
				"Fields": "ID,Name,Email",
			},
			Examples:  []string{"type User struct { ID int `json:\"id\"` }"},
			CreatedAt: now,
			UpdatedAt: now,
		},
		{
			ID:          uuid.New().String(),
			Type:        domain.TypeInterface,
			Name:        "basic-interface",
			Description: "Basic interface template",
			Template:    "type {{.Name}} interface {\n{{range .Methods}}\t{{.Name}}({{.Parameters}}) {{.Returns}}\n{{end}}}",
			Parameters: map[string]string{
				"Name":    "MyInterface",
				"Methods": "Get,Set,Delete",
			},
			Examples:  []string{"type Repository interface { Get(id string) error }"},
			CreatedAt: now,
			UpdatedAt: now,
		},
		{
			ID:          uuid.New().String(),
			Type:        domain.TypeFunction,
			Name:        "basic-function",
			Description: "Basic function template",
			Template:    "func {{.Name}}({{.Parameters}}) {{.Returns}} {\n\t{{.Body}}\n}",
			Parameters: map[string]string{
				"Name":       "MyFunction",
				"Parameters": "",
				"Returns":    "error",
				"Body":       "return nil",
			},
			Examples:  []string{"func Process() error { return nil }"},
			CreatedAt: now,
			UpdatedAt: now,
		},
		{
			ID:          uuid.New().String(),
			Type:        domain.TypeVariable,
			Name:        "string-constant",
			Description: "String constant declaration",
			Template:    "const {{.Name}} = \"{{.Value}}\"",
			Parameters: map[string]string{
				"Name":  "MyConstant",
				"Value": "default",
			},
			Examples:  []string{"const DefaultTimeout = \"30s\""},
			CreatedAt: now,
			UpdatedAt: now,
		},
		{
			ID:          uuid.New().String(),
			Type:        domain.TypeVariable,
			Name:        "package-declaration",
			Description: "Package declaration",
			Template:    "package {{.Name}}",
			Parameters: map[string]string{
				"Name": "main",
			},
			Examples:  []string{"package main", "package models"},
			CreatedAt: now,
			UpdatedAt: now,
		},
	}

	// Add all primitives to the repository
	for _, primitive := range primitives {
		r.blocks[primitive.ID] = primitive
	}
}

// CreateBuildingBlock creates a new building block
func (r *InMemoryBuildingBlockRepository) CreateBuildingBlock(block *domain.BuildingBlock) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	if _, exists := r.blocks[block.ID]; exists {
		return fmt.Errorf("building block with ID %s already exists", block.ID)
	}

	r.blocks[block.ID] = block
	return nil
}

// GetBuildingBlock retrieves a building block by ID
func (r *InMemoryBuildingBlockRepository) GetBuildingBlock(id string) (*domain.BuildingBlock, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	block, exists := r.blocks[id]
	if !exists {
		return nil, fmt.Errorf("building block with ID %s not found", id)
	}

	return block, nil
}

// GetBuildingBlocksByType retrieves building blocks by type
func (r *InMemoryBuildingBlockRepository) GetBuildingBlocksByType(blockType domain.BuildingBlockType) ([]*domain.BuildingBlock, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	var result []*domain.BuildingBlock
	for _, block := range r.blocks {
		if block.Type == blockType {
			result = append(result, block)
		}
	}

	return result, nil
}

// UpdateBuildingBlock updates an existing building block
func (r *InMemoryBuildingBlockRepository) UpdateBuildingBlock(block *domain.BuildingBlock) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	if _, exists := r.blocks[block.ID]; !exists {
		return fmt.Errorf("building block with ID %s not found", block.ID)
	}

	r.blocks[block.ID] = block
	return nil
}

// DeleteBuildingBlock deletes a building block
func (r *InMemoryBuildingBlockRepository) DeleteBuildingBlock(id string) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	if _, exists := r.blocks[id]; !exists {
		return fmt.Errorf("building block with ID %s not found", id)
	}

	delete(r.blocks, id)
	return nil
}

// ListAllBuildingBlocks lists all building blocks
func (r *InMemoryBuildingBlockRepository) ListAllBuildingBlocks() ([]*domain.BuildingBlock, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	var result []*domain.BuildingBlock
	for _, block := range r.blocks {
		result = append(result, block)
	}

	return result, nil
}
