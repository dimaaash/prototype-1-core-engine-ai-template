#!/bin/bash

# Integration Test Script - Full Pipeline Validation
# Tests the complete pipeline: Orchestrator → Generator → Compiler
# Validates end-to-end integration with compilation checking

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ORCHESTRATOR_URL="http://localhost:8086"
GENERATOR_URL="http://localhost:8083"
COMPILER_URL="http://localhost:8084"
PROJECT_STRUCTURE_URL="http://localhost:8085"
OUTPUT_BASE="/tmp/integration-test-full-pipeline"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEST_DIR="${OUTPUT_BASE}-${TIMESTAMP}"

echo -e "${BLUE}🚀 Full Pipeline Integration Test${NC}"
echo -e "${BLUE}================================${NC}"
echo "Test Directory: ${TEST_DIR}"
echo "Timestamp: ${TIMESTAMP}"
echo ""

# Function to check service health
check_service() {
    local service_name=$1
    local url=$2
    echo -n "Checking ${service_name}..."
    # Use same health check logic as manage.sh - check for any HTTP response
    if curl -s -o /dev/null -w "%{http_code}" "${url}" 2>/dev/null | grep -q "200\|404\|405"; then
        echo -e " ${GREEN}✅ Running${NC}"
        return 0
    else
        echo -e " ${RED}❌ Not responding${NC}"
        echo "Please ensure ${service_name} is running on ${url}"
        return 1
    fi
}

# Function to run full pipeline test
run_full_pipeline_test() {
    local project_type=$1
    local project_name=$2
    local test_spec=$3
    
    echo -e "\n${YELLOW}🧪 Full Pipeline Test: ${project_type} - ${project_name}${NC}"
    echo "=============================================="
    
    local project_dir="${TEST_DIR}/${project_name}"
    local module_name="github.com/example/${project_name}"
    
    # Step 1: Create project structure
    echo -e "\n${BLUE}📁 Step 1: Creating project structure${NC}"
    local structure_response=$(curl -s -X POST "${PROJECT_STRUCTURE_URL}/api/v1/projects/create" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"${project_name}\",
            \"module_name\": \"${module_name}\",
            \"output_path\": \"${project_dir}\",
            \"project_type\": \"${project_type}\",
            \"include_gitignore\": true,
            \"include_readme\": true,
            \"include_dockerfile\": true,
            \"include_makefile\": true
        }")
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}❌ Failed to create project structure${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Project structure created${NC}"
    
    # Step 2: Generate entities via orchestrator
    echo -e "\n${BLUE}🔄 Step 2: Generating entities via orchestrator${NC}"
    
    # Create test specification
    echo "${test_spec}" > "${TEST_DIR}/${project_name}-spec.json"
    
    local orchestrator_response=$(curl -s -X POST "${ORCHESTRATOR_URL}/api/v1/orchestrate/${project_type}" \
        -H "Content-Type: application/json" \
        -d "${test_spec}")
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}❌ Failed to orchestrate entities${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Entities orchestrated${NC}"
    
    # Step 3: Generate code
    echo -e "\n${BLUE}🔧 Step 3: Generating code${NC}"
    local generator_payload=$(echo "${orchestrator_response}" | jq -r '.generator_payload')
    
    if [[ "${generator_payload}" == "null" || -z "${generator_payload}" ]]; then
        echo -e "${RED}❌ No generator payload${NC}"
        return 1
    fi
    
    local generator_response=$(echo "${generator_payload}" | curl -s -X POST "${GENERATOR_URL}/api/v1/generate" \
        -H "Content-Type: application/json" \
        -d @-)
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}❌ Failed to generate code${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Code generated${NC}"
    
    # Step 4: Write files to project
    echo -e "\n${BLUE}📝 Step 4: Writing files to project${NC}"
    local files_data=$(echo "${generator_response}" | jq -c '.accumulator.files')
    
    # Write files using compiler service
    local write_response=$(curl -s -X POST "${COMPILER_URL}/api/v1/files/write" \
        -H "Content-Type: application/json" \
        -d "{
            \"files\": ${files_data},
            \"output_path\": \"${project_dir}\",
            \"metadata\": {
                \"workflow\": \"full-pipeline-test\",
                \"project_type\": \"${project_type}\"
            }
        }")
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}❌ Failed to write files${NC}"
        return 1
    fi
    
    local file_count=$(echo "${files_data}" | jq '. | length')
    echo -e "${GREEN}✅ ${file_count} files written to project${NC}"
    
    # Step 5: Validate project structure
    echo -e "\n${BLUE}🔍 Step 5: Validating project structure${NC}"
    if [[ -d "${project_dir}" ]]; then
        echo "Project directory exists: ✅"
        
        # Check for go.mod
        if [[ -f "${project_dir}/go.mod" ]]; then
            echo "go.mod exists: ✅"
        else
            echo "go.mod missing: ❌"
        fi
        
        # Check for generated entities
        local entity_files=$(find "${project_dir}" -name "*.go" -path "*/domain/*" | wc -l)
        echo "Generated entity files: ${entity_files}"
        
        # Show project structure
        echo -e "\n📁 Project structure:"
        tree "${project_dir}" -L 3 2>/dev/null || find "${project_dir}" -type d | head -10
        
    else
        echo -e "${RED}❌ Project directory not found${NC}"
        return 1
    fi
    
    # Step 6: Attempt compilation
    echo -e "\n${BLUE}🔨 Step 6: Testing compilation${NC}"
    cd "${project_dir}"
    
    # Check if we can run go mod tidy
    if go mod tidy 2>/dev/null; then
        echo "go mod tidy: ✅"
        
        # Try to build
        if go build ./... 2>/dev/null; then
            echo -e "${GREEN}✅ Project compiles successfully!${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  Project has compilation issues${NC}"
            echo "Running go build for detailed errors:"
            go build ./... 2>&1 | head -10
            return 2  # Partial success
        fi
    else
        echo -e "${YELLOW}⚠️  go mod tidy failed${NC}"
        go mod tidy 2>&1 | head -5
        return 2  # Partial success
    fi
}

