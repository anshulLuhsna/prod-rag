#!/bin/bash
# Startup script for NIFTY 50 RAG MVP Development VM
# This runs automatically when the VM is created

set -e

echo "=========================================="
echo "NIFTY 50 RAG MVP - VM Setup Starting"
echo "=========================================="

# Update system
echo "[1/8] Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install essential tools
echo "[2/8] Installing essential tools..."
sudo apt-get install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    unzip \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Docker
echo "[3/8] Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "Docker installed successfully"
else
    echo "Docker already installed"
fi

# Install Docker Compose
echo "[4/8] Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed successfully"
else
    echo "Docker Compose already installed"
fi

# Install Python 3.11 and pip
echo "[5/8] Installing Python 3.11..."
sudo apt-get install -y python3.11 python3.11-venv python3.11-dev python3-pip
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

# Install Node.js 20 LTS
echo "[6/8] Installing Node.js 20 LTS..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo "Node.js installed successfully"
else
    echo "Node.js already installed"
fi

# Install Google Cloud SDK (for accessing secrets, storage, etc.)
echo "[7/8] Installing Google Cloud SDK..."
if ! command -v gcloud &> /dev/null; then
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    sudo apt-get update && sudo apt-get install -y google-cloud-sdk
    echo "Google Cloud SDK installed successfully"
else
    echo "Google Cloud SDK already installed"
fi

# Create project directory structure
echo "[8/8] Setting up project directory..."
mkdir -p ~/nifty50-rag
cd ~/nifty50-rag

# Clone repository (if using git)
# Uncomment and modify if you have a git repo
# if [ ! -d ".git" ]; then
#     git clone https://github.com/your-org/nifty50-rag.git .
# fi

# Create necessary directories
mkdir -p data/documents
mkdir -p data/logs
mkdir -p .ssh

# Set permissions
chmod 700 ~/nifty50-rag/.ssh

echo "=========================================="
echo "VM Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. SSH into the VM: ssh -i ~/.ssh/nifty50_rag_key dev@<VM_IP>"
echo "2. Navigate to: cd ~/nifty50-rag"
echo "3. Set up your project files"
echo "4. Run: docker-compose up -d"
echo ""
echo "Installed versions:"
echo "- Docker: $(docker --version 2>/dev/null || echo 'Not installed')"
echo "- Docker Compose: $(docker-compose --version 2>/dev/null || echo 'Not installed')"
echo "- Python: $(python3 --version 2>/dev/null || echo 'Not installed')"
echo "- Node.js: $(node --version 2>/dev/null || echo 'Not installed')"
echo "- gcloud: $(gcloud --version 2>/dev/null | head -1 || echo 'Not installed')"
echo "=========================================="

# Note: User needs to log out and back in for Docker group changes to take effect
echo ""
echo "⚠️  IMPORTANT: After first login, run: newgrp docker"
echo "   Or log out and log back in for Docker permissions"



