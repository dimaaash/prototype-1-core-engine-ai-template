-- Migration: create_template_tables
-- Service: template
-- Description: Drop template management tables

-- Drop triggers first
DROP TRIGGER IF EXISTS trigger_templates_search_vector ON templates;
DROP TRIGGER IF EXISTS trigger_template_reviews_updated_at ON template_reviews;
DROP TRIGGER IF EXISTS trigger_templates_updated_at ON templates;
DROP TRIGGER IF EXISTS trigger_template_categories_updated_at ON template_categories;

-- Drop function
DROP FUNCTION IF EXISTS update_template_search_vector();

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS template_shares CASCADE;
DROP TABLE IF EXISTS template_reviews CASCADE;
DROP TABLE IF EXISTS template_favorites CASCADE;
DROP TABLE IF EXISTS template_usage CASCADE;
DROP TABLE IF EXISTS template_versions CASCADE;
DROP TABLE IF EXISTS templates CASCADE;
DROP TABLE IF EXISTS template_categories CASCADE;
