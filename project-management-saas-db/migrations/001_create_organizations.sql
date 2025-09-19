-- Migration: 001_create_organizations.sql
-- Description: Create organizations table for recruitment company SaaS
-- Date: 2025-01-01

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Organizations table (recruitment companies as tenants)
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    logo_url TEXT,
    website TEXT,
    company_size VARCHAR(50) CHECK (company_size IN ('startup', 'small', 'medium', 'large', 'enterprise')),
    industry VARCHAR(100),
    subscription_plan VARCHAR(50) DEFAULT 'trial' CHECK (subscription_plan IN ('trial', 'basic', 'professional', 'enterprise')),
    subscription_status VARCHAR(20) DEFAULT 'active' CHECK (subscription_status IN ('active', 'suspended', 'cancelled', 'trial_expired')),
    -- Subscription limits
    max_recruiters INTEGER DEFAULT 3,
    max_jobs_per_month INTEGER DEFAULT 10,
    max_cvs_per_job INTEGER DEFAULT 100,
    max_ai_analyses_per_month INTEGER DEFAULT 1000,
    -- Usage tracking
    current_month_jobs INTEGER DEFAULT 0,
    current_month_ai_analyses INTEGER DEFAULT 0,
    -- Billing info
    billing_email VARCHAR(255),
    billing_address JSONB,
    -- Settings
    ai_matching_threshold DECIMAL(3,2) DEFAULT 0.70, -- Minimum score to show matches
    auto_process_cvs BOOLEAN DEFAULT true,
    notification_preferences JSONB DEFAULT '{}',
    api_settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_organizations_slug ON organizations(slug);
CREATE INDEX idx_organizations_subscription_plan ON organizations(subscription_plan);
CREATE INDEX idx_organizations_subscription_status ON organizations(subscription_status);

-- Updated at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to organizations table
CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();