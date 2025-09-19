-- test_rls_policies.sql
-- Test script to validate Row Level Security policies for recruitment SaaS platform
-- This script tests data isolation between organizations and role-based permissions

-- Setup test environment
\echo '========================================='
\echo 'TESTING ROW LEVEL SECURITY POLICIES'
\echo '========================================='

-- Enable RLS for testing
SET row_security = on;

\echo ''
\echo '=== TEST 1: Organization Data Isolation ==='
\echo 'Testing that users can only see their organization data...'

-- Test as TechTalent Recruiters admin (Sarah Martinez)
SET LOCAL role = 'authenticated';
SET LOCAL request.jwt.claims = '{"sub": "550e8400-e29b-41d4-a716-446655440101"}';

\echo ''
\echo 'Logged in as Sarah Martinez (TechTalent admin)'
\echo 'Should see TechTalent organization and related data only:'

-- Should return 1 organization (TechTalent)
SELECT 
    count(*) as org_count,
    string_agg(company_name, ', ') as visible_orgs
FROM organizations;

-- Should see jobs from TechTalent only
SELECT 
    count(*) as job_count,
    string_agg(title, ', ') as visible_jobs
FROM jobs;

-- Should see CVs uploaded to TechTalent jobs only
SELECT 
    count(*) as cv_count,
    string_agg(candidate_name, ', ') as visible_candidates
FROM cvs;

\echo ''
\echo '=== TEST 2: Cross-Organization Access Prevention ==='
\echo 'Testing that users cannot access other organizations data...'

-- Test as Executive Search owner (Elizabeth Brown)
SET LOCAL role = 'authenticated';
SET LOCAL request.jwt.claims = '{"sub": "550e8400-e29b-41d4-a716-446655440103"}';

\echo ''
\echo 'Logged in as Elizabeth Brown (Executive Search owner)'
\echo 'Should see Executive Search organization only:'

-- Should return 1 organization (Executive Search)
SELECT 
    count(*) as org_count,
    string_agg(company_name, ', ') as visible_orgs
FROM organizations;

-- Should see different jobs than TechTalent
SELECT 
    count(*) as job_count,
    string_agg(title, ', ') as visible_jobs
FROM jobs;

\echo ''
\echo '=== TEST 3: Role-Based Permissions ==='
\echo 'Testing different permission levels within same organization...'

-- Test as recruiter (Maria Garcia) - lower privileges
SET LOCAL role = 'authenticated';
SET LOCAL request.jwt.claims = '{"sub": "550e8400-e29b-41d4-a716-446655440105"}';

\echo ''
\echo 'Logged in as Maria Garcia (TechTalent recruiter)'
\echo 'Checking role-based permissions:'

-- Check user permissions
SELECT 
    u.first_name,
    u.last_name,
    om.role,
    om.can_create_jobs,
    om.can_upload_cvs,
    om.can_run_ai_analysis,
    om.can_manage_team
FROM users u
JOIN organization_members om ON u.id = om.user_id
WHERE u.id = auth.uid();

\echo ''
\echo '=== TEST 4: Job Access Control ==='
\echo 'Testing job-level access permissions...'

-- Test job access for different users
SET LOCAL role = 'authenticated';
SET LOCAL request.jwt.claims = '{"sub": "550e8400-e29b-41d4-a716-446655440101"}';

\echo ''
\echo 'Testing job access as Sarah Martinez:'

-- Should see jobs from own organization
SELECT 
    j.id,
    j.title,
    j.company_name,
    o.company_name as recruitment_company,
    j.created_by = auth.uid() as is_creator
FROM jobs j
JOIN organizations o ON j.organization_id = o.id
ORDER BY j.created_at;

\echo ''
\echo '=== TEST 5: CV and Match Access Control ==='
\echo 'Testing CV and match result access...'

-- Test CV matches access
SELECT 
    cjm.id,
    j.title as job_title,
    cv.candidate_name,
    cjm.overall_match_score,
    cjm.ai_recommendation,
    cjm.status
