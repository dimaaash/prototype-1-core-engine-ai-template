package infrastructure

import (
	"errors"
	"sync"

	"go-factory-platform/services/project-structure-service/internal/domain"
)

// InMemoryProjectTemplateRepository implements ProjectTemplateRepository with in-memory storage
type InMemoryProjectTemplateRepository struct {
	templates map[string]*domain.ProjectTemplate
	mutex     sync.RWMutex
}

// NewProjectTemplateRepository creates a new in-memory project template repository
func NewProjectTemplateRepository() domain.ProjectTemplateRepository {
	return &InMemoryProjectTemplateRepository{
		templates: make(map[string]*domain.ProjectTemplate),
	}
}

func (r *InMemoryProjectTemplateRepository) Create(template *domain.ProjectTemplate) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	if _, exists := r.templates[template.ID]; exists {
		return errors.New("template already exists")
	}

	r.templates[template.ID] = template
	return nil
}

func (r *InMemoryProjectTemplateRepository) GetByID(id string) (*domain.ProjectTemplate, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	template, exists := r.templates[id]
	if !exists {
		return nil, errors.New("template not found")
	}

	return template, nil
}

func (r *InMemoryProjectTemplateRepository) GetByName(name string) (*domain.ProjectTemplate, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	for _, template := range r.templates {
		if template.Name == name {
			return template, nil
		}
	}

	return nil, errors.New("template not found")
}

func (r *InMemoryProjectTemplateRepository) GetByType(projectType domain.ProjectType) ([]*domain.ProjectTemplate, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	var templates []*domain.ProjectTemplate
	for _, template := range r.templates {
		if template.Type == projectType {
			templates = append(templates, template)
		}
	}

	return templates, nil
}

func (r *InMemoryProjectTemplateRepository) GetAll() ([]*domain.ProjectTemplate, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	var templates []*domain.ProjectTemplate
	for _, template := range r.templates {
		templates = append(templates, template)
	}

	return templates, nil
}

func (r *InMemoryProjectTemplateRepository) Update(template *domain.ProjectTemplate) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	if _, exists := r.templates[template.ID]; !exists {
		return errors.New("template not found")
	}

	r.templates[template.ID] = template
	return nil
}

func (r *InMemoryProjectTemplateRepository) Delete(id string) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	if _, exists := r.templates[id]; !exists {
		return errors.New("template not found")
	}

	delete(r.templates, id)
	return nil
}

// InMemoryProjectStructureRepository implements ProjectStructureRepository with in-memory storage
type InMemoryProjectStructureRepository struct {
	structures map[string]*domain.ProjectStructure
	mutex      sync.RWMutex
}

// NewProjectStructureRepository creates a new in-memory project structure repository
func NewProjectStructureRepository() domain.ProjectStructureRepository {
	return &InMemoryProjectStructureRepository{
		structures: make(map[string]*domain.ProjectStructure),
	}
}

func (r *InMemoryProjectStructureRepository) Create(structure *domain.ProjectStructure) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	if _, exists := r.structures[structure.ID]; exists {
		return errors.New("project structure already exists")
	}

	r.structures[structure.ID] = structure
	return nil
}

func (r *InMemoryProjectStructureRepository) GetByID(id string) (*domain.ProjectStructure, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	structure, exists := r.structures[id]
	if !exists {
		return nil, errors.New("project structure not found")
	}

	return structure, nil
}

func (r *InMemoryProjectStructureRepository) GetAll() ([]*domain.ProjectStructure, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	var structures []*domain.ProjectStructure
	for _, structure := range r.structures {
		structures = append(structures, structure)
	}

	return structures, nil
}

func (r *InMemoryProjectStructureRepository) Delete(id string) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	if _, exists := r.structures[id]; !exists {
		return errors.New("project structure not found")
	}

	delete(r.structures, id)
	return nil
}
