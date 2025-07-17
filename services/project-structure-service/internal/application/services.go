package application

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"text/template"

	"go-factory-platform/services/project-structure-service/internal/domain"
)

// ProjectTemplateService handles project template operations
type ProjectTemplateService struct {
	repo domain.ProjectTemplateRepository
}

// NewProjectTemplateService creates a new project template service
func NewProjectTemplateService(repo domain.ProjectTemplateRepository) *ProjectTemplateService {
	return &ProjectTemplateService{
		repo: repo,
	}
}

func (s *ProjectTemplateService) CreateTemplate(tmpl *domain.ProjectTemplate) (*domain.ProjectTemplate, error) {
	if err := s.repo.Create(tmpl); err != nil {
		return nil, fmt.Errorf("failed to create template: %w", err)
	}
	return tmpl, nil
}

func (s *ProjectTemplateService) GetTemplate(id string) (*domain.ProjectTemplate, error) {
	return s.repo.GetByID(id)
}

func (s *ProjectTemplateService) GetTemplateByName(name string) (*domain.ProjectTemplate, error) {
	return s.repo.GetByName(name)
}

func (s *ProjectTemplateService) GetTemplatesByType(projectType domain.ProjectType) ([]*domain.ProjectTemplate, error) {
	return s.repo.GetByType(projectType)
}

func (s *ProjectTemplateService) GetAllTemplates() ([]*domain.ProjectTemplate, error) {
	return s.repo.GetAll()
}

func (s *ProjectTemplateService) UpdateTemplate(tmpl *domain.ProjectTemplate) error {
	return s.repo.Update(tmpl)
}

func (s *ProjectTemplateService) DeleteTemplate(id string) error {
	return s.repo.Delete(id)
}

// ProjectStructureService handles project structure creation and management
type ProjectStructureService struct {
	structureRepo   domain.ProjectStructureRepository
	templateService *ProjectTemplateService
}

// NewProjectStructureService creates a new project structure service
func NewProjectStructureService(
	structureRepo domain.ProjectStructureRepository,
	templateService *ProjectTemplateService,
) *ProjectStructureService {
	return &ProjectStructureService{
		structureRepo:   structureRepo,
		templateService: templateService,
	}
}

// CreateProjectStructure creates a new project structure based on a template
func (s *ProjectStructureService) CreateProjectStructure(req *domain.CreateProjectStructureRequest) (*domain.ProjectStructure, error) {
	// Get template
	var tmpl *domain.ProjectTemplate
	var err error

	if req.TemplateID != "" {
		tmpl, err = s.templateService.GetTemplate(req.TemplateID)
	} else {
		// Get default template for project type
		templates, err := s.templateService.GetTemplatesByType(req.ProjectType)
		if err != nil || len(templates) == 0 {
			return nil, fmt.Errorf("no template found for project type: %s", req.ProjectType)
		}
		tmpl = templates[0] // Use first template
	}

	if err != nil {
		return nil, fmt.Errorf("failed to get template: %w", err)
	}

	// Create project structure
	structure := domain.NewProjectStructure(req.Name, req.ModuleName, req.OutputPath, req.ProjectType)
	structure.TemplateID = tmpl.ID

	// Add directories from template
	for _, dir := range tmpl.Directories {
		structure.AddDirectory(dir)
	}

	// Add custom directories
	for _, dir := range req.CustomDirectories {
		structure.AddDirectory(dir)
	}

	// Process boilerplate files
	variables := s.createTemplateVariables(req)
	for filePath, content := range tmpl.BoilerplateFiles {
		processedContent, err := s.processTemplate(content, variables)
		if err != nil {
			return nil, fmt.Errorf("failed to process template for file %s: %w", filePath, err)
		}
		structure.AddFile(filePath, processedContent)
	}

	// Add optional files based on flags
	if req.IncludeGitIgnore && !s.hasFile(structure, ".gitignore") {
		structure.AddFile(".gitignore", s.getDefaultGitIgnore())
	}

	if req.IncludeReadme && !s.hasFile(structure, "README.md") {
		readmeContent, _ := s.processTemplate(s.getDefaultReadme(), variables)
		structure.AddFile("README.md", readmeContent)
	}

	if req.IncludeDockerfile && !s.hasFile(structure, "Dockerfile") {
		dockerfileContent, _ := s.processTemplate(s.getDefaultDockerfile(), variables)
		structure.AddFile("Dockerfile", dockerfileContent)
	}

	if req.IncludeMakefile && !s.hasFile(structure, "Makefile") {
		makefileContent, _ := s.processTemplate(s.getDefaultMakefile(), variables)
		structure.AddFile("Makefile", makefileContent)
	}

	// Store structure
	if err := s.structureRepo.Create(structure); err != nil {
		return nil, fmt.Errorf("failed to store project structure: %w", err)
	}

	return structure, nil
}

