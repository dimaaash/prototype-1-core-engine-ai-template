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
	microserviceTemplate := domain.NewProjectTemplate(
		"microservice",
		"Standard Go microservice project structure",
		domain.ProjectTypeMicroservice,
	)
	microserviceTemplate.Directories = []string{
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
	}
	microserviceTemplate.BoilerplateFiles = map[string]string{
		"go.mod":             "module {{.ModuleName}}\n\ngo 1.21\n",
		"cmd/server/main.go": "package main\n\nimport (\n\t\"log\"\n\t\"net/http\"\n\n\t\"github.com/gin-gonic/gin\"\n)\n\nfunc main() {\n\trouter := gin.Default()\n\trouter.GET(\"/health\", func(c *gin.Context) {\n\t\tc.JSON(http.StatusOK, gin.H{\"status\": \"healthy\"})\n\t})\n\tlog.Println(\"Server starting on :8080\")\n\tlog.Fatal(router.Run(\":8080\"))\n}",
		"README.md":          "# {{.ProjectName}}\n\n{{.Description}}\n\n## Getting Started\n\n```bash\ngo run cmd/server/main.go\n```",
		"Dockerfile":         "FROM golang:1.21-alpine AS builder\nWORKDIR /app\nCOPY . .\nRUN go build -o main cmd/server/main.go\n\nFROM alpine:latest\nRUN apk --no-cache add ca-certificates\nWORKDIR /root/\nCOPY --from=builder /app/main .\nCMD [\"./main\"]",
		"Makefile":           "build:\n\tgo build -o bin/server cmd/server/main.go\n\nrun:\n\tgo run cmd/server/main.go\n\ntest:\n\tgo test ./...\n\nclean:\n\trm -rf bin/",
		".gitignore":         "# Binaries\n*.exe\n*.exe~\n*.dll\n*.so\n*.dylib\nbin/\n\n# Test files\n*.test\n*.out\n\n# IDE\n.vscode/\n.idea/\n\n# OS\n.DS_Store\n\n# Logs\n*.log\nlogs/",
	}

	// CLI template
	cliTemplate := domain.NewProjectTemplate(
		"cli",
		"Command-line tool project structure",
		domain.ProjectTypeCLI,
	)
	cliTemplate.Directories = []string{
		"cmd",
		"internal/commands",
		"internal/config",
		"pkg/utils",
		"docs",
	}
	cliTemplate.BoilerplateFiles = map[string]string{
		"go.mod":      "module {{.ModuleName}}\n\ngo 1.21\n\nrequire (\n\tgithub.com/spf13/cobra v1.7.0\n\tgithub.com/spf13/viper v1.16.0\n)",
		"cmd/main.go": "package main\n\nimport (\n\t\"{{.ModuleName}}/internal/commands\"\n)\n\nfunc main() {\n\tcommands.Execute()\n}",
		"README.md":   "# {{.ProjectName}}\n\n{{.Description}}\n\n## Installation\n\n```bash\ngo install {{.ModuleName}}@latest\n```\n\n## Usage\n\n```bash\n{{.ProjectName}} --help\n```",
		"Makefile":    "build:\n\tgo build -o bin/{{.ProjectName}} cmd/main.go\n\ninstall:\n\tgo install cmd/main.go\n\ntest:\n\tgo test ./...\n\nclean:\n\trm -rf bin/",
	}

	// Library template
	libraryTemplate := domain.NewProjectTemplate(
		"library",
		"Go library project structure",
		domain.ProjectTypeLibrary,
	)
	libraryTemplate.Directories = []string{
		"pkg",
		"examples",
		"docs",
		"internal",
	}
	libraryTemplate.BoilerplateFiles = map[string]string{
		"go.mod":    "module {{.ModuleName}}\n\ngo 1.21\n",
		"README.md": "# {{.ProjectName}}\n\n{{.Description}}\n\n## Installation\n\n```bash\ngo get {{.ModuleName}}\n```\n\n## Usage\n\n```go\nimport \"{{.ModuleName}}\"\n```",
		"LICENSE":   "MIT License\n\nCopyright (c) 2025\n\nPermission is hereby granted, free of charge, to any person obtaining a copy...",
	}

	// API template
	apiTemplate := domain.NewProjectTemplate(
		"api",
		"REST API service with OpenAPI specification",
		domain.ProjectTypeAPI,
	)
	apiTemplate.Directories = []string{
		"cmd/server",
		"internal/domain",
		"internal/application",
		"internal/infrastructure/http",
		"internal/infrastructure/persistence",
		"internal/interfaces/http/handlers",
		"pkg/api",
		"docs/swagger",
		"scripts",
		"configs",
	}
	apiTemplate.BoilerplateFiles = map[string]string{
		"go.mod":             "module {{.ModuleName}}\n\ngo 1.21\n\nrequire (\n\tgithub.com/gin-gonic/gin v1.9.1\n\tgithub.com/swaggo/gin-swagger v1.6.0\n)",
		"cmd/server/main.go": "package main\n\nimport (\n\t\"log\"\n\t\"net/http\"\n\n\t\"github.com/gin-gonic/gin\"\n)\n\nfunc main() {\n\trouter := gin.Default()\n\trouter.GET(\"/health\", func(c *gin.Context) {\n\t\tc.JSON(http.StatusOK, gin.H{\"status\": \"healthy\"})\n\t})\n\tlog.Println(\"API Server starting on :8080\")\n\tlog.Fatal(router.Run(\":8080\"))\n}",
		"README.md":          "# {{.ProjectName}}\n\n{{.Description}}\n\n## Getting Started\n\n```bash\ngo run cmd/server/main.go\n```\n\n## API Documentation\n\nSwagger UI available at: http://localhost:8080/swagger/index.html",
		"Dockerfile":         "FROM golang:1.21-alpine AS builder\nWORKDIR /app\nCOPY . .\nRUN go build -o main cmd/server/main.go\n\nFROM alpine:latest\nRUN apk --no-cache add ca-certificates\nWORKDIR /root/\nCOPY --from=builder /app/main .\nCMD [\"./main\"]",
		"Makefile":           "build:\n\tgo build -o bin/server cmd/server/main.go\n\nrun:\n\tgo run cmd/server/main.go\n\ntest:\n\tgo test ./...\n\nswagger:\n\tswag init -g cmd/server/main.go\n\nclean:\n\trm -rf bin/",
		".gitignore":         "# Binaries\n*.exe\n*.exe~\n*.dll\n*.so\n*.dylib\nbin/\n\n# Test files\n*.test\n*.out\n\n# IDE\n.vscode/\n.idea/\n\n# OS\n.DS_Store\n\n# Logs\n*.log\nlogs/\n\n# Swagger\ndocs/",
	}

	// Worker template
	workerTemplate := domain.NewProjectTemplate(
		"worker",
		"Background worker or job processor",
		domain.ProjectTypeWorker,
	)
	workerTemplate.Directories = []string{
		"cmd/worker",
		"internal/domain",
		"internal/application",
		"internal/infrastructure/queue",
		"internal/infrastructure/persistence",
		"internal/interfaces/jobs",
		"pkg/jobs",
		"docs",
		"scripts",
		"configs",
	}
	workerTemplate.BoilerplateFiles = map[string]string{
		"go.mod":             "module {{.ModuleName}}\n\ngo 1.21\n",
		"cmd/worker/main.go": "package main\n\nimport (\n\t\"log\"\n\t\"os\"\n\t\"os/signal\"\n\t\"syscall\"\n)\n\nfunc main() {\n\tlog.Println(\"Worker starting...\")\n\t\n\t// Graceful shutdown\n\tc := make(chan os.Signal, 1)\n\tsignal.Notify(c, os.Interrupt, syscall.SIGTERM)\n\t<-c\n\t\n\tlog.Println(\"Worker shutting down...\")\n}",
		"README.md":          "# {{.ProjectName}}\n\n{{.Description}}\n\n## Getting Started\n\n```bash\ngo run cmd/worker/main.go\n```",
		"Dockerfile":         "FROM golang:1.21-alpine AS builder\nWORKDIR /app\nCOPY . .\nRUN go build -o main cmd/worker/main.go\n\nFROM alpine:latest\nRUN apk --no-cache add ca-certificates\nWORKDIR /root/\nCOPY --from=builder /app/main .\nCMD [\"./main\"]",
		"Makefile":           "build:\n\tgo build -o bin/worker cmd/worker/main.go\n\nrun:\n\tgo run cmd/worker/main.go\n\ntest:\n\tgo test ./...\n\nclean:\n\trm -rf bin/",
		".gitignore":         "# Binaries\n*.exe\n*.exe~\n*.dll\n*.so\n*.dylib\nbin/\n\n# Test files\n*.test\n*.out\n\n# IDE\n.vscode/\n.idea/\n\n# OS\n.DS_Store\n\n# Logs\n*.log\nlogs/",
	}

	// Add templates with error handling
	if _, err := service.CreateTemplate(microserviceTemplate); err != nil {
		log.Printf("Failed to create microservice template: %v", err)
	}
	if _, err := service.CreateTemplate(cliTemplate); err != nil {
		log.Printf("Failed to create CLI template: %v", err)
	}
	if _, err := service.CreateTemplate(libraryTemplate); err != nil {
		log.Printf("Failed to create library template: %v", err)
	}
	if _, err := service.CreateTemplate(apiTemplate); err != nil {
		log.Printf("Failed to create API template: %v", err)
	}
	if _, err := service.CreateTemplate(workerTemplate); err != nil {
		log.Printf("Failed to create worker template: %v", err)
	}

	log.Println("✅ Default project templates loaded")
}
