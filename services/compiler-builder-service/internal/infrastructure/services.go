package infrastructure

import (
	"context"
	"fmt"
	"go/format"
	"go/parser"
	"go/token"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"go-factory-platform/services/compiler-builder-service/internal/domain"
)

// LocalFileSystemService implements FileSystemService using local filesystem
type LocalFileSystemService struct{}

// NewLocalFileSystemService creates a new local filesystem service
func NewLocalFileSystemService() *LocalFileSystemService {
	return &LocalFileSystemService{}
}

// WriteFiles writes accumulated code files to the filesystem
func (s *LocalFileSystemService) WriteFiles(ctx context.Context, accumulator *domain.CodeAccumulator, outputPath string) error {
	for _, file := range accumulator.Files {
		fullPath := file.Path
		fmt.Printf("[DEBUG] Attempting to write file. outputPath: '%s', file.Path: '%s', initial fullPath: '%s'\n", outputPath, file.Path, fullPath)
		if !filepath.IsAbs(fullPath) {
			fullPath = filepath.Join(outputPath, file.Path)
			fmt.Printf("[DEBUG] Joined outputPath and file.Path. New fullPath: '%s'\n", fullPath)
		}

		// Create directory if it doesn't exist
		dir := filepath.Dir(fullPath)
		fmt.Printf("[DEBUG] Ensuring directory exists: '%s'\n", dir)
		if err := s.CreateDirectory(ctx, dir); err != nil {
			fmt.Printf("[ERROR] Failed to create directory '%s': %v\n", dir, err)
			return fmt.Errorf("failed to create directory %s: %w", dir, err)
		}

		// Write file
		fmt.Printf("[DEBUG] Writing file to: '%s'\n", fullPath)
		if err := os.WriteFile(fullPath, []byte(file.Content), 0644); err != nil {
			fmt.Printf("[ERROR] Failed to write file '%s': %v\n", fullPath, err)
			return fmt.Errorf("failed to write file %s: %w", fullPath, err)
		}

		fmt.Printf("Written file: %s (%d bytes)\n", fullPath, file.Size)
	}

	return nil
}

// ReadFile reads a file from the filesystem
func (s *LocalFileSystemService) ReadFile(ctx context.Context, filePath string) (string, error) {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return "", fmt.Errorf("failed to read file %s: %w", filePath, err)
	}
	return string(content), nil
}

// CreateDirectory creates a directory and all parent directories
func (s *LocalFileSystemService) CreateDirectory(ctx context.Context, dirPath string) error {
	return os.MkdirAll(dirPath, 0755)
}

// DeleteFile deletes a file
func (s *LocalFileSystemService) DeleteFile(ctx context.Context, filePath string) error {
	return os.Remove(filePath)
}

// ListFiles lists files in a directory
func (s *LocalFileSystemService) ListFiles(ctx context.Context, dirPath string) ([]string, error) {
	entries, err := os.ReadDir(dirPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read directory %s: %w", dirPath, err)
	}

	var files []string
	for _, entry := range entries {
		if !entry.IsDir() {
			files = append(files, entry.Name())
		}
	}

	return files, nil
}

// FileExists checks if a file exists
func (s *LocalFileSystemService) FileExists(ctx context.Context, filePath string) (bool, error) {
	_, err := os.Stat(filePath)
	if os.IsNotExist(err) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return true, nil
}

// GoCompilerService implements CompilerService using Go tools
type GoCompilerService struct{}

// NewGoCompilerService creates a new Go compiler service
func NewGoCompilerService() *GoCompilerService {
	return &GoCompilerService{}
}

// CompileProject compiles a Go project
func (s *GoCompilerService) CompileProject(ctx context.Context, projectPath string) (*domain.CompilationResult, error) {
	startTime := time.Now()

	cmd := exec.CommandContext(ctx, "go", "build", "./...")
	cmd.Dir = projectPath

	output, err := cmd.CombinedOutput()
	buildTime := time.Since(startTime)

	result := &domain.CompilationResult{
		ID:          fmt.Sprintf("comp_%d", time.Now().UnixNano()),
		ProjectPath: projectPath,
		Output:      string(output),
		BuildTime:   buildTime,
		Metadata:    make(map[string]string),
		CreatedAt:   time.Now(),
	}

	if err != nil {
		result.Success = false
		result.ErrorMessage = err.Error()
		return result, nil
	}

	result.Success = true
	return result, nil
}

// BuildProject builds a Go project and outputs binary
func (s *GoCompilerService) BuildProject(ctx context.Context, projectPath, outputPath string) (*domain.CompilationResult, error) {
	startTime := time.Now()

	cmd := exec.CommandContext(ctx, "go", "build", "-o", outputPath, "./...")
	cmd.Dir = projectPath

	output, err := cmd.CombinedOutput()
	buildTime := time.Since(startTime)

	result := &domain.CompilationResult{
		ID:          fmt.Sprintf("build_%d", time.Now().UnixNano()),
		ProjectPath: projectPath,
		Output:      string(output),
		BuildTime:   buildTime,
		Metadata: map[string]string{
			"output_path": outputPath,
		},
		CreatedAt: time.Now(),
	}

	if err != nil {
		result.Success = false
		result.ErrorMessage = err.Error()
		return result, nil
	}

	result.Success = true
	return result, nil
}