// WriteProjectStructure writes the project structure to the filesystem
func (s *ProjectStructureService) WriteProjectStructure(structure *domain.ProjectStructure) error {
	// Create base directory
	if err := os.MkdirAll(structure.OutputPath, 0755); err != nil {
		return fmt.Errorf("failed to create base directory: %w", err)
	}

	// Create directories
	for _, dir := range structure.Directories {
		fullPath := filepath.Join(structure.OutputPath, dir)
		if err := os.MkdirAll(fullPath, 0755); err != nil {
			return fmt.Errorf("failed to create directory %s: %w", dir, err)
		}
	}

	// Create files
	for _, file := range structure.Files {
		fullPath := filepath.Join(structure.OutputPath, file.Path)

		// Ensure directory exists
		dir := filepath.Dir(fullPath)
		if err := os.MkdirAll(dir, 0755); err != nil {
			return fmt.Errorf("failed to create directory for file %s: %w", file.Path, err)
		}

		// Write file
		mode := os.FileMode(0644)
		if file.Mode != "" {
			// Parse mode if specified (e.g., "0755")
			if file.Mode == "0755" {
				mode = 0755
			}
		}

		if err := os.WriteFile(fullPath, []byte(file.Content), mode); err != nil {
			return fmt.Errorf("failed to write file %s: %w", file.Path, err)
		}
	}

	// Automated Dependency Resolution - Run 'go mod tidy' for Go projects
	if s.hasGoModFile(structure) {
		if err := s.runGoModTidy(structure.OutputPath); err != nil {
			// Log warning but don't fail - dependency resolution is optional
			fmt.Printf("Warning: Failed to run 'go mod tidy' for project at %s: %v\n", structure.OutputPath, err)
		}
	}

	return nil
}

// ValidateProjectStructure validates if a directory follows Go project conventions
func (s *ProjectStructureService) ValidateProjectStructure(req *domain.ValidateProjectStructureRequest) (*domain.ProjectStructureValidationResult, error) {
	result := &domain.ProjectStructureValidationResult{
		IsValid: true,
	}

	// Check if path exists
	if _, err := os.Stat(req.Path); os.IsNotExist(err) {
		result.IsValid = false
		result.MissingDirs = append(result.MissingDirs, req.Path)
		return result, nil
	}

	// Detect project type
	projectType := s.detectProjectType(req.Path)
	result.ProjectType = string(projectType)

	// Project-type-specific validation
	switch projectType {
	case domain.ProjectTypeMicroservice:
		s.validateMicroserviceStructure(req.Path, result)
	case domain.ProjectTypeCLI:
		s.validateCLIStructure(req.Path, result)
	case domain.ProjectTypeLibrary:
		s.validateLibraryStructure(req.Path, result)
	case domain.ProjectTypeAPI:
		s.validateAPIStructure(req.Path, result)
	case domain.ProjectTypeWorker:
		s.validateWorkerStructure(req.Path, result)
	default:
		// Fallback to microservice validation
		s.validateMicroserviceStructure(req.Path, result)
	}

	// Common validation for all project types
	s.validateCommonStructure(req.Path, result)

	return result, nil
}

// Helper methods

func (s *ProjectStructureService) createTemplateVariables(req *domain.CreateProjectStructureRequest) map[string]interface{} {
	// Extract package name from module name (take the last part after /)
	packageName := req.Name
	if strings.Contains(req.ModuleName, "/") {
		parts := strings.Split(req.ModuleName, "/")
		packageName = parts[len(parts)-1]
	}

	// Clean package name for Go compatibility
	packageName = strings.ReplaceAll(packageName, "-", "")
	packageName = strings.ReplaceAll(packageName, "_", "")
	packageName = strings.ToLower(packageName)

	variables := map[string]interface{}{
		"ProjectName": req.Name,
		"ModuleName":  req.ModuleName,
		"PackageName": packageName,
		"Description": fmt.Sprintf("A %s project", req.ProjectType),
	}

	// Add custom variables
	for k, v := range req.Variables {
		variables[k] = v
	}

	return variables
}

