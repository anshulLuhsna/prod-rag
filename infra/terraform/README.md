# Terraform Setup for GCP VM - MVP Development

This guide walks you through creating a GCP VM using Terraform and setting up SSH access for MVP development.

---

## Prerequisites

1. **GCP Account** with billing enabled
2. **GCP Project** created
3. **Terraform** installed (>= 1.0)
4. **gcloud CLI** installed and authenticated
5. **SSH client** (built into most systems)

---

## Step 1: Install Prerequisites

### Install Terraform

**macOS:**
```bash
brew install terraform
```

**Linux:**
```bash
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

**Windows:**
Download from https://www.terraform.io/downloads

### Install Google Cloud SDK

```bash
# macOS
brew install google-cloud-sdk

# Linux
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Windows
# Download installer from https://cloud.google.com/sdk/docs/install
```

### Authenticate with GCP

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

### Enable Required APIs

```bash
gcloud services enable compute.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

---

## Step 2: Configure Terraform

### 1. Navigate to Terraform Directory

```bash
cd prod-rag/infra/terraform
```

### 2. Create terraform.tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
project_id = "your-gcp-project-id"
# Optionally override other variables
```

### 3. Create SSH Directory

```bash
mkdir -p ../.ssh
chmod 700 ../.ssh
```

---

## Step 3: Initialize and Apply Terraform

### Initialize Terraform

```bash
terraform init
```

This downloads the Google provider and sets up the backend.

### Review Plan

```bash
terraform plan
```

Review what will be created:
- VPC network and subnet
- Firewall rules (SSH + app ports)
- Static IP address
- VM instance (e2-standard-4)
- SSH key pair

### Apply Configuration

```bash
terraform apply
```

Type `yes` when prompted. This takes ~2-3 minutes.

**What happens:**
1. Creates VPC network
2. Creates firewall rules
3. Generates SSH key pair
4. Creates VM with startup script
5. Installs Docker, Python, Node.js, etc.

### Get Outputs

After apply completes, you'll see outputs like:

```
vm_external_ip = "34.93.xxx.xxx"
ssh_command = "ssh -i ../.ssh/nifty50_rag_key dev@34.93.xxx.xxx"
```

**Save the IP address!**

---

## Step 4: SSH into the VM

### Option 1: Direct SSH Command

```bash
ssh -i ../.ssh/nifty50_rag_key dev@<VM_EXTERNAL_IP>
```

Replace `<VM_EXTERNAL_IP>` with the IP from terraform output.

### Option 2: SSH Config (Recommended)

Add to `~/.ssh/config`:

```
Host nifty50-rag-dev
    HostName <VM_EXTERNAL_IP>
    User dev
    IdentityFile /path/to/prod-rag/infra/.ssh/nifty50_rag_key
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

Then simply:
```bash
ssh nifty50-rag-dev
```

### First Login

On first login, you'll see the startup script output. Wait for it to complete (~5 minutes).

Verify installations:
```bash
docker --version
docker-compose --version
python3 --version
node --version
gcloud --version
```

**Important:** For Docker to work without sudo, run:
```bash
newgrp docker
# Or log out and log back in
```

---

## Step 5: Set Up Development Environment

### 1. Navigate to Project Directory

```bash
cd ~/nifty50-rag
```

### 2. Clone/Copy Your Project

**Option A: If using Git**
```bash
git clone https://github.com/your-org/nifty50-rag.git .
```

**Option B: Copy files from local machine**

From your local machine:
```bash
# Copy entire project
scp -r -i infra/.ssh/nifty50_rag_key \
    /path/to/prod-rag/* \
    dev@<VM_IP>:~/nifty50-rag/

# Or use rsync (better for large files)
rsync -avz -e "ssh -i infra/.ssh/nifty50_rag_key" \
    /path/to/prod-rag/ \
    dev@<VM_IP>:~/nifty50-rag/
```

### 3. Set Up Environment Variables

```bash
cd ~/nifty50-rag
cp .env.example .env
nano .env  # Edit with your API keys
```

### 4. Start Services

```bash
docker-compose up -d
```

This starts:
- PostgreSQL
- Qdrant
- Redis
- Backend (FastAPI)
- Frontend (Next.js)

### 5. Verify Services

```bash
# Check running containers
docker ps

# Check logs
docker-compose logs -f

# Test backend
curl http://localhost:8000/health

# Test frontend
curl http://localhost:3000
```

---

## Step 6: Development Workflow

### Working on the VM

**Option 1: Direct Development on VM**
- SSH into VM
- Edit files with `vim`, `nano`, or install VS Code Server
- Run commands directly

**Option 2: VS Code Remote SSH (Recommended)**

