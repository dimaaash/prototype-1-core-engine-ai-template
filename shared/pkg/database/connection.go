package database

import (
	"database/sql"
	"fmt"
	"log"
	"time"

	_ "github.com/lib/pq"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// Config holds database configuration
type Config struct {
	Host            string
	Port            int
	User            string
	Password        string
	Database        string
	SSLMode         string
	MaxOpenConns    int
	MaxIdleConns    int
	ConnMaxLifetime time.Duration
}

// Connection holds database connections
type Connection struct {
	DB     *gorm.DB
	SqlDB  *sql.DB
	Config *Config
}

// NewConnection creates a new database connection
func NewConnection(config *Config) (*Connection, error) {
	dsn := fmt.Sprintf(
		"host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		config.Host,
		config.Port,
		config.User,
		config.Password,
		config.Database,
		config.SSLMode,
	)

	// Configure GORM logger
	newLogger := logger.New(
		log.New(log.Writer(), "\r\n", log.LstdFlags),
		logger.Config{
			SlowThreshold:             time.Second,
			LogLevel:                  logger.Info,
			IgnoreRecordNotFoundError: true,
			Colorful:                  true,
		},
	)

	// Open GORM connection
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: newLogger,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	// Get underlying sql.DB for connection pooling
	sqlDB, err := db.DB()
	if err != nil {
		return nil, fmt.Errorf("failed to get underlying sql.DB: %w", err)
	}

	// Configure connection pool
	sqlDB.SetMaxOpenConns(config.MaxOpenConns)
	sqlDB.SetMaxIdleConns(config.MaxIdleConns)
	sqlDB.SetConnMaxLifetime(config.ConnMaxLifetime)

	// Test connection
	if err := sqlDB.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return &Connection{
		DB:     db,
		SqlDB:  sqlDB,
		Config: config,
	}, nil
}

// Close closes the database connection
func (c *Connection) Close() error {
	if c.SqlDB != nil {
		return c.SqlDB.Close()
	}
	return nil
}

// Health checks database connection health
func (c *Connection) Health() error {
	if c.SqlDB == nil {
		return fmt.Errorf("database connection is nil")
	}
	return c.SqlDB.Ping()
}

// GetStats returns database connection statistics
func (c *Connection) GetStats() sql.DBStats {
	if c.SqlDB == nil {
		return sql.DBStats{}
	}
	return c.SqlDB.Stats()
}

// WithTransaction executes a function within a database transaction
func (c *Connection) WithTransaction(fn func(*sql.Tx) error) error {
	if c.SqlDB == nil {
		return fmt.Errorf("database connection is nil")
	}

	tx, err := c.SqlDB.Begin()
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
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
