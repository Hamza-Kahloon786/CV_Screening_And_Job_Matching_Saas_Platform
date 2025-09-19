-- Seed Data: seed_recruitment_platform.sql
-- Description: Sample data for AI-powered CV screening recruitment SaaS
-- Date: 2025-01-01

-- Insert sample recruitment companies (organizations)
INSERT INTO organizations (id, company_name, slug, description, industry, company_size, subscription_plan, max_recruiters, max_jobs_per_month, max_cvs_per_job, max_ai_analyses_per_month, billing_email, ai_matching_threshold) VALUES
(
    '550e8400-e29b-41d4-a716-446655440001',
    'TechTalent Recruiters',
    'techtalent-recruiters',
    'Specialized IT recruitment agency focusing on software engineering and data science roles',
    'Recruitment Services',
    'medium',
    'professional',
    25,
    50,
    500,
    5000,
    'billing@techtalent.com',
    0.75
),
(
    '550e8400-e29b-41d4-a716-446655440002',
    'Executive Search Partners',
    'executive-search',
    'High-end executive search firm for C-level and senior management positions',
    'Executive Search',
    'small',
    'enterprise',
    15,
    20,
    200,
    2000,
    'finance@execsearch.com',
    0.80
),
(
    '550e8400-e29b-41d4-a716-446655440003',
    'StartupCrew Hiring',
    'startupcrew',
    'Fast-growing recruitment startup serving early-stage tech companies',
    'Recruitment Technology',
    'startup',
    'basic',
    10,
    30,
    300,
    3000,
    'admin@startupcrew.io',
    0.70
);

-- Insert sample recruiters and admins
INSERT INTO users (id, email, password_hash, first_name, last_name, job_title, specializations, timezone, email_verified_at) VALUES
(
    '550e8400-e29b-41d4-a716-446655440101',
    'sarah.martinez@techtalent.com',
    '$2b$10$example_hash_for_sarah_martinez_password',
    'Sarah',
    'Martinez',
    'Senior Technical Recruiter',
    '{"Software Engineering", "DevOps", "Data Science"}',
    'America/New_York',
    NOW() - INTERVAL '45 days'
),
(
    '550e8400-e29b-41d4-a716-446655440102',
    'james.wilson@techtalent.com',
    '$2b$10$example_hash_for_james_wilson_password',
    'James',
    'Wilson',
    'AI/ML Recruitment Specialist',
    '{"Machine Learning", "AI Research", "Data Engineering"}',
    'America/Los_Angeles',
    NOW() - INTERVAL '30 days'
),
(
    '550e8400-e29b-41d4-a716-446655440103',
    'elizabeth.brown@execsearch.com',
    '$2b$10$example_hash_for_elizabeth_brown_password',
    'Elizabeth',
    'Brown',
    'Managing Partner',
    '{"Executive Search", "C-Suite", "Board Positions"}',
    'America/Chicago',
    NOW() - INTERVAL '60 days'
),
(
    '550e8400-e29b-41d4-a716-446655440104',
    'david.kim@startupcrew.io',
    '$2b$10$example_hash_for_david_kim_password',
    'David',
    'Kim',
    'Lead Recruiter',
    '{"Full Stack", "Frontend", "Backend", "Mobile"}',
    'America/Los_Angeles',
    NOW() - INTERVAL '20 days'
),
(
    '550e8400-e29b-41d4-a716-446655440105',
    'maria.garcia@techtalent.com',
    '$2b$10$example_hash_for_maria_garcia_password',
    'Maria',
    'Garcia',
    'Recruitment Coordinator',
    '{"Junior Roles", "Internships", "Entry Level"}',
    'America/New_York',
    NOW() - INTERVAL '15 days'
);

-- Insert organization memberships with recruitment-specific permissions
INSERT INTO organization_members (organization_id, user_id, role, can_create_jobs, can_upload_cvs, can_run_ai_analysis, can_export_results, can_manage_team, can_view_analytics, joined_at) VALUES
-- TechTalent Recruiters team
('550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440101', 'admin', true, true, true, true, true, true, NOW() - INTERVAL '45 days'),
('550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440102', 'senior_recruiter', true, true, true, true, false, true, NOW() - INTERVAL '30 days'),
('550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440105', 'recruiter', true, true, true, true, false, false, NOW() - INTERVAL '15 days'),

