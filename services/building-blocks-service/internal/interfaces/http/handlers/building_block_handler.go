package handlers

import (
	"net/http"

	"go-factory-platform/services/building-blocks-service/internal/application"
	"go-factory-platform/services/building-blocks-service/internal/domain"

	"github.com/gin-gonic/gin"
)

// BuildingBlockHandler handles HTTP requests for building blocks
type BuildingBlockHandler struct {
	service *application.BuildingBlockApplicationService
}

// NewBuildingBlockHandler creates a new building block handler
func NewBuildingBlockHandler(service *application.BuildingBlockApplicationService) *BuildingBlockHandler {
	return &BuildingBlockHandler{
		service: service,
	}
}

// CreateBuildingBlock creates a new building block
func (h *BuildingBlockHandler) CreateBuildingBlock(c *gin.Context) {
	var block domain.BuildingBlock
	if err := c.ShouldBindJSON(&block); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.service.CreateBuildingBlock(&block); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, block)
}

// GetBuildingBlock retrieves a building block by ID
func (h *BuildingBlockHandler) GetBuildingBlock(c *gin.Context) {
	id := c.Param("id")
	block, err := h.service.GetBuildingBlock(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, block)
}

// GetPrimitiveBlocks returns all primitive building blocks
func (h *BuildingBlockHandler) GetPrimitiveBlocks(c *gin.Context) {
	blocks, err := h.service.GetPrimitiveBlocks()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, blocks)
}

// CreateVariableBlock creates a variable building block
func (h *BuildingBlockHandler) CreateVariableBlock(c *gin.Context) {
	var req struct {
		Name         string `json:"name"`
		Type         string `json:"type"`
		DefaultValue string `json:"default_value"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	block, err := h.service.CreateVariableBlock(req.Name, req.Type, req.DefaultValue)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, block)
}

// CreateStructBlock creates a struct building block
func (h *BuildingBlockHandler) CreateStructBlock(c *gin.Context) {
	var req struct {
		Name    string              `json:"name"`
		Package string              `json:"package"`
		Fields  []domain.GoVariable `json:"fields"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	block, err := h.service.CreateStructBlock(req.Name, req.Package, req.Fields)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, block)
}

// RegisterRoutes registers the building block routes
func (h *BuildingBlockHandler) RegisterRoutes(router *gin.Engine) {
	api := router.Group("/api/v1")
	{
		api.POST("/building-blocks", h.CreateBuildingBlock)
		api.GET("/building-blocks/:id", h.GetBuildingBlock)
		api.GET("/building-blocks/primitives", h.GetPrimitiveBlocks)
		api.POST("/building-blocks/variable", h.CreateVariableBlock)
		api.POST("/building-blocks/struct", h.CreateStructBlock)
	}
}
