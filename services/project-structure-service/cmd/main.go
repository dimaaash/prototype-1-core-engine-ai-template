package main

import (
	"log"
	"net/http"

	"go-factory-platform/services/project-structure-service/internal/application"
	"go-factory-platform/services/project-structure-service/internal/domain"
	"go-factory-platform/services/project-structure-service/internal/infrastructure"
	"go-factory-platform/services/project-structure-service/internal/interfaces/http/handlers"

	"github.com/gin-gonic/gin"
)

func main() {
	// Initialize repositories
	templateRepo := infrastructure.NewProjectTemplateRepository()
	structureRepo := infrastructure.NewProjectStructureRepository()

	// Initialize services
	templateService := application.NewProjectTemplateService(templateRepo)
	structureService := application.NewProjectStructureService(structureRepo, templateService)

	// Load default templates
	loadDefaultTemplates(templateService)

	// Initialize handlers
	templateHandler := handlers.NewProjectTemplateHandler(templateService)
	structureHandler := handlers.NewProjectStructureHandler(structureService)

	// Setup router
	router := gin.Default()

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "healthy",
			"service": "project-structure-service",
			"port":    "8085",
		})
	})

	// Register routes
	templateHandler.RegisterRoutes(router)
	structureHandler.RegisterRoutes(router)

	log.Println("🏗️ Project Structure Service starting on port 8085...")
	log.Fatal(router.Run(":8085"))
}

func loadDefaultTemplates(service *application.ProjectTemplateService) {
	// Microservice template
	microserviceTemplate := &domain.ProjectTemplate{
		Name:        "microservice",
		Description: "Standard Go microservice project structure",
		Type:        domain.ProjectTypeMicroservice,
		Directories: []string{
			"cmd/server",
			"internal/domain",
			"internal/application",
			"internal/infrastructure/http",
			"internal/infrastructure/persistence",
			"internal/interfaces/http/handlers",
			"pkg/api",
			"docs",
			"scripts",
			"configs",
		},
		BoilerplateFiles: map[string]string{
			"go.mod":             "module {{.ModuleName}}\n\ngo 1.21\n",
			"cmd/server/main.go": "package main\n\nimport (\n\t\"log\"\n\t\"net/http\"\n\n\t\"github.com/gin-gonic/gin\"\n)\n\nfunc main() {\n\trouter := gin.Default()\n\trouter.GET(\"/health\", func(c *gin.Context) {\n\t\tc.JSON(http.StatusOK, gin.H{\"status\": \"healthy\"})\n\t})\n\tlog.Println(\"Server starting on :8080\")\n\tlog.Fatal(router.Run(\":8080\"))\n}",
			"README.md":          "# {{.ProjectName}}\n\n{{.Description}}\n\n## Getting Started\n\n```bash\ngo run cmd/server/main.go\n```",
			"Dockerfile":         "FROM golang:1.21-alpine AS builder\nWORKDIR /app\nCOPY . .\nRUN go build -o main cmd/server/main.go\n\nFROM alpine:latest\nRUN apk --no-cache add ca-certificates\nWORKDIR /root/\nCOPY --from=builder /app/main .\nCMD [\"./main\"]",
			"Makefile":           "build:\n\tgo build -o bin/server cmd/server/main.go\n\nrun:\n\tgo run cmd/server/main.go\n\ntest:\n\tgo test ./...\n\nclean:\n\trm -rf bin/",
			".gitignore":         "# Binaries\n*.exe\n*.exe~\n*.dll\n*.so\n*.dylib\nbin/\n\n# Test files\n*.test\n*.out\n\n# IDE\n.vscode/\n.idea/\n\n# OS\n.DS_Store\n\n# Logs\n*.log\nlogs/",
		},
	}

	// CLI template
	cliTemplate := &domain.ProjectTemplate{
		Name:        "cli",
		Description: "Command-line tool project structure",
		Type:        domain.ProjectTypeCLI,
		Directories: []string{
			"cmd",
			"internal/commands",
			"internal/config",
			"pkg/utils",
			"docs",
		},
		BoilerplateFiles: map[string]string{
			"go.mod":      "module {{.ModuleName}}\n\ngo 1.21\n\nrequire (\n\tgithub.com/spf13/cobra v1.7.0\n\tgithub.com/spf13/viper v1.16.0\n)",
			"cmd/main.go": "package main\n\nimport (\n\t\"{{.ModuleName}}/internal/commands\"\n)\n\nfunc main() {\n\tcommands.Execute()\n}",
			"README.md":   "# {{.ProjectName}}\n\n{{.Description}}\n\n## Installation\n\n```bash\ngo install {{.ModuleName}}@latest\n```\n\n## Usage\n\n```bash\n{{.ProjectName}} --help\n```",
			"Makefile":    "build:\n\tgo build -o bin/{{.ProjectName}} cmd/main.go\n\ninstall:\n\tgo install cmd/main.go\n\ntest:\n\tgo test ./...\n\nclean:\n\trm -rf bin/",
		},
	}

	// Library template
	libraryTemplate := &domain.ProjectTemplate{
		Name:        "library",
		Description: "Go library project structure",
		Type:        domain.ProjectTypeLibrary,
		Directories: []string{
			"pkg",
			"examples",
			"docs",
			"internal",
		},
		BoilerplateFiles: map[string]string{
			"go.mod":    "module {{.ModuleName}}\n\ngo 1.21\n",
			"README.md": "# {{.ProjectName}}\n\n{{.Description}}\n\n## Installation\n\n```bash\ngo get {{.ModuleName}}\n```\n\n## Usage\n\n```go\nimport \"{{.ModuleName}}\"\n```",
			"LICENSE":   "MIT License\n\nCopyright (c) 2025\n\nPermission is hereby granted, free of charge, to any person obtaining a copy...",
		},
	}

	// Add templates
	service.CreateTemplate(microserviceTemplate)
	service.CreateTemplate(cliTemplate)
	service.CreateTemplate(libraryTemplate)

	log.Println("✅ Default project templates loaded")
}
