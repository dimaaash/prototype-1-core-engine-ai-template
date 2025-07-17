package generators

import (
	"math/rand"
	"time"

	"github.com/go-faker/faker/v4"
	"github.com/google/uuid"
)

// TenantGenerator handles fake tenant generation
type TenantGenerator struct{}

// NewTenantGenerator creates a new tenant generator
func NewTenantGenerator() *TenantGenerator {
	return &TenantGenerator{}
}

// GenerateTenants creates realistic fake tenant data
func (tg *TenantGenerator) GenerateTenants(count int) ([]map[string]interface{}, error) {
	var tenants []map[string]interface{}

	industries := []string{
		"Technology", "Manufacturing", "Retail", "Healthcare",
		"Education", "Finance", "Logistics", "Construction",
		"Food & Beverage", "Automotive", "Energy", "Real Estate",
	}

	plans := []string{"basic", "premium", "enterprise"}

	for i := 0; i < count; i++ {
		companyName := faker.Name() + " " + []string{"Systems", "Solutions", "Group", "Corp", "Inc", "Technologies", "Industries", "Services"}[rand.Intn(8)]
		slug := tg.generateSlug(companyName)
		domain := slug + ".example.com"

		// Generate settings as JSON object
		settings := map[string]interface{}{
			"industry":         industries[rand.Intn(len(industries))],
			"timezone":         "America/New_York",
			"currency":         "USD",
			"language":         "en",
			"date_format":      "MM/DD/YYYY",
			"time_format":      "12h",
			"weight_unit":      "kg",
			"dimension_unit":   "cm",
			"temperature_unit": "celsius",
			"max_users":        []int{10, 50, 1000}[rand.Intn(3)],
			"max_storage_gb":   []int{100, 500, 10000}[rand.Intn(3)],
			"features": map[string]interface{}{
				"multi_projects":     true,
				"api_access":         i%2 == 0,
				"advanced_reporting": i%3 == 0,
				"integrations":       []string{"shopify", "amazon", "woocommerce"}[rand.Intn(3)],
			},
		}

		tenant := map[string]interface{}{
			"id":         uuid.New().String(),
			"name":       companyName,
			"slug":       slug,
			"domain":     domain,
			"status":     "active", // Use fixed status for now
			"plan":       plans[rand.Intn(len(plans))],
			"settings":   settings,
			"created_at": time.Now().Add(-time.Duration(rand.Intn(365)+1) * 24 * time.Hour).Format(time.RFC3339),
			"updated_at": time.Now().Add(-time.Duration(rand.Intn(30)+1) * 24 * time.Hour).Format(time.RFC3339),
		}

		tenants = append(tenants, tenant)
	}

	return tenants, nil
}

func (tg *TenantGenerator) generateSlug(name string) string {
	// Convert to lowercase and replace spaces/special chars with dashes
	slug := ""
	for _, char := range name {
		if (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') {
			slug += string(char)
		} else if char >= 'A' && char <= 'Z' {
			slug += string(char + 32) // Convert to lowercase
		} else if char == ' ' || char == '_' {
			slug += "-"
		}
	}
	return slug
}
