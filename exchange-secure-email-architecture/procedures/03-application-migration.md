# Application Migration Procedures

## Overview
This document provides step-by-step procedures for migrating applications from legacy plaintext SMTP (Port 25) to secure protocols (SMTPS or EWS).

---

## Pre-Migration Assessment

### Application Discovery and Classification

#### Steps

**1. Inventory All Applications**

Create a spreadsheet with:
- Application name
- Server/hostname
- Current email method (SMTP Port 25, etc.)
- Email purpose (notifications, mailbox processing, etc.)
- Business owner
- Technical contact
- Criticality (High/Medium/Low)

**2. Network Traffic Analysis**

```bash
# On Linux systems, capture SMTP traffic
tcpdump -i any 'port 25' -w smtp-traffic.pcap -c 10000

# Analyze source IPs
tcpdump -r smtp-traffic.pcap -n | awk '{print $3}' | sort -u
```

**3. Exchange Log Analysis**

```powershell
# Run on Exchange server to identify Port 25 senders
$StartDate = (Get-Date).AddDays(-30)
Get-MessageTrackingLog -Start $StartDate -ResultSize Unlimited | 
    Where-Object {$_.ClientHostname -notlike "*exchange*"} | 
    Group-Object -Property ClientHostname | 
    Select Count, Name | 
    Sort Count -Descending | 
    Export-Csv "C:\Temp\SMTP-Senders.csv" -NoTypeInformation
```

**4. Classify Applications**

- **Type A - Simple Relay**: Send-only notifications
  - **Migration Path**: SMTPS (Port 587)
- **Type B - Mailbox Processing**: Read/move/delete emails
  - **Migration Path**: EWS (HTTPS)
- **Type C - Legacy**: Cannot be updated
  - **Migration Path**: Keep on restricted Port 25 or external relay

---

## Migration Path 1: SMTPS Relay (Port 587)

### Use Case
Applications that only need to **send** email notifications/alerts (no mailbox access needed).

### Prerequisites
- Application supports TLS 1.2+
- Application can be configured with SMTP port (587)
- Application supports STARTTLS or explicit TLS
- Network access from application to AVI VIP on port 587
- Firewall rules implemented

### Procedure: Migrate to SMTPS Port 587

#### Step 1: Test Connectivity

```bash
# From application server, test SMTP connectivity
openssl s_client -connect <AVI-VIP>:587 -starttls smtp

# Expected output should show:
# - Connected
# - Certificate chain
# - "250 OK" or similar SMTP greeting
```

#### Step 2: Configure Application Settings

**Example 1: Linux Applications (Postfix/sendmail)**

```bash
# Edit /etc/postfix/main.cf
relayhost = [<AVI-VIP>]:587
smtp_tls_security_level = encrypt
smtp_tls_wrappermode = no
smtp_use_tls = yes
smtp_tls_CAfile = /etc/ssl/certs/ca-bundle.crt

# Restart Postfix
systemctl restart postfix

# Test
echo "Test email" | mail -s "Test Subject" user@example.com
```

**Example 2: Windows Applications (.NET System.Net.Mail)**

```csharp
using System.Net.Mail;
using System.Net;

SmtpClient client = new SmtpClient("<AVI-VIP>", 587);
client.EnableSsl = true;  // Enable STARTTLS
client.DeliveryMethod = SmtpDeliveryMethod.Network;
client.UseDefaultCredentials = false;
client.Credentials = null;  // Anonymous relay via IP trust

MailMessage message = new MailMessage(
    "sender@contoso.com",
    "recipient@example.com",
    "Test Subject",
    "Test Body"
);

client.Send(message);
```

**Example 3: Python Applications**

```python
import smtplib
from email.mime.text import MIMEText

smtp_server = "<AVI-VIP>"
smtp_port = 587

msg = MIMEText("Test email body")
msg['Subject'] = "Test Subject"
msg['From'] = "sender@contoso.com"
msg['To'] = "recipient@example.com"

with smtplib.SMTP(smtp_server, smtp_port) as server:
    server.starttls()  # Upgrade to TLS
    server.send_message(msg)
```

**Example 4: PowerShell Scripts**

