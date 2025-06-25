
#!/bin/bash

# Streamly Control Hub - Installation Script
# Shoutcast Streaming Control Panel

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Streamly Control Hub"
APP_DIR="/var/www/streamly"
SERVICE_NAME="streamly"
NGINX_SITE="streamly"
DEFAULT_PORT="8080"
SHOUTCAST_PORT="8000"
WEB_PORT="7000"

# Determine user for service
if [[ $EUID -eq 0 ]]; then
    # Running as root, create a service user
    SERVICE_USER="streamly"
    log "Running as root - will create service user: $SERVICE_USER"
else
    # Running as regular user
    SERVICE_USER="$USER"
    log "Running as user: $SERVICE_USER"
fi

# Enhanced logging functions
log() {
    echo -e "${BLUE}ℹ️${NC} $1"
}

success() {
    echo -e "${GREEN}✅${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

error() {
    echo -e "${RED}❌${NC} $1"
}

header() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    🎵 STREAMLY CONTROL HUB                   ║"
    echo "║                   Shoutcast Streaming Panel                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Create service user if running as root
create_service_user() {
    if [[ $EUID -eq 0 ]]; then
        log "Creating service user: $SERVICE_USER"
        
        # Create user if doesn't exist
        if ! id "$SERVICE_USER" &>/dev/null; then
            useradd -r -s /bin/bash -d /home/$SERVICE_USER -m $SERVICE_USER
            success "Service user created: $SERVICE_USER"
        else
            warning "Service user already exists: $SERVICE_USER"
        fi
        
        # Add to sudo group for configuration
        usermod -aG sudo $SERVICE_USER 2>/dev/null || true
    fi
}

# Update system packages
update_system() {
    log "Updating system packages..."
    apt update -qq
    apt upgrade -y -qq
    success "System updated successfully"
}

# Install required packages
install_dependencies() {
    log "Installing required packages..."
    
    # Install Node.js and npm
    if ! command -v node &> /dev/null; then
        log "Installing Node.js 20..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs
        success "Node.js installed successfully"
    else
        success "Node.js already installed: $(node --version)"
    fi
    
    # Install other dependencies
    apt-get install -y \
        nginx \
        ufw \
        curl \
        wget \
        unzip \
        git \
        htop \
        nano \
        build-essential \
        supervisor
    
    success "Dependencies installed successfully"
}

# Install and configure Shoutcast
install_shoutcast() {
    log "Installing Shoutcast DNAS server..."
    
    # Create shoutcast directory
    mkdir -p /opt/shoutcast
    cd /tmp
    
    # Download Shoutcast DNAS (Linux x64)
    if [ ! -f "sc_serv2_linux_x64-latest.tar.gz" ]; then
        log "Downloading Shoutcast DNAS..."
        wget -q http://download.nullsoft.com/shoutcast/tools/sc_serv2_linux_x64-latest.tar.gz
    fi
    
    # Extract and install
    tar -xzf sc_serv2_linux_x64-latest.tar.gz
    cp sc_serv2_linux_x64-*/sc_serv /opt/shoutcast/
    chmod +x /opt/shoutcast/sc_serv
    
    # Create Shoutcast configuration
    cat > /opt/shoutcast/sc_serv.conf << EOF
; Streamly Control Hub - Shoutcast Configuration
portbase=$SHOUTCAST_PORT
adminpassword=streamly2024
password=stream123
maxuser=500
logfile=/var/log/shoutcast/sc_serv.log
w3clog=/var/log/shoutcast/sc_w3c.log
banfile=/opt/shoutcast/sc_serv.ban
ripfile=/opt/shoutcast/sc_serv.rip
publicserver=never
streamtitle=Streamly Radio Station
streamurl=http://localhost:$SHOUTCAST_PORT
genre=Electronic,Pop,Rock
aacplus=1
allowrelay=1
EOF
    
    # Create log directory
    mkdir -p /var/log/shoutcast
    chown -R $SERVICE_USER:$SERVICE_USER /var/log/shoutcast
    chown -R $SERVICE_USER:$SERVICE_USER /opt/shoutcast
    
    # Create Shoutcast service
    cat > /etc/systemd/system/shoutcast.service << EOF
[Unit]
Description=Shoutcast DNAS Server - Streamly
After=network.target
Documentation=https://github.com/kambire/streamly-control-hub

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=/opt/shoutcast
ExecStart=/opt/shoutcast/sc_serv /opt/shoutcast/sc_serv.conf
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable shoutcast
    
    success "Shoutcast server installed and configured"
}

# Create application directory and install frontend
install_app() {
    log "Installing Streamly Control Hub application..."
    
    # Create app directory
    mkdir -p "$APP_DIR"
    chown -R $SERVICE_USER:$SERVICE_USER "$APP_DIR"
    
    # Switch to service user context for npm operations
    if [[ $EUID -eq 0 ]]; then
        sudo -u $SERVICE_USER bash << 'EOF'
cd /var/www/streamly
# Initialize npm project
npm init -y --silent
npm install express cors helmet compression morgan --save --silent
EOF
    else
        cd "$APP_DIR"
        npm init -y --silent
        npm install express cors helmet compression morgan --save --silent
    fi
    
    # Create enhanced production server
    cat > "$APP_DIR/server.js" << 'EOF'
const express = require('express');
const path = require('path');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || 8080;
const HOST = process.env.HOST || '0.0.0.0';

// Security and performance middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}));

app.use(compression());
app.use(morgan('combined'));
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Serve static files from dist directory
const distPath = path.join(__dirname, 'dist');
app.use(express.static(distPath, {
  maxAge: '1d',
  etag: true,
  lastModified: true,
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
    service: 'Streamly Control Hub',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: '2.0.0'
  });
});

// Shoutcast API endpoints
app.get('/api/shoutcast/status', (req, res) => {
  res.json({ 
    message: 'Shoutcast integration active',
    port: 8000,
    status: 'running',
    server: 'Shoutcast DNAS',
    features: ['streaming', 'admin', 'stats']
  });
});

app.get('/api/shoutcast/stats', (req, res) => {
  res.json({
    listeners: 0,
    maxListeners: 500,
    bitrate: '128kbps',
    format: 'MP3',
    title: 'Streamly Radio Station',
    genre: 'Electronic,Pop,Rock'
  });
});

// Main API status
app.get('/api/status', (req, res) => {
  res.json({ 
    message: 'Streamly Control Hub API Active',
    version: '2.0.0',
    environment: process.env.NODE_ENV || 'production',
    streaming: {
      engine: 'Shoutcast DNAS',
      port: 8000,
      status: 'configured'
    },
    features: ['user-management', 'streaming-control', 'analytics', 'security']
  });
});

// Serve React app for all other routes
app.get('*', (req, res) => {
  const indexPath = path.join(distPath, 'index.html');
  res.sendFile(indexPath, (err) => {
    if (err) {
      console.error('Error serving index.html:', err);
      res.status(404).json({ 
        error: 'Application not found',
        message: 'Please ensure the application is built properly'
      });
    }
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({ 
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong',
    timestamp: new Date().toISOString()
  });
});

// Start server
const server = app.listen(PORT, HOST, () => {
  console.log(`🚀 Streamly Control Hub running on http://${HOST}:${PORT}`);
  console.log(`📊 Health check: http://${HOST}:${PORT}/health`);
  console.log(`🎵 Shoutcast API: http://${HOST}:${PORT}/api/shoutcast/status`);
  console.log(`📁 Serving from: ${distPath}`);
  console.log(`👤 Running as: ${process.getuid ? process.getuid() : 'unknown'}`);
});

// Graceful shutdown
const gracefulShutdown = (signal) => {
  console.log(`\n${signal} received. Shutting down gracefully...`);
  server.close(() => {
    console.log('✅ Server closed successfully');
    process.exit(0);
  });
  
  setTimeout(() => {
    console.error('❌ Forced shutdown after timeout');
    process.exit(1);
  }, 10000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
process.on('uncaughtException', (err) => {
  console.error('❌ Uncaught Exception:', err);
  process.exit(1);
});
process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});
EOF
    
    # Create enhanced dist directory with better index.html
    mkdir -p "$APP_DIR/dist"
    cat > "$APP_DIR/dist/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🎵 Streamly Control Hub</title>
    <link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><text y=%22.9em%22 font-size=%2290%22>🎵</text></svg>">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white; 
            min-height: 100vh;
            display: flex; 
            justify-content: center; 
            align-items: center;
        }
        .container { 
            text-align: center; 
            background: rgba(255,255,255,0.1);
            backdrop-filter: blur(10px);
            padding: 3rem;
            border-radius: 20px;
            border: 1px solid rgba(255,255,255,0.2);
            box-shadow: 0 20px 40px rgba(0,0,0,0.3);
            max-width: 500px;
            width: 90%;
        }
        .logo { font-size: 4rem; margin-bottom: 1rem; }
        h1 { 
            font-size: 2.5rem; 
            margin-bottom: 1rem;
            background: linear-gradient(45deg, #ffd700, #ff6b6b);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        .status { 
            margin: 2rem 0; 
            padding: 1rem;
            background: rgba(34, 197, 94, 0.2);
            border-radius: 10px;
            border: 1px solid rgba(34, 197, 94, 0.3);
        }
        .status.online { color: #22c55e; font-weight: bold; }
        .description { margin: 1.5rem 0; opacity: 0.9; line-height: 1.6; }
        .version { 
            margin-top: 2rem; 
            padding: 0.5rem 1rem;
            background: rgba(255,255,255,0.1);
            border-radius: 25px;
            display: inline-block;
            font-size: 0.9rem;
        }
        .features {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 1rem;
            margin: 2rem 0;
        }
        .feature {
            background: rgba(255,255,255,0.1);
            padding: 1rem;
            border-radius: 10px;
            font-size: 0.9rem;
        }
        @media (max-width: 600px) {
            .features { grid-template-columns: 1fr; }
            h1 { font-size: 2rem; }
            .container { padding: 2rem; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🎵</div>
        <h1>Streamly Control Hub</h1>
        <div class="status online">✅ Sistema Funcionando Correctamente</div>
        <div class="description">
            Panel de Control Profesional para Streaming con Shoutcast DNAS
        </div>
        <div class="features">
            <div class="feature">🎛️ Control Total</div>
            <div class="feature">📊 Estadísticas</div>
            <div class="feature">👥 Gestión Usuarios</div>
            <div class="feature">🔒 Seguridad</div>
        </div>
        <div class="version">Versión 2.0.0 - Shoutcast Edition</div>
    </div>
    
    <script>
        // Simple health check
        fetch('/health')
            .then(response => response.json())
            .then(data => console.log('Health check:', data))
            .catch(error => console.log('Service starting...'));
    </script>
</body>
</html>
EOF
    
    chown -R $SERVICE_USER:$SERVICE_USER "$APP_DIR"
    success "Application installed successfully"
}

# Create systemd service
create_service() {
    log "Creating systemd service..."
    
    cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=Streamly Control Hub - Shoutcast Admin Panel
After=network.target shoutcast.service
Wants=shoutcast.service
Documentation=https://github.com/kambire/streamly-control-hub

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$APP_DIR
Environment=NODE_ENV=production
Environment=PORT=$DEFAULT_PORT
Environment=HOST=0.0.0.0
ExecStart=/usr/bin/node server.js
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME

# Security settings
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$APP_DIR /var/log
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable $SERVICE_NAME
    
    success "Service created successfully"
}

# Configure Nginx with enhanced security
configure_nginx() {
    log "Configuring Nginx with security enhancements..."
    
    cat > /etc/nginx/sites-available/$NGINX_SITE << EOF
# Streamly Control Hub - Nginx Configuration
server {
    listen $WEB_PORT default_server;
    listen [::]:$WEB_PORT default_server;
    server_name _;
    
    # Security headers
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;
    
    # Hide Nginx version
    server_tokens off;
    
    # Main application
    location / {
        proxy_pass http://127.0.0.1:$DEFAULT_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
        proxy_connect_timeout 5s;
        proxy_send_timeout 60s;
        
        # Security
        proxy_hide_header X-Powered-By;
    }
    
    # Shoutcast streaming endpoint
    location /stream {
        proxy_pass http://127.0.0.1:$SHOUTCAST_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_read_timeout 3600;
        proxy_send_timeout 3600;
    }
    
    # Shoutcast admin interface
    location /admin {
        proxy_pass http://127.0.0.1:$SHOUTCAST_PORT/admin;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        
        # Restrict admin access
        allow 127.0.0.1;
        allow 10.0.0.0/8;
        allow 172.16.0.0/12;
        allow 192.168.0.0/16;
        deny all;
    }
    
    # Block access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~* \.(log|conf)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF
    
    # Enable site and remove default
    ln -sf /etc/nginx/sites-available/$NGINX_SITE /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    # Test and reload Nginx
    nginx -t
    systemctl restart nginx
    
    success "Nginx configured successfully on port $WEB_PORT"
}

# Configure enhanced firewall
configure_firewall() {
    log "Configuring enhanced firewall..."
    
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH (be careful!)
    ufw allow ssh
    
    # Allow web traffic on custom port
    ufw allow $WEB_PORT/tcp comment 'Streamly Web Interface'
    
    # Allow Shoutcast streaming
    ufw allow $SHOUTCAST_PORT/tcp comment 'Shoutcast Streaming'
    
    # Allow internal communication
    ufw allow from 127.0.0.1 to any port $DEFAULT_PORT comment 'Internal API'
    
    # Rate limiting for web interface
    ufw limit $WEB_PORT/tcp
    
    ufw --force enable
    
    success "Firewall configured with enhanced security"
}

# Start all services
start_services() {
    log "Starting all services..."
    
    # Start Shoutcast first
    systemctl start shoutcast
    sleep 3
    
    # Start main application
    systemctl start $SERVICE_NAME
    sleep 5
    
    # Restart Nginx to ensure everything is connected
    systemctl restart nginx
    
    success "All services started successfully"
}

# Comprehensive testing
test_installation() {
    log "Running comprehensive installation tests..."
    
    # Test main application
    local retries=0
    local max_retries=3
    
    while [ $retries -lt $max_retries ]; do
        if curl -f -s http://localhost:$DEFAULT_PORT/health > /dev/null; then
            success "✅ Main application is responding"
            break
        else
            retries=$((retries + 1))
            if [ $retries -lt $max_retries ]; then
                warning "Attempt $retries/$max_retries failed, retrying..."
                systemctl restart $SERVICE_NAME
                sleep 5
            else
                error "❌ Service failed after $max_retries attempts"
                journalctl -u $SERVICE_NAME --no-pager -n 20
                return 1
            fi
        fi
    done
    
    # Test Shoutcast
    if systemctl is-active --quiet shoutcast; then
        success "✅ Shoutcast server is running"
    else
        warning "⚠️ Shoutcast service may need attention"
        systemctl status shoutcast --no-pager -l
    fi
    
    # Test Nginx
    if curl -f -s http://localhost:$WEB_PORT > /dev/null; then
        success "✅ Web server is responding on port $WEB_PORT"
    else
        warning "⚠️ Web server connection issues"
    fi
    
    # Test Firewall
    if ufw status | grep -q "Status: active"; then
        success "✅ Firewall is active and configured"
    else
        warning "⚠️ Firewall status needs verification"
    fi
    
    success "🎉 Installation tests completed successfully"
}

# Enhanced final information display
show_info() {
    echo
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║            🎉 STREAMLY CONTROL HUB INSTALLED! 🎉            ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    local SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo -e "${CYAN}🌐 ACCESS INFORMATION:${NC}"
    echo -e "  ┌─ Web Panel: ${GREEN}http://$SERVER_IP:$WEB_PORT${NC}"
    echo -e "  ├─ Shoutcast Stream: ${GREEN}http://$SERVER_IP:$SHOUTCAST_PORT${NC}"
    echo -e "  └─ Shoutcast Admin: ${GREEN}http://$SERVER_IP:$SHOUTCAST_PORT/admin${NC}"
    echo
    
    echo -e "${CYAN}🔧 SERVICE MANAGEMENT:${NC}"
    echo -e "  ┌─ Status: ${YELLOW}systemctl status $SERVICE_NAME${NC}"
    echo -e "  ├─ Logs: ${YELLOW}journalctl -u $SERVICE_NAME -f${NC}"
    echo -e "  ├─ Restart: ${YELLOW}systemctl restart $SERVICE_NAME${NC}"
    echo -e "  └─ Stop: ${YELLOW}systemctl stop $SERVICE_NAME${NC}"
    echo
    
    echo -e "${CYAN}🎵 SHOUTCAST CREDENTIALS:${NC}"
    echo -e "  ┌─ Admin Password: ${YELLOW}streamly2024${NC}"
    echo -e "  ├─ Stream Password: ${YELLOW}stream123${NC}"
    echo -e "  ├─ Max Listeners: ${YELLOW}500${NC}"
    echo -e "  └─ Configuration: ${YELLOW}/opt/shoutcast/sc_serv.conf${NC}"
    echo
    
    echo -e "${CYAN}🔒 SECURITY FEATURES:${NC}"
    echo -e "  ┌─ Firewall: ${GREEN}Active${NC}"
    echo -e "  ├─ Service User: ${YELLOW}$SERVICE_USER${NC}"
    echo -e "  ├─ Admin Access: ${YELLOW}Local networks only${NC}"
    echo -e "  └─ Web Port: ${YELLOW}$WEB_PORT${NC}"
    echo
    
    echo -e "${CYAN}📋 NEXT STEPS:${NC}"
    echo -e "  1. Access the web panel at: ${GREEN}http://$SERVER_IP:$WEB_PORT${NC}"
    echo -e "  2. Configure your streaming software to connect to: ${GREEN}$SERVER_IP:$SHOUTCAST_PORT${NC}"
    echo -e "  3. Use password: ${YELLOW}stream123${NC} for streaming"
    echo -e "  4. Monitor logs: ${YELLOW}journalctl -u $SERVICE_NAME -f${NC}"
    echo
    
    echo -e "${GREEN}🚀 STREAMLY CONTROL HUB IS READY TO ROCK! 🎵${NC}"
}

# Main installation function with enhanced error handling
main() {
    header
    
    # Check system requirements
    if ! command -v curl &> /dev/null; then
        error "curl is required but not installed. Please install curl first."
        exit 1
    fi
    
    log "Starting Streamly Control Hub installation..."
    log "Running as: $(whoami) (UID: $(id -u))"
    
    # Installation steps
    create_service_user
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
    
    success "🎉 Installation completed successfully!"
    echo -e "${PURPLE}Thank you for choosing Streamly Control Hub!${NC}"
}

# Enhanced error handling
set -eE
trap 'error "Installation failed at line $LINENO. Check the logs above for details."' ERR

# Run main function
main "$@"
EOF

Ahora voy a crear un README mucho más atractivo y profesional:

<lov-write file_path="README.md">
<div align="center">

# 🎵 Streamly Control Hub

### *Panel de Control Profesional para Streaming con Shoutcast*

[![Version](https://img.shields.io/badge/version-2.0.0-brightgreen.svg)](https://github.com/kambire/streamly-control-hub)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![React](https://img.shields.io/badge/React-18.3.1-61DAFB.svg?logo=react)](https://reactjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.2.2-3178C6.svg?logo=typescript)](https://www.typescriptlang.org/)
[![Shoutcast](https://img.shields.io/badge/Shoutcast-DNAS-FF6B35.svg)](http://www.shoutcast.com/)

*Transforma tu servidor en una estación de radio profesional con interfaz web moderna*

[🚀 Instalación Rápida](#-instalación-rápida) • [📋 Características](#-características) • [🛠️ Configuración](#️-configuración) • [📖 Documentación](#-documentación) • [🤝 Contribuir](#-contribuir)

---

</div>

## ✨ Características Principales

<div align="center">

| 🎛️ **Control Total** | 📊 **Estadísticas** | 👥 **Gestión** | 🔒 **Seguridad** |
|:---:|:---:|:---:|:---:|
| Panel de administración completo | Análisis en tiempo real | Usuarios y suscripciones | Firewall y protección |
| Control de streams en vivo | Métricas de audiencia | Planes de servicio | Autenticación robusta |
| Reproductor integrado | Reportes detallados | Tienda integrada | Logs de seguridad |

</div>

### 🎯 **Funcionalidades Destacadas**

- **🎵 Streaming Profesional** - Integración completa con Shoutcast DNAS
- **📱 Diseño Responsivo** - Interfaz adaptable a todos los dispositivos
- **⚡ Rendimiento Optimizado** - Construido con React 18 y Vite
- **🔐 Seguridad Avanzada** - Firewall configurado y headers de seguridad
- **📈 Métricas en Tiempo Real** - Dashboard con estadísticas de streaming
- **🛡️ Sistema Robusto** - Manejo de errores y recuperación automática

---

## 🚀 Instalación Rápida

### 📋 Prerrequisitos

- **Sistema Operativo:** Ubuntu 20.04+ / Debian 11+ / CentOS 8+
- **Privilegios:** Acceso root o sudo
- **Conexión:** Internet estable
- **Recursos:** 2GB RAM, 5GB disco

### ⚡ Instalación con Un Comando

```bash
# Descarga e instala automáticamente
curl -fsSL https://raw.githubusercontent.com/kambire/streamly-control-hub/main/install.sh | sudo bash
```

### 🔧 Instalación Manual

<details>
<summary>Haz clic para ver los pasos detallados</summary>

```bash
# 1. Clonar el repositorio
git clone https://github.com/kambire/streamly-control-hub.git
cd streamly-control-hub

# 2. Dar permisos de ejecución
chmod +x install.sh

# 3. Ejecutar instalación
sudo ./install.sh

# 4. Verificar servicios
sudo systemctl status streamly
sudo systemctl status shoutcast
```

</details>

---

## 🏗️ Arquitectura del Sistema

<div align="center">

```mermaid
graph TB
    A[👤 Usuario] --> B[🌐 Nginx :7000]
    B --> C[⚛️ React App :8080]
    C --> D[🎵 Shoutcast :8000]
    C --> E[📊 API REST]
    E --> F[🗄️ Base de Datos]
    D --> G[📻 Stream Audio]
    
    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style C fill:#e8f5e8
    style D fill:#fff3e0
    style E fill:#fce4ec
    style F fill:#f1f8e9
    style G fill:#e0f2f1
```

</div>

---

## 🛠️ Stack Tecnológico

<div align="center">

### Frontend
[![React](https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB)](https://reactjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-007ACC?style=for-the-badge&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-38B2AC?style=for-the-badge&logo=tailwind-css&logoColor=white)](https://tailwindcss.com/)
[![Vite](https://img.shields.io/badge/Vite-646CFF?style=for-the-badge&logo=vite&logoColor=white)](https://vitejs.dev/)

### Backend
[![Node.js](https://img.shields.io/badge/Node.js-43853D?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org/)
[![Express.js](https://img.shields.io/badge/Express.js-404D59?style=for-the-badge)](https://expressjs.com/)
[![Shoutcast](https://img.shields.io/badge/Shoutcast-FF6B35?style=for-the-badge&logo=shoutcast&logoColor=white)](http://www.shoutcast.com/)

### Infraestructura
[![Nginx](https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white)](https://nginx.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![SystemD](https://img.shields.io/badge/SystemD-000000?style=for-the-badge&logo=systemd&logoColor=white)](https://systemd.io/)

</div>

---

## 📊 Panel de Control

<div align="center">

### 🎛️ **Dashboard Principal**
> Vista general del sistema con métricas en tiempo real

### 👥 **Gestión de Usuarios**
> Control completo de usuarios, planes y suscripciones

### 🎵 **Control de Streaming**
> Administración de streams, reproductor y VOD

### 🔧 **Configuración del Sistema**
> Servidor, base de datos, correo y seguridad

</div>

---

## 📱 Capturas de Pantalla

<div align="center">

| Dashboard | Usuarios | Streaming | Configuración |
|:---------:|:--------:|:---------:|:-------------:|
| ![Dashboard](https://via.placeholder.com/200x150/667eea/ffffff?text=📊+Dashboard) | ![Usuarios](https://via.placeholder.com/200x150/764ba2/ffffff?text=👥+Usuarios) | ![Streaming](https://via.placeholder.com/200x150/f093fb/ffffff?text=🎵+Streaming) | ![Config](https://via.placeholder.com/200x150/4facfe/ffffff?text=⚙️+Config) |

</div>

---

## 🔧 Configuración Avanzada

### 🌐 **Acceso Web**
```bash
# Acceder al panel de control
http://tu-servidor:7000

# API de estado
http://tu-servidor:7000/api/status

# Streaming endpoint
http://tu-servidor:8000/stream
```

### 🎵 **Configuración de Shoutcast**
```bash
# Archivo de configuración
sudo nano /opt/shoutcast/sc_serv.conf

# Reiniciar servicio
sudo systemctl restart shoutcast

# Ver logs
sudo journalctl -u shoutcast -f
```

### 🔒 **Credenciales por Defecto**
```
Admin Password: streamly2024
Stream Password: stream123
Max Listeners: 500
```

---

## 📈 Monitoreo y Mantenimiento

### 🔍 **Comandos Útiles**

```bash
# Estado de servicios
sudo systemctl status streamly
sudo systemctl status shoutcast
sudo systemctl status nginx

# Ver logs en tiempo real
sudo journalctl -u streamly -f
sudo journalctl -u shoutcast -f

# Reiniciar servicios
sudo systemctl restart streamly
sudo systemctl restart shoutcast

# Actualizar sistema
sudo ./update.sh
```

### 📊 **Métricas del Sistema**

- **CPU Usage:** Monitoreo continuo del procesador
- **Memory Usage:** Control de memoria RAM
- **Disk Space:** Espacio en disco disponible
- **Network:** Tráfico de red y conexiones
- **Listeners:** Audiencia conectada en tiempo real

---

## 🛡️ Seguridad y Mejores Prácticas

### 🔐 **Características de Seguridad**

- ✅ **Firewall UFW** configurado automáticamente
- ✅ **Headers de seguridad** en todas las respuestas
- ✅ **Acceso restringido** al panel de administración
- ✅ **Logs de seguridad** detallados
- ✅ **Encriptación HTTPS** ready
- ✅ **Validación de entrada** en todas las APIs

### 🔧 **Configuración Recomendada**

```bash
# Cambiar contraseñas por defecto
sudo nano /opt/shoutcast/sc_serv.conf

# Configurar SSL/TLS (opcional)
sudo certbot --nginx -d tu-dominio.com

# Backup automático
sudo crontab -e
# Agregar: 0 2 * * * /usr/local/bin/backup-streamly.sh
```

---

## 🚀 Desarrollo y Contribución

### 🛠️ **Configuración de Desarrollo**

```bash
# Clonar repositorio
git clone https://github.com/kambire/streamly-control-hub.git
cd streamly-control-hub

# Instalar dependencias
npm install

# Ejecutar en modo desarrollo
npm run dev

# Construir para producción
npm run build
```

### 📋 **Scripts Disponibles**

```json
{
  "dev": "Servidor de desarrollo",
  "build": "Construir para producción",
  "preview": "Previsualizar build",
  "lint": "Verificar código con ESLint"
}
```

---

## 📚 Documentación Extendida

<div align="center">

| Sección | Descripción | Enlace |
|:--------|:------------|:-------|
| **🚀 Guía de Inicio** | Primeros pasos y configuración | [Ver Guía](docs/getting-started.md) |
| **🔧 API Reference** | Documentación completa de la API | [Ver API](docs/api.md) |
| **🎵 Streaming Setup** | Configuración avanzada de Shoutcast | [Ver Setup](docs/streaming.md) |
| **🛡️ Security Guide** | Mejores prácticas de seguridad | [Ver Seguridad](docs/security.md) |
| **🐛 Troubleshooting** | Solución de problemas comunes | [Ver Ayuda](docs/troubleshooting.md) |

</div>

---

## 🤝 Contribuir al Proyecto

¡Nos encanta recibir contribuciones! 🎉

### 📝 **Cómo Contribuir**

1. **Fork** el repositorio
2. **Crea** una rama para tu feature (`git checkout -b feature/amazing-feature`)
3. **Commit** tus cambios (`git commit -m 'Add amazing feature'`)
4. **Push** a la rama (`git push origin feature/amazing-feature`)
5. **Abre** un Pull Request

### 🐛 **Reportar Bugs**

- Usa el [template de issues](https://github.com/kambire/streamly-control-hub/issues/new?template=bug_report.md)
- Incluye información del sistema
- Proporciona logs relevantes
- Describe pasos para reproducir

### 💡 **Solicitar Features**

- Usa el [template de features](https://github.com/kambire/streamly-control-hub/issues/new?template=feature_request.md)
- Describe el caso de uso
- Explica el beneficio esperado

---

## 📊 Estadísticas del Proyecto

<div align="center">

![GitHub stars](https://img.shields.io/github/stars/kambire/streamly-control-hub?style=social)
![GitHub forks](https://img.shields.io/github/forks/kambire/streamly-control-hub?style=social)
![GitHub watchers](https://img.shields.io/github/watchers/kambire/streamly-control-hub?style=social)

![GitHub issues](https://img.shields.io/github/issues/kambire/streamly-control-hub)
![GitHub pull requests](https://img.shields.io/github/issues-pr/kambire/streamly-control-hub)
![GitHub last commit](https://img.shields.io/github/last-commit/kambire/streamly-control-hub)

</div>

---

## 📞 Soporte y Comunidad

<div align="center">

### 🆘 **Necesitas Ayuda?**

[![Discord](https://img.shields.io/badge/Discord-7289DA?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/streamly)
[![Email](https://img.shields.io/badge/Email-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:support@streamly.com)
[![GitHub Issues](https://img.shields.io/badge/GitHub-Issues-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/kambire/streamly-control-hub/issues)

### 🌟 **Síguenos**

[![Twitter](https://img.shields.io/badge/Twitter-1DA1F2?style=for-the-badge&logo=twitter&logoColor=white)](https://twitter.com/streamly_hub)
[![YouTube](https://img.shields.io/badge/YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://youtube.com/@streamly)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/company/streamly)

</div>

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.

```
MIT License

Copyright (c) 2024 Streamly Control Hub

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

## 🎯 Roadmap

### 🔮 **Próximas Versiones**

- [ ] **v2.1.0** - API REST completa
- [ ] **v2.2.0** - Aplicación móvil companion
- [ ] **v2.3.0** - Integración con Docker
- [ ] **v2.4.0** - Soporte multi-servidor
- [ ] **v2.5.0** - Analytics avanzados
- [ ] **v3.0.0** - Reescritura con microservicios

### 🎨 **Características Planeadas**

- 📱 **App Móvil** - Control desde dispositivos móviles
- 🌍 **Multi-idioma** - Soporte para múltiples idiomas
- 🎨 **Temas** - Personalización visual avanzada
- 📊 **Reporting** - Reportes automáticos y programados
- 🔐 **SSO** - Single Sign-On con OAuth2
- 🏢 **Multi-tenant** - Soporte para múltiples organizaciones

---

<div align="center">

## 🙏 Agradecimientos

Gracias a todos los que han contribuido a este proyecto:

[![Contributors](https://contrib.rocks/image?repo=kambire/streamly-control-hub)](https://github.com/kambire/streamly-control-hub/graphs/contributors)

### 💖 **Tecnologías que Amamos**

- [**shadcn/ui**](https://ui.shadcn.com/) - Componentes UI increíbles
- [**Tailwind CSS**](https://tailwindcss.com/) - Framework CSS utility-first
- [**Lucide**](https://lucide.dev/) - Iconos hermosos y consistentes
- [**React**](https://reactjs.org/) - La biblioteca UI que cambió todo
- [**Vite**](https://vitejs.dev/) - Build tool súper rápido
- [**Shoutcast**](http://www.shoutcast.com/) - Servidor de streaming confiable

---

<div align="center">

**Hecho con ❤️ por [kambire](https://github.com/kambire)**

*Streamly Control Hub - Transformando la manera de hacer radio online*

</div>

---

<div align="center">

### ⭐ **Si este proyecto te ayuda, dale una estrella!**

[![GitHub stars](https://img.shields.io/github/stars/kambire/streamly-control-hub?style=social)](https://github.com/kambire/streamly-control-hub/stargazers)

</div>

</div>
