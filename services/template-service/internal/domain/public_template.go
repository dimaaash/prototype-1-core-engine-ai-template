package domain

import (
	"time"
)

// PublicTemplate represents a public template available to all users
type PublicTemplate struct {
	ID               string     `json:"id" gorm:"column:id;primaryKey"`
	Name             string     `json:"name" gorm:"column:name"`
	DisplayName      string     `json:"display_name" gorm:"column:display_name"`
	Description      string     `json:"description" gorm:"column:description"`
	Slug             string     `json:"slug" gorm:"column:slug;uniqueIndex"`
	TemplateCategory string     `json:"template_category" gorm:"column:template_category"`
	TemplateType     string     `json:"template_type" gorm:"column:template_type"`
	Content          string     `json:"content" gorm:"column:content"`
	ContentType      string     `json:"content_type" gorm:"column:content_type"`
	Language         string     `json:"language" gorm:"column:language"`
	Framework        string     `json:"framework" gorm:"column:framework"`
	Version          string     `json:"version" gorm:"column:version"`
	MajorVersion     int        `json:"major_version" gorm:"column:major_version"`
	MinorVersion     int        `json:"minor_version" gorm:"column:minor_version"`
	PatchVersion     int        `json:"patch_version" gorm:"column:patch_version"`
	IsLatestVersion  bool       `json:"is_latest_version" gorm:"column:is_latest_version"`
	IsActive         bool       `json:"is_active" gorm:"column:is_active"`
	IsPublished      bool       `json:"is_published" gorm:"column:is_published"`
	IsFeatured       bool       `json:"is_featured" gorm:"column:is_featured"`
	ComplexityLevel  string     `json:"complexity_level" gorm:"column:complexity_level"`
	EstimatedTime    int        `json:"estimated_time_minutes" gorm:"column:estimated_time_minutes"`
	UsageCount       int        `json:"usage_count" gorm:"column:usage_count"`
	LikeCount        int        `json:"like_count" gorm:"column:like_count"`
	FileExtension    string     `json:"file_extension" gorm:"column:file_extension"`
	OutputPath       string     `json:"output_path" gorm:"column:output_path"`
	Variables        string     `json:"variables" gorm:"column:variables;type:jsonb"` // JSONB stored as string
	Configuration    string     `json:"configuration" gorm:"column:configuration;type:jsonb"`
	Dependencies     string     `json:"dependencies" gorm:"column:dependencies;type:jsonb"`
	Tags             string     `json:"tags" gorm:"column:tags;type:jsonb"`
	Keywords         string     `json:"keywords" gorm:"column:keywords"`
	CreatedAt        time.Time  `json:"created_at" gorm:"column:created_at"`
	UpdatedAt        time.Time  `json:"updated_at" gorm:"column:updated_at"`
	PublishedAt      *time.Time `json:"published_at" gorm:"column:published_at"`
}

// TableName returns the table name for GORM
func (PublicTemplate) TableName() string {
	return "public_templates"
}

// PublicTemplateRepository defines the interface for public template operations
type PublicTemplateRepository interface {
	// Basic CRUD operations
	GetByID(id string) (*PublicTemplate, error)
	GetBySlug(slug string) (*PublicTemplate, error)
	GetAll() ([]*PublicTemplate, error)
	GetPublished() ([]*PublicTemplate, error)

	// Category and filtering
	GetByCategory(category string) ([]*PublicTemplate, error)
	GetByLanguage(language string) ([]*PublicTemplate, error)
	GetByFramework(framework string) ([]*PublicTemplate, error)
	GetByType(templateType string) ([]*PublicTemplate, error)

	// Search functionality
	Search(query string) ([]*PublicTemplate, error)
	GetFeatured() ([]*PublicTemplate, error)
	GetMostPopular(limit int) ([]*PublicTemplate, error)

	// Usage tracking
	IncrementUsageCount(id string) error
}
