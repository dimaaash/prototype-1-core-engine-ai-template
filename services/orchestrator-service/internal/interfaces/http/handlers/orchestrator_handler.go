package handlers

import (
	"fmt"
	"net/http"
	"time"

	"go-factory-platform/services/orchestrator-service/internal/application"
	"go-factory-platform/services/orchestrator-service/internal/domain"

	"github.com/gin-gonic/gin"
)

// OrchestratorHandler handles HTTP requests for orchestration
type OrchestratorHandler struct {
	service *application.OrchestratorService
}

// NewOrchestratorHandler creates a new orchestrator handler
func NewOrchestratorHandler(service *application.OrchestratorService) *OrchestratorHandler {
	return &OrchestratorHandler{
		service: service,
	}
}

// OrchestrateMicroservice handles microservice orchestration requests
// @Summary Orchestrate microservice generation
// @Description Convert high-level project specification to detailed generator payload
// @Tags orchestrator
// @Accept json
// @Produce json
// @Param project body domain.ProjectSpecification true "Project specification"
// @Success 200 {object} domain.OrchestrationResult
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/v1/orchestrate/microservice [post]
func (h *OrchestratorHandler) OrchestrateMicroservice(c *gin.Context) {
	var spec domain.ProjectSpecification
	if err := c.ShouldBindJSON(&spec); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body: " + err.Error()})
		return
	}

	// Validate specification
	if err := h.validateProjectSpecification(&spec); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid specification: " + err.Error()})
		return
	}

	result, err := h.service.OrchestrateMicroservice(&spec)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Orchestration failed: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}

// GetGeneratorPayload handles requests to get only the generator payload
// @Summary Get generator payload
// @Description Convert project specification to generator payload only
// @Tags orchestrator
// @Accept json
// @Produce json
// @Param project body domain.ProjectSpecification true "Project specification"
// @Success 200 {object} domain.GeneratorPayload
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/v1/orchestrate/payload [post]
func (h *OrchestratorHandler) GetGeneratorPayload(c *gin.Context) {
	var spec domain.ProjectSpecification
	if err := c.ShouldBindJSON(&spec); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body: " + err.Error()})
		return
	}

	// Validate specification
	if err := h.validateProjectSpecification(&spec); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid specification: " + err.Error()})
		return
	}

	result, err := h.service.OrchestrateMicroservice(&spec)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Orchestration failed: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, result.GeneratorPayload)
}

// CreateEntityPayload handles requests to create payload for a single entity
// @Summary Create entity payload
// @Description Convert single entity specification to generator payload
// @Tags orchestrator
// @Accept json
// @Produce json
// @Param entity body CreateEntityRequest true "Entity specification"
// @Success 200 {object} domain.GeneratorPayload
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/v1/orchestrate/entity [post]
func (h *OrchestratorHandler) CreateEntityPayload(c *gin.Context) {
	var req CreateEntityRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body: " + err.Error()})
		return
	}

	// Create a minimal project specification for the entity
	spec := domain.ProjectSpecification{
		Name:        req.ProjectName,
		ModulePath:  req.ModulePath,
		OutputPath:  req.OutputPath,
		ProjectType: "microservice",
		Entities:    []domain.EntitySpecification{req.Entity},
	}

	result, err := h.service.OrchestrateMicroservice(&spec)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Entity orchestration failed: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, result.GeneratorPayload)
}

// HealthCheck handles health check requests
// @Summary Health check
// @Description Check if the orchestrator service is healthy
// @Tags health
// @Produce json
// @Success 200 {object} map[string]string
// @Router /health [get]
func (h *OrchestratorHandler) HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":    "healthy",
		"service":   "orchestrator-service",
		"timestamp": time.Now().Format(time.RFC3339),
	})
}

