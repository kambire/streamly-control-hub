
#!/bin/bash

# Streamly Control Hub - Installation Script
# Shoutcast Streaming Control Panel

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Streamly Control Hub"
APP_DIR="/var/www/streamly"
SERVICE_NAME="streamly"
NGINX_SITE="streamly"
DEFAULT_PORT="8080"
SHOUTCAST_PORT="8000"

# Logging function
log() {
    echo -e "${BLUE}ℹ${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Update system packages
update_system() {
    log "Updating system packages..."
    sudo apt update -qq
    sudo apt upgrade -y -qq
    success "System updated successfully"
}

# Install required packages
install_dependencies() {
    log "Installing required packages..."
    
    # Install Node.js and npm
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    
    # Install other dependencies
    sudo apt-get install -y \
        nginx \
        ufw \
        curl \
        wget \
        unzip \
        git \
        htop \
        nano \
        build-essential
    
    success "Dependencies installed successfully"
}

# Install and configure Shoutcast
install_shoutcast() {
    log "Installing Shoutcast server..."
    
    # Create shoutcast directory
    sudo mkdir -p /opt/shoutcast
    cd /tmp
    
    # Download Shoutcast DNAS (Linux x64)
    if [ ! -f "sc_serv2_linux_x64-latest.tar.gz" ]; then
        wget -q http://download.nullsoft.com/shoutcast/tools/sc_serv2_linux_x64-latest.tar.gz
    fi
    
    # Extract and install
    tar -xzf sc_serv2_linux_x64-latest.tar.gz
    sudo cp sc_serv2_linux_x64-*/sc_serv /opt/shoutcast/
    sudo chmod +x /opt/shoutcast/sc_serv
    
    # Create Shoutcast configuration
    sudo tee /opt/shoutcast/sc_serv.conf > /dev/null << EOF
; Shoutcast Server Configuration
portbase=$SHOUTCAST_PORT
adminpassword=admin123
password=streamly123
maxuser=100
logfile=/var/log/shoutcast/sc_serv.log
w3clog=/var/log/shoutcast/sc_w3c.log
banfile=/opt/shoutcast/sc_serv.ban
ripfile=/opt/shoutcast/sc_serv.rip
publicserver=never
streamtitle=Streamly Radio
streamurl=http://localhost:$SHOUTCAST_PORT
genre=Various
aacplus=1
EOF
    
    # Create log directory
    sudo mkdir -p /var/log/shoutcast
    sudo chown $USER:$USER /var/log/shoutcast
    
    # Create Shoutcast service
    sudo tee /etc/systemd/system/shoutcast.service > /dev/null << EOF
[Unit]
Description=Shoutcast DNAS Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/opt/shoutcast
ExecStart=/opt/shoutcast/sc_serv /opt/shoutcast/sc_serv.conf
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable shoutcast
    
    success "Shoutcast server installed and configured"
}

# Create application directory and install frontend
install_app() {
    log "Installing Streamly Control Hub..."
    
    # Create app directory
    sudo mkdir -p "$APP_DIR"
    sudo chown $USER:$USER "$APP_DIR"
    
    # Initialize npm project
    cd "$APP_DIR"
    npm init -y --silent
    npm install express --save --silent
    npm install -g serve --silent
    
    # Create a robust production server using CommonJS to avoid module issues
    cat > "$APP_DIR/server.js" << 'EOF'
const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 8080;
const HOST = process.env.HOST || '0.0.0.0';

// Security middleware
app.disable('x-powered-by');

// Serve static files from dist directory
const distPath = path.join(__dirname, 'dist');
app.use(express.static(distPath, {
  maxAge: '1d',
  setHeaders: (res, filePath) => {
    if (path.extname(filePath) === '.html') {
      res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
      res.setHeader('Pragma', 'no-cache');
      res.setHeader('Expires', '0');
    }
  }
}));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// API endpoint for Shoutcast integration
app.get('/api/shoutcast/status', (req, res) => {
  res.json({ 
    message: 'Shoutcast integration ready',
    port: 8000,
    status: 'configured'
  });
});

// API endpoint for testing
app.get('/api/status', (req, res) => {
  res.json({ 
    message: 'Streamly Control Hub API is running',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'production',
    streaming: 'Shoutcast'
  });
});

// Serve index.html for all other routes (SPA support)
app.get('*', (req, res) => {
  const indexPath = path.join(distPath, 'index.html');
  res.sendFile(indexPath, (err) => {
    if (err) {
      console.error('Error serving index.html:', err);
      res.status(404).send('Application not found');
    }
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({ 
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
  });
});

// Start server
const server = app.listen(PORT, HOST, () => {
  console.log(`🚀 Streamly Control Hub running on http://${HOST}:${PORT}`);
  console.log(`📊 Health check: http://${HOST}:${PORT}/health`);
  console.log(`🔧 API status: http://${HOST}:${PORT}/api/status`);
  console.log(`🎵 Shoutcast status: http://${HOST}:${PORT}/api/shoutcast/status`);
  console.log(`📁 Serving files from: ${distPath}`);
});

// Graceful shutdown handlers
const gracefulShutdown = (signal) => {
  console.log(`\n${signal} received. Shutting down gracefully...`);
  server.close(() => {
    console.log('Server closed successfully');
    process.exit(0);
  });
  
  // Force close after 10 seconds
  setTimeout(() => {
    console.error('Could not close connections in time, forcefully shutting down');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});
EOF
    
    # Create dist directory with a basic index.html if it doesn't exist
    mkdir -p "$APP_DIR/dist"
    if [ ! -f "$APP_DIR/dist/index.html" ]; then
        cat > "$APP_DIR/dist/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Streamly Control Hub</title>
    <style>
        body { 
            margin: 0; 
            font-family: Arial, sans-serif; 
            background: #1a1a1a; 
            color: white; 
            display: flex; 
            justify-content: center; 
            align-items: center; 
            height: 100vh; 
        }
        .container { text-align: center; }
        h1 { color: #9b87f5; }
        .status { margin: 20px 0; }
        .status.online { color: #22c55e; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎵 Streamly Control Hub</h1>
        <div class="status online">✓ Sistema Funcionando</div>
        <p>Panel de Control de Streaming con Shoutcast</p>
        <small>Versión 1.0.0</small>
    </div>
</body>
</html>
EOF
    fi
    
    success "Application installed successfully"
}

# Create systemd service
create_service() {
    log "Creating systemd service..."
    
    sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << EOF
[Unit]
Description=$APP_NAME
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$APP_DIR
Environment=NODE_ENV=production
Environment=PORT=$DEFAULT_PORT
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=$SERVICE_NAME

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    sudo systemctl enable $SERVICE_NAME
    
    success "Service created successfully"
}

# Configure Nginx
configure_nginx() {
    log "Configuring Nginx..."
    
    sudo tee /etc/nginx/sites-available/$NGINX_SITE > /dev/null << EOF
server {
    listen 80;
    server_name _;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    
    # Main application
    location / {
        proxy_pass http://localhost:$DEFAULT_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
    }
    
    # Shoutcast streaming endpoint
    location /stream {
        proxy_pass http://localhost:$SHOUTCAST_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    
    # Shoutcast admin
    location /admin {
        proxy_pass http://localhost:$SHOUTCAST_PORT/admin;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
    
    # Enable site
    sudo ln -sf /etc/nginx/sites-available/$NGINX_SITE /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Test and reload Nginx
    sudo nginx -t
    sudo systemctl restart nginx
    
    success "Nginx configured successfully"
}

# Configure firewall
configure_firewall() {
    log "Configuring firewall..."
    
    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Allow SSH
    sudo ufw allow ssh
    
    # Allow HTTP and HTTPS
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    
    # Allow Shoutcast
    sudo ufw allow $SHOUTCAST_PORT/tcp
    
    # Allow application port (internal)
    sudo ufw allow from 127.0.0.1 to any port $DEFAULT_PORT
    
    sudo ufw --force enable
    
    success "Firewall configured successfully"
}

# Start services
start_services() {
    log "Starting services..."
    
    # Start Shoutcast
    sudo systemctl start shoutcast
    sleep 2
    
    # Start main application
    sudo systemctl start $SERVICE_NAME
    sleep 3
    
    success "Services started successfully"
}

# Test installation
test_installation() {
    log "Testing server configuration..."
    
    # Test main application
    if curl -f -s http://localhost:$DEFAULT_PORT/health > /dev/null; then
        success "Main application is responding"
    else
        warning "Service attempt 1/3 failed, checking logs..."
        sudo journalctl -u $SERVICE_NAME --no-pager -n 10
        log "Attempting to restart service..."
        sudo systemctl restart $SERVICE_NAME
        sleep 5
        
        if curl -f -s http://localhost:$DEFAULT_PORT/health > /dev/null; then
            success "Service recovered successfully"
        else
            error "Service failed to start properly"
            return 1
        fi
    fi
    
    # Test Shoutcast
    if netstat -ln | grep -q ":$SHOUTCAST_PORT "; then
        success "Shoutcast server is running on port $SHOUTCAST_PORT"
    else
        warning "Shoutcast may need manual configuration"
    fi
    
    success "Installation test completed"
}

# Show final information
show_info() {
    echo
    success "🎉 $APP_NAME installation completed!"
    echo
    echo -e "${BLUE}Access Information:${NC}"
    echo -e "  • Web Panel: ${GREEN}http://$(hostname -I | awk '{print $1}')${NC}"
    echo -e "  • Shoutcast Stream: ${GREEN}http://$(hostname -I | awk '{print $1}'):$SHOUTCAST_PORT${NC}"
    echo -e "  • Shoutcast Admin: ${GREEN}http://$(hostname -I | awk '{print $1}'):$SHOUTCAST_PORT/admin${NC}"
    echo
    echo -e "${BLUE}Service Management:${NC}"
    echo -e "  • Status: ${YELLOW}sudo systemctl status $SERVICE_NAME${NC}"
    echo -e "  • Logs: ${YELLOW}sudo journalctl -u $SERVICE_NAME -f${NC}"
    echo -e "  • Restart: ${YELLOW}sudo systemctl restart $SERVICE_NAME${NC}"
    echo
    echo -e "${BLUE}Shoutcast Information:${NC}"
    echo -e "  • Admin Password: ${YELLOW}admin123${NC}"
    echo -e "  • Stream Password: ${YELLOW}streamly123${NC}"
    echo -e "  • Configuration: ${YELLOW}/opt/shoutcast/sc_serv.conf${NC}"
    echo
    echo -e "${GREEN}Ready to stream with Shoutcast! 🎵${NC}"
}

# Main installation function
main() {
    echo -e "${GREEN}🎵 $APP_NAME - Shoutcast Installation${NC}"
    echo "========================================"
    
    check_root
    update_system
    install_dependencies
    install_shoutcast
    install_app
    create_service
    configure_nginx
    configure_firewall
    start_services
    test_installation
    show_info
    
    success "Installation completed successfully!"
}

# Error handling
trap 'error "Installation failed at line $LINENO"' ERR

# Run main function
main "$@"
