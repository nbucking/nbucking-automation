<#
.SYNOPSIS
    Configures WinRM on Windows Server for Ansible connectivity.

.DESCRIPTION
    This script enables and configures WinRM to allow Ansible to connect to the Windows Server.
    Should be run on the Windows Server 2019 VM after initial installation.

.NOTES
    Run this on the Windows Server as Administrator.
#>

# Enable WinRM
Write-Host "Enabling WinRM..." -ForegroundColor Cyan
Enable-PSRemoting -Force

# Configure WinRM service
Write-Host "Configuring WinRM service..." -ForegroundColor Cyan
Set-Service -Name WinRM -StartupType Automatic
Start-Service -Name WinRM

# Allow Basic authentication (for Ansible)
Write-Host "Enabling Basic authentication..." -ForegroundColor Cyan
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true

# Allow unencrypted traffic (for testing/lab environments only)
Write-Host "Allowing unencrypted traffic (lab use only)..." -ForegroundColor Yellow
Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true

# Configure firewall rule
Write-Host "Configuring firewall..." -ForegroundColor Cyan
New-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 5985 `
    -Action Allow `
    -ErrorAction SilentlyContinue

# Test WinRM
Write-Host "`nTesting WinRM configuration..." -ForegroundColor Cyan
Test-WSMan -ComputerName localhost

# Display configuration
Write-Host "`nCurrent WinRM configuration:" -ForegroundColor Green
winrm get winrm/config

Write-Host "`nWinRM is now configured for Ansible!" -ForegroundColor Green
Write-Host "You can now run Ansible playbooks against this server." -ForegroundColor Green
