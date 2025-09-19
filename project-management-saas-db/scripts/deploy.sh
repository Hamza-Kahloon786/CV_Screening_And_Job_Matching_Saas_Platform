#!/bin/bash

# deploy.sh - Automated deployment script for AI-powered recruitment SaaS database
# Usage: ./deploy.sh [environment] [database_url]
# Example: ./deploy.sh production postgresql://user:pass@host:5432/recruitment_db

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MIGRATIONS_DIR="$PROJECT_DIR/migrations"
SEED_DIR="$PROJECT_DIR/seed"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if psql is installed
    if ! command -v psql &> /dev/null; then
        log_error "psql is not installed. Please install PostgreSQL client."
        exit 1
    fi
    
    # Check if migration files exist
    if [ ! -d "$MIGRATIONS_DIR" ]; then
        log_error "Migrations directory not found: $MIGRATIONS_DIR"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

validate_database_connection() {
    local db_url=$1
    log_info "Validating database connection..."
    
    if ! psql "$db_url" -c "SELECT 1;" &> /dev/null; then
        log_error "Cannot connect to database: $db_url"
        exit 1
    fi
    
    log_success "Database connection validated"
}

check_migrations_table() {
    local db_url=$1
    log_info "Checking migrations tracking table..."
    
    # Create migrations table if it doesn't exist
    psql "$db_url" -c "
        CREATE TABLE IF NOT EXISTS schema_migrations (
            id SERIAL PRIMARY KEY,
            migration_name VARCHAR(255) NOT NULL UNIQUE,
            applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            checksum VARCHAR(64)
        );
    " &> /dev/null
    
    log_success "Migrations table ready"
}

get_migration_checksum() {
    local file_path=$1
    if command -v sha256sum &> /dev/null; then
        sha256sum "$file_path" | cut -d' ' -f1
    elif command -v shasum &> /dev/null; then
        shasum -a 256 "$file_path" | cut -d' ' -f1
    else
        # Fallback to basic file size and modification time
        stat -c "%s-%Y" "$file_path" 2>/dev/null || stat -f "%z-%m" "$file_path"
    fi
}

