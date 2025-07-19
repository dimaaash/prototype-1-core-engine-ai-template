package main

import (
	"log"
	"os"

	"go-factory-platform/services/orchestrator-service/internal/application"
	"go-factory-platform/services/orchestrator-service/internal/interfaces/http/handlers"

	"github.com/gin-gonic/gin"
)

func main() {
	// Get port from environment or use default
	port := os.Getenv("PORT")
	if port == "" {
		port = "8086" // Default port for orchestrator service
	}

	// Create services
	orchestratorService := application.NewOrchestratorService()

	// Create handlers
	orchestratorHandler := handlers.NewOrchestratorHandler(orchestratorService)

	// Setup Gin router
	router := gin.Default()

	// Register routes
	orchestratorHandler.RegisterRoutes(router)

	// Start server
	log.Printf("🎼 Orchestrator Service starting on port %s", port)
	log.Printf("🌐 Health check: http://localhost:%s/health", port)
	log.Printf("📋 API endpoints: http://localhost:%s/api/v1", port)

	if err := router.Run(":" + port); err != nil {
		log.Fatalf("❌ Failed to start server: %v", err)
	}
}
