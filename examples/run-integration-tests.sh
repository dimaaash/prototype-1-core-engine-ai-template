#!/bin/bash

# Master Integration Test Runner
# Runs all integration test suites for the Enhanced Orchestrator Service v2.0.0
# Provides options to run individual test suites or comprehensive testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_BASE="/tmp/integration-test-master"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEST_DIR="${OUTPUT_BASE}-${TIMESTAMP}"

echo -e "${CYAN}🚀 Master Integration Test Runner - Enhanced Orchestrator Service v2.0.0${NC}"
echo -e "${CYAN}==================================================================${NC}"
echo "Test Directory: ${TEST_DIR}"
echo "Script Directory: ${SCRIPT_DIR}"
echo "Timestamp: ${TIMESTAMP}"
echo ""

# Function to show usage
show_usage() {
    echo -e "${YELLOW}Usage: $0 [OPTIONS]${NC}"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  -h, --help              Show this help message"
    echo "  -a, --all               Run all integration test suites (default)"
    echo "  -o, --orchestrator      Run enhanced orchestrator v2.0 tests only"
    echo "  -f, --full-pipeline     Run full pipeline integration tests only"
    echo "  -p, --performance       Run performance and scalability tests only"
    echo "  -r, --regression        Run regression testing only"
    echo "  -R, --reproduction      Run July 19th test reproduction only"
    echo "  -q, --quick             Run quick validation (orchestrator + reproduction)"
    echo "  -c, --check-services    Check service health only"
    echo "  --list                  List available test suites"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0                      # Run all tests"
    echo "  $0 --quick              # Quick validation"
    echo "  $0 --orchestrator       # Test orchestrator v2.0 only"
    echo "  $0 --performance        # Performance tests only"
    echo ""
}

# Function to list available test suites
list_test_suites() {
    echo -e "${BLUE}Available Integration Test Suites:${NC}"
    echo ""
    echo -e "${GREEN}1. Enhanced Orchestrator v2.0 Tests${NC}"
    echo "   File: integration-test-orchestrator-v2.sh"
    echo "   Focus: Enhanced entity features, advanced type mappings, validation"
    echo ""
    echo -e "${GREEN}2. Full Pipeline Integration Tests${NC}"
    echo "   File: integration-test-full-pipeline.sh"
    echo "   Focus: End-to-end testing with compilation validation"
    echo ""
    echo -e "${GREEN}3. Performance & Scalability Tests${NC}"
    echo "   File: integration-test-performance.sh"
    echo "   Focus: Load testing, concurrent requests, performance metrics"
    echo ""
    echo -e "${GREEN}4. Regression Testing${NC}"
    echo "   File: integration-test-regression.sh"
    echo "   Focus: Backward compatibility, edge cases, enhanced features"
    echo ""
    echo -e "${GREEN}5. July 19th Test Reproduction${NC}"
    echo "   File: integration-test-reproduction.sh"
    echo "   Focus: Exact reproduction of documented integration testing"
    echo ""
}

