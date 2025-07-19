#!/bin/bash

# Integration Test Script - Enhanced Orchestrator Service v2.0.0
# Tests the enhanced orchestrator service with advanced entity features
# Based on integration testing performed on July 19, 2025

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
OUTPUT_BASE="/tmp/integration-test-orchestrator-v2"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEST_DIR="${OUTPUT_BASE}-${TIMESTAMP}"

echo -e "${BLUE}🚀 Enhanced Orchestrator Service v2.0.0 Integration Test${NC}"
echo -e "${BLUE}===================================================${NC}"
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

# Function to test orchestrator endpoint
test_orchestrator_endpoint() {
    local project_type=$1
    local test_file=$2
    local description=$3
    
    echo -e "\n${YELLOW}📋 Testing ${project_type} project with ${description}${NC}"
    echo "Input file: ${test_file}"
    
    if [[ ! -f "${test_file}" ]]; then
        echo -e "${RED}❌ Test file not found: ${test_file}${NC}"
        return 1
    fi
    
    # Step 1: Send to orchestrator
    echo "  🔄 Sending request to orchestrator service..."
    local orchestrator_response=$(curl -s -X POST "${ORCHESTRATOR_URL}/api/v1/orchestrate/${project_type}" \
        -H "Content-Type: application/json" \
        -d @"${test_file}")
    
    if [[ $? -ne 0 ]]; then
        echo -e "  ${RED}❌ Failed to send request to orchestrator${NC}"
        return 1
    fi
    
    echo "  ✅ Orchestrator response received"
    
    # Step 2: Extract payload and send to generator
    echo "  🔄 Extracting payload and sending to generator..."
    local generator_payload=$(echo "${orchestrator_response}" | jq -r '.generator_payload')
    
    if [[ "${generator_payload}" == "null" || -z "${generator_payload}" ]]; then
        echo -e "  ${RED}❌ No generator payload in response${NC}"
        echo "  Response: ${orchestrator_response}"
        return 1
    fi
    
    local generator_response=$(echo "${generator_payload}" | curl -s -X POST "${GENERATOR_URL}/api/v1/generate" \
        -H "Content-Type: application/json" \
        -d @-)
    
    if [[ $? -ne 0 ]]; then
        echo -e "  ${RED}❌ Failed to send request to generator${NC}"
        return 1
    fi
    
    echo "  ✅ Generator response received"
    
    # Step 3: Extract files and write to disk
    echo "  🔄 Writing generated files..."
    local output_dir="${TEST_DIR}/${project_type}-$(date +%H%M%S)"
    mkdir -p "${output_dir}"
    
    local files_data=$(echo "${generator_response}" | jq -r '.accumulator.files')
    
    if [[ "${files_data}" == "null" || -z "${files_data}" ]]; then
        echo -e "  ${RED}❌ No files in generator response${NC}"
        return 1
    fi
    
    # Write files locally for inspection
    echo "${files_data}" | jq -c '.[]' | while read -r file_data; do
        local file_path=$(echo "${file_data}" | jq -r '.path')
        local file_content=$(echo "${file_data}" | jq -r '.content')
        local full_path="${output_dir}/${file_path}"
        
        mkdir -p "$(dirname "${full_path}")"
        echo "${file_content}" > "${full_path}"
        echo "    📄 Created: ${file_path}"
    done
    
    # Step 4: Count files and show summary
    local file_count=$(echo "${files_data}" | jq '. | length')
    echo -e "  ${GREEN}✅ Successfully generated ${file_count} files${NC}"
    
    # Step 5: Show enhanced features detected
    echo "  🔍 Enhanced features detected:"
    
    # Check for advanced types
    if grep -r "decimal.Decimal\|json.RawMessage\|time.Time" "${output_dir}" > /dev/null 2>&1; then
        echo "    ✅ Advanced type mappings (decimal, json, timestamp)"
    fi
    
    # Check for validation tags
    if grep -r 'validate:' "${output_dir}" > /dev/null 2>&1; then
        echo "    ✅ Validation tags applied"
    fi
    
    # Check for database tags
    if grep -r 'db:' "${output_dir}" > /dev/null 2>&1; then
        echo "    ✅ Database tags generated"
    fi
    
    # Check for constructor functions
    if grep -r "func New" "${output_dir}" > /dev/null 2>&1; then
        echo "    ✅ Constructor functions generated"
    fi
    
    echo "  📁 Output directory: ${output_dir}"
    
    return 0
}

