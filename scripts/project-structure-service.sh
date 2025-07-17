#!/bin/bash

# Project Structure Service Management Script
# Manages the project structure microservice

SERVICE_NAME="project-structure-service"
SERVICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../services/project-structure-service" && pwd)"
PID_FILE="$SERVICE_DIR/$SERVICE_NAME.pid"
LOG_FILE="$SERVICE_DIR/logs/$SERVICE_NAME.log"
BINARY_PATH="$SERVICE_DIR/bin/$SERVICE_NAME"
PORT=8085

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure logs directory exists
mkdir -p "$SERVICE_DIR/logs"
mkdir -p "$SERVICE_DIR/bin"

# Function to print colored output
print_status() {
    echo -e "${BLUE}📊 Status of $SERVICE_NAME...${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if service is running
is_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        else
            # PID file exists but process is dead, clean up
            rm -f "$PID_FILE"
            return 1
        fi
    fi
    return 1
}

# Function to install dependencies
deps() {
    echo "📦 Installing dependencies for $SERVICE_NAME..."
    cd "$SERVICE_DIR"
    go mod tidy
    go mod download
    print_success "Dependencies installed"
}

# Function to build the service
build() {
    echo "🔨 Building $SERVICE_NAME..."
    cd "$SERVICE_DIR"
    
    # Ensure dependencies are installed
    go mod tidy
    
    # Build the service
    if go build -o "$BINARY_PATH" cmd/main.go; then
        print_success "$SERVICE_NAME built successfully"
        return 0
    else
        print_error "Failed to build $SERVICE_NAME"
        return 1
    fi
}

# Function to run the service in foreground
run() {
    echo "🚀 Running $SERVICE_NAME in foreground..."
    cd "$SERVICE_DIR"
    
    if ! build; then
        return 1
    fi
    
    exec "$BINARY_PATH"
}

# Function to start the service in background
start() {
    if is_running; then
        local pid=$(cat "$PID_FILE")
        print_warning "$SERVICE_NAME is already running (PID: $pid)"
        return 0
    fi
    
    echo "🚀 Starting $SERVICE_NAME in background on port $PORT..."
    cd "$SERVICE_DIR"
    
    if ! build; then
        return 1
    fi
    
    # Start service in background
    nohup "$BINARY_PATH" > "$LOG_FILE" 2>&1 &
    local pid=$!
    echo $pid > "$PID_FILE"
    
    # Wait a moment and check if it's still running
    sleep 2
    if is_running; then
        print_success "Started $SERVICE_NAME (PID: $pid)"
        echo -e "${BLUE}🌐 Service available at: http://localhost:$PORT${NC}"
        return 0
    else
        print_error "Failed to start $SERVICE_NAME"
        rm -f "$PID_FILE"
        return 1
    fi
}

# Function to stop the service
stop() {
    if ! is_running; then
        print_warning "$SERVICE_NAME is not running"
        return 0
    fi
    
    local pid=$(cat "$PID_FILE")
    echo "🛑 Stopping $SERVICE_NAME (PID: $pid)..."
    
    # Try graceful shutdown first
    if kill "$pid" 2>/dev/null; then
        # Wait for graceful shutdown
        local count=0
        while [ $count -lt 10 ]; do
            if ! ps -p "$pid" > /dev/null 2>&1; then
                break
            fi
            sleep 1
            count=$((count + 1))
        done
        
        # Force kill if still running
        if ps -p "$pid" > /dev/null 2>&1; then
            kill -9 "$pid" 2>/dev/null
            print_warning "Force killed $SERVICE_NAME"
        else
            print_success "Stopped $SERVICE_NAME"
        fi
    else
        print_warning "$SERVICE_NAME process not found"
    fi
    
    rm -f "$PID_FILE"
}

# Function to restart the service
restart() {
    stop
    sleep 1
    start
}

# Function to show service status
status() {
    print_status
    if is_running; then
        local pid=$(cat "$PID_FILE")
        print_success "$SERVICE_NAME is running (PID: $pid)"
        echo -e "${BLUE}🌐 Health check: http://localhost:$PORT/health${NC}"
        
        # Try to get memory usage
        if command -v ps >/dev/null 2>&1; then
            local mem_usage=$(ps -o rss= -p "$pid" 2>/dev/null | awk '{print $1/1024 " MB"}')
            if [ -n "$mem_usage" ]; then
                echo -e "${BLUE}💾 Memory usage: $mem_usage${NC}"
            fi
        fi
    else
        print_warning "$SERVICE_NAME is not running"
    fi
}

# Function to test the service
test() {
    echo "🧪 Testing $SERVICE_NAME..."
    cd "$SERVICE_DIR"
    
    if go test ./...; then
        print_success "All tests passed"
    else
        print_error "Some tests failed"
        return 1
    fi
}

# Function to show logs
logs() {
    if [ -f "$LOG_FILE" ]; then
        echo "📋 Showing logs for $SERVICE_NAME..."
        tail -f "$LOG_FILE"
    else
        print_warning "No log file found at $LOG_FILE"
    fi
}

# Function to clean build artifacts
clean() {
    echo "🧹 Cleaning $SERVICE_NAME..."
    cd "$SERVICE_DIR"
    rm -rf bin/
    rm -f "$PID_FILE"
    print_success "Cleaned $SERVICE_NAME"
}

# Function to show service health
health() {
    if is_running; then
        echo "🏥 Checking health of $SERVICE_NAME..."
        if command -v curl >/dev/null 2>&1; then
            curl -s "http://localhost:$PORT/health" | grep -q "healthy" && \
                print_success "Service is healthy" || \
                print_error "Service health check failed"
        else
            print_warning "curl not available for health check"
        fi
    else
        print_error "$SERVICE_NAME is not running"
    fi
}

# Main script logic
case "${1:-}" in
    deps)
        deps
        ;;
    build)
        build
        ;;
    run)
        run
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    test)
        test
        ;;
    logs)
        logs
        ;;
    clean)
        clean
        ;;
    health)
        health
        ;;
    *)
        echo "Usage: $0 {deps|build|run|start|stop|restart|status|test|logs|clean|health}"
        echo ""
        echo "Commands:"
        echo "  deps     - Install Go dependencies"
        echo "  build    - Build the service binary"
        echo "  run      - Run service in foreground"
        echo "  start    - Start service in background"
        echo "  stop     - Stop the running service"
        echo "  restart  - Restart the service"
        echo "  status   - Show service status"
        echo "  test     - Run tests"
        echo "  logs     - Show service logs"
        echo "  clean    - Clean build artifacts"
        echo "  health   - Check service health"
        echo ""
        echo "Examples:"
        echo "  $0 start"
        echo "  $0 status"
        echo "  $0 logs"
        exit 1
        ;;
esac
