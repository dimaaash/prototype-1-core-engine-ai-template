package database

import (
	"database/sql"
	"fmt"
	"time"

	_ "github.com/lib/pq"
)

// Connection wraps sql.DB with additional functionality
type Connection struct {
	*sql.DB
}

// NewConnection creates a new database connection
func NewConnection(databaseURL string) (*Connection, error) {
	db, err := sql.Open("postgres", databaseURL)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Configure connection pool
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return &Connection{DB: db}, nil
}

// HasSeederTrackingColumn checks if a table has the created_by_seeder column
func (c *Connection) HasSeederTrackingColumn(tableName string) (bool, error) {
	var exists bool
	query := `SELECT EXISTS (
		SELECT 1 FROM information_schema.columns 
		WHERE table_name = $1 AND column_name = 'created_by_seeder'
	)`
	err := c.QueryRow(query, tableName).Scan(&exists)
	return exists, err
}

// RecordExists checks if a record with the given ID exists in the table
func (c *Connection) RecordExists(tableName string, record map[string]interface{}) (bool, error) {
	if id, exists := record["id"]; exists {
		var count int
		query := fmt.Sprintf("SELECT COUNT(*) FROM %s WHERE id = $1", tableName)
		err := c.QueryRow(query, id).Scan(&count)
		if err != nil {
			return false, err
		}
		return count > 0, nil
	}
	return false, nil
}
