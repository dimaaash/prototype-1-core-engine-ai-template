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
		"go.mod":             "module {{.ModuleName}}\n\ngo 1.21\n\nrequire (\n\tgithub.com/gin-gonic/gin v1.9.1\n)\n",
		"cmd/server/main.go": "package main\n\nimport (\n\t\"log\"\n\t\"net/http\"\n\n\t\"github.com/gin-gonic/gin\"\n)\n\nfunc main() {\n\trouter := gin.Default()\n\trouter.GET(\"/health\", func(c *gin.Context) {\n\t\tc.JSON(http.StatusOK, gin.H{\"status\": \"healthy\"})\n\t})\n\tlog.Println(\"Server starting on :8080\")\n\tlog.Fatal(router.Run(\":8080\"))\n}",
		"README.md":          "# {{.ProjectName}}\n\n{{.Description}}\n\n## Getting Started\n\n```bash\n# Install dependencies\ngo mod tidy\n\n# Run the server\ngo run cmd/server/main.go\n```\n\n## API Endpoints\n\n- `GET /health` - Health check endpoint",
		"Dockerfile":         "FROM golang:1.21-alpine AS builder\nWORKDIR /app\nCOPY go.mod go.sum ./\nRUN go mod download\nCOPY . .\nRUN go build -o main cmd/server/main.go\n\nFROM alpine:latest\nRUN apk --no-cache add ca-certificates\nWORKDIR /root/\nCOPY --from=builder /app/main .\nEXPOSE 8080\nCMD [\"./main\"]",
		"Makefile":           "build:\n\tgo build -o bin/server cmd/server/main.go\n\nrun:\n\tgo mod tidy\n\tgo run cmd/server/main.go\n\ntest:\n\tgo test ./...\n\ndeps:\n\tgo mod tidy\n\tgo mod download\n\nclean:\n\trm -rf bin/\n\n.PHONY: build run test deps clean",
		".gitignore":         "# Binaries\n*.exe\n*.exe~\n*.dll\n*.so\n*.dylib\nbin/\n\n# Test files\n*.test\n*.out\n\n# IDE\n.vscode/\n.idea/\n\n# OS\n.DS_Store\n\n# Logs\n*.log\nlogs/\n\n# Go modules\ngo.sum",
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
		"go.mod":                    "module {{.ModuleName}}\n\ngo 1.21\n\nrequire (\n\tgithub.com/spf13/cobra v1.8.0\n\tgithub.com/spf13/viper v1.18.2\n)\n",
		"cmd/main.go":               "package main\n\nimport (\n\t\"{{.ModuleName}}/internal/commands\"\n)\n\nfunc main() {\n\tcommands.Execute()\n}",
		"internal/commands/root.go": "package commands\n\nimport (\n\t\"fmt\"\n\t\"os\"\n\n\t\"github.com/spf13/cobra\"\n\t\"github.com/spf13/viper\"\n)\n\nvar rootCmd = &cobra.Command{\n\tUse:   \"{{.ProjectName}}\",\n\tShort: \"{{.Description}}\",\n\tLong:  \"{{.Description}}\",\n}\n\nfunc Execute() {\n\tif err := rootCmd.Execute(); err != nil {\n\t\tfmt.Fprintf(os.Stderr, \"Error: %v\\n\", err)\n\t\tos.Exit(1)\n\t}\n}\n\nfunc init() {\n\tviper.AutomaticEnv()\n}",
		"README.md":                 "# {{.ProjectName}}\n\n{{.Description}}\n\n## Installation\n\n```bash\n# Install dependencies\ngo mod tidy\n\n# Build the CLI\ngo build -o bin/{{.ProjectName}} cmd/main.go\n\n# Or install globally\ngo install\n```\n\n## Usage\n\n```bash\n# Run from source\ngo run cmd/main.go --help\n\n# Or run the built binary\n./bin/{{.ProjectName}} --help\n```",
		"Makefile":                  "build:\n\tgo build -o bin/{{.ProjectName}} cmd/main.go\n\ninstall:\n\tgo install\n\nrun:\n\tgo mod tidy\n\tgo run cmd/main.go\n\ntest:\n\tgo test ./...\n\ndeps:\n\tgo mod tidy\n\tgo mod download\n\nclean:\n\trm -rf bin/\n\n.PHONY: build install run test deps clean",
		".gitignore":                "# Binaries\n*.exe\n*.exe~\n*.dll\n*.so\n*.dylib\nbin/\n\n# Test files\n*.test\n*.out\n\n# IDE\n.vscode/\n.idea/\n\n# OS\n.DS_Store\n\n# Logs\n*.log\nlogs/\n\n# Go modules\ngo.sum",
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
		"go.mod":      "module {{.ModuleName}}\n\ngo 1.21\n\nrequire (\n\tgithub.com/stretchr/testify v1.8.4\n)\n",
		"lib.go":      "// Package {{.PackageName}} provides {{.Description}}\npackage {{.PackageName}}\n\nimport (\n\t\"fmt\"\n)\n\n// Version returns the current version of the library\nfunc Version() string {\n\treturn \"1.0.0\"\n}\n\n// Hello returns a greeting message\nfunc Hello(name string) string {\n\tif name == \"\" {\n\t\tname = \"World\"\n\t}\n\treturn fmt.Sprintf(\"Hello, %s!\", name)\n}\n\n// Config represents library configuration\ntype Config struct {\n\tDebug   bool   `json:\"debug\"`\n\tTimeout int    `json:\"timeout\"`\n\tBaseURL string `json:\"base_url\"`\n}\n\n// NewConfig creates a new configuration with defaults\nfunc NewConfig() *Config {\n\treturn &Config{\n\t\tDebug:   false,\n\t\tTimeout: 30,\n\t\tBaseURL: \"https://api.example.com\",\n\t}\n}\n\n// Client represents the library client\ntype Client struct {\n\tconfig *Config\n}\n\n// NewClient creates a new client with the given configuration\nfunc NewClient(config *Config) *Client {\n\tif config == nil {\n\t\tconfig = NewConfig()\n\t}\n\treturn &Client{\n\t\tconfig: config,\n\t}\n}\n\n// GetConfig returns the client configuration\nfunc (c *Client) GetConfig() *Config {\n\treturn c.config\n}",
		"lib_test.go": "package {{.PackageName}}\n\nimport (\n\t\"testing\"\n\n\t\"github.com/stretchr/testify/assert\"\n\t\"github.com/stretchr/testify/require\"\n)\n\nfunc TestVersion(t *testing.T) {\n\tversion := Version()\n\tassert.Equal(t, \"1.0.0\", version)\n}\n\nfunc TestHello(t *testing.T) {\n\ttests := []struct {\n\t\tname     string\n\t\tinput    string\n\t\texpected string\n\t}{\n\t\t{\"with name\", \"Alice\", \"Hello, Alice!\"},\n\t\t{\"empty name\", \"\", \"Hello, World!\"},\n\t}\n\n\tfor _, tt := range tests {\n\t\tt.Run(tt.name, func(t *testing.T) {\n\t\t\tresult := Hello(tt.input)\n\t\t\tassert.Equal(t, tt.expected, result)\n\t\t})\n\t}\n}\n\nfunc TestNewConfig(t *testing.T) {\n\tconfig := NewConfig()\n\trequire.NotNil(t, config)\n\tassert.False(t, config.Debug)\n\tassert.Equal(t, 30, config.Timeout)\n\tassert.Equal(t, \"https://api.example.com\", config.BaseURL)\n}\n\nfunc TestNewClient(t *testing.T) {\n\tt.Run(\"with config\", func(t *testing.T) {\n\t\tconfig := &Config{Debug: true, Timeout: 60}\n\t\tclient := NewClient(config)\n\t\trequire.NotNil(t, client)\n\t\tassert.Equal(t, config, client.GetConfig())\n\t})\n\n\tt.Run(\"with nil config\", func(t *testing.T) {\n\t\tclient := NewClient(nil)\n\t\trequire.NotNil(t, client)\n\t\tassert.NotNil(t, client.GetConfig())\n\t\tassert.False(t, client.GetConfig().Debug)\n\t})\n}",
		"README.md":   "# {{.ProjectName}}\n\n{{.Description}}\n\n## Installation\n\n```bash\ngo get {{.ModuleName}}\n```\n\n## Usage\n\n```go\npackage main\n\nimport (\n\t\"fmt\"\n\t\"{{.ModuleName}}\"\n)\n\nfunc main() {\n\t// Basic usage\n\tfmt.Println({{.PackageName}}.Hello(\"World\"))\n\t\n\t// With configuration\n\tconfig := {{.PackageName}}.NewConfig()\n\tconfig.Debug = true\n\t\n\tclient := {{.PackageName}}.NewClient(config)\n\tfmt.Printf(\"Version: %s\\n\", {{.PackageName}}.Version())\n}\n```\n\n## Development\n\n```bash\n# Run tests\ngo test ./...\n\n# Run tests with coverage\ngo test -cover ./...\n\n# Build\ngo build\n```\n\n## API Reference\n\n### Functions\n\n- `Version() string` - Returns the library version\n- `Hello(name string) string` - Returns a greeting message\n- `NewConfig() *Config` - Creates default configuration\n- `NewClient(config *Config) *Client` - Creates a new client\n\n### Types\n\n- `Config` - Library configuration\n- `Client` - Main library client",
		"Makefile":    "test:\n\tgo test ./...\n\ntest-cover:\n\tgo test -cover ./...\n\ntest-verbose:\n\tgo test -v ./...\n\nbuild:\n\tgo build\n\nlint:\n\tgolangci-lint run\n\nmod-tidy:\n\tgo mod tidy\n\nexample:\n\tgo run examples/main.go\n\nclean:\n\tgo clean\n\tgo mod tidy\n\ncheck: mod-tidy lint test\n\n.PHONY: test test-cover test-verbose build lint mod-tidy example clean check",
		".gitignore":  "# Binaries\n*.exe\n*.exe~\n*.dll\n*.so\n*.dylib\n\n# Test files\n*.test\n*.out\n\n# Coverage files\n*.cover\ncoverage.html\ncoverage.out\n\n# IDE\n.vscode/\n.idea/\n*.swp\n*.swo\n\n# OS\n.DS_Store\nThumbs.db\n\n# Logs\n*.log\nlogs/\n\n# Temporary files\n*.tmp\n*.temp",
		"LICENSE":     "MIT License\n\nCopyright (c) 2024 {{.ProjectName}}\n\nPermission is hereby granted, free of charge, to any person obtaining a copy\nof this software and associated documentation files (the \"Software\"), to deal\nin the Software without restriction, including without limitation the rights\nto use, copy, modify, merge, publish, distribute, sublicense, and/or sell\ncopies of the Software, and to permit persons to whom the Software is\nfurnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all\ncopies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\nIMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\nFITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\nAUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\nLIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\nOUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\nSOFTWARE.",
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
		"go.mod":             "module {{.ModuleName}}\n\ngo 1.21\n\nrequire (\n\tgithub.com/gin-gonic/gin v1.9.1\n\tgithub.com/swaggo/gin-swagger v1.6.0\n\tgithub.com/swaggo/files v1.0.1\n\tgithub.com/swaggo/swag v1.16.2\n)\n",
		"cmd/server/main.go": "package main\n\nimport (\n\t\"log\"\n\t\"net/http\"\n\n\t\"github.com/gin-gonic/gin\"\n\tginSwagger \"github.com/swaggo/gin-swagger\"\n\t\"github.com/swaggo/gin-swagger/swaggerFiles\"\n)\n\n// @title {{.ProjectName}} API\n// @version 1.0\n// @description {{.Description}}\n// @host localhost:8080\n// @BasePath /api/v1\nfunc main() {\n\trouter := gin.Default()\n\t\n\t// Health check endpoint\n\trouter.GET(\"/health\", healthCheck)\n\t\n\t// API routes\n\tv1 := router.Group(\"/api/v1\")\n\t{\n\t\tv1.GET(\"/ping\", ping)\n\t}\n\t\n\t// Swagger documentation\n\trouter.GET(\"/swagger/*any\", ginSwagger.WrapHandler(swaggerFiles.Handler))\n\t\n\tlog.Println(\"API Server starting on :8080\")\n\tlog.Fatal(router.Run(\":8080\"))\n}\n\n// @Summary Health check\n// @Description Health check endpoint\n// @Tags health\n// @Accept json\n// @Produce json\n// @Success 200 {object} map[string]string\n// @Router /health [get]\nfunc healthCheck(c *gin.Context) {\n\tc.JSON(http.StatusOK, gin.H{\"status\": \"healthy\"})\n}\n\n// @Summary Ping\n// @Description Ping endpoint\n// @Tags ping\n// @Accept json\n// @Produce json\n// @Success 200 {object} map[string]string\n// @Router /api/v1/ping [get]\nfunc ping(c *gin.Context) {\n\tc.JSON(http.StatusOK, gin.H{\"message\": \"pong\"})\n}",
		"README.md":          "# {{.ProjectName}}\n\n{{.Description}}\n\n## Getting Started\n\n```bash\n# Install dependencies\ngo mod tidy\n\n# Generate Swagger documentation\nswag init -g cmd/server/main.go\n\n# Run the API server\ngo run cmd/server/main.go\n```\n\n## API Documentation\n\nSwagger UI available at: http://localhost:8080/swagger/index.html\n\n## API Endpoints\n\n- `GET /health` - Health check endpoint\n- `GET /api/v1/ping` - Ping endpoint\n- `GET /swagger/*` - Swagger documentation",
		"Dockerfile":         "FROM golang:1.21-alpine AS builder\nWORKDIR /app\nCOPY go.mod go.sum ./\nRUN go mod download\nCOPY . .\nRUN go install github.com/swaggo/swag/cmd/swag@latest\nRUN swag init -g cmd/server/main.go\nRUN go build -o main cmd/server/main.go\n\nFROM alpine:latest\nRUN apk --no-cache add ca-certificates\nWORKDIR /root/\nCOPY --from=builder /app/main .\nCOPY --from=builder /app/docs ./docs\nEXPOSE 8080\nCMD [\"./main\"]",
		"Makefile":           "build:\n\tswag init -g cmd/server/main.go\n\tgo build -o bin/server cmd/server/main.go\n\nrun:\n\tgo mod tidy\n\tswag init -g cmd/server/main.go\n\tgo run cmd/server/main.go\n\ntest:\n\tgo test ./...\n\nswagger:\n\tswag init -g cmd/server/main.go\n\ndeps:\n\tgo mod tidy\n\tgo install github.com/swaggo/swag/cmd/swag@latest\n\nclean:\n\trm -rf bin/ docs/\n\n.PHONY: build run test swagger deps clean",
		".gitignore":         "# Binaries\n*.exe\n*.exe~\n*.dll\n*.so\n*.dylib\nbin/\n\n# Test files\n*.test\n*.out\n\n# IDE\n.vscode/\n.idea/\n\n# OS\n.DS_Store\n\n# Logs\n*.log\nlogs/\n\n# Swagger generated docs\ndocs/docs.go\ndocs/swagger.json\ndocs/swagger.yaml\n\n# Go modules\ngo.sum",
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