-- Executive Search Partners
('550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440103', 'owner', true, true, true, true, true, true, NOW() - INTERVAL '60 days'),

-- StartupCrew Hiring
('550e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440104', 'owner', true, true, true, true, true, true, NOW() - INTERVAL '20 days');

-- Insert sample job postings
INSERT INTO jobs (id, organization_id, title, description, requirements, responsibilities, company_name, location, job_type, experience_level, salary_min, salary_max, required_skills, preferred_skills, education_requirements, remote_work, status, created_by, ai_processed_at, ai_processing_status, total_cvs_uploaded) VALUES
(
    '550e8400-e29b-41d4-a716-446655440201',
    '550e8400-e29b-41d4-a716-446655440001',
    'Senior Full Stack Developer',
    'We are seeking an experienced Full Stack Developer to join our growing engineering team. You will work on building scalable web applications using modern technologies and frameworks.',
    'Minimum 5 years of experience in full stack development. Strong proficiency in JavaScript, React, Node.js, and database management. Experience with cloud platforms (AWS/Azure). Strong problem-solving skills and attention to detail.',
    'Design and develop web applications from frontend to backend. Collaborate with product managers and designers. Write clean, maintainable code. Participate in code reviews and technical discussions. Mentor junior developers.',
    'InnovateTech Solutions',
    'San Francisco, CA',
    'full_time',
    'senior',
    120000.00,
    180000.00,
    '{"JavaScript", "React", "Node.js", "PostgreSQL", "AWS", "Git"}',
    '{"TypeScript", "Docker", "Kubernetes", "Redis", "GraphQL"}',
    'Bachelor''s degree in Computer Science or equivalent experience',
    true,
    'active',
    '550e8400-e29b-41d4-a716-446655440101',
    NOW() - INTERVAL '2 hours',
    'completed',
    127
),
(
    '550e8400-e29b-41d4-a716-446655440202',
    '550e8400-e29b-41d4-a716-446655440001',
    'Machine Learning Engineer',
    'Join our AI team to build and deploy machine learning models that power our recommendation engine and drive business decisions.',
    'PhD or Master''s in Computer Science, Statistics, or related field. 3+ years of experience in ML engineering. Strong Python skills. Experience with TensorFlow/PyTorch. Knowledge of MLOps practices.',
    'Develop and deploy ML models. Design experiments and analyze results. Build data pipelines. Collaborate with data scientists and engineers. Optimize model performance.',
    'DataDriven Analytics',
    'Remote (US)',
    'full_time',
    'mid',
    140000.00,
    200000.00,
    '{"Python", "Machine Learning", "TensorFlow", "PyTorch", "SQL", "Statistics"}',
    '{"MLflow", "Kubeflow", "Apache Spark", "Kubernetes", "MLOps"}',
    'Master''s or PhD in relevant field',
    true,
    'active',
    '550e8400-e29b-41d4-a716-446655440102',
    NOW() - INTERVAL '1 hour',
    'completed',
    89
),
(
    '550e8400-e29b-41d4-a716-446655440203',
    '550e8400-e29b-41d4-a716-446655440002',
    'Chief Technology Officer',
    'Lead our technology vision and strategy for a fast-growing fintech startup. Build and manage a world-class engineering team.',
    'Minimum 10 years of technology leadership experience. Previous CTO or VP Engineering experience at high-growth companies. Strong technical background in modern software architecture. Experience scaling engineering teams.',
    'Define technology strategy and roadmap. Build and lead engineering team. Ensure scalable and secure architecture. Partner with CEO and other executives. Drive innovation and technical excellence.',
    'FinTech Innovations',
    'New York, NY',
    'full_time',
    'executive',
    300000.00,
    450000.00,
    '{"Technology Leadership", "Software Architecture", "Team Management", "Fintech", "Scaling"}',
    '{"Cloud Architecture", "Security", "AI/ML", "Blockchain", "Startup Experience"}',
    'Bachelor''s degree in Engineering or Computer Science',
    false,
    'active',
    '550e8400-e29b-41d4-a716-446655440103',
    NOW() - INTERVAL '30 minutes',
    'completed',
    45
),
(
    '550e8400-e29b-41d4-a716-446655440204',
    '550e8400-e29b-41d4-a716-446655440003',
    'Frontend Developer (React)',
    'Join our startup to build beautiful, responsive user interfaces that delight our customers.',
    '2+ years of React development experience. Strong JavaScript and CSS skills. Experience with modern frontend tools and frameworks. Understanding of responsive design principles.',
    'Build responsive web applications using React. Collaborate with designers and backend developers. Write clean, efficient code. Participate in agile development process.',
    'GrowthApp Startup',
    'Austin, TX',
    'full_time',
    'mid',
    80000.00,
    120000.00,
    '{"React", "JavaScript", "CSS", "HTML", "Git"}',
    '{"TypeScript", "Next.js", "Styled Components", "Jest", "Webpack"}',
    'Bachelor''s degree preferred or equivalent experience',
    true,
    'active',
    '550e8400-e29b-41d4-a716-446655440104',
    NOW() - INTERVAL '45 minutes',
    'completed',
    203
);