# Check all services
echo -e "${BLUE}🔍 Checking service health...${NC}"
services_ok=true
check_service "Orchestrator Service" "${ORCHESTRATOR_URL}" || services_ok=false
check_service "Generator Service" "${GENERATOR_URL}" || services_ok=false
check_service "Compiler Service" "${COMPILER_URL}" || services_ok=false
check_service "Project Structure Service" "${PROJECT_STRUCTURE_URL}" || services_ok=false

if [[ "${services_ok}" != "true" ]]; then
    echo -e "${RED}❌ Some services are not running. Please start all services first.${NC}"
    exit 1
fi

# Create test directory
mkdir -p "${TEST_DIR}"

# Test specifications for different project types
CLI_SPEC='{
  "name": "cli-tool",
  "module_path": "github.com/example/cli-tool",
  "output_path": "",
  "project_type": "cli",
  "entities": [
    {
      "name": "Command",
      "fields": [
        {
          "name": "ID",
          "type": "uuid",
          "required": true
        },
        {
          "name": "Name",
          "type": "string",
          "required": true,
          "validation": ["min:1", "max:50"]
        },
        {
          "name": "Args",
          "type": "json",
          "required": false
        }
      ]
    }
  ],
  "features": ["cli_commands", "validation"]
}'

MICROSERVICE_SPEC='{
  "name": "user-service",
  "module_path": "github.com/example/user-service",
  "output_path": "",
  "project_type": "microservice",
  "entities": [
    {
      "name": "User",
      "fields": [
        {
          "name": "ID",
          "type": "uuid",
          "required": true
        },
        {
          "name": "Email",
          "type": "email",
          "required": true,
          "validation": ["email"]
        },
        {
          "name": "CreatedAt",
          "type": "timestamp",
          "required": true
        }
      ],
      "constraints": [
        {
          "name": "unique_email",
          "type": "unique",
          "fields": ["Email"]
        }
      ]
    }
  ],
  "features": ["rest_api", "database", "validation"]
}'

API_SPEC='{
  "name": "product-api",
  "module_path": "github.com/example/product-api",
  "output_path": "",
  "project_type": "api",
  "entities": [
    {
      "name": "Product",
      "fields": [
        {
          "name": "ID",
          "type": "uuid",
          "required": true
        },
        {
          "name": "Name",
          "type": "string",
          "required": true,
          "validation": ["min:1", "max:100"]
        },
        {
          "name": "Price",
          "type": "decimal",
          "required": true,
          "validation": ["min:0"]
        }
      ],
      "endpoints": [
        {
          "path": "/products",
          "method": "GET",
          "description": "List products"
        }
      ]
    }
  ],
  "features": ["rest_api", "validation", "documentation"]
}'

# Run tests
success_count=0
partial_count=0
failure_count=0

# Test CLI project
if run_full_pipeline_test "cli" "cli-tool-test" "${CLI_SPEC}"; then
    ((success_count++))
elif [[ $? -eq 2 ]]; then
    ((partial_count++))
else
    ((failure_count++))
fi

# Test Microservice project
if run_full_pipeline_test "microservice" "user-service-test" "${MICROSERVICE_SPEC}"; then
    ((success_count++))
elif [[ $? -eq 2 ]]; then
    ((partial_count++))
else
    ((failure_count++))
fi

# Test API project
if run_full_pipeline_test "api" "product-api-test" "${API_SPEC}"; then
    ((success_count++))
elif [[ $? -eq 2 ]]; then
    ((partial_count++))
else
    ((failure_count++))
fi

# Add missing project types for comprehensive coverage

