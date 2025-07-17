# 🏭 Go Factory Platform - Global Makefile
# Manages all microservices in the platform

# Service definitions
SERVICES = building-blocks-service template-service generator-service compiler-builder-service project-structure-service
SERVICE_PORTS = 8081 8082 8083 8084 8085
SCRIPT_DIR = scripts
MIGRATOR := ./bin/migrator
SEEDER := ./bin/seeder
MIGRATION_PATH := ./database/migrations
DATABASE_URL := postgresql://postgres:postgres@127.0.0.1:54322/postgres?sslmode=disable

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

.PHONY: help deps build run start stop test clean status logs health check-deps install-tools docker-build migrate-up migrate-down migrate-create migrate-status migrate-rollback migrate-build seed

# Default target
help:
	@echo "🏭 $(GREEN)Go Factory Platform - Management Commands$(NC)"
	@echo "=================================================="
	@echo ""
	@echo "$(YELLOW)Global Operations:$(NC)"
	@echo "  make deps           - Install dependencies for all services"
	@echo "  make build          - Build all services"
	@echo "  make start          - Start all services in background"
	@echo "  make stop           - Stop all running services"
	@echo "  make restart        - Restart all services"
	@echo "  make status         - Show status of all services"
	@echo "  make logs           - Show logs for all services"
	@echo "  make test           - Run tests for all services"
	@echo "  make clean          - Clean all services"
	@echo "  make health         - Check health of all services"
	@echo ""
	@echo "$(YELLOW)Individual Service Operations:$(NC)"
	@echo "  make <service>-deps     - Install deps for specific service"
	@echo "  make <service>-build    - Build specific service"
	@echo "  make <service>-run      - Run specific service in foreground"
	@echo "  make <service>-start    - Start specific service in background"
	@echo "  make <service>-stop     - Stop specific service"
	@echo "  make <service>-test     - Test specific service"
	@echo "  make <service>-clean    - Clean specific service"
	@echo "  make <service>-status   - Status of specific service"
	@echo "  make <service>-logs     - Logs of specific service"
	@echo ""
	@echo "$(YELLOW)Available Services:$(NC)"
	@for service in $(SERVICES); do \
		echo "  - $$service"; \
	done
	@echo ""
	@echo "$(YELLOW)Development & Tools:$(NC)"
	@echo "  make check-deps     - Check if required tools are installed"
	@echo "  make install-tools  - Install required development tools"
	@echo "  make example        - Run the platform example"
	@echo "  make docker-build   - Build Docker images for all services"
	@echo ""
	@echo "$(YELLOW)Database Operations:$(NC)"
	@echo "  make migrate-build    - Build migration and seeder tools"
	@echo "  make migrate-up       - Run database migrations for all services"
	@echo "  make migrate-down     - Rollback all database migrations"
	@echo "  make migrate-create   - Create new migration (usage: make migrate-create service=tenant name=migration_name)"
	@echo "  make migrate-status   - Show migration status for all services"
	@echo "  make migrate-rollback - Rollback last migration (usage: make migrate-rollback service=tenant)"
	@echo "  make seed            - Run database seeder"
	@echo "  make db-reset        - Reset database (down, up, seed)"
	@echo ""

# Global operations
deps:
	@echo "$(GREEN)📦 Installing dependencies for all services...$(NC)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Installing dependencies for $$service...$(NC)"; \
		./$(SCRIPT_DIR)/$$service.sh deps || exit 1; \
	done
	@echo "$(GREEN)✅ All dependencies installed successfully!$(NC)"

build:
	@echo "$(GREEN)🔨 Building all services...$(NC)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Building $$service...$(NC)"; \
		./$(SCRIPT_DIR)/$$service.sh build || exit 1; \
	done
	@echo "$(GREEN)✅ All services built successfully!$(NC)"

start:
	@echo "$(GREEN)🚀 Starting all services...$(NC)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Starting $$service...$(NC)"; \
		./$(SCRIPT_DIR)/$$service.sh start; \
		sleep 2; \
	done
	@echo "$(GREEN)✅ All services started!$(NC)"
	@echo "$(YELLOW)Services running on ports: $(SERVICE_PORTS)$(NC)"
	@sleep 3
	@make status

stop:
	@echo "$(GREEN)🛑 Stopping all services...$(NC)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Stopping $$service...$(NC)"; \
		./$(SCRIPT_DIR)/$$service.sh stop; \
	done
	@echo "$(GREEN)✅ All services stopped!$(NC)"

restart: stop start

status:
	@echo "$(GREEN)📊 Status of all services:$(NC)"
	@echo "================================"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)$$service:$(NC)"; \
		./$(SCRIPT_DIR)/$$service.sh status; \
		echo ""; \
	done

