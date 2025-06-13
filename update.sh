
#!/bin/bash

# Streamly Control Hub - Update Script
# Updates the application to the latest version

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="streamly"
APP_DIR="/var/www/streamly"
BACKUP_DIR="/var/backups/streamly"
SERVICE_NAME="streamly"
REPO_URL="https://github.com/kambire/streamly-control-hub.git"

# Functions
print_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 Streamly Control Hub                         ║"
    echo "║                      Update Script                           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root. Use: sudo $0"
    fi
}

check_app_exists() {
    if [[ ! -d "$APP_DIR" ]]; then
        print_error "Application directory not found: $APP_DIR"
    fi
    
    if [[ ! -f "$APP_DIR/package.json" ]]; then
        print_error "package.json not found. Is this a valid Streamly installation?"
    fi
}

create_backup() {
    print_info "Creating backup..."
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Create timestamped backup
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$BACKUP_DIR/streamly_backup_$TIMESTAMP.tar.gz"
    
    # Stop service before backup
    systemctl stop "$SERVICE_NAME" || true
    
    # Create backup excluding node_modules and build files
    cd "$APP_DIR"
    tar -czf "$BACKUP_FILE" \
        --exclude='node_modules' \
        --exclude='dist' \
        --exclude='build' \
        --exclude='.git' \
        --exclude='*.log' \
        .
    
    print_success "Backup created: $BACKUP_FILE"
}

get_current_version() {
    cd "$APP_DIR"
    CURRENT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    print_info "Current version: $CURRENT_BRANCH ($CURRENT_COMMIT)"
}

pull_updates() {
    print_info "Pulling latest updates from repository..."
    
    cd "$APP_DIR"
    
    # Stash any local changes
    git stash push -m "Auto-stash before update $(date)"
    
    # Fetch latest changes
    git fetch origin
    
    # Get current branch
    BRANCH=$(git branch --show-current)
    if [[ -z "$BRANCH" ]]; then
        BRANCH="main"
        print_warning "Could not determine current branch, using main"
    fi
    
    # Pull latest changes
    git pull origin "$BRANCH"
    
    NEW_COMMIT=$(git rev-parse HEAD)
    
    if [[ "$CURRENT_COMMIT" == "$NEW_COMMIT" ]]; then
        print_info "Already up to date!"
        UPDATE_AVAILABLE=false
    else
        print_success "Updated to: $BRANCH ($NEW_COMMIT)"
        UPDATE_AVAILABLE=true
    fi
}

update_dependencies() {
    if [[ "$UPDATE_AVAILABLE" == true ]]; then
        print_info "Updating dependencies..."
        cd "$APP_DIR"
        
        # Check if package-lock.json changed
        if git diff --name-only "$CURRENT_COMMIT" HEAD | grep -q "package-lock.json\|package.json"; then
            print_info "Package files changed, running npm ci..."
            npm ci
        else
            print_info "No package changes detected"
        fi
        
        print_success "Dependencies updated"
    fi
}

build_application() {
    if [[ "$UPDATE_AVAILABLE" == true ]]; then
        print_info "Building application..."
        cd "$APP_DIR"
        
        # Clean previous build
        rm -rf dist build
        
        # Build application
        npm run build
        
        print_success "Application built successfully"
    fi
}

restart_services() {
    if [[ "$UPDATE_AVAILABLE" == true ]]; then
        print_info "Restarting services..."
        
        # Restart application service
        systemctl restart "$SERVICE_NAME"
        
        # Wait for service to start
        sleep 3
        
        # Check service status
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            print_success "Service restarted successfully"
        else
            print_error "Service failed to start. Check logs: journalctl -u $SERVICE_NAME"
        fi
        
        # Reload Nginx configuration
        nginx -t && systemctl reload nginx
        print_success "Nginx reloaded"
    fi
}

verify_update() {
    print_info "Verifying update..."
    
    # Check if service is running
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        print_success "Service is running"
    else
        print_error "Service is not running"
    fi
    
    # Check if application responds
    sleep 5
    if curl -f -s http://localhost:8080 > /dev/null; then
        print_success "Application is responding"
    else
        print_warning "Application may not be responding correctly"
    fi
}

cleanup_old_backups() {
    print_info "Cleaning up old backups..."
    
    # Keep only last 5 backups
    cd "$BACKUP_DIR"
    ls -t streamly_backup_*.tar.gz 2>/dev/null | tail -n +6 | xargs rm -f || true
    
    print_success "Old backups cleaned up"
}

rollback() {
    print_error "Update failed! Starting rollback process..."
    
    # Stop service
    systemctl stop "$SERVICE_NAME" || true
    
    # Find latest backup
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/streamly_backup_*.tar.gz 2>/dev/null | head -n1)
    
    if [[ -n "$LATEST_BACKUP" ]]; then
        print_info "Restoring from backup: $LATEST_BACKUP"
        
        # Remove current installation
        rm -rf "$APP_DIR"
        mkdir -p "$APP_DIR"
        
        # Restore from backup
        tar -xzf "$LATEST_BACKUP" -C "$APP_DIR"
        
        # Restore dependencies
        cd "$APP_DIR"
        npm ci
        
        # Start service
        systemctl start "$SERVICE_NAME"
        
        print_success "Rollback completed"
    else
        print_error "No backup found for rollback!"
    fi
}

show_logs() {
    echo -e "${BLUE}📋 Recent logs:${NC}"
    journalctl -u "$SERVICE_NAME" --lines=10 --no-pager
}

print_completion() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                      Update Complete!                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${BLUE}📊 Update Summary:${NC}"
    echo "  • Previous version: $CURRENT_BRANCH ($CURRENT_COMMIT)"
    echo "  • Current version: $(git -C "$APP_DIR" branch --show-current) ($(git -C "$APP_DIR" rev-parse HEAD))"
    echo "  • Repository: $REPO_URL"
    echo "  • Backup location: $BACKUP_FILE"
    
    echo -e "${BLUE}🔧 Useful Commands:${NC}"
    echo "  • Check status: sudo systemctl status $SERVICE_NAME"
    echo "  • View logs: sudo journalctl -u $SERVICE_NAME -f"
    echo "  • Restart app: sudo systemctl restart $SERVICE_NAME"
    
    if [[ "$UPDATE_AVAILABLE" == false ]]; then
        echo -e "${GREEN}🎉 Your installation is already up to date!${NC}"
    fi
}

# Main update process
main() {
    print_header
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-backup)
                SKIP_BACKUP=true
                shift
                ;;
            --force)
                FORCE_UPDATE=true
                shift
                ;;
            --logs)
                show_logs
                exit 0
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --no-backup    Skip creating backup"
                echo "  --force        Force update even if up to date"
                echo "  --logs         Show recent application logs"
                echo "  --help         Show this help"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                ;;
        esac
    done
    
    # Pre-update checks
    check_root
    check_app_exists
    
    # Update process
    get_current_version
    
    if [[ "$SKIP_BACKUP" != true ]]; then
        create_backup
    fi
    
    # Set up error handling for rollback
    if [[ "$SKIP_BACKUP" != true ]]; then
        trap 'rollback' ERR
    fi
    
    pull_updates
    update_dependencies
    build_application
    restart_services
    verify_update
    
    # Disable error trap
    trap - ERR
    
    cleanup_old_backups
    print_completion
}

# Run main function
main "$@"
