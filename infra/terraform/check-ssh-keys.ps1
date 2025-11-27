# PowerShell script to check for existing SSH keys on Windows
# Run this before setting up Terraform

Write-Host "=========================================="
Write-Host "SSH Key Check for NIFTY 50 RAG MVP"
Write-Host "=========================================="
Write-Host ""

$sshDir = "$env:USERPROFILE\.ssh"
$publicKeyPath = "$sshDir\id_rsa.pub"
$privateKeyPath = "$sshDir\id_rsa"

# Check if .ssh directory exists
if (-not (Test-Path $sshDir)) {
    Write-Host "❌ .ssh directory not found at: $sshDir" -ForegroundColor Red
    Write-Host ""
    Write-Host "You can either:"
    Write-Host "1. Generate SSH keys manually: ssh-keygen -t rsa -b 4096"
    Write-Host "2. Let Terraform generate keys for you (set use_existing_ssh_key = false)"
    Write-Host ""
    exit 1
}

Write-Host "✅ .ssh directory found at: $sshDir" -ForegroundColor Green
Write-Host ""

# Check for public key
if (Test-Path $publicKeyPath) {
    Write-Host "✅ Found SSH public key: $publicKeyPath" -ForegroundColor Green
    
    # Show first line of public key (for verification)
    $keyContent = Get-Content $publicKeyPath -First 1
    Write-Host "   Key preview: $($keyContent.Substring(0, [Math]::Min(50, $keyContent.Length)))..." -ForegroundColor Gray
    Write-Host ""
    
    # Check for private key
    if (Test-Path $privateKeyPath) {
        Write-Host "✅ Found SSH private key: $privateKeyPath" -ForegroundColor Green
        Write-Host ""
        Write-Host "=========================================="
        Write-Host "✅ You can use your existing SSH keys!"
        Write-Host "=========================================="
        Write-Host ""
        Write-Host "Add this to your terraform.tfvars:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "use_existing_ssh_key = true" -ForegroundColor Cyan
        Write-Host "existing_ssh_public_key_path = `"$publicKeyPath`"" -ForegroundColor Cyan
        Write-Host ""
    } else {
        Write-Host "⚠️  Public key found but private key missing!" -ForegroundColor Yellow
        Write-Host "   You may need to regenerate your keys." -ForegroundColor Yellow
        Write-Host ""
    }
} else {
    Write-Host "❌ No SSH public key found at: $publicKeyPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Options:"
    Write-Host "1. Generate SSH keys now:" -ForegroundColor Yellow
    Write-Host "   ssh-keygen -t rsa -b 4096 -f `"$privateKeyPath`"" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "2. Let Terraform generate keys for you:" -ForegroundColor Yellow
    Write-Host "   Set use_existing_ssh_key = false in terraform.tfvars" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "=========================================="

