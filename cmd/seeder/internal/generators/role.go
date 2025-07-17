package generators

import (
	"fmt"
	"math/rand"
	"time"

	"github.com/google/uuid"
)

// RoleGenerator handles fake role generation
type RoleGenerator struct {
	tenantIDs []string
	clientIDs []string
}

// NewRoleGenerator creates a new role generator
func NewRoleGenerator(tenantIDs, clientIDs []string) *RoleGenerator {
	return &RoleGenerator{
		tenantIDs: tenantIDs,
		clientIDs: clientIDs,
	}
}

// GenerateRoles creates realistic fake role data
func (rg *RoleGenerator) GenerateRoles(count int) ([]map[string]interface{}, error) {
	var roles []map[string]interface{}

	roleTemplates := []struct {
		name        string
		displayName string
		description string
		category    string
		level       int
		isAdmin     bool
		isDefault   bool
	}{
		{"platform_admin", "Platform Administrator", "Full administrative access to the Go Factory Platform", "admin", 5, true, false},
		{"tenant_admin", "Tenant Administrator", "Administrative access within tenant scope", "admin", 4, false, false},
		{"project_manager", "Project Manager", "Management access for project operations", "operational", 3, false, false},
		{"developer", "Developer", "Developer access for code generation and templates", "operational", 2, false, false},
		{"template_creator", "Template Creator", "Access to create and manage templates", "operational", 2, false, false},
		{"code_reviewer", "Code Reviewer", "Access to review generated code and projects", "operational", 2, false, false},
		{"operator", "Platform Operator", "Basic operational access for platform usage", "operational", 1, false, false},
		{"shift_supervisor", "Shift Supervisor", "Supervisor access for shift operations", "operational", 2, false, false},
		{"quality_controller", "Quality Controller", "Quality control and assurance role", "quality", 2, false, false},
		{"logistics_coordinator", "Logistics Coordinator", "Coordination role for logistics operations", "logistics", 2, false, false},
		{"receiving_clerk", "Receiving Clerk", "Clerk level access for receiving operations", "operational", 1, false, false},
		{"shipping_clerk", "Shipping Clerk", "Clerk level access for shipping operations", "operational", 1, false, false},
		{"client_admin", "Client Administrator", "Administrative access for specific client", "administrative", 2, true, false},
		{"user", "User", "Basic user access for platform usage", "operational", 1, false, true},
		{"data_analyst", "Data Analyst", "Analyst role for data and reporting", "analytical", 2, false, false},
		{"maintenance_tech", "Maintenance Technician", "Technical role for equipment maintenance", "technical", 2, false, false},
	}

	for i := 0; i < count; i++ {
		template := roleTemplates[i%len(roleTemplates)]

		// Select random tenant and sometimes client
		tenantID := rg.tenantIDs[rand.Intn(len(rg.tenantIDs))]
		var clientID interface{} = nil

		// 30% chance of client-specific role
		if rand.Intn(10) < 3 && len(rg.clientIDs) > 0 {
			clientID = rg.clientIDs[rand.Intn(len(rg.clientIDs))]
		}

		// Add variation to role name if generating multiple
		roleName := template.name
		displayName := template.displayName
		if i >= len(roleTemplates) {
			suffix := fmt.Sprintf("_%d", (i/len(roleTemplates))+1)
			roleName += suffix
			displayName += fmt.Sprintf(" %d", (i/len(roleTemplates))+1)
		}

		role := map[string]interface{}{
			"id":                  uuid.New().String(),
			"tenant_id":           tenantID,
			"client_id":           clientID,
			"name":                roleName,
			"display_name":        displayName,
			"description":         template.description,
			"parent_role_id":      nil,
			"role_level":          template.level,
			"is_system_role":      false,
			"is_admin_role":       template.isAdmin,
			"is_default_role":     template.isDefault,
			"is_active":           rg.getRoleStatus(i),
			"inherit_permissions": true,
			"metadata": map[string]interface{}{
				"category":   template.category,
				"created_by": "seeder",
			},
			"created_at": time.Now().Add(-time.Duration(rand.Intn(365)+1) * 24 * time.Hour).Format(time.RFC3339),
			"updated_at": time.Now().Add(-time.Duration(rand.Intn(30)+1) * 24 * time.Hour).Format(time.RFC3339),
		}

		// Add scope for client-specific roles
		if clientID != nil {
			role["metadata"].(map[string]interface{})["scope"] = "client"
		}

		roles = append(roles, role)
	}

	return roles, nil
}

func (rg *RoleGenerator) getRoleStatus(index int) bool {
	return index%20 != 0 // 95% active
}