# Check service health
echo -e "${BLUE}🔍 Checking service health...${NC}"
check_service "Orchestrator Service" "${ORCHESTRATOR_URL}"
check_service "Generator Service" "${GENERATOR_URL}"
check_service "Compiler Service" "${COMPILER_URL}"

# Create test directory
mkdir -p "${TEST_DIR}"

# Test Case 1: CLI Project with Enhanced Features
echo -e "\n${BLUE}🧪 Test Case 1: CLI Project with Enhanced Features${NC}"
cat > "${TEST_DIR}/test-cli-enhanced.json" << 'EOF'
{
  "name": "config-manager",
  "module_path": "github.com/example/config-manager",
  "output_path": "/tmp/generated/config-manager-cli",
  "project_type": "cli",
  "entities": [
    {
      "name": "ConfigFile",
      "fields": [
        {
          "name": "ID",
          "type": "uuid",
          "required": true
        },
        {
          "name": "Path",
          "type": "string",
          "required": true,
          "validation": ["max:500"]
        },
        {
          "name": "Content",
          "type": "json",
          "required": true
        },
        {
          "name": "CreatedAt",
          "type": "timestamp",
          "required": true
        }
      ],
      "relationships": [
        {
          "name": "templates",
          "type": "one_to_many",
          "target": "Template",
          "foreign_key": "config_file_id"
        }
      ],
      "constraints": [
        {
          "name": "unique_config_path",
          "type": "unique",
          "fields": ["Path"]
        }
      ],
      "indexes": [
        {
          "name": "idx_config_created",
          "type": "btree",
          "fields": ["CreatedAt"]
        }
      ]
    }
  ],
  "features": [
    "cli_commands",
    "config_management",
    "validation"
  ]
}
EOF

test_orchestrator_endpoint "cli" "${TEST_DIR}/test-cli-enhanced.json" "enhanced CLI features"

# Test Case 2: Microservice with Complex Relationships
echo -e "\n${BLUE}🧪 Test Case 2: Microservice with Complex Relationships${NC}"
cat > "${TEST_DIR}/test-microservice-complex.json" << 'EOF'
{
  "name": "order-service",
  "module_path": "github.com/example/order-service",
  "output_path": "/tmp/generated/order-service-micro",
  "project_type": "microservice",
  "entities": [
    {
      "name": "Order",
      "fields": [
        {
          "name": "ID",
          "type": "uuid",
          "required": true
        },
        {
          "name": "CustomerID",
          "type": "uuid",
          "required": true
        },
        {
          "name": "Status",
          "type": "enum",
          "required": true,
          "enum_values": ["pending", "confirmed", "shipped", "delivered"]
        },
        {
          "name": "TotalAmount",
          "type": "decimal",
          "required": true,
          "validation": ["min:0"]
        },
        {
          "name": "CreatedAt",
          "type": "timestamp",
          "required": true
        }
      ],
      "relationships": [
        {
          "name": "items",
          "type": "one_to_many",
          "target": "OrderItem",
          "foreign_key": "order_id"
        }
      ],
      "constraints": [
        {
          "name": "positive_total",
          "type": "check",
          "condition": "total_amount >= 0"
        }
      ],
      "indexes": [
        {
          "name": "idx_order_customer",
          "type": "btree",
          "fields": ["CustomerID"]
        }
      ]
    },
    {
      "name": "OrderItem",
      "fields": [
        {
          "name": "ID",
          "type": "uuid",
          "required": true
        },
        {
          "name": "OrderID",
          "type": "uuid",
          "required": true
        },
        {
          "name": "ProductID",
          "type": "uuid",
          "required": true
        },
        {
          "name": "Quantity",
          "type": "integer",
          "required": true,
          "validation": ["min:1"]
        },
        {
          "name": "UnitPrice",
          "type": "decimal",
          "required": true,
          "validation": ["min:0"]
        }
      ],
      "relationships": [
        {
          "name": "order",
          "type": "many_to_one",
          "target": "Order",
          "foreign_key": "order_id"
        }
      ]
    }
  ],
  "features": [
    "rest_api",
    "database",
    "validation",
    "monitoring"
  ]
}
EOF