func (s *ProjectStructureService) processTemplate(content string, variables map[string]interface{}) (string, error) {
	tmpl, err := template.New("content").Parse(content)
	if err != nil {
		return "", err
	}

	var buf strings.Builder
	if err := tmpl.Execute(&buf, variables); err != nil {
		return "", err
	}

	return buf.String(), nil
}

func (s *ProjectStructureService) hasFile(structure *domain.ProjectStructure, fileName string) bool {
	for _, file := range structure.Files {
		if file.Path == fileName {
			return true
		}
	}
	return false
}

func (s *ProjectStructureService) fileExists(basePath, fileName string) bool {
	fullPath := filepath.Join(basePath, fileName)
	_, err := os.Stat(fullPath)
	return !os.IsNotExist(err)
}

func (s *ProjectStructureService) detectProjectType(path string) domain.ProjectType {
	// Enhanced project type detection logic

	// Check for CLI project patterns
	if s.fileExists(path, "cmd") && s.fileExists(path, "internal/commands") {
		return domain.ProjectTypeCLI
	}

	// Check for worker project patterns
	if s.fileExists(path, "cmd/worker") || s.fileExists(path, "internal/infrastructure/queue") {
		return domain.ProjectTypeWorker
	}

	// Check for library project patterns
	if s.fileExists(path, "pkg") && !s.fileExists(path, "cmd/server") {
		return domain.ProjectTypeLibrary
	}

	// Check for API project patterns (similar to microservice but with swagger/docs)
	if s.fileExists(path, "docs/swagger") || s.fileExists(path, "internal/infrastructure/http") {
		if s.containsSwaggerFiles(path) {
			return domain.ProjectTypeAPI
		}
		return domain.ProjectTypeMicroservice
	}

	// Check for microservice patterns
	if s.fileExists(path, "cmd/server") && s.fileExists(path, "internal") {
		return domain.ProjectTypeMicroservice
	}

	// Fallback based on directory structure
	if s.fileExists(path, "cmd") && s.fileExists(path, "internal") {
		return domain.ProjectTypeMicroservice
	}

	// Default to microservice for unknown patterns
	return domain.ProjectTypeMicroservice
}

// Default file templates

func (s *ProjectStructureService) getDefaultGitIgnore() string {
	return `# Binaries
*.exe
*.exe~
*.dll
*.so
*.dylib
bin/

# Test files
*.test
*.out

# IDE
.vscode/
.idea/

# OS
.DS_Store

# Logs
*.log
logs/

# Generated
generated/
tmp/
`
}

func (s *ProjectStructureService) getDefaultReadme() string {
	return `# {{.ProjectName}}

{{.Description}}

## Getting Started

` + "```bash" + `
go run cmd/server/main.go
` + "```" + `

## Development

` + "```bash" + `
make build
make test
` + "```" + `
`
}

func (s *ProjectStructureService) getDefaultDockerfile() string {
	return `FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY . .
RUN go build -o main cmd/server/main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/main .
CMD ["./main"]
`
}

func (s *ProjectStructureService) getDefaultMakefile() string {
	return `build:
	go build -o bin/server cmd/server/main.go

run:
	go run cmd/server/main.go

test:
	go test ./...

clean:
	rm -rf bin/

docker-build:
	docker build -t {{.ProjectName}} .

docker-run:
	docker run -p 8080:8080 {{.ProjectName}}

.PHONY: build run test clean docker-build docker-run
`
}

// hasGoModFile checks if the project structure contains a go.mod file
func (s *ProjectStructureService) hasGoModFile(structure *domain.ProjectStructure) bool {
	for _, file := range structure.Files {
		if file.Path == "go.mod" {
			return true
		}
	}
	return false
}

// runGoModTidy executes 'go mod tidy' in the specified directory
func (s *ProjectStructureService) runGoModTidy(projectPath string) error {
	cmd := exec.Command("go", "mod", "tidy")
	cmd.Dir = projectPath

	// Capture output for debugging
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("go mod tidy failed: %w\nOutput: %s", err, string(output))
	}

	fmt.Printf("Successfully ran 'go mod tidy' for project at %s\n", projectPath)
	return nil
}

// containsSwaggerFiles checks if the project contains swagger-related files
func (s *ProjectStructureService) containsSwaggerFiles(path string) bool {
	swaggerPaths := []string{
		"docs/swagger.yaml",
		"docs/swagger.json",
		"docs/docs.go",
		"api/swagger.yaml",
		"openapi.yaml",
	}

	for _, swaggerPath := range swaggerPaths {
		if s.fileExists(path, swaggerPath) {
			return true
		}
	}
	return false
}

// Project-type-specific validation methods

