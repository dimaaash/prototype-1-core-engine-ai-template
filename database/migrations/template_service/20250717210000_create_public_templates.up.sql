-- Migration: create_public_templates
-- Service: template
-- Description: Create public templates table for generic/free-for-all templates that don't belong to any tenant or client

-- Public template categories for organization
CREATE TABLE public_template_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Category information
    name VARCHAR(100) NOT NULL UNIQUE,
    display_name VARCHAR(200) NOT NULL,
    description TEXT,
    slug VARCHAR(100) NOT NULL UNIQUE,
    
    -- Category hierarchy
    parent_category_id UUID REFERENCES public_template_categories(id) ON DELETE SET NULL,
    category_level INTEGER DEFAULT 1,
    sort_order INTEGER DEFAULT 0,
    
    -- Category metadata
    icon VARCHAR(100),
    color VARCHAR(7), -- hex color code
    metadata JSONB DEFAULT '{}',
    
    -- Category visibility
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID, -- References users(id) - constraint added later
    updated_by UUID, -- References users(id) - constraint added later
    version INTEGER DEFAULT 1,
    
    -- Constraints
    CONSTRAINT public_template_categories_name_not_empty CHECK (length(trim(name)) > 0),
    CONSTRAINT public_template_categories_slug_format CHECK (slug ~ '^[a-z0-9\-_]+$'),
    CONSTRAINT public_template_categories_level_positive CHECK (category_level > 0)
);

-- Public templates table - free for all, no tenant/client restrictions
CREATE TABLE public_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID REFERENCES public_template_categories(id) ON DELETE SET NULL,
    
    -- Template identification
    name VARCHAR(200) NOT NULL,
    display_name VARCHAR(300),
    description TEXT,
    slug VARCHAR(200) NOT NULL UNIQUE,
    
    -- Template classification
    template_category VARCHAR(100) NOT NULL DEFAULT 'general', -- Custom field for template categorization
    template_type VARCHAR(50) DEFAULT 'code' CHECK (template_type IN ('code', 'config', 'documentation', 'test', 'deployment', 'snippet', 'boilerplate')),
    
    -- Template content
    content TEXT NOT NULL,
    content_type VARCHAR(50) DEFAULT 'handlebars' CHECK (content_type IN ('handlebars', 'mustache', 'go_template', 'jinja2', 'liquid', 'plaintext')),
    
    -- Template metadata
    language VARCHAR(50), -- programming language: go, python, javascript, etc
    framework VARCHAR(100), -- framework: gin, fastapi, express, etc
    
    -- Version control
    version VARCHAR(50) DEFAULT '1.0.0',
    major_version INTEGER DEFAULT 1,
    minor_version INTEGER DEFAULT 0,
    patch_version INTEGER DEFAULT 0,
    is_latest_version BOOLEAN DEFAULT TRUE,
    parent_template_id UUID REFERENCES public_templates(id) ON DELETE SET NULL, -- For versioning
    
    -- Template status
    is_active BOOLEAN DEFAULT TRUE,
    is_published BOOLEAN DEFAULT FALSE,
    is_draft BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE, -- Highlight popular templates
    
    -- Template characteristics
    complexity_level VARCHAR(20) DEFAULT 'beginner' CHECK (complexity_level IN ('beginner', 'intermediate', 'advanced', 'expert')),
    estimated_time_minutes INTEGER DEFAULT 5,
    
    -- Usage and popularity tracking
    usage_count INTEGER DEFAULT 0,
    download_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMP WITH TIME ZONE,
    
    -- Template validation
    is_validated BOOLEAN DEFAULT FALSE,
    validation_errors JSONB DEFAULT '[]',
    validated_at TIMESTAMP WITH TIME ZONE,
    validated_by UUID, -- References users(id) - constraint added later
    
    -- File information
    file_extension VARCHAR(20),
    output_path VARCHAR(500), -- Default output path for generated files
    preview_image_url VARCHAR(1000), -- Optional preview image
    
    -- Template variables and configuration
    variables JSONB DEFAULT '{}', -- Template variable definitions
    configuration JSONB DEFAULT '{}', -- Template configuration options
    dependencies JSONB DEFAULT '[]', -- Required dependencies
    tags JSONB DEFAULT '[]', -- Template tags for searchability
    
    -- License and attribution
    license VARCHAR(100) DEFAULT 'MIT', -- Template license
    author_name VARCHAR(200), -- Original author
    author_email VARCHAR(200), -- Author contact
    source_url VARCHAR(1000), -- Original source if applicable
    
    -- SEO and discoverability
    keywords TEXT,
    search_vector TSVECTOR,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    published_at TIMESTAMP WITH TIME ZONE,
    created_by UUID, -- References users(id) - constraint added later
    
    -- Unique constraints
    UNIQUE(name, major_version, minor_version, patch_version),
    UNIQUE(slug) -- Global unique slug for public templates
);

