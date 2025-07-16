package main

import (
	"log"

	"go-factory-platform/services/template-service/internal/application"
	"go-factory-platform/services/template-service/internal/infrastructure"
	"go-factory-platform/services/template-service/internal/interfaces/http/handlers"

	"github.com/gin-gonic/gin"
)

func main() {
	// Initialize dependencies
	repository := infrastructure.NewInMemoryTemplateRepository()
	buildingBlockClient := infrastructure.NewHTTPBuildingBlockClient("http://localhost:8081")
	service := application.NewTemplateApplicationService(repository, buildingBlockClient)
	handler := handlers.NewTemplateHandler(service)

	// Initialize Gin router
	router := gin.Default()

	// Register routes
	handler.RegisterRoutes(router)

	// Start server
	log.Println("Template Service starting on port 8082...")
	if err := router.Run(":8082"); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
