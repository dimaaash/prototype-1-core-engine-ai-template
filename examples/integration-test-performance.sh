#!/bin/bash

# Integration Test Script - Performance and Scalability Testing
# Tests the enhanced orchestrator service under various load conditions
# Measures performance metrics and validates scalability

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
ORCHESTRATOR_URL="http://localhost:8086"
GENERATOR_URL="http://localhost:8083"
OUTPUT_BASE="/tmp/integration-test-performance"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEST_DIR="${OUTPUT_BASE}-${TIMESTAMP}"

echo -e "${BLUE}⚡ Performance & Scalability Integration Test${NC}"
echo -e "${BLUE}=============================================${NC}"
echo "Test Directory: ${TEST_DIR}"
echo "Timestamp: ${TIMESTAMP}"
echo ""

# Function to measure execution time
measure_time() {
    local start_time=$(date +%s%N)
    "$@"
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
    echo "${duration}"
}

# Function to test orchestrator performance
test_orchestrator_performance() {
    local project_type=$1
    local entity_count=$2
    local field_count=$3
    local description=$4
    
    echo -e "\n${YELLOW}⚡ Performance Test: ${description}${NC}"
    echo "Project Type: ${project_type}"
    echo "Entity Count: ${entity_count}"
    echo "Fields per Entity: ${field_count}"
    
    # Generate test payload
    local test_payload=$(cat << EOF
{
  "name": "perf-test-${entity_count}e-${field_count}f",
  "module_path": "github.com/example/perf-test",
  "output_path": "/tmp/generated/perf-test",
  "project_type": "${project_type}",
  "entities": [
EOF
)
    
    # Add entities dynamically
    for ((i=1; i<=entity_count; i++)); do
        if [[ $i -gt 1 ]]; then
            test_payload+=","
        fi
        
        test_payload+=$(cat << EOF

    {
      "name": "Entity${i}",
      "fields": [
EOF
)
        
        # Add fields dynamically
        for ((j=1; j<=field_count; j++)); do
            if [[ $j -gt 1 ]]; then
                test_payload+=","
            fi
            
            # Vary field types for realistic testing
            local field_type="string"
            case $((j % 6)) in
                0) field_type="uuid" ;;
                1) field_type="string" ;;
                2) field_type="integer" ;;
                3) field_type="decimal" ;;
                4) field_type="timestamp" ;;
                5) field_type="json" ;;
            esac
            
            test_payload+=$(cat << EOF

        {
          "name": "Field${j}",
          "type": "${field_type}",
          "required": $( [[ $((j % 2)) -eq 0 ]] && echo "true" || echo "false" )
EOF
)
            
            # Add validation for some fields
            if [[ $((j % 3)) -eq 0 ]]; then
                test_payload+=',
          "validation": ["min:1", "max:100"]'
            fi
            
            test_payload+="
        }"
        done
        
        test_payload+="]"
        
        # Add relationships for some entities
        if [[ $i -gt 1 && $((i % 2)) -eq 0 ]]; then
            local target_entity=$((i - 1))
            test_payload+=',
      "relationships": [
        {
          "name": "related_entity",
          "type": "many_to_one",
          "target": "Entity'${target_entity}'",
          "foreign_key": "entity'${target_entity}'_id"
        }
      ]'
        fi
        
        # Add constraints and indexes
        test_payload+=',
      "constraints": [
        {
          "name": "unique_field1_entity'${i}'",
          "type": "unique",
          "fields": ["Field1"]
        }
      ],
      "indexes": [
        {
          "name": "idx_entity'${i}'_field1",
          "type": "btree",
          "fields": ["Field1"]
        }
      ]'
        
        test_payload+="
    }"
    done
    
    test_payload+='],'
    
    # Add features
    test_payload+='
  "features": [
    "validation",
    "database",
    "monitoring"
  ]
}'
    
    # Save test payload for debugging
    echo "${test_payload}" > "${TEST_DIR}/perf-test-${entity_count}e-${field_count}f.json"
    
    # Measure orchestrator time
    echo -n "  🔄 Orchestrator processing... "
    local orchestrator_time=$(measure_time curl -s -X POST "${ORCHESTRATOR_URL}/api/v1/orchestrate/${project_type}" \
        -H "Content-Type: application/json" \
        -d "${test_payload}" \
        -o "${TEST_DIR}/orchestrator-response-${entity_count}e-${field_count}f.json")
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}${orchestrator_time}ms${NC}"
    else
        echo -e "${RED}FAILED${NC}"
        return 1
    fi
    
    # Measure generator time
    echo -n "  🔧 Generator processing... "
    local generator_payload=$(jq -r '.orchestrated_payload' "${TEST_DIR}/orchestrator-response-${entity_count}e-${field_count}f.json")
    
    if [[ "${generator_payload}" == "null" || -z "${generator_payload}" ]]; then
        echo -e "${RED}No orchestrated payload${NC}"
        return 1
    fi
    
    local generator_time=$(measure_time sh -c "echo '${generator_payload}' | curl -s -X POST '${GENERATOR_URL}/api/v1/generate' \
        -H 'Content-Type: application/json' \
        -d @- \
        -o '${TEST_DIR}/generator-response-${entity_count}e-${field_count}f.json'")
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}${generator_time}ms${NC}"
    else
        echo -e "${RED}FAILED${NC}"
        return 1
    fi
    
    # Analyze results
    local total_time=$((orchestrator_time + generator_time))
    local generated_files=$(jq '.accumulator.files | length' "${TEST_DIR}/generator-response-${entity_count}e-${field_count}f.json" 2>/dev/null || echo "0")
    
    echo "  📊 Results:"
    echo "    • Total processing time: ${total_time}ms"
    echo "    • Orchestrator time: ${orchestrator_time}ms"
    echo "    • Generator time: ${generator_time}ms"
    echo "    • Generated files: ${generated_files}"
    echo "    • Time per entity: $((total_time / entity_count))ms"
    echo "    • Time per field: $((total_time / (entity_count * field_count)))ms"
    
    # Store results for summary
    echo "${entity_count},${field_count},${total_time},${orchestrator_time},${generator_time},${generated_files}" >> "${TEST_DIR}/performance-results.csv"
    
    return 0
}

