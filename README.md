
# Streamly Control Hub

A modern, responsive admin panel for streaming platform management built with React, TypeScript, and Tailwind CSS.

![Streamly Control Hub](https://via.placeholder.com/800x400/1a1a1a/ffffff?text=Streamly+Control+Hub)

## ✨ Features

- **Dashboard Overview** - Real-time statistics and system monitoring
- **User Management** - Comprehensive user and subscription management
- **Streaming Control** - Live stream management and VOD handling
- **System Administration** - Server status, database, and mail server management
- **Security Features** - Firewall configuration and reporting tools
- **Responsive Design** - Mobile-friendly interface with modern UI components

## 🚀 Quick Start

### Prerequisites

- Ubuntu 22.04 LTS (recommended)
- Node.js 20+ and npm
- Git
- Root or sudo access

### Automatic Installation

Run our automated installation script:

```bash
curl -fsSL https://raw.githubusercontent.com/kambire/streamly-control-hub/main/install.sh | sudo bash
```

Or download and run manually:

```bash
wget https://raw.githubusercontent.com/kambire/streamly-control-hub/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

### Manual Installation

1. **Clone the repository**
```bash
git clone https://github.com/kambire/streamly-control-hub.git
cd streamly-control-hub
```

2. **Install dependencies**
```bash
npm install
```

3. **Start development server**
```bash
npm run dev
```

4. **Build for production**
```bash
npm run build
npm run preview
```

## 🛠️ Technology Stack

- **Frontend**: React 18 + TypeScript
- **Styling**: Tailwind CSS + shadcn/ui
- **State Management**: TanStack Query
- **Routing**: React Router v6
- **Build Tool**: Vite
- **Icons**: Lucide React

## 📁 Project Structure

```
src/
├── components/          # Reusable UI components
│   ├── layout/         # Layout components (Header, Sidebar, etc.)
│   └── ui/             # shadcn/ui components
├── pages/              # Page components
├── hooks/              # Custom React hooks
├── lib/                # Utility functions
└── main.tsx           # Application entry point
```

## 🔧 Development

### Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint

### Environment Setup

1. Copy environment template:
```bash
cp .env.example .env.local
```

2. Configure your environment variables:
```env
VITE_API_URL=http://localhost:3000/api
```

## 🚀 Deployment

### Using the Installation Script

The easiest way to deploy Streamly Control Hub is using our automated installation script:

```bash
# Basic installation
curl -fsSL https://raw.githubusercontent.com/kambire/streamly-control-hub/main/install.sh | sudo bash

# With domain and SSL
curl -fsSL https://raw.githubusercontent.com/kambire/streamly-control-hub/main/install.sh | sudo bash -s -- --domain your-domain.com --email your-email@example.com
```

### Manual Deployment

#### Using Docker

```bash
# Build Docker image
docker build -t streamly-control-hub .

# Run container
docker run -p 8080:8080 streamly-control-hub
```

#### Using PM2

```bash
# Install PM2 globally
npm install -g pm2

# Build the application
npm run build

# Start application
pm2 start "npm run preview" --name streamly

# Save PM2 configuration
pm2 save
pm2 startup
```

### Nginx Configuration

```nginx
server {
    listen 80;
    server_name your-domain.com;
    
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
    }
}
```

## 🔄 Updates

To update your installation to the latest version:

```bash
# Using update script
sudo ./update.sh

# Or manually
git pull origin main
npm install
npm run build
sudo systemctl restart streamly
```

## 📋 System Requirements

### Minimum Requirements
- **CPU**: 1 core
- **RAM**: 1GB
- **Storage**: 2GB free space
- **OS**: Ubuntu 20.04+ / CentOS 8+ / Debian 11+

### Recommended Requirements
- **CPU**: 2+ cores
- **RAM**: 2GB+
- **Storage**: 5GB+ free space
- **Network**: 100Mbps+

## 🔒 Security

- All API endpoints require authentication
- HTTPS encryption in production
- CORS protection enabled
- Rate limiting implemented
- Input validation and sanitization

## 🐛 Troubleshooting

### Common Issues

**Port 8080 already in use**
```bash
sudo lsof -i :8080
sudo kill -9 <PID>
```

**Permission denied errors**
```bash
sudo chown -R $USER:$USER /var/www/streamly
```

**Node.js version issues**
```bash
# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Logs

Check application logs:
```bash
# SystemD logs
sudo journalctl -u streamly -f

# PM2 logs
pm2 logs streamly

# Nginx logs
sudo tail -f /var/log/nginx/error.log
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### Development Guidelines

- Follow TypeScript best practices
- Use semantic commit messages
- Add tests for new features
- Update documentation as needed

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: [GitHub Repository](https://github.com/kambire/streamly-control-hub)
- **Issues**: [GitHub Issues](https://github.com/kambire/streamly-control-hub/issues)
- **Email**: support@streamly.com

## 🗺️ Roadmap

- [ ] Real-time streaming analytics
- [ ] Multi-server support
- [ ] Advanced user role management
- [ ] API documentation
- [ ] Mobile app companion
- [ ] Docker Compose setup
- [ ] Kubernetes deployment

## 🙏 Acknowledgments

- [shadcn/ui](https://ui.shadcn.com/) for the amazing component library
- [Tailwind CSS](https://tailwindcss.com/) for the utility-first CSS framework
- [Lucide](https://lucide.dev/) for the beautiful icons
- [React](https://reactjs.org/) for the powerful UI library
- [Vite](https://vitejs.dev/) for the fast build tool

---

Made with ❤️ by [kambire](https://github.com/kambire)