```powershell
$SMTPServer = "<AVI-VIP>"
$SMTPPort = 587

Send-MailMessage -From "sender@contoso.com" `
    -To "recipient@example.com" `
    -Subject "Test Subject" `
    -Body "Test Body" `
    -SmtpServer $SMTPServer `
    -Port $SMTPPort `
    -UseSsl
```

**Example 5: Java Applications**

```java
import javax.mail.*;
import javax.mail.internet.*;
import java.util.Properties;

Properties props = new Properties();
props.put("mail.smtp.host", "<AVI-VIP>");
props.put("mail.smtp.port", "587");
props.put("mail.smtp.starttls.enable", "true");
props.put("mail.smtp.auth", "false");

Session session = Session.getInstance(props);

MimeMessage message = new MimeMessage(session);
message.setFrom(new InternetAddress("sender@contoso.com"));
message.addRecipient(Message.RecipientType.TO, new InternetAddress("recipient@example.com"));
message.setSubject("Test Subject");
message.setText("Test Body");

Transport.send(message);
```

#### Step 3: Verify Application Configuration

Check application logs for successful send and verify in Exchange message tracking:

```powershell
# On Exchange server
Get-MessageTrackingLog -ResultSize 100 -Start (Get-Date).AddHours(-1) | 
    Where-Object {$_.ClientHostname -eq "<application-server>"} | 
    Select Timestamp, Sender, Recipients, MessageSubject, Source
```

#### Step 4: Monitor for 48 Hours
- Check application logs for errors
- Verify emails are being delivered
- Monitor Exchange SMTP logs
- Check for any TLS negotiation failures

#### Step 5: Document and Close
- Update application inventory spreadsheet
- Mark application as migrated
- Remove from Port 25 allowed list

---

## Migration Path 2: EWS Mailbox Processing

### Use Case
Applications that need to **read, move, delete, or process** emails from a mailbox.

### Prerequisites
- Application can be updated to use REST API or EWS library
- Application supports TLS 1.2+ and HTTPS
- Dedicated mailbox created for application
- Service account with appropriate permissions
- Network access from application to AVI VIP on port 443
- Firewall rules implemented (Apps → LB VIP and Apps → CAS direct)

### Procedure: Migrate to EWS

#### Step 1: Prepare Exchange Environment

**Create Dedicated Mailbox (if not exists)**

```powershell
# Run on Exchange server
New-Mailbox -UserPrincipalName app-processing@contoso.com `
    -Alias app-processing `
    -Name "Application Processing Mailbox" `
    -Password (ConvertTo-SecureString -String "ComplexP@ssw0rd!" -AsPlainText -Force) `
    -ResetPasswordOnNextLogon $false

# Hide from GAL
Set-Mailbox -Identity app-processing@contoso.com -HiddenFromAddressListsEnabled $true

# Grant ApplicationImpersonation if needed
New-ManagementRoleAssignment -Name "App-EWS-Impersonation" `
    -Role ApplicationImpersonation `
    -User app-processing@contoso.com
```

#### Step 2: Test EWS Connectivity

**PowerShell Test**

```powershell
# Test EWS endpoint
$url = "https://<AVI-VIP>/ews/Exchange.asmx"
$credential = New-Object System.Net.NetworkCredential("app-processing@contoso.com", "password")

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

$service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService
$service.Url = $url
$service.Credentials = $credential

# Test by getting inbox folder
$inbox = [Microsoft.Exchange.WebServices.Data.Folder]::Bind(
    $service, 
    [Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Inbox
)

Write-Host "Connected successfully. Inbox has $($inbox.TotalCount) items." -ForegroundColor Green
```

#### Step 3: Update Application Code

**Example 1: PowerShell Script - Move Emails**