-- Insert sample CVs
INSERT INTO cvs (id, organization_id, job_id, original_filename, file_url, file_size, file_type, candidate_name, candidate_email, candidate_phone, candidate_location, extracted_skills, years_of_experience, ai_processed_at, ai_processing_status, status, uploaded_by) VALUES
(
    '550e8400-e29b-41d4-a716-446655440301',
    '550e8400-e29b-41d4-a716-446655440001',
    '550e8400-e29b-41d4-a716-446655440201',
    'john_doe_fullstack_cv.pdf',
    'https://storage.example.com/cvs/john_doe_fullstack_cv.pdf',
    245760,
    'application/pdf',
    'John Doe',
    'john.doe@email.com',
    '+1-555-0123',
    'San Francisco, CA',
    '{"JavaScript", "React", "Node.js", "PostgreSQL", "AWS", "Docker", "TypeScript"}',
    6,
    NOW() - INTERVAL '1 hour',
    'completed',
    'processed',
    '550e8400-e29b-41d4-a716-446655440101'
),
(
    '550e8400-e29b-41d4-a716-446655440302',
    '550e8400-e29b-41d4-a716-446655440001',
    '550e8400-e29b-41d4-a716-446655440201',
    'alice_smith_developer.pdf',
    'https://storage.example.com/cvs/alice_smith_developer.pdf',
    189440,
    'application/pdf',
    'Alice Smith',
    'alice.smith@email.com',
    '+1-555-0456',
    'Seattle, WA',
    '{"JavaScript", "React", "Python", "Django", "MySQL", "Git"}',
    4,
    NOW() - INTERVAL '1 hour',
    'completed',
    'processed',
    '550e8400-e29b-41d4-a716-446655440101'
),
(
    '550e8400-e29b-41d4-a716-446655440303',
    '550e8400-e29b-41d4-a716-446655440001',
    '550e8400-e29b-41d4-a716-446655440202',
    'dr_michael_chen_ml.pdf',
    'https://storage.example.com/cvs/dr_michael_chen_ml.pdf',
    367104,
    'application/pdf',
    'Dr. Michael Chen',
    'michael.chen@university.edu',
    '+1-555-0789',
    'Boston, MA',
    '{"Python", "Machine Learning", "TensorFlow", "PyTorch", "Statistics", "Deep Learning", "MLOps"}',
    5,
    NOW() - INTERVAL '45 minutes',
    'completed',
    'processed',
    '550e8400-e29b-41d4-a716-446655440102'
),
(
    '550e8400-e29b-41d4-a716-446655440304',
    '550e8400-e29b-41d4-a716-446655440002',
    '550e8400-e29b-41d4-a716-446655440203',
    'robert_johnson_cto.pdf',
    'https://storage.example.com/cvs/robert_johnson_cto.pdf',
    445952,
    'application/pdf',
    'Robert Johnson',
    'robert.johnson@techcorp.com',
    '+1-555-0321',
    'New York, NY',
    '{"Technology Leadership", "Software Architecture", "Team Management", "Cloud Computing", "Fintech", "Scaling"}',
    12,
    NOW() - INTERVAL '20 minutes',
    'completed',
    'processed',
    '550e8400-e29b-41d4-a716-446655440103'
),
(
    '550e8400-e29b-41d4-a716-446655440305',
    '550e8400-e29b-41d4-a716-446655440003',
    '550e8400-e29b-41d4-a716-446655440204',
    'emma_williams_frontend.pdf',
    'https://storage.example.com/cvs/emma_williams_frontend.pdf',
    198144,
    'application/pdf',
    'Emma Williams',
    'emma.williams@email.com',
    '+1-555-0654',
    'Austin, TX',
    '{"React", "JavaScript", "TypeScript", "CSS", "HTML", "Next.js", "Jest"}',
    3,
    NOW() - INTERVAL '30 minutes',
    'completed',
    'processed',
    '550e8400-e29b-41d4-a716-446655440104'
);

