-- Migration: 003_create_jobs_and_cvs.sql
-- Description: Create jobs, CVs, and AI matching tables for recruitment platform
-- Date: 2025-01-01

-- Jobs table (job postings from recruitment companies)
CREATE TABLE jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    requirements TEXT,
    responsibilities TEXT,
    -- Job details
    company_name VARCHAR(255), -- Client company name
    location VARCHAR(255),
    job_type VARCHAR(50) CHECK (job_type IN ('full_time', 'part_time', 'contract', 'temporary', 'internship')),
    experience_level VARCHAR(50) CHECK (experience_level IN ('entry', 'mid', 'senior', 'executive')),
    salary_min DECIMAL(12,2),
    salary_max DECIMAL(12,2),
    currency VARCHAR(3) DEFAULT 'USD',
    remote_work BOOLEAN DEFAULT false,
    -- Technical requirements
    required_skills TEXT[], -- Array of required skills
    preferred_skills TEXT[], -- Array of preferred skills
    education_requirements TEXT,
    certifications TEXT[],
    -- Job status and workflow
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('draft', 'active', 'paused', 'closed', 'archived')),
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    deadline DATE,
    -- AI processing
    ai_keywords JSONB, -- Extracted keywords for matching
    ai_processed_at TIMESTAMP WITH TIME ZONE,
    ai_processing_status VARCHAR(50) DEFAULT 'pending' CHECK (ai_processing_status IN ('pending', 'processing', 'completed', 'failed')),
    -- Tracking
    total_cvs_uploaded INTEGER DEFAULT 0,
    total_matches_found INTEGER DEFAULT 0,
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- CVs table (uploaded candidate CVs)
CREATE TABLE cvs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    -- CV file information
    original_filename VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    file_type VARCHAR(50) NOT NULL,
    -- Candidate information (extracted via AI)
    candidate_name VARCHAR(255),
    candidate_email VARCHAR(255),
    candidate_phone VARCHAR(50),
    candidate_location VARCHAR(255),
    -- CV content (AI extracted)
    extracted_text TEXT,
    extracted_skills TEXT[],
    extracted_experience JSONB, -- Structured experience data
    extracted_education JSONB, -- Structured education data
    extracted_certifications TEXT[],
    years_of_experience INTEGER,
    -- AI processing status
    ai_processed_at TIMESTAMP WITH TIME ZONE,
    ai_processing_status VARCHAR(50) DEFAULT 'pending' CHECK (ai_processing_status IN ('pending', 'processing', 'completed', 'failed')),
    ai_processing_error TEXT,
    -- Status
    status VARCHAR(50) DEFAULT 'uploaded' CHECK (status IN ('uploaded', 'processing', 'processed', 'error')),
    uploaded_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- CV-Job matches (AI analysis results)
CREATE TABLE cv_job_matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    cv_id UUID NOT NULL REFERENCES cvs(id) ON DELETE CASCADE,
    -- Matching scores (0.0 to 1.0)
    overall_match_score DECIMAL(5,4) NOT NULL,
    skills_match_score DECIMAL(5,4),
    experience_match_score DECIMAL(5,4),
    education_match_score DECIMAL(5,4),
    location_match_score DECIMAL(5,4),
    -- AI analysis
    ai_summary TEXT, -- AI-generated recommendation summary
    ai_pros TEXT[],  -- Strengths identified by AI
    ai_cons TEXT[],  -- Weaknesses identified by AI
    matching_skills TEXT[], -- Skills that matched
    missing_skills TEXT[], -- Required skills candidate lacks
    ai_recommendation VARCHAR(50) CHECK (ai_recommendation IN ('strong_match', 'good_match', 'partial_match', 'poor_match', 'not_recommended')),
    -- Processing info
    ai_model_version VARCHAR(50),
    processed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- Recruiter actions
    recruiter_rating INTEGER CHECK (recruiter_rating >= 1 AND recruiter_rating <= 5),
    recruiter_notes TEXT,
    status VARCHAR(50) DEFAULT 'new' CHECK (status IN ('new', 'reviewed', 'shortlisted', 'rejected', 'contacted')),
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(job_id, cv_id)
);

-- Match actions/workflow tracking
CREATE TABLE match_actions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    match_id UUID NOT NULL REFERENCES cv_job_matches(id) ON DELETE CASCADE,
    action_type VARCHAR(50) NOT NULL CHECK (action_type IN ('viewed', 'downloaded', 'shortlisted', 'rejected', 'contacted', 'interviewed', 'hired')),
    notes TEXT,
    performed_by UUID NOT NULL REFERENCES users(id),
    performed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AI processing queue (for background job processing)
CREATE TABLE ai_processing_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    cv_id UUID REFERENCES cvs(id) ON DELETE CASCADE,
    task_type VARCHAR(50) NOT NULL CHECK (task_type IN ('extract_cv_content', 'process_job_description', 'match_cv_to_job')),
    priority INTEGER DEFAULT 5, -- 1 = highest, 10 = lowest
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'retrying')),
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    error_message TEXT,
    payload JSONB,
    scheduled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_jobs_organization_id ON jobs(organization_id);
CREATE INDEX idx_jobs_status ON jobs(status);
CREATE INDEX idx_jobs_created_by ON jobs(created_by);
CREATE INDEX idx_jobs_ai_processing_status ON jobs(ai_processing_status);
CREATE INDEX idx_cvs_organization_id ON cvs(organization_id);
CREATE INDEX idx_cvs_job_id ON cvs(job_id);
CREATE INDEX idx_cvs_ai_processing_status ON cvs(ai_processing_status);
CREATE INDEX idx_cvs_uploaded_by ON cvs(uploaded_by);
CREATE INDEX idx_cv_job_matches_job_id ON cv_job_matches(job_id);
CREATE INDEX idx_cv_job_matches_cv_id ON cv_job_matches(cv_id);
CREATE INDEX idx_cv_job_matches_overall_score ON cv_job_matches(overall_match_score DESC);
CREATE INDEX idx_cv_job_matches_status ON cv_job_matches(status);
CREATE INDEX idx_cv_job_matches_organization_id ON cv_job_matches(organization_id);
CREATE INDEX idx_match_actions_match_id ON match_actions(match_id);
CREATE INDEX idx_match_actions_performed_by ON match_actions(performed_by);
CREATE INDEX idx_ai_processing_queue_status ON ai_processing_queue(status);
CREATE INDEX idx_ai_processing_queue_priority ON ai_processing_queue(priority);

-- Apply updated_at triggers
CREATE TRIGGER update_jobs_updated_at BEFORE UPDATE ON jobs 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cvs_updated_at BEFORE UPDATE ON cvs 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cv_job_matches_updated_at BEFORE UPDATE ON cv_job_matches 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();