```powershell
# Load EWS Managed API (install Microsoft.Exchange.WebServices NuGet package)
Add-Type -Path "C:\Program Files\Microsoft\Exchange\Web Services\2.2\Microsoft.Exchange.WebServices.dll"

$service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService
$service.Url = "https://<AVI-VIP>/ews/Exchange.asmx"
$service.Credentials = New-Object System.Net.NetworkCredential("app-processing@contoso.com", "password")

# Get Inbox
$inbox = [Microsoft.Exchange.WebServices.Data.Folder]::Bind(
    $service, 
    [Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Inbox
)

# Get target folder (create if not exists)
$folderView = New-Object Microsoft.Exchange.WebServices.Data.FolderView(10)
$folderView.Traversal = [Microsoft.Exchange.WebServices.Data.FolderTraversal]::Deep
$searchFilter = New-Object Microsoft.Exchange.WebServices.Data.SearchFilter+IsEqualTo(
    [Microsoft.Exchange.WebServices.Data.FolderSchema]::DisplayName, 
    "Processed"
)
$findResults = $service.FindFolders([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Inbox, $searchFilter, $folderView)

if ($findResults.TotalCount -eq 0) {
    # Create folder
    $processedFolder = New-Object Microsoft.Exchange.WebServices.Data.Folder($service)
    $processedFolder.DisplayName = "Processed"
    $processedFolder.Save($inbox.Id)
    $targetFolderId = $processedFolder.Id
} else {
    $targetFolderId = $findResults.Folders[0].Id
}

# Find and move items
$itemView = New-Object Microsoft.Exchange.WebServices.Data.ItemView(100)
$findResults = $service.FindItems([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Inbox, $itemView)

foreach ($item in $findResults.Items) {
    # Process item (your business logic here)
    Write-Host "Processing: $($item.Subject)"
    
    # Move to Processed folder
    $item.Move($targetFolderId) | Out-Null
}

Write-Host "Processed $($findResults.TotalCount) items." -ForegroundColor Green
```

**Example 2: C# Application**

```csharp
using Microsoft.Exchange.WebServices.Data;
using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;

class Program
{
    static void Main()
    {
        // Allow self-signed certificates (remove in production)
        ServicePointManager.ServerCertificateValidationCallback = 
            (sender, certificate, chain, sslPolicyErrors) => true;

        // Initialize EWS service
        ExchangeService service = new ExchangeService();
        service.Url = new Uri("https://<AVI-VIP>/ews/Exchange.asmx");
        service.Credentials = new NetworkCredential("app-processing@contoso.com", "password");

        // Bind to Inbox
        Folder inbox = Folder.Bind(service, WellKnownFolderName.Inbox);
        
        // Find items
        ItemView view = new ItemView(100);
        FindItemsResults<Item> findResults = service.FindItems(WellKnownFolderName.Inbox, view);

        // Find or create target folder
        FolderView folderView = new FolderView(10);
        SearchFilter filter = new SearchFilter.IsEqualTo(FolderSchema.DisplayName, "Processed");
        FindFoldersResults folders = service.FindFolders(WellKnownFolderName.Inbox, filter, folderView);
        
        FolderId targetFolderId;
        if (folders.TotalCount == 0)
        {
            Folder processedFolder = new Folder(service);
            processedFolder.DisplayName = "Processed";
            processedFolder.Save(inbox.Id);
            targetFolderId = processedFolder.Id;
        }
        else
        {
            targetFolderId = folders.Folders[0].Id;
        }

        // Process each item
        foreach (Item item in findResults.Items)
        {
            EmailMessage email = EmailMessage.Bind(service, item.Id);
            
            // Your business logic here
            Console.WriteLine($"Processing: {email.Subject}");
            
            // Move to Processed folder
            email.Move(targetFolderId);
        }

        Console.WriteLine($"Processed {findResults.TotalCount} items.");
    }
}
```

**Example 3: Python Application (using exchangelib)**

```python
from exchangelib import Credentials, Account, Configuration, FolderCollection
from exchangelib.protocol import BaseProtocol, NoVerifyHTTPAdapter
import urllib3

# Disable SSL warnings for self-signed certs (remove in production)
urllib3.disable_warnings()
BaseProtocol.HTTP_ADAPTER_CLS = NoVerifyHTTPAdapter

# Configure credentials
credentials = Credentials(username='app-processing@contoso.com', password='password')
config = Configuration(server='<AVI-VIP>', credentials=credentials)

# Connect to account
account = Account(
    primary_smtp_address='app-processing@contoso.com',
    config=config,
    autodiscover=False,
    access_type=DELEGATE
)

# Get or create Processed folder
try:
    processed_folder = account.inbox / 'Processed'
except:
    processed_folder = account.inbox.add_child_folder('Processed')

# Process inbox items
for item in account.inbox.all():
    print(f"Processing: {item.subject}")
    
    # Your business logic here
    
    # Move to Processed folder
    item.move(to_folder=processed_folder)

print(f"Processing complete.")
```

