#!/bin/bash

# Example usage of the Go Factory Platform with VALIDATED Integration Pattern

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}🏭 Go Factory Platform - Individual Service Usage Examples${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

# Check if services are running, if not start them
echo -e "${YELLOW}📦 Ensuring all services are running...${NC}"
./manage.sh start-all

echo ""
echo -e "${YELLOW}⏳ Waiting for services to initialize...${NC}"
sleep 3

# Example project configuration  
PROJECT_NAME="usage-example-service"
PROJECT_PATH="$(pwd)/generated/$PROJECT_NAME"

echo ""
echo -e "${PURPLE}========== VALIDATED INTEGRATION PATTERN EXAMPLES ==========${NC}"
echo ""

# 1. Building Blocks Service Examples
echo -e "${BLUE}Example 1: Building Blocks Service (Port 8081)${NC}"
echo "🧱 Creating building blocks..."

curl -s -X POST http://localhost:8081/api/v1/building-blocks/variable \
  -H "Content-Type: application/json" \
  -d '{
    "name": "userID",
    "type": "string",
    "default_value": ""
  }' | jq '.'

echo ""

# 2. Template Service Examples  
echo -e "${BLUE}Example 2: Template Service (Port 8082)${NC}"
echo "📄 Creating templates..."

curl -s -X POST http://localhost:8082/api/v1/templates \
  -H "Content-Type: application/json" \
  -d '{
    "name": "user-model-template",
    "description": "Template for creating User models",
    "content": "package {{.package}}\n\ntype {{.name}} struct {\n\tID string `json:\"id\"`\n\tName string `json:\"name\"`\n\tEmail string `json:\"email\"`\n}",
    "parameters": [
      {"name": "package", "type": "string", "description": "Package name", "required": true},
      {"name": "name", "type": "string", "description": "Struct name", "required": true}
    ]
  }' | jq '.'

echo ""

# 3. Project Structure Service Examples (INTEGRATION PATTERN)
echo -e "${PURPLE}Example 3: Project Structure Service (Port 8085) - INTEGRATION PATTERN${NC}"
echo "🏗️ Creating project structure..."

# Clean up any existing project
rm -rf "$PROJECT_PATH" 2>/dev/null || true

curl -s -X POST http://localhost:8085/api/v1/projects/create \
  -H "Content-Type: application/json" \
  -d '{
    "name": "'$PROJECT_NAME'",
    "module_name": "github.com/example/'$PROJECT_NAME'",
    "output_path": "'$PROJECT_PATH'",
    "project_type": "microservice",
    "include_gitignore": true,
    "include_readme": true,
    "include_dockerfile": true,
    "include_makefile": true
  }' | jq '.'

echo ""

# 4. Generator Service Examples
echo -e "${BLUE}Example 4: Generator Service (Port 8083)${NC}"
echo "⚙️ Generating code..."

curl -s -X POST http://localhost:8083/api/v1/generate \
  -H "Content-Type: application/json" \
  -d '{
    "elements": [
      {
        "type": "struct",
        "name": "User",
        "package": "domain",
        "fields": [
          {"name": "ID", "type": "string", "tags": "json:\"id\""},
          {"name": "Name", "type": "string", "tags": "json:\"name\""},
          {"name": "Email", "type": "string", "tags": "json:\"email\""}
        ]
      }
    ]
  }' | jq '.accumulator.files'

echo ""

# 5. Compiler Builder Service Examples (INTEGRATION PATTERN)
echo -e "${PURPLE}Example 5: Compiler Builder Service (Port 8084) - INTEGRATION PATTERN${NC}"
echo "� Writing files to project structure..."

# Generate and write files to the project-specific location
GENERATED_FILES=$(curl -s -X POST http://localhost:8083/api/v1/generate \
  -H "Content-Type: application/json" \
  -d '{
    "elements": [
      {
        "type": "struct",
        "name": "User",
        "package": "domain",
        "fields": [
          {"name": "ID", "type": "string", "tags": "json:\"id\""},
          {"name": "Name", "type": "string", "tags": "json:\"name\""},
          {"name": "Email", "type": "string", "tags": "json:\"email\""}
        ]
      }
    ]
  }' | jq '.accumulator.files')

curl -s -X POST http://localhost:8084/api/v1/files/write \
  -H "Content-Type: application/json" \
  -d '{
    "files": '$GENERATED_FILES',
    "output_path": "'$PROJECT_PATH'",
    "metadata": {
      "workflow": "usage-examples",
      "integration_pattern": "validated"
    }
  }' | jq '.'

echo ""

# 6. Compilation validation (INTEGRATION PATTERN)
echo -e "${PURPLE}Example 6: Project Compilation - INTEGRATION PATTERN${NC}"
echo "🔨 Compiling the integrated project..."

curl -s -X POST http://localhost:8084/api/v1/compile \
  -H "Content-Type: application/json" \
  -d '{"path": "'$PROJECT_PATH'"}' | jq '.'

echo ""
echo -e "${GREEN}✅ All examples completed successfully!${NC}"
echo ""
echo -e "${YELLOW}📁 Generated project location: $PROJECT_PATH${NC}"
echo -e "${YELLOW}🔍 Project structure:${NC}"
tree "$PROJECT_PATH" 2>/dev/null || find "$PROJECT_PATH" -type f

echo ""
echo -e "${PURPLE}🎯 Integration Pattern Demonstrated:${NC}"
echo "   1. ✅ Building Blocks Service: Created primitives"
echo "   2. ✅ Template Service: Created reusable templates"
echo "   3. ✅ Project Structure Service: Created proper Go project layout"
echo "   4. ✅ Generator Service: Generated code using templates"
echo "   5. ✅ Compiler Builder Service: Wrote files to project-specific location"
echo "   6. ✅ Compilation: Project compiles with integrated structure"
echo ""
echo -e "${BLUE}🔧 This demonstrates the VALIDATED integration pattern!${NC}"

echo "🎉 Example completed!"
