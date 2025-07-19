#!/bin/bash

# Simple Integration Test - Bypass Health Checks
# Test the enhanced orchestrator service directly

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
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEST_DIR="/tmp/simple-integration-test-${TIMESTAMP}"

echo -e "${BLUE}🚀 Simple Integration Test - Enhanced Orchestrator Service v2.0.0${NC}"
echo -e "${BLUE}================================================================${NC}"
echo "Test Directory: ${TEST_DIR}"
echo "Timestamp: ${TIMESTAMP}"
echo ""

# Create test directory
mkdir -p "${TEST_DIR}"

# Test Case: CLI Project with Enhanced Features
echo -e "${YELLOW}🧪 Test Case: CLI Project with Enhanced Features${NC}"

# Create test specification
cat > "${TEST_DIR}/cli-test.json" << 'EOF'
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

echo "Test specification created: ${TEST_DIR}/cli-test.json"

# Step 1: Test orchestrator service
echo -e "\n${BLUE}🔄 Step 1: Testing orchestrator service...${NC}"
orchestrator_response=$(curl -s -X POST "${ORCHESTRATOR_URL}/api/v1/orchestrate/cli" \
    -H "Content-Type: application/json" \
    -d @"${TEST_DIR}/cli-test.json")

if [[ $? -ne 0 ]]; then
    echo -e "${RED}❌ Orchestrator request failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Orchestrator response received${NC}"

# Save orchestrator response
echo "${orchestrator_response}" > "${TEST_DIR}/orchestrator-response.json"

# Step 2: Extract payload and test generator
echo -e "\n${BLUE}🔧 Step 2: Testing generator service...${NC}"
generator_payload=$(echo "${orchestrator_response}" | jq -r '.orchestrated_payload')

if [[ "${generator_payload}" == "null" || -z "${generator_payload}" ]]; then
    echo -e "${RED}❌ No orchestrated payload in response${NC}"
    echo "Response: ${orchestrator_response}"
    exit 1
fi

generator_response=$(echo "${generator_payload}" | curl -s -X POST "${GENERATOR_URL}/api/v1/generate" \
    -H "Content-Type: application/json" \
    -d @-)

if [[ $? -ne 0 ]]; then
    echo -e "${RED}❌ Generator request failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Generator response received${NC}"

# Save generator response
echo "${generator_response}" > "${TEST_DIR}/generator-response.json"

# Step 3: Analyze generated files
echo -e "\n${BLUE}📄 Step 3: Analyzing generated files...${NC}"
files_data=$(echo "${generator_response}" | jq -r '.accumulator.files')

if [[ "${files_data}" == "null" || -z "${files_data}" ]]; then
    echo -e "${RED}❌ No files in generator response${NC}"
    exit 1
fi

file_count=$(echo "${files_data}" | jq '. | length')
echo "Generated files: ${file_count}"

# Write files locally for inspection
output_dir="${TEST_DIR}/generated-code"
mkdir -p "${output_dir}"

echo "${files_data}" | jq -c '.[]' | while read -r file_data; do
    file_path=$(echo "${file_data}" | jq -r '.path')
    file_content=$(echo "${file_data}" | jq -r '.content')
    full_path="${output_dir}/${file_path}"
    
    mkdir -p "$(dirname "${full_path}")"
    echo "${file_content}" > "${full_path}"
    echo "  📄 Created: ${file_path}"
done

# Step 4: Validate enhanced features
echo -e "\n${BLUE}🔍 Step 4: Validating enhanced features...${NC}"

echo "Enhanced features detected:"

# Check for advanced types
if grep -r "json\.RawMessage\|time\.Time" "${output_dir}" > /dev/null 2>&1; then
    echo -e "  ✅ Advanced type mappings (json.RawMessage, time.Time)"
else
    echo -e "  ⚠️  Advanced type mappings not found"
fi

# Check for validation tags
if grep -r 'validate:' "${output_dir}" > /dev/null 2>&1; then
    echo -e "  ✅ Validation tags applied"
    grep -r 'validate:' "${output_dir}" | head -3 | sed 's/^/    /'
else
    echo -e "  ⚠️  Validation tags not found"
fi

# Check for database tags
if grep -r 'db:' "${output_dir}" > /dev/null 2>&1; then
    echo -e "  ✅ Database tags generated"
else
    echo -e "  ⚠️  Database tags not found"
fi

# Check for constructor functions
if grep -r "func New" "${output_dir}" > /dev/null 2>&1; then
    echo -e "  ✅ Constructor functions generated"
else
    echo -e "  ⚠️  Constructor functions not found"
fi

# Step 5: Show sample code
echo -e "\n${BLUE}📋 Step 5: Sample generated code${NC}"
sample_file=$(find "${output_dir}" -name "*.go" | head -1)
if [[ -f "${sample_file}" ]]; then
    echo "Sample from $(basename "${sample_file}"):"
    echo "---"
    head -20 "${sample_file}"
    echo "---"
fi

# Summary
echo -e "\n${GREEN}✅ Simple Integration Test Complete${NC}"
echo "Test directory: ${TEST_DIR}"
echo "Generated files: ${file_count}"
echo ""
echo -e "${YELLOW}🔍 To inspect generated code:${NC}"
echo "cd ${TEST_DIR}/generated-code"
echo "find . -name '*.go' -exec cat {} \\;"
