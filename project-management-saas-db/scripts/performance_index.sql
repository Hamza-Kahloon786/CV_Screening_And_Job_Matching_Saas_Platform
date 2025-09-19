-- performance_indexes.sql
-- Additional performance optimization indexes for AI-powered recruitment SaaS
-- Run this after main migrations for enhanced query performance

-- =====================================================
-- COMPOSITE INDEXES FOR COMMON QUERY PATTERNS
-- =====================================================

\echo 'Creating composite indexes for common query patterns...'

-- Organization + Status queries (very common in SaaS)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_jobs_org_status_created 
ON jobs(organization_id, status, created_at DESC) 
WHERE status IN ('active', 'paused');

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cvs_org_job_status 
ON cvs(organization_id, job_id, ai_processing_status) 
WHERE ai_processing_status IN ('pending', 'processing');

-- Match queries with scoring (core business logic)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_matches_job_score_status 
ON cv_job_matches(job_id, overall_match_score DESC, status) 
WHERE overall_match_score >= 0.70;

-- User activity patterns
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_match_actions_user_date 
ON match_actions(performed_by, performed_at DESC, action_type);

-- =====================================================
-- AI PROCESSING PERFORMANCE INDEXES
-- =====================================================

\echo 'Creating AI processing optimization indexes...'

-- AI processing queue performance (critical for background jobs)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_ai_queue_status_priority_scheduled 
ON ai_processing_queue(status, priority ASC, scheduled_at ASC) 
WHERE status IN ('pending', 'retrying');

-- CV processing status tracking
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cvs_processing_created 
ON cvs(ai_processing_status, created_at DESC) 
WHERE ai_processing_status IN ('pending', 'processing', 'failed');

-- Job AI processing tracking
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_jobs_ai_processing 
ON jobs(ai_processing_status, ai_processed_at DESC) 
WHERE ai_processing_status = 'completed';

-- =====================================================
-- RECRUITMENT WORKFLOW INDEXES
-- =====================================================

\echo 'Creating recruitment workflow optimization indexes...'

-- Recruiter dashboard queries (most frequent)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_matches_recruiter_dashboard 
ON cv_job_matches(organization_id, status, overall_match_score DESC, processed_at DESC) 
WHERE status IN ('new', 'reviewed');

-- Candidate pipeline tracking
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_matches_pipeline_status 
ON cv_job_matches(job_id, status, reviewed_at DESC) 
WHERE status IN ('shortlisted', 'contacted', 'interviewed');

-- Job performance analytics
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_jobs_analytics 
ON jobs(organization_id, created_at DESC, status) 
INCLUDE (total_cvs_uploaded, total_matches_found);

-- =====================================================
-- SEARCH AND FILTERING INDEXES
-- =====================================================

\echo 'Creating search and filtering indexes...'

-- Skills-based searching (using GIN for arrays)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cvs_extracted_skills_gin 
ON cvs USING GIN (extracted_skills) 
WHERE ai_processing_status = 'completed';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_jobs_required_skills_gin 
ON jobs USING GIN (required_skills) 
WHERE status = 'active';

-- Text search on job titles and descriptions
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_jobs_title_search 
ON jobs USING GIN (to_tsvector('english', title || ' ' || COALESCE(description, ''))) 
WHERE status = 'active';

-- Candidate name search
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cvs_candidate_name_search 
ON cvs USING GIN (to_tsvector('english', COALESCE(candidate_name, ''))) 
WHERE ai_processing_status = 'completed';

-- =====================================================
-- DATE RANGE AND ANALYTICS INDEXES
-- =====================================================

\echo 'Creating analytics and reporting indexes...'

-- Monthly reporting and analytics
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_jobs_monthly_analytics 
ON jobs(organization_id, EXTRACT(year FROM created_at), EXTRACT(month FROM created_at), status);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cvs_monthly_analytics 
ON cvs(organization_id, EXTRACT(year FROM created_at), EXTRACT(month FROM created_at));

-- Match success rate analytics
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_matches_success_analytics 
ON cv_job_matches(organization_id, ai_recommendation, status, processed_at) 
WHERE ai_recommendation IN ('strong_match', 'good_match');

-- Recruiter performance tracking
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_actions_recruiter_performance 
ON match_actions(performed_by, action_type, performed_at DESC) 
WHERE action_type IN ('shortlisted', 'contacted', 'hired');

-- =====================================================
-- SUBSCRIPTION AND BILLING INDEXES
-- =====================================================

\echo 'Creating subscription management indexes...'

-- Usage tracking for billing
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orgs_usage_tracking 
ON organizations(subscription_plan, current_month_jobs, current_month_ai_analyses) 
WHERE subscription_status = 'active';

-- Organization member counting
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_members_active_count 
ON organization_members(organization_id, is_active) 
WHERE is_active = true;

-- API usage tracking
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_api_keys_usage 
ON api_keys(organization_id, is_active, last_used_at DESC) 
WHERE is_active = true;

