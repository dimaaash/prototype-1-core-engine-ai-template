package generators

import (
	"fmt"
	"math/rand"
	"time"

	"github.com/google/uuid"
)

// UserRoleGenerator handles fake user role assignment generation
type UserRoleGenerator struct {
	userIDs   []string
	roleIDs   []string
	tenantIDs []string
	clientIDs []string
}

// NewUserRoleGenerator creates a new user role generator
func NewUserRoleGenerator(userIDs, roleIDs, tenantIDs, clientIDs []string) *UserRoleGenerator {
	return &UserRoleGenerator{
		userIDs:   userIDs,
		roleIDs:   roleIDs,
		tenantIDs: tenantIDs,
		clientIDs: clientIDs,
	}
}

// GenerateUserRoles creates realistic fake user role assignment data
func (urg *UserRoleGenerator) GenerateUserRoles(count int) ([]map[string]interface{}, error) {
	var userRoles []map[string]interface{}

	// Validate we have users and roles
	if len(urg.userIDs) == 0 {
		return nil, fmt.Errorf("no user IDs available for user role generation")
	}
	if len(urg.roleIDs) == 0 {
		return nil, fmt.Errorf("no role IDs available for user role generation")
	}

	assignmentReasons := []string{"new_employee_setup", "role_change", "promotion", "department_transfer", "system_initialization"}

	// Track unique combinations to avoid duplicates
	seen := make(map[string]bool)

	for i := 0; i < count; i++ {
		var userID, roleID, tenantID, clientID string
		var uniqueKey string

		// Try to find a unique combination, up to 50 attempts
		attempts := 0
		for attempts < 50 {
			userID = urg.userIDs[rand.Intn(len(urg.userIDs))]
			roleID = urg.roleIDs[rand.Intn(len(urg.roleIDs))]
			tenantID = urg.tenantIDs[rand.Intn(len(urg.tenantIDs))]
			clientID = urg.clientIDs[rand.Intn(len(urg.clientIDs))]

			uniqueKey = fmt.Sprintf("%s-%s-%s-%s", userID, roleID, tenantID, clientID)
			if !seen[uniqueKey] {
				seen[uniqueKey] = true
				break
			}
			attempts++
		}

		// If we couldn't find a unique combination after 50 attempts, skip
		if attempts >= 50 {
			continue
		}

		// Random assignment details
		reason := assignmentReasons[rand.Intn(len(assignmentReasons))]
		assignedAt := time.Now().Add(-time.Duration(rand.Intn(365)+1) * 24 * time.Hour)

		// 10% chance of expiring role
		var expiresAt interface{} = nil
		if rand.Intn(10) == 0 {
			expiresAt = assignedAt.Add(time.Duration(rand.Intn(365)+30) * 24 * time.Hour).Format(time.RFC3339)
		}

		userRole := map[string]interface{}{
			"id":          uuid.New().String(),
			"user_id":     userID,
			"role_id":     roleID,
			"tenant_id":   tenantID,
			"client_id":   clientID,
			"assigned_by": urg.userIDs[rand.Intn(len(urg.userIDs))], // Random assigner
			"assigned_at": assignedAt.Format(time.RFC3339),
			"expires_at":  expiresAt,
			"metadata": map[string]interface{}{
				"reason":           reason,
				"assigned_by_name": "System Administrator",
			},
			"created_at": assignedAt.Format(time.RFC3339),
		}

		userRoles = append(userRoles, userRole)
	}

	return userRoles, nil
}
