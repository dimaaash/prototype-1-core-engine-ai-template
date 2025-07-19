package infrastructure

import (
	"database/sql"
	"fmt"

	"go-factory-platform/services/template-service/internal/domain"

	_ "github.com/lib/pq"
)

// PostgreSQLPublicTemplateRepository implements PublicTemplateRepository using PostgreSQL
type PostgreSQLPublicTemplateRepository struct {
	db *sql.DB
}

// NewPostgreSQLPublicTemplateRepository creates a new PostgreSQL public template repository
func NewPostgreSQLPublicTemplateRepository(dsn string) (*PostgreSQLPublicTemplateRepository, error) {
	// Create database connection
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open database connection: %w", err)
	}

	// Test the connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return &PostgreSQLPublicTemplateRepository{
		db: db,
	}, nil
}

// GetByID retrieves a public template by ID
func (r *PostgreSQLPublicTemplateRepository) GetByID(id string) (*domain.PublicTemplate, error) {
	query := `
		SELECT id, name, display_name, description, slug, template_category, template_type, 
		       content, content_type, language, framework, version, major_version, 
		       minor_version, patch_version, is_latest_version, is_active, is_published, 
		       is_featured, complexity_level, estimated_time_minutes, usage_count, 
		       like_count, file_extension, output_path, variables, configuration, 
		       dependencies, tags, keywords, created_at, updated_at, published_at
		FROM public_templates 
		WHERE id = $1 AND is_active = true`

	template := &domain.PublicTemplate{}
	var publishedAt sql.NullTime

	err := r.db.QueryRow(query, id).Scan(
		&template.ID, &template.Name, &template.DisplayName, &template.Description,
		&template.Slug, &template.TemplateCategory, &template.TemplateType,
		&template.Content, &template.ContentType, &template.Language, &template.Framework,
		&template.Version, &template.MajorVersion, &template.MinorVersion, &template.PatchVersion,
		&template.IsLatestVersion, &template.IsActive, &template.IsPublished, &template.IsFeatured,
		&template.ComplexityLevel, &template.EstimatedTime, &template.UsageCount, &template.LikeCount,
		&template.FileExtension, &template.OutputPath, &template.Variables, &template.Configuration,
		&template.Dependencies, &template.Tags, &template.Keywords, &template.CreatedAt,
		&template.UpdatedAt, &publishedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("public template with ID %s not found", id)
		}
		return nil, fmt.Errorf("failed to get public template by ID: %w", err)
	}

	if publishedAt.Valid {
		template.PublishedAt = &publishedAt.Time
	}

	return template, nil
}

// GetBySlug retrieves a public template by slug
func (r *PostgreSQLPublicTemplateRepository) GetBySlug(slug string) (*domain.PublicTemplate, error) {
	query := `
		SELECT id, name, display_name, description, slug, template_category, template_type, 
		       content, content_type, language, framework, version, major_version, 
		       minor_version, patch_version, is_latest_version, is_active, is_published, 
		       is_featured, complexity_level, estimated_time_minutes, usage_count, 
		       like_count, file_extension, output_path, variables, configuration, 
		       dependencies, tags, keywords, created_at, updated_at, published_at
		FROM public_templates 
		WHERE slug = $1 AND is_active = true AND is_published = true`

	template := &domain.PublicTemplate{}
	var publishedAt sql.NullTime

	err := r.db.QueryRow(query, slug).Scan(
		&template.ID, &template.Name, &template.DisplayName, &template.Description,
		&template.Slug, &template.TemplateCategory, &template.TemplateType,
		&template.Content, &template.ContentType, &template.Language, &template.Framework,
		&template.Version, &template.MajorVersion, &template.MinorVersion, &template.PatchVersion,
		&template.IsLatestVersion, &template.IsActive, &template.IsPublished, &template.IsFeatured,
		&template.ComplexityLevel, &template.EstimatedTime, &template.UsageCount, &template.LikeCount,
		&template.FileExtension, &template.OutputPath, &template.Variables, &template.Configuration,
		&template.Dependencies, &template.Tags, &template.Keywords, &template.CreatedAt,
		&template.UpdatedAt, &publishedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("public template with slug %s not found", slug)
		}
		return nil, fmt.Errorf("failed to get public template by slug: %w", err)
	}

	if publishedAt.Valid {
		template.PublishedAt = &publishedAt.Time
	}

	return template, nil
}

