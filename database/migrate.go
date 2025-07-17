package database

import (
	"database/sql"
	"fmt"
	"time"

	_ "github.com/lib/pq"
)

// MigratorConfig holds migration tool configuration
type MigratorConfig struct {
	URL             string
	MaxOpenConns    int
	MaxIdleConns    int
	ConnMaxLifetime time.Duration
}

// DefaultMigratorConfig returns default configuration for migrations
func DefaultMigratorConfig() MigratorConfig {
	return MigratorConfig{
		URL:             "postgresql://postgres:postgres@127.0.0.1:54322/postgres?sslmode=disable",
		MaxOpenConns:    25,
		MaxIdleConns:    5,
		ConnMaxLifetime: 5 * time.Minute,
	}
}

// MigratorDB wraps sql.DB with migration-specific functionality
type MigratorDB struct {
	*sql.DB
	config MigratorConfig
}

// NewMigratorConnection creates a new database connection optimized for migrations
func NewMigratorConnection(config MigratorConfig) (*MigratorDB, error) {
	db, err := sql.Open("postgres", config.URL)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	db.SetMaxOpenConns(config.MaxOpenConns)
	db.SetMaxIdleConns(config.MaxIdleConns)
	db.SetConnMaxLifetime(config.ConnMaxLifetime)

	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return &MigratorDB{DB: db, config: config}, nil
}

// WithTransaction executes a function within a database transaction
func (db *MigratorDB) WithTransaction(fn func(*sql.Tx) error) error {
	tx, err := db.Begin()
	if err != nil {
		return err
	}

	defer func() {
		if p := recover(); p != nil {
			tx.Rollback()
			panic(p)
		}
	}()

	if err := fn(tx); err != nil {
		tx.Rollback()
		return err
	}

	return tx.Commit()
}

// EnsureSchemaTable creates the schema_migrations table if it doesn't exist
func (db *MigratorDB) EnsureSchemaTable() error {
	query := `
		CREATE TABLE IF NOT EXISTS schema_migrations (
			version VARCHAR(255) NOT NULL,
			service VARCHAR(100) NOT NULL,
			applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
			PRIMARY KEY (version, service)
		)
	`
	_, err := db.Exec(query)
	return err
}

// IsMigrationApplied checks if a specific migration has been applied
func (db *MigratorDB) IsMigrationApplied(version, service string) (bool, error) {
	var count int
	err := db.QueryRow("SELECT COUNT(*) FROM schema_migrations WHERE version = $1 AND service = $2",
		version, service).Scan(&count)
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

// RecordMigration records that a migration has been applied
func (db *MigratorDB) RecordMigration(version, service string) error {
	_, err := db.Exec("INSERT INTO schema_migrations (version, service) VALUES ($1, $2)",
		version, service)
	return err
}

// RemoveMigrationRecord removes a migration record (for rollbacks)
func (db *MigratorDB) RemoveMigrationRecord(version, service string) error {
	_, err := db.Exec("DELETE FROM schema_migrations WHERE version = $1 AND service = $2",
		version, service)
	return err
}

// GetAppliedMigrations returns all applied migrations for a service
func (db *MigratorDB) GetAppliedMigrations(service string) ([]string, error) {
	rows, err := db.Query("SELECT version FROM schema_migrations WHERE service = $1 ORDER BY applied_at",
		service)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var migrations []string
	for rows.Next() {
		var version string
		if err := rows.Scan(&version); err != nil {
			return nil, err
		}
		migrations = append(migrations, version)
	}

	return migrations, rows.Err()
}