logs:
	@echo "$(GREEN)📋 Recent logs from all services:$(NC)"
	@echo "====================================="
	@for service in $(SERVICES); do \
		echo "$(YELLOW)=== $$service logs ===$(NC)"; \
		if [ -f services/$$service/logs/$$service.log ]; then \
			tail -10 services/$$service/logs/$$service.log; \
		else \
			echo "No logs found"; \
		fi; \
		echo ""; \
	done

test:
	@echo "$(GREEN)🧪 Running tests for all services...$(NC)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Testing $$service...$(NC)"; \
		./$(SCRIPT_DIR)/$$service.sh test || exit 1; \
	done
	@echo "$(GREEN)✅ All tests passed!$(NC)"

clean:
	@echo "$(GREEN)🧹 Cleaning all services...$(NC)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Cleaning $$service...$(NC)"; \
		./$(SCRIPT_DIR)/$$service.sh clean; \
	done
	@echo "$(GREEN)✅ All services cleaned!$(NC)"

health:
	@echo "$(GREEN)🏥 Health check for all services:$(NC)"
	@echo "===================================="
	@ports="$(SERVICE_PORTS)"; \
	i=1; \
	for service in $(SERVICES); do \
		port=$$(echo $$ports | cut -d' ' -f$$i); \
		echo -n "$(YELLOW)$$service (port $$port): $(NC)"; \
		if curl -s -o /dev/null -w "%{http_code}" http://localhost:$$port/health 2>/dev/null | grep -q "200\|404"; then \
			echo "$(GREEN)✅ Healthy$(NC)"; \
		else \
			echo "$(RED)❌ Unhealthy$(NC)"; \
		fi; \
		i=$$((i+1)); \
	done

# Individual service operations
$(foreach service,$(SERVICES),$(eval \
$(service)-deps: ; @./$(SCRIPT_DIR)/$(service).sh deps \
))

$(foreach service,$(SERVICES),$(eval \
$(service)-build: ; @./$(SCRIPT_DIR)/$(service).sh build \
))

$(foreach service,$(SERVICES),$(eval \
$(service)-run: ; @./$(SCRIPT_DIR)/$(service).sh run \
))

$(foreach service,$(SERVICES),$(eval \
$(service)-start: ; @./$(SCRIPT_DIR)/$(service).sh start \
))

$(foreach service,$(SERVICES),$(eval \
$(service)-stop: ; @./$(SCRIPT_DIR)/$(service).sh stop \
))

$(foreach service,$(SERVICES),$(eval \
$(service)-test: ; @./$(SCRIPT_DIR)/$(service).sh test \
))

$(foreach service,$(SERVICES),$(eval \
$(service)-clean: ; @./$(SCRIPT_DIR)/$(service).sh clean \
))

$(foreach service,$(SERVICES),$(eval \
$(service)-status: ; @./$(SCRIPT_DIR)/$(service).sh status \
))

$(foreach service,$(SERVICES),$(eval \
$(service)-logs: ; @./$(SCRIPT_DIR)/$(service).sh logs \
))

# Development tools
check-deps:
	@echo "$(GREEN)🔍 Checking required dependencies...$(NC)"
	@which go >/dev/null 2>&1 || (echo "$(RED)❌ Go is not installed$(NC)" && exit 1)
	@which curl >/dev/null 2>&1 || (echo "$(RED)❌ curl is not installed$(NC)" && exit 1)
	@which jq >/dev/null 2>&1 || echo "$(YELLOW)⚠️  jq is not installed (optional for JSON formatting)$(NC)"
	@echo "$(GREEN)✅ All required dependencies are available!$(NC)"

install-tools:
	@echo "$(GREEN)🛠️  Installing development tools...$(NC)"
	@echo "$(YELLOW)Installing Go tools...$(NC)"
	@go install golang.org/x/tools/cmd/goimports@latest
	@go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	@go install github.com/swaggo/swag/cmd/swag@latest
	@echo "$(GREEN)✅ Development tools installed!$(NC)"

# Example workflow
example:
	@echo "$(GREEN)🎯 Running Go Factory Platform example...$(NC)"
	@chmod +x examples/usage.sh
	@./examples/usage.sh

# Docker support
docker-build:
	@echo "$(GREEN)🐳 Building Docker images for all services...$(NC)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Building Docker image for $$service...$(NC)"; \
		if [ -f services/$$service/Dockerfile ]; then \
			docker build -t go-factory/$$service services/$$service/; \
		else \
			echo "$(YELLOW)⚠️  No Dockerfile found for $$service$(NC)"; \
		fi; \
	done