test_orchestrator_endpoint "microservice" "${TEST_DIR}/test-microservice-complex.json" "complex relationships and validation"

# Test Case 3: API Project with Advanced Features
echo -e "\n${BLUE}🧪 Test Case 3: API Project with Advanced Features${NC}"
if [[ -f "test-integration-full-pipeline.json" ]]; then
    test_orchestrator_endpoint "api" "test-integration-full-pipeline.json" "full pipeline integration"
else
    echo -e "${YELLOW}⚠️  test-integration-full-pipeline.json not found, skipping API test${NC}"
fi

# Test Case 4: Library Project with Public API
echo -e "\n${BLUE}🧪 Test Case 4: Library Project with Public API${NC}"
cat > "${TEST_DIR}/test-library-public.json" << 'EOF'
{
  "name": "user-lib",
  "module_path": "github.com/example/user-lib",
  "output_path": "/tmp/generated/user-lib",
  "project_type": "library",
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
          "name": "Profile",
          "type": "json",
          "required": false
        },
        {
          "name": "LastLogin",
          "type": "timestamp",
          "required": false
        }
      ],
      "constraints": [
        {
          "name": "unique_user_email",
          "type": "unique",
          "fields": ["Email"]
        }
      ],
      "indexes": [
        {
          "name": "idx_user_email",
          "type": "btree",
          "fields": ["Email"]
        }
      ]
    }
  ],
  "features": [
    "public_api",
    "validation",
    "documentation"
  ]
}
EOF

test_orchestrator_endpoint "library" "${TEST_DIR}/test-library-public.json" "public library API"

# Test Case 5: Web Project with Templates and Static Content
echo -e "\n${YELLOW}🧪 Test Case 5: Web Project with Advanced Features${NC}"
echo -e "${YELLOW}⚠️  test-integration-full-pipeline.json not found, creating web test${NC}"

cat > "${TEST_DIR}/test-web-app.json" << 'EOF'
{
  "name": "web-dashboard",
  "module_path": "github.com/example/web-dashboard",
  "output_path": "/tmp/generated/web-dashboard",
  "project_type": "web",
  "entities": [
    {
      "name": "Page",
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
          "validation": ["min:1", "max:200"]
        },
        {
          "name": "Content",
          "type": "text",
          "required": true
        },
        {
          "name": "Template",
          "type": "string",
          "required": true,
          "validation": ["max:100"]
        },
        {
          "name": "Published",
          "type": "boolean",
          "required": true,
          "default": "false"
        },
        {
          "name": "CreatedAt",
          "type": "timestamp",
          "required": true
        },
        {
          "name": "UpdatedAt",
          "type": "timestamp",
          "required": true
        }
      ],
      "indexes": [
        {
          "name": "idx_page_published",
          "type": "btree",
          "fields": ["Published", "CreatedAt"]
        }
      ]
    }
  ],
  "features": [
    "web_templates",
    "static_files",
    "session_management",
    "validation"
  ]
}
EOF

test_orchestrator_endpoint "web" "${TEST_DIR}/test-web-app.json" "web application with templates"

# Test Case 6: Worker Project with Job Processing
echo -e "\n${YELLOW}🧪 Test Case 6: Worker Project with Job Processing${NC}"

