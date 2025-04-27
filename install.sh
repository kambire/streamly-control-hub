
#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Starting Streamly Admin Panel Installation...${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update system
echo -e "${YELLOW}Updating system packages...${NC}"
apt update && apt upgrade -y

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
apt install -y curl git nginx nodejs npm certbot python3-certbot-nginx

# Install NVM
echo -e "${YELLOW}Installing NVM...${NC}"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node.js
echo -e "${YELLOW}Installing Node.js...${NC}"
nvm install 20
nvm use 20

# Create application directory
echo -e "${YELLOW}Creating application directory...${NC}"
mkdir -p /var/www/streamly
cd /var/www/streamly

# Clone repository
echo -e "${YELLOW}Cloning repository...${NC}"
git clone <YOUR_GIT_URL> .

# Install project dependencies
echo -e "${YELLOW}Installing project dependencies...${NC}"
npm install

# Build the application
echo -e "${YELLOW}Building the application...${NC}"
npm run build

# Configure Nginx
echo -e "${YELLOW}Configuring Nginx...${NC}"
cat > /etc/nginx/sites-available/streamly << 'EOL'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOL

# Enable the site
ln -s /etc/nginx/sites-available/streamly /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

# Create systemd service
echo -e "${YELLOW}Creating systemd service...${NC}"
cat > /etc/systemd/system/streamly.service << 'EOL'
[Unit]
Description=Streamly Admin Panel
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/streamly
ExecStart=/usr/bin/npm run dev
Restart=always
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOL

# Start and enable the service
systemctl daemon-reload
systemctl enable streamly
systemctl start streamly

echo -e "${GREEN}Installation completed!${NC}"
echo -e "${GREEN}You can now access your admin panel at http://your-server-ip${NC}"
echo -e "${YELLOW}Don't forget to:"
echo "1. Configure your domain in Nginx configuration"
echo "2. Set up SSL with: sudo certbot --nginx -d your-domain.com"
echo -e "3. Update environment variables if needed${NC}"

