package config

// SeederConfig holds configuration for the seeder
type SeederConfig struct {
	DatabaseURL      string
	Environment      string
	TenantMode       string // single, multi, all
	ClientMode       string // single, multi, all
	Services         []string
	DryRun           bool
	Verbose          bool
	GenerateProducts int // Number of fake products to generate
	GenerateUsers    int // Number of fake users to generate
	FakerCount       int // Default count for faker generation
}

// DefaultConfig returns a default configuration
func DefaultConfig() *SeederConfig {
	return &SeederConfig{
		DatabaseURL:      "postgresql://postgres:postgres@127.0.0.1:54322/postgres?sslmode=disable",
		Environment:      "development",
		TenantMode:       "single",
		ClientMode:       "single",
		Services:         []string{"core", "tenant", "auth", "user", "product", "warehouse", "store", "inventory", "order", "allocation", "fulfillment", "platform", "notification", "reporting"},
		DryRun:           false,
		Verbose:          false,
		GenerateProducts: 0,
		GenerateUsers:    0,
		FakerCount:       3,
	}
}