func (s *ProjectStructureService) validateCommonStructure(path string, result *domain.ProjectStructureValidationResult) {
	// Check for essential files common to all Go projects
	if !s.fileExists(path, "go.mod") {
		result.MissingFiles = append(result.MissingFiles, "go.mod")
		result.IsValid = false
	}

	// Add recommendations for common files
	if !s.fileExists(path, "README.md") {
		result.Recommendations = append(result.Recommendations, "Consider adding a README.md file")
	}
	if !s.fileExists(path, ".gitignore") {
		result.Recommendations = append(result.Recommendations, "Consider adding a .gitignore file")
	}
}

func (s *ProjectStructureService) validateMicroserviceStructure(path string, result *domain.ProjectStructureValidationResult) {
	requiredDirs := []string{"cmd/server", "internal/domain", "internal/application"}
	for _, dir := range requiredDirs {
		if !s.fileExists(path, dir) {
			result.MissingDirs = append(result.MissingDirs, dir)
			result.IsValid = false
		}
	}

	// Recommendations
	if !s.fileExists(path, "Makefile") {
		result.Recommendations = append(result.Recommendations, "Consider adding a Makefile for build automation")
	}
	if !s.fileExists(path, "Dockerfile") {
		result.Recommendations = append(result.Recommendations, "Consider adding a Dockerfile for containerization")
	}
}

func (s *ProjectStructureService) validateCLIStructure(path string, result *domain.ProjectStructureValidationResult) {
	requiredDirs := []string{"cmd", "internal/commands"}
	for _, dir := range requiredDirs {
		if !s.fileExists(path, dir) {
			result.MissingDirs = append(result.MissingDirs, dir)
			result.IsValid = false
		}
	}

	// Check for main.go in cmd
	if !s.fileExists(path, "cmd/main.go") {
		result.MissingFiles = append(result.MissingFiles, "cmd/main.go")
		result.IsValid = false
	}

	// Recommendations
	if !s.fileExists(path, "internal/config") {
		result.Recommendations = append(result.Recommendations, "Consider adding internal/config for configuration management")
	}
}

func (s *ProjectStructureService) validateLibraryStructure(path string, result *domain.ProjectStructureValidationResult) {
	// Libraries should have main package files or pkg directory
	hasMainFile := s.fileExists(path, "lib.go") || s.fileExists(path, fmt.Sprintf("%s.go", filepath.Base(path)))
	hasPkgDir := s.fileExists(path, "pkg")

	if !hasMainFile && !hasPkgDir {
		result.MissingFiles = append(result.MissingFiles, "lib.go or pkg/ directory")
		result.IsValid = false
	}

	// Check for test files
	if !s.fileExists(path, "lib_test.go") && !s.containsTestFiles(path) {
		result.Recommendations = append(result.Recommendations, "Consider adding test files for your library")
	}

	// Recommendations
	if !s.fileExists(path, "examples") {
		result.Recommendations = append(result.Recommendations, "Consider adding an examples/ directory")
	}
	if !s.fileExists(path, "LICENSE") {
		result.Recommendations = append(result.Recommendations, "Consider adding a LICENSE file for open source libraries")
	}
}

func (s *ProjectStructureService) validateAPIStructure(path string, result *domain.ProjectStructureValidationResult) {
	// API projects are similar to microservices but with additional API-specific requirements
	s.validateMicroserviceStructure(path, result)

	// Additional API-specific checks
	if !s.fileExists(path, "docs/swagger") && !s.containsSwaggerFiles(path) {
		result.Recommendations = append(result.Recommendations, "Consider adding OpenAPI/Swagger documentation")
	}
}

func (s *ProjectStructureService) validateWorkerStructure(path string, result *domain.ProjectStructureValidationResult) {
	requiredDirs := []string{"cmd/worker", "internal/domain"}
	for _, dir := range requiredDirs {
		if !s.fileExists(path, dir) {
			result.MissingDirs = append(result.MissingDirs, dir)
			result.IsValid = false
		}
	}

	// Recommendations
	if !s.fileExists(path, "internal/infrastructure/queue") {
		result.Recommendations = append(result.Recommendations, "Consider adding internal/infrastructure/queue for job queue management")
	}
}

// containsTestFiles checks if the directory contains any Go test files
func (s *ProjectStructureService) containsTestFiles(path string) bool {
	files, err := os.ReadDir(path)
	if err != nil {
		return false
	}

	for _, file := range files {
		if !file.IsDir() && strings.HasSuffix(file.Name(), "_test.go") {
			return true
		}
	}
	return false
}
