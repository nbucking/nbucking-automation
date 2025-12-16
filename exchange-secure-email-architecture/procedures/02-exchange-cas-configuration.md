# Exchange CAS Configuration Procedures

## Overview
This document provides step-by-step procedures for configuring Exchange Server SE Client Access Servers to support secure SMTPS relay and EWS mailbox processing.

---

## Prerequisites

- Exchange Management Shell access with Organization Management role
- AVI Service Engine subnet documented (from AVI configuration)
- Valid SSL certificate installed on Exchange servers
- Exchange Server SE with latest security updates
- Firewall rules implemented (Apps → LB, LB → CAS)

---

## Procedure 1: Create SMTPS Receive Connector

### Purpose
Create a new Receive Connector on Exchange CAS servers to accept secure SMTP relay traffic from applications via the AVI load balancer.

### Steps

#### 1.1 Identify Current Connectors
Open Exchange Management Shell and list existing connectors:

```powershell
Get-ReceiveConnector | Select Name, Bindings, RemoteIPRanges, AuthMechanism, PermissionGroups | Format-List
```

Document the existing Port 25 connector for reference.

#### 1.2 Create New Secure Receive Connector - Port 587

```powershell
# Define variables
$CASServer = $env:COMPUTERNAME
$ConnectorName = "Secure Relay - Port 587"
$AviSubnet = "10.10.50.0/24"  # Replace with your AVI SE subnet from AVI procedure

# Create connector
New-ReceiveConnector `
    -Name $ConnectorName `
    -Server $CASServer `
    -TransportRole FrontendTransport `
    -Bindings "0.0.0.0:587" `
    -RemoteIPRanges $AviSubnet `
    -AuthMechanism Tls `
    -PermissionGroups AnonymousUsers `
    -RequireTLS $true
```

#### 1.3 Configure Connector Settings - Port 587

```powershell
# Get the connector
$Connector = Get-ReceiveConnector "$CASServer\$ConnectorName"

# Configure TLS and security settings
Set-ReceiveConnector $Connector -Identity $Connector.Identity `
    -RequireTLS $true `
    -EnableAuthGSSAPI $false `
    -ExtendedProtectionPolicy Require `
    -TlsDomainCapabilities "contoso.com:AcceptOorgProtocol" `
    -MaxMessageSize 35MB `
    -MessageRateLimit Unlimited `
    -MessageRateSource IPAddress `
    -Banner "220 SMTP Ready" `
    -ChunkingEnabled $true

# Verify configuration
Get-ReceiveConnector $Connector.Identity | Format-List Name, Bindings, RemoteIPRanges, RequireTLS, ExtendedProtectionPolicy, AuthMechanism
```

#### 1.4 Grant Relay Permissions

```powershell
# Grant relay permissions to anonymous users (trust based on AVI SE subnet)
Get-ReceiveConnector "$CASServer\$ConnectorName" | 
    Add-ADPermission -User "NT AUTHORITY\ANONYMOUS LOGON" `
    -ExtendedRights "ms-Exch-SMTP-Submit", "ms-Exch-SMTP-Accept-Any-Recipient", "ms-Exch-Bypass-Anti-Spam"
```

#### 1.5 Create Connector for Port 465 (Implicit TLS) - Optional

```powershell
# Create connector for port 465
New-ReceiveConnector `
    -Name "Secure Relay - Port 465" `
    -Server $CASServer `
    -TransportRole FrontendTransport `
    -Bindings "0.0.0.0:465" `
    -RemoteIPRanges $AviSubnet `
    -AuthMechanism Tls `
    -PermissionGroups AnonymousUsers `
    -RequireTLS $true

# Configure settings
$Connector465 = Get-ReceiveConnector "$CASServer\Secure Relay - Port 465"
Set-ReceiveConnector $Connector465 -Identity $Connector465.Identity `
    -RequireTLS $true `
    -EnableAuthGSSAPI $false `
    -ExtendedProtectionPolicy Require `
    -MaxMessageSize 35MB `
    -MessageRateLimit Unlimited `
    -MessageRateSource IPAddress `
    -Banner "220 SMTP Ready" `
    -ChunkingEnabled $true

# Grant relay permissions
Get-ReceiveConnector "$CASServer\Secure Relay - Port 465" | 
    Add-ADPermission -User "NT AUTHORITY\ANONYMOUS LOGON" `
    -ExtendedRights "ms-Exch-SMTP-Submit", "ms-Exch-SMTP-Accept-Any-Recipient", "ms-Exch-Bypass-Anti-Spam"