-- Public template usage tracking
CREATE TABLE public_template_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID NOT NULL REFERENCES public_templates(id) ON DELETE CASCADE,
    
    -- Usage context (optional - can track even without user)
    user_id UUID, -- References users(id) - constraint added later (nullable for anonymous usage)
    tenant_id UUID, -- References tenants(id) - track which tenant used it (nullable)
    client_id UUID, -- References clients(id) - track which client used it (nullable)
    
    -- Usage information
    used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    generation_status VARCHAR(50) DEFAULT 'success' CHECK (generation_status IN ('success', 'error', 'partial')),
    error_message TEXT,
    
    -- Generation context
    parameters_used JSONB DEFAULT '{}', -- Parameters passed to template
    output_file_path VARCHAR(500), -- Where the generated file was saved
    generation_time_ms INTEGER, -- Time taken to generate
    
    -- User feedback (optional)
    user_rating INTEGER CHECK (user_rating >= 1 AND user_rating <= 5),
    user_feedback TEXT,
    
    -- Metadata
    ip_address INET, -- For anonymous usage tracking
    user_agent TEXT,
    metadata JSONB DEFAULT '{}'
);

-- Public template likes/favorites (for popularity)
CREATE TABLE public_template_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID NOT NULL REFERENCES public_templates(id) ON DELETE CASCADE,
    user_id UUID, -- References users(id) - nullable for anonymous likes
    
    -- Like information
    liked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ip_address INET, -- For anonymous like tracking
    
    -- Prevent duplicate likes
    UNIQUE(template_id, user_id),
    UNIQUE(template_id, ip_address) -- Prevent anonymous spam (one like per IP per template)
);

-- Public template reviews and ratings
CREATE TABLE public_template_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID NOT NULL REFERENCES public_templates(id) ON DELETE CASCADE,
    user_id UUID, -- References users(id) - nullable for anonymous reviews
    
    -- Review content
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(200),
    review_text TEXT,
    
    -- Review context
    is_verified_usage BOOLEAN DEFAULT FALSE, -- Did they actually use the template?
    usage_context VARCHAR(100), -- What did they use it for?
    
    -- Review status
    is_approved BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    ip_address INET,
    user_agent TEXT,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Prevent duplicate reviews
    UNIQUE(template_id, user_id),
    UNIQUE(template_id, ip_address) -- Prevent anonymous spam
);

