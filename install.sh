#!/bin/bash

# Streamly Control Hub - Installation Script
# Compatible with Ubuntu 22.04 LTS

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
NODE_VERSION="20"
REPO_URL="https://github.com/kambire/streamly-control-hub.git"
DOMAIN=""
SSL_EMAIL=""

# Set non-interactive mode
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export NEEDRESTART_SUSPEND=1

# Functions
print_header() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 Streamly Control Hub                         ║"
    echo "║                    Installation Script                       ║"
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

check_os() {
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot determine OS version"
    fi
    
    . /etc/os-release
    if [[ "$ID" != "ubuntu" ]] || [[ "$VERSION_ID" != "22.04" ]]; then
        print_warning "This script is optimized for Ubuntu 22.04. Proceeding anyway..."
    fi
}

configure_noninteractive() {
    print_info "Configuring non-interactive mode..."
    
    # Configure debconf for non-interactive mode
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
    
    # Disable needrestart prompts
    if [[ -f /etc/needrestart/needrestart.conf ]]; then
        sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
    fi
    
    # Create needrestart config if it doesn't exist
    mkdir -p /etc/needrestart
    cat > /etc/needrestart/needrestart.conf << 'EOF'
# Restart services automatically
$nrconf{restart} = 'a';
$nrconf{kernelhints} = 0;
EOF
    
    print_success "Non-interactive mode configured"
}

update_system() {
    print_info "Updating system packages..."
    apt-get update -qq
    apt-get upgrade -y -qq
    print_success "System updated successfully"
}

install_dependencies() {
    print_info "Installing system dependencies..."
    
    # Pre-configure packages to avoid prompts
    echo "postfix postfix/mailname string localhost" | debconf-set-selections
    echo "postfix postfix/main_mailer_type string 'No configuration'" | debconf-set-selections
    
    apt-get install -y -qq \
        curl \
        git \
        nginx \
        certbot \
        python3-certbot-nginx \
        ufw \
        htop \
        unzip \
        software-properties-common \
        build-essential \
        ca-certificates \
        gnupg \
        lsb-release
    
    print_success "Dependencies installed"
}

install_nodejs() {
    print_info "Installing Node.js via NodeSource repository..."
    
    # Remove any existing Node.js installations
    apt-get remove -y -qq nodejs npm 2>/dev/null || true
    apt-get autoremove -y -qq 2>/dev/null || true
    
    # Create directory for GPG key
    mkdir -p /etc/apt/keyrings
    
    # Download and add NodeSource GPG key
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    
    # Add NodeSource repository
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
    
    # Update package list and install Node.js
    apt-get update -qq
    apt-get install -y -qq nodejs
    
    # Verify installation
    node_version=$(node --version)
    npm_version=$(npm --version)
    
    print_success "Node.js ${node_version} and npm ${npm_version} installed"
}

setup_application() {
    print_info "Setting up Streamly Control Hub..."
    
    # Create application directory
    mkdir -p "$APP_DIR"
    cd "$APP_DIR"
    
    # Clone repository
    print_info "Cloning repository from GitHub..."
    git clone "$REPO_URL" . --quiet
    
    # Install npm dependencies
    print_info "Installing application dependencies..."
    npm install --silent --no-progress
    
    # Build application
    print_info "Building application..."
    npm run build --silent
    
    # Create a simple server file for production
    cat > "$APP_DIR/dist/server.js" << 'EOF'
const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 8080;
const HOST = process.env.HOST || '0.0.0.0';

// Serve static files from dist directory
app.use(express.static(path.join(__dirname)));

// Handle all routes by serving index.html (SPA)
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(PORT, HOST, () => {
  console.log(`Streamly Control Hub running on http://${HOST}:${PORT}`);
});
EOF
    
    # Install express for the server
    npm install express --save --silent
    
    print_success "Streamly Control Hub setup completed"
}

