package handlers

import (
	"net/http"

	"go-factory-platform/services/project-structure-service/internal/application"
	"go-factory-platform/services/project-structure-service/internal/domain"

	"github.com/gin-gonic/gin"
)

// ProjectTemplateHandler handles HTTP requests for project templates
type ProjectTemplateHandler struct {
	service *application.ProjectTemplateService
}

// NewProjectTemplateHandler creates a new project template handler
func NewProjectTemplateHandler(service *application.ProjectTemplateService) *ProjectTemplateHandler {
	return &ProjectTemplateHandler{
		service: service,
	}
}

// CreateTemplate creates a new project template
func (h *ProjectTemplateHandler) CreateTemplate(c *gin.Context) {
	var template domain.ProjectTemplate
	if err := c.ShouldBindJSON(&template); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	result, err := h.service.CreateTemplate(&template)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, result)
}

// GetTemplate gets a project template by ID
func (h *ProjectTemplateHandler) GetTemplate(c *gin.Context) {
	id := c.Param("id")
	template, err := h.service.GetTemplate(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, template)
}

// GetTemplates gets all project templates, optionally filtered by type
func (h *ProjectTemplateHandler) GetTemplates(c *gin.Context) {
	projectType := c.Query("type")

	if projectType != "" {
		templates, err := h.service.GetTemplatesByType(domain.ProjectType(projectType))
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, templates)
		return
	}

	templates, err := h.service.GetAllTemplates()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, templates)
}

// UpdateTemplate updates a project template
func (h *ProjectTemplateHandler) UpdateTemplate(c *gin.Context) {
	id := c.Param("id")

	var template domain.ProjectTemplate
	if err := c.ShouldBindJSON(&template); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	template.ID = id
	if err := h.service.UpdateTemplate(&template); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, template)
}

// DeleteTemplate deletes a project template
func (h *ProjectTemplateHandler) DeleteTemplate(c *gin.Context) {
	id := c.Param("id")

	if err := h.service.DeleteTemplate(id); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Template deleted successfully"})
}

// RegisterRoutes registers the template routes
func (h *ProjectTemplateHandler) RegisterRoutes(router *gin.Engine) {
	api := router.Group("/api/v1")
	{
		api.POST("/templates", h.CreateTemplate)
		api.GET("/templates/:id", h.GetTemplate)
		api.GET("/templates", h.GetTemplates)
		api.PUT("/templates/:id", h.UpdateTemplate)
		api.DELETE("/templates/:id", h.DeleteTemplate)
	}
}

// ProjectStructureHandler handles HTTP requests for project structures
type ProjectStructureHandler struct {
	service *application.ProjectStructureService
}

// NewProjectStructureHandler creates a new project structure handler
func NewProjectStructureHandler(service *application.ProjectStructureService) *ProjectStructureHandler {
	return &ProjectStructureHandler{
		service: service,
	}
}

// CreateProjectStructure creates a new project structure
func (h *ProjectStructureHandler) CreateProjectStructure(c *gin.Context) {
	var req domain.CreateProjectStructureRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	structure, err := h.service.CreateProjectStructure(&req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, structure)
}

// WriteProjectStructure writes a project structure to filesystem
func (h *ProjectStructureHandler) WriteProjectStructure(c *gin.Context) {
	var structure domain.ProjectStructure
	if err := c.ShouldBindJSON(&structure); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.service.WriteProjectStructure(&structure); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Project structure written successfully",
		"path":    structure.OutputPath,
		"files":   len(structure.Files),
		"dirs":    len(structure.Directories),
	})
}

// CreateAndWriteProjectStructure creates and writes a project structure in one step
func (h *ProjectStructureHandler) CreateAndWriteProjectStructure(c *gin.Context) {
	var req domain.CreateProjectStructureRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Create structure
	structure, err := h.service.CreateProjectStructure(&req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Write to filesystem
	if err := h.service.WriteProjectStructure(structure); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":     err.Error(),
			"structure": structure,
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message":   "Project structure created and written successfully",
		"structure": structure,
		"path":      structure.OutputPath,
		"files":     len(structure.Files),
		"dirs":      len(structure.Directories),
	})
}

