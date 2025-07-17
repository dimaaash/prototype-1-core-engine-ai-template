package generators

import (
	"fmt"
	"math/rand"
	"strings"
	"time"

	"github.com/go-faker/faker/v4"
	"github.com/google/uuid"
)

// ClientGenerator handles fake client generation
type ClientGenerator struct {
	tenantIDs []string
}

// NewClientGenerator creates a new client generator
func NewClientGenerator(tenantIDs []string) *ClientGenerator {
	return &ClientGenerator{
		tenantIDs: tenantIDs,
	}
}

// GenerateClients creates realistic fake client data
func (cg *ClientGenerator) GenerateClients(count int) ([]map[string]interface{}, error) {
	var clients []map[string]interface{}

	industries := []string{"manufacturing", "retail", "logistics", "healthcare", "technology", "automotive", "food_beverage"}
	currencies := []string{"USD", "EUR", "GBP", "CAD", "AUD", "JPY"}
	timezones := []string{"America/New_York", "America/Chicago", "America/Denver", "America/Los_Angeles", "UTC", "Europe/London", "Asia/Tokyo"}
	divisions := []string{"headquarters", "north_region", "south_region", "east_region", "west_region", "central", "international"}

	for i := 0; i < count; i++ {
		var fakeData struct {
			Name     string `faker:"name"`
			LastName string `faker:"last_name"`
			Email    string `faker:"email"`
			Phone    string `faker:"phone_number"`
		}

		if err := faker.FakeData(&fakeData); err != nil {
			return nil, fmt.Errorf("failed to generate fake client data: %w", err)
		}

		// Generate company name
		businessTypes := []string{"Corp", "Inc", "LLC", "Ltd", "Industries", "Systems", "Solutions", "Technologies"}
		companyName := fmt.Sprintf("%s %s", fakeData.LastName, businessTypes[rand.Intn(len(businessTypes))])

		// Generate address
		address := cg.generateAddress()

		// Select random tenant
		tenantID := cg.tenantIDs[rand.Intn(len(cg.tenantIDs))]

		// Generate client code
		companyAbbrev := cg.generateCompanyAbbreviation(companyName)
		division := divisions[rand.Intn(len(divisions))]
		code := fmt.Sprintf("%s-%s", companyAbbrev, strings.ToUpper(division[:3]))

		client := map[string]interface{}{
			"id":                    uuid.New().String(),
			"tenant_id":             tenantID,
			"code":                  code,
			"name":                  fmt.Sprintf("%s %s", companyName, cg.capitalizeDivision(division)),
			"description":           fmt.Sprintf("%s operations for %s", cg.capitalizeDivision(division), companyName),
			"contact_name":          fakeData.Name,
			"contact_email":         fakeData.Email,
			"contact_phone":         fakeData.Phone,
			"address_line_1":        address["street"],
			"city":                  address["city"],
			"state_province":        address["state"],
			"postal_code":           address["postal_code"],
			"country":               address["country"],
			"business_registration": fmt.Sprintf("%s-%03d", companyAbbrev, rand.Intn(999)+1),
			"industry":              industries[rand.Intn(len(industries))],
			"default_currency":      currencies[rand.Intn(len(currencies))],
			"default_timezone":      timezones[rand.Intn(len(timezones))],
			"settings":              cg.generateClientSettings(),
			"status":                cg.getClientStatus(i),
			"metadata": map[string]interface{}{
				"division":   division,
				"created_by": "seeder",
			},
			"created_at": time.Now().Add(-time.Duration(rand.Intn(365)+1) * 24 * time.Hour).Format(time.RFC3339),
			"updated_at": time.Now().Add(-time.Duration(rand.Intn(30)+1) * 24 * time.Hour).Format(time.RFC3339),
		}

		clients = append(clients, client)
	}

	return clients, nil
}

func (cg *ClientGenerator) generateAddress() map[string]interface{} {
	streets := []string{"Main St", "Oak Ave", "Park Blvd", "First St", "Second Ave", "Commerce Dr", "Industrial Blvd", "Business Way"}
	cities := []string{"Springfield", "Madison", "Franklin", "Georgetown", "Arlington", "Salem", "Bristol", "Clinton"}
	states := []string{"NY", "CA", "TX", "FL", "IL", "PA", "OH", "GA", "NC", "MI"}
	countries := []string{"US", "CA", "GB", "AU"}

	country := countries[rand.Intn(len(countries))]
	postalCode := cg.generatePostalCode(country)

	return map[string]interface{}{
		"street":      fmt.Sprintf("%d %s", rand.Intn(9999)+1, streets[rand.Intn(len(streets))]),
		"city":        cities[rand.Intn(len(cities))],
		"state":       states[rand.Intn(len(states))],
		"postal_code": postalCode,
		"country":     country,
	}
}

func (cg *ClientGenerator) generatePostalCode(country string) string {
	switch country {
	case "US":
		return fmt.Sprintf("%05d", rand.Intn(99999)+1)
	case "CA":
		letters := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		digits := "0123456789"
		return fmt.Sprintf("%c%c%c %c%c%c",
			letters[rand.Intn(len(letters))], digits[rand.Intn(len(digits))], letters[rand.Intn(len(letters))],
			digits[rand.Intn(len(digits))], letters[rand.Intn(len(letters))], digits[rand.Intn(len(digits))])
	case "GB":
		letters := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		digits := "0123456789"
		return fmt.Sprintf("%c%c%c%c %c%c%c",
			letters[rand.Intn(len(letters))], letters[rand.Intn(len(letters))], digits[rand.Intn(len(digits))], letters[rand.Intn(len(letters))],
			digits[rand.Intn(len(digits))], letters[rand.Intn(len(letters))], letters[rand.Intn(len(letters))])
	case "AU":
		return fmt.Sprintf("%04d", rand.Intn(9999)+1000)
	default:
		return fmt.Sprintf("%05d", rand.Intn(99999)+1)
	}
}

func (cg *ClientGenerator) generateCompanyAbbreviation(company string) string {
	words := strings.Fields(company)
	if len(words) == 1 {
		if len(words[0]) >= 4 {
			return strings.ToUpper(words[0][:4])
		}
		return strings.ToUpper(words[0])
	}

	abbrev := ""
	for i, word := range words {
		if i < 3 { // Max 3 letters
			abbrev += strings.ToUpper(string(word[0]))
		}
	}
	return abbrev
}

func (cg *ClientGenerator) capitalizeDivision(division string) string {
	parts := strings.Split(division, "_")
	for i, part := range parts {
		if len(part) > 0 {
			parts[i] = strings.ToUpper(string(part[0])) + strings.ToLower(part[1:])
		}
	}
	return strings.Join(parts, " ")
}

func (cg *ClientGenerator) getClientStatus(index int) string {
	if index%15 == 0 { // ~7% inactive
		return "inactive"
	}
	return "active"
}

func (cg *ClientGenerator) generateClientSettings() map[string]interface{} {
	apiLimit := []int{1000, 2000, 3000, 5000, 10000}
	storageQuota := []int{50, 100, 150, 200, 300}

	features := []string{"code_generation", "template_management", "project_creation"}
	if rand.Intn(3) == 0 { // 33% chance
		features = append(features, "reporting")
	}
	if rand.Intn(4) == 0 { // 25% chance
		features = append(features, "advanced_generation")
	}

	return map[string]interface{}{
		"api_rate_limit":   apiLimit[rand.Intn(len(apiLimit))],
		"storage_quota_gb": storageQuota[rand.Intn(len(storageQuota))],
		"features":         features,
	}
}
