# PowerShell script to update SSH firewall rule with current IP
# Run this if your IP has changed and direct SSH is timing out

Write-Host "Updating SSH firewall rule with your current IP..." -ForegroundColor Yellow
Write-Host ""

# Get current IP
$currentIP = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content
Write-Host "Your current IP: $currentIP" -ForegroundColor Green
Write-Host ""

# Run terraform apply to update the firewall rule
Write-Host "Running terraform apply to update firewall rule..." -ForegroundColor Yellow
terraform apply -auto-approve

Write-Host ""
Write-Host "✅ Firewall rule updated! You can now SSH directly." -ForegroundColor Green
Write-Host ""
Write-Host "Try connecting:"
Write-Host "ssh -i `"`$env:USERPROFILE\.ssh\id_rsa`" dev@<VM_IP>" -ForegroundColor Cyan

