-- Migration: create_public_templates (DOWN)
-- Service: template
-- Description: Drop public templates tables and related objects

-- Drop triggers first
DROP TRIGGER IF EXISTS trigger_public_template_like_count_delete ON public_template_likes;
DROP TRIGGER IF EXISTS trigger_public_template_like_count_insert ON public_template_likes;
DROP TRIGGER IF EXISTS trigger_public_template_usage_count ON public_template_usage;
DROP TRIGGER IF EXISTS trigger_public_templates_search_vector ON public_templates;
DROP TRIGGER IF EXISTS trigger_public_template_reviews_updated_at ON public_template_reviews;
DROP TRIGGER IF EXISTS trigger_public_templates_updated_at ON public_templates;
DROP TRIGGER IF EXISTS trigger_public_template_categories_updated_at ON public_template_categories;

-- Drop functions
DROP FUNCTION IF EXISTS update_public_template_like_count();
DROP FUNCTION IF EXISTS update_public_template_usage_count();
DROP FUNCTION IF EXISTS update_public_template_search_vector();

-- Drop indexes
DROP INDEX IF EXISTS idx_public_template_reviews_featured;
DROP INDEX IF EXISTS idx_public_template_reviews_approved;
DROP INDEX IF EXISTS idx_public_template_reviews_rating;
DROP INDEX IF EXISTS idx_public_template_reviews_user;
DROP INDEX IF EXISTS idx_public_template_reviews_template;

DROP INDEX IF EXISTS idx_public_template_likes_liked_at;
DROP INDEX IF EXISTS idx_public_template_likes_user;
DROP INDEX IF EXISTS idx_public_template_likes_template;

DROP INDEX IF EXISTS idx_public_template_usage_status;
DROP INDEX IF EXISTS idx_public_template_usage_used_at;
DROP INDEX IF EXISTS idx_public_template_usage_tenant;
DROP INDEX IF EXISTS idx_public_template_usage_user;
DROP INDEX IF EXISTS idx_public_template_usage_template;

DROP INDEX IF EXISTS idx_public_templates_parent;
DROP INDEX IF EXISTS idx_public_templates_slug;
DROP INDEX IF EXISTS idx_public_templates_tags;
DROP INDEX IF EXISTS idx_public_templates_search_vector;
DROP INDEX IF EXISTS idx_public_templates_created_at;
DROP INDEX IF EXISTS idx_public_templates_like_count;
DROP INDEX IF EXISTS idx_public_templates_usage_count;
DROP INDEX IF EXISTS idx_public_templates_latest;
DROP INDEX IF EXISTS idx_public_templates_complexity;
DROP INDEX IF EXISTS idx_public_templates_category_custom;
DROP INDEX IF EXISTS idx_public_templates_type;
DROP INDEX IF EXISTS idx_public_templates_framework;
DROP INDEX IF EXISTS idx_public_templates_language;
DROP INDEX IF EXISTS idx_public_templates_featured;
DROP INDEX IF EXISTS idx_public_templates_active;
DROP INDEX IF EXISTS idx_public_templates_published;
DROP INDEX IF EXISTS idx_public_templates_category;
DROP INDEX IF EXISTS idx_public_templates_search_text;

DROP INDEX IF EXISTS idx_public_template_categories_sort;
DROP INDEX IF EXISTS idx_public_template_categories_slug;
DROP INDEX IF EXISTS idx_public_template_categories_active;
DROP INDEX IF EXISTS idx_public_template_categories_parent;

-- Drop tables in correct order (children first)
DROP TABLE IF EXISTS public_template_reviews;
DROP TABLE IF EXISTS public_template_likes;
DROP TABLE IF EXISTS public_template_usage;
DROP TABLE IF EXISTS public_templates;
DROP TABLE IF EXISTS public_template_categories;
