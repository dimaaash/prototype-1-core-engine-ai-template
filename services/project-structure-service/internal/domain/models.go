package domain

import (
	"time"

	"github.com/google/uuid"
)

// ProjectType represents the type of project structure
type ProjectType string

const (
	ProjectTypeMicroservice ProjectType = "microservice"
	ProjectTypeCLI          ProjectType = "cli"
	ProjectTypeLibrary      ProjectType = "library"
	ProjectTypeAPI          ProjectType = "api"
	ProjectTypeWorker       ProjectType = "worker"
)

// ProjectTemplate defines a project structure template
type ProjectTemplate struct {
	ID               string            `json:"id"`
	Name             string            `json:"name"`
	Description      string            `json:"description"`
	Type             ProjectType       `json:"type"`
	Directories      []string          `json:"directories"`
	BoilerplateFiles map[string]string `json:"boilerplate_files"`
	CreatedAt        time.Time         `json:"created_at"`
	UpdatedAt        time.Time         `json:"updated_at"`
}

// ProjectStructure represents a generated project structure
type ProjectStructure struct {
	ID          string                 `json:"id"`
	Name        string                 `json:"name"`
	ModuleName  string                 `json:"module_name"`
	OutputPath  string                 `json:"output_path"`
	Type        ProjectType            `json:"type"`
	Directories []string               `json:"directories"`
	Files       []ProjectFile          `json:"files"`
	Metadata    map[string]interface{} `json:"metadata"`
	TemplateID  string                 `json:"template_id"`
	CreatedAt   time.Time              `json:"created_at"`
}

// ProjectFile represents a file to be created in the project
type ProjectFile struct {
	Path    string `json:"path"`
	Content string `json:"content"`
	Mode    string `json:"mode,omitempty"` // File permissions (e.g., "0755" for executables)
}

// CreateProjectStructureRequest represents a request to create project structure
type CreateProjectStructureRequest struct {
	Name              string                 `json:"name" binding:"required"`
	ModuleName        string                 `json:"module_name" binding:"required"`
	OutputPath        string                 `json:"output_path" binding:"required"`
	ProjectType       ProjectType            `json:"project_type" binding:"required"`
	TemplateID        string                 `json:"template_id,omitempty"`
	CustomDirectories []string               `json:"custom_directories,omitempty"`
	Variables         map[string]interface{} `json:"variables,omitempty"`
	IncludeGitIgnore  bool                   `json:"include_gitignore,omitempty"`
	IncludeReadme     bool                   `json:"include_readme,omitempty"`
	IncludeDockerfile bool                   `json:"include_dockerfile,omitempty"`
	IncludeMakefile   bool                   `json:"include_makefile,omitempty"`
}

// ValidateProjectStructureRequest represents a request to validate project structure
type ValidateProjectStructureRequest struct {
	Path string `json:"path" binding:"required"`
}

// ProjectStructureValidationResult represents the result of project structure validation
type ProjectStructureValidationResult struct {
	IsValid         bool     `json:"is_valid"`
	MissingFiles    []string `json:"missing_files,omitempty"`
	MissingDirs     []string `json:"missing_directories,omitempty"`
	ExtraFiles      []string `json:"extra_files,omitempty"`
	Recommendations []string `json:"recommendations,omitempty"`
	ProjectType     string   `json:"detected_project_type,omitempty"`
}

// NewProjectTemplate creates a new project template with generated ID
func NewProjectTemplate(name, description string, projectType ProjectType) *ProjectTemplate {
	return &ProjectTemplate{
		ID:               uuid.New().String(),
		Name:             name,
		Description:      description,
		Type:             projectType,
		Directories:      make([]string, 0),
		BoilerplateFiles: make(map[string]string),
		CreatedAt:        time.Now(),
		UpdatedAt:        time.Now(),
	}
}

// NewProjectStructure creates a new project structure with generated ID
func NewProjectStructure(name, moduleName, outputPath string, projectType ProjectType) *ProjectStructure {
	return &ProjectStructure{
		ID:          uuid.New().String(),
		Name:        name,
		ModuleName:  moduleName,
		OutputPath:  outputPath,
		Type:        projectType,
		Directories: make([]string, 0),
		Files:       make([]ProjectFile, 0),
		Metadata:    make(map[string]interface{}),
		CreatedAt:   time.Now(),
	}
}

// AddDirectory adds a directory to the project structure
func (ps *ProjectStructure) AddDirectory(path string) {
	ps.Directories = append(ps.Directories, path)
}

// AddFile adds a file to the project structure
func (ps *ProjectStructure) AddFile(path, content string) {
	ps.Files = append(ps.Files, ProjectFile{
		Path:    path,
		Content: content,
	})
}

// AddExecutableFile adds an executable file to the project structure
func (ps *ProjectStructure) AddExecutableFile(path, content string) {
	ps.Files = append(ps.Files, ProjectFile{
		Path:    path,
		Content: content,
		Mode:    "0755",
	})
}

// ProjectTemplateRepository defines the interface for project template storage
type ProjectTemplateRepository interface {
	Create(template *ProjectTemplate) error
	GetByID(id string) (*ProjectTemplate, error)
	GetByName(name string) (*ProjectTemplate, error)
	GetByType(projectType ProjectType) ([]*ProjectTemplate, error)
	GetAll() ([]*ProjectTemplate, error)
	Update(template *ProjectTemplate) error
	Delete(id string) error
}

// ProjectStructureRepository defines the interface for project structure storage
type ProjectStructureRepository interface {
	Create(structure *ProjectStructure) error
	GetByID(id string) (*ProjectStructure, error)
	GetAll() ([]*ProjectStructure, error)
	Delete(id string) error
}