# Quick development workflow
dev: deps build start
	@echo "$(GREEN)🎉 Development environment ready!$(NC)"
	@echo "$(YELLOW)All services are running. Use 'make logs' to monitor.$(NC)"

# Production deployment preparation
prod-check: check-deps test
	@echo "$(GREEN)🚀 Production readiness check completed!$(NC)"

# Monitoring and debugging
tail-logs:
	@echo "$(GREEN)📋 Tailing logs from all services (Ctrl+C to stop)...$(NC)"
	@for service in $(SERVICES); do \
		if [ -f services/$$service/logs/$$service.log ]; then \
			(tail -f services/$$service/logs/$$service.log | sed "s/^/[$$service] /") & \
		fi; \
	done; \
	wait

# Service dependency order (building-blocks -> template -> generator -> compiler)
start-ordered:
	@echo "$(GREEN)🚀 Starting services in dependency order...$(NC)"
	@echo "$(YELLOW)Starting building-blocks-service...$(NC)"
	@./$(SCRIPT_DIR)/building-blocks-service.sh start
	@sleep 3
	@echo "$(YELLOW)Starting template-service...$(NC)"
	@./$(SCRIPT_DIR)/template-service.sh start
	@sleep 3
	@echo "$(YELLOW)Starting generator-service...$(NC)"
	@./$(SCRIPT_DIR)/generator-service.sh start
	@sleep 3
	@echo "$(YELLOW)Starting compiler-builder-service...$(NC)"
	@./$(SCRIPT_DIR)/compiler-builder-service.sh start
	@sleep 2
	@echo "$(GREEN)✅ All services started in order!$(NC)"
	@make status


# Database Operations
migrate-build: ## Build migration and seeder tools
	@echo "$(GREEN)🔨 Building migration tools...$(NC)"
	@mkdir -p bin
	@go build -o bin/migrator ./cmd/migrator
	@go build -o bin/seeder ./cmd/seeder
	@echo "$(GREEN)✅ Migration tools built successfully!$(NC)"

migrate-up: migrate-build ## Run database migrations
	@echo "$(GREEN)🗄️ Running database migrations...$(NC)"
	@$(MIGRATOR) -action=up -service=all -db-url="$(DATABASE_URL)"
	@echo "$(GREEN)✅ Database migrations completed!$(NC)"

migrate-down: migrate-build ## Rollback database migrations
	@echo "$(GREEN)🗄️ Rolling back database migrations...$(NC)"
	@$(MIGRATOR) -action=down -service=all -db-url="$(DATABASE_URL)"
	@echo "$(GREEN)✅ Database rollback completed!$(NC)"

migrate-create: migrate-build ## Create new migration (usage: make migrate-create service=tenant name=migration_name)
	@if [ -z "$(service)" ] || [ -z "$(name)" ]; then \
		echo "$(RED)❌ Error: Both service and name are required$(NC)"; \
		echo "$(YELLOW)Usage: make migrate-create service=<service> name=<migration_name>$(NC)"; \
		echo "$(YELLOW)Example: make migrate-create service=tenant name=create_tenants_table$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)📝 Creating migration: $(name) for service: $(service)$(NC)"
	@$(MIGRATOR) -action=create -service="$(service)" -name="$(name)"
	@echo "$(GREEN)✅ Migration created successfully!$(NC)"

migrate-status: migrate-build ## Show migration status for all services
	@echo "$(GREEN)📊 Checking migration status...$(NC)"
	@$(MIGRATOR) -action=status -service=all -db-url="$(DATABASE_URL)"

migrate-rollback: migrate-build ## Rollback last migration (usage: make migrate-rollback service=tenant or service=all)
	@if [ -z "$(service)" ]; then \
		echo "$(RED)❌ Error: service parameter is required$(NC)"; \
		echo "$(YELLOW)Usage: make migrate-rollback service=<service>$(NC)"; \
		echo "$(YELLOW)Example: make migrate-rollback service=tenant$(NC)"; \
		echo "$(YELLOW)Example: make migrate-rollback service=all$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)⏪ Rolling back last migration for service: $(service)$(NC)"
	@$(MIGRATOR) -action=rollback -service="$(service)" -db-url="$(DATABASE_URL)"
	@echo "$(GREEN)✅ Rollback completed!$(NC)"

seed: migrate-build ## Run database seeder
	@echo "$(GREEN)🌱 Running database seeder...$(NC)"
	@$(SEEDER) -db-url="$(DATABASE_URL)"
	@echo "$(GREEN)✅ Database seeding completed!$(NC)"

# Database Management
db-reset: migrate-down migrate-up seed ## Reset database (down, up, seed)
