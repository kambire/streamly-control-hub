# Welcome to your Lovable project

## Project info

**URL**: https://lovable.dev/projects/2e5d81ee-f797-45a4-90ab-12d60b5faa02

## How can I edit this code?

There are several ways of editing your application.

**Use Lovable**

Simply visit the [Lovable Project](https://lovable.dev/projects/2e5d81ee-f797-45a4-90ab-12d60b5faa02) and start prompting.

Changes made via Lovable will be committed automatically to this repo.

**Use your preferred IDE**

If you want to work locally using your own IDE, you can clone this repo and push changes. Pushed changes will also be reflected in Lovable.

The only requirement is having Node.js & npm installed - [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating)

Follow these steps:

```sh
# Step 1: Clone the repository using the project's Git URL.
git clone <YOUR_GIT_URL>

# Step 2: Navigate to the project directory.
cd <YOUR_PROJECT_NAME>

# Step 3: Install the necessary dependencies.
npm i

# Step 4: Start the development server with auto-reloading and an instant preview.
npm run dev
```

**Edit a file directly in GitHub**

- Navigate to the desired file(s).
- Click the "Edit" button (pencil icon) at the top right of the file view.
- Make your changes and commit the changes.

**Use GitHub Codespaces**

- Navigate to the main page of your repository.
- Click on the "Code" button (green button) near the top right.
- Select the "Codespaces" tab.
- Click on "New codespace" to launch a new Codespace environment.
- Edit files directly within the Codespace and commit and push your changes once you're done.

## What technologies are used for this project?

This project is built with:

- Vite
- TypeScript
- React
- shadcn-ui
- Tailwind CSS

## How can I deploy this project?

Simply open [Lovable](https://lovable.dev/projects/2e5d81ee-f797-45a4-90ab-12d60b5faa02) and click on Share -> Publish.

## Can I connect a custom domain to my Lovable project?

Yes, you can!

To connect a domain, navigate to Project > Settings > Domains and click Connect Domain.

Read more here: [Setting up a custom domain](https://docs.lovable.dev/tips-tricks/custom-domain#step-by-step-guide)

## Ubuntu 22.04 Installation Guide

### Prerequisites
1. A fresh Ubuntu 22.04 LTS server
2. Root or sudo access
3. Domain name pointed to your server (optional)

### Manual Installation Steps

1. **Update System & Install Dependencies**
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git nginx nodejs npm certbot python3-certbot-nginx
```

2. **Install Node Version Manager (nvm)**
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20
```

3. **Clone the Repository**
```bash
git clone <YOUR_GIT_URL>
cd <YOUR_PROJECT_NAME>
```

4. **Install Dependencies**
```bash
npm install
```

5. **Build the Application**
```bash
npm run build
```

6. **Configure Nginx**
```bash
sudo nano /etc/nginx/sites-available/streamly
```

Add this configuration:
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
    }
}
```

7. **Enable the Site**
```bash
sudo ln -s /etc/nginx/sites-available/streamly /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

8. **SSL Certificate (Optional)**
```bash
sudo certbot --nginx -d your-domain.com
```

9. **Start the Application**
```bash
npm run dev
```

### Automatic Installation Script

You can also use our automatic installation script:

```bash
wget https://raw.githubusercontent.com/your-repo/install.sh
chmod +x install.sh
sudo ./install.sh
```