```

#### 1.6 Repeat for All CAS Servers

If you have multiple CAS servers, repeat the above steps on each server, or use a script:

```powershell
$CASServers = @("EXCH-CAS01", "EXCH-CAS02", "EXCH-CAS03")
$AviSubnet = "10.10.50.0/24"

foreach ($Server in $CASServers) {
    Write-Host "Configuring $Server..." -ForegroundColor Green
    
    # Create Port 587 connector
    New-ReceiveConnector `
        -Name "Secure Relay - Port 587" `
        -Server $Server `
        -TransportRole FrontendTransport `
        -Bindings "0.0.0.0:587" `
        -RemoteIPRanges $AviSubnet `
        -AuthMechanism Tls `
        -PermissionGroups AnonymousUsers `
        -RequireTLS $true
    
    # Configure settings
    $Connector = Get-ReceiveConnector "$Server\Secure Relay - Port 587"
    Set-ReceiveConnector $Connector -Identity $Connector.Identity `
        -RequireTLS $true `
        -ExtendedProtectionPolicy Require `
        -MaxMessageSize 35MB
    
    # Grant permissions
    Get-ReceiveConnector "$Server\Secure Relay - Port 587" | 
        Add-ADPermission -User "NT AUTHORITY\ANONYMOUS LOGON" `
        -ExtendedRights "ms-Exch-SMTP-Submit", "ms-Exch-SMTP-Accept-Any-Recipient"
}
```

#### 1.7 Verification

```powershell
# Verify all connectors are created
Get-ReceiveConnector | Where-Object {$_.Name -like "*Secure Relay*"} | 
    Select Name, Server, Bindings, RemoteIPRanges, RequireTLS | Format-Table

# Test connectivity from AVI subnet
Test-NetConnection -ComputerName <CAS-Server> -Port 587
Test-NetConnection -ComputerName <CAS-Server> -Port 465

# Check Exchange logs for errors
Get-EventLog -LogName Application -Source "MSExchange*" -Newest 50 | 
    Where-Object {$_.EntryType -eq "Error"}
```

---

## Procedure 2: Configure EWS Virtual Directory

### Purpose
Configure EWS virtual directory settings to support secure mailbox processing via EWS API with Modern Authentication and Extended Protection.

### Steps

#### 2.1 Review Current EWS Configuration

```powershell
# Get current EWS virtual directory settings
Get-WebServicesVirtualDirectory | 
    Select Server, InternalUrl, ExternalUrl, BasicAuthentication, WindowsAuthentication, OAuthAuthentication, ExtendedProtectionTokenCheck | 
    Format-List
```

#### 2.2 Configure EWS for Modern Authentication

```powershell
$CASServers = @("EXCH-CAS01", "EXCH-CAS02", "EXCH-CAS03")
$ExternalURL = "https://mail.contoso.com"  # Replace with your load balancer VIP URL

foreach ($Server in $CASServers) {
    Write-Host "Configuring EWS on $Server..." -ForegroundColor Green
    
    # Get the EWS virtual directory
    $EWS = Get-WebServicesVirtualDirectory -Server $Server
    
    # Configure settings
    Set-WebServicesVirtualDirectory -Identity $EWS.Identity `
        -InternalUrl "$ExternalURL/ews/Exchange.asmx" `
        -ExternalUrl "$ExternalURL/ews/Exchange.asmx" `
        -BasicAuthentication $false `
        -WindowsAuthentication $true `
        -OAuthAuthentication $true `
        -ExtendedProtectionTokenCheck Require `
        -ExtendedProtectionFlags None `
        -ExtendedProtectionSPNList @()
}
```

#### 2.3 Configure Extended Protection for EWS

```powershell
# Set Extended Protection policy
foreach ($Server in $CASServers) {
    $EWS = Get-WebServicesVirtualDirectory -Server $Server
    
    Set-WebServicesVirtualDirectory -Identity $EWS.Identity `
        -ExtendedProtectionTokenCheck Require `
        -ExtendedProtectionFlags None
}
```

#### 2.4 Enable OAuth 2.0 (Modern Auth)

```powershell
# Verify OAuth is enabled organization-wide
Get-OrganizationConfig | Select OAuth*