#### Step 4: Test Application
1. Send test email to application mailbox
2. Run application to process email
3. Verify email moved to correct folder
4. Check application logs for errors
5. Check Exchange logs

```powershell
# Check EWS logs on Exchange server
Get-Content "C:\Program Files\Microsoft\Exchange Server\V15\Logging\EWS\*.log" | 
    Select-String "app-processing@contoso.com" | 
    Select -Last 20
```

#### Step 5: Schedule Application

**Linux cron example:**
```bash
# Run every 5 minutes
*/5 * * * * /usr/local/bin/process-emails.py >> /var/log/email-processor.log 2>&1
```

**Windows Task Scheduler:**
```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Scripts\Process-Emails.ps1"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)
Register-ScheduledTask -TaskName "Email Processor" -Action $action -Trigger $trigger
```

#### Step 6: Monitor for 48 Hours
- Check application execution logs
- Verify emails are being processed correctly
- Monitor Exchange EWS logs
- Check for authentication failures
- Verify folder operations working

#### Step 7: Document and Close
- Update application inventory
- Document service account credentials in password vault
- Mark application as migrated

---

## Migration Path 3: Port 465 (Implicit TLS)

### Use Case
Legacy applications that support SSL/TLS but only with implicit TLS (port 465), not STARTTLS.

### Prerequisites
- Application supports SMTPS on port 465
- Application supports TLS 1.2+
- Network access to AVI VIP on port 465

### Procedure

#### Step 1: Test Connectivity

```bash
openssl s_client -connect <AVI-VIP>:465
```

#### Step 2: Configure Application

Similar to Port 587, but:
- Use port **465**
- Enable **Implicit SSL/TLS** (not STARTTLS)
- Connection is encrypted from the start

**Example: .NET Configuration**

```csharp
SmtpClient client = new SmtpClient("<AVI-VIP>", 465);
client.EnableSsl = true;  // Implicit TLS
client.DeliveryMethod = SmtpDeliveryMethod.Network;
```

**Example: Python Configuration**

```python
import smtplib
from email.mime.text import MIMEText
import ssl

context = ssl.create_default_context()

msg = MIMEText("Test body")
msg['Subject'] = "Test"
msg['From'] = "sender@contoso.com"
msg['To'] = "recipient@example.com"

with smtplib.SMTP_SSL("<AVI-VIP>", 465, context=context) as server:
    server.send_message(msg)
```

#### Step 3-7: Follow same verification steps as Port 587 migration

---

## Migration Path 4: Legacy Applications (Cannot Be Updated)

### Use Case
Applications that cannot be updated to support TLS or modern protocols.

### Options

#### Option A: Keep on Restricted Port 25
1. Add application IP to Exchange Receive Connector remote IP ranges
2. Document as exception
3. Plan for eventual replacement

```powershell
# Add IP to Port 25 connector
$Connector = Get-ReceiveConnector | Where-Object {$_.Bindings -like "*:25"}
$CurrentIPs = $Connector.RemoteIPRanges
$NewIP = "192.168.1.100"
Set-ReceiveConnector -Identity $Connector.Identity -RemoteIPRanges ($CurrentIPs + $NewIP)
```

#### Option B: Use External SMTP Relay
1. Configure third-party SMTP relay service (SendGrid, Amazon SES, etc.)
2. Point application to external relay
3. Removes burden from Exchange

#### Option C: Replace Application
1. Identify modern alternative
2. Plan replacement project
3. Migrate users to new application

---

## Post-Migration Validation

### Validation Checklist Script

Save as `Validate-ApplicationMigration.ps1`:

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$ApplicationName,
    
    [Parameter(Mandatory=$true)]
    [string]$ServerName,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("SMTPS-587","SMTPS-465","EWS")]
    [string]$MigrationPath
)

Write-Host "=== Post-Migration Validation: $ApplicationName ===" -ForegroundColor Cyan

# Check recent message tracking
Write-Host "`nChecking Exchange message tracking..." -ForegroundColor Yellow
$Messages = Get-MessageTrackingLog -Start (Get-Date).AddHours(-24) -ResultSize 1000 | 
    Where-Object {$_.ClientHostname -like "*$ServerName*"}