// RegisterRoutes registers all orchestrator routes
func (h *OrchestratorHandler) RegisterRoutes(router *gin.Engine) {
	// Health check
	router.GET("/health", h.HealthCheck)

	// API routes
	api := router.Group("/api/v1")
	{
		orchestrate := api.Group("/orchestrate")
		{
			// Generic orchestration (backwards compatible)
			orchestrate.POST("/microservice", h.OrchestrateMicroservice)
			orchestrate.POST("/payload", h.GetGeneratorPayload)
			orchestrate.POST("/entity", h.CreateEntityPayload)

			// Project type specific orchestration
			orchestrate.POST("/api", h.OrchestrateAPI)
			orchestrate.POST("/cli", h.OrchestrateCLI)
			orchestrate.POST("/library", h.OrchestrateLibrary)
			orchestrate.POST("/web", h.OrchestrateWeb)
			orchestrate.POST("/worker", h.OrchestrateWorker)
		}

		// Project type information
		info := api.Group("/info")
		{
			info.GET("/project-types", h.GetProjectTypes)
			info.GET("/features", h.GetAvailableFeatures)
			info.GET("/types", h.GetAvailableTypes)
		}
	}
}

// Request types

// CreateEntityRequest represents a request to create payload for a single entity
type CreateEntityRequest struct {
	ProjectName string                     `json:"project_name"`
	ModulePath  string                     `json:"module_path"`
	OutputPath  string                     `json:"output_path"`
	Entity      domain.EntitySpecification `json:"entity"`
}

// Validation methods

func (h *OrchestratorHandler) validateProjectSpecification(spec *domain.ProjectSpecification) error {
	if spec.Name == "" {
		return fmt.Errorf("project name is required")
	}

	if spec.ModulePath == "" {
		return fmt.Errorf("module path is required")
	}

	if spec.OutputPath == "" {
		return fmt.Errorf("output path is required")
	}

	if len(spec.Entities) == 0 {
		return fmt.Errorf("at least one entity is required")
	}

	// Validate each entity
	for i, entity := range spec.Entities {
		if err := h.validateEntitySpecification(&entity); err != nil {
			return fmt.Errorf("entity %d (%s): %w", i, entity.Name, err)
		}
	}

	return nil
}

func (h *OrchestratorHandler) validateEntitySpecification(entity *domain.EntitySpecification) error {
	if entity.Name == "" {
		return fmt.Errorf("entity name is required")
	}

	if len(entity.Fields) == 0 {
		return fmt.Errorf("at least one field is required")
	}

	// Validate each field
	for i, field := range entity.Fields {
		if field.Name == "" {
			return fmt.Errorf("field %d: name is required", i)
		}
		if field.Type == "" {
			return fmt.Errorf("field %d (%s): type is required", i, field.Name)
		}
	}

	return nil
}

// Project type specific orchestration handlers

// OrchestrateAPI handles API project orchestration
func (h *OrchestratorHandler) OrchestrateAPI(c *gin.Context) {
	h.orchestrateProjectType(c, "api")
}

// OrchestrateCLI handles CLI project orchestration
func (h *OrchestratorHandler) OrchestrateCLI(c *gin.Context) {
	h.orchestrateProjectType(c, "cli")
}

// OrchestrateLibrary handles library project orchestration
func (h *OrchestratorHandler) OrchestrateLibrary(c *gin.Context) {
	h.orchestrateProjectType(c, "library")
}

// OrchestrateWeb handles web project orchestration
func (h *OrchestratorHandler) OrchestrateWeb(c *gin.Context) {
	h.orchestrateProjectType(c, "web")
}

// OrchestrateWorker handles worker project orchestration
func (h *OrchestratorHandler) OrchestrateWorker(c *gin.Context) {
	h.orchestrateProjectType(c, "worker")
}

// orchestrateProjectType is a helper method for project type specific orchestration
func (h *OrchestratorHandler) orchestrateProjectType(c *gin.Context, projectType string) {
	var spec domain.ProjectSpecification
	if err := c.ShouldBindJSON(&spec); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body: " + err.Error()})
		return
	}

	// Set the project type
	spec.ProjectType = projectType

	// Validate specification
	if err := h.validateProjectSpecification(&spec); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid specification: " + err.Error()})
		return
	}

	result, err := h.service.OrchestrateMicroservice(&spec)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Orchestration failed: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}

