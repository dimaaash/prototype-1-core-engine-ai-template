package main

import (
	"database/sql"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
	_ "github.com/lib/pq"
)

func main() {
	var (
		service       = flag.String("service", "", "Service name for migration (or 'all' for all services)")
		action        = flag.String("action", "up", "Migration action (up/down/create/status/rollback)")
		dbURL         = flag.String("db-url", "", "Database URL (overrides environment)")
		showHelp      = flag.Bool("help", false, "Show help message")
		migrationName = flag.String("name", "", "Migration name for create action")
	)
	flag.Parse()

	if *showHelp {
		showUsage()
		return
	}
	// Auto-discover available services
	availableServices := discoverServices()

	// Handle create action without database connection
	if *action == "create" {
		if *service == "" || *migrationName == "" {
			log.Fatal("Service name and migration name are required for create action")
		}

		// Validate service name
		if !contains(availableServices, *service) {
			log.Fatalf("Invalid service name: %s. Available services: %s", *service, strings.Join(availableServices, ", "))
		}

		// Create migration without database connection
		migrator := &Migrator{availableServices: availableServices}
		if err := migrator.CreateMigration(*service, *migrationName); err != nil {
			log.Fatalf("Failed to create migration: %v", err)
		}
		fmt.Printf("Migration created for %s service: %s\n", *service, *migrationName)
		return
	}

	// Get database URL from flag or environment (only for up/down/status actions)
	databaseURL := *dbURL
	if databaseURL == "" {
		databaseURL = os.Getenv("DATABASE_URL")
		if databaseURL == "" {
			databaseURL = "postgresql://postgres:postgres@127.0.0.1:54322/postgres?sslmode=disable"
		}
	}

	db, err := sql.Open("postgres", databaseURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}

	migrator := NewMigrator(db, availableServices)

	switch *action {
	case "status":
		// Handle status action
		if *service == "all" {
			// Show status for all services in dependency order
			orderedServices, err := resolveDependencyOrder(availableServices)
			if err != nil {
				log.Fatalf("Failed to resolve service dependencies: %v", err)
			}

			fmt.Println("📊 Migration Status Report")
			fmt.Println("=========================")
			fmt.Println()

			totalApplied := 0
			totalPending := 0

			for _, svc := range orderedServices {
				applied, pending, err := migrator.GetMigrationStatus(svc)
				if err != nil {
					log.Fatalf("Failed to get migration status for %s service: %v", svc, err)
				}

				fmt.Printf("🔧 %s service:\n", strings.ToUpper(svc))
				if len(applied) > 0 {
					fmt.Printf("  ✅ Applied (%d):\n", len(applied))
					for _, migration := range applied {
						fmt.Printf("    • %s\n", migration)
					}
				} else {
					fmt.Printf("  ✅ Applied: None\n")
				}

				if len(pending) > 0 {
					fmt.Printf("  ⏳ Pending (%d):\n", len(pending))
					for _, migration := range pending {
						fmt.Printf("    • %s\n", migration)
					}
				} else {
					fmt.Printf("  ⏳ Pending: None\n")
				}

				totalApplied += len(applied)
				totalPending += len(pending)
				fmt.Println()
			}

			fmt.Println("📈 Summary:")
			fmt.Printf("  Total Applied: %d\n", totalApplied)
			fmt.Printf("  Total Pending: %d\n", totalPending)
			fmt.Printf("  Total Services: %d\n", len(orderedServices))

			if totalPending > 0 {
				fmt.Println()
				fmt.Println("💡 To apply pending migrations, run:")
				fmt.Println("  go run ./cmd/migrator -action=up -service=all")
			} else {
				fmt.Println()
				fmt.Println("🎉 All migrations are up to date!")
			}

			return
		}

		if *service == "" {
			log.Fatal("Service name is required for status action. Use 'all' to see all services or specify a service name.")
		}

		// Validate service name
		if !contains(availableServices, *service) {
			log.Fatalf("Invalid service name: %s. Available services: %s", *service, strings.Join(availableServices, ", "))
		}

		// Show status for single service
		applied, pending, err := migrator.GetMigrationStatus(*service)
		if err != nil {
			log.Fatalf("Failed to get migration status: %v", err)
		}

		fmt.Printf("📊 Migration Status for %s service\n", strings.ToUpper(*service))
		fmt.Println("================================")
		fmt.Println()

		if len(applied) > 0 {
			fmt.Printf("✅ Applied migrations (%d):\n", len(applied))
			for _, migration := range applied {
				fmt.Printf("  • %s\n", migration)
			}
			fmt.Println()
		} else {
			fmt.Println("✅ Applied migrations: None")
			fmt.Println()
		}

		if len(pending) > 0 {
			fmt.Printf("⏳ Pending migrations (%d):\n", len(pending))
			for _, migration := range pending {
				fmt.Printf("  • %s\n", migration)
			}
			fmt.Println()
			fmt.Printf("💡 To apply pending migrations, run:\n")
			fmt.Printf("  go run ./cmd/migrator -action=up -service=%s\n", *service)
		} else {
			fmt.Println("⏳ Pending migrations: None")
			fmt.Println()
			fmt.Println("🎉 All migrations are up to date!")
		}

		return
	case "rollback":
		// Handle rollback action (rollback last migration)
		if *service == "all" {
			// Get last applied migration across all services in reverse dependency order
			orderedServices, err := resolveDependencyOrder(availableServices)
			if err != nil {
				log.Fatalf("Failed to resolve service dependencies: %v", err)
			}

			// For rollback, reverse the order (same as down migrations)
			for i := len(orderedServices)/2 - 1; i >= 0; i-- {
				opp := len(orderedServices) - 1 - i
				orderedServices[i], orderedServices[opp] = orderedServices[opp], orderedServices[i]
			}

			fmt.Println("Rolling back last migrations in dependency order...")
			hasRollbacks := false

			for _, svc := range orderedServices {
				rolled, err := migrator.RollbackLastMigration(svc)
				if err != nil {
					log.Fatalf("Rollback failed for %s service: %v", svc, err)
				}
				if rolled {
					hasRollbacks = true
				}
			}

			if !hasRollbacks {
				fmt.Println("No migrations to rollback.")
			} else {
				fmt.Println("Rollback completed successfully!")
			}
			return
		}

		if *service == "" {
			log.Fatal("Service name is required for rollback action. Use 'all' to rollback across all services or specify a service name.")
		}

		// Validate service name
		if !contains(availableServices, *service) {
			log.Fatalf("Invalid service name: %s. Available services: %s", *service, strings.Join(availableServices, ", "))
		}

		// Rollback last migration for specific service
		rolled, err := migrator.RollbackLastMigration(*service)
		if err != nil {
			log.Fatalf("Rollback failed: %v", err)
		}

		if rolled {
			fmt.Printf("Rollback completed for %s service\n", *service)
		} else {
			fmt.Printf("No migrations to rollback for %s service\n", *service)
		}

		return
	case "up", "down":
		// Handle 'all' services migration
		if *service == "all" {
			// Resolve dependency order
			orderedServices, err := resolveDependencyOrder(availableServices)
			if err != nil {
				log.Fatalf("Failed to resolve service dependencies: %v", err)
			}

			// For down migrations, reverse the order
			if *action == "down" {
				for i := len(orderedServices)/2 - 1; i >= 0; i-- {
					opp := len(orderedServices) - 1 - i
					orderedServices[i], orderedServices[opp] = orderedServices[opp], orderedServices[i]
				}
			}

			fmt.Printf("Migration order for %s: %s\n", *action, strings.Join(orderedServices, " → "))

			for _, svc := range orderedServices {
				fmt.Printf("Running %s migrations for %s service...\n", *action, svc)
				if err := runMigrationForService(migrator, svc, *action); err != nil {
					log.Fatalf("Migration failed for %s service: %v", svc, err)
				}
			}
			fmt.Println("All migrations completed successfully!")
			return
		}

		if *service == "" {
			log.Fatal("Service name is required. Use --help for usage information.")
		}

		// Validate service name
		if !contains(availableServices, *service) {
			log.Fatalf("Invalid service name: %s. Available services: %s", *service, strings.Join(availableServices, ", "))
		}

		if err := runMigrationForService(migrator, *service, *action); err != nil {
			log.Fatalf("Migration failed: %v", err)
		}

		fmt.Printf("Migration completed for %s service\n", *service)

	default:
		log.Fatalf("Unsupported action: %s", *action)
	}
}

