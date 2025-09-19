-- Migration: 004_create_rls_policies.sql
-- Description: Create Row Level Security policies for recruitment SaaS platform
-- Date: 2025-01-01

-- Enable RLS on all tables
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE password_reset_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE cvs ENABLE ROW LEVEL SECURITY;
ALTER TABLE cv_job_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_processing_queue ENABLE ROW LEVEL SECURITY;

-- Helper function to get current user's organizations
CREATE OR REPLACE FUNCTION current_user_organizations()
RETURNS UUID[] AS $$
BEGIN
    RETURN ARRAY(
        SELECT om.organization_id 
        FROM organization_members om 
        WHERE om.user_id = auth.uid() 
        AND om.is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to check if user is organization owner/admin
CREATE OR REPLACE FUNCTION is_organization_admin(org_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM organization_members om 
        WHERE om.organization_id = org_id 
        AND om.user_id = auth.uid() 
        AND om.role IN ('owner', 'admin')
        AND om.is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to check if user can access specific job
CREATE OR REPLACE FUNCTION can_access_job(job_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM jobs j
        JOIN organization_members om ON j.organization_id = om.organization_id
        WHERE j.id = job_id 
        AND om.user_id = auth.uid() 
        AND om.is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to check upload permissions
CREATE OR REPLACE FUNCTION can_upload_cvs(org_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM organization_members om 
        WHERE om.organization_id = org_id 
        AND om.user_id = auth.uid() 
        AND om.can_upload_cvs = true
        AND om.is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to check AI analysis permissions
CREATE OR REPLACE FUNCTION can_run_ai_analysis(org_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM organization_members om 
        WHERE om.organization_id = org_id 
        AND om.user_id = auth.uid() 
        AND om.can_run_ai_analysis = true
        AND om.is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ORGANIZATIONS POLICIES
-- Users can only see organizations they belong to
CREATE POLICY organizations_select_policy ON organizations
    FOR SELECT USING (id = ANY(current_user_organizations()));

-- Only organization owners/admins can update organization details
CREATE POLICY organizations_update_policy ON organizations
    FOR UPDATE USING (is_organization_admin(id));

-- USERS POLICIES  
-- Users can see their own profile and profiles of users in same organizations
CREATE POLICY users_select_policy ON users
    FOR SELECT USING (
        id = auth.uid() OR 
        EXISTS (
            SELECT 1 FROM organization_members om1
            JOIN organization_members om2 ON om1.organization_id = om2.organization_id
            WHERE om1.user_id = auth.uid() AND om2.user_id = users.id
            AND om1.is_active = true AND om2.is_active = true
        )
    );

-- Users can only update their own profile
CREATE POLICY users_update_policy ON users
    FOR UPDATE USING (id = auth.uid());

-- ORGANIZATION_MEMBERS POLICIES
-- Users can see memberships of organizations they belong to
CREATE POLICY organization_members_select_policy ON organization_members
    FOR SELECT USING (organization_id = ANY(current_user_organizations()));

-- Only organization admins can manage memberships
CREATE POLICY organization_members_insert_policy ON organization_members
    FOR INSERT WITH CHECK (is_organization_admin(organization_id));

CREATE POLICY organization_members_update_policy ON organization_members
    FOR UPDATE USING (is_organization_admin(organization_id));

CREATE POLICY organization_members_delete_policy ON organization_members
    FOR DELETE USING (is_organization_admin(organization_id) OR user_id = auth.uid());

-- PASSWORD_RESET_TOKENS POLICIES
-- Users can only access their own password reset tokens
CREATE POLICY password_reset_tokens_policy ON password_reset_tokens
    FOR ALL USING (user_id = auth.uid());

-- API_KEYS POLICIES
-- Users can see API keys for organizations they belong to
CREATE POLICY api_keys_select_policy ON api_keys
    FOR SELECT USING (organization_id = ANY(current_user_organizations()));

-- Only organization admins can manage API keys
CREATE POLICY api_keys_manage_policy ON api_keys
    FOR ALL USING (is_organization_admin(organization_id));

-- JOBS POLICIES
-- Users can see jobs from organizations they belong to
CREATE POLICY jobs_select_policy ON jobs
    FOR SELECT USING (organization_id = ANY(current_user_organizations()));

-- Users can create jobs in organizations they belong to (if they have permission)
CREATE POLICY jobs_insert_policy ON jobs
    FOR INSERT WITH CHECK (
        organization_id = ANY(current_user_organizations()) AND
        created_by = auth.uid() AND
        EXISTS (
            SELECT 1 FROM organization_members om 
            WHERE om.organization_id = jobs.organization_id 
            AND om.user_id = auth.uid() 
            AND om.can_create_jobs = true
            AND om.is_active = true
        )
    );

-- Job creators and organization admins can update jobs
CREATE POLICY jobs_update_policy ON jobs
    FOR UPDATE USING (
        created_by = auth.uid() OR 
        is_organization_admin(organization_id)
    );

-- Only organization admins can delete jobs
CREATE POLICY jobs_delete_policy ON jobs
    FOR DELETE USING (is_organization_admin(organization_id));

-- CVS POLICIES
-- Users can see CVs from jobs they can access
CREATE POLICY cvs_select_policy ON cvs
    FOR SELECT USING (can_access_job(job_id));

-- Users can upload CVs to jobs they can access (if they have permission)
CREATE POLICY cvs_insert_policy ON cvs
    FOR INSERT WITH CHECK (
        can_access_job(job_id) AND
        can_upload_cvs(organization_id) AND
        uploaded_by = auth.uid()
    );

-- CV uploaders and organization admins can update CVs
CREATE POLICY cvs_update_policy ON cvs
    FOR UPDATE USING (
        uploaded_by = auth.uid() OR 
        is_organization_admin(organization_id)
    );

-- Only organization admins can delete CVs
CREATE POLICY cvs_delete_policy ON cvs
    FOR DELETE USING (is_organization_admin(organization_id));

-- CV_JOB_MATCHES POLICIES
-- Users can see matches for jobs they can access
CREATE POLICY cv_job_matches_select_policy ON cv_job_matches
    FOR SELECT USING (can_access_job(job_id));

-- System can create matches (background AI processing)
CREATE POLICY cv_job_matches_insert_policy ON cv_job_matches
    FOR INSERT WITH CHECK (
        can_access_job(job_id) AND
        organization_id = ANY(current_user_organizations())
    );

-- Users can update their reviews/ratings on matches
CREATE POLICY cv_job_matches_update_policy ON cv_job_matches
    FOR UPDATE USING (can_access_job(job_id));

-- Only organization admins can delete matches
CREATE POLICY cv_job_matches_delete_policy ON cv_job_matches
    FOR DELETE USING (is_organization_admin(organization_id));

-- MATCH_ACTIONS POLICIES
-- Users can see actions on matches they can access
CREATE POLICY match_actions_select_policy ON match_actions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM cv_job_matches cjm 
            WHERE cjm.id = match_id 
            AND can_access_job(cjm.job_id)
        )
    );

-- Users can create actions on matches they can access
CREATE POLICY match_actions_insert_policy ON match_actions
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM cv_job_matches cjm 
            WHERE cjm.id = match_id 
            AND can_access_job(cjm.job_id)
        ) AND performed_by = auth.uid()
    );

-- Users can only update their own actions
CREATE POLICY match_actions_update_policy ON match_actions
    FOR UPDATE USING (performed_by = auth.uid());

-- AI_PROCESSING_QUEUE POLICIES
-- Users can see processing queue for their organizations
CREATE POLICY ai_processing_queue_select_policy ON ai_processing_queue
    FOR SELECT USING (organization_id = ANY(current_user_organizations()));

-- System and users with AI permissions can manage queue
CREATE POLICY ai_processing_queue_insert_policy ON ai_processing_queue
    FOR INSERT WITH CHECK (
        organization_id = ANY(current_user_organizations()) AND
        can_run_ai_analysis(organization_id)
    );

CREATE POLICY ai_processing_queue_update_policy ON ai_processing_queue
    FOR UPDATE USING (
        organization_id = ANY(current_user_organizations()) AND
        can_run_ai_analysis(organization_id)
    );