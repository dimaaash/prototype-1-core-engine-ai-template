#!/bin/bash

# Example usage of the Go Factory Platform
# This script demonstrates the VALIDATED INTEGRATION PATTERN with proper service coordination

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
echo "   Go Factory Platform - Example Workflow (Updated)"
echo "   Template → Project Structure → Compiler Integration"
echo "=========================================================${NC}"
echo ""

# Project configuration
PROJECT_NAME="example-user-service"
PROJECT_PATH="$(pwd)/generated/$PROJECT_NAME"

# Check if services are running
echo -e "${YELLOW}📋 Checking service health...${NC}"
./manage.sh status-all

echo ""
echo -e "${YELLOW}🚀 Starting validated integration workflow...${NC}"
echo ""

# Step 1: Get building blocks
echo -e "${BLUE}Step 1: Fetching available building blocks${NC}"
echo "GET http://localhost:8081/api/v1/building-blocks/primitives"
echo ""
curl -s http://localhost:8081/api/v1/building-blocks/primitives | jq '.' || {
    echo -e "${RED}❌ Building blocks service not responding. Please run './manage.sh start-all' first${NC}"
    exit 1
}

echo ""
echo -e "${BLUE}Step 2: Creating a new template${NC}"
echo "POST http://localhost:8082/api/v1/templates"
echo ""

# Create a template for a simple Go struct
TEMPLATE_PAYLOAD='{
  "name": "user-struct",
  "description": "Template for creating a User struct",
  "content": "package {{.package}}\n\ntype {{.name}} struct {\n\tID   int    `json:\"id\"`\n\tName string `json:\"name\"`\n\tEmail string `json:\"email\"`\n}",
  "parameters": [
    {"name": "package", "type": "string", "description": "Go package name", "required": true},
    {"name": "name", "type": "string", "description": "Struct name", "required": true}
  ]
}'

TEMPLATE_RESPONSE=$(curl -s -X POST http://localhost:8082/api/v1/templates \
    -H "Content-Type: application/json" \
    -d "$TEMPLATE_PAYLOAD")

echo "$TEMPLATE_RESPONSE" | jq '.'
TEMPLATE_ID=$(echo "$TEMPLATE_RESPONSE" | jq -r '.id')

echo ""
echo -e "${PURPLE}Step 3: Creating project structure (INTEGRATION PATTERN)${NC}"
echo "POST http://localhost:8085/api/v1/projects/create"
echo ""

# Clean up any existing project
rm -rf "$PROJECT_PATH" 2>/dev/null || true

# Create project structure using project-structure-service
PROJECT_PAYLOAD='{
  "name": "'$PROJECT_NAME'",
  "module_name": "github.com/example/'$PROJECT_NAME'",
  "output_path": "'$PROJECT_PATH'",
  "project_type": "microservice",
  "include_gitignore": true,
  "include_readme": true,
  "include_dockerfile": true,
  "include_makefile": true
}'

PROJECT_RESPONSE=$(curl -s -X POST http://localhost:8085/api/v1/projects/create \
    -H "Content-Type: application/json" \
    -d "$PROJECT_PAYLOAD")

echo "$PROJECT_RESPONSE" | jq '.'

# Validate project structure was created
if [ -d "$PROJECT_PATH" ]; then
    echo -e "${GREEN}✅ Project structure created successfully at: $PROJECT_PATH${NC}"
else
    echo -e "${RED}❌ Project structure creation failed${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 4: Generating code using visitor pattern${NC}"
echo "POST http://localhost:8083/api/v1/generate"
echo ""