// Information endpoints

// GetProjectTypes returns available project types and their configurations
func (h *OrchestratorHandler) GetProjectTypes(c *gin.Context) {
	projectTypes := make(map[string]interface{})

	for projectType, config := range domain.ProjectTypeMapping {
		projectTypes[projectType] = map[string]interface{}{
			"default_features":     config.DefaultFeatures,
			"required_structure":   config.RequiredStructure,
			"default_dependencies": config.DefaultDependencies,
			"description":          h.getProjectTypeDescription(projectType),
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"project_types": projectTypes,
		"count":         len(projectTypes),
	})
}

// GetAvailableFeatures returns all available features and their descriptions
func (h *OrchestratorHandler) GetAvailableFeatures(c *gin.Context) {
	features := make(map[string]interface{})

	for feature, implementations := range domain.FeatureMapping {
		features[feature] = map[string]interface{}{
			"implementations": implementations,
			"description":     h.getFeatureDescription(feature),
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"features": features,
		"count":    len(features),
	})
}

// GetAvailableTypes returns all available field types and their Go mappings
func (h *OrchestratorHandler) GetAvailableTypes(c *gin.Context) {
	types := make(map[string]interface{})

	for userType, goType := range domain.TypeMapping {
		types[userType] = map[string]interface{}{
			"go_type":     goType,
			"description": h.getTypeDescription(userType),
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"types": types,
		"count": len(types),
	})
}

// Helper methods for descriptions

func (h *OrchestratorHandler) getProjectTypeDescription(projectType string) string {
	descriptions := map[string]string{
		"microservice": "A complete microservice with REST API, database integration, and business logic",
		"api":          "A REST API service with endpoints, validation, and middleware",
		"cli":          "A command-line interface application with commands and flags",
		"library":      "A reusable Go library package with documentation and examples",
		"web":          "A web application with templates, static files, and session management",
		"worker":       "A background worker service for queue processing and scheduled jobs",
	}
	if desc, exists := descriptions[projectType]; exists {
		return desc
	}
	return "Custom project type"
}

func (h *OrchestratorHandler) getFeatureDescription(feature string) string {
	descriptions := map[string]string{
		"crud":          "Create, Read, Update, Delete operations for entities",
		"validation":    "Input validation and data sanitization",
		"rest_api":      "REST API endpoints with HTTP handlers",
		"repository":    "Data access layer with database integration",
		"service":       "Business logic layer with domain services",
		"monitoring":    "Health checks, metrics, and observability",
		"logging":       "Structured logging with multiple output formats",
		"security":      "Authentication, authorization, and encryption",
		"cache":         "Caching layer for improved performance",
		"events":        "Event-driven architecture with pub/sub",
		"messaging":     "Message queue integration for async processing",
		"cli":           "Command-line interface with argument parsing",
		"testing":       "Unit and integration test frameworks",
		"documentation": "API documentation and code comments",
	}
	if desc, exists := descriptions[feature]; exists {
		return desc
	}
	return "Custom feature implementation"
}

func (h *OrchestratorHandler) getTypeDescription(fieldType string) string {
	descriptions := map[string]string{
		"string":    "Basic text string",
		"integer":   "Whole number (32-bit)",
		"int64":     "Large whole number (64-bit)",
		"float":     "Decimal number (64-bit)",
		"boolean":   "True/false value",
		"uuid":      "Universally unique identifier",
		"email":     "Email address with validation",
		"timestamp": "Date and time with timezone",
		"json":      "JSON data structure",
		"array":     "Array of values",
		"decimal":   "High-precision decimal number",
		"enum":      "Predefined set of values",
		"binary":    "Binary data (byte array)",
	}
	if desc, exists := descriptions[fieldType]; exists {
		return desc
	}
	return "Custom data type"
}
