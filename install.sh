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

update_system() {
    print_info "Updating system packages..."
    apt update && apt upgrade -y
    print_success "System updated successfully"
}

install_dependencies() {
    print_info "Installing system dependencies..."
    apt install -y \
        curl \
        git \
        nginx \
        certbot \
        python3-certbot-nginx \
        ufw \
        htop \
        unzip \
        software-properties-common \
        build-essential
    print_success "Dependencies installed"
}

install_nodejs() {
    print_info "Installing Node.js via NodeSource repository..."
    
    # Remove any existing Node.js installations
    apt remove -y nodejs npm || true
    
    # Install NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
    apt install -y nodejs
    
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
    git clone "$REPO_URL" .
    
    # Install npm dependencies
    print_info "Installing application dependencies..."
    npm install
    
    # Build application
    print_info "Building application..."
    npm run build
    
    print_success "Streamly Control Hub setup completed"
}

configure_nginx() {
    print_info "Configuring Nginx..."
    
    # Backup default configuration
    cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup
    
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
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss;
    
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
    
    systemctl restart nginx
    systemctl enable nginx
    
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
ExecStart=/usr/bin/npm run preview
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

[Install]
WantedBy=multi-user.target
EOF
    
    # Set correct permissions
    chown -R www-data:www-data "$APP_DIR"
    
    # Reload systemd and start service
    systemctl daemon-reload
    systemctl enable streamly
    systemctl start streamly
    
    print_success "Systemd service created and started"
}

configure_firewall() {
    print_info "Configuring UFW firewall..."
    
    # Reset UFW to defaults
    ufw --force reset
    
    # Default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH (be careful not to lock yourself out!)
    ufw allow ssh
    
    # Allow HTTP and HTTPS
    ufw allow 'Nginx Full'
    
    # Enable firewall
    ufw --force enable
    
    print_success "Firewall configured"
}

setup_ssl() {
    if [[ -n "$DOMAIN" ]] && [[ -n "$SSL_EMAIL" ]]; then
        print_info "Setting up SSL certificate for $DOMAIN..."
        
        # Update Nginx configuration with domain
        sed -i "s/server_name _;/server_name $DOMAIN;/" /etc/nginx/sites-available/streamly
        nginx -t && systemctl reload nginx
        
        # Get SSL certificate
        certbot --nginx -d "$DOMAIN" --email "$SSL_EMAIL" --agree-tos --non-interactive
        
        print_success "SSL certificate installed"
    else
        print_warning "Skipping SSL setup (no domain/email provided)"
        print_info "To setup SSL later, run: sudo certbot --nginx -d your-domain.com"
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
    echo "  • App Server: Node.js (Port 8080)"
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
    echo "  • Nginx $(nginx -v 2>&1 | grep -o 'nginx/[0-9.]*')"
    echo "  • UFW Firewall (active)"
    echo "  • Certbot (for SSL certificates)"
    echo "  • Git (for updates)"
    
    echo -e "${BLUE}📋 Useful Commands:${NC}"
    echo "  • Check app status: sudo systemctl status streamly"
    echo "  • View app logs: sudo journalctl -u streamly -f"
    echo "  • Restart app: sudo systemctl restart streamly"
    echo "  • Update app: sudo ./update.sh"
    echo "  • Check Nginx: sudo systemctl status nginx"
    echo "  • Test Nginx config: sudo nginx -t"
    
    echo -e "${BLUE}🔧 Next Steps:${NC}"
    echo "  1. Open your browser and go to: http://$SERVER_IP"
    echo "  2. Configure your domain (optional): Edit /etc/nginx/sites-available/streamly"
    echo "  3. Set up SSL certificate: sudo certbot --nginx -d your-domain.com"
    echo "  4. Configure streaming settings in the admin panel"
    echo "  5. Set up user accounts and permissions"
    
    echo -e "${BLUE}🔒 Security Recommendations:${NC}"
    echo "  • Configure authentication for admin access"
    echo "  • Set up SSL certificate for HTTPS"
    echo "  • Review and customize firewall rules"
    echo "  • Enable automatic security updates"
    echo "  • Regular backup of configuration and data"
    
    echo -e "${YELLOW}⚠  Important Notes:${NC}"
    echo "  • The application runs on port 8080 internally"
    echo "  • Nginx proxies external traffic from port 80"
    echo "  • Logs are available via systemctl/journalctl"
    echo "  • Configuration files are in $APP_DIR"
    echo "  • Update script is available in current directory"
    
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
    
    # Installation steps
    update_system
    install_dependencies
    install_nodejs
    setup_application
    configure_nginx
    create_systemd_service
    configure_firewall
    setup_ssl
    
    # Post-installation
    print_completion
}

# Trap errors
trap 'print_error "Installation failed at line $LINENO"' ERR

# Run main function
main "$@"