# Enable OAuth if not already enabled
Set-OrganizationConfig -OAuth2ClientProfileEnabled $true

# Verify per virtual directory
Get-WebServicesVirtualDirectory | Select Server, OAuthAuthentication
```

#### 2.5 Create Service Account for EWS Applications

```powershell
# Create mailbox for EWS processing (if not exists)
New-Mailbox -UserPrincipalName ewsprocessing@contoso.com `
    -Alias ewsprocessing `
    -Name "EWS Processing Service Account" `
    -Password (ConvertTo-SecureString -String "ComplexP@ssw0rd!" -AsPlainText -Force) `
    -ResetPasswordOnNextLogon $false

# Assign Full Access to the mailbox if apps need to access other mailboxes
Add-MailboxPermission -Identity "target-mailbox@contoso.com" `
    -User ewsprocessing@contoso.com `
    -AccessRights FullAccess `
    -InheritanceType All

# Prevent mailbox from appearing in GAL
Set-Mailbox -Identity ewsprocessing@contoso.com -HiddenFromAddressListsEnabled $true
```

#### 2.6 Configure Application Impersonation (if needed)

```powershell
# Create RBAC role for impersonation
New-ManagementRoleAssignment -Name "EWS-Application-Impersonation" `
    -Role ApplicationImpersonation `
    -User ewsprocessing@contoso.com

# Verify assignment
Get-ManagementRoleAssignment -Role ApplicationImpersonation | 
    Where-Object {$_.User -like "*ewsprocessing*"}
```

#### 2.7 Configure Throttling Policy (Optional)

```powershell
# Create throttling policy for EWS service accounts
New-ThrottlingPolicy -Name "EWS-Processing-Policy" `
    -EWSMaxConcurrency 50 `
    -EWSPercentTimeInAD 50 `
    -EWSPercentTimeInCAS 50 `
    -EWSPercentTimeInMailboxRPC 50 `
    -EWSMaxSubscriptions 200

# Assign to service account
Set-Mailbox -Identity ewsprocessing@contoso.com `
    -ThrottlingPolicy "EWS-Processing-Policy"

# Verify
Get-Mailbox ewsprocessing@contoso.com | Select ThrottlingPolicy
```

#### 2.8 Verification

```powershell
# Verify EWS virtual directory configuration
Get-WebServicesVirtualDirectory | 
    Select Server, InternalUrl, ExternalUrl, OAuthAuthentication, ExtendedProtectionTokenCheck | 
    Format-Table

# Test EWS connectivity
Test-WebServicesConnectivity -ClientAccessServer EXCH-CAS01 -Verbose

# Test EWS from PowerShell
$ews = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService
$ews.Url = "https://mail.contoso.com/ews/Exchange.asmx"
$ews.Credentials = New-Object System.Net.NetworkCredential("ewsprocessing@contoso.com", "password")
$ews.FindFolders([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Inbox, `
    (New-Object Microsoft.Exchange.WebServices.Data.FolderView(10)))

# Check IIS logs
Get-Content "C:\inetpub\logs\LogFiles\W3SVC1\*.log" -Tail 50 | 
    Where-Object {$_ -like "*ews*"}

# Check Extended Protection
Get-WebServicesVirtualDirectory | Select Server, ExtendedProtectionTokenCheck

# Test certificate
Get-ExchangeCertificate | Where-Object {$_.Services -like "*IIS*"}
```

---

## Procedure 3: Monitor Port 25 Usage (Phase 1 - Coexistence)

### Purpose
During the coexistence phase, monitor Port 25 usage to track migration progress. Since Port 25 already only allows load balancer IPs, no restriction is needed.

### Steps

#### 3.1 Document Current Port 25 Configuration

```powershell
$LegacyConnector = Get-ReceiveConnector | 
    Where-Object {$_.Bindings -like "*:25"} | 
    Select -First 1

# Document current settings
$LegacyConnector | Select Name, Bindings, RemoteIPRanges, PermissionGroups | Format-List