-- Comprehensive indexes for optimal performance
CREATE INDEX idx_public_template_categories_parent ON public_template_categories(parent_category_id);
CREATE INDEX idx_public_template_categories_active ON public_template_categories(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_public_template_categories_slug ON public_template_categories(slug);
CREATE INDEX idx_public_template_categories_sort ON public_template_categories(sort_order);

CREATE INDEX idx_public_templates_category ON public_templates(category_id);
CREATE INDEX idx_public_templates_published ON public_templates(is_published) WHERE is_published = TRUE;
CREATE INDEX idx_public_templates_active ON public_templates(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_public_templates_featured ON public_templates(is_featured) WHERE is_featured = TRUE;
CREATE INDEX idx_public_templates_language ON public_templates(language);
CREATE INDEX idx_public_templates_framework ON public_templates(framework);
CREATE INDEX idx_public_templates_type ON public_templates(template_type);
CREATE INDEX idx_public_templates_category_custom ON public_templates(template_category);
CREATE INDEX idx_public_templates_complexity ON public_templates(complexity_level);
CREATE INDEX idx_public_templates_latest ON public_templates(is_latest_version) WHERE is_latest_version = TRUE;
CREATE INDEX idx_public_templates_usage_count ON public_templates(usage_count);
CREATE INDEX idx_public_templates_like_count ON public_templates(like_count);
CREATE INDEX idx_public_templates_created_at ON public_templates(created_at);
CREATE INDEX idx_public_templates_search_vector ON public_templates USING gin(search_vector);
CREATE INDEX idx_public_templates_tags ON public_templates USING gin(tags);
CREATE INDEX idx_public_templates_slug ON public_templates(slug);
CREATE INDEX idx_public_templates_parent ON public_templates(parent_template_id);

CREATE INDEX idx_public_template_usage_template ON public_template_usage(template_id);
CREATE INDEX idx_public_template_usage_user ON public_template_usage(user_id);
CREATE INDEX idx_public_template_usage_tenant ON public_template_usage(tenant_id);
CREATE INDEX idx_public_template_usage_used_at ON public_template_usage(used_at);
CREATE INDEX idx_public_template_usage_status ON public_template_usage(generation_status);

CREATE INDEX idx_public_template_likes_template ON public_template_likes(template_id);
CREATE INDEX idx_public_template_likes_user ON public_template_likes(user_id);
CREATE INDEX idx_public_template_likes_liked_at ON public_template_likes(liked_at);

CREATE INDEX idx_public_template_reviews_template ON public_template_reviews(template_id);
CREATE INDEX idx_public_template_reviews_user ON public_template_reviews(user_id);
CREATE INDEX idx_public_template_reviews_rating ON public_template_reviews(rating);
CREATE INDEX idx_public_template_reviews_approved ON public_template_reviews(is_approved) WHERE is_approved = TRUE;
CREATE INDEX idx_public_template_reviews_featured ON public_template_reviews(is_featured) WHERE is_featured = TRUE;

-- Search index for full-text search
CREATE INDEX idx_public_templates_search_text ON public_templates USING gin(to_tsvector('english', 
    coalesce(name, '') || ' ' || 
    coalesce(description, '') || ' ' || 
    coalesce(keywords, '') || ' ' ||
    coalesce(template_category, '')
));

-- Triggers for automatic updates
CREATE TRIGGER trigger_public_template_categories_updated_at 
    BEFORE UPDATE ON public_template_categories 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_public_templates_updated_at 
    BEFORE UPDATE ON public_templates 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_public_template_reviews_updated_at 
    BEFORE UPDATE ON public_template_reviews 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger to update search vector on template changes
CREATE OR REPLACE FUNCTION update_public_template_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector := to_tsvector('english', 
        coalesce(NEW.name, '') || ' ' || 
        coalesce(NEW.description, '') || ' ' || 
        coalesce(NEW.keywords, '') || ' ' ||
        coalesce(NEW.template_category, '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_public_templates_search_vector
    BEFORE INSERT OR UPDATE ON public_templates
    FOR EACH ROW EXECUTE FUNCTION update_public_template_search_vector();

-- Trigger to update usage count when public_template_usage is inserted
CREATE OR REPLACE FUNCTION update_public_template_usage_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public_templates 
    SET usage_count = usage_count + 1,
        last_used_at = NEW.used_at
    WHERE id = NEW.template_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_public_template_usage_count
    AFTER INSERT ON public_template_usage
    FOR EACH ROW EXECUTE FUNCTION update_public_template_usage_count();

-- Trigger to update like count when public_template_likes is inserted/deleted
CREATE OR REPLACE FUNCTION update_public_template_like_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public_templates 
        SET like_count = like_count + 1
        WHERE id = NEW.template_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public_templates 
        SET like_count = like_count - 1
        WHERE id = OLD.template_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_public_template_like_count_insert
    AFTER INSERT ON public_template_likes
    FOR EACH ROW EXECUTE FUNCTION update_public_template_like_count();

CREATE TRIGGER trigger_public_template_like_count_delete
    AFTER DELETE ON public_template_likes
    FOR EACH ROW EXECUTE FUNCTION update_public_template_like_count();

-- Insert default public template categories
INSERT INTO public_template_categories (name, display_name, description, slug, sort_order) VALUES
('go-patterns', 'Go Patterns', 'Common Go programming patterns and idioms', 'go-patterns', 1),
('web-frameworks', 'Web Frameworks', 'Templates for web frameworks like Gin, Echo, Fiber', 'web-frameworks', 2),
('microservices', 'Microservices', 'Microservice architecture templates', 'microservices', 3),
('database', 'Database', 'Database models, repositories, and migrations', 'database', 4),
('testing', 'Testing', 'Unit tests, integration tests, and testing utilities', 'testing', 5),
('deployment', 'Deployment', 'Docker, Kubernetes, and deployment configurations', 'deployment', 6),
('utilities', 'Utilities', 'Helper functions, middleware, and common utilities', 'utilities', 7),
('boilerplate', 'Boilerplate', 'Complete project templates and starter kits', 'boilerplate', 8),
('snippets', 'Code Snippets', 'Small, reusable code snippets', 'snippets', 9),
('examples', 'Examples', 'Example implementations and demonstrations', 'examples', 10)
ON CONFLICT (slug) DO NOTHING;

-- Add comments for documentation
COMMENT ON TABLE public_templates IS 'Generic templates available to all users without tenant/client restrictions';
COMMENT ON COLUMN public_templates.template_category IS 'Custom categorization field for flexible template organization';
COMMENT ON COLUMN public_templates.is_featured IS 'Highlights popular or recommended templates';
COMMENT ON COLUMN public_templates.license IS 'License under which the template is shared';
COMMENT ON COLUMN public_templates.author_name IS 'Original template author for attribution';
COMMENT ON TABLE public_template_usage IS 'Tracks usage of public templates across all tenants and anonymous users';
COMMENT ON TABLE public_template_likes IS 'User likes/favorites for public templates';
COMMENT ON TABLE public_template_reviews IS 'User reviews and ratings for public templates';
