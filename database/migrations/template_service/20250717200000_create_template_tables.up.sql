-- Migration: create_template_tables
-- Service: template
-- Description: Create template management tables with support for global and client-specific templates

-- Template categories for organization
CREATE TABLE template_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    
    -- Category information
    name VARCHAR(100) NOT NULL,
    display_name VARCHAR(200) NOT NULL,
    description TEXT,
    slug VARCHAR(100) NOT NULL,
    
    -- Category hierarchy
    parent_category_id UUID REFERENCES template_categories(id) ON DELETE SET NULL,
    category_level INTEGER DEFAULT 1,
    sort_order INTEGER DEFAULT 0,
    
    -- Visibility and access
    is_global BOOLEAN DEFAULT FALSE, -- Global categories available to all clients
    is_system_category BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Category metadata
    icon VARCHAR(100),
    color VARCHAR(7), -- hex color code
    metadata JSONB DEFAULT '{}',
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID, -- References users(id) - constraint added later
    updated_by UUID, -- References users(id) - constraint added later
    version INTEGER DEFAULT 1,
    
    -- Constraints
    CONSTRAINT template_categories_name_not_empty CHECK (length(trim(name)) > 0),
    CONSTRAINT template_categories_slug_format CHECK (slug ~ '^[a-z0-9\-_]+$'),
    CONSTRAINT template_categories_level_positive CHECK (category_level > 0),
    CONSTRAINT template_categories_global_client CHECK (
        (is_global = TRUE AND client_id IS NULL) OR 
        (is_global = FALSE)
    ),
    
    -- Unique constraints
    UNIQUE(tenant_id, client_id, slug),
    UNIQUE(tenant_id, client_id, name)
);

-- Main templates table
CREATE TABLE templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    category_id UUID REFERENCES template_categories(id) ON DELETE SET NULL,
    
    -- Template identification
    name VARCHAR(200) NOT NULL,
    display_name VARCHAR(300),
    description TEXT,
    slug VARCHAR(200) NOT NULL,
    
    -- Template content
    content TEXT NOT NULL,
    content_type VARCHAR(50) DEFAULT 'handlebars' CHECK (content_type IN ('handlebars', 'mustache', 'go_template', 'jinja2', 'liquid')),
    
    -- Template metadata
    language VARCHAR(50), -- programming language: go, python, javascript, etc
    framework VARCHAR(100), -- framework: gin, fastapi, express, etc
    template_type VARCHAR(50) DEFAULT 'code' CHECK (template_type IN ('code', 'config', 'documentation', 'test', 'deployment')),
    
    -- Version control
    version VARCHAR(50) DEFAULT '1.0.0',
    major_version INTEGER DEFAULT 1,
    minor_version INTEGER DEFAULT 0,
    patch_version INTEGER DEFAULT 0,
    is_latest_version BOOLEAN DEFAULT TRUE,
    parent_template_id UUID REFERENCES templates(id) ON DELETE SET NULL, -- For versioning
    
    -- Visibility and access
    is_global BOOLEAN DEFAULT FALSE, -- Global templates available to all clients
    is_system_template BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    is_published BOOLEAN DEFAULT FALSE,
    is_draft BOOLEAN DEFAULT TRUE,
    
    -- Template characteristics
    complexity_level VARCHAR(20) DEFAULT 'beginner' CHECK (complexity_level IN ('beginner', 'intermediate', 'advanced', 'expert')),
    estimated_time_minutes INTEGER DEFAULT 5,
    
    -- Usage tracking
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMP WITH TIME ZONE,
    
    -- Template validation
    is_validated BOOLEAN DEFAULT FALSE,
    validation_errors JSONB DEFAULT '[]',
    validated_at TIMESTAMP WITH TIME ZONE,
    validated_by UUID, -- References users(id) - constraint added later
    
    -- File information
    file_extension VARCHAR(20),
    output_path VARCHAR(500), -- Default output path for generated files
    
    -- Template variables and configuration
    variables JSONB DEFAULT '{}', -- Template variable definitions
    configuration JSONB DEFAULT '{}', -- Template configuration options
    dependencies JSONB DEFAULT '[]', -- Required dependencies
    tags JSONB DEFAULT '[]', -- Template tags for searchability
    
    -- SEO and discoverability
    keywords TEXT,
    search_vector TSVECTOR,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    published_at TIMESTAMP WITH TIME ZONE,
    created_by UUID, -- References users(id) - constraint added later
    updated_by UUID, -- References users(id) - constraint added later
    published_by UUID, -- References users(id) - constraint added later
    record_version INTEGER DEFAULT 1,
    
    -- Constraints
    CONSTRAINT templates_name_not_empty CHECK (length(trim(name)) > 0),
    CONSTRAINT templates_content_not_empty CHECK (length(trim(content)) > 0),
    CONSTRAINT templates_slug_format CHECK (slug ~ '^[a-z0-9\-_]+$'),
    CONSTRAINT templates_version_valid CHECK (major_version >= 0 AND minor_version >= 0 AND patch_version >= 0),
    CONSTRAINT templates_estimated_time_positive CHECK (estimated_time_minutes > 0),
    CONSTRAINT templates_usage_count_non_negative CHECK (usage_count >= 0),
    CONSTRAINT templates_global_client CHECK (
        (is_global = TRUE AND client_id IS NULL) OR 
        (is_global = FALSE)
    ),
    CONSTRAINT templates_draft_published CHECK (
        NOT (is_draft = TRUE AND is_published = TRUE)
    ),
    
    -- Unique constraints
    UNIQUE(tenant_id, client_id, slug, major_version, minor_version, patch_version),
    UNIQUE(tenant_id, client_id, name, major_version, minor_version, patch_version)
);

