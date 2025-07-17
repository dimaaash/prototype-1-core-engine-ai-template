-- Migration: create_notifications_table (DOWN)
-- Service: notification
-- Description: Drop notification and communication system tables

-- Drop indexes first
DROP INDEX IF EXISTS idx_notification_rules_channel_id;
DROP INDEX IF EXISTS idx_notification_rules_template_id;
DROP INDEX IF EXISTS idx_notification_rules_trigger;
DROP INDEX IF EXISTS idx_notification_rules_active;
DROP INDEX IF EXISTS idx_notification_rules_tenant_id;

DROP INDEX IF EXISTS idx_notification_subscriptions_subscribed;
DROP INDEX IF EXISTS idx_notification_subscriptions_channel;
DROP INDEX IF EXISTS idx_notification_subscriptions_type;
DROP INDEX IF EXISTS idx_notification_subscriptions_user_id;
DROP INDEX IF EXISTS idx_notification_subscriptions_tenant_id;

DROP INDEX IF EXISTS idx_notification_events_occurred_at;
DROP INDEX IF EXISTS idx_notification_events_type;
DROP INDEX IF EXISTS idx_notification_events_notification_id;

DROP INDEX IF EXISTS idx_notifications_related_entity;
DROP INDEX IF EXISTS idx_notifications_template_id;
DROP INDEX IF EXISTS idx_notifications_channel_id;
DROP INDEX IF EXISTS idx_notifications_scheduled_at;
DROP INDEX IF EXISTS idx_notifications_priority;
DROP INDEX IF EXISTS idx_notifications_status;
DROP INDEX IF EXISTS idx_notifications_recipient_id;
DROP INDEX IF EXISTS idx_notifications_recipient;
DROP INDEX IF EXISTS idx_notifications_category;
DROP INDEX IF EXISTS idx_notifications_type;
DROP INDEX IF EXISTS idx_notifications_tenant_id;

DROP INDEX IF EXISTS idx_notification_channels_status;
DROP INDEX IF EXISTS idx_notification_channels_default;
DROP INDEX IF EXISTS idx_notification_channels_active;
DROP INDEX IF EXISTS idx_notification_channels_type;
DROP INDEX IF EXISTS idx_notification_channels_tenant_id;

DROP INDEX IF EXISTS idx_notification_templates_language;
DROP INDEX IF EXISTS idx_notification_templates_active;
DROP INDEX IF EXISTS idx_notification_templates_category;
DROP INDEX IF EXISTS idx_notification_templates_type;
DROP INDEX IF EXISTS idx_notification_templates_tenant_id;

-- Drop triggers
DROP TRIGGER IF EXISTS trigger_notification_rules_updated_at ON notification_rules;
DROP TRIGGER IF EXISTS trigger_notification_subscriptions_updated_at ON notification_subscriptions;
DROP TRIGGER IF EXISTS trigger_notifications_updated_at ON notifications;
DROP TRIGGER IF EXISTS trigger_notification_channels_updated_at ON notification_channels;
DROP TRIGGER IF EXISTS trigger_notification_templates_updated_at ON notification_templates;

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS notification_rules;
DROP TABLE IF EXISTS notification_subscriptions;
DROP TABLE IF EXISTS notification_events;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS notification_channels;
DROP TABLE IF EXISTS notification_templates;
