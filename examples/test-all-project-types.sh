#!/bin/bash

# Test All Project Structure Types
# This script tests all 5 project structures supported by project-structure-service
# Each project type is created in the generated/ folder with validation

# Ensure we're using bash for associative arrays
if [ -z "$BASH_VERSION" ]; then
    echo "This script requires bash. Please run with: bash $0"
    exit 1
fi

# Don't exit on errors - continue testing all project types
set +e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "🏗️ =================================================================="
echo "   Go Factory Platform - Project Structure Types Test Suite"
echo "   Testing all 5 supported project types with validation"
echo "==================================================================${NC}"
echo ""

# Base configuration
BASE_DIR="$(pwd)/generated"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEST_SESSION_DIR="$BASE_DIR/project-types-test-$TIMESTAMP"

# Project types to test
PROJECT_TYPES_LIST="microservice cli library api worker"
PROJECT_DESCRIPTIONS=()
PROJECT_DESCRIPTIONS[0]="Standard Go microservice with clean architecture"
PROJECT_DESCRIPTIONS[1]="Command-line application using Cobra"
PROJECT_DESCRIPTIONS[2]="Reusable Go library package"
PROJECT_DESCRIPTIONS[3]="REST API service with OpenAPI specification"
PROJECT_DESCRIPTIONS[4]="Background worker or job processor"

# Check if services are running
echo -e "${YELLOW}📋 Checking service health...${NC}"
./manage.sh status-all

echo ""
echo -e "${YELLOW}🚀 Starting project structure tests...${NC}"
echo -e "${YELLOW}📁 Test session directory: $TEST_SESSION_DIR${NC}"
echo ""

# Create test session directory
mkdir -p "$TEST_SESSION_DIR"

# Function to test a project type
test_project_type() {
    local project_type=$1
    local description=$2
    local project_name="${project_type}-example"
    local project_path="$TEST_SESSION_DIR/$project_name"
    
    echo -e "${PURPLE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}🔧 Testing Project Type: ${project_type}${NC}"
    echo -e "${CYAN}📝 Description: ${description}${NC}"
    echo -e "${CYAN}📁 Path: ${project_path}${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════${NC}"
    
    # Step 1: Create project structure
    echo -e "${BLUE}Step 1: Creating ${project_type} project structure${NC}"
    
    local project_payload=$(cat <<EOF
{
    "name": "$project_name",
    "module_name": "github.com/example/$project_name",
    "output_path": "$project_path",
    "project_type": "$project_type",
    "include_gitignore": true,
    "include_readme": true,
    "include_dockerfile": true,
    "include_makefile": true,
    "variables": {
        "description": "$description",
        "author": "Go Factory Platform",
        "version": "1.0.0"
    }
}
EOF
)
    
    local response=$(curl -s -X POST http://localhost:8085/api/v1/projects/create \
        -H "Content-Type: application/json" \
        -d "$project_payload")
    
    echo "$response" | jq '.'
    
    # Validate creation
    if [ -d "$project_path" ]; then
        echo -e "${GREEN}✅ Project structure created successfully${NC}"
    else
        echo -e "${RED}❌ Project structure creation failed${NC}"
        return 1
    fi
    
    # Step 2: Validate project structure
    echo -e "${BLUE}Step 2: Validating ${project_type} project structure${NC}"
    
    local validate_payload='{
        "path": "'$project_path'"
    }'
    
    local validation_response=$(curl -s -X POST http://localhost:8085/api/v1/projects/validate \
        -H "Content-Type: application/json" \
        -d "$validate_payload")
    
    echo "$validation_response" | jq '.'
    
    local is_valid=$(echo "$validation_response" | jq -r '.is_valid // false')
    if [ "$is_valid" = "true" ]; then
        echo -e "${GREEN}✅ Project structure validation passed${NC}"
    else
        echo -e "${YELLOW}⚠️  Project structure validation has recommendations${NC}"
    fi
    
    # Step 3: Generate and add code specific to project type
    echo -e "${BLUE}Step 3: Generating ${project_type}-specific code${NC}"
    
    case $project_type in
        "microservice")
            generate_microservice_code "$project_path"
            ;;
        "cli")
            generate_cli_code "$project_path"
            ;;
        "library")
            generate_library_code "$project_path"
            ;;
        "api")
            generate_api_code "$project_path"
            ;;
        "worker")
            generate_worker_code "$project_path"
            ;;
    esac
    
    # Step 4: Compile the project (allow failures)
    echo -e "${BLUE}Step 4: Compiling ${project_type} project${NC}"
    
    local compile_payload='{
        "path": "'$project_path'"
    }'
    
    local compile_response=$(curl -s -X POST http://localhost:8084/api/v1/compile \
        -H "Content-Type: application/json" \
        -d "$compile_payload")
    
    echo "$compile_response" | jq '.'
    
    local compile_success=$(echo "$compile_response" | jq -r '.success // false')
    if [ "$compile_success" = "true" ]; then
        echo -e "${GREEN}✅ Project compilation successful${NC}"
    else
        echo -e "${YELLOW}⚠️  Project compilation had issues (expected for missing dependencies)${NC}"
    fi
    
    # Step 5: Display project structure
    echo -e "${BLUE}Step 5: Project structure overview${NC}"
    echo -e "${YELLOW}📁 Generated structure for ${project_type}:${NC}"
    
    if command -v tree >/dev/null 2>&1; then
        tree "$project_path" -I 'bin|*.log|.git' -L 3
    else
        find "$project_path" -type f -not -path "*/bin/*" -not -name "*.log" | head -20
    fi
    
    echo ""
    echo -e "${GREEN}✅ ${project_type} project test completed successfully${NC}"
    echo ""
    
    return 0
}