-- Template versions table for detailed version history
CREATE TABLE template_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    
    -- Version information
    version VARCHAR(50) NOT NULL,
    major_version INTEGER NOT NULL,
    minor_version INTEGER NOT NULL,
    patch_version INTEGER NOT NULL,
    
    -- Version content snapshot
    content TEXT NOT NULL,
    content_hash VARCHAR(64) NOT NULL, -- SHA-256 hash of content
    
    -- Version metadata
    change_log TEXT,
    breaking_changes BOOLEAN DEFAULT FALSE,
    migration_notes TEXT,
    
    -- Version characteristics
    content_size_bytes INTEGER DEFAULT 0,
    variables JSONB DEFAULT '{}',
    configuration JSONB DEFAULT '{}',
    dependencies JSONB DEFAULT '[]',
    
    -- Version status
    is_stable BOOLEAN DEFAULT FALSE,
    is_deprecated BOOLEAN DEFAULT FALSE,
    deprecated_reason TEXT,
    deprecation_date TIMESTAMP WITH TIME ZONE,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID, -- References users(id) - constraint added later
    
    -- Constraints
    CONSTRAINT template_versions_version_valid CHECK (major_version >= 0 AND minor_version >= 0 AND patch_version >= 0),
    CONSTRAINT template_versions_content_not_empty CHECK (length(trim(content)) > 0),
    CONSTRAINT template_versions_size_non_negative CHECK (content_size_bytes >= 0),
    CONSTRAINT template_versions_deprecated_reason CHECK (
        (is_deprecated = FALSE) OR 
        (is_deprecated = TRUE AND deprecated_reason IS NOT NULL)
    ),
    
    -- Unique constraint
    UNIQUE(template_id, major_version, minor_version, patch_version)
);

-- Template usage tracking
CREATE TABLE template_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    user_id UUID, -- References users(id) - constraint added later
    
    -- Usage information
    used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    template_version VARCHAR(50),
    
    -- Generation context
    generation_context JSONB DEFAULT '{}', -- Variables used during generation
    output_files_count INTEGER DEFAULT 1,
    generation_time_ms INTEGER,
    
    -- Result tracking
    generation_status VARCHAR(20) DEFAULT 'success' CHECK (generation_status IN ('success', 'error', 'partial')),
    error_message TEXT,
    
    -- Session information
    session_id UUID,
    ip_address INET,
    user_agent TEXT,
    
    -- Constraints
    CONSTRAINT template_usage_files_count_positive CHECK (output_files_count > 0),
    CONSTRAINT template_usage_generation_time_non_negative CHECK (generation_time_ms >= 0),
    CONSTRAINT template_usage_error_message CHECK (
        (generation_status = 'success') OR 
        (generation_status IN ('error', 'partial') AND error_message IS NOT NULL)
    )
);