-- Insert CV-Job matches (AI analysis results)
INSERT INTO cv_job_matches (id, organization_id, job_id, cv_id, overall_match_score, skills_match_score, experience_match_score, education_match_score, location_match_score, ai_summary, ai_pros, ai_cons, matching_skills, missing_skills, ai_recommendation, ai_model_version, status) VALUES
(
    '550e8400-e29b-41d4-a716-446655440401',
    '550e8400-e29b-41d4-a716-446655440001',
    '550e8400-e29b-41d4-a716-446655440201',
    '550e8400-e29b-41d4-a716-446655440301',
    0.92,
    0.95,
    0.90,
    0.85,
    1.00,
    'Excellent match for Senior Full Stack Developer position. John has 6 years of experience with all required technologies and is located in the target city. Strong background in JavaScript, React, and Node.js with additional experience in Docker and TypeScript.',
    '{"Strong technical skills in all required technologies", "6 years of relevant experience", "Located in San Francisco", "Experience with Docker and TypeScript", "AWS cloud experience"}',
    '{"Salary expectation might be on higher end", "No explicit team leadership experience mentioned"}',
    '{"JavaScript", "React", "Node.js", "PostgreSQL", "AWS", "Git"}',
    '{}',
    'strong_match',
    'gpt-4-cv-analyzer-v1.2',
    'new'
),
(
    '550e8400-e29b-41d4-a716-446655440402',
    '550e8400-e29b-41d4-a716-446655440001',
    '550e8400-e29b-41d4-a716-446655440201',
    '550e8400-e29b-41d4-a716-446655440302',
    0.78,
    0.75,
    0.70,
    0.85,
    0.85,
    'Good match for Senior Full Stack Developer role. Alice has solid 4 years of experience but may need some upskilling in backend technologies. Strong React skills and willingness to relocate.',
    '{"Strong React and frontend skills", "Python and Django experience", "Good cultural fit", "Open to relocation"}',
    '{"Limited Node.js experience", "Only 4 years experience vs 5+ required", "No AWS cloud experience", "Limited PostgreSQL knowledge"}',
    '{"JavaScript", "React", "Git"}',
    '{"Node.js", "PostgreSQL", "AWS"}',
    'good_match',
    'gpt-4-cv-analyzer-v1.2',
    'new'
),
(
    '550e8400-e29b-41d4-a716-446655440403',
    '550e8400-e29b-41d4-a716-446655440001',
    '550e8400-e29b-41d4-a716-446655440202',
    '550e8400-e29b-41d4-a716-446655440303',
    0.96,
    0.98,
    0.95,
    1.00,
    0.90,
    'Outstanding match for Machine Learning Engineer position. Dr. Chen has PhD-level education and 5 years of hands-on ML experience. Expertise covers all required technologies with additional MLOps experience.',
    '{"PhD in relevant field", "5 years ML engineering experience", "Expert in TensorFlow and PyTorch", "MLOps and deployment experience", "Strong academic background", "Deep learning expertise"}',
    '{"May expect higher compensation due to PhD", "Academic background might need industry adjustment"}',
    '{"Python", "Machine Learning", "TensorFlow", "PyTorch", "Statistics"}',
    '{}',
    'strong_match',
    'gpt-4-cv-analyzer-v1.2',
    'new'
),
(
    '550e8400-e29b-41d4-a716-446655440404',
    '550e8400-e29b-41d4-a716-446655440002',
    '550e8400-e29b-41d4-a716-446655440203',
    '550e8400-e29b-41d4-a716-446655440304',
    0.89,
    0.90,
    0.95,
    0.80,
    1.00,
    'Strong match for CTO position. Robert brings 12 years of technology leadership experience with proven track record in fintech and scaling teams. Located in target market.',
    '{"12+ years technology leadership", "Previous fintech experience", "Proven team scaling experience", "Strong software architecture background", "Located in New York", "Cloud computing expertise"}',
    '{"May be expensive for startup budget", "Might be overqualified for early-stage startup"}',
    '{"Technology Leadership", "Software Architecture", "Team Management", "Fintech", "Scaling"}',
    '{"Startup Experience"}',
    'strong_match',
    'gpt-4-cv-analyzer-v1.2',
    'new'
),
(
    '550e8400-e29b-41d4-a716-446655440405',
    '550e8400-e29b-41d4-a716-446655440003',
    '550e8400-e29b-41d4-a716-446655440204',
    '550e8400-e29b-41d4-a716-446655440305',
    0.87,
    0.90,
    0.80,
    0.85,
    1.00,
    'Strong match for Frontend Developer position. Emma has 3 years of React experience with modern frontend technologies. Located in Austin and demonstrates strong technical skills.',
    '{"Strong React and TypeScript skills", "3 years relevant experience", "Next.js experience", "Testing experience with Jest", "Located in Austin", "Modern frontend tooling knowledge"}',
    '{"Slightly less experience than ideal", "No mention of responsive design experience", "Limited backend exposure"}',
    '{"React", "JavaScript", "CSS", "HTML", "Git"}',
    '{}',
    'strong_match',
    'gpt-4-cv-analyzer-v1.2',
    'new'
);

