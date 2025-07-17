package database

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/lib/pq"
)

// ProcessValue handles the conversion of values for database insertion
func (c *Connection) ProcessValue(value interface{}) (interface{}, error) {
	switch v := value.(type) {
	case []interface{}:
		// Check if it's a string array (for PostgreSQL TEXT[] columns)
		if allStrings := true; len(v) > 0 {
			for _, item := range v {
				if _, isString := item.(string); !isString {
					allStrings = false
					break
				}
			}
			if allStrings {
				// Convert to PostgreSQL array format using pq.Array
				var pgArray []string
				for _, item := range v {
					pgArray = append(pgArray, item.(string))
				}
				return pq.Array(pgArray), nil
			}
		}
		// Convert other arrays to JSON
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
		// Handle string slices as PostgreSQL arrays
		return pq.Array(v), nil
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
