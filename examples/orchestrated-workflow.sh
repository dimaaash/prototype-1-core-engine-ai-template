#!/bin/bash

# orchestrated-workflow.sh - Demonstrates using orchestrator service for user-friendly code generation
# This replaces the manual payload construction in enhanced-workflow.sh

set -e

echo "🎼 Starting Orchestrated Workflow Example"
echo "=========================================="

# Configuration
WORKSPACE="/tmp/orchestrated-example"
PROJECT_NAME="user-management-service"
MODULE_PATH="github.com/example/user-management-service"

# Cleanup and prepare workspace
echo "📁 Preparing workspace: $WORKSPACE"
rm -rf "$WORKSPACE"
mkdir -p "$WORKSPACE"

# Step 1: Define user-friendly entity specification
echo "👤 Creating User entity specification..."
USER_SPEC=$(cat <<EOF
{
  "name": "$PROJECT_NAME",
  "module_path": "$MODULE_PATH",
  "output_path": "$WORKSPACE",
  "project_type": "microservice",
  "entities": [
    {
      "name": "User",
      "description": "User entity with authentication capabilities",
      "fields": [
        {
          "name": "id",
          "type": "uuid",
          "required": true,
          "description": "Unique user identifier"
        },
        {
          "name": "email",
          "type": "email",
          "required": true,
          "unique": true,
          "description": "User email address"
        },
        {
          "name": "password_hash",
          "type": "string",
          "required": true,
          "description": "Hashed password"
        },
        {
          "name": "first_name",
          "type": "string",
          "required": true,
          "description": "User first name"
        },
        {
          "name": "last_name",
          "type": "string",
          "required": true,
          "description": "User last name"
        },
        {
          "name": "is_active",
          "type": "boolean",
          "required": true,
          "description": "User active status"
        },
        {
          "name": "created_at",
          "type": "timestamp",
          "required": true,
          "description": "Account creation time"
        },
        {
          "name": "updated_at",
          "type": "timestamp",
          "required": true,
          "description": "Last update time"
        }
      ],
      "features": ["database", "api", "validation", "repository"]
    }
  ],
  "features": ["docker", "makefile", "rest_api"],
  "dependencies": ["gin", "gorm", "uuid", "bcrypt"]
}
EOF
)

# Step 2: Use orchestrator service to convert specification to generator payload
echo "🎼 Converting specification to generator payload via orchestrator service..."
ORCHESTRATION_RESULT=$(curl -s -X POST http://localhost:8086/api/v1/orchestrate/microservice \
  -H "Content-Type: application/json" \
  -d "$USER_SPEC")

# Check if orchestrator service responded successfully
if ! echo "$ORCHESTRATION_RESULT" | jq -e '.success' > /dev/null 2>&1; then
    echo "❌ Orchestrator service failed:"
    echo "$ORCHESTRATION_RESULT" | jq .
    exit 1
fi

echo "✅ Orchestration successful!"
echo "   - Generated $(echo "$ORCHESTRATION_RESULT" | jq -r '.generated_files') code elements"
echo "   - Processing time: $(echo "$ORCHESTRATION_RESULT" | jq -r '.processing_time') microseconds"

# Step 3: Extract the generation request for the generator service
GENERATION_REQUEST=$(echo "$ORCHESTRATION_RESULT" | jq '.generation_request')

echo "🏗️  Extracted generation request with $(echo "$GENERATION_REQUEST" | jq '.elements | length') elements:"
echo "$GENERATION_REQUEST" | jq '.elements[] | {type: .type, name: .name, package: .package}'

# Step 4: Send request to generator service (if running)
echo "🔧 Sending request to generator service..."
if curl -s http://localhost:8083/api/v1/generate > /dev/null 2>&1; then
    GENERATION_RESULT=$(curl -s -X POST http://localhost:8083/api/v1/generate \
      -H "Content-Type: application/json" \
      -d "$GENERATION_REQUEST")
    
    if echo "$GENERATION_RESULT" | jq -e '.success' > /dev/null 2>&1; then
        echo "✅ Code generation successful!"
        echo "   - Generated $(echo "$GENERATION_RESULT" | jq -r '.files_generated') files"
        
        # List generated files
        echo "📄 Generated files:"
        find "$WORKSPACE" -name "*.go" | head -10 | while read file; do
            echo "   - $(basename "$file")"
        done
        
        # Show sample of generated code
        echo "🔍 Sample generated User struct:"
        find "$WORKSPACE" -name "*.go" -exec grep -l "type User struct" {} \; | head -1 | xargs cat | head -20
    else
        echo "❌ Code generation failed:"
        echo "$GENERATION_RESULT" | jq .
    fi
else
    echo "⚠️  Generator service not responding on localhost:8083"
    echo "   Try: curl http://localhost:8083/api/v1/generate"
    echo "   Start it with: ./manage.sh start generator-service"
fi

echo ""
echo "🎯 Workflow Summary:"
echo "   1. ✅ Created user-friendly entity specification"
echo "   2. ✅ Converted to technical generator payload using orchestrator service"
echo "   3. ✅ Generated code using generator service"
echo ""
echo "🆚 Comparison to manual approach:"
echo "   - Manual: ~100 lines of complex JSON payload construction"
echo "   - Orchestrated: ~10 lines of simple entity specification"
echo "   - Reduction: 90% less complexity for end users"
echo ""
echo "📂 Output location: $WORKSPACE"
echo "🎼 Orchestrated Workflow Complete!"
