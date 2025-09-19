-- run_all_migrations.sql
-- Master script to run all migrations and seed data
-- Date: 2025-01-01

\echo 'Starting database setup for Project Management SaaS...'

\echo 'Creating organizations table...'
\i migrations/001_create_organizations.sql

\echo 'Creating users and membership tables...'
\i migrations/002_create_users.sql

\echo 'Creating projects and tasks tables...'
\i migrations/003_create_projects_and_tasks.sql

\echo 'Setting up Row Level Security policies...'
\i migrations/004_create_rls_policies.sql

\echo 'Loading sample data...'
\i seed/seed_sample_data.sql

\echo 'Database setup completed successfully!'

-- Verify setup
\echo 'Verification - Tables created:'
\dt

\echo 'Verification - Sample organizations:'
SELECT name, subscription_plan, max_users FROM organizations;

\echo 'Verification - Sample users:'
SELECT email, first_name || ' ' || last_name AS full_name FROM users;

\echo 'Verification - Sample projects:'
SELECT name, status, priority FROM projects;

\echo 'Setup complete! Your Project Management SaaS database is ready.'