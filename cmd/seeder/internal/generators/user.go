package generators

import (
	"fmt"
	"math/rand"
	"strings"
	"time"

	"github.com/go-faker/faker/v4"
	"github.com/google/uuid"
)

// UserGenerator handles fake user generation
type UserGenerator struct {
	tenantIDs []string
	clientIDs []string
}

// NewUserGenerator creates a new user generator
func NewUserGenerator(tenantIDs, clientIDs []string) *UserGenerator {
	return &UserGenerator{
		tenantIDs: tenantIDs,
		clientIDs: clientIDs,
	}
}

// GenerateUsers creates realistic fake user data
func (ug *UserGenerator) GenerateUsers(count int) ([]map[string]interface{}, error) {
	var users []map[string]interface{}

	for i := 0; i < count; i++ {
		// Generate basic user data using faker
		var fakeUser struct {
			FirstName string `faker:"first_name"`
			LastName  string `faker:"last_name"`
			Email     string `faker:"email"`
			Phone     string `faker:"phone_number"`
		}

		if err := faker.FakeData(&fakeUser); err != nil {
			return nil, fmt.Errorf("failed to generate fake user data: %w", err)
		}

		// Create username from first and last name
		username := strings.ToLower(fmt.Sprintf("%s.%s", fakeUser.FirstName, fakeUser.LastName))
		username = strings.ReplaceAll(username, " ", ".")

		// Select random tenant and client
		tenantID := ug.tenantIDs[rand.Intn(len(ug.tenantIDs))]
		clientID := ug.clientIDs[rand.Intn(len(ug.clientIDs))]

		// Generate user status and verification flags
		isActive := i%20 != 0      // 95% active
		emailVerified := i%10 != 0 // 90% email verified

		// Generate email verification timestamp or nil
		var emailVerifiedAt interface{} = nil
		if emailVerified {
			emailVerifiedAt = time.Now().Add(-time.Duration(rand.Intn(30)+1) * 24 * time.Hour).Format(time.RFC3339)
		}

		user := map[string]interface{}{
			"id":                uuid.New().String(),
			"tenant_id":         tenantID,
			"client_id":         clientID,
			"email":             strings.ToLower(fakeUser.Email),
			"password_hash":     "$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj9Q3PQKY6.m", // Default bcrypt hash for "password123"
			"first_name":        fakeUser.FirstName,
			"last_name":         fakeUser.LastName,
			"phone":             fakeUser.Phone,
			"status":            ug.getUserStatus(isActive),
			"email_verified_at": emailVerifiedAt,
			"created_at":        time.Now().Add(-time.Duration(rand.Intn(365)+1) * 24 * time.Hour).Format(time.RFC3339),
			"updated_at":        time.Now().Add(-time.Duration(rand.Intn(30)+1) * 24 * time.Hour).Format(time.RFC3339),
		}

		users = append(users, user)
	}

	return users, nil
}

func (ug *UserGenerator) getUserStatus(isActive bool) string {
	if isActive {
		return "active"
	}
	statuses := []string{"inactive", "suspended", "pending"}
	return statuses[rand.Intn(len(statuses))]
}

func (ug *UserGenerator) getRandomTheme() string {
	themes := []string{"light", "dark", "auto"}
	return themes[rand.Intn(len(themes))]
}

func (ug *UserGenerator) getRandomWidgets() []string {
	allWidgets := []string{"inventory", "orders", "analytics", "alerts", "tasks", "notifications", "reports", "dashboard"}
	numWidgets := rand.Intn(4) + 2 // 2-5 widgets

	// Shuffle and select random widgets
	rand.Shuffle(len(allWidgets), func(i, j int) {
		allWidgets[i], allWidgets[j] = allWidgets[j], allWidgets[i]
	})

	if numWidgets > len(allWidgets) {
		numWidgets = len(allWidgets)
	}

	return allWidgets[:numWidgets]
}

func (ug *UserGenerator) generateLastLogin(isActive bool) interface{} {
	if !isActive || rand.Intn(5) == 0 { // 20% chance of never logged in or inactive users
		return nil
	}

	// Generate last login within the last 30 days
	lastLogin := time.Now().Add(-time.Duration(rand.Intn(30)) * 24 * time.Hour)
	return lastLogin.Format(time.RFC3339)
}