// ServiceDependencies defines the dependency graph for Go Factory Platform services
var ServiceDependencies = map[string][]string{
	// Foundation layer - no dependencies
	"core":   {},
	"tenant": {"core"}, // tenant depends on core for status_enum and other types

	// Auth layer - depends on tenant for clients table
	"auth": {"core", "tenant"},

	// User layer - depends on auth and tenant
	"user": {"core", "tenant", "auth"},

	// Support services - depends on business operations
	"platform":     {"core", "tenant"},
	"notification": {"core", "tenant", "user"},
	"reporting":    {"core", "tenant", "user"},
}

// discoverServices dynamically finds available services by scanning migration directories
func discoverServices() []string {
	var services []string

	migrationPath := "database/migrations"

	// Check if migrations directory exists
	if _, err := os.Stat(migrationPath); os.IsNotExist(err) {
		fmt.Println("No migration directories found. Available services will be empty.")
		return services
	}

	// Scan for service directories
	entries, err := os.ReadDir(migrationPath)
	if err != nil {
		fmt.Printf("Error reading migrations directory: %v\n", err)
		return services
	}

	for _, entry := range entries {
		if entry.IsDir() {
			serviceName := entry.Name()
			// Remove '_service' suffix if present for cleaner service names
			serviceName = strings.TrimSuffix(serviceName, "_service")
			services = append(services, serviceName)
		}
	}

	// Don't sort alphabetically - we'll use dependency order
	return services
}

