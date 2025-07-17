package seeder

import (
	"fmt"
	"strings"

	"go-factory-platform/cmd/seeder/internal/config"
	"go-factory-platform/cmd/seeder/internal/database"
	"go-factory-platform/cmd/seeder/internal/generators"
	"go-factory-platform/cmd/seeder/internal/models"
)

// Seeder is the main seeder struct
type Seeder struct {
	config *config.SeederConfig
	db     *database.Connection
}

// New creates a new seeder instance
func New(cfg *config.SeederConfig) (*Seeder, error) {
	db, err := database.NewConnection(cfg.DatabaseURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	return &Seeder{
		config: cfg,
		db:     db,
	}, nil
}

// Close closes the database connection
func (s *Seeder) Close() error {
	return s.db.Close()
}

// SeedAll runs the complete seeding process
func (s *Seeder) SeedAll() error {
	fmt.Printf("🌱 Starting seeding process...\n")
	fmt.Printf("📊 Environment: %s\n", s.config.Environment)
	fmt.Printf("🏢 Tenant Mode: %s\n", s.config.TenantMode)
	fmt.Printf("🏬 Client Mode: %s\n", s.config.ClientMode)
	fmt.Printf("🔧 Services: %s\n", strings.Join(s.config.Services, ", "))
	fmt.Printf("🎭 FAKER MODE - Generating realistic test data\n")
	fmt.Printf("📊 Default Count: %d\n", s.config.FakerCount)

	// Generate core entities
	if err := s.generateFakeTenants(); err != nil {
		return fmt.Errorf("failed to generate tenants: %w", err)
	}

	if err := s.generateFakeClients(); err != nil {
		return fmt.Errorf("failed to generate clients: %w", err)
	}

	if err := s.generateFakeRoles(); err != nil {
		return fmt.Errorf("failed to generate roles: %w", err)
	}

	if err := s.generateFakeUsers(); err != nil {
		return fmt.Errorf("failed to generate users: %w", err)
	}

	if err := s.generateFakeUserRoles(); err != nil {
		return fmt.Errorf("failed to generate user roles: %w", err)
	}

	fmt.Printf("🎉 Faker seeding completed successfully!\n")
	fmt.Printf("🎉 Seeding completed successfully!\n")
	return nil
}

func (s *Seeder) generateFakeTenants() error {
	fmt.Printf("🏢 Generating %d fake tenants...\n", s.config.FakerCount)

	generator := generators.NewTenantGenerator()
	tenants, err := generator.GenerateTenants(s.config.FakerCount)
	if err != nil {
		return err
	}

	seedData := &models.SeedData{
		Service:     "tenant",
		Table:       "tenants",
		Description: fmt.Sprintf("Generated %d fake tenants", len(tenants)),
		Data:        tenants,
	}

	return s.seedFile(seedData)
}

func (s *Seeder) generateFakeClients() error {
	fmt.Printf("🏬 Generating %d fake clients...\n", s.config.FakerCount*2)

	// Get tenant IDs for client generation
	tenantIDs, err := s.getTenantIDs()
	if err != nil {
		return fmt.Errorf("failed to get tenant IDs: %w", err)
	}

	generator := generators.NewClientGenerator(tenantIDs)
	clients, err := generator.GenerateClients(s.config.FakerCount * 2)
	if err != nil {
		return err
	}

	seedData := &models.SeedData{
		Service:     "client",
		Table:       "clients",
		Description: fmt.Sprintf("Generated %d fake clients", len(clients)),
		Data:        clients,
	}

	return s.seedFile(seedData)
}

func (s *Seeder) generateFakeRoles() error {
	fmt.Printf("🛡️ Generating %d fake roles...\n", s.config.FakerCount)

	// Get tenant and client IDs for role generation
	tenantIDs, err := s.getTenantIDs()
	if err != nil {
		return fmt.Errorf("failed to get tenant IDs: %w", err)
	}

	clientIDs, err := s.getClientIDs()
	if err != nil {
		return fmt.Errorf("failed to get client IDs: %w", err)
	}

	generator := generators.NewRoleGenerator(tenantIDs, clientIDs)
	roles, err := generator.GenerateRoles(s.config.FakerCount)
	if err != nil {
		return err
	}

	seedData := &models.SeedData{
		Service:     "role",
		Table:       "roles",
		Description: fmt.Sprintf("Generated %d fake roles", len(roles)),
		Data:        roles,
	}

	return s.seedFile(seedData)
}

func (s *Seeder) generateFakeUsers() error {
	fmt.Printf("👥 Generating %d fake users...\n", s.config.FakerCount)

	// Get tenant and client IDs for user generation
	tenantIDs, err := s.getTenantIDs()
	if err != nil {
		return fmt.Errorf("failed to get tenant IDs: %w", err)
	}

	clientIDs, err := s.getClientIDs()
	if err != nil {
		return fmt.Errorf("failed to get client IDs: %w", err)
	}

	generator := generators.NewUserGenerator(tenantIDs, clientIDs)
	users, err := generator.GenerateUsers(s.config.FakerCount)
	if err != nil {
		return err
	}

	seedData := &models.SeedData{
		Service:     "user",
		Table:       "users",
		Description: fmt.Sprintf("Generated %d fake users", len(users)),
		Data:        users,
	}

	return s.seedFile(seedData)
}

func (s *Seeder) generateFakeUserRoles() error {
	fmt.Printf("👥🛡️ Generating %d fake user roles...\n", s.config.FakerCount)

	// Check if required tables exist before proceeding
	if !s.tableExists("users") {
		fmt.Printf("  ⏭️ Table 'users' does not exist - skipping user roles\n")
		return nil
	}
	if !s.tableExists("roles") {
		fmt.Printf("  ⏭️ Table 'roles' does not exist - skipping user roles\n")
		return nil
	}
	if !s.tableExists("user_roles") {
		fmt.Printf("  ⏭️ Table 'user_roles' does not exist - skipping user roles\n")
		return nil
	}

	// Get IDs for user role generation
	userIDs, err := s.getUserIDs()
	if err != nil {
		return fmt.Errorf("failed to get user IDs: %w", err)
	}

	roleIDs, err := s.getRoleIDs()
	if err != nil {
		return fmt.Errorf("failed to get role IDs: %w", err)
	}

	tenantIDs, err := s.getTenantIDs()
	if err != nil {
		return fmt.Errorf("failed to get tenant IDs: %w", err)
	}

	clientIDs, err := s.getClientIDs()
	if err != nil {
		return fmt.Errorf("failed to get client IDs: %w", err)
	}

	generator := generators.NewUserRoleGenerator(userIDs, roleIDs, tenantIDs, clientIDs)
	userRoles, err := generator.GenerateUserRoles(s.config.FakerCount)
	if err != nil {
		return err
	}

	seedData := &models.SeedData{
		Service:     "user_role",
		Table:       "user_roles",
		Description: fmt.Sprintf("Generated %d fake user roles", len(userRoles)),
		Data:        userRoles,
	}

	return s.seedFile(seedData)
}

// Helper methods for database operations

// seedFile handles the seeding process for a given seed data
func (s *Seeder) seedFile(seedData *models.SeedData) error {
	if s.config.Verbose {
		fmt.Printf("  📝 Processing %s: %s\n", seedData.Service, seedData.Description)
	}

	// Check if table exists before proceeding
	if !s.tableExists(seedData.Table) {
		fmt.Printf("  ⏭️ Table '%s' does not exist - skipping %s\n", seedData.Table, seedData.Service)
		return nil
	}

	// Insert data
	insertedCount := 0
	for i, record := range seedData.Data {
		if s.config.Verbose {
			fmt.Printf("    🔍 Processing record %d\n", i+1)
		}

		if err := s.db.InsertRecord(seedData.Table, record); err != nil {
			return fmt.Errorf("failed to insert record %d: %w", i+1, err)
		}
		insertedCount++
	}

	fmt.Printf("  ✅ Inserted %d records\n", insertedCount)
	fmt.Printf("✅ Successfully generated and seeded %d fake %s\n", insertedCount, seedData.Service)
	return nil
}

// getTenantIDs retrieves all tenant IDs from the database
func (s *Seeder) getTenantIDs() ([]string, error) {
	query := "SELECT id FROM tenants"
	rows, err := s.db.DB.Query(query)
	if err != nil {
		return nil, fmt.Errorf("failed to query tenant IDs: %w", err)
	}
	defer rows.Close()

	var tenantIDs []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, fmt.Errorf("failed to scan tenant ID: %w", err)
		}
		tenantIDs = append(tenantIDs, id)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating over tenant IDs: %w", err)
	}

	return tenantIDs, nil
}

