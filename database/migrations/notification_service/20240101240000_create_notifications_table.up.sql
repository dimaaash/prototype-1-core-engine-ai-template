-- Migration: create_notifications_table
-- Service: notification
-- Description: Create notification and communication system tables

-- Notification templates for consistent messaging
CREATE TABLE notification_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    template_name VARCHAR(100) NOT NULL,
    template_type VARCHAR(50) NOT NULL CHECK (template_type IN ('email', 'sms', 'push', 'webhook', 'in_app')),
    category VARCHAR(50) NOT NULL CHECK (category IN ('order', 'inventory', 'system', 'marketing', 'alert', 'reminder')),
    
    -- Template content
    subject VARCHAR(255), -- For email templates
    content_text TEXT NOT NULL,
    content_html TEXT, -- For email templates
    
    -- Template configuration
    is_active BOOLEAN DEFAULT true,
    is_system BOOLEAN DEFAULT false, -- System templates cannot be deleted
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    
    -- Localization
    language_code VARCHAR(10) DEFAULT 'en',
    variables JSONB DEFAULT '{}', -- Template variables and their descriptions
    
    -- Delivery settings
    delivery_settings JSONB DEFAULT '{}', -- Channel-specific settings
    retry_settings JSONB DEFAULT '{}',
    
    -- Template metadata
    description TEXT,
    version INTEGER DEFAULT 1,
    
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tenant_id, template_name, language_code)
);

-- Notification channels for delivery methods
CREATE TABLE notification_channels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    channel_name VARCHAR(100) NOT NULL,
    channel_type VARCHAR(50) NOT NULL CHECK (channel_type IN ('email', 'sms', 'push', 'webhook', 'slack', 'teams')),
    
    -- Channel configuration
    is_active BOOLEAN DEFAULT true,
    is_default BOOLEAN DEFAULT false,
    priority INTEGER DEFAULT 0,
    
    -- Provider configuration
    provider VARCHAR(100) NOT NULL, -- sendgrid, twilio, firebase, etc.
    provider_config JSONB NOT NULL DEFAULT '{}', -- API keys, endpoints, etc.
    
    -- Rate limiting
    rate_limit_per_minute INTEGER DEFAULT 100,
    rate_limit_per_hour INTEGER DEFAULT 1000,
    rate_limit_per_day INTEGER DEFAULT 10000,
    
    -- Channel health
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'error', 'maintenance')),
    last_health_check TIMESTAMP WITH TIME ZONE,
    error_count INTEGER DEFAULT 0,
    last_error TEXT,
    
    -- Usage tracking
    messages_sent_today INTEGER DEFAULT 0,
    messages_sent_this_month INTEGER DEFAULT 0,
    last_reset_date DATE DEFAULT CURRENT_DATE,
    
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    UNIQUE(tenant_id, channel_name)
);

-- Main notifications table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL CHECK (notification_type IN ('email', 'sms', 'push', 'webhook', 'in_app')),
    category VARCHAR(50) NOT NULL CHECK (category IN ('order', 'inventory', 'system', 'marketing', 'alert', 'reminder')),
    
    -- Notification content
    subject VARCHAR(255),
    content_text TEXT NOT NULL,
    content_html TEXT,
    
    -- Recipients
    recipient_type VARCHAR(20) CHECK (recipient_type IN ('user', 'email', 'phone', 'external')),
    recipient_id UUID, -- user_id if recipient_type is 'user'
    recipient_address VARCHAR(255) NOT NULL, -- email, phone, device token, etc.
    recipient_name VARCHAR(255),
    
    -- Sending configuration
    channel_id UUID REFERENCES notification_channels(id),
    template_id UUID REFERENCES notification_templates(id),
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    
    -- Delivery status
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'queued', 'sending', 'sent', 'delivered', 'failed', 'cancelled')),
    delivery_attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    
    -- Timing
    scheduled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sent_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    
    -- Tracking and analytics
    opened BOOLEAN DEFAULT false,
    clicked BOOLEAN DEFAULT false,
    bounced BOOLEAN DEFAULT false,
    unsubscribed BOOLEAN DEFAULT false,
    
    -- Error handling
    error_message TEXT,
    error_code VARCHAR(50),
    retry_after TIMESTAMP WITH TIME ZONE,
    
    -- Related entities
    related_entity_type VARCHAR(50), -- order, product, inventory, etc.
    related_entity_id UUID,
    
    -- Additional data
    metadata JSONB DEFAULT '{}',
    tracking_data JSONB DEFAULT '{}',
    
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notification events for tracking user interactions
CREATE TABLE notification_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN ('queued', 'sent', 'delivered', 'opened', 'clicked', 'bounced', 'failed', 'unsubscribed')),
    
    -- Event details
    event_data JSONB DEFAULT '{}',
    user_agent VARCHAR(500),
    ip_address INET,
    
    -- Timing
    occurred_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Provider data
    provider_event_id VARCHAR(255),
    provider_data JSONB DEFAULT '{}'
);