configure_nginx() {
    print_info "Configuring Nginx..."
    
    # Stop nginx if running
    systemctl stop nginx 2>/dev/null || true
    
    # Backup default configuration
    cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup 2>/dev/null || true
    
    # Create Streamly configuration
    cat > /etc/nginx/sites-available/streamly << 'EOF'
server {
    listen 80;
    server_name _;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript application/json;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeout settings
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Static assets caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
    
    # Enable the site
    ln -sf /etc/nginx/sites-available/streamly /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test configuration
    nginx -t || print_error "Nginx configuration test failed"
    
    # Start and enable nginx
    systemctl start nginx
    systemctl enable nginx --quiet
    
    print_success "Nginx configured and started"
}

create_systemd_service() {
    print_info "Creating systemd service..."
    
    cat > /etc/systemd/system/streamly.service << EOF
[Unit]
Description=Streamly Control Hub
Documentation=https://github.com/kambire/streamly-control-hub
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/node $APP_DIR/dist/server.js
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=10
KillMode=mixed
TimeoutStopSec=5
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$APP_DIR
NoNewPrivileges=true

# Environment
Environment=NODE_ENV=production
Environment=PORT=8080
Environment=HOST=0.0.0.0

[Install]
WantedBy=multi-user.target
EOF
    
    # Set correct permissions
    chown -R www-data:www-data "$APP_DIR"
    
    # Reload systemd and start service
    systemctl daemon-reload
    systemctl enable streamly --quiet
    
    # Wait a moment before starting
    sleep 2
    systemctl start streamly
    
    # Wait for service to start and check status
    sleep 5
    if systemctl is-active --quiet streamly; then
        print_success "Systemd service created and started successfully"
    else
        print_warning "Service may not have started correctly, checking..."
        systemctl status streamly --no-pager -l
        print_info "Attempting to restart service..."
        systemctl restart streamly
        sleep 3
        if systemctl is-active --quiet streamly; then
            print_success "Service restarted successfully"
        else
            print_error "Service failed to start. Check logs with: journalctl -u streamly -f"
        fi
    fi
}

configure_firewall() {
    print_info "Configuring UFW firewall..."
    
    # Reset UFW to defaults
    ufw --force reset >/dev/null 2>&1
    
    # Default policies
    ufw default deny incoming >/dev/null 2>&1
    ufw default allow outgoing >/dev/null 2>&1
    
    # Allow SSH (be careful not to lock yourself out!)
    ufw allow ssh >/dev/null 2>&1
    
    # Allow HTTP and HTTPS
    ufw allow 'Nginx Full' >/dev/null 2>&1
    
    # Enable firewall
    echo "y" | ufw enable >/dev/null 2>&1
    
    print_success "Firewall configured"
}

setup_ssl() {
    if [[ -n "$DOMAIN" ]] && [[ -n "$SSL_EMAIL" ]]; then
        print_info "Setting up SSL certificate for $DOMAIN..."
        
        # Update Nginx configuration with domain
        sed -i "s/server_name _;/server_name $DOMAIN;/" /etc/nginx/sites-available/streamly
        nginx -t && systemctl reload nginx
        
        # Get SSL certificate
        certbot --nginx -d "$DOMAIN" --email "$SSL_EMAIL" --agree-tos --non-interactive --quiet
        
        print_success "SSL certificate installed"
    else
        print_warning "Skipping SSL setup (no domain/email provided)"
        print_info "To setup SSL later, run: sudo certbot --nginx -d your-domain.com"
    fi
}

verify_services() {
    print_info "Verifying services..."
    
    # Check if application is responding
    print_info "Testing application connectivity..."
    sleep 3
    
    local retries=5
    local count=0
    
    while [ $count -lt $retries ]; do
        if curl -f -s http://localhost:8080 > /dev/null 2>&1; then
            print_success "Application is responding on port 8080"
            break
        else
            print_warning "Application not responding, attempt $((count + 1))/$retries"
            sleep 5
            ((count++))
        fi
    done
    
    if [ $count -eq $retries ]; then
        print_error "Application failed to respond after $retries attempts"
        print_info "Checking service logs..."
        journalctl -u streamly --lines=20 --no-pager
        print_info "Attempting manual restart..."
        systemctl restart streamly
        sleep 10
        if curl -f -s http://localhost:8080 > /dev/null 2>&1; then
            print_success "Application responding after restart"
        else
            print_error "Application still not responding. Manual intervention required."
        fi
    fi
    
    # Test Nginx configuration
    print_info "Testing Nginx configuration..."
    if nginx -t; then
        print_success "Nginx configuration is valid"
        systemctl reload nginx
        print_success "Nginx reloaded successfully"
    else
        print_error "Nginx configuration test failed"
    fi
    
    # Test full pipeline
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    print_info "Testing full request pipeline..."
    if curl -f -s http://localhost > /dev/null 2>&1; then
        print_success "Full pipeline test successful"
    else
        print_warning "Full pipeline test failed - may need manual configuration"
    fi
}

print_completion() {
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                     Installation Complete!                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${BLUE}📊 Installation Summary:${NC}"
    echo "  • Application: Streamly Control Hub"
    echo "  • Version: Latest from GitHub"
    echo "  • Directory: $APP_DIR"
    echo "  • Repository: $REPO_URL"
    echo "  • Service: streamly.service"
    echo "  • Web Server: Nginx (Port 80)"
    echo "  • App Server: Express.js (Port 8080)"
    echo "  • Firewall: UFW (enabled)"
    
    echo -e "${BLUE}🌐 Access Information:${NC}"
    if [[ -n "$DOMAIN" ]]; then
        echo "  • Primary URL: https://$DOMAIN"
        echo "  • Alternative: http://$DOMAIN"
    else
        echo "  • Primary URL: http://$SERVER_IP"
        echo "  • Local URL: http://localhost"
    fi
    echo "  • Default credentials: No authentication required"
    echo "  • Admin panel: Available at root URL"
    
    echo -e "${BLUE}🔧 Installed Components:${NC}"
    echo "  • Node.js $(node --version)"
    echo "  • npm $(npm --version)"
    echo "  • Express.js (production server)"
    echo "  • Nginx $(nginx -v 2>&1 | grep -o 'nginx/[0-9.]*')"
    echo "  • UFW Firewall (active)"
    echo "  • Certbot (for SSL certificates)"
    echo "  • Git (for updates)"
    
    echo -e "${BLUE}🔍 Service Status:${NC}"
    if systemctl is-active --quiet streamly; then
        echo "  • Streamly Service: ✓ Running"
    else
        echo "  • Streamly Service: ✗ Stopped"
    fi
    
    if systemctl is-active --quiet nginx; then
        echo "  • Nginx Service: ✓ Running"
    else
        echo "  • Nginx Service: ✗ Stopped"
    fi
    
    if curl -f -s http://localhost:8080 > /dev/null 2>&1; then
        echo "  • Application Port 8080: ✓ Responding"
    else
        echo "  • Application Port 8080: ✗ Not responding"
    fi
    
    if curl -f -s http://localhost > /dev/null 2>&1; then
        echo "  • Web Access Port 80: ✓ Working"
    else
        echo "  • Web Access Port 80: ✗ Error (check configuration)"
    fi
    
    echo -e "${BLUE}📋 Useful Commands:${NC}"
    echo "  • Check app status: sudo systemctl status streamly"
    echo "  • View app logs: sudo journalctl -u streamly -f"
    echo "  • Restart app: sudo systemctl restart streamly"
    echo "  • Update app: sudo ./update.sh"
    echo "  • Check Nginx: sudo systemctl status nginx"
    echo "  • Test Nginx config: sudo nginx -t"
    echo "  • Test app direct: curl http://localhost:8080"
    echo "  • Test web access: curl http://localhost"
    
    echo -e "${BLUE}🔧 Troubleshooting:${NC}"
    echo "  • If 502 Error: sudo systemctl restart streamly && sudo systemctl reload nginx"
    echo "  • Check port 8080: sudo netstat -tlnp | grep :8080"
    echo "  • View detailed logs: sudo journalctl -u streamly --since '5 minutes ago'"
    
    echo -e "${GREEN}🎉 Streamly Control Hub is now ready to use!${NC}"
    echo -e "${GREEN}   Access it at: http://$SERVER_IP${NC}"
}

# Main installation process
main() {
    print_header
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --domain)
                DOMAIN="$2"
                shift 2
                ;;
            --email)
                SSL_EMAIL="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --domain DOMAIN    Domain name for SSL"
                echo "  --email EMAIL      Email for SSL certificate"
                echo "  --help             Show this help"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                ;;
        esac
    done
    
    # Pre-installation checks
    check_root
    check_os
    configure_noninteractive
    
    # Installation steps
    update_system
    install_dependencies
    install_nodejs
    setup_application
    configure_nginx
    create_systemd_service
    configure_firewall
    setup_ssl
    verify_services
    
    # Post-installation
    print_completion
}

# Trap errors
trap 'print_error "Installation failed at line $LINENO"' ERR

# Run main function
main "$@"