# Function to test concurrent requests
test_concurrent_performance() {
    local concurrent_requests=$1
    local project_type=$2
    
    echo -e "\n${MAGENTA}🚀 Concurrent Performance Test${NC}"
    echo "Concurrent Requests: ${concurrent_requests}"
    echo "Project Type: ${project_type}"
    
    # Create simple test payload
    local test_payload='{
  "name": "concurrent-test",
  "module_path": "github.com/example/concurrent-test",
  "output_path": "/tmp/generated/concurrent-test",
  "project_type": "'${project_type}'",
  "entities": [
    {
      "name": "TestEntity",
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
        }
      ]
    }
  ],
  "features": ["validation"]
}'
    
    # Create temporary files for concurrent requests
    local pids=()
    local start_time=$(date +%s%N)
    
    echo "  🔄 Launching ${concurrent_requests} concurrent requests..."
    
    for ((i=1; i<=concurrent_requests; i++)); do
        (
            curl -s -X POST "${ORCHESTRATOR_URL}/api/v1/orchestrate/${project_type}" \
                -H "Content-Type: application/json" \
                -d "${test_payload}" \
                -o "${TEST_DIR}/concurrent-${i}.json" \
                2>/dev/null
            echo $? > "${TEST_DIR}/concurrent-${i}.status"
        ) &
        pids+=($!)
    done
    
    # Wait for all requests to complete
    echo "  ⏳ Waiting for requests to complete..."
    for pid in "${pids[@]}"; do
        wait $pid
    done
    
    local end_time=$(date +%s%N)
    local total_time=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
    
    # Analyze results
    local successful_requests=0
    local failed_requests=0
    
    for ((i=1; i<=concurrent_requests; i++)); do
        local status=$(cat "${TEST_DIR}/concurrent-${i}.status" 2>/dev/null || echo "1")
        if [[ "${status}" == "0" ]]; then
            ((successful_requests++))
        else
            ((failed_requests++))
        fi
    done
    
    echo "  📊 Concurrent Test Results:"
    echo "    • Total time: ${total_time}ms"
    echo "    • Average time per request: $((total_time / concurrent_requests))ms"
    echo "    • Successful requests: ${successful_requests}/${concurrent_requests}"
    echo "    • Failed requests: ${failed_requests}/${concurrent_requests}"
    echo "    • Success rate: $(( (successful_requests * 100) / concurrent_requests ))%"
    
    # Store concurrent results
    echo "${concurrent_requests},${total_time},${successful_requests},${failed_requests}" >> "${TEST_DIR}/concurrent-results.csv"
    
    return 0
}