if ($Messages) {
    Write-Host "✓ Found $($Messages.Count) messages from $ServerName" -ForegroundColor Green
    $Messages | Select Timestamp, Sender, Recipients, MessageSubject | Format-Table
} else {
    Write-Warning "✗ No messages found from $ServerName in last 24 hours"
}

# Check for errors
Write-Host "`nChecking for SMTP errors..." -ForegroundColor Yellow
$Errors = Get-EventLog -LogName Application -Source "MSExchange*" -After (Get-Date).AddHours(-24) |
    Where-Object {$_.EntryType -eq "Error" -and $_.Message -like "*$ServerName*"}

if ($Errors) {
    Write-Warning "✗ Found $($Errors.Count) errors"
    $Errors | Format-List TimeGenerated, Message
} else {
    Write-Host "✓ No errors found" -ForegroundColor Green
}

# Protocol-specific checks
switch ($MigrationPath) {
    "SMTPS-587" {
        Write-Host "`nVerifying SMTPS Port 587 configuration..." -ForegroundColor Yellow
        $Connector = Get-ReceiveConnector | Where-Object {$_.Bindings -like "*:587"}
        Write-Host "✓ Connector: $($Connector.Name)" -ForegroundColor Green
        Write-Host "✓ TLS Required: $($Connector.RequireTLS)" -ForegroundColor Green
    }
    "SMTPS-465" {
        Write-Host "`nVerifying SMTPS Port 465 configuration..." -ForegroundColor Yellow
        $Connector = Get-ReceiveConnector | Where-Object {$_.Bindings -like "*:465"}
        Write-Host "✓ Connector: $($Connector.Name)" -ForegroundColor Green
        Write-Host "✓ TLS Required: $($Connector.RequireTLS)" -ForegroundColor Green
    }
    "EWS" {
        Write-Host "`nVerifying EWS configuration..." -ForegroundColor Yellow
        $EWS = Get-WebServicesVirtualDirectory | Select -First 1
        Write-Host "✓ OAuth Enabled: $($EWS.OAuthAuthentication)" -ForegroundColor Green
        Write-Host "✓ Extended Protection: $($EWS.ExtendedProtectionTokenCheck)" -ForegroundColor Green
    }
}

Write-Host "`n=== Validation Complete ===" -ForegroundColor Cyan
```

---

## Migration Tracking Template

Create a spreadsheet to track progress:

| App Name | Server | Type | Owner | Current State | Migration Path | Test Date | Prod Date | Status | Notes |
|----------|--------|------|-------|---------------|----------------|-----------|-----------|--------|-------|
| Backup App | SRV01 | Relay | IT Ops | Port 25 | SMTPS-587 | 2025-01-15 | 2025-01-22 | Complete | Success |
| Processing App | SRV02 | Mailbox | Dev Team | Port 25 | EWS | 2025-01-16 | 2025-01-23 | Testing | Issues with auth |
| Legacy App | SRV03 | Relay | Finance | Port 25 | Port 25 Exception | N/A | N/A | Deferred | Cannot update |

---

## Common Issues and Solutions

### Issue: TLS Negotiation Failure
**Symptoms**: Connection refused, TLS handshake errors

**Solution**:
```bash
# Check TLS version support
openssl s_client -connect <AVI-VIP>:587 -starttls smtp -tls1_2

# Update application to support TLS 1.2+
```

### Issue: Authentication Failure (EWS)
**Symptoms**: 401 Unauthorized

**Solution**:
```powershell
# Verify service account credentials
Test-Credential -Username "app-processing@contoso.com" -Password "password"

# Check ApplicationImpersonation role
Get-ManagementRoleAssignment -Role ApplicationImpersonation
```

### Issue: Extended Protection Errors
**Symptoms**: HTTP 403 errors on EWS

**Solution**:
```powershell
# Verify certificate synchronization between AVI and Exchange
Get-ExchangeCertificate | Where-Object {$_.Services -like "*IIS*"}

# Check Extended Protection settings
Get-WebServicesVirtualDirectory | Select ExtendedProtectionTokenCheck
```

---

## Notes

- Migrate applications in waves (10-20 per week)
- Always test in non-production first
- Keep detailed logs of each migration
- Have rollback plan ready for each application
- Communicate changes to application owners
