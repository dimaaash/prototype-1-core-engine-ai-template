#!/bin/bash

#!/bin/bash

# Generator Service Management Script  
# Implements Visitor pattern for code generation

set -e

SERVICE_NAME="generator-service"
SERVICE_PORT="8083"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_DIR="$(dirname "$SCRIPT_DIR")/services/$SERVICE_NAME"
PID_FILE="$SERVICE_DIR/$SERVICE_NAME.pid"
LOG_FILE="$SERVICE_DIR/logs/$SERVICE_NAME.log"

cd "$(dirname "$0")"

case "$1" in
    "deps")
        echo "📦 Installing dependencies for $SERVICE_NAME..."
        cd $SERVICE_DIR
        go mod tidy
        go mod download
        ;;
    "build")
        echo "🔨 Building $SERVICE_NAME..."
        cd $SERVICE_DIR
        go build -o bin/$SERVICE_NAME cmd/main.go
        echo "✅ Built successfully: bin/$SERVICE_NAME"
        ;;
    "run")
        echo "🚀 Starting $SERVICE_NAME on port $SERVICE_PORT..."
        cd $SERVICE_DIR
        go run cmd/main.go
        ;;
    "start")
        echo "🚀 Starting $SERVICE_NAME in background on port $SERVICE_PORT..."
        
        # Check if service is already running
        if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo "⚠️  $SERVICE_NAME is already running (PID: $(cat "$PID_FILE"))"
            echo "🌐 Health check: http://localhost:$SERVICE_PORT/health"
            exit 0
        fi
        
        # Check if port is already in use by another process
        if lsof -Pi :$SERVICE_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo "❌ Port $SERVICE_PORT is already in use by another process"
            echo "🔍 Processes using port $SERVICE_PORT:"
            lsof -Pi :$SERVICE_PORT -sTCP:LISTEN
            exit 1
        fi
        
        # Clean up stale PID file if it exists
        if [ -f "$PID_FILE" ]; then
            echo "🧹 Cleaning up stale PID file..."
            rm -f "$PID_FILE"
        fi
        
        cd $SERVICE_DIR
        
        # Ensure logs directory exists
        mkdir -p logs
        
        # Start the service
        nohup go run cmd/main.go > logs/$SERVICE_NAME.log 2>&1 &
        echo $! > "$PID_FILE"
        
        # Verify it started successfully
        sleep 2
        if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo "✅ Started $SERVICE_NAME (PID: $(cat "$PID_FILE"))"
            echo "🌐 Service available at: http://localhost:$SERVICE_PORT"
        else
            echo "❌ Failed to start $SERVICE_NAME"
            rm -f "$PID_FILE"
            exit 1
        fi
        ;;
    "stop")
        echo "🛑 Stopping $SERVICE_NAME..."
        if [ -f "$PID_FILE" ]; then
            kill $(cat "$PID_FILE") 2>/dev/null || true
            rm -f "$PID_FILE"
            echo "✅ Stopped $SERVICE_NAME"
        else
            echo "⚠️  PID file not found, service may not be running"
        fi
        ;;
    "test")
        echo "🧪 Running tests for $SERVICE_NAME..."
        cd $SERVICE_DIR
        go test ./...
        ;;
    "clean")
        echo "🧹 Cleaning $SERVICE_NAME..."
        cd $SERVICE_DIR
        rm -rf bin/
        rm -f "$PID_FILE"
        rm -f "$LOG_FILE"
        go clean
        ;;
    "status")
        echo "📊 Status of $SERVICE_NAME..."
        if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo "✅ $SERVICE_NAME is running (PID: $(cat "$PID_FILE"))"
            echo "🌐 Health check: http://localhost:$SERVICE_PORT/health"
        else
            echo "❌ $SERVICE_NAME is not running"
        fi
        ;;
    "logs")
        echo "📋 Logs for $SERVICE_NAME..."
        if [ -f "$LOG_FILE" ]; then
            tail -f "$LOG_FILE"
        else
            echo "No log file found"
        fi
        ;;
    *)
        echo "Usage: $0 {deps|build|run|start|stop|test|clean|status|logs}"
        echo ""
        echo "Commands:"
        echo "  deps   - Install Go dependencies"
        echo "  build  - Build the service binary"
        echo "  run    - Run the service in foreground"
        echo "  start  - Start the service in background"
        echo "  stop   - Stop the background service"
        echo "  test   - Run tests"
        echo "  clean  - Clean build artifacts"
        echo "  status - Check service status"
        echo "  logs   - Show service logs"
        exit 1
        ;;
esac
