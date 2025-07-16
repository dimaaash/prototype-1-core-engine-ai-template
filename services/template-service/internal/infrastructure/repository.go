package infrastructure

import (
	"bytes"
	"fmt"
	"sync"
	"text/template"
	"time"

	"go-factory-platform/services/template-service/internal/domain"
)

// InMemoryTemplateRepository implements TemplateService using in-memory storage
type InMemoryTemplateRepository struct {
	templates map[string]*domain.Template
	mutex     sync.RWMutex
}

// NewInMemoryTemplateRepository creates a new in-memory repository
func NewInMemoryTemplateRepository() *InMemoryTemplateRepository {
	return &InMemoryTemplateRepository{
		templates: make(map[string]*domain.Template),
	}
}

// CreateTemplate creates a new template
func (r *InMemoryTemplateRepository) CreateTemplate(tmpl *domain.Template) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	if _, exists := r.templates[tmpl.ID]; exists {
		return fmt.Errorf("template with ID %s already exists", tmpl.ID)
	}

	r.templates[tmpl.ID] = tmpl
	return nil
}

// GetTemplate retrieves a template by ID
func (r *InMemoryTemplateRepository) GetTemplate(id string) (*domain.Template, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	tmpl, exists := r.templates[id]
	if !exists {
		return nil, fmt.Errorf("template with ID %s not found", id)
	}

	return tmpl, nil
}

// GetTemplatesByCategory retrieves templates by category
func (r *InMemoryTemplateRepository) GetTemplatesByCategory(category domain.TemplateCategory) ([]*domain.Template, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	var result []*domain.Template
	for _, tmpl := range r.templates {
		if tmpl.Category == category {
			result = append(result, tmpl)
		}
	}

	return result, nil
}

// UpdateTemplate updates an existing template
func (r *InMemoryTemplateRepository) UpdateTemplate(tmpl *domain.Template) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	if _, exists := r.templates[tmpl.ID]; !exists {
		return fmt.Errorf("template with ID %s not found", tmpl.ID)
	}

	tmpl.UpdatedAt = time.Now()
	r.templates[tmpl.ID] = tmpl
	return nil
}

// DeleteTemplate deletes a template
func (r *InMemoryTemplateRepository) DeleteTemplate(id string) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()

	if _, exists := r.templates[id]; !exists {
		return fmt.Errorf("template with ID %s not found", id)
	}

	delete(r.templates, id)
	return nil
}

// ListAllTemplates lists all templates
func (r *InMemoryTemplateRepository) ListAllTemplates() ([]*domain.Template, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()

	var result []*domain.Template
	for _, tmpl := range r.templates {
		result = append(result, tmpl)
	}

	return result, nil
}

// ProcessTemplate processes a template request
func (r *InMemoryTemplateRepository) ProcessTemplate(request *domain.TemplateRequest) (*domain.TemplateResult, error) {
	// Get template
	tmpl, err := r.GetTemplate(request.TemplateID)
	if err != nil {
		return nil, err
	}

	// Parse template
	t, err := template.New(tmpl.Name).Parse(tmpl.Content)
	if err != nil {
		return &domain.TemplateResult{
			ID:           fmt.Sprintf("result_%d", time.Now().UnixNano()),
			TemplateID:   request.TemplateID,
			Success:      false,
			ErrorMessage: fmt.Sprintf("failed to parse template: %v", err),
			CreatedAt:    time.Now(),
		}, nil
	}

	// Execute template
	var buffer bytes.Buffer
	if err := t.Execute(&buffer, request.Parameters); err != nil {
		return &domain.TemplateResult{
			ID:           fmt.Sprintf("result_%d", time.Now().UnixNano()),
			TemplateID:   request.TemplateID,
			Success:      false,
			ErrorMessage: fmt.Sprintf("failed to execute template: %v", err),
			CreatedAt:    time.Now(),
		}, nil
	}

	return &domain.TemplateResult{
		ID:            fmt.Sprintf("result_%d", time.Now().UnixNano()),
		TemplateID:    request.TemplateID,
		GeneratedCode: buffer.String(),
		Success:       true,
		Metadata: map[string]string{
			"template_name": tmpl.Name,
			"category":      string(tmpl.Category),
			"output_path":   request.OutputPath,
			"package_name":  request.PackageName,
		},
		CreatedAt: time.Now(),
	}, nil
}
