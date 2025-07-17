package models

// SeedData represents the structure for seed data files
type SeedData struct {
	Service      string                   `json:"service"`
	Table        string                   `json:"table"`
	Description  string                   `json:"description"`
	Data         []map[string]interface{} `json:"data"`
	Dependencies []string                 `json:"dependencies,omitempty"`
}

// CategoryRef represents a category reference for generators
type CategoryRef struct {
	ID   string
	Name string
}

// TenantRef represents a tenant reference
type TenantRef struct {
	ID   string
	Name string
}

// ClientRef represents a client reference
type ClientRef struct {
	ID   string
	Name string
}

// RoleRef represents a role reference
type RoleRef struct {
	ID   string
	Name string
}

// UserRef represents a user reference
type UserRef struct {
	ID   string
	Name string
}

// WarehouseRef represents a warehouse reference
type WarehouseRef struct {
	ID   string
	Name string
}