-- Template favorites for users
CREATE TABLE template_favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
    user_id UUID NOT NULL, -- References users(id) - constraint added later
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    
    -- Favorite metadata
    favorited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    
    -- Unique constraint
    UNIQUE(template_id, user_id)
);

-- Template reviews and ratings
CREATE TABLE template_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
    user_id UUID NOT NULL, -- References users(id) - constraint added later
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    
    -- Review content
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(200),
    review_text TEXT,
    
    -- Review metadata
    is_verified_usage BOOLEAN DEFAULT FALSE, -- User actually used the template
    helpful_votes INTEGER DEFAULT 0,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT template_reviews_title_not_empty CHECK (
        title IS NULL OR length(trim(title)) > 0
    ),
    CONSTRAINT template_reviews_helpful_votes_non_negative CHECK (helpful_votes >= 0),
    
    -- Unique constraint - one review per user per template
    UNIQUE(template_id, user_id)
);

-- Template sharing and permissions
CREATE TABLE template_shares (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
    shared_by_user_id UUID NOT NULL, -- References users(id) - constraint added later
    shared_with_user_id UUID, -- References users(id) - constraint added later
    shared_with_client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    
    -- Share permissions
    permission_level VARCHAR(20) DEFAULT 'read' CHECK (permission_level IN ('read', 'edit', 'admin')),
    can_reshare BOOLEAN DEFAULT FALSE,
    
    -- Share metadata
    share_message TEXT,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accessed_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT template_shares_target_specified CHECK (
        (shared_with_user_id IS NOT NULL) OR 
        (shared_with_client_id IS NOT NULL)
    ),
    CONSTRAINT template_shares_expiry_future CHECK (
        expires_at IS NULL OR expires_at > created_at
    )
);