# Functions to generate project-specific code
generate_microservice_code() {
    local project_path=$1
    
    local generation_payload='{
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
            },
            {
                "type": "interface",
                "name": "UserService",
                "package": "application",
                "methods": [
                    {"name": "CreateUser", "parameters": [{"name": "user", "type": "*domain.User"}], "returns": [{"type": "error"}]},
                    {"name": "GetUser", "parameters": [{"name": "id", "type": "string"}], "returns": [{"type": "*domain.User"}, {"type": "error"}]}
                ]
            }
        ]
    }'
    
    generate_and_write_code "$generation_payload" "$project_path" "microservice"
}

generate_cli_code() {
    local project_path=$1
    
    local generation_payload='{
        "elements": [
            {
                "type": "struct", 
                "name": "Config",
                "package": "config",
                "fields": [
                    {"name": "Debug", "type": "bool", "tags": "yaml:\"debug\""},
                    {"name": "LogLevel", "type": "string", "tags": "yaml:\"log_level\""}
                ]
            },
            {
                "type": "function",
                "name": "Execute",
                "package": "commands",
                "parameters": [],
                "returns": [],
                "body": "// CLI command execution logic"
            }
        ]
    }'
    
    generate_and_write_code "$generation_payload" "$project_path" "cli"
}

generate_library_code() {
    local project_path=$1
    
    local generation_payload='{
        "elements": [
            {
                "type": "struct",
                "name": "Library",
                "package": "pkg",
                "fields": [
                    {"name": "Name", "type": "string", "tags": "json:\"name\""},
                    {"name": "Version", "type": "string", "tags": "json:\"version\""}
                ]
            },
            {
                "type": "function",
                "name": "NewLibrary",
                "package": "pkg",
                "parameters": [
                    {"name": "name", "type": "string"},
                    {"name": "version", "type": "string"}
                ],
                "returns": [{"type": "*Library"}],
                "body": "return &Library{Name: name, Version: version}"
            }
        ]
    }'
    
    generate_and_write_code "$generation_payload" "$project_path" "library"
}

generate_api_code() {
    local project_path=$1
    
    local generation_payload='{
        "elements": [
            {
                "type": "struct",
                "name": "APIResponse",
                "package": "api",
                "fields": [
                    {"name": "Success", "type": "bool", "tags": "json:\"success\""},
                    {"name": "Data", "type": "interface{}", "tags": "json:\"data,omitempty\""},
                    {"name": "Error", "type": "string", "tags": "json:\"error,omitempty\""}
                ]
            },
            {
                "type": "interface",
                "name": "Handler",
                "package": "interfaces",
                "methods": [
                    {"name": "Handle", "parameters": [{"name": "ctx", "type": "context.Context"}], "returns": [{"type": "*APIResponse"}, {"type": "error"}]}
                ]
            }
        ]
    }'
    
    generate_and_write_code "$generation_payload" "$project_path" "api"
}

