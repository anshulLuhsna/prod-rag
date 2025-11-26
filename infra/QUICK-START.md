# Quick Start: GCP VM Setup for MVP

This is a condensed guide to get your GCP VM up and running quickly.

---

## Prerequisites Checklist

- [ ] GCP account with billing enabled
- [ ] GCP project created
- [ ] Terraform installed (`terraform --version`)
- [ ] gcloud CLI installed (`gcloud --version`)
- [ ] Authenticated with GCP (`gcloud auth login`)

---

## 5-Minute Setup

### Step 1: Configure

```bash
cd prod-rag/infra/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
project_id = "your-gcp-project-id"
```

### Step 2: Run Setup Script

```bash
# Make executable (Linux/Mac)
chmod +x setup.sh
./setup.sh

# Or manually:
terraform init
terraform plan
terraform apply
```

### Step 3: SSH into VM

```bash
# Get the SSH command from output
ssh -i ../.ssh/nifty50_rag_key dev@<VM_IP>

# Or add to ~/.ssh/config and use:
ssh nifty50-rag-dev
```

### Step 4: Wait for Setup

The VM startup script takes ~5 minutes. Wait for it to complete.

### Step 5: Verify

```bash
# On VM
docker --version
python3 --version
node --version
cd ~/nifty50-rag
```

---

## Copy Your Project to VM

### Option 1: Git Clone (Recommended)

```bash
# On VM
cd ~/nifty50-rag
git clone https://github.com/your-org/nifty50-rag.git .
```

### Option 2: SCP from Local

```bash
# From local machine
scp -r -i infra/terraform/../.ssh/nifty50_rag_key \
    /path/to/prod-rag/* \
    dev@<VM_IP>:~/nifty50-rag/
```

### Option 3: VS Code Remote SSH

1. Install "Remote - SSH" extension
2. Connect to `nifty50-rag-dev`
3. Open `~/nifty50-rag` folder
4. Develop directly on VM!

---

## Start Development

```bash
# On VM
cd ~/nifty50-rag

# Set up environment
cp .env.example .env
nano .env  # Add your API keys

# Start services
docker-compose up -d

# Check status
docker ps
docker-compose logs -f
```

---

## Access Services

### From VM (localhost)
- Backend: http://localhost:8000
- Frontend: http://localhost:3000
- Qdrant: http://localhost:6333

### From Local Machine (Port Forwarding)

```bash
# SSH with port forwarding
ssh -i infra/terraform/../.ssh/nifty50_rag_key \
    -L 8000:localhost:8000 \
    -L 3000:localhost:3000 \
    -L 6333:localhost:6333 \
    dev@<VM_IP>
```

Then access from your browser:
- Backend: http://localhost:8000
- Frontend: http://localhost:3000

---

## Cost Management

### Stop VM (When Not Using)

```bash
gcloud compute instances stop nifty50-rag-dev --zone=asia-south1-a
```

**Saves ~$0.15/hour** (e2-standard-4)

### Start VM

```bash
gcloud compute instances start nifty50-rag-dev --zone=asia-south1-a
```

### Estimated Monthly Cost

- Running 24/7: ~$110/month
- Running 8 hours/day: ~$37/month
- Running only when needed: ~$10-20/month

---

## Common Commands

```bash
# SSH into VM
ssh nifty50-rag-dev

# Start services
cd ~/nifty50-rag && docker-compose up -d

# View logs
docker-compose logs -f backend

# Stop services
docker-compose down

# Stop VM
gcloud compute instances stop nifty50-rag-dev --zone=asia-south1-a

# Start VM
gcloud compute instances start nifty50-rag-dev --zone=asia-south1-a

# Destroy VM (careful!)
cd infra/terraform && terraform destroy
```

---

## Troubleshooting

**Can't SSH?**
- Check firewall allows your IP
- Check VM is running: `gcloud compute instances list`
- Verify IP: `terraform output vm_external_ip`

**Docker permission denied?**
```bash
# On VM
sudo usermod -aG docker $USER
newgrp docker
```

**Services not accessible?**
- Check firewall rules
- Check services running: `docker ps`
- Check logs: `docker-compose logs`

---

## Next Steps

1. ✅ VM is running
2. ✅ Project files copied
3. ✅ Environment variables set
4. ✅ Services started
5. 🚀 Begin MVP development (Week 1 of MVP plan)

---

For detailed documentation, see `infra/terraform/README.md`