# Library Project Spec
LIBRARY_SPEC='{
  "name": "go-cache",
  "module_path": "github.com/example/go-cache",
  "output_path": "",
  "project_type": "library",
  "entities": [
    {
      "name": "CacheEntry",
      "fields": [
        {
          "name": "Key",
          "type": "string",
          "required": true,
          "primary_key": true
        },
        {
          "name": "Value",
          "type": "json",
          "required": true
        },
        {
          "name": "TTL",
          "type": "integer",
          "required": true,
          "validation": ["min:0"]
        },
        {
          "name": "ExpiresAt",
          "type": "timestamp",
          "required": false
        }
      ]
    }
  ],
  "features": ["public_api", "documentation", "validation"]
}'

# Test Library project
if run_full_pipeline_test "library" "go-cache-test" "${LIBRARY_SPEC}"; then
    ((success_count++))
elif [[ $? -eq 2 ]]; then
    ((partial_count++))
else
    ((failure_count++))
fi

# Web Project Spec
WEB_SPEC='{
  "name": "blog-web",
  "module_path": "github.com/example/blog-web",
  "output_path": "",
  "project_type": "web",
  "entities": [
    {
      "name": "Article",
      "fields": [
        {
          "name": "ID",
          "type": "uuid",
          "required": true,
          "primary_key": true
        },
        {
          "name": "Title",
          "type": "string",
          "required": true,
          "validation": ["max:200"]
        },
        {
          "name": "Content",
          "type": "text",
          "required": true
        },
        {
          "name": "Published",
          "type": "boolean",
          "required": true,
          "default": false
        },
        {
          "name": "CreatedAt",
          "type": "timestamp",
          "required": true
        }
      ]
    }
  ],
  "features": ["web_templates", "static_files", "validation"]
}'

# Test Web project
if run_full_pipeline_test "web" "blog-web-test" "${WEB_SPEC}"; then
    ((success_count++))
elif [[ $? -eq 2 ]]; then
    ((partial_count++))
else
    ((failure_count++))
fi

# Worker Project Spec
WORKER_SPEC='{
  "name": "task-worker",
  "module_path": "github.com/example/task-worker",
  "output_path": "",
  "project_type": "worker",
  "entities": [
    {
      "name": "Job",
      "fields": [
        {
          "name": "ID",
          "type": "uuid",
          "required": true,
          "primary_key": true
        },
        {
          "name": "Type",
          "type": "enum",
          "required": true,
          "enum_values": ["email", "report", "cleanup"]
        },
        {
          "name": "Status",
          "type": "enum",
          "required": true,
          "enum_values": ["pending", "running", "completed", "failed"],
          "default": "pending"
        },
        {
          "name": "Priority",
          "type": "integer",
          "required": true,
          "default": 0,
          "validation": ["min:0", "max:10"]
        },
        {
          "name": "Payload",
          "type": "json",
          "required": true
        },
        {
          "name": "CreatedAt",
          "type": "timestamp",
          "required": true
        }
      ]
    }
  ],
  "features": ["job_processing", "queue_management", "validation"]
}'

# Test Worker project
if run_full_pipeline_test "worker" "task-worker-test" "${WORKER_SPEC}"; then
    ((success_count++))
elif [[ $? -eq 2 ]]; then
    ((partial_count++))
else
    ((failure_count++))
fi

# Summary
echo -e "\n${BLUE}📊 Full Pipeline Test Summary${NC}"
echo -e "${BLUE}=============================${NC}"
echo "Test directory: ${TEST_DIR}"
echo ""
echo -e "${GREEN}✅ Successful builds: ${success_count}${NC}"
echo -e "${YELLOW}⚠️  Partial success: ${partial_count}${NC}"
echo -e "${RED}❌ Failures: ${failure_count}${NC}"

total_tests=$((success_count + partial_count + failure_count))
if [[ ${total_tests} -gt 0 ]]; then
    success_rate=$(( (success_count * 100) / total_tests ))
    partial_rate=$(( (partial_count * 100) / total_tests ))
    echo ""
    echo "Success rate: ${success_rate}%"
    echo "Partial success rate: ${partial_rate}%"
    echo "Combined success rate: $((success_rate + partial_rate))%"
fi

echo ""
echo -e "${YELLOW}🔍 To inspect generated projects:${NC}"
echo "cd ${TEST_DIR}"
echo "ls -la"

echo ""
echo -e "${YELLOW}🔨 To test compilation manually:${NC}"
echo "cd ${TEST_DIR}/<project-name>"
echo "go mod tidy"
echo "go build ./..."

echo ""
if [[ ${success_count} -gt 0 ]]; then
    echo -e "${GREEN}✅ Full Pipeline Integration Test Complete - Some projects compile successfully!${NC}"
elif [[ ${partial_count} -gt 0 ]]; then
    echo -e "${YELLOW}⚠️  Full Pipeline Integration Test Complete - Projects generated but need compilation fixes${NC}"
else
    echo -e "${RED}❌ Full Pipeline Integration Test Complete - Issues detected${NC}"
fi