// GetAll retrieves all active public templates
func (r *PostgreSQLPublicTemplateRepository) GetAll() ([]*domain.PublicTemplate, error) {
	query := `
		SELECT id, name, display_name, description, slug, template_category, template_type, 
		       content, content_type, language, framework, version, major_version, 
		       minor_version, patch_version, is_latest_version, is_active, is_published, 
		       is_featured, complexity_level, estimated_time_minutes, usage_count, 
		       like_count, file_extension, output_path, variables, configuration, 
		       dependencies, tags, keywords, created_at, updated_at, published_at
		FROM public_templates 
		WHERE is_active = true 
		ORDER BY created_at DESC`

	return r.scanTemplates(query)
}

// GetPublished retrieves all published public templates
func (r *PostgreSQLPublicTemplateRepository) GetPublished() ([]*domain.PublicTemplate, error) {
	query := `
		SELECT id, name, display_name, description, slug, template_category, template_type, 
		       content, content_type, language, framework, version, major_version, 
		       minor_version, patch_version, is_latest_version, is_active, is_published, 
		       is_featured, complexity_level, estimated_time_minutes, usage_count, 
		       like_count, file_extension, output_path, variables, configuration, 
		       dependencies, tags, keywords, created_at, updated_at, published_at
		FROM public_templates 
		WHERE is_active = true AND is_published = true 
		ORDER BY is_featured DESC, like_count DESC, usage_count DESC, created_at DESC`

	return r.scanTemplates(query)
}

// GetByCategory retrieves public templates by category
func (r *PostgreSQLPublicTemplateRepository) GetByCategory(category string) ([]*domain.PublicTemplate, error) {
	query := `
		SELECT id, name, display_name, description, slug, template_category, template_type, 
		       content, content_type, language, framework, version, major_version, 
		       minor_version, patch_version, is_latest_version, is_active, is_published, 
		       is_featured, complexity_level, estimated_time_minutes, usage_count, 
		       like_count, file_extension, output_path, variables, configuration, 
		       dependencies, tags, keywords, created_at, updated_at, published_at
		FROM public_templates 
		WHERE template_category = $1 AND is_active = true AND is_published = true 
		ORDER BY is_featured DESC, like_count DESC, usage_count DESC`

	return r.scanTemplatesWithArgs(query, category)
}

// GetByLanguage retrieves public templates by programming language
func (r *PostgreSQLPublicTemplateRepository) GetByLanguage(language string) ([]*domain.PublicTemplate, error) {
	query := `
		SELECT id, name, display_name, description, slug, template_category, template_type, 
		       content, content_type, language, framework, version, major_version, 
		       minor_version, patch_version, is_latest_version, is_active, is_published, 
		       is_featured, complexity_level, estimated_time_minutes, usage_count, 
		       like_count, file_extension, output_path, variables, configuration, 
		       dependencies, tags, keywords, created_at, updated_at, published_at
		FROM public_templates 
		WHERE language = $1 AND is_active = true AND is_published = true 
		ORDER BY is_featured DESC, like_count DESC, usage_count DESC`

	return r.scanTemplatesWithArgs(query, language)
}

// GetByFramework retrieves public templates by framework
func (r *PostgreSQLPublicTemplateRepository) GetByFramework(framework string) ([]*domain.PublicTemplate, error) {
	query := `
		SELECT id, name, display_name, description, slug, template_category, template_type, 
		       content, content_type, language, framework, version, major_version, 
		       minor_version, patch_version, is_latest_version, is_active, is_published, 
		       is_featured, complexity_level, estimated_time_minutes, usage_count, 
		       like_count, file_extension, output_path, variables, configuration, 
		       dependencies, tags, keywords, created_at, updated_at, published_at
		FROM public_templates 
		WHERE framework = $1 AND is_active = true AND is_published = true 
		ORDER BY is_featured DESC, like_count DESC, usage_count DESC`

	return r.scanTemplatesWithArgs(query, framework)
}

// GetByType retrieves public templates by template type
func (r *PostgreSQLPublicTemplateRepository) GetByType(templateType string) ([]*domain.PublicTemplate, error) {
	query := `
		SELECT id, name, display_name, description, slug, template_category, template_type, 
		       content, content_type, language, framework, version, major_version, 
		       minor_version, patch_version, is_latest_version, is_active, is_published, 
		       is_featured, complexity_level, estimated_time_minutes, usage_count, 
		       like_count, file_extension, output_path, variables, configuration, 
		       dependencies, tags, keywords, created_at, updated_at, published_at
		FROM public_templates 
		WHERE template_type = $1 AND is_active = true AND is_published = true 
		ORDER BY is_featured DESC, like_count DESC, usage_count DESC`

	return r.scanTemplatesWithArgs(query, templateType)
}