// resolveDependencyOrder sorts services in dependency order using topological sort
func resolveDependencyOrder(services []string) ([]string, error) {
	// Create a map for quick lookup
	serviceSet := make(map[string]bool)
	for _, service := range services {
		serviceSet[service] = true
	}

	// Track visited and visiting nodes for cycle detection
	visited := make(map[string]bool)
	visiting := make(map[string]bool)
	result := make([]string, 0, len(services))

	var visit func(string) error
	visit = func(service string) error {
		if visiting[service] {
			return fmt.Errorf("circular dependency detected involving service: %s", service)
		}
		if visited[service] {
			return nil
		}

		visiting[service] = true

		// Visit dependencies first
		if deps, exists := ServiceDependencies[service]; exists {
			for _, dep := range deps {
				// Only process dependencies that exist in our service list
				if serviceSet[dep] {
					if err := visit(dep); err != nil {
						return err
					}
				}
			}
		}

		visiting[service] = false
		visited[service] = true
		result = append(result, service)
		return nil
	}

	// Visit all services
	for _, service := range services {
		if !visited[service] {
			if err := visit(service); err != nil {
				return nil, err
			}
		}
	}

	return result, nil
}

func runMigrationForService(migrator *Migrator, service, action string) error {
	switch action {
	case "up":
		return migrator.MigrateUp(service)
	case "down":
		return migrator.MigrateDown(service)
	case "rollback":
		_, err := migrator.RollbackLastMigration(service)
		return err
	default:
		return fmt.Errorf("unsupported action: %s", action)
	}
}

func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}

func showUsage() {
	fmt.Println("Go Factory Platform Database Migration Tool")
	fmt.Println()
	fmt.Println("Usage:")
	fmt.Println("  go run ./cmd/migrator [OPTIONS]")
	fmt.Println()
	fmt.Println("Actions:")
	fmt.Println("  -action=up         Run migrations")
	fmt.Println("  -action=down       Rollback ALL migrations")
	fmt.Println("  -action=rollback   Rollback LAST migration only")
	fmt.Println("  -action=create     Create new migration")
	fmt.Println("  -action=status     Show migration status (applied/pending)")
	fmt.Println()
	fmt.Println("Options:")
	fmt.Println("  -service=NAME      Service name (or 'all' for all services)")
	fmt.Println("  -name=NAME         Migration name (required for create)")
	fmt.Println("  -db-url=URL        Database URL (overrides DATABASE_URL env)")
	fmt.Println("  -help              Show this help message")
	fmt.Println()
	fmt.Println("Examples:")
	fmt.Println("  go run ./cmd/migrator -action=up -service=all")
	fmt.Println("  go run ./cmd/migrator -action=status -service=all")
	fmt.Println("  go run ./cmd/migrator -action=status -service=tenant")
	fmt.Println("  go run ./cmd/migrator -action=up -service=tenant")
	fmt.Println("  go run ./cmd/migrator -action=rollback -service=tenant")
	fmt.Println("  go run ./cmd/migrator -action=rollback -service=all")
	fmt.Println("  go run ./cmd/migrator -action=create -service=tenant -name=create_tenants_table")
	fmt.Println("  go run ./cmd/migrator -action=down -service=tenant")
	fmt.Println("  go run ./cmd/migrator -db-url=\"postgresql://postgres:postgres@127.0.0.1:54322/postgres?sslmode=disable\" -action=up -service=all")
	fmt.Println()
	fmt.Println("Dependency Order (for -service=all):")
	fmt.Println("  UP:   core → tenant → auth → user → platform → notification → reporting")
	fmt.Println("  DOWN: reporting → notification → platform → user → auth → tenant → core")
}

// Migrator handles database migrations for Go Factory Platform services
type Migrator struct {
	db                *sql.DB
	availableServices []string
}

