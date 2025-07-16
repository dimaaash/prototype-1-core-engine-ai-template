package main

import (
	"log"

	"go-factory-platform/services/generator-service/internal/application"
	"go-factory-platform/services/generator-service/internal/infrastructure"
	"go-factory-platform/services/generator-service/internal/interfaces/http/handlers"

	"github.com/gin-gonic/gin"
)

func main() {
	// Initialize dependencies
	templateClient := infrastructure.NewHTTPTemplateServiceClient("http://localhost:8082")
	compilerClient := infrastructure.NewHTTPCompilerServiceClient("http://localhost:8084")
	service := application.NewGeneratorApplicationService(templateClient, compilerClient)
	handler := handlers.NewGeneratorHandler(service)

	// Initialize Gin router
	router := gin.Default()

	// Register routes
	handler.RegisterRoutes(router)

	// Start server
	log.Println("Generator Service starting on port 8083...")
	if err := router.Run(":8083"); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
