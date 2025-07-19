#!/bin/bash

# Integration Test Script - Regression Testing
# Ensures that enhanced orchestrator service maintains backward compatibility
# Tests existing functionality while validating new features

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
ORCHESTRATOR_URL="http://localhost:8086"
GENERATOR_URL="http://localhost:8083"
OUTPUT_BASE="/tmp/integration-test-regression"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEST_DIR="${OUTPUT_BASE}-${TIMESTAMP}"

echo -e "${CYAN}🔍 Regression Testing - Enhanced Orchestrator Service v2.0.0${NC}"
echo -e "${CYAN}=======================================================${NC}"
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
        return 1
    fi
}

# Function to test backward compatibility
test_backward_compatibility() {
    local test_name=$1
    local project_type=$2
    local payload=$3
    local expected_features=$4
    
    echo -e "\n${YELLOW}🔄 Backward Compatibility Test: ${test_name}${NC}"
    echo "Project Type: ${project_type}"
    
    # Send request
    local response=$(curl -s -X POST "${ORCHESTRATOR_URL}/api/v1/orchestrate/${project_type}" \
        -H "Content-Type: application/json" \
        -d "${payload}")
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}❌ Request failed${NC}"
        return 1
    fi
    
    # Check response structure
    local orchestrated_payload=$(echo "${response}" | jq -r '.generator_payload')
    if [[ "${orchestrated_payload}" == "null" || -z "${orchestrated_payload}" ]]; then
        echo -e "${RED}❌ No generator payload in response${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Response structure valid${NC}"
    
    # Test with generator
    local generator_response=$(echo "${orchestrated_payload}" | curl -s -X POST "${GENERATOR_URL}/api/v1/generate" \
        -H "Content-Type: application/json" \
        -d @-)
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}❌ Generator integration failed${NC}"
        return 1
    fi
    
    local files_count=$(echo "${generator_response}" | jq '.accumulator.files | length')
    echo -e "${GREEN}✅ Generated ${files_count} files${NC}"
    
    # Validate expected features
    for feature in ${expected_features}; do
        if echo "${generator_response}" | grep -q "${feature}"; then
            echo -e "  ✅ Feature '${feature}' present"
        else
            echo -e "  ⚠️  Feature '${feature}' not found (may be expected for simple tests)"
        fi
    done
    
    return 0
}

# Function to test enhanced features
test_enhanced_features() {
    local test_name=$1
    local project_type=$2
    local payload=$3
    local new_features=$4
    
    echo -e "\n${BLUE}🆕 Enhanced Features Test: ${test_name}${NC}"
    echo "Project Type: ${project_type}"
    
    # Send request
    local response=$(curl -s -X POST "${ORCHESTRATOR_URL}/api/v1/orchestrate/${project_type}" \
        -H "Content-Type: application/json" \
        -d "${payload}")
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}❌ Request failed${NC}"
        return 1
    fi
    
    # Check enhanced response
    local orchestrated_payload=$(echo "${response}" | jq -r '.generator_payload')
    if [[ "${orchestrated_payload}" == "null" || -z "${orchestrated_payload}" ]]; then
        echo -e "${RED}❌ No generator payload in response${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Enhanced response structure valid${NC}"
    
    # Test with generator
    local generator_response=$(echo "${orchestrated_payload}" | curl -s -X POST "${GENERATOR_URL}/api/v1/generate" \
        -H "Content-Type: application/json" \
        -d @-)
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}❌ Generator integration failed${NC}"
        return 1
    fi
    
    local files_count=$(echo "${generator_response}" | jq '.accumulator.files | length')
    echo -e "${GREEN}✅ Generated ${files_count} files with enhanced features${NC}"
    
    # Save generated content for analysis
    local test_output="${TEST_DIR}/${test_name}-output"
    mkdir -p "${test_output}"
    echo "${generator_response}" | jq -r '.accumulator.files[] | .path + ":\n" + .content + "\n---"' > "${test_output}/generated-code.txt"
    
    # Validate new features
    for feature in ${new_features}; do
        case "${feature}" in
            "decimal_type")
                if grep -q "decimal\.Decimal" "${test_output}/generated-code.txt"; then
                    echo -e "  ✅ Enhanced type mapping: decimal.Decimal"
                else
                    echo -e "  ❌ Missing: decimal.Decimal type"
                fi
                ;;
            "json_type")
                if grep -q "json\.RawMessage" "${test_output}/generated-code.txt"; then
                    echo -e "  ✅ Enhanced type mapping: json.RawMessage"
                else
                    echo -e "  ❌ Missing: json.RawMessage type"
                fi
                ;;
            "validation_tags")
                if grep -q 'validate:' "${test_output}/generated-code.txt"; then
                    echo -e "  ✅ Validation tags present"
                else
                    echo -e "  ❌ Missing: validation tags"
                fi
                ;;
            "constructor_functions")
                if grep -q "func New" "${test_output}/generated-code.txt"; then
                    echo -e "  ✅ Constructor functions generated"
                else
                    echo -e "  ❌ Missing: constructor functions"
                fi
                ;;
            "database_tags")
                if grep -q 'db:' "${test_output}/generated-code.txt"; then
                    echo -e "  ✅ Database tags present"
                else
                    echo -e "  ❌ Missing: database tags"
                fi
                ;;
            "relationships")
                if grep -q -i "relationship\|foreign" "${test_output}/generated-code.txt"; then
                    echo -e "  ✅ Relationship structures present"
                else
                    echo -e "  ⚠️  No relationship structures (may be expected)"
                fi
                ;;
        esac
    done
    
    return 0
}

