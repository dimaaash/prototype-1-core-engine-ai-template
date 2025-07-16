#!/bin/bash

# Example usage of the Go Factory Platform

echo "🏭 Go Factory Platform - Example Usage"
echo "======================================"

# 1. Start all services
echo "📦 Starting all services..."
make build-all

# Start services in background
cd services/building-blocks-service && go run cmd/main.go &
BUILDING_BLOCKS_PID=$!

cd ../template-service && go run cmd/main.go &
TEMPLATE_PID=$!

cd ../generator-service && go run cmd/main.go &
GENERATOR_PID=$!

cd ../compiler-builder-service && go run cmd/main.go &
COMPILER_PID=$!

cd ../..

echo "⏳ Waiting for services to start..."
sleep 5

# 2. Create some building blocks
echo "🧱 Creating building blocks..."
curl -X POST http://localhost:8081/api/v1/building-blocks/variable \
  -H "Content-Type: application/json" \
  -d '{
    "name": "userID",
    "type": "string",
    "default_value": ""
  }'

# 3. Create templates
echo "📄 Creating templates..."
curl -X POST http://localhost:8082/api/v1/templates/repository \
  -H "Content-Type: application/json" \
  -d '{
    "name": "UserRepository",
    "entity_name": "User"
  }'

curl -X POST http://localhost:8082/api/v1/templates/service \
  -H "Content-Type: application/json" \
  -d '{
    "name": "UserService", 
    "entity_name": "User"
  }'

curl -X POST http://localhost:8082/api/v1/templates/handler \
  -H "Content-Type: application/json" \
  -d '{
    "name": "UserHandler",
    "entity_name": "User"
  }'

# 4. Generate complete entity set
echo "🔧 Generating complete User entity..."
curl -X POST http://localhost:8083/api/v1/generate/entity \
  -H "Content-Type: application/json" \
  -d '{
    "entity_name": "User",
    "module_path": "example.com/user-service",
    "output_path": "./generated/user-service"
  }'

echo "✅ Generation complete! Check ./generated/user-service/"

# 5. Cleanup
echo "🧹 Cleaning up..."
kill $BUILDING_BLOCKS_PID $TEMPLATE_PID $GENERATOR_PID $COMPILER_PID

echo "🎉 Example completed!"