-- =====================================================
-- PARTIAL INDEXES FOR COMMON FILTERS
-- =====================================================

\echo 'Creating partial indexes for common filter conditions...'

-- Active jobs only (most queries filter to active)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_jobs_active_only 
ON jobs(organization_id, created_at DESC, priority) 
WHERE status = 'active';

-- High-score matches only (recruiters focus on good matches)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_matches_high_score 
ON cv_job_matches(job_id, overall_match_score DESC, processed_at DESC) 
WHERE overall_match_score >= 0.80;

-- Recent activity tracking
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_recent_activity 
ON match_actions(organization_id, performed_at DESC) 
WHERE performed_at >= NOW() - INTERVAL '30 days';

-- Failed AI processing (for monitoring and retries)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_ai_failures 
ON ai_processing_queue(organization_id, task_type, created_at DESC) 
WHERE status = 'failed';

-- =====================================================
-- COVERING INDEXES FOR READ PERFORMANCE
-- =====================================================

\echo 'Creating covering indexes for read-heavy queries...'

-- Job listing with essential info (avoid table lookups)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_jobs_listing_covered 
ON jobs(organization_id, status, created_at DESC) 
INCLUDE (id, title, company_name, location, total_cvs_uploaded, total_matches_found);

-- CV listing with candidate info
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cvs_listing_covered 
ON cvs(job_id, ai_processing_status) 
INCLUDE (id, candidate_name, candidate_email, years_of_experience, created_at);

-- Match results with scores
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_matches_results_covered 
ON cv_job_matches(job_id, overall_match_score DESC) 
INCLUDE (cv_id, skills_match_score, experience_match_score, ai_recommendation, status);

-- =====================================================
-- PERFORMANCE MONITORING VIEWS
-- =====================================================

\echo 'Creating performance monitoring views...'

-- View for monitoring slow queries and index usage
CREATE OR REPLACE VIEW performance_stats AS
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_tup_read,
    idx_tup_fetch,
    idx_scan
FROM pg_stat_user_indexes 
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- View for monitoring table sizes and growth
CREATE OR REPLACE VIEW table_sizes AS
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
    pg_total_relation_size(schemaname||'.'||tablename) as size_bytes
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- View for AI processing queue monitoring
CREATE OR REPLACE VIEW ai_queue_stats AS
SELECT 
    task_type,
    status,
    COUNT(*) as count,
    AVG(EXTRACT(EPOCH FROM (completed_at - started_at))) as avg_processing_seconds,
    MIN(created_at) as oldest_task,
    MAX(created_at) as newest_task
FROM ai_processing_queue
GROUP BY task_type, status
ORDER BY task_type, status;

-- =====================================================
-- INDEX MAINTENANCE PROCEDURES
-- =====================================================

\echo 'Creating index maintenance procedures...'

-- Function to reindex all tables (for maintenance)
CREATE OR REPLACE FUNCTION reindex_all_tables()
RETURNS void AS $$
DECLARE
    table_name text;
BEGIN
    FOR table_name IN 
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE 'REINDEX TABLE ' || quote_ident(table_name);
        RAISE NOTICE 'Reindexed table: %', table_name;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function to analyze table statistics (for query planning)
CREATE OR REPLACE FUNCTION analyze_all_tables()
RETURNS void AS $$
DECLARE
    table_name text;
BEGIN
    FOR table_name IN 
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        EXECUTE 'ANALYZE ' || quote_ident(table_name);
        RAISE NOTICE 'Analyzed table: %', table_name;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PERFORMANCE RECOMMENDATIONS
-- =====================================================

\echo ''
\echo '=================================================='
\echo 'PERFORMANCE OPTIMIZATION SUMMARY'
\echo '=================================================='
\echo ''
\echo 'Indexes created for:'
\echo '✓ Common SaaS query patterns (org + status + date)'
\echo '✓ AI processing workflow optimization'
\echo '✓ Recruitment dashboard queries'
\echo '✓ Skills and text search (GIN indexes)'
\echo '✓ Analytics and reporting'
\echo '✓ Subscription and billing queries'
\echo '✓ Covering indexes for read performance'
\echo ''
\echo 'Monitoring views created:'
\echo '✓ performance_stats - Index usage monitoring'
\echo '✓ table_sizes - Storage monitoring'
\echo '✓ ai_queue_stats - AI processing monitoring'
\echo ''
\echo 'Maintenance functions created:'
\echo '✓ reindex_all_tables() - Rebuild all indexes'
\echo '✓ analyze_all_tables() - Update table statistics'
\echo ''
\echo 'Performance recommendations:'
\echo '1. Monitor ai_queue_stats regularly for bottlenecks'
\echo '2. Run ANALYZE weekly: SELECT analyze_all_tables();'
\echo '3. Monitor performance_stats for unused indexes'
\echo '4. Consider partitioning large tables by organization_id'
\echo '5. Set up connection pooling (PgBouncer recommended)'
\echo '6. Configure appropriate work_mem for AI processing'
\echo '7. Monitor table_sizes for storage planning'