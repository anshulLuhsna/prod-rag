#!/bin/bash
# Quick setup script for Terraform GCP VM
# Run this from the terraform directory

set -e

echo "=========================================="
echo "NIFTY 50 RAG - Terraform VM Setup"
echo "=========================================="
echo ""

# Check prerequisites
echo "[1/6] Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Please install Terraform first."
    exit 1
fi

if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI not found. Please install Google Cloud SDK first."
    exit 1
fi

echo "✅ Prerequisites check passed"
echo ""

# Check authentication
echo "[2/6] Checking GCP authentication..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "⚠️  Not authenticated with GCP. Running gcloud auth login..."
    gcloud auth login
    gcloud auth application-default login
fi

# Get project ID
if [ -f "terraform.tfvars" ]; then
    PROJECT_ID=$(grep "project_id" terraform.tfvars | cut -d'"' -f2)
    echo "✅ Using project: $PROJECT_ID"
    gcloud config set project "$PROJECT_ID"
else
    echo "⚠️  terraform.tfvars not found. Please create it first."
    echo "   Run: cp terraform.tfvars.example terraform.tfvars"
    echo "   Then edit terraform.tfvars with your project_id"
    exit 1
fi

echo ""

# Enable APIs
echo "[3/6] Enabling required GCP APIs..."
gcloud services enable compute.googleapis.com --quiet
gcloud services enable cloudresourcemanager.googleapis.com --quiet
echo "✅ APIs enabled"
echo ""

# Create SSH directory
echo "[4/6] Creating SSH directory..."
mkdir -p ../.ssh
chmod 700 ../.ssh
echo "✅ SSH directory created"
echo ""

# Initialize Terraform
echo "[5/6] Initializing Terraform..."
terraform init
echo "✅ Terraform initialized"
echo ""

# Show plan
echo "[6/6] Showing Terraform plan..."
echo ""
terraform plan
echo ""

# Ask for confirmation
read -p "Do you want to create the VM? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

# Apply
echo ""
echo "Creating VM (this may take 2-3 minutes)..."
terraform apply -auto-approve

# Get outputs
echo ""
echo "=========================================="
echo "✅ VM Created Successfully!"
echo "=========================================="
echo ""

VM_IP=$(terraform output -raw vm_external_ip)
SSH_CMD=$(terraform output -raw ssh_command)

echo "VM External IP: $VM_IP"
echo ""
echo "SSH Command:"
echo "$SSH_CMD"
echo ""
echo "SSH Config Entry (add to ~/.ssh/config):"
terraform output -raw ssh_config_entry
echo ""

echo "Next steps:"
echo "1. Wait 2-3 minutes for VM startup script to complete"
echo "2. SSH into VM: $SSH_CMD"
echo "3. Verify installations: docker --version, python3 --version"
echo "4. Navigate to: cd ~/nifty50-rag"
echo "5. Copy your project files or clone from git"
echo "6. Start services: docker-compose up -d"
echo ""
echo "=========================================="