cat > "${TEST_DIR}/test-worker-jobs.json" << 'EOF'
{
  "name": "email-worker",
  "module_path": "github.com/example/email-worker",
  "output_path": "/tmp/generated/email-worker",
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
          "enum_values": ["email", "notification", "webhook", "report"]
        },
        {
          "name": "Payload",
          "type": "json",
          "required": true
        },
        {
          "name": "Status",
          "type": "enum",
          "required": true,
          "enum_values": ["pending", "processing", "completed", "failed", "retrying"],
          "default": "pending"
        },
        {
          "name": "Priority",
          "type": "integer",
          "required": true,
          "default": "0",
          "validation": ["min:0", "max:10"]
        },
        {
          "name": "MaxRetries",
          "type": "integer",
          "required": true,
          "default": "3"
        },
        {
          "name": "Attempts",
          "type": "integer",
          "required": true,
          "default": "0"
        },
        {
          "name": "ScheduledAt",
          "type": "timestamp",
          "required": false
        },
        {
          "name": "StartedAt",
          "type": "timestamp",
          "required": false
        },
        {
          "name": "CompletedAt",
          "type": "timestamp",
          "required": false
        },
        {
          "name": "CreatedAt",
          "type": "timestamp",
          "required": true
        },
        {
          "name": "UpdatedAt",
          "type": "timestamp",
          "required": true
        }
      ],
      "constraints": [
        {
          "name": "check_priority_range",
          "type": "check",
          "expression": "Priority >= 0 AND Priority <= 10"
        }
      ],
      "indexes": [
        {
          "name": "idx_job_status_priority",
          "type": "btree",
          "fields": ["Status", "Priority", "ScheduledAt"]
        },
        {
          "name": "idx_job_type_status",
          "type": "btree",
          "fields": ["Type", "Status"]
        }
      ]
    },
    {
      "name": "WorkerStats",
      "fields": [
        {
          "name": "ID",
          "type": "uuid",
          "required": true,
          "primary_key": true
        },
        {
          "name": "WorkerID",
          "type": "string",
          "required": true
        },
        {
          "name": "JobsProcessed",
          "type": "integer",
          "required": true,
          "default": "0"
        },
        {
          "name": "JobsSucceeded",
          "type": "integer",
          "required": true,
          "default": "0"
        },
        {
          "name": "JobsFailed",
          "type": "integer",
          "required": true,
          "default": "0"
        },
        {
          "name": "LastActiveAt",
          "type": "timestamp",
          "required": true
        },
        {
          "name": "CreatedAt",
          "type": "timestamp",
          "required": true
        }
      ],
      "constraints": [
        {
          "name": "unique_worker_id",
          "type": "unique",
          "fields": ["WorkerID"]
        }
      ]
    }
  ],
  "features": [
    "job_processing",
    "queue_management",
    "worker_pools",
    "retry_logic",
    "metrics",
    "validation"
  ]
}
EOF

test_orchestrator_endpoint "worker" "${TEST_DIR}/test-worker-jobs.json" "worker with job processing"

# Summary
echo -e "\n${BLUE}📊 Integration Test Summary${NC}"
echo -e "${BLUE}=========================${NC}"
echo "Test directory: ${TEST_DIR}"
echo ""
echo "Generated projects:"
find "${TEST_DIR}" -type d -name "*-*" | while read -r dir; do
    if [[ -d "${dir}" ]]; then
        project_name=$(basename "${dir}")
        file_count=$(find "${dir}" -type f -name "*.go" | wc -l)
        echo "  📁 ${project_name}: ${file_count} Go files"
    fi
done

echo ""
echo -e "${YELLOW}🔍 To inspect generated code:${NC}"
echo "cd ${TEST_DIR}"
echo "find . -name '*.go' -exec echo '=== {} ===' \\; -exec cat {} \\;"

echo ""
echo -e "${YELLOW}🧪 To validate compilation:${NC}"
echo "# For each generated project directory:"
echo "cd <project_directory>"
echo "go mod init <module_name>"
echo "go mod tidy"
echo "go build ./..."

echo ""
echo -e "${GREEN}✅ Enhanced Orchestrator Service v2.0.0 Integration Test Complete${NC}"
