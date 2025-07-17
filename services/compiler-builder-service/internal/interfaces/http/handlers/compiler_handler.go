package handlers

import (
	"net/http"
	"os"
	"path/filepath"

	"go-factory-platform/services/compiler-builder-service/internal/application"
	"go-factory-platform/services/compiler-builder-service/internal/domain"

	"github.com/gin-gonic/gin"
)

// Always use this directory for all file/project operations
var generatedDir = filepath.Join(getSolutionRoot(), "generated")

// getSolutionRoot returns the root directory of the solution (not the service)
func getSolutionRoot() string {
	// Get the current working directory
	dir, err := os.Getwd()
	if err != nil {
		return "." // fallback
	}

	// If we're running from a service directory, go up to solution root
	// Services are typically in services/<service-name>, so we need to go up 2 levels
	if filepath.Base(filepath.Dir(dir)) == "services" {
		return filepath.Dir(filepath.Dir(dir))
	}

	// If we're already in the solution root, use it
	return dir
}

// CompilerHandler handles HTTP requests for compilation
type CompilerHandler struct {
	service *application.CompilerApplicationService
}

// NewCompilerHandler creates a new compiler handler
func NewCompilerHandler(service *application.CompilerApplicationService) *CompilerHandler {
	return &CompilerHandler{
		service: service,
	}
}

// WriteFiles writes accumulated files to filesystem
func (h *CompilerHandler) WriteFiles(c *gin.Context) {
	var req struct {
		Files      []domain.GeneratedFile `json:"files"`
		OutputPath string                 `json:"output_path"`
		Metadata   map[string]string      `json:"metadata"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	accumulator := &domain.CodeAccumulator{
		Files:    req.Files,
		Metadata: req.Metadata,
	}

	// Force outputPath to generatedDir
	if err := h.service.WriteFiles(c.Request.Context(), accumulator, generatedDir); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Files written successfully",
		"count":   len(req.Files),
		"path":    req.OutputPath,
	})
}

// CompileProject compiles a Go project
func (h *CompilerHandler) CompileProject(c *gin.Context) {
	var req struct {
		ProjectPath string `json:"project_path"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Force projectPath to generatedDir
	result, err := h.service.CompileProject(c.Request.Context(), generatedDir)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}

// BuildProject builds a Go project
func (h *CompilerHandler) BuildProject(c *gin.Context) {
	var req struct {
		ProjectPath string `json:"project_path"`
		OutputPath  string `json:"output_path"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Force projectPath and outputPath to generatedDir
	result, err := h.service.BuildProject(c.Request.Context(), generatedDir, generatedDir)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}

// ValidateCode validates generated code files
func (h *CompilerHandler) ValidateCode(c *gin.Context) {
	var req struct {
		Files []domain.GeneratedFile `json:"files"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	result, err := h.service.ValidateCode(c.Request.Context(), req.Files)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}

// CreateProject creates a new Go project
func (h *CompilerHandler) CreateProject(c *gin.Context) {
	var structure domain.ProjectStructure
	if err := c.ShouldBindJSON(&structure); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Force RootPath to generatedDir
	structure.RootPath = generatedDir
	if err := h.service.CreateProject(c.Request.Context(), &structure); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Project created successfully",
		"path":    structure.RootPath,
	})
}

// CreateStandardProject creates a standard Go project structure
func (h *CompilerHandler) CreateStandardProject(c *gin.Context) {
	var req struct {
		RootPath   string `json:"root_path"`
		ModuleName string `json:"module_name"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Force RootPath to generatedDir
	structure, err := h.service.CreateStandardProjectStructure(c.Request.Context(), generatedDir, req.ModuleName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, structure)
}

// FormatCode formats Go code
func (h *CompilerHandler) FormatCode(c *gin.Context) {
	var req struct {
		Content string `json:"content"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	formatted, err := h.service.FormatCode(c.Request.Context(), req.Content)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"formatted_content": formatted,
	})
}

// InitializeGoModule initializes a Go module
func (h *CompilerHandler) InitializeGoModule(c *gin.Context) {
	var req struct {
		ProjectPath string `json:"project_path"`
		ModuleName  string `json:"module_name"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.service.InitializeGoModule(c.Request.Context(), req.ProjectPath, req.ModuleName); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Go module initialized successfully",
		"path":    req.ProjectPath,
		"module":  req.ModuleName,
	})
}

// ProcessGeneratedFiles processes files from generator service
func (h *CompilerHandler) ProcessGeneratedFiles(c *gin.Context) {
	var req struct {
		Files       []domain.GeneratedFile `json:"files"`
		Metadata    map[string]string      `json:"metadata"`
		ProjectPath string                 `json:"project_path"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	accumulator := &domain.CodeAccumulator{
		Files:    req.Files,
		Metadata: req.Metadata,
	}

	result, err := h.service.ProcessGeneratedFiles(c.Request.Context(), accumulator, req.ProjectPath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}

// RegisterRoutes registers the compiler routes
func (h *CompilerHandler) RegisterRoutes(router *gin.Engine) {
	api := router.Group("/api/v1")
	{
		api.POST("/files/write", h.WriteFiles)
		api.POST("/compile", h.CompileProject)
		api.POST("/build", h.BuildProject)
		api.POST("/validate", h.ValidateCode)
		api.POST("/projects", h.CreateProject)
		api.POST("/projects/standard", h.CreateStandardProject)
		api.POST("/format", h.FormatCode)
		api.POST("/modules/init", h.InitializeGoModule)
		api.POST("/process", h.ProcessGeneratedFiles)
	}
}