// getClientIDs retrieves all client IDs from the database
func (s *Seeder) getClientIDs() ([]string, error) {
	query := "SELECT id FROM clients"
	rows, err := s.db.DB.Query(query)
	if err != nil {
		return nil, fmt.Errorf("failed to query client IDs: %w", err)
	}
	defer rows.Close()

	var clientIDs []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, fmt.Errorf("failed to scan client ID: %w", err)
		}
		clientIDs = append(clientIDs, id)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating over client IDs: %w", err)
	}

	return clientIDs, nil
}

// getUserIDs retrieves all user IDs from the database
func (s *Seeder) getUserIDs() ([]string, error) {
	query := "SELECT id FROM users"
	rows, err := s.db.DB.Query(query)
	if err != nil {
		return nil, fmt.Errorf("failed to query user IDs: %w", err)
	}
	defer rows.Close()

	var userIDs []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, fmt.Errorf("failed to scan user ID: %w", err)
		}
		userIDs = append(userIDs, id)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating over user IDs: %w", err)
	}

	return userIDs, nil
}

// getRoleIDs retrieves all role IDs from the database
func (s *Seeder) getRoleIDs() ([]string, error) {
	query := "SELECT id FROM roles"
	rows, err := s.db.DB.Query(query)
	if err != nil {
		return nil, fmt.Errorf("failed to query role IDs: %w", err)
	}
	defer rows.Close()

	var roleIDs []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, fmt.Errorf("failed to scan role ID: %w", err)
		}
		roleIDs = append(roleIDs, id)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating over role IDs: %w", err)
	}

	return roleIDs, nil
}

// tableExists checks if a table exists in the database
func (s *Seeder) tableExists(tableName string) bool {
	query := `SELECT EXISTS (
		SELECT FROM information_schema.tables 
		WHERE table_schema = 'public' 
		AND table_name = $1
	)`
	var exists bool
	err := s.db.DB.QueryRow(query, tableName).Scan(&exists)
	if err != nil {
		if s.config.Verbose {
			fmt.Printf("  ⚠️ Error checking if table '%s' exists: %v\n", tableName, err)
		}
		return false
	}
	return exists
}
