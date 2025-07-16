package main

import (
	"log"

	"go-factory-platform/services/building-blocks-service/internal/application"
	"go-factory-platform/services/building-blocks-service/internal/infrastructure"
	"go-factory-platform/services/building-blocks-service/internal/interfaces/http/handlers"

	"github.com/gin-gonic/gin"
)

func main() {
	// Initialize dependencies
	repository := infrastructure.NewInMemoryBuildingBlockRepository()
	builder := infrastructure.NewGoCodeElementBuilder()
	service := application.NewBuildingBlockApplicationService(repository, builder)
	handler := handlers.NewBuildingBlockHandler(service)

	// Initialize Gin router
	router := gin.Default()

	// Register routes
	handler.RegisterRoutes(router)

	// Start server
	log.Println("Building Blocks Service starting on port 8081...")
	if err := router.Run(":8081"); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
