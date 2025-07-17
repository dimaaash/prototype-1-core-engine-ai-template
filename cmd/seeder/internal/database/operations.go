package database

import (
	"encoding/json"
	"fmt"
	"strings"
)

// ProcessValue handles the conversion of values for database insertion
func (c *Connection) ProcessValue(value interface{}) (interface{}, error) {
	switch v := value.(type) {
	case []interface{}:
		// Convert arrays to JSON (for JSONB columns)
		jsonBytes, err := json.Marshal(v)
		if err != nil {
			return nil, err
		}
		return string(jsonBytes), nil
	case map[string]interface{}:
		// Convert objects to JSON
		jsonBytes, err := json.Marshal(v)
		if err != nil {
			return nil, err
		}
		return string(jsonBytes), nil
	case []string:
		// Convert string arrays to JSON (for JSONB columns)
		jsonBytes, err := json.Marshal(v)
		if err != nil {
			return nil, err
		}
		return string(jsonBytes), nil
	default:
		return v, nil
	}
}

// InsertRecord inserts a single record into the specified table
func (c *Connection) InsertRecord(tableName string, record map[string]interface{}) error {
	// Check if table has created_by_seeder column before adding it
	hasSeederColumn, err := c.HasSeederTrackingColumn(tableName)
	if err == nil && hasSeederColumn {
		record["created_by_seeder"] = true
	}

	// Build INSERT query
	var columns []string
	var placeholders []string
	var values []interface{}

	i := 1
	for column, value := range record {
		columns = append(columns, column)
		placeholders = append(placeholders, fmt.Sprintf("$%d", i))

		// Handle JSON fields by marshaling complex types
		processedValue, err := c.ProcessValue(value)
		if err != nil {
			return fmt.Errorf("failed to process value for column %s: %w", column, err)
		}

		values = append(values, processedValue)
		i++
	}

	query := fmt.Sprintf("INSERT INTO %s (%s) VALUES (%s)",
		tableName,
		strings.Join(columns, ", "),
		strings.Join(placeholders, ", "))

	_, err = c.Exec(query, values...)
	return err
}