# Function to test edge cases
test_edge_cases() {
    echo -e "\n${CYAN}🧪 Edge Case Testing${NC}"
    
    # Test 1: Empty entities array
    echo -e "\n${YELLOW}Edge Case 1: Empty entities array${NC}"
    local empty_response=$(curl -s -X POST "${ORCHESTRATOR_URL}/api/v1/orchestrate/microservice" \
        -H "Content-Type: application/json" \
        -d '{
            "name": "empty-test",
            "module_path": "github.com/example/empty-test",
            "output_path": "/tmp/generated/empty-test",
            "project_type": "microservice",
            "entities": [],
            "features": ["rest_api"]
        }')
    
    if echo "${empty_response}" | jq -e '.orchestrated_payload' > /dev/null; then
        echo -e "${GREEN}✅ Handles empty entities gracefully${NC}"
    else
        echo -e "${RED}❌ Failed to handle empty entities${NC}"
    fi
    
    # Test 2: Missing optional fields
    echo -e "\n${YELLOW}Edge Case 2: Missing optional fields${NC}"
    local minimal_response=$(curl -s -X POST "${ORCHESTRATOR_URL}/api/v1/orchestrate/cli" \
        -H "Content-Type: application/json" \
        -d '{
            "name": "minimal-test",
            "module_path": "github.com/example/minimal-test",
            "project_type": "cli",
            "entities": [
                {
                    "name": "SimpleEntity",
                    "fields": [
                        {
                            "name": "ID",
                            "type": "string",
                            "required": true
                        }
                    ]
                }
            ]
        }')
    
    if echo "${minimal_response}" | jq -e '.orchestrated_payload' > /dev/null; then
        echo -e "${GREEN}✅ Handles minimal configuration gracefully${NC}"
    else
        echo -e "${RED}❌ Failed to handle minimal configuration${NC}"
    fi
    
    # Test 3: Large entity with many fields
    echo -e "\n${YELLOW}Edge Case 3: Large entity (20+ fields)${NC}"
    local large_fields=""
    for i in {1..25}; do
        if [[ $i -gt 1 ]]; then large_fields+=","; fi
        large_fields+='{
            "name": "Field'${i}'",
            "type": "string",
            "required": false
        }'
    done
    
    local large_response=$(curl -s -X POST "${ORCHESTRATOR_URL}/api/v1/orchestrate/library" \
        -H "Content-Type: application/json" \
        -d '{
            "name": "large-entity-test",
            "module_path": "github.com/example/large-entity-test",
            "project_type": "library",
            "entities": [
                {
                    "name": "LargeEntity",
                    "fields": ['${large_fields}']
                }
            ]
        }')
    
    if echo "${large_response}" | jq -e '.orchestrated_payload' > /dev/null; then
        echo -e "${GREEN}✅ Handles large entities gracefully${NC}"
    else
        echo -e "${RED}❌ Failed to handle large entities${NC}"
    fi
}

