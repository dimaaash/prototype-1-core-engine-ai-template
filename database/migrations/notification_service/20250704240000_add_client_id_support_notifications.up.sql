-- Migration: add_client_id_support_notifications
-- Service: notification
-- Description: Add client_id support to notification tables for multi-client architecture

-- Add client_id to notification_templates table
ALTER TABLE notification_templates 
    ADD COLUMN client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE;

-- Update unique constraint to include client_id
ALTER TABLE notification_templates 
    DROP CONSTRAINT notification_templates_tenant_id_template_name_language_cod_key;

ALTER TABLE notification_templates 
    ADD CONSTRAINT notification_templates_client_name_unique 
    UNIQUE (tenant_id, client_id, template_name, language_code);

-- Add client_id to notification_channels table
ALTER TABLE notification_channels 
    ADD COLUMN client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE;

-- Update unique constraint to include client_id
ALTER TABLE notification_channels 
    DROP CONSTRAINT notification_channels_tenant_id_channel_name_key;

ALTER TABLE notification_channels 
    ADD CONSTRAINT notification_channels_client_name_unique 
    UNIQUE (tenant_id, client_id, channel_name);

-- Add client_id to notifications table
ALTER TABLE notifications 
    ADD COLUMN client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE;

-- Add client_id to notification_rules table
ALTER TABLE notification_rules 
    ADD COLUMN client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE;

-- Update unique constraint to include client_id
ALTER TABLE notification_rules 
    DROP CONSTRAINT notification_rules_tenant_id_rule_name_key;

ALTER TABLE notification_rules 
    ADD CONSTRAINT notification_rules_client_name_unique 
    UNIQUE (tenant_id, client_id, rule_name);

-- Add client_id to notification_subscriptions table
ALTER TABLE notification_subscriptions 
    ADD COLUMN client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE;

-- Update unique constraint to include client_id
ALTER TABLE notification_subscriptions 
    DROP CONSTRAINT notification_subscriptions_tenant_id_user_id_subscription_t_key;

ALTER TABLE notification_subscriptions 
    ADD CONSTRAINT notification_subscriptions_client_unique 
    UNIQUE (tenant_id, client_id, user_id, subscription_type);

-- Add client_id to notification_events table
ALTER TABLE notification_events 
    ADD COLUMN client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE;

-- Add client_id indexes for performance
CREATE INDEX idx_notification_templates_client_id ON notification_templates(client_id);
CREATE INDEX idx_notification_channels_client_id ON notification_channels(client_id);
CREATE INDEX idx_notifications_client_id ON notifications(client_id);
CREATE INDEX idx_notification_rules_client_id ON notification_rules(client_id);
CREATE INDEX idx_notification_subscriptions_client_id ON notification_subscriptions(client_id);
CREATE INDEX idx_notification_events_client_id ON notification_events(client_id);

-- Add comments for client_id columns
COMMENT ON COLUMN notification_templates.client_id IS 'Reference to client for multi-tenant data isolation';
COMMENT ON COLUMN notification_channels.client_id IS 'Reference to client for multi-tenant data isolation';
COMMENT ON COLUMN notifications.client_id IS 'Reference to client for multi-tenant data isolation';
COMMENT ON COLUMN notification_rules.client_id IS 'Reference to client for multi-tenant data isolation';
COMMENT ON COLUMN notification_subscriptions.client_id IS 'Reference to client for multi-tenant data isolation';
COMMENT ON COLUMN notification_events.client_id IS 'Reference to client for multi-tenant data isolation';
