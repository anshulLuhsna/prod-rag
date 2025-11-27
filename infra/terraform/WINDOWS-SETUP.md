# Windows Setup Guide - Quick Reference

This is a Windows-specific guide for setting up the GCP VM with Terraform.

---

## Prerequisites

1. **Terraform** - Download from https://www.terraform.io/downloads
2. **Google Cloud SDK** - Download from https://cloud.google.com/sdk/docs/install
3. **SSH Client** - Windows 10+ includes OpenSSH by default

---

## Step 1: Check Your SSH Keys

Run the helper script:

```powershell
cd prod-rag\infra\terraform
.\check-ssh-keys.ps1
```

Or manually check:

```powershell
Test-Path "$env:USERPROFILE\.ssh\id_rsa.pub"
```

**If you have keys:** You'll see a path to use in `terraform.tfvars`  
**If you don't have keys:** Terraform will generate them automatically

---

## Step 2: Configure Terraform

1. Copy the example file:
```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with Notepad or your editor:
```powershell
notepad terraform.tfvars
```

3. Fill in your project ID and SSH key preference:

**Option A: Use Existing SSH Key**
```hcl
project_id = "your-gcp-project-id"
use_existing_ssh_key = true
existing_ssh_public_key_path = "C:\\Users\\YourUsername\\.ssh\\id_rsa.pub"
```

**Option B: Generate New Key (Default)**
```hcl
project_id = "your-gcp-project-id"
use_existing_ssh_key = false
```

---

## Step 3: Authenticate with GCP

```powershell
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

---

## Step 4: Create the VM

```powershell
terraform init
terraform plan
terraform apply
```

Type `yes` when prompted.

---

## Step 5: SSH into the VM

After `terraform apply` completes, you'll get an SSH command. Use it like this:

**If using generated key:**
```powershell
ssh -i "..\.ssh\nifty50_rag_key" dev@<VM_IP>
```

**If using existing key:**
```powershell
# Option 1: Using environment variable (recommended)
ssh -i "$env:USERPROFILE\.ssh\id_rsa" dev@<VM_IP>

# Option 2: Using full path (if path has spaces, use quotes)
ssh -i "C:\Users\YourUsername\.ssh\id_rsa" dev@<VM_IP>

# Option 3: Using forward slashes (also works on Windows)
ssh -i "C:/Users/YourUsername/.ssh/id_rsa" dev@<VM_IP>
```

**Important:** Don't use escaped quotes (`\"`). Use regular double quotes (`"`) around the path.

---

## Step 6: Set Up SSH Config (Optional but Recommended)

Create or edit `C:\Users\<YourUsername>\.ssh\config`:

```
Host nifty50-rag-dev
    HostName <VM_IP>
    User dev
    IdentityFile C:\Users\<YourUsername>\.ssh\id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile NUL
```

Then you can simply:
```powershell
ssh nifty50-rag-dev
```

---

## Common Issues

### Issue: "Permission denied (publickey)"

**Solution:** Make sure you're using the correct key path:
```powershell
# Check which key Terraform is using
terraform output ssh_key_path

# Use that exact path in SSH command
ssh -i "<path_from_output>" dev@<VM_IP>
```

### Issue: "Could not resolve hostname"

**Solution:** Use the IP address directly instead of hostname.

### Issue: "SSH key file not found"

**Solution:** 
- If using existing key: Check the path in `terraform.tfvars` uses double backslashes: `C:\\Users\\...`
- If using generated key: Check that `terraform apply` completed successfully

### Issue: "Terraform can't find SSH key file"

**Solution:** Use absolute path with forward slashes or escaped backslashes:
```hcl
existing_ssh_public_key_path = "C:/Users/YourUsername/.ssh/id_rsa.pub"
# OR
existing_ssh_public_key_path = "C:\\Users\\YourUsername\\.ssh\\id_rsa.pub"
```

---

## Port Forwarding (Access Services from Windows)

To access services running on the VM from your Windows machine:

```powershell
ssh -i "$env:USERPROFILE\.ssh\id_rsa" `
    -L 8000:localhost:8000 `
    -L 3000:localhost:3000 `
    -L 6333:localhost:6333 `
    dev@<VM_IP>
```

Then open in browser:
- Backend: http://localhost:8000
- Frontend: http://localhost:3000
- Qdrant: http://localhost:6333

---

## VS Code Remote SSH (Recommended)

1. Install "Remote - SSH" extension in VS Code
2. Add to `C:\Users\<YourUsername>\.ssh\config`:
   ```
   Host nifty50-rag-dev
       HostName <VM_IP>
       User dev
       IdentityFile C:\Users\<YourUsername>\.ssh\id_rsa
   ```
3. In VS Code: `F1` → "Remote-SSH: Connect to Host" → `nifty50-rag-dev`
4. Open folder: `~/nifty50-rag`

---

## Quick Commands Reference

```powershell
# Check SSH keys
.\check-ssh-keys.ps1

# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Get VM IP
terraform output vm_external_ip

# Get SSH command
terraform output ssh_command

# SSH into VM
ssh nifty50-rag-dev

# Stop VM (save costs)
gcloud compute instances stop nifty50-rag-dev --zone=asia-south1-a

# Start VM
gcloud compute instances start nifty50-rag-dev --zone=asia-south1-a

# Destroy everything
terraform destroy
```

---

## Next Steps

After SSH'ing into the VM:

1. Wait for startup script to complete (~5 minutes)
2. Verify installations:
   ```bash
   docker --version
   python3 --version
   node --version
   ```
3. Navigate to project: `cd ~/nifty50-rag`
4. Copy your project files or clone from git
5. Start development!

---

For more details, see the main [README.md](README.md)