# Check service health
echo -e "${BLUE}🔍 Checking service health...${NC}"
# Use same health check logic as manage.sh - check for any HTTP response
if ! curl -s -o /dev/null -w "%{http_code}" "${ORCHESTRATOR_URL}" 2>/dev/null | grep -q "200\|404\|405"; then
    echo -e "${RED}❌ Orchestrator service not responding${NC}"
    exit 1
fi

if ! curl -s -o /dev/null -w "%{http_code}" "${GENERATOR_URL}" 2>/dev/null | grep -q "200\|404\|405"; then
    echo -e "${RED}❌ Generator service not responding${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All services running${NC}"

# Create test directory
mkdir -p "${TEST_DIR}"

# Initialize results files
echo "entities,fields,total_time_ms,orchestrator_time_ms,generator_time_ms,generated_files" > "${TEST_DIR}/performance-results.csv"
echo "concurrent_requests,total_time_ms,successful_requests,failed_requests" > "${TEST_DIR}/concurrent-results.csv"

# Performance Tests - Scale by entity count
echo -e "\n${BLUE}📈 Scalability Tests - Entity Count${NC}"
test_orchestrator_performance "microservice" 1 5 "Small project (1 entity, 5 fields)"
test_orchestrator_performance "microservice" 3 5 "Medium project (3 entities, 5 fields)"
test_orchestrator_performance "microservice" 5 5 "Large project (5 entities, 5 fields)"
test_orchestrator_performance "microservice" 10 5 "Extra large project (10 entities, 5 fields)"

# Performance Tests - Scale by field count
echo -e "\n${BLUE}📈 Scalability Tests - Field Count${NC}"
test_orchestrator_performance "api" 2 5 "Standard fields (2 entities, 5 fields)"
test_orchestrator_performance "api" 2 10 "Many fields (2 entities, 10 fields)"
test_orchestrator_performance "api" 2 20 "Complex entities (2 entities, 20 fields)"

# Performance Tests - Different project types
echo -e "\n${BLUE}📈 Project Type Performance Comparison${NC}"
test_orchestrator_performance "cli" 2 5 "CLI project (2 entities, 5 fields)"
test_orchestrator_performance "library" 2 5 "Library project (2 entities, 5 fields)"
test_orchestrator_performance "web" 2 5 "Web project (2 entities, 5 fields)"
test_orchestrator_performance "worker" 2 5 "Worker project (2 entities, 5 fields)"

# Concurrent Performance Tests
echo -e "\n${BLUE}🚀 Concurrent Performance Tests${NC}"
test_concurrent_performance 2 "microservice"
test_concurrent_performance 5 "microservice"
test_concurrent_performance 10 "microservice"

# Generate performance report
echo -e "\n${BLUE}📊 Performance Analysis${NC}"
echo -e "${BLUE}=====================${NC}"

echo -e "\n${YELLOW}🔍 Performance Trends:${NC}"
echo "Entity Count vs Performance:"
awk -F',' 'NR>1 {print "  " $1 " entities: " $3 "ms (" $3/$1 "ms/entity)"}' "${TEST_DIR}/performance-results.csv"

echo -e "\n${YELLOW}🔍 Concurrent Performance:${NC}"
awk -F',' 'NR>1 {print "  " $1 " concurrent: " $2 "ms (success rate: " int(($3*100)/($3+$4)) "%)"}' "${TEST_DIR}/concurrent-results.csv"

echo -e "\n${YELLOW}📁 Test Results Location:${NC}"
echo "Performance data: ${TEST_DIR}/performance-results.csv"
echo "Concurrent data: ${TEST_DIR}/concurrent-results.csv"
echo "Test payloads: ${TEST_DIR}/perf-test-*.json"

echo ""
echo -e "${YELLOW}📈 To analyze results:${NC}"
echo "cd ${TEST_DIR}"
echo "cat performance-results.csv"
echo "cat concurrent-results.csv"

echo ""
echo -e "${GREEN}✅ Performance & Scalability Integration Test Complete${NC}"
