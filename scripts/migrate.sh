#!/bin/bash
# Migration helper script

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

# Default values
ACTION="up"
SERVICE=""
MIGRATION_NAME=""
DB_URL="${DATABASE_URL:-postgresql://postgres:postgres@localhost:5432/go_factory_platform?sslmode=disable}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -s|--service)
            SERVICE="$2"
            shift 2
            ;;
        -n|--name)
            MIGRATION_NAME="$2"
            shift 2
            ;;
        -d|--db-url)
            DB_URL="$2"
            shift 2
            ;;
        -h|--help)
            echo "Migration Helper Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -a, --action     Migration action (up/down/create) [default: up]"
            echo "  -s, --service    Service name (required, or 'all' for all services)"
            echo "  -n, --name       Migration name (required for create action)"
            echo "  -d, --db-url     Database URL [default: \$DATABASE_URL]"
            echo "  -h, --help       Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --action=up --service=all"
            echo "  $0 --action=create --service=tenant --name=create_tenants_table"
            echo "  $0 --action=down --service=tenant"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$SERVICE" ]]; then
    echo "Error: Service name is required"
    echo "Use --help for usage information"
    exit 1
fi

if [[ "$ACTION" == "create" && -z "$MIGRATION_NAME" ]]; then
    echo "Error: Migration name is required for create action"
    echo "Use --help for usage information"
    exit 1
fi

# Build migrator if not exists
if [[ ! -f "bin/migrator" ]]; then
    echo "🔨 Building migrator..."
    go build -o bin/migrator ./cmd/migrator
fi

# Run migration
echo "🗄️ Running migration: action=$ACTION, service=$SERVICE"
if [[ "$ACTION" == "create" ]]; then
    ./bin/migrator -action="$ACTION" -service="$SERVICE" -name="$MIGRATION_NAME" -db-url="$DB_URL"
else
    ./bin/migrator -action="$ACTION" -service="$SERVICE" -db-url="$DB_URL"
fi

echo "✅ Migration completed!"
