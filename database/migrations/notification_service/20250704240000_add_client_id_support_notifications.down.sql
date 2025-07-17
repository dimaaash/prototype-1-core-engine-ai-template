-- Migration: add_client_id_support_notifications (ROLLBACK)
-- Service: notification
-- Description: Rollback client_id support from notification tables

-- Remove comments
COMMENT ON COLUMN notification_templates.client_id IS NULL;
COMMENT ON COLUMN notification_channels.client_id IS NULL;
COMMENT ON COLUMN notifications.client_id IS NULL;
COMMENT ON COLUMN notification_rules.client_id IS NULL;
COMMENT ON COLUMN notification_subscriptions.client_id IS NULL;
COMMENT ON COLUMN notification_events.client_id IS NULL;

-- Drop client_id indexes
DROP INDEX IF EXISTS idx_notification_events_client_id;
DROP INDEX IF EXISTS idx_notification_subscriptions_client_id;
DROP INDEX IF EXISTS idx_notification_rules_client_id;
DROP INDEX IF EXISTS idx_notifications_client_id;
DROP INDEX IF EXISTS idx_notification_channels_client_id;
DROP INDEX IF EXISTS idx_notification_templates_client_id;

-- Restore original unique constraints
ALTER TABLE notification_subscriptions 
    DROP CONSTRAINT notification_subscriptions_client_unique;

ALTER TABLE notification_subscriptions 
    ADD CONSTRAINT notification_subscriptions_tenant_id_user_id_subscription_t_key 
    UNIQUE (tenant_id, user_id, subscription_type);

ALTER TABLE notification_rules 
    DROP CONSTRAINT notification_rules_client_name_unique;

ALTER TABLE notification_rules 
    ADD CONSTRAINT notification_rules_tenant_id_rule_name_key 
    UNIQUE (tenant_id, rule_name);

ALTER TABLE notification_channels 
    DROP CONSTRAINT notification_channels_client_name_unique;

ALTER TABLE notification_channels 
    ADD CONSTRAINT notification_channels_tenant_id_channel_name_key 
    UNIQUE (tenant_id, channel_name);

ALTER TABLE notification_templates 
    DROP CONSTRAINT notification_templates_client_name_unique;

ALTER TABLE notification_templates 
    ADD CONSTRAINT notification_templates_tenant_id_template_name_language_cod_key 
    UNIQUE (tenant_id, template_name, language_code);

-- Remove client_id columns
ALTER TABLE notification_events DROP COLUMN client_id;
ALTER TABLE notification_subscriptions DROP COLUMN client_id;
ALTER TABLE notification_rules DROP COLUMN client_id;
ALTER TABLE notifications DROP COLUMN client_id;
ALTER TABLE notification_channels DROP COLUMN client_id;
ALTER TABLE notification_templates DROP COLUMN client_id;