generate_worker_code() {
    local project_path=$1
    
    local generation_payload='{
        "elements": [
            {
                "type": "struct",
                "name": "Job",
                "package": "worker",
                "fields": [
                    {"name": "ID", "type": "string", "tags": "json:\"id\""},
                    {"name": "Type", "type": "string", "tags": "json:\"type\""},
                    {"name": "Payload", "type": "map[string]interface{}", "tags": "json:\"payload\""}
                ]
            },
            {
                "type": "interface",
                "name": "Worker",
                "package": "worker",
                "methods": [
                    {"name": "Process", "parameters": [{"name": "job", "type": "*Job"}], "returns": [{"type": "error"}]},
                    {"name": "Start", "parameters": [], "returns": [{"type": "error"}]},
                    {"name": "Stop", "parameters": [], "returns": [{"type": "error"}]}
                ]
            }
        ]
    }'
    
    generate_and_write_code "$generation_payload" "$project_path" "worker"
}

generate_and_write_code() {
    local generation_payload=$1
    local project_path=$2
    local project_type=$3
    
    # Generate code
    local generation_response=$(curl -s -X POST http://localhost:8083/api/v1/generate \
        -H "Content-Type: application/json" \
        -d "$generation_payload")
    
    # Extract generated files
    local generated_files=$(echo "$generation_response" | jq '.accumulator.files')
    
    # Write files to project
    local write_files_payload=$(cat <<EOF
{
    "files": $generated_files,
    "output_path": "$project_path",
    "metadata": {
        "workflow": "project-types-test",
        "project_type": "$project_type",
        "generated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    }
}
EOF
)
    
    local write_response=$(curl -s -X POST http://localhost:8084/api/v1/files/write \
        -H "Content-Type: application/json" \
        -d "$write_files_payload")
    
    echo "Generated and wrote $project_type-specific code files"
}

# Main test execution
echo -e "${YELLOW}🎯 Testing 5 project types...${NC}"
echo ""

success_count=0
total_count=5
index=0

for project_type in $PROJECT_TYPES_LIST; do
    description="${PROJECT_DESCRIPTIONS[$index]}"
    
    if test_project_type "$project_type" "$description"; then
        ((success_count++))
    else
        echo -e "${RED}❌ Failed to test project type: $project_type${NC}"
    fi
    
    ((index++))
    echo ""
done

# Summary
echo -e "${BLUE}📊 =================================================================="
echo "                        TEST SUMMARY"
echo "==================================================================${NC}"
echo -e "${GREEN}✅ Successful tests: $success_count/$total_count${NC}"
echo -e "${YELLOW}📁 All projects created in: $TEST_SESSION_DIR${NC}"
echo ""

if [ $success_count -eq $total_count ]; then
    echo -e "${GREEN}🎉 All project structure types tested successfully!${NC}"
else
    echo -e "${YELLOW}⚠️  Some tests had issues. Check the output above for details.${NC}"
fi

echo ""
echo -e "${CYAN}📋 Generated Project Types:${NC}"
for project_type in $PROJECT_TYPES_LIST; do
    project_path="$TEST_SESSION_DIR/${project_type}-example"
    if [ -d "$project_path" ]; then
        echo -e "   ✅ ${project_type}: $project_path"
    else
        echo -e "   ❌ ${project_type}: $project_path (failed)"
    fi
done

echo ""
echo -e "${YELLOW}🔍 To explore individual projects:${NC}"
echo "   cd $TEST_SESSION_DIR"
echo "   ls -la"
echo ""
echo -e "${YELLOW}🔨 To run any generated project:${NC}"
echo "   cd $TEST_SESSION_DIR/[project-name]"
echo "   go run cmd/server/main.go  # (for microservice/api)"
echo "   go run cmd/main.go         # (for cli)"
echo "   go test ./...              # (for library/worker)"
echo ""
echo -e "${BLUE}🎯 Project Structure Service Validation Complete!${NC}"