func NewMigrator(db *sql.DB, services []string) *Migrator {
	return &Migrator{
		db:                db,
		availableServices: services,
	}
}

func (m *Migrator) CreateMigration(service, name string) error {
	timestamp := time.Now().Format("20060102150405")
	// Generate a unique ID for the migration to prevent conflicts
	migrationID := uuid.New().String()[:8]
	filename := fmt.Sprintf("%s_%s_%s", timestamp, migrationID, name)

	servicePath := getMigrationPath(service)

	// Create service directory if it doesn't exist
	if err := os.MkdirAll(servicePath, 0755); err != nil {
		return fmt.Errorf("failed to create migration directory: %w", err)
	}

	// Create up migration file
	upFile := filepath.Join(servicePath, filename+".up.sql")
	upContent := fmt.Sprintf(`-- Migration: %s
-- Service: %s
-- Created: %s
-- ID: %s

-- Add your UP migration SQL here

`, name, service, time.Now().Format("2006-01-02 15:04:05"), migrationID)

	if err := os.WriteFile(upFile, []byte(upContent), 0644); err != nil {
		return fmt.Errorf("failed to create up migration file: %w", err)
	}

	// Create down migration file
	downFile := filepath.Join(servicePath, filename+".down.sql")
	downContent := fmt.Sprintf(`-- Migration: %s (ROLLBACK)
-- Service: %s
-- Created: %s
-- ID: %s

-- Add your DOWN migration SQL here (rollback changes from up migration)

`, name, service, time.Now().Format("2006-01-02 15:04:05"), migrationID)

	if err := os.WriteFile(downFile, []byte(downContent), 0644); err != nil {
		return fmt.Errorf("failed to create down migration file: %w", err)
	}

	fmt.Printf("Created migration files:\n")
	fmt.Printf("  - %s\n", upFile)
	fmt.Printf("  - %s\n", downFile)

	return nil
}

func (m *Migrator) MigrateUp(service string) error {
	fmt.Printf("Starting UP migration for service: %s\n", service)

	if err := m.createMigrationsTable(); err != nil {
		return err
	}

	migrationPath := getMigrationPath(service)
	fmt.Printf("Looking for migrations in: %s\n", migrationPath)

	files, err := getMigrationFiles(migrationPath, "up")
	if err != nil {
		return err
	}

	if len(files) == 0 {
		fmt.Printf("No migrations found for service: %s\n", service)
		return nil
	}

	fmt.Printf("Found %d migration files\n", len(files))
	for _, file := range files {
		fmt.Printf("Processing file: %s\n", file)
		if err := m.applyMigration(file); err != nil {
			return err
		}
	}

	return nil
}

func (m *Migrator) MigrateDown(service string) error {
	fmt.Printf("Starting DOWN migration for service: %s\n", service)

	migrationPath := getMigrationPath(service)
	files, err := getMigrationFiles(migrationPath, "down")
	if err != nil {
		return err
	}

	if len(files) == 0 {
		fmt.Printf("No down migrations found for service: %s\n", service)
		return nil
	}

	// Reverse order for down migrations
	for i := len(files) - 1; i >= 0; i-- {
		fmt.Printf("Processing file: %s\n", files[i])
		if err := m.applyMigration(files[i]); err != nil {
			return err
		}
	}

	return nil
}

// GetMigrationStatus returns applied and pending migrations for a service
func (m *Migrator) GetMigrationStatus(service string) ([]string, []string, error) {
	// Ensure the migrations table exists
	if err := m.createMigrationsTable(); err != nil {
		return nil, nil, err
	}

	// Get all migration files for this service
	migrationPath := getMigrationPath(service)
	upFiles, err := getMigrationFiles(migrationPath, "up")
	if err != nil {
		return nil, nil, err
	}

	// Get applied migrations from database
	appliedMigrations := make(map[string]bool)
	rows, err := m.db.Query("SELECT version FROM schema_migrations WHERE service = $1", service)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var version string
		if err := rows.Scan(&version); err != nil {
			return nil, nil, err
		}
		appliedMigrations[version] = true
	}

	var applied []string
	var pending []string

	// Check each migration file
	for _, file := range upFiles {
		version := filepath.Base(file)
		if appliedMigrations[version] {
			applied = append(applied, version)
		} else {
			pending = append(pending, version)
		}
	}

	return applied, pending, nil
}