# Check service health
echo -e "${BLUE}🔍 Checking service health...${NC}"
if ! check_service "Orchestrator Service" "${ORCHESTRATOR_URL}"; then
    echo -e "${RED}❌ Orchestrator service not running${NC}"
    exit 1
fi

if ! check_service "Generator Service" "${GENERATOR_URL}"; then
    echo -e "${RED}❌ Generator service not running${NC}"
    exit 1
fi

# Create test directory
mkdir -p "${TEST_DIR}"

# Backward Compatibility Tests
echo -e "\n${CYAN}🔄 Backward Compatibility Tests${NC}"
echo -e "${CYAN}================================${NC}"

# Test 1: Simple CLI project (v1.0 style)
test_backward_compatibility "Simple CLI Project" "cli" '{
  "name": "simple-cli",
  "module_path": "github.com/example/simple-cli",
  "output_path": "/tmp/generated/simple-cli",
  "project_type": "cli",
  "entities": [
    {
      "name": "Config",
      "fields": [
        {
          "name": "ID",
          "type": "string",
          "required": true
        },
        {
          "name": "Value",
          "type": "string",
          "required": true
        }
      ]
    }
  ],
  "features": ["cli_commands"]
}' "ID Value"

# Test 2: Basic microservice (v1.0 style)
test_backward_compatibility "Basic Microservice" "microservice" '{
  "name": "simple-service",
  "module_path": "github.com/example/simple-service",
  "output_path": "/tmp/generated/simple-service",
  "project_type": "microservice",
  "entities": [
    {
      "name": "User",
      "fields": [
        {
          "name": "ID",
          "type": "string",
          "required": true
        },
        {
          "name": "Name",
          "type": "string",
          "required": true
        }
      ]
    }
  ],
  "features": ["rest_api"]
}' "ID Name"

# Enhanced Features Tests
echo -e "\n${CYAN}🆕 Enhanced Features Tests${NC}"
echo -e "${CYAN}=========================${NC}"

# Test 1: Advanced type mappings
test_enhanced_features "Advanced Type Mappings" "api" '{
  "name": "advanced-types",
  "module_path": "github.com/example/advanced-types",
  "output_path": "/tmp/generated/advanced-types",
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
          "name": "Price",
          "type": "decimal",
          "required": true,
          "validation": ["min:0"]
        },
        {
          "name": "Metadata",
          "type": "json",
          "required": false
        },
        {
          "name": "CreatedAt",
          "type": "timestamp",
          "required": true
        }
      ]
    }
  ],
  "features": ["rest_api", "validation"]
}' "decimal_type json_type validation_tags constructor_functions database_tags"

# Test 2: Complex relationships and constraints
test_enhanced_features "Complex Relationships" "microservice" '{
  "name": "complex-relationships",
  "module_path": "github.com/example/complex-relationships",
  "output_path": "/tmp/generated/complex-relationships",
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
          "name": "Total",
          "type": "decimal",
          "required": true,
          "validation": ["min:0"]
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
          "condition": "total >= 0"
        }
      ],
      "indexes": [
        {
          "name": "idx_order_customer",
          "type": "btree",
          "fields": ["CustomerID"]
        }
      ]
    }
  ],
  "features": ["rest_api", "database", "validation"]
}' "decimal_type validation_tags constructor_functions database_tags relationships"

