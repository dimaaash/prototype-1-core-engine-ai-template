#!/bin/bash

# Go Factory Platform - Master Service Manager
# This script provides a unified interface to manage all services

set -e

SERVICES=("building-blocks-service" "template-service" "generator-service" "compiler-builder-service")
PORTS=("8081" "8082" "8083" "8084")
SCRIPT_DIR="scripts"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

show_banner() {
    echo -e "${BLUE}"
    echo "🏭 ================================================="
    echo "   Go Factory Platform - Service Manager"
    echo "   Microservices Code Generation Platform"
    echo "=================================================${NC}"
    echo ""
}

show_help() {
    show_banner
    echo -e "${YELLOW}Usage: $0 <command> [service-name]${NC}"
    echo ""
    echo -e "${YELLOW}Global Commands:${NC}"
    echo "  start-all     - Start all services in dependency order"
    echo "  stop-all      - Stop all running services"
    echo "  restart-all   - Restart all services"
    echo "  status-all    - Show status of all services"
    echo "  build-all     - Build all services"
    echo "  deps-all      - Install dependencies for all services"
    echo "  test-all      - Run tests for all services"
    echo "  clean-all     - Clean all services"
    echo "  logs-all      - Show logs from all services"
    echo "  health-all    - Health check for all services"
    echo ""
    echo -e "${YELLOW}Individual Service Commands:${NC}"
    echo "  start <service>   - Start specific service"
    echo "  stop <service>    - Stop specific service"
    echo "  status <service>  - Show service status"
    echo "  logs <service>    - Show service logs"
    echo "  build <service>   - Build specific service"
    echo "  test <service>    - Test specific service"
    echo ""
    echo -e "${YELLOW}Available Services:${NC}"
    for i in "${!SERVICES[@]}"; do
        echo "  - ${SERVICES[$i]} (port ${PORTS[$i]})"
    done
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 start-all"
    echo "  $0 start generator-service"
    echo "  $0 status-all"
    echo "  $0 logs template-service"
    echo ""
}

check_service_exists() {
    local service=$1
    for s in "${SERVICES[@]}"; do
        if [[ "$s" == "$service" ]]; then
            return 0
        fi
    done
    return 1
}

execute_service_command() {
    local service=$1
    local command=$2
    
    if [[ ! -f "$SCRIPT_DIR/$service.sh" ]]; then
        echo -e "${RED}❌ Script not found: $SCRIPT_DIR/$service.sh${NC}"
        return 1
    fi
    
    ./"$SCRIPT_DIR/$service.sh" "$command"
}

