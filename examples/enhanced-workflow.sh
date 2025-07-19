#!/bin/bash

# Enhanced Workflow with VALIDATED Integration Pattern
# This script demonstrates the complete code generation workflow 
# using the VALIDATED Template → Project Structure → Compiler integration

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "🏭 =========================================================="
echo "   Enhanced Go Factory Platform Workflow (VALIDATED)"
echo "   Template → Project Structure → Compiler Integration"
echo "=========================================================${NC}"
echo ""

# Check if services are running
echo -e "${YELLOW}📋 Checking service status...${NC}"
./manage.sh status-all

echo ""
echo -e "${YELLOW}🚀 Starting enhanced workflow...${NC}"
echo ""

# Step 1: Create Project Structure
echo -e "${BLUE}Step 1: Creating project structure with Project Structure Service${NC}"
echo "POST http://localhost:8085/api/v1/projects/create"
echo ""

PROJECT_CREATE_PAYLOAD='{
  "name": "user-microservice",
  "module_name": "github.com/example/user-microservice",
  "output_path": "/Users/dmitrykuznetsov/Documents/repos/ever-go/prototype-1-core-engine-ai-template/generated/user-microservice",
  "project_type": "microservice",
  "include_gitignore": true,
  "include_readme": true,
  "include_dockerfile": true,
  "include_makefile": true,
  "variables": {
    "Description": "A user management microservice with clean architecture"
  }
}'

PROJECT_RESPONSE=$(curl -s -X POST http://localhost:8085/api/v1/projects/create \
    -H "Content-Type: application/json" \
    -d "$PROJECT_CREATE_PAYLOAD")

echo "$PROJECT_RESPONSE" | jq '.'

# Extract project path for next steps
PROJECT_PATH=$(echo "$PROJECT_RESPONSE" | jq -r '.path')

echo ""
echo -e "${BLUE}Step 2: Generating domain code with Generator Service${NC}"
echo "POST http://localhost:8083/api/v1/generate"
echo ""

# Generate User domain model and application service
GENERATION_PAYLOAD='{
  "output_path": "'$PROJECT_PATH'",
  "module_path": "github.com/example/user-microservice",
  "elements": [
    {
      "type": "struct",
      "name": "User",
      "package": "domain",
      "fields": [
        {"name": "ID", "type": "string", "tags": "json:\"id\" db:\"id\""},
        {"name": "Email", "type": "string", "tags": "json:\"email\" db:\"email\""},
        {"name": "Name", "type": "string", "tags": "json:\"name\" db:\"name\""},
        {"name": "CreatedAt", "type": "time.Time", "tags": "json:\"created_at\" db:\"created_at\""},
        {"name": "UpdatedAt", "type": "time.Time", "tags": "json:\"updated_at\" db:\"updated_at\""}
      ]
    },
    {
      "type": "function",
      "name": "NewUser",
      "package": "domain",
      "parameters": [
        {"name": "email", "type": "string"},
        {"name": "name", "type": "string"}
      ],
      "returns": [
        {"type": "*User"}
      ],
      "body": "return &User{\n\t\tID: uuid.New().String(),\n\t\tEmail: email,\n\t\tName: name,\n\t\tCreatedAt: time.Now(),\n\t\tUpdatedAt: time.Now(),\n\t}"
    },
    {
      "type": "function",
      "name": "CreateUser",
      "package": "application",
      "parameters": [
        {"name": "email", "type": "string"},
        {"name": "name", "type": "string"}
      ],
      "returns": [
        {"type": "*domain.User"},
        {"type": "error"}
      ],
      "body": "user := domain.NewUser(email, name)\n\t// TODO: Add validation logic\n\t// TODO: Save to repository\n\treturn user, nil"
    }
  ]
}'

GENERATION_RESPONSE=$(curl -s -X POST http://localhost:8083/api/v1/generate \
    -H "Content-Type: application/json" \
    -d "$GENERATION_PAYLOAD")

echo "$GENERATION_RESPONSE" | jq '.'

echo ""
echo -e "${BLUE}Step 3: Verifying generated code was written to project structure${NC}"
echo "Checking contents of: $PROJECT_PATH"
echo ""

# Show the generated files in the project structure
echo -e "${YELLOW}Generated files:${NC}"
if [ -d "$PROJECT_PATH/internal" ]; then
    find "$PROJECT_PATH/internal" -name "*.go" -type f | head -10
else
    echo "⚠️  No internal directory found in project structure"
fi

echo ""
echo -e "${BLUE}Step 4: Validating project structure${NC}"
echo "POST http://localhost:8085/api/v1/projects/validate"
echo ""

VALIDATE_PAYLOAD="{\"path\": \"$PROJECT_PATH\"}"

VALIDATE_RESPONSE=$(curl -s -X POST http://localhost:8085/api/v1/projects/validate \
    -H "Content-Type: application/json" \
    -d "$VALIDATE_PAYLOAD")

echo "$VALIDATE_RESPONSE" | jq '.'

echo ""
echo -e "${BLUE}Step 5: Compiling the complete project${NC}"
echo "POST http://localhost:8084/api/v1/compile"
echo ""

COMPILE_PAYLOAD="{\"path\": \"$PROJECT_PATH\"}"

COMPILE_RESPONSE=$(curl -s -X POST http://localhost:8084/api/v1/compile \
    -H "Content-Type: application/json" \
    -d "$COMPILE_PAYLOAD")

echo "$COMPILE_RESPONSE" | jq '.'

echo ""
echo -e "${GREEN}✅ Enhanced workflow completed successfully!${NC}"
echo ""
echo -e "${YELLOW}📁 Generated project location: $PROJECT_PATH${NC}"
echo -e "${YELLOW}🏗️ Project structure:${NC}"
if command -v tree >/dev/null 2>&1; then
    tree "$PROJECT_PATH"
else
    find "$PROJECT_PATH" -type f -name "*.go" | head -10
fi

echo ""
echo -e "${YELLOW}🔨 To test the generated microservice:${NC}"
echo "   cd $PROJECT_PATH"
echo "   go mod tidy"
echo "   go run cmd/server/main.go"
echo ""
echo -e "${YELLOW}📊 Enhanced workflow demonstrates:${NC}"
echo "   ✅ Project Structure Service - Creates standard Go project layout"
echo "   ✅ Generator Service - Generates domain models and application logic"
echo "   ✅ Compiler Builder Service - Writes files and validates compilation"
echo "   ✅ Template Service - Provides building blocks for code generation"
echo "   ✅ Complete separation of concerns across 5 microservices"
echo ""
echo -e "${BLUE}🎉 The platform now supports end-to-end project creation!${NC}"