is_migration_applied() {
    local db_url=$1
    local migration_name=$2
    local checksum=$3
    
    local count=$(psql "$db_url" -t -c "
        SELECT COUNT(*) FROM schema_migrations 
        WHERE migration_name = '$migration_name' AND checksum = '$checksum';
    " | xargs)
    
    [ "$count" -gt 0 ]
}

apply_migration() {
    local db_url=$1
    local migration_file=$2
    local migration_name=$(basename "$migration_file")
    local checksum=$(get_migration_checksum "$migration_file")
    
    if is_migration_applied "$db_url" "$migration_name" "$checksum"; then
        log_info "Migration $migration_name already applied (checksum: $checksum)"
        return 0
    fi
    
    log_info "Applying migration: $migration_name"
    
    # Begin transaction
    psql "$db_url" -c "BEGIN;" &> /dev/null
    
    # Apply migration
    if psql "$db_url" -f "$migration_file" &> /dev/null; then
        # Record successful migration
        psql "$db_url" -c "
            INSERT INTO schema_migrations (migration_name, checksum) 
            VALUES ('$migration_name', '$checksum')
            ON CONFLICT (migration_name) 
            DO UPDATE SET checksum = EXCLUDED.checksum, applied_at = NOW();
        " &> /dev/null
        
        # Commit transaction
        psql "$db_url" -c "COMMIT;" &> /dev/null
        log_success "Migration $migration_name applied successfully"
    else
        # Rollback on error
        psql "$db_url" -c "ROLLBACK;" &> /dev/null
        log_error "Failed to apply migration: $migration_name"
        exit 1
    fi
}

run_migrations() {
    local db_url=$1
    log_info "Running database migrations..."
    
    # Apply migrations in order
    local migrations=(
        "001_create_organizations.sql"
        "002_create_users.sql"
        "003_create_jobs_and_cvs.sql"
        "004_create_rls_policies.sql"
    )
    
    for migration in "${migrations[@]}"; do
        local migration_path="$MIGRATIONS_DIR/$migration"
        if [ -f "$migration_path" ]; then
            apply_migration "$db_url" "$migration_path"
        else
            log_warning "Migration file not found: $migration_path"
        fi
    done
    
    log_success "All migrations completed"
}

load_seed_data() {
    local db_url=$1
    local environment=$2
    
    if [ "$environment" = "production" ]; then
        log_warning "Skipping seed data for production environment"
        return 0
    fi
    
    local seed_file="$SEED_DIR/seed_recruitment_platform.sql"
    if [ -f "$seed_file" ]; then
        log_info "Loading seed data..."
        if psql "$db_url" -f "$seed_file" &> /dev/null; then
            log_success "Seed data loaded successfully"
        else
            log_error "Failed to load seed data"
            exit 1
        fi
    else
        log_warning "Seed file not found: $seed_file"
    fi
}

run_post_deployment_checks() {
    local db_url=$1
    log_info "Running post-deployment checks..."
    
    # Check if key tables exist
    local tables=("organizations" "users" "jobs" "cvs" "cv_job_matches")
    
    for table in "${tables[@]}"; do
        local count=$(psql "$db_url" -t -c "
            SELECT COUNT(*) FROM information_schema.tables 
            WHERE table_name = '$table';
        " | xargs)
        
        if [ "$count" -eq 0 ]; then
            log_error "Table '$table' not found"
            exit 1
        fi
    done
    
    # Check if RLS is enabled
    local rls_count=$(psql "$db_url" -t -c "
        SELECT COUNT(*) FROM pg_class 
        WHERE relname IN ('organizations', 'jobs', 'cvs') 
        AND relrowsecurity = true;
    " | xargs)
    
    if [ "$rls_count" -lt 3 ]; then
        log_error "Row Level Security not properly enabled"
        exit 1
    fi
    
    log_success "Post-deployment checks passed"
}

show_usage() {
    echo "Usage: $0 [environment] [database_url]"
    echo ""
    echo "Arguments:"
    echo "  environment     Deployment environment (development|staging|production)"
    echo "  database_url    PostgreSQL connection URL"
    echo ""
    echo "Examples:"
    echo "  $0 development postgresql://user:pass@localhost:5432/recruitment_dev"
    echo "  $0 production postgresql://user:pass@prod-host:5432/recruitment_prod"
    echo ""
    echo "Environment variables can also be used:"
    echo "  DATABASE_URL    PostgreSQL connection URL"
    echo "  ENVIRONMENT     Deployment environment"
}

main() {
    local environment=${1:-$ENVIRONMENT}
    local db_url=${2:-$DATABASE_URL}
    
    # Validate arguments
    if [ -z "$environment" ] || [ -z "$db_url" ]; then
        log_error "Missing required arguments"
        show_usage
        exit 1
    fi
    
    # Validate environment
    if [[ ! "$environment" =~ ^(development|staging|production)$ ]]; then
        log_error "Invalid environment: $environment"
        log_error "Must be one of: development, staging, production"
        exit 1
    fi
    
    log_info "Starting deployment for $environment environment"
    log_info "Database: $db_url"
    
    # Run deployment steps
    check_prerequisites
    validate_database_connection "$db_url"
    check_migrations_table "$db_url"
    run_migrations "$db_url"
    load_seed_data "$db_url" "$environment"
    run_post_deployment_checks "$db_url"
    
    log_success "Deployment completed successfully!"
    log_info "Environment: $environment"
    log_info "Database: $db_url"
    
    if [ "$environment" != "production" ]; then
        log_info "Sample data has been loaded for testing"
        log_info "You can now test the application with the seed data"
    fi
}

# Run main function with all arguments
main "$@"