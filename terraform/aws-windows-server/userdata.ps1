<powershell>
# Windows Server UserData Script
# Configures WinRM for Ansible and sets hostname

# Set execution policy
Set-ExecutionPolicy Unrestricted -Force

# Configure WinRM for Ansible
Write-Host "Configuring WinRM for Ansible..."
Enable-PSRemoting -Force

# Allow Basic authentication
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true

# Allow unencrypted traffic (lab environment only)
Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true

# Set WinRM to start automatically
Set-Service -Name WinRM -StartupType Automatic
Restart-Service -Name WinRM

# Configure firewall for WinRM
New-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 5985 `
    -Action Allow `
    -ErrorAction SilentlyContinue

New-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 5986 `
    -Action Allow `
    -ErrorAction SilentlyContinue

# Set hostname
Rename-Computer -NewName "DC01" -Force -ErrorAction SilentlyContinue

# Log completion
Write-Host "UserData script completed successfully"
Add-Content -Path "C:\userdata-log.txt" -Value "$(Get-Date): UserData script completed"

</powershell>