# Backup current settings
$LegacyConnector | Export-Clixml -Path "C:\Temp\LegacyConnector-Backup.xml"
```

#### 3.2 Monitor Port 25 Traffic

```powershell
# Check message tracking for Port 25 usage over the last 7 days
Get-MessageTrackingLog -Start (Get-Date).AddDays(-7) -ResultSize Unlimited | 
    Where-Object {$_.Source -eq "SMTP" -and $_.ConnectorId -like "*$($LegacyConnector.Name)*"} | 
    Group-Object -Property ClientHostname | 
    Select Count, Name | 
    Sort Count -Descending | 
    Export-Csv "C:\Temp\Port25-Usage.csv" -NoTypeInformation

Write-Host "Port 25 traffic logged to C:\Temp\Port25-Usage.csv" -ForegroundColor Green

# Display summary
Import-Csv "C:\Temp\Port25-Usage.csv" | Format-Table -AutoSize
```

#### 3.3 Set Up Weekly Monitoring

Create a scheduled task to run the monitoring script weekly:

```powershell
# Create monitoring script
$ScriptPath = "C:\Scripts\Monitor-Port25.ps1"
$ScriptContent = @'
$LegacyConnector = Get-ReceiveConnector | Where-Object {$_.Bindings -like "*:25"} | Select -First 1
Get-MessageTrackingLog -Start (Get-Date).AddDays(-7) -ResultSize Unlimited | 
    Where-Object {$_.Source -eq "SMTP" -and $_.ConnectorId -like "*$($LegacyConnector.Name)*"} | 
    Group-Object -Property ClientHostname | 
    Select Count, Name | 
    Sort Count -Descending | 
    Export-Csv "C:\Temp\Port25-Usage-$(Get-Date -Format 'yyyy-MM-dd').csv" -NoTypeInformation
'@

New-Item -Path $ScriptPath -ItemType File -Value $ScriptContent -Force

# Create scheduled task
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File $ScriptPath"
$Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 8am
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
Register-ScheduledTask -TaskName "Monitor-Port25-Usage" -Action $Action -Trigger $Trigger -Principal $Principal
```

---

## Procedure 4: Configure Send Connector (Optional)

### Purpose
If applications need to send external email through Exchange, configure a Send Connector.

### Steps

#### 4.1 Create Send Connector

```powershell
$CASServers = @("EXCH-CAS01", "EXCH-CAS02", "EXCH-CAS03")

New-SendConnector -Name "Internet Send Connector" `
    -Usage Internet `
    -AddressSpaces "*" `
    -IsScopedConnector $false `
    -DNSRoutingEnabled $true `
    -UseExternalDNSServersEnabled $false `
    -SourceTransportServers $CASServers `
    -MaxMessageSize 35MB
```

#### 4.2 Configure TLS Settings

```powershell
Get-SendConnector "Internet Send Connector" | 
    Set-SendConnector -RequireTLS $true -TlsAuthLevel DomainValidation
```

---

## Procedure 5: Disable Port 25 Connector (Phase 3 - Decommission)

### Purpose
After all applications are migrated and validated, disable the legacy Port 25 connector.

### Prerequisites
- All applications migrated to SMTPS or EWS
- 30+ days of monitoring showing zero Port 25 traffic
- Change approval obtained

### Steps

#### 5.1 Final Verification

```powershell
# Check recent Port 25 activity
$LogPath = "C:\Program Files\Microsoft\Exchange Server\V15\TransportRoles\Logs\MessageTracking"
$RecentActivity = Get-ChildItem $LogPath -Recurse | 
    Where-Object {$_.LastWriteTime -gt (Get-Date).AddDays(-30)} | 
    Select-String ":25 "

if ($RecentActivity.Count -gt 0) {
    Write-Warning "Port 25 activity detected in last 30 days. Review before proceeding."
    $RecentActivity | Select -First 10
} else {
    Write-Host "No Port 25 activity in last 30 days. Safe to proceed." -ForegroundColor Green
}
```

#### 5.2 Disable Connector

```powershell
# Disable (but don't delete) the connector
$LegacyConnector = Get-ReceiveConnector | Where-Object {$_.Bindings -like "*:25"}
Set-ReceiveConnector -Identity $LegacyConnector.Identity -Enabled $false

# Verify
Get-ReceiveConnector -Identity $LegacyConnector.Identity | Select Name, Enabled
```