1. Install "Remote - SSH" extension in VS Code
2. Connect to `nifty50-rag-dev` (from SSH config)
3. Open folder: `~/nifty50-rag`
4. Develop as if local!

**Option 3: Sync Files**

Use `rsync` to sync files from local to VM:
```bash
# From local machine
rsync -avz --exclude 'node_modules' --exclude '.git' \
    -e "ssh -i infra/.ssh/nifty50_rag_key" \
    ./ \
    dev@<VM_IP>:~/nifty50-rag/
```

### Port Forwarding (Access Services Locally)

Forward ports to your local machine:

```bash
# From local machine
ssh -i infra/.ssh/nifty50_rag_key \
    -L 8000:localhost:8000 \
    -L 3000:localhost:3000 \
    -L 6333:localhost:6333 \
    dev@<VM_IP>
```

Then access:
- Backend: http://localhost:8000
- Frontend: http://localhost:3000
- Qdrant: http://localhost:6333

---

## Step 7: Managing the VM

### Stop VM (Save Costs)

```bash
# From local machine
gcloud compute instances stop nifty50-rag-dev --zone=asia-south1-a

# Or via Terraform
cd infra/terraform
terraform destroy -target=google_compute_instance.dev_vm
terraform apply  # Recreates it
```

### Start VM

```bash
gcloud compute instances start nifty50-rag-dev --zone=asia-south1-a
```

### View VM Status

```bash
gcloud compute instances describe nifty50-rag-dev --zone=asia-south1-a
```

### Resize VM (Change Machine Type)

Edit `terraform.tfvars`:
```hcl
machine_type = "e2-standard-8"  # Upgrade to 8 vCPU
```

Then:
```bash
terraform apply
```

**Note:** VM will be stopped and restarted.

### View Costs

```bash
# In GCP Console: Billing > Reports
# Or use gcloud:
gcloud billing accounts list
```

**Estimated Monthly Cost:**
- e2-standard-4: ~$100/month
- Disk (50GB SSD): ~$8/month
- Static IP: ~$2/month
- **Total: ~$110/month**

---

## Step 8: Cleanup

### Destroy Everything

```bash
cd infra/terraform
terraform destroy
```

This removes:
- VM instance
- Static IP
- Firewall rules
- VPC network (if not used elsewhere)

**Warning:** This deletes everything! Make sure you've backed up your work.

### Destroy Only VM (Keep Network)

```bash
terraform destroy -target=google_compute_instance.dev_vm
terraform destroy -target=google_compute_address.static_ip
```

---

## Troubleshooting

### SSH Connection Refused

1. Check firewall rule allows your IP:
   ```bash
   gcloud compute firewall-rules describe allow-ssh-nifty50-rag
   ```

2. Check VM is running:
   ```bash
   gcloud compute instances list
   ```

3. Check your IP hasn't changed:
   ```bash
   curl https://api.ipify.org
   ```

### Permission Denied (SSH Key)

```bash
chmod 600 infra/.ssh/nifty50_rag_key
```

### Docker Permission Denied

```bash
# On VM
sudo usermod -aG docker $USER
newgrp docker
# Or log out and back in
```

### Can't Access Services

1. Check firewall rules allow your IP
2. Check services are running:
   ```bash
   docker ps
   docker-compose ps
   ```
3. Check ports are listening:
   ```bash
   sudo netstat -tlnp | grep -E '8000|3000|6333'
   ```

### VM Startup Script Failed

Check logs:
```bash
# On VM
sudo journalctl -u google-startup-scripts.service
```

Re-run startup script manually:
```bash
sudo bash /var/run/google.startup.script
```

---

## Security Best Practices

1. **Firewall Rules:** Only allow your IP (already configured)
2. **SSH Keys:** Use key-based auth (already configured)
3. **Updates:** Keep system updated:
   ```bash
   sudo apt-get update && sudo apt-get upgrade -y
   ```
4. **Secrets:** Use GCP Secret Manager, not `.env` files in git
5. **Backup:** Regularly backup important data

---

## Next Steps

After VM is set up:

1. ✅ Clone/copy project files
2. ✅ Set up environment variables
3. ✅ Start Docker services
4. ✅ Begin MVP development (Week 1 of MVP plan)
5. ✅ Set up monitoring and logging

---

## Quick Reference

```bash
# SSH into VM
ssh nifty50-rag-dev

# Start services
cd ~/nifty50-rag && docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Stop VM (save costs)
gcloud compute instances stop nifty50-rag-dev --zone=asia-south1-a

# Start VM
gcloud compute instances start nifty50-rag-dev --zone=asia-south1-a

# Destroy everything
cd infra/terraform && terraform destroy
```

---

*For questions or issues, refer to the main MVP plan or create an issue.*