// ValidateCode validates generated code files
func (s *GoCompilerService) ValidateCode(ctx context.Context, files []domain.GeneratedFile) (*domain.ValidationResult, error) {
	result := &domain.ValidationResult{
		ID:        fmt.Sprintf("val_%d", time.Now().UnixNano()),
		Files:     make([]string, len(files)),
		Valid:     true,
		Issues:    []domain.ValidationIssue{},
		Metadata:  make(map[string]string),
		CreatedAt: time.Now(),
	}

	for i, file := range files {
		result.Files[i] = file.Path

		// Skip non-Go files
		if !strings.HasSuffix(file.Path, ".go") {
			continue
		}

		// Parse and validate Go syntax
		if err := s.CheckSyntax(ctx, file.Content); err != nil {
			result.Valid = false
			result.Issues = append(result.Issues, domain.ValidationIssue{
				File:    file.Path,
				Type:    "error",
				Message: err.Error(),
				Rule:    "syntax",
			})
		}
	}

	return result, nil
}

// FormatCode formats Go code
func (s *GoCompilerService) FormatCode(ctx context.Context, content string) (string, error) {
	formatted, err := format.Source([]byte(content))
	if err != nil {
		return "", fmt.Errorf("failed to format code: %w", err)
	}
	return string(formatted), nil
}

// CheckSyntax checks Go syntax
func (s *GoCompilerService) CheckSyntax(ctx context.Context, content string) error {
	fset := token.NewFileSet()
	_, err := parser.ParseFile(fset, "", content, parser.ParseComments)
	if err != nil {
		return fmt.Errorf("syntax error: %w", err)
	}
	return nil
}

// GoProjectService implements ProjectService using Go tools
type GoProjectService struct {
	fileSystemService domain.FileSystemService
}

// NewGoProjectService creates a new Go project service
func NewGoProjectService(fileSystemService domain.FileSystemService) *GoProjectService {
	return &GoProjectService{
		fileSystemService: fileSystemService,
	}
}

// CreateProject creates a new Go project with the specified structure
func (s *GoProjectService) CreateProject(ctx context.Context, structure *domain.ProjectStructure) error {
	// Create root directory
	if err := s.fileSystemService.CreateDirectory(ctx, structure.RootPath); err != nil {
		return fmt.Errorf("failed to create root directory: %w", err)
	}

	// Create subdirectories
	for _, dir := range structure.Directories {
		dirPath := filepath.Join(structure.RootPath, dir)
		if err := s.fileSystemService.CreateDirectory(ctx, dirPath); err != nil {
			return fmt.Errorf("failed to create directory %s: %w", dirPath, err)
		}
	}

	// Create files
	for _, file := range structure.Files {
		filePath := filepath.Join(structure.RootPath, file.Path)
		if err := os.WriteFile(filePath, []byte(file.Content), 0644); err != nil {
			return fmt.Errorf("failed to create file %s: %w", filePath, err)
		}
	}

	return nil
}

// InitializeGoModule initializes a Go module
func (s *GoProjectService) InitializeGoModule(ctx context.Context, projectPath, moduleName string) error {
	cmd := exec.CommandContext(ctx, "go", "mod", "init", moduleName)
	cmd.Dir = projectPath

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to initialize Go module: %w", err)
	}

	return nil
}

// AddDependency adds a dependency to the Go module
func (s *GoProjectService) AddDependency(ctx context.Context, projectPath, dependency, version string) error {
	depSpec := dependency
	if version != "" {
		depSpec = fmt.Sprintf("%s@%s", dependency, version)
	}

	cmd := exec.CommandContext(ctx, "go", "get", depSpec)
	cmd.Dir = projectPath

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to add dependency %s: %w", depSpec, err)
	}

	return nil
}

// UpdateDependencies updates all dependencies
func (s *GoProjectService) UpdateDependencies(ctx context.Context, projectPath string) error {
	cmd := exec.CommandContext(ctx, "go", "mod", "tidy")
	cmd.Dir = projectPath

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to update dependencies: %w", err)
	}

	return nil
}

// GenerateGoMod generates a go.mod file
func (s *GoProjectService) GenerateGoMod(ctx context.Context, projectPath, moduleName string, dependencies []string) error {
	content := fmt.Sprintf("module %s\n\ngo 1.21\n", moduleName)

	if len(dependencies) > 0 {
		content += "\nrequire (\n"
		for _, dep := range dependencies {
			content += fmt.Sprintf("    %s\n", dep)
		}
		content += ")\n"
	}

	goModPath := filepath.Join(projectPath, "go.mod")
	return os.WriteFile(goModPath, []byte(content), 0644)
}
