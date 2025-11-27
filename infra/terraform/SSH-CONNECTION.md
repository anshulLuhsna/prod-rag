# SSH Connection Guide

There are two ways to connect to your VM:

## Option 1: Direct SSH (Recommended - Faster)

Use your SSH key directly. This is faster and doesn't require IAP.

### Windows PowerShell:

```powershell
# Using environment variable (recommended)
ssh -i "$env:USERPROFILE\.ssh\id_rsa" dev@<VM_IP>

# Or using full path
ssh -i "C:\Users\abhay kalbande\.ssh\id_rsa" dev@<VM_IP>
```

### Linux/Mac:

```bash
ssh -i ~/.ssh/id_rsa dev@<VM_IP>
```

**Get your VM IP:**
```powershell
terraform output vm_external_ip
```

---

## Option 2: Via GCP Console / Identity-Aware Proxy (IAP)

If you want to use the "SSH" button in GCP Console, you need the IAP firewall rule.

### Step 1: Apply the IAP Firewall Rule

The Terraform config now includes an IAP firewall rule. Apply it:

```powershell
terraform apply
```

This adds a firewall rule allowing connections from IAP IP range (35.235.240.0/20).

### Step 2: Connect via GCP Console

1. Go to [GCP Console](https://console.cloud.google.com)
2. Navigate to Compute Engine > VM instances
3. Click "SSH" button next to your VM
4. This will open a browser-based SSH session

---

## Troubleshooting

### "Connection refused" or "Connection via IAP Failed"

**If using IAP (GCP Console):**
- Make sure you ran `terraform apply` after adding the IAP firewall rule
- The firewall rule `allow-ssh-iap-nifty50-rag` should exist
- Check in GCP Console: VPC network > Firewall rules

**If using direct SSH:**
- Verify your IP is allowed: Check firewall rule `allow-ssh-nifty50-rag`
- Your IP might have changed - run `terraform apply` again to update it
- Make sure the VM is running: `gcloud compute instances list`

### "Permission denied (publickey)"

- Verify your SSH key path is correct
- Check the key exists: `Test-Path "$env:USERPROFILE\.ssh\id_rsa"` (Windows)
- Make sure the key was added to the VM during creation
- Try regenerating: Set `use_existing_ssh_key = false` and run `terraform apply`

### "Could not resolve hostname"

- Use the IP address directly, not a hostname
- Get the IP: `terraform output vm_external_ip`

---

## Quick Commands

```powershell
# Get VM IP
terraform output vm_external_ip

# Get SSH command
terraform output ssh_command

# Check if VM is running
gcloud compute instances list --filter="name=nifty50-rag-dev"

# Start VM if stopped
gcloud compute instances start nifty50-rag-dev --zone=asia-south1-a

# Connect via SSH (replace with your actual IP)
ssh -i "$env:USERPROFILE\.ssh\id_rsa" dev@34.93.17.227
```

---

## Recommended: Use SSH Config

Add to `C:\Users\<YourUsername>\.ssh\config` (Windows) or `~/.ssh/config` (Linux/Mac):

```
Host nifty50-rag-dev
    HostName <VM_IP>
    User dev
    IdentityFile C:\Users\<YourUsername>\.ssh\id_rsa
    StrictHostKeyChecking no
    UserKnownHostsFile NUL
```

Then simply:
```powershell
ssh nifty50-rag-dev
```

---

**Note:** Direct SSH (Option 1) is recommended as it's faster and doesn't require IAP setup. Use IAP only if you need browser-based access or don't have SSH keys set up.