start_all_services() {
    echo -e "${GREEN}🚀 Starting all services in dependency order...${NC}"
    echo ""
    
    for i in "${!SERVICES[@]}"; do
        local service="${SERVICES[$i]}"
        local port="${PORTS[$i]}"
        
        echo -e "${YELLOW}Starting $service on port $port...${NC}"
        execute_service_command "$service" "start"
        
        # Wait a bit between services to ensure proper startup
        if [[ $i -lt $((${#SERVICES[@]} - 1)) ]]; then
            echo "⏳ Waiting for service to initialize..."
            sleep 3
        fi
        echo ""
    done
    
    echo -e "${GREEN}✅ All services started!${NC}"
    echo ""
    echo -e "${YELLOW}Service Endpoints:${NC}"
    for i in "${!SERVICES[@]}"; do
        local service="${SERVICES[$i]}"
        local port="${PORTS[$i]}"
        echo "  - $service: http://localhost:$port"
    done
    echo ""
    
    # Show status after startup
    sleep 2
    status_all_services
}

stop_all_services() {
    echo -e "${GREEN}🛑 Stopping all services...${NC}"
    echo ""
    
    # Stop in reverse order
    for ((i=${#SERVICES[@]}-1; i>=0; i--)); do
        local service="${SERVICES[$i]}"
        echo -e "${YELLOW}Stopping $service...${NC}"
        execute_service_command "$service" "stop"
    done
    
    echo -e "${GREEN}✅ All services stopped!${NC}"
}

status_all_services() {
    echo -e "${GREEN}📊 Service Status Overview:${NC}"
    echo "================================="
    echo ""
    
    for i in "${!SERVICES[@]}"; do
        local service="${SERVICES[$i]}"
        local port="${PORTS[$i]}"
        
        echo -e "${YELLOW}$service (port $port):${NC}"
        execute_service_command "$service" "status"
        echo ""
    done
}

health_check_all() {
    echo -e "${GREEN}🏥 Health Check for All Services:${NC}"
    echo "===================================="
    echo ""
    
    for i in "${!SERVICES[@]}"; do
        local service="${SERVICES[$i]}"
        local port="${PORTS[$i]}"
        
        echo -n -e "${YELLOW}$service (port $port): ${NC}"
        
        # Try to connect to the service
        if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port" 2>/dev/null | grep -q "200\|404\|405"; then
            echo -e "${GREEN}✅ Responsive${NC}"
        else
            echo -e "${RED}❌ Not responding${NC}"
        fi
    done
    echo ""
}

logs_all_services() {
    echo -e "${GREEN}📋 Recent logs from all services:${NC}"
    echo "====================================="
    echo ""
    
    for service in "${SERVICES[@]}"; do
        echo -e "${YELLOW}=== $service logs ===${NC}"
        if [[ -f "services/$service/logs/$service.log" ]]; then
            tail -10 "services/$service/logs/$service.log"
        else
            echo "No logs found"
        fi
        echo ""
    done
}

# Main command processing
case "$1" in
    "start-all")
        start_all_services
        ;;
    "stop-all")
        stop_all_services
        ;;
    "restart-all")
        stop_all_services
        sleep 2
        start_all_services
        ;;
    "status-all")
        status_all_services
        ;;
    "build-all")
        echo -e "${GREEN}🔨 Building all services...${NC}"
        for service in "${SERVICES[@]}"; do
            echo -e "${YELLOW}Building $service...${NC}"
            execute_service_command "$service" "build"
        done
        echo -e "${GREEN}✅ All services built!${NC}"
        ;;
    "deps-all")
        echo -e "${GREEN}📦 Installing dependencies for all services...${NC}"
        for service in "${SERVICES[@]}"; do
            echo -e "${YELLOW}Installing dependencies for $service...${NC}"
            execute_service_command "$service" "deps"
        done
        echo -e "${GREEN}✅ All dependencies installed!${NC}"
        ;;
    "test-all")
        echo -e "${GREEN}🧪 Running tests for all services...${NC}"
        for service in "${SERVICES[@]}"; do
            echo -e "${YELLOW}Testing $service...${NC}"
            execute_service_command "$service" "test"
        done
        echo -e "${GREEN}✅ All tests completed!${NC}"
        ;;
    "clean-all")
        echo -e "${GREEN}🧹 Cleaning all services...${NC}"
        for service in "${SERVICES[@]}"; do
            echo -e "${YELLOW}Cleaning $service...${NC}"
            execute_service_command "$service" "clean"
        done
        echo -e "${GREEN}✅ All services cleaned!${NC}"
        ;;
    "logs-all")
        logs_all_services
        ;;
    "health-all")
        health_check_all
        ;;
    "start"|"stop"|"status"|"logs"|"build"|"test"|"clean")
        if [[ -z "$2" ]]; then
            echo -e "${RED}❌ Service name required for command '$1'${NC}"
            echo -e "${YELLOW}Usage: $0 $1 <service-name>${NC}"
            exit 1
        fi
        
        if ! check_service_exists "$2"; then
            echo -e "${RED}❌ Unknown service: $2${NC}"
            echo -e "${YELLOW}Available services: ${SERVICES[*]}${NC}"
            exit 1
        fi
        
        execute_service_command "$2" "$1"
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    "")
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
