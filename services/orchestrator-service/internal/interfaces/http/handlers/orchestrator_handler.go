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
			orchestrate.POST("/microservice", h.OrchestrateMicroservice)
			orchestrate.POST("/payload", h.GetGeneratorPayload)
			orchestrate.POST("/entity", h.CreateEntityPayload)
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