# Function to check if all required scripts exist
check_test_scripts() {
    local scripts=(
        "integration-test-orchestrator-v2.sh"
        "integration-test-full-pipeline.sh"
        "integration-test-performance.sh"
        "integration-test-regression.sh"
        "integration-test-reproduction.sh"
    )
    
    local missing_scripts=()
    
    for script in "${scripts[@]}"; do
        if [[ ! -f "${SCRIPT_DIR}/${script}" ]]; then
            missing_scripts+=("${script}")
        fi
    done
    
    if [[ ${#missing_scripts[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Missing test scripts:${NC}"
        for script in "${missing_scripts[@]}"; do
            echo "  - ${script}"
        done
        echo ""
        echo "Please ensure all integration test scripts are present in ${SCRIPT_DIR}/"
        return 1
    fi
    
    echo -e "${GREEN}✅ All test scripts found${NC}"
    return 0
}

# Function to make scripts executable
make_scripts_executable() {
    local scripts=(
        "integration-test-orchestrator-v2.sh"
        "integration-test-full-pipeline.sh"
        "integration-test-performance.sh"
        "integration-test-regression.sh"
        "integration-test-reproduction.sh"
    )
    
    echo -e "${BLUE}🔧 Making test scripts executable...${NC}"
    
    for script in "${scripts[@]}"; do
        if [[ -f "${SCRIPT_DIR}/${script}" ]]; then
            chmod +x "${SCRIPT_DIR}/${script}"
            echo "  ✅ ${script}"
        fi
    done
}

# Function to check service health (using same logic as manage.sh)
check_services() {
    echo -e "${BLUE}🔍 Checking service health...${NC}"
    
    local services=(
        "Orchestrator Service v2.0.0:http://localhost:8086"
        "Template Service:http://localhost:8082"
        "Generator Service:http://localhost:8083"
        "Compiler Builder Service:http://localhost:8084"
        "Project Structure Service:http://localhost:8085"
    )
    
    local healthy_services=0
    local total_services=${#services[@]}
    
    for service_info in "${services[@]}"; do
        local service_name=$(echo "${service_info}" | cut -d: -f1)
        local service_url=$(echo "${service_info}" | cut -d: -f2-)
        
        echo -n "  ${service_name}..."
        # Use same health check logic as manage.sh - check for any HTTP response
        if curl -s -o /dev/null -w "%{http_code}" "${service_url}" 2>/dev/null | grep -q "200\|404\|405"; then
            echo -e " ${GREEN}✅ Running${NC}"
            ((healthy_services++))
        else
            echo -e " ${RED}❌ Not responding${NC}"
        fi
    done
    
    echo ""
    echo "Service Health: ${healthy_services}/${total_services} services running"
    
    if [[ ${healthy_services} -eq ${total_services} ]]; then
        echo -e "${GREEN}✅ All services operational - ready for testing${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Some services are not running${NC}"
        echo -e "${YELLOW}Please start missing services before running integration tests${NC}"
        echo ""
        echo -e "${YELLOW}To start all services:${NC}"
        echo "make build-all"
        echo "make run-all"
        return 1
    fi
}

# Function to run a test suite
run_test_suite() {
    local suite_name=$1
    local script_name=$2
    local description=$3
    
    echo -e "\n${MAGENTA}🧪 Running ${suite_name}${NC}"
    echo -e "${MAGENTA}$(printf '=%.0s' {1..80})${NC}"
    echo "${description}"
    echo ""
    
    if [[ ! -f "${SCRIPT_DIR}/${script_name}" ]]; then
        echo -e "${RED}❌ Script not found: ${script_name}${NC}"
        return 1
    fi
    
    local start_time=$(date +%s)
    
    if bash "${SCRIPT_DIR}/${script_name}"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo -e "\n${GREEN}✅ ${suite_name} completed successfully (${duration}s)${NC}"
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo -e "\n${RED}❌ ${suite_name} failed (${duration}s)${NC}"
        return 1
    fi
}

# Function to run all test suites
run_all_tests() {
    echo -e "${CYAN}🚀 Running All Integration Test Suites${NC}"
    echo -e "${CYAN}=====================================${NC}"
    
    local start_time=$(date +%s)
    local successful_tests=0
    local failed_tests=0
    local test_results=()
    
    # Test Suite 1: Enhanced Orchestrator v2.0
    if run_test_suite "Enhanced Orchestrator v2.0 Tests" "integration-test-orchestrator-v2.sh" "Testing enhanced entity features and advanced type mappings"; then
        ((successful_tests++))
        test_results+=("✅ Enhanced Orchestrator v2.0 Tests")
    else
        ((failed_tests++))
        test_results+=("❌ Enhanced Orchestrator v2.0 Tests")
    fi
    
    # Test Suite 2: Full Pipeline Integration
    if run_test_suite "Full Pipeline Integration Tests" "integration-test-full-pipeline.sh" "End-to-end testing with project structure and compilation"; then
        ((successful_tests++))
        test_results+=("✅ Full Pipeline Integration Tests")
    else
        ((failed_tests++))
        test_results+=("❌ Full Pipeline Integration Tests")
    fi
    
    # Test Suite 3: Performance & Scalability
    if run_test_suite "Performance & Scalability Tests" "integration-test-performance.sh" "Load testing and performance metrics collection"; then
        ((successful_tests++))
        test_results+=("✅ Performance & Scalability Tests")
    else
        ((failed_tests++))
        test_results+=("❌ Performance & Scalability Tests")
    fi
    
    # Test Suite 4: Regression Testing
    if run_test_suite "Regression Testing" "integration-test-regression.sh" "Backward compatibility and edge case validation"; then
        ((successful_tests++))
        test_results+=("✅ Regression Testing")
    else
        ((failed_tests++))
        test_results+=("❌ Regression Testing")
    fi
    
    # Test Suite 5: July 19th Reproduction
    if run_test_suite "July 19th Test Reproduction" "integration-test-reproduction.sh" "Exact reproduction of documented integration testing"; then
        ((successful_tests++))
        test_results+=("✅ July 19th Test Reproduction")
    else
        ((failed_tests++))
        test_results+=("❌ July 19th Test Reproduction")
    fi
    
    # Final summary
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    local total_tests=$((successful_tests + failed_tests))
    
    echo -e "\n${CYAN}📊 Master Integration Test Summary${NC}"
    echo -e "${CYAN}==================================${NC}"
    echo "Total Duration: ${total_duration} seconds"
    echo "Total Test Suites: ${total_tests}"
    echo -e "Successful: ${GREEN}${successful_tests}${NC}"
    echo -e "Failed: ${RED}${failed_tests}${NC}"
    
    if [[ ${total_tests} -gt 0 ]]; then
        local success_rate=$(( (successful_tests * 100) / total_tests ))
        echo "Success Rate: ${success_rate}%"
    fi
    
    echo ""
    echo -e "${YELLOW}📋 Detailed Results:${NC}"
    for result in "${test_results[@]}"; do
        echo "  ${result}"
    done
    
    echo ""
    if [[ ${failed_tests} -eq 0 ]]; then
        echo -e "${GREEN}🎉 All integration test suites passed successfully!${NC}"
        echo -e "${GREEN}   Enhanced Orchestrator Service v2.0.0 is fully validated ✅${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Some test suites failed - please review the output above${NC}"
        return 1
    fi
}

# Function to run quick validation
run_quick_tests() {
    echo -e "${CYAN}⚡ Quick Integration Validation${NC}"
    echo -e "${CYAN}==============================${NC}"
    echo "Running essential tests for rapid validation"
    
    local start_time=$(date +%s)
    local successful_tests=0
    local failed_tests=0
    
    # Quick Test 1: Enhanced Orchestrator
    if run_test_suite "Enhanced Orchestrator v2.0 Tests" "integration-test-orchestrator-v2.sh" "Core enhanced features validation"; then
        ((successful_tests++))
    else
        ((failed_tests++))
    fi
    
    # Quick Test 2: July 19th Reproduction
    if run_test_suite "July 19th Test Reproduction" "integration-test-reproduction.sh" "Validated integration patterns"; then
        ((successful_tests++))
    else
        ((failed_tests++))
    fi
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    echo -e "\n${CYAN}⚡ Quick Validation Summary${NC}"
    echo -e "${CYAN}===========================${NC}"
    echo "Duration: ${total_duration} seconds"
    echo -e "Successful: ${GREEN}${successful_tests}${NC}"
    echo -e "Failed: ${RED}${failed_tests}${NC}"
    
    if [[ ${failed_tests} -eq 0 ]]; then
        echo -e "\n${GREEN}✅ Quick validation passed - system is operational${NC}"
        return 0
    else
        echo -e "\n${RED}❌ Quick validation failed - please check service status${NC}"
        return 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -a|--all)
            TEST_MODE="all"
            shift
            ;;
        -o|--orchestrator)
            TEST_MODE="orchestrator"
            shift
            ;;
        -f|--full-pipeline)
            TEST_MODE="full-pipeline"
            shift
            ;;
        -p|--performance)
            TEST_MODE="performance"
            shift
            ;;
        -r|--regression)
            TEST_MODE="regression"
            shift
            ;;
        -R|--reproduction)
            TEST_MODE="reproduction"
            shift
            ;;
        -q|--quick)
            TEST_MODE="quick"
            shift
            ;;
        -c|--check-services)
            TEST_MODE="check-services"
            shift
            ;;
        --list)
            list_test_suites
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Default to all tests if no mode specified
if [[ -z "${TEST_MODE}" ]]; then
    TEST_MODE="all"