FROM cv_job_matches cjm
JOIN jobs j ON cjm.job_id = j.id
JOIN cvs cv ON cjm.cv_id = cv.id
ORDER BY cjm.overall_match_score DESC;

\echo ''
\echo '=== TEST 6: Permission Boundary Testing ==='
\echo 'Testing permission enforcement for restricted actions...'

-- Test as viewer role (simulate restricted user)
\echo 'Testing restricted access scenarios:'

-- Try to access organization member management
SELECT 
    om.user_id,
    u.first_name,
    u.last_name,
    om.role,
    om.is_active
FROM organization_members om
JOIN users u ON om.user_id = u.id
WHERE om.organization_id = ANY(current_user_organizations())
ORDER BY om.role, u.last_name;

\echo ''
\echo '=== TEST 7: AI Processing Queue Access ==='
\echo 'Testing AI processing queue visibility...'

-- Should only see processing tasks for accessible organizations
SELECT 
    apq.task_type,
    apq.status,
    apq.priority,
    apq.created_at,
    j.title as job_title
FROM ai_processing_queue apq
LEFT JOIN jobs j ON apq.job_id = j.id
ORDER BY apq.created_at DESC
LIMIT 5;

\echo ''
\echo '=== TEST 8: Match Actions Audit Trail ==='
\echo 'Testing match actions access and audit trail...'

-- Should see actions on matches user can access
SELECT 
    ma.action_type,
    ma.notes,
    u.first_name as performed_by,
    j.title as job_title,
    cv.candidate_name,
    ma.performed_at
FROM match_actions ma
JOIN users u ON ma.performed_by = u.id
JOIN cv_job_matches cjm ON ma.match_id = cjm.id
JOIN jobs j ON cjm.job_id = j.id
JOIN cvs cv ON cjm.cv_id = cv.id
ORDER BY ma.performed_at DESC
LIMIT 10;

\echo ''
\echo '=== TEST 9: Security Function Testing ==='
\echo 'Testing custom security functions...'

-- Test current_user_organizations function
\echo 'Current user organizations:'
SELECT unnest(current_user_organizations()) as organization_id;

-- Test admin check function
\echo 'Admin status for visible organizations:'
SELECT 
    o.company_name,
    is_organization_admin(o.id) as is_admin
FROM organizations o;

-- Test job access function
\echo 'Job access validation:'
SELECT 
    j.title,
    can_access_job(j.id) as can_access
FROM jobs j
LIMIT 5;

\echo ''
\echo '=== TEST 10: Data Integrity Validation ==='
\echo 'Testing data consistency and relationships...'

-- Verify all CVs belong to accessible jobs
SELECT 
    'CV-Job relationship integrity' as test_name,
    COUNT(*) as total_cvs,
    COUNT(CASE WHEN can_access_job(cv.job_id) THEN 1 END) as accessible_cvs,
    COUNT(*) = COUNT(CASE WHEN can_access_job(cv.job_id) THEN 1 END) as integrity_check
FROM cvs cv;

-- Verify all matches are for accessible jobs
SELECT 
    'Match-Job relationship integrity' as test_name,
    COUNT(*) as total_matches,
    COUNT(CASE WHEN can_access_job(cjm.job_id) THEN 1 END) as accessible_matches,
    COUNT(*) = COUNT(CASE WHEN can_access_job(cjm.job_id) THEN 1 END) as integrity_check
FROM cv_job_matches cjm;

\echo ''
\echo '=== RLS POLICY TEST SUMMARY ==='
\echo 'All tests completed. Review results above for:'
\echo '1. Organization data isolation'
\echo '2. Role-based permission enforcement'
\echo '3. Job and CV access control'
\echo '4. AI processing queue security'
\echo '5. Audit trail access'
\echo '6. Security function validation'
\echo '7. Data integrity checks'
\echo ''
\echo 'Expected behavior:'
\echo '- Users see only their organization data'
\echo '- Different roles have appropriate permissions'
\echo '- All relationships maintain referential integrity'
\echo '- Security functions return correct results'
\echo '========================================='

-- Reset session
RESET role;
RESET request.jwt.claims;