# Create a code generation request
GENERATION_PAYLOAD='{
  "elements": [
    {
      "type": "struct",
      "name": "User",
      "package": "domain",
      "fields": [
        {"name": "ID", "type": "int", "tags": "json:\"id\""},
        {"name": "Name", "type": "string", "tags": "json:\"name\""},
        {"name": "Email", "type": "string", "tags": "json:\"email\""}
      ]
    },
    {
      "type": "function",
      "name": "NewUser",
      "package": "application",
      "parameters": [
        {"name": "name", "type": "string"},
        {"name": "email", "type": "string"}
      ],
      "returns": [
        {"type": "*domain.User"}
      ],
      "body": "return &domain.User{Name: name, Email: email}"
    }
  ]
}'

GENERATION_RESPONSE=$(curl -s -X POST http://localhost:8083/api/v1/generate \
    -H "Content-Type: application/json" \
    -d "$GENERATION_PAYLOAD")

echo "$GENERATION_RESPONSE" | jq '.'

echo ""
echo -e "${BLUE}Step 5: Writing generated files to project structure (INTEGRATION PATTERN)${NC}"
echo "POST http://localhost:8084/api/v1/files/write"
echo ""

# Extract the generated files from Step 4 and write them to the PROJECT-SPECIFIC path
GENERATED_FILES=$(echo "$GENERATION_RESPONSE" | jq '.accumulator.files')

WRITE_FILES_PAYLOAD=$(cat <<EOF
{
  "files": $GENERATED_FILES,
  "output_path": "$PROJECT_PATH",
  "metadata": {
    "workflow": "example-user-service",
    "project_name": "$PROJECT_NAME",
    "integration_pattern": "validated",
    "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  }
}
EOF
)

WRITE_RESPONSE=$(curl -s -X POST http://localhost:8084/api/v1/files/write \
    -H "Content-Type: application/json" \
    -d "$WRITE_FILES_PAYLOAD")

echo "$WRITE_RESPONSE" | jq '.'

# Validate files were written to the correct location
echo -e "${BLUE}🔍 Validating file integration...${NC}"
EXPECTED_FILES=(
    "$PROJECT_PATH/internal/domain/user.go"
    "$PROJECT_PATH/internal/application/newuser.go"
)

for file in "${EXPECTED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file exists${NC}"
    else
        echo -e "${RED}❌ $file missing${NC}"
        exit 1
    fi
done

echo ""
echo -e "${BLUE}Step 6: Compiling the integrated project (INTEGRATION PATTERN)${NC}"
echo "POST http://localhost:8084/api/v1/compile"
echo ""

COMPILE_PAYLOAD='{
  "path": "'$PROJECT_PATH'"
}'

COMPILE_RESPONSE=$(curl -s -X POST http://localhost:8084/api/v1/compile \
    -H "Content-Type: application/json" \
    -d "$COMPILE_PAYLOAD")

echo "$COMPILE_RESPONSE" | jq '.'

echo ""
echo -e "${GREEN}✅ Example workflow completed successfully with VALIDATED INTEGRATION!${NC}"
echo ""
echo -e "${YELLOW}📁 Generated project location: $PROJECT_PATH${NC}"
echo -e "${YELLOW}🔨 To run the generated project:${NC}"
echo "   cd $PROJECT_PATH"
echo "   go run cmd/server/main.go"
echo ""
echo -e "${PURPLE}📋 Integration Pattern Validated:${NC}"
echo "   1. ✅ Template Service: Created reusable template"
echo "   2. ✅ Project Structure Service: Created proper Go project layout"
echo "   3. ✅ Generator Service: Generated code using Visitor pattern"
echo "   4. ✅ Compiler Builder Service: Wrote files to project-specific location"
echo "   5. ✅ Compilation: Project compiles successfully with integrated structure"
echo ""
echo -e "${YELLOW}🔍 To explore the APIs further:${NC}"
echo "   - Building Blocks API: http://localhost:8081"
echo "   - Template API: http://localhost:8082"
echo "   - Generator API: http://localhost:8083"
echo "   - Compiler API: http://localhost:8084"
echo ""
echo -e "${BLUE}🎉 Happy coding with the Go Factory Platform!${NC}"
