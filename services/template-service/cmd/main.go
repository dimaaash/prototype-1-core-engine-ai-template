package main

import (
	"log"
	"os"

	"go-factory-platform/services/template-service/internal/application"
	"go-factory-platform/services/template-service/internal/infrastructure"
	"go-factory-platform/services/template-service/internal/interfaces/http/handlers"

	"github.com/gin-gonic/gin"
)

func main() {
	// Get database URL from environment variable or use default
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = "postgresql://postgres:postgres@127.0.0.1:54322/postgres?sslmode=disable"
	}

	// Initialize dependencies
	repository := infrastructure.NewInMemoryTemplateRepository()
	publicTemplateRepo, err := infrastructure.NewPostgreSQLPublicTemplateRepository(dbURL)
	if err != nil {
		log.Fatal("Failed to initialize public template repository:", err)
	}
	buildingBlockClient := infrastructure.NewHTTPBuildingBlockClient("http://localhost:8081")
	service := application.NewTemplateApplicationService(repository, publicTemplateRepo, buildingBlockClient)
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