// RollbackLastMigration rolls back the most recently applied migration for a service
func (m *Migrator) RollbackLastMigration(service string) (bool, error) {
	// Ensure the migrations table exists
	if err := m.createMigrationsTable(); err != nil {
		return false, err
	}

	// Find the last applied migration for this service
	var lastMigration string
	err := m.db.QueryRow(`
		SELECT version 
		FROM schema_migrations 
		WHERE service = $1 
		ORDER BY applied_at DESC 
		LIMIT 1
	`, service).Scan(&lastMigration)

	if err == sql.ErrNoRows {
		fmt.Printf("No migrations to rollback for %s service\n", service)
		return false, nil
	}

	if err != nil {
		return false, fmt.Errorf("failed to find last migration: %w", err)
	}

	fmt.Printf("Rolling back last migration for %s service: %s\n", service, lastMigration)

	// Find the corresponding down migration file
	migrationPath := getMigrationPath(service)
	downFile := strings.Replace(lastMigration, ".up.sql", ".down.sql", 1)
	downFilePath := filepath.Join(migrationPath, downFile)

	// Check if down migration file exists
	if _, err := os.Stat(downFilePath); os.IsNotExist(err) {
		return false, fmt.Errorf("down migration file not found: %s", downFilePath)
	}

	// Read and execute the down migration
	content, err := os.ReadFile(downFilePath)
	if err != nil {
		return false, fmt.Errorf("failed to read down migration file: %w", err)
	}

	fmt.Printf("  Executing rollback: %s\n", downFile)
	_, err = m.db.Exec(string(content))
	if err != nil {
		return false, fmt.Errorf("failed to execute rollback migration: %w", err)
	}

	// Remove the migration record from the database
	_, err = m.db.Exec("DELETE FROM schema_migrations WHERE version = $1 AND service = $2",
		lastMigration, service)
	if err != nil {
		return false, fmt.Errorf("failed to remove migration record: %w", err)
	}

	fmt.Printf("  ✅ Rolled back %s\n", lastMigration)
	return true, nil
}

func getMigrationPath(service string) string {
	// Special case for core service - it doesn't use the "_service" suffix
	if service == "core" {
		return filepath.Join("database", "migrations", "core")
	}
	return filepath.Join("database", "migrations", service+"_service")
}

func getMigrationFiles(path, direction string) ([]string, error) {
	pattern := filepath.Join(path, fmt.Sprintf("*.%s.sql", direction))
	files, err := filepath.Glob(pattern)
	if err != nil {
		return nil, err
	}
	sort.Strings(files)
	return files, nil
}

func (m *Migrator) createMigrationsTable() error {
	query := `
		CREATE TABLE IF NOT EXISTS schema_migrations (
			version VARCHAR(255) NOT NULL,
			service VARCHAR(100) NOT NULL,
			applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			PRIMARY KEY (version, service)
		)
	`
	_, err := m.db.Exec(query)
	return err
}

func (m *Migrator) applyMigration(file string) error {
	version := filepath.Base(file)
	service := extractServiceFromPath(file)

	// Check if migration was already applied (only for up migrations)
	if strings.Contains(file, ".up.sql") {
		var count int
		err := m.db.QueryRow("SELECT COUNT(*) FROM schema_migrations WHERE version = $1 AND service = $2",
			version, service).Scan(&count)
		if err != nil {
			return err
		}

		if count > 0 {
			fmt.Printf("  Skipping %s (already applied)\n", version)
			return nil
		}
	}

	// Read and execute migration file
	content, err := os.ReadFile(file)
	if err != nil {
		return err
	}

	fmt.Printf("  Applying %s...\n", version)
	_, err = m.db.Exec(string(content))
	if err != nil {
		return fmt.Errorf("failed to apply migration %s: %w", version, err)
	}

	// Record migration (only for up migrations)
	if strings.Contains(file, ".up.sql") {
		_, err = m.db.Exec("INSERT INTO schema_migrations (version, service) VALUES ($1, $2)",
			version, service)
		if err != nil {
			return err
		}
		fmt.Printf("  ✅ Applied %s\n", version)
	} else {
		// Remove migration record for down migrations
		upVersion := strings.Replace(version, ".down.sql", ".up.sql", 1)
		_, err = m.db.Exec("DELETE FROM schema_migrations WHERE version = $1 AND service = $2",
			upVersion, service)
		if err != nil {
			return err
		}
		fmt.Printf("  ✅ Rolled back %s\n", version)
	}

	return nil
}

func extractServiceFromPath(file string) string {
	parts := strings.Split(file, string(filepath.Separator))
	for _, part := range parts {
		// Check for core service (special case - no _service suffix)
		if part == "core" {
			return "core"
		}
		// Check for other services with _service suffix
		if strings.HasSuffix(part, "_service") {
			return strings.TrimSuffix(part, "_service")
		}
	}
	return "unknown"
}
