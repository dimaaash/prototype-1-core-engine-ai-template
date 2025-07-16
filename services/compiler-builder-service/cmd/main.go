package main

import (
	"log"

	"go-factory-platform/services/compiler-builder-service/internal/application"
	"go-factory-platform/services/compiler-builder-service/internal/infrastructure"
	"go-factory-platform/services/compiler-builder-service/internal/interfaces/http/handlers"

	"github.com/gin-gonic/gin"
)

func main() {
	// Initialize dependencies
	fileSystemService := infrastructure.NewLocalFileSystemService()
	compilerService := infrastructure.NewGoCompilerService()
	projectService := infrastructure.NewGoProjectService(fileSystemService)

	service := application.NewCompilerApplicationService(
		fileSystemService,
		compilerService,
		projectService,
	)

	handler := handlers.NewCompilerHandler(service)

	// Initialize Gin router
	router := gin.Default()

	// Register routes
	handler.RegisterRoutes(router)

	// Start server
	log.Println("Compiler Builder Service starting on port 8084...")
	if err := router.Run(":8084"); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
