package domain

import (
	"context"
	"time"
)

// FileOperation represents a file operation
type FileOperation struct {
	Type     string            `json:"type"` // write, read, delete
	Path     string            `json:"path"`
	Content  string            `json:"content,omitempty"`
	Metadata map[string]string `json:"metadata,omitempty"`
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

// CompilationResult represents the result of compilation
type CompilationResult struct {
	ID           string            `json:"id"`
	ProjectPath  string            `json:"project_path"`
	Success      bool              `json:"success"`
	Output       string            `json:"output"`
	ErrorMessage string            `json:"error_message,omitempty"`
	Warnings     []string          `json:"warnings,omitempty"`
	BuildTime    time.Duration     `json:"build_time"`
	Metadata     map[string]string `json:"metadata"`
	CreatedAt    time.Time         `json:"created_at"`
}

// ValidationResult represents the result of code validation
type ValidationResult struct {
	ID        string            `json:"id"`
	Files     []string          `json:"files"`
	Valid     bool              `json:"valid"`
	Issues    []ValidationIssue `json:"issues"`
	Metadata  map[string]string `json:"metadata"`
	CreatedAt time.Time         `json:"created_at"`
}

// ValidationIssue represents a validation issue
type ValidationIssue struct {
	File    string `json:"file"`
	Line    int    `json:"line"`
	Column  int    `json:"column"`
	Type    string `json:"type"` // error, warning, info
	Message string `json:"message"`
	Rule    string `json:"rule,omitempty"`
}

// ProjectStructure represents a Go project structure
type ProjectStructure struct {
	RootPath    string            `json:"root_path"`
	ModuleName  string            `json:"module_name"`
	GoVersion   string            `json:"go_version"`
	Directories []string          `json:"directories"`
	Files       []ProjectFile     `json:"files"`
	Metadata    map[string]string `json:"metadata"`
	CreatedAt   time.Time         `json:"created_at"`
}

// ProjectFile represents a file in a project
type ProjectFile struct {
	Path     string `json:"path"`
	Type     string `json:"type"` // go, mod, yaml, etc.
	Content  string `json:"content"`
	Template bool   `json:"template"`
}

// FileSystemService defines the interface for file system operations
type FileSystemService interface {
	WriteFiles(ctx context.Context, accumulator *CodeAccumulator, outputPath string) error
	ReadFile(ctx context.Context, filePath string) (string, error)
	CreateDirectory(ctx context.Context, dirPath string) error
	DeleteFile(ctx context.Context, filePath string) error
	ListFiles(ctx context.Context, dirPath string) ([]string, error)
	FileExists(ctx context.Context, filePath string) (bool, error)
}

// CompilerService defines the interface for Go compilation operations
type CompilerService interface {
	CompileProject(ctx context.Context, projectPath string) (*CompilationResult, error)
	BuildProject(ctx context.Context, projectPath string, outputPath string) (*CompilationResult, error)
	ValidateCode(ctx context.Context, files []GeneratedFile) (*ValidationResult, error)
	FormatCode(ctx context.Context, content string) (string, error)
	CheckSyntax(ctx context.Context, content string) error
}

// ProjectService defines the interface for project management operations
type ProjectService interface {
	CreateProject(ctx context.Context, structure *ProjectStructure) error
	InitializeGoModule(ctx context.Context, projectPath, moduleName string) error
	AddDependency(ctx context.Context, projectPath, dependency, version string) error
	UpdateDependencies(ctx context.Context, projectPath string) error
	GenerateGoMod(ctx context.Context, projectPath, moduleName string, dependencies []string) error
}