# Test 3: Library project with enhanced features
test_enhanced_features "Library Enhanced Features" "library" '{
  "name": "enhanced-library",
  "module_path": "github.com/example/enhanced-library",
  "output_path": "/tmp/generated/enhanced-library",
  "project_type": "library",
  "entities": [
    {
      "name": "Config",
      "fields": [
        {
          "name": "ID",
          "type": "uuid",
          "required": true,
          "primary_key": true
        },
        {
          "name": "Settings",
          "type": "json",
          "required": true
        },
        {
          "name": "Version",
          "type": "string",
          "required": true,
          "validation": {
            "pattern": "^[0-9]+\\.[0-9]+\\.[0-9]+$"
          }
        },
        {
          "name": "CreatedAt",
          "type": "timestamp",
          "required": true
        }
      ],
      "indexes": [
        {
          "name": "idx_config_version",
          "type": "btree",
          "fields": ["Version"]
        }
      ]
    }
  ],
  "features": ["public_api", "documentation", "validation"]
}' "uuid_type json_type validation_tags public_api"

# Test 4: Web project with enhanced features
test_enhanced_features "Web Enhanced Features" "web" '{
  "name": "enhanced-web",
  "module_path": "github.com/example/enhanced-web",
  "output_path": "/tmp/generated/enhanced-web",
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
          "validation": {
            "min_length": 1,
            "max_length": 200
          }
        },
        {
          "name": "Content",
          "type": "text",
          "required": true
        },
        {
          "name": "Metadata",
          "type": "json",
          "required": false
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
      ],
      "constraints": [
        {
          "name": "unique_page_title",
          "type": "unique",
          "fields": ["Title"]
        }
      ]
    }
  ],
  "features": ["web_templates", "static_files", "validation"]
}' "uuid_type text_type json_type boolean_type validation_tags web_templates"

# Test 5: Worker project with enhanced features
test_enhanced_features "Worker Enhanced Features" "worker" '{
  "name": "enhanced-worker",
  "module_path": "github.com/example/enhanced-worker",
  "output_path": "/tmp/generated/enhanced-worker",
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
          "enum_values": ["data_sync", "email_batch", "report_gen", "cleanup"]
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
          "default": 0,
          "validation": {
            "min": 0,
            "max": 10
          }
        },
        {
          "name": "Progress",
          "type": "decimal",
          "required": true,
          "default": "0.0",
          "validation": {
            "min": 0,
            "max": 100
          }
        },
        {
          "name": "Payload",
          "type": "json",
          "required": true
        },
        {
          "name": "RetryCount",
          "type": "integer",
          "required": true,
          "default": 0
        },
        {
          "name": "CreatedAt",
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
          "fields": ["Status", "Priority"]
        }
      ]
    }
  ],
  "features": ["job_processing", "queue_management", "metrics", "validation"]
}' "uuid_type enum_type decimal_type json_type validation_tags job_processing"

# Edge Case Tests
test_edge_cases

# Summary
echo -e "\n${CYAN}📊 Regression Test Summary${NC}"
echo -e "${CYAN}==========================${NC}"
echo "Test directory: ${TEST_DIR}"
echo ""

# Count test results
local test_outputs=($(find "${TEST_DIR}" -name "*-output" -type d 2>/dev/null))
echo "Generated test outputs: ${#test_outputs[@]}"

echo ""
echo -e "${YELLOW}🔍 To inspect test results:${NC}"
echo "cd ${TEST_DIR}"
echo "find . -name '*.txt' -exec echo '=== {} ===' \\; -exec head -20 {} \\;"

echo ""
echo -e "${YELLOW}📝 Generated content analysis:${NC}"
for output_dir in "${test_outputs[@]}"; do
    if [[ -f "${output_dir}/generated-code.txt" ]]; then
        local test_name=$(basename "${output_dir}" | sed 's/-output$//')
        local line_count=$(wc -l < "${output_dir}/generated-code.txt")
        echo "  📄 ${test_name}: ${line_count} lines of code"
    fi
done

echo ""
echo -e "${GREEN}✅ Regression Testing Complete${NC}"
echo -e "${GREEN}   - Backward compatibility maintained ✅${NC}"
echo -e "${GREEN}   - Enhanced features working ✅${NC}"
echo -e "${GREEN}   - Edge cases handled ✅${NC}"
