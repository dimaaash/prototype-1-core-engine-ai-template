package handlers

import (
	"net/http"
	"time"

	"go-factory-platform/services/generator-service/internal/application"
	"go-factory-platform/services/generator-service/internal/domain"

	"github.com/gin-gonic/gin"
)

// GeneratorHandler handles HTTP requests for code generation
type GeneratorHandler struct {
	service *application.GeneratorApplicationService
}

// NewGeneratorHandler creates a new generator handler
func NewGeneratorHandler(service *application.GeneratorApplicationService) *GeneratorHandler {
	return &GeneratorHandler{
		service: service,
	}
}

// GenerateCode handles code generation requests
func (h *GeneratorHandler) GenerateCode(c *gin.Context) {
	var request domain.GenerationRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Parse raw elements into concrete types
	if err := request.ParseElements(); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to parse elements: " + err.Error()})
		return
	}

	// Set request ID if not provided
	if request.ID == "" {
		request.ID = generateRequestID()
	}
	request.CreatedAt = time.Now()

	result, err := h.service.GenerateCode(c.Request.Context(), &request)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}

// GenerateEntitySet generates a complete entity set (model, repository, service, handler)
func (h *GeneratorHandler) GenerateEntitySet(c *gin.Context) {
	var req struct {
		EntityName string `json:"entity_name"`
		ModulePath string `json:"module_path"`
		OutputPath string `json:"output_path"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Create elements for the entity
	elements := h.service.CreateCompleteEntitySet(req.EntityName, req.ModulePath)

	// Create generation request
	request := &domain.GenerationRequest{
		ID:          generateRequestID(),
		Elements:    elements,
		ModulePath:  req.ModulePath,
		OutputPath:  req.OutputPath,
		PackageName: "main",
		CreatedAt:   time.Now(),
	}

	result, err := h.service.GenerateCode(c.Request.Context(), request)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}

// CreateRepository creates a repository element
func (h *GeneratorHandler) CreateRepository(c *gin.Context) {
	var req struct {
		Name       string `json:"name"`
		EntityName string `json:"entity_name"`
		Package    string `json:"package"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	element := h.service.CreateRepositoryElement(req.Name, req.EntityName, req.Package)
	c.JSON(http.StatusCreated, element)
}

// CreateService creates a service element
func (h *GeneratorHandler) CreateService(c *gin.Context) {
	var req struct {
		Name       string `json:"name"`
		EntityName string `json:"entity_name"`
		Package    string `json:"package"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	element := h.service.CreateServiceElement(req.Name, req.EntityName, req.Package)
	c.JSON(http.StatusCreated, element)
}

// CreateHandler creates a handler element
func (h *GeneratorHandler) CreateHandler(c *gin.Context) {
	var req struct {
		Name       string `json:"name"`
		EntityName string `json:"entity_name"`
		Package    string `json:"package"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	element := h.service.CreateHandlerElement(req.Name, req.EntityName, req.Package)
	c.JSON(http.StatusCreated, element)
}

// CreateModel creates a model element
func (h *GeneratorHandler) CreateModel(c *gin.Context) {
	var req struct {
		Name    string                `json:"name"`
		Package string                `json:"package"`
		Fields  []domain.FieldElement `json:"fields"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	element := h.service.CreateModelElement(req.Name, req.Package, req.Fields)
	c.JSON(http.StatusCreated, element)
}

// RegisterRoutes registers the generator routes
func (h *GeneratorHandler) RegisterRoutes(router *gin.Engine) {
	api := router.Group("/api/v1")
	{
		api.POST("/generate", h.GenerateCode)
		api.POST("/generate/entity", h.GenerateEntitySet)
		api.POST("/elements/repository", h.CreateRepository)
		api.POST("/elements/service", h.CreateService)
		api.POST("/elements/handler", h.CreateHandler)
		api.POST("/elements/model", h.CreateModel)
	}
}

// generateRequestID generates a request ID
func generateRequestID() string {
	return "req_" + time.Now().Format("20060102150405")
}