#### 5.3 Monitor for Issues

Monitor for 7 days after disabling. Check:
- Application logs
- Service desk tickets
- User complaints

#### 5.4 Remove Connector (Optional - After Extended Validation)

```powershell
# Only after 30+ days of stable operation
Remove-ReceiveConnector -Identity $LegacyConnector.Identity -Confirm:$false
```

---

## Troubleshooting

### SMTPS Connector Issues

```powershell
# Check connector status
Get-ReceiveConnector | Where-Object {$_.Name -like "*Secure Relay*"} | Test-ReceiveConnector

# Check SMTP logs
Get-TransportService | Get-MessageTrackingLog -ResultSize 100 -Start (Get-Date).AddHours(-1)

# Test TLS
Test-ServiceHealth -Service SMTP

# Check certificate
Get-ExchangeCertificate | Where-Object {$_.Services -like "*SMTP*"} | Format-List
```

### EWS Issues

```powershell
# Test EWS connectivity
Test-WebServicesConnectivity -ClientAccessServer $env:COMPUTERNAME

# Check IIS logs
Get-Content "C:\inetpub\logs\LogFiles\W3SVC1\*.log" -Tail 50 | 
    Where-Object {$_ -like "*ews*"}

# Check Extended Protection
Get-WebServicesVirtualDirectory | Select Server, ExtendedProtectionTokenCheck

# Test certificate
Get-ExchangeCertificate | Where-Object {$_.Services -like "*IIS*"}
```

---

## Rollback Procedures

### SMTPS Connector

```powershell
# Remove secure connectors
$ConnectorsToRemove = Get-ReceiveConnector | Where-Object {$_.Name -like "*Secure Relay*"}
$ConnectorsToRemove | Remove-ReceiveConnector -Confirm:$false

# Restore legacy connector from backup
$Backup = Import-Clixml -Path "C:\Temp\LegacyConnector-Backup.xml"
Set-ReceiveConnector -Identity $Backup.Identity -RemoteIPRanges $Backup.RemoteIPRanges
```

### EWS Configuration

```powershell
# Restore previous EWS settings
Set-WebServicesVirtualDirectory -Identity "EXCH-CAS01\EWS (Default Web Site)" `
    -BasicAuthentication $true `
    -ExtendedProtectionTokenCheck None
```

---

## Validation Scripts

### Comprehensive Health Check

Save as `Test-SecureEmailConfiguration.ps1`:

```powershell
function Test-SecureEmailConfiguration {
    Write-Host "=== Exchange Secure Email Configuration Health Check ===" -ForegroundColor Cyan
    
    # Check SMTPS Connectors
    Write-Host "`nSMTPS Receive Connectors:" -ForegroundColor Yellow
    Get-ReceiveConnector | Where-Object {$_.Bindings -like "*:587" -or $_.Bindings -like "*:465"} | 
        Select Server, Name, Bindings, RequireTLS, ExtendedProtectionPolicy | Format-Table
    
    # Check EWS Virtual Directories
    Write-Host "`nEWS Virtual Directories:" -ForegroundColor Yellow
    Get-WebServicesVirtualDirectory | 
        Select Server, InternalUrl, OAuthAuthentication, ExtendedProtectionTokenCheck | Format-Table
    
    # Check Certificates
    Write-Host "`nSSL Certificates:" -ForegroundColor Yellow
    Get-ExchangeCertificate | Where-Object {$_.Services -ne "None"} | 
        Select Subject, Services, NotAfter, IsSelfSigned | Format-Table
    
    # Check Service Health
    Write-Host "`nService Health:" -ForegroundColor Yellow
    Test-ServiceHealth | Where-Object {$_.Role -like "*ClientAccess*"} | Format-Table
    
    Write-Host "`n=== Health Check Complete ===" -ForegroundColor Cyan
}

# Run the health check
Test-SecureEmailConfiguration
```

---

## Notes

- All PowerShell commands should be run in Exchange Management Shell
- Test all changes in non-production environment first
- Document all changes in change management system
- Schedule changes during maintenance windows
- Keep backups of all configuration before making changes