-- Insert some match actions (recruiter activities)
INSERT INTO match_actions (match_id, action_type, notes, performed_by) VALUES
(
    '550e8400-e29b-41d4-a716-446655440401',
    'viewed',
    'Initial review of top candidate',
    '550e8400-e29b-41d4-a716-446655440101'
),
(
    '550e8400-e29b-41d4-a716-446655440401',
    'shortlisted',
    'Excellent technical match, scheduling phone screen',
    '550e8400-e29b-41d4-a716-446655440101'
),
(
    '550e8400-e29b-41d4-a716-446655440403',
    'viewed',
    'Reviewing ML engineer candidate',
    '550e8400-e29b-41d4-a716-446655440102'
),
(
    '550e8400-e29b-41d4-a716-446655440404',
    'downloaded',
    'Downloading full CV for executive review',
    '550e8400-e29b-41d4-a716-446655440103'
),
(
    '550e8400-e29b-41d4-a716-446655440405',
    'contacted',
    'Reached out via LinkedIn for initial conversation',
    '550e8400-e29b-41d4-a716-446655440104'
);

-- Update match statuses based on actions
UPDATE cv_job_matches SET status = 'shortlisted', reviewed_by = '550e8400-e29b-41d4-a716-446655440101', reviewed_at = NOW() WHERE id = '550e8400-e29b-41d4-a716-446655440401';
UPDATE cv_job_matches SET status = 'reviewed', reviewed_by = '550e8400-e29b-41d4-a716-446655440102', reviewed_at = NOW() WHERE id = '550e8400-e29b-41d4-a716-446655440403';
UPDATE cv_job_matches SET status = 'reviewed', reviewed_by = '550e8400-e29b-41d4-a716-446655440103', reviewed_at = NOW() WHERE id = '550e8400-e29b-41d4-a716-446655440404';
UPDATE cv_job_matches SET status = 'contacted', reviewed_by = '550e8400-e29b-41d4-a716-446655440104', reviewed_at = NOW() WHERE id = '550e8400-e29b-41d4-a716-446655440405';

-- Insert some AI processing queue examples
INSERT INTO ai_processing_queue (organization_id, job_id, cv_id, task_type, priority, status, payload) VALUES
(
    '550e8400-e29b-41d4-a716-446655440001',
    '550e8400-e29b-41d4-a716-446655440201',
    NULL,
    'process_job_description',
    1,
    'completed',
    '{"job_id": "550e8400-e29b-41d4-a716-446655440201", "extract_keywords": true, "analyze_requirements": true}'
),
(
    '550e8400-e29b-41d4-a716-446655440001',
    NULL,
    '550e8400-e29b-41d4-a716-446655440301',
    'extract_cv_content',
    2,
    'completed',
    '{"cv_id": "550e8400-e29b-41d4-a716-446655440301", "extract_skills": true, "extract_experience": true}'
),
(
    '550e8400-e29b-41d4-a716-446655440001',
    '550e8400-e29b-41d4-a716-446655440201',
    '550e8400-e29b-41d4-a716-446655440301',
    'match_cv_to_job',
    1,
    'completed',
    '{"job_id": "550e8400-e29b-41d4-a716-446655440201", "cv_id": "550e8400-e29b-41d4-a716-446655440301", "generate_summary": true}'
);