// ValidateProjectStructure validates a project structure
func (h *ProjectStructureHandler) ValidateProjectStructure(c *gin.Context) {
	var req domain.ValidateProjectStructureRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	result, err := h.service.ValidateProjectStructure(&req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}

// GetProjectTypes returns available project types
func (h *ProjectStructureHandler) GetProjectTypes(c *gin.Context) {
	types := []map[string]interface{}{
		{
			"type":        "microservice",
			"name":        "Microservice",
			"description": "Standard Go microservice with clean architecture",
		},
		{
			"type":        "cli",
			"name":        "CLI Tool",
			"description": "Command-line application using Cobra",
		},
		{
			"type":        "library",
			"name":        "Library",
			"description": "Reusable Go library package",
		},
		{
			"type":        "api",
			"name":        "API Service",
			"description": "REST API service with OpenAPI specification",
		},
		{
			"type":        "worker",
			"name":        "Worker Service",
			"description": "Background worker or job processor",
		},
	}

	c.JSON(http.StatusOK, gin.H{
		"project_types": types,
		"count":         len(types),
	})
}

// GetProjectStandards returns Go project structure standards and conventions
func (h *ProjectStructureHandler) GetProjectStandards(c *gin.Context) {
	standards := gin.H{
		"go_standard_layout": gin.H{
			"description": "Standard Go project layout based on golang-standards/project-layout",
			"directories": gin.H{
				"cmd":         "Main applications for this project",
				"internal":    "Private application and library code",
				"pkg":         "Library code that's ok to use by external applications",
				"api":         "OpenAPI/Swagger specs, JSON schema files, protocol definition files",
				"web":         "Web application specific components",
				"configs":     "Configuration file templates or default configs",
				"init":        "System init (systemd, upstart, sysv) and process manager/supervisor (runit, supervisord) configs",
				"scripts":     "Scripts to perform various build, install, analysis, etc operations",
				"build":       "Packaging and Continuous Integration",
				"deploy":      "IaaS, PaaS, system and container orchestration deployment configurations and templates",
				"test":        "Additional external test apps and test data",
				"docs":        "Design and user documents",
				"tools":       "Supporting tools for this project",
				"examples":    "Examples for your applications and/or public libraries",
				"third_party": "External helper tools, forked code and other 3rd party utilities",
				"githooks":    "Git hooks",
				"assets":      "Other assets to go along with your repository",
				"website":     "Project's website data if not using GitHub pages",
			},
		},
		"naming_conventions": gin.H{
			"packages":  "lowercase, single word, descriptive",
			"files":     "lowercase with underscores for separation",
			"functions": "CamelCase for exported, camelCase for unexported",
			"variables": "CamelCase for exported, camelCase for unexported",
			"constants": "CamelCase or ALL_CAPS for public constants",
		},
		"file_organization": gin.H{
			"main_package":     "Keep main.go files small, move logic to other packages",
			"internal_package": "Use internal/ for code that shouldn't be imported by other projects",
			"pkg_package":      "Use pkg/ for code that can be imported by other projects",
			"test_files":       "Place test files in the same package as the code being tested",
		},
	}

	c.JSON(http.StatusOK, standards)
}

// RegisterRoutes registers the project structure routes
func (h *ProjectStructureHandler) RegisterRoutes(router *gin.Engine) {
	api := router.Group("/api/v1")
	{
		// Project structure operations
		api.POST("/projects/structure", h.CreateProjectStructure)
		api.POST("/projects/structure/write", h.WriteProjectStructure)
		api.POST("/projects/create", h.CreateAndWriteProjectStructure)
		api.POST("/projects/validate", h.ValidateProjectStructure)

		// Metadata and standards
		api.GET("/projects/types", h.GetProjectTypes)
		api.GET("/projects/standards", h.GetProjectStandards)
	}
}
