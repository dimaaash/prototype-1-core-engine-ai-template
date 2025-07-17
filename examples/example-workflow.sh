#!/bin/bash

# Example usage of the Go Factory Platform
# This script demonstrates a complete code generation workflow

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "🏭 ================================================="
echo "   Go Factory Platform - Example Workflow"
echo "   Complete Code Generation Demonstration"
echo "=================================================${NC}"
echo ""

# Check if services are running
echo -e "${YELLOW}📋 Checking service status...${NC}"
./manage.sh status-all

echo ""
echo -e "${YELLOW}🚀 Starting example workflow...${NC}"
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
echo -e "${BLUE}Step 3: Generating code using visitor pattern${NC}"
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
echo -e "${BLUE}Step 4: Writing generated files to filesystem${NC}"
echo "POST http://localhost:8084/api/v1/files/write"
echo ""

# Extract the generated files from Step 3 and write them to filesystem
GENERATED_FILES=$(echo "$GENERATION_RESPONSE" | jq '.accumulator.files')

WRITE_FILES_PAYLOAD=$(cat <<EOF
{
  "files": $GENERATED_FILES,
  "output_path": "/Users/dmitrykuznetsov/Documents/repos/ever-go/prototype-1-core-engine-ai-template/generated",
  "metadata": {
    "workflow": "example-user-service",
    "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  }
}
EOF
)

WRITE_RESPONSE=$(curl -s -X POST http://localhost:8084/api/v1/files/write \
    -H "Content-Type: application/json" \
    -d "$WRITE_FILES_PAYLOAD")

echo "$WRITE_RESPONSE" | jq '.'

echo ""
echo -e "${BLUE}Step 5: Compiling the generated project${NC}"
echo "POST http://localhost:8084/api/v1/compile"
echo ""

COMPILE_PAYLOAD='{
  "path": "output/example-user-service"
}'

COMPILE_RESPONSE=$(curl -s -X POST http://localhost:8084/api/v1/compile \
    -H "Content-Type: application/json" \
    -d "$COMPILE_PAYLOAD")

echo "$COMPILE_RESPONSE" | jq '.'

echo ""
echo -e "${GREEN}✅ Example workflow completed successfully!${NC}"
echo ""
echo -e "${YELLOW}📁 Generated project location: output/example-user-service${NC}"
echo -e "${YELLOW}🔨 To run the generated project:${NC}"
echo "   cd output/example-user-service"
echo "   go run main.go"
echo ""
echo -e "${YELLOW}🔍 To explore the APIs further:${NC}"
echo "   - Building Blocks API: http://localhost:8081"
echo "   - Template API: http://localhost:8082"
echo "   - Generator API: http://localhost:8083"
echo "   - Compiler API: http://localhost:8084"
echo ""
echo -e "${BLUE}🎉 Happy coding with the Go Factory Platform!${NC}"
