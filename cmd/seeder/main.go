package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"strings"

	"go-factory-platform/cmd/seeder/internal/config"
	"go-factory-platform/cmd/seeder/internal/seeder"
)

func main() {
	var (
		dbURL            = flag.String("db-url", "", "Database URL (overrides environment)")
		environment      = flag.String("env", "development", "Environment (development, staging, production)")
		tenantMode       = flag.String("tenant-mode", "single", "Tenant seeding mode (single, multi, all)")
		clientMode       = flag.String("client-mode", "single", "Client seeding mode (single, multi, all)")
		services         = flag.String("services", "all", "Comma-separated list of services to seed (or 'all')")
		verbose          = flag.Bool("verbose", false, "Enable verbose logging")
		showHelp         = flag.Bool("help", false, "Show help message")
		generateProducts = flag.Int("generate-products", 0, "Generate fake products (specify count, 0 disables)")
		fakerCount       = flag.Int("faker-count", 10, "Default count for faker generation")
	)
	flag.Parse()

	if *showHelp {
		showUsage()
		return
	}

	// Get database URL from flag or environment
	databaseURL := *dbURL
	if databaseURL == "" {
		databaseURL = os.Getenv("DATABASE_URL")
		if databaseURL == "" {
			databaseURL = "postgresql://postgres:postgres@127.0.0.1:54322/postgres?sslmode=disable"
		}
	}

	// Parse services list
	var serviceList []string
	if *services == "all" {
		serviceList = []string{"core", "tenant", "auth", "user", "platform", "notification", "reporting"}
	} else {
		serviceList = strings.Split(*services, ",")
		for i, service := range serviceList {
			serviceList[i] = strings.TrimSpace(service)
		}
	}

	// Create configuration
	cfg := &config.SeederConfig{
		DatabaseURL:      databaseURL,
		Environment:      *environment,
		TenantMode:       *tenantMode,
		ClientMode:       *clientMode,
		Services:         serviceList,
		Verbose:          *verbose,
		GenerateProducts: *generateProducts,
		FakerCount:       *fakerCount,
	}

	// Create seeder instance
	s, err := seeder.New(cfg)
	if err != nil {
		log.Fatalf("Failed to create seeder: %v", err)
	}
	defer s.Close()

	// Run seeding process
	if err := s.SeedAll(); err != nil {
		log.Fatalf("Seeding failed: %v", err)
	}
}

func showUsage() {
	fmt.Printf(`
🌱 Go Factory Platform Seeder Tool

This tool seeds the database with initial data for the Go Factory Platform.

USAGE:
  %s [OPTIONS]

OPTIONS:
  -db-url string
        Database URL (overrides environment variable)
        Default: Uses DATABASE_URL environment variable or postgres://postgres:postgres@127.0.0.1:54322/postgres?sslmode=disable

  -env string
        Environment (development, staging, production)
        Default: development

  -tenant-mode string
        Tenant seeding mode
        Options: single, multi, all
        Default: single

  -client-mode string
        Client seeding mode
        Options: single, multi, all
        Default: single

  -services string
        Comma-separated list of services to seed (or 'all')
        Default: all

  -verbose
        Enable verbose logging
        Default: false

  -generate-products int
        Generate fake products (specify count, 0 disables)
        Default: 0

  -faker-count int
        Default count for faker data generation
        Default: 10

  -help
        Show this help message

EXAMPLES:
  # Basic seeding with defaults
  %s

  # Generate 50 fake entries with verbose output
  %s -faker-count 50 -verbose

  # Seed specific services only
  %s -services "tenant,user,auth"

  # Use custom database URL
  %s -db-url "postgresql://user:pass@localhost:5432/platform"

  # Generate data with custom faker count
  %s -faker-count 25

ENVIRONMENT VARIABLES:
  DATABASE_URL    PostgreSQL connection string

For more information, see the documentation in the docs/ directory.
`, os.Args[0], os.Args[0], os.Args[0], os.Args[0], os.Args[0], os.Args[0])
}