// Search performs full-text search on public templates
func (r *PostgreSQLPublicTemplateRepository) Search(query string) ([]*domain.PublicTemplate, error) {
	searchQuery := `
		SELECT id, name, display_name, description, slug, template_category, template_type, 
		       content, content_type, language, framework, version, major_version, 
		       minor_version, patch_version, is_latest_version, is_active, is_published, 
		       is_featured, complexity_level, estimated_time_minutes, usage_count, 
		       like_count, file_extension, output_path, variables, configuration, 
		       dependencies, tags, keywords, created_at, updated_at, published_at
		FROM public_templates 
		WHERE search_vector @@ plainto_tsquery('english', $1) AND is_active = true AND is_published = true 
		ORDER BY is_featured DESC, like_count DESC, usage_count DESC`

	return r.scanTemplatesWithArgs(searchQuery, query)
}

// GetFeatured retrieves featured public templates
func (r *PostgreSQLPublicTemplateRepository) GetFeatured() ([]*domain.PublicTemplate, error) {
	query := `
		SELECT id, name, display_name, description, slug, template_category, template_type, 
		       content, content_type, language, framework, version, major_version, 
		       minor_version, patch_version, is_latest_version, is_active, is_published, 
		       is_featured, complexity_level, estimated_time_minutes, usage_count, 
		       like_count, file_extension, output_path, variables, configuration, 
		       dependencies, tags, keywords, created_at, updated_at, published_at
		FROM public_templates 
		WHERE is_featured = true AND is_active = true AND is_published = true 
		ORDER BY like_count DESC, usage_count DESC`

	return r.scanTemplates(query)
}

// GetMostPopular retrieves the most popular public templates
func (r *PostgreSQLPublicTemplateRepository) GetMostPopular(limit int) ([]*domain.PublicTemplate, error) {
	query := `
		SELECT id, name, display_name, description, slug, template_category, template_type, 
		       content, content_type, language, framework, version, major_version, 
		       minor_version, patch_version, is_latest_version, is_active, is_published, 
		       is_featured, complexity_level, estimated_time_minutes, usage_count, 
		       like_count, file_extension, output_path, variables, configuration, 
		       dependencies, tags, keywords, created_at, updated_at, published_at
		FROM public_templates 
		WHERE is_active = true AND is_published = true 
		ORDER BY (like_count * 2 + usage_count) DESC 
		LIMIT $1`

	return r.scanTemplatesWithArgs(query, limit)
}

// IncrementUsageCount increments the usage count for a template
func (r *PostgreSQLPublicTemplateRepository) IncrementUsageCount(id string) error {
	query := `UPDATE public_templates SET usage_count = usage_count + 1 WHERE id = $1 AND is_active = true`

	result, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("failed to increment usage count: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to get rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("template with ID %s not found or inactive", id)
	}

	return nil
}

// scanTemplates is a helper function to scan multiple templates from a query without arguments
func (r *PostgreSQLPublicTemplateRepository) scanTemplates(query string) ([]*domain.PublicTemplate, error) {
	rows, err := r.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("failed to execute query: %w", err)
	}
	defer rows.Close()

	return r.scanTemplateRows(rows)
}

// scanTemplatesWithArgs is a helper function to scan multiple templates from a query with arguments
func (r *PostgreSQLPublicTemplateRepository) scanTemplatesWithArgs(query string, args ...interface{}) ([]*domain.PublicTemplate, error) {
	rows, err := r.db.Query(query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to execute query: %w", err)
	}
	defer rows.Close()

	return r.scanTemplateRows(rows)
}

// scanTemplateRows scans rows into PublicTemplate structs
func (r *PostgreSQLPublicTemplateRepository) scanTemplateRows(rows *sql.Rows) ([]*domain.PublicTemplate, error) {
	var templates []*domain.PublicTemplate

	for rows.Next() {
		template := &domain.PublicTemplate{}
		var publishedAt sql.NullTime

		err := rows.Scan(
			&template.ID, &template.Name, &template.DisplayName, &template.Description,
			&template.Slug, &template.TemplateCategory, &template.TemplateType,
			&template.Content, &template.ContentType, &template.Language, &template.Framework,
			&template.Version, &template.MajorVersion, &template.MinorVersion, &template.PatchVersion,
			&template.IsLatestVersion, &template.IsActive, &template.IsPublished, &template.IsFeatured,
			&template.ComplexityLevel, &template.EstimatedTime, &template.UsageCount, &template.LikeCount,
			&template.FileExtension, &template.OutputPath, &template.Variables, &template.Configuration,
			&template.Dependencies, &template.Tags, &template.Keywords, &template.CreatedAt,
			&template.UpdatedAt, &publishedAt,
		)

		if err != nil {
			return nil, fmt.Errorf("failed to scan template row: %w", err)
		}

		if publishedAt.Valid {
			template.PublishedAt = &publishedAt.Time
		}

		templates = append(templates, template)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating rows: %w", err)
	}

	return templates, nil
}