fi

# Create test directory
mkdir -p "${TEST_DIR}"

# Check test scripts
if ! check_test_scripts; then
    exit 1
fi

# Make scripts executable
make_scripts_executable

# Execute based on mode
case "${TEST_MODE}" in
    "check-services")
        check_services
        exit $?
        ;;
    "all")
        if check_services; then
            run_all_tests
        else
            exit 1
        fi
        ;;
    "quick")
        if check_services; then
            run_quick_tests
        else
            exit 1
        fi
        ;;
    "orchestrator")
        if check_services; then
            run_test_suite "Enhanced Orchestrator v2.0 Tests" "integration-test-orchestrator-v2.sh" "Testing enhanced entity features and advanced type mappings"
        else
            exit 1
        fi
        ;;
    "full-pipeline")
        if check_services; then
            run_test_suite "Full Pipeline Integration Tests" "integration-test-full-pipeline.sh" "End-to-end testing with project structure and compilation"
        else
            exit 1
        fi
        ;;
    "performance")
        if check_services; then
            run_test_suite "Performance & Scalability Tests" "integration-test-performance.sh" "Load testing and performance metrics collection"
        else
            exit 1
        fi
        ;;
    "regression")
        if check_services; then
            run_test_suite "Regression Testing" "integration-test-regression.sh" "Backward compatibility and edge case validation"
        else
            exit 1
        fi
        ;;
    "reproduction")
        if check_services; then
            run_test_suite "July 19th Test Reproduction" "integration-test-reproduction.sh" "Exact reproduction of documented integration testing"
        else
            exit 1
        fi
        ;;
    *)
        echo -e "${RED}❌ Invalid test mode: ${TEST_MODE}${NC}"
        show_usage
        exit 1
        ;;
esac
