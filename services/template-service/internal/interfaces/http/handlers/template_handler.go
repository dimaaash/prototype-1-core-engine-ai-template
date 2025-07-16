package handlers

import (
	"net/http"

	"go-factory-platform/services/template-service/internal/application"
	"go-factory-platform/services/template-service/internal/domain"

	"github.com/gin-gonic/gin"
)

// TemplateHandler handles HTTP requests for templates
type TemplateHandler struct {
	service *application.TemplateApplicationService
}

// NewTemplateHandler creates a new template handler
func NewTemplateHandler(service *application.TemplateApplicationService) *TemplateHandler {
	return &TemplateHandler{
		service: service,
	}
}

// CreateTemplate creates a new template
func (h *TemplateHandler) CreateTemplate(c *gin.Context) {
	var template domain.Template
	if err := c.ShouldBindJSON(&template); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.service.CreateTemplate(&template); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, template)
}

// GetTemplate retrieves a template by ID
func (h *TemplateHandler) GetTemplate(c *gin.Context) {
	id := c.Param("id")
	template, err := h.service.GetTemplate(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, template)
}

// GetTemplatesByCategory retrieves templates by category
func (h *TemplateHandler) GetTemplatesByCategory(c *gin.Context) {
	category := domain.TemplateCategory(c.Query("category"))
	templates, err := h.service.GetTemplatesByCategory(category)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, templates)
}

// ProcessTemplate processes a template request
func (h *TemplateHandler) ProcessTemplate(c *gin.Context) {
	var request domain.TemplateRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	result, err := h.service.ProcessTemplate(&request)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}

// CreateRepositoryTemplate creates a repository template
func (h *TemplateHandler) CreateRepositoryTemplate(c *gin.Context) {
	var req struct {
		Name       string `json:"name"`
		EntityName string `json:"entity_name"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	template, err := h.service.CreateRepositoryTemplate(req.Name, req.EntityName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, template)
}

// CreateServiceTemplate creates a service template
func (h *TemplateHandler) CreateServiceTemplate(c *gin.Context) {
	var req struct {
		Name       string `json:"name"`
		EntityName string `json:"entity_name"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	template, err := h.service.CreateServiceTemplate(req.Name, req.EntityName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, template)
}

// CreateHandlerTemplate creates a handler template
func (h *TemplateHandler) CreateHandlerTemplate(c *gin.Context) {
	var req struct {
		Name       string `json:"name"`
		EntityName string `json:"entity_name"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	template, err := h.service.CreateHandlerTemplate(req.Name, req.EntityName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, template)
}

// RegisterRoutes registers the template routes
func (h *TemplateHandler) RegisterRoutes(router *gin.Engine) {
	api := router.Group("/api/v1")
	{
		api.POST("/templates", h.CreateTemplate)
		api.GET("/templates/:id", h.GetTemplate)
		api.GET("/templates", h.GetTemplatesByCategory)
		api.POST("/templates/process", h.ProcessTemplate)
		api.POST("/templates/repository", h.CreateRepositoryTemplate)
		api.POST("/templates/service", h.CreateServiceTemplate)
		api.POST("/templates/handler", h.CreateHandlerTemplate)
	}
}