-- Comprehensive indexes for optimal performance
CREATE INDEX idx_template_categories_tenant_client ON template_categories(tenant_id, client_id);
CREATE INDEX idx_template_categories_parent ON template_categories(parent_category_id);
CREATE INDEX idx_template_categories_global ON template_categories(is_global) WHERE is_global = TRUE;
CREATE INDEX idx_template_categories_active ON template_categories(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_template_categories_slug ON template_categories(slug);

CREATE INDEX idx_templates_tenant_client ON templates(tenant_id, client_id);
CREATE INDEX idx_templates_category ON templates(category_id);
CREATE INDEX idx_templates_global ON templates(is_global) WHERE is_global = TRUE;
CREATE INDEX idx_templates_published ON templates(is_published) WHERE is_published = TRUE;
CREATE INDEX idx_templates_active ON templates(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_templates_language ON templates(language);
CREATE INDEX idx_templates_framework ON templates(framework);
CREATE INDEX idx_templates_type ON templates(template_type);
CREATE INDEX idx_templates_complexity ON templates(complexity_level);
CREATE INDEX idx_templates_latest ON templates(is_latest_version) WHERE is_latest_version = TRUE;
CREATE INDEX idx_templates_usage_count ON templates(usage_count);
CREATE INDEX idx_templates_created_at ON templates(created_at);
CREATE INDEX idx_templates_search_vector ON templates USING gin(search_vector);
CREATE INDEX idx_templates_tags ON templates USING gin(tags);
CREATE INDEX idx_templates_slug ON templates(slug);
CREATE INDEX idx_templates_parent ON templates(parent_template_id);

CREATE INDEX idx_template_versions_template ON template_versions(template_id);
CREATE INDEX idx_template_versions_version ON template_versions(major_version, minor_version, patch_version);
CREATE INDEX idx_template_versions_stable ON template_versions(is_stable) WHERE is_stable = TRUE;
CREATE INDEX idx_template_versions_content_hash ON template_versions(content_hash);

CREATE INDEX idx_template_usage_template ON template_usage(template_id);
CREATE INDEX idx_template_usage_user ON template_usage(user_id);
CREATE INDEX idx_template_usage_used_at ON template_usage(used_at);
CREATE INDEX idx_template_usage_status ON template_usage(generation_status);
CREATE INDEX idx_template_usage_tenant_client ON template_usage(tenant_id, client_id);

CREATE INDEX idx_template_favorites_user ON template_favorites(user_id);
CREATE INDEX idx_template_favorites_template ON template_favorites(template_id);
CREATE INDEX idx_template_favorites_favorited_at ON template_favorites(favorited_at);

CREATE INDEX idx_template_reviews_template ON template_reviews(template_id);
CREATE INDEX idx_template_reviews_user ON template_reviews(user_id);
CREATE INDEX idx_template_reviews_rating ON template_reviews(rating);
CREATE INDEX idx_template_reviews_verified ON template_reviews(is_verified_usage) WHERE is_verified_usage = TRUE;

CREATE INDEX idx_template_shares_template ON template_shares(template_id);
CREATE INDEX idx_template_shares_shared_by ON template_shares(shared_by_user_id);
CREATE INDEX idx_template_shares_shared_with_user ON template_shares(shared_with_user_id);
CREATE INDEX idx_template_shares_shared_with_client ON template_shares(shared_with_client_id);
CREATE INDEX idx_template_shares_permission ON template_shares(permission_level);
CREATE INDEX idx_template_shares_expires ON template_shares(expires_at) WHERE expires_at IS NOT NULL;

-- Search index for full-text search
CREATE INDEX idx_templates_search_text ON templates USING gin(to_tsvector('english', 
    coalesce(name, '') || ' ' || 
    coalesce(display_name, '') || ' ' || 
    coalesce(description, '') || ' ' || 
    coalesce(keywords, '')
));

-- Triggers for automatic updates
CREATE TRIGGER trigger_template_categories_updated_at 
    BEFORE UPDATE ON template_categories 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_templates_updated_at 
    BEFORE UPDATE ON templates 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_template_reviews_updated_at 
    BEFORE UPDATE ON template_reviews 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger to update search vector on template changes
CREATE OR REPLACE FUNCTION update_template_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector := to_tsvector('english', 
        coalesce(NEW.name, '') || ' ' || 
        coalesce(NEW.display_name, '') || ' ' || 
        coalesce(NEW.description, '') || ' ' || 
        coalesce(NEW.keywords, '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_templates_search_vector
    BEFORE INSERT OR UPDATE ON templates
    FOR EACH ROW EXECUTE FUNCTION update_template_search_vector();

-- Insert default template categories
INSERT INTO template_categories (tenant_id, name, display_name, description, slug, is_global, is_system_category) 
SELECT 
    t.id,
    'web-development',
    'Web Development',
    'Templates for web application development',
    'web-development',
    TRUE,
    TRUE
FROM tenants t
ON CONFLICT (tenant_id, client_id, slug) DO NOTHING;

INSERT INTO template_categories (tenant_id, name, display_name, description, slug, is_global, is_system_category) 
SELECT 
    t.id,
    'api-development',
    'API Development',
    'Templates for API and microservice development',
    'api-development',
    TRUE,
    TRUE
FROM tenants t
ON CONFLICT (tenant_id, client_id, slug) DO NOTHING;

INSERT INTO template_categories (tenant_id, name, display_name, description, slug, is_global, is_system_category) 
SELECT 
    t.id,
    'database',
    'Database',
    'Database-related templates and migrations',
    'database',
    TRUE,
    TRUE
FROM tenants t
ON CONFLICT (tenant_id, client_id, slug) DO NOTHING;

INSERT INTO template_categories (tenant_id, name, display_name, description, slug, is_global, is_system_category) 
SELECT 
    t.id,
    'frontend',
    'Frontend',
    'Frontend application templates',
    'frontend',
    TRUE,
    TRUE
FROM tenants t
ON CONFLICT (tenant_id, client_id, slug) DO NOTHING;

INSERT INTO template_categories (tenant_id, name, display_name, description, slug, is_global, is_system_category) 
SELECT 
    t.id,
    'backend',
    'Backend',
    'Backend service templates',
    'backend',
    TRUE,
    TRUE
FROM tenants t
ON CONFLICT (tenant_id, client_id, slug) DO NOTHING;

INSERT INTO template_categories (tenant_id, name, display_name, description, slug, is_global, is_system_category) 
SELECT 
    t.id,
    'devops',
    'DevOps',
    'DevOps and deployment templates',
    'devops',
    TRUE,
    TRUE
FROM tenants t
ON CONFLICT (tenant_id, client_id, slug) DO NOTHING;