-- Notification subscriptions for managing user preferences
CREATE TABLE notification_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Subscription details
    subscription_type VARCHAR(50) NOT NULL, -- order_updates, inventory_alerts, etc.
    channel_type VARCHAR(50) NOT NULL CHECK (channel_type IN ('email', 'sms', 'push', 'in_app')),
    
    -- Subscription status
    is_subscribed BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    
    -- Preferences
    frequency VARCHAR(20) DEFAULT 'immediate' CHECK (frequency IN ('immediate', 'hourly', 'daily', 'weekly')),
    priority_threshold VARCHAR(20) DEFAULT 'normal' CHECK (priority_threshold IN ('low', 'normal', 'high', 'urgent')),
    
    -- Verification
    verification_token VARCHAR(255),
    verified_at TIMESTAMP WITH TIME ZONE,
    
    -- Subscription management
    subscribed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    unsubscribed_at TIMESTAMP WITH TIME ZONE,
    unsubscribe_reason VARCHAR(255),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tenant_id, user_id, subscription_type, channel_type)
);

-- Notification rules for automated notifications
CREATE TABLE notification_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    rule_name VARCHAR(100) NOT NULL,
    
    -- Rule configuration
    is_active BOOLEAN DEFAULT true,
    trigger_event VARCHAR(100) NOT NULL, -- order.created, inventory.low, etc.
    conditions JSONB NOT NULL DEFAULT '{}', -- When to trigger
    
    -- Notification configuration
    template_id UUID REFERENCES notification_templates(id),
    channel_id UUID REFERENCES notification_channels(id),
    recipient_configuration JSONB NOT NULL DEFAULT '{}', -- Who to notify
    
    -- Rule timing
    delay_minutes INTEGER DEFAULT 0, -- Delay before sending
    frequency_limit JSONB DEFAULT '{}', -- Rate limiting per recipient
    
    -- Rule metadata
    description TEXT,
    priority INTEGER DEFAULT 0,
    
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    UNIQUE(tenant_id, rule_name)
);

-- Comprehensive indexing for notification service
CREATE INDEX idx_notification_templates_tenant_id ON notification_templates(tenant_id);
CREATE INDEX idx_notification_templates_type ON notification_templates(template_type);
CREATE INDEX idx_notification_templates_category ON notification_templates(category);
CREATE INDEX idx_notification_templates_active ON notification_templates(is_active) WHERE is_active = true;
CREATE INDEX idx_notification_templates_language ON notification_templates(language_code);

CREATE INDEX idx_notification_channels_tenant_id ON notification_channels(tenant_id);
CREATE INDEX idx_notification_channels_type ON notification_channels(channel_type);
CREATE INDEX idx_notification_channels_active ON notification_channels(is_active) WHERE is_active = true;
CREATE INDEX idx_notification_channels_default ON notification_channels(is_default) WHERE is_default = true;
CREATE INDEX idx_notification_channels_status ON notification_channels(status);

CREATE INDEX idx_notifications_tenant_id ON notifications(tenant_id);
CREATE INDEX idx_notifications_type ON notifications(notification_type);
CREATE INDEX idx_notifications_category ON notifications(category);
CREATE INDEX idx_notifications_recipient ON notifications(recipient_address);
CREATE INDEX idx_notifications_recipient_id ON notifications(recipient_id);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_notifications_priority ON notifications(priority);
CREATE INDEX idx_notifications_scheduled_at ON notifications(scheduled_at);
CREATE INDEX idx_notifications_channel_id ON notifications(channel_id);
CREATE INDEX idx_notifications_template_id ON notifications(template_id);
CREATE INDEX idx_notifications_related_entity ON notifications(related_entity_type, related_entity_id);

CREATE INDEX idx_notification_events_notification_id ON notification_events(notification_id);
CREATE INDEX idx_notification_events_type ON notification_events(event_type);
CREATE INDEX idx_notification_events_occurred_at ON notification_events(occurred_at);

CREATE INDEX idx_notification_subscriptions_tenant_id ON notification_subscriptions(tenant_id);
CREATE INDEX idx_notification_subscriptions_user_id ON notification_subscriptions(user_id);
CREATE INDEX idx_notification_subscriptions_type ON notification_subscriptions(subscription_type);
CREATE INDEX idx_notification_subscriptions_channel ON notification_subscriptions(channel_type);
CREATE INDEX idx_notification_subscriptions_subscribed ON notification_subscriptions(is_subscribed) WHERE is_subscribed = true;

CREATE INDEX idx_notification_rules_tenant_id ON notification_rules(tenant_id);
CREATE INDEX idx_notification_rules_active ON notification_rules(is_active) WHERE is_active = true;
CREATE INDEX idx_notification_rules_trigger ON notification_rules(trigger_event);
CREATE INDEX idx_notification_rules_template_id ON notification_rules(template_id);
CREATE INDEX idx_notification_rules_channel_id ON notification_rules(channel_id);

-- Triggers
CREATE TRIGGER trigger_notification_templates_updated_at 
    BEFORE UPDATE ON notification_templates 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_notification_channels_updated_at 
    BEFORE UPDATE ON notification_channels 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_notifications_updated_at 
    BEFORE UPDATE ON notifications 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_notification_subscriptions_updated_at 
    BEFORE UPDATE ON notification_subscriptions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_notification_rules_updated_at 
    BEFORE UPDATE ON notification_rules 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
