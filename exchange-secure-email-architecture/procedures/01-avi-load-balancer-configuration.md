# AVI Load Balancer Configuration Procedures

## Overview
This document provides step-by-step procedures for configuring AVI load balancer to support secure email protocols (SMTPS and EWS) for Exchange Server SE.

---

## Procedure 1: SMTPS L4 Passthrough Configuration

### Purpose
Configure Layer 4 passthrough for SMTPS traffic on ports 587 and 465 to preserve Extended Protection while simplifying IP trust management via SNAT.

### Prerequisites
- AVI Controller access with write permissions
- Exchange Server SE backend pool IPs
- Certificate installed on Exchange servers
- Network connectivity verified between AVI SE and Exchange servers

### Steps

#### 1.1 Create Health Monitor (TCP)
1. Navigate to **Templates → Health Monitors**
2. Click **Create**
3. Configure:
   - **Name**: `HM-Exchange-SMTP-TCP`
   - **Type**: `TCP`
   - **Send Interval**: `10 seconds`
   - **Receive Timeout**: `10 seconds`
   - **Successful Checks**: `2`
   - **Failed Checks**: `3`
4. Click **Save**

#### 1.2 Create Backend Pool
1. Navigate to **Applications → Pools**
2. Click **Create**
3. Configure **Basic Settings**:
   - **Name**: `Pool-Exchange-SMTPS`
   - **Default Server Port**: `587`
4. Configure **Servers** tab:
   - Click **Add Server**
   - Add each Exchange CAS server IP
   - Repeat for all CAS servers
5. Configure **Health Monitor** tab:
   - Select `HM-Exchange-SMTP-TCP`
6. Click **Save**

#### 1.3 Create Virtual Service - Port 587 (STARTTLS)
1. Navigate to **Applications → Virtual Services**
2. Click **Create Virtual Service** → **Advanced Setup**
3. Configure **Settings** tab:
   - **Name**: `VS-Exchange-SMTP-587`
   - **Application Type**: `L4`
   - **Virtual Service IP**: `<Your VIP>`
   - **Port**: `587`
4. Configure **Pool** tab:
   - **Default Pool**: `Pool-Exchange-SMTPS`
5. Configure **Advanced** tab:
   - **Network Profile**: `System-TCP-Proxy` or `System-TCP-Fast-Path`
   - **TCP/UDP Profile**: `System-TCP-Proxy`
6. Configure **SNAT**:
   - Navigate to **VS Settings → Advanced**
   - Enable **SNAT** → **Auto Allocate**
   - Or select specific SNAT IP pool
7. Click **Save**

#### 1.4 Create Virtual Service - Port 465 (Implicit TLS)
1. Navigate to **Applications → Virtual Services**
2. Click **Create Virtual Service** → **Advanced Setup**
3. Configure **Settings** tab:
   - **Name**: `VS-Exchange-SMTP-465`
   - **Application Type**: `L4`
   - **Virtual Service IP**: `<Your VIP>` (same as 587)
   - **Port**: `465`
4. Configure **Pool** tab:
   - **Default Pool**: `Pool-Exchange-SMTPS`
   - **Default Server Port**: `465`
5. Configure **Advanced** tab:
   - **Network Profile**: `System-TCP-Proxy` or `System-TCP-Fast-Path`
   - **TCP/UDP Profile**: `System-TCP-Proxy`
6. Configure **SNAT**:
   - Navigate to **VS Settings → Advanced**
   - Enable **SNAT** → **Auto Allocate**
   - Or select specific SNAT IP pool
7. Click **Save**

#### 1.5 Verification
1. Check Virtual Service status (should be green/up)
2. Verify backend pool members are healthy
3. Test connectivity:
   ```bash
   openssl s_client -connect <VIP>:587 -starttls smtp
   openssl s_client -connect <VIP>:465
   ```
4. Verify SNAT is working:
   - Check Exchange SMTP logs for source IPs
   - Should see AVI SE subnet IPs, not application server IPs

---

## Procedure 2: EWS L7 Bridging Configuration

### Purpose
Configure Layer 7 bridging for EWS/HTTPS traffic to enable application health monitoring, session persistence, and proper Extended Protection support with certificate synchronization.

### Prerequisites
- AVI Controller access with write permissions
- Exchange Server SE backend pool IPs
- SSL certificate matching Exchange server certificate
- Certificate uploaded to AVI
- Network connectivity verified

### Steps

#### 2.1 Import SSL Certificate
1. Navigate to **Templates → Security → SSL/TLS Certificates**
2. Click **Create** → **Application Certificate**
3. Options:
   - **Import**: Upload certificate matching Exchange
   - **CSR**: Generate new certificate request
4. Ensure certificate **Common Name** or **SAN** matches Exchange external URL
5. Click **Save**

#### 2.2 Create SSL/TLS Profile
1. Navigate to **Templates → Security → SSL/TLS Profile**
2. Click **Create**
3. Configure:
   - **Name**: `SSL-Profile-Exchange-EWS`
   - **Type**: `Application`
   - **Accepted Ciphers**: `TLS 1.2, TLS 1.3`
   - **Cipher Suite**: Select strong ciphers only
   - **Enable SSL Session Reuse**: `Checked`
4. Click **Save**

#### 2.3 Create Health Monitor (HTTP/HTTPS)
1. Navigate to **Templates → Health Monitors**
2. Click **Create**
3. Configure:
   - **Name**: `HM-Exchange-EWS`
   - **Type**: `HTTPS`
   - **Send Interval**: `30 seconds`
   - **Receive Timeout**: `10 seconds`
   - **Successful Checks**: `2`
   - **Failed Checks**: `3`
4. Configure **HTTP Request**:
   - **Path**: `/ews/healthcheck.htm`
   - **Method**: `GET`
5. Configure **Response Code**: `2xx, 3xx`
6. Click **Save**

#### 2.4 Create Persistence Profile
1. Navigate to **Templates → Profiles → Persistence**
2. Click **Create**
3. Configure:
   - **Name**: `Persistence-Exchange-EWS`
   - **Type**: `HTTP Cookie`
   - **Cookie Name**: `EWSSESSION` (or custom)
   - **Timeout**: `20 minutes`
4. Click **Save**

#### 2.5 Create Backend Pool
1. Navigate to **Applications → Pools**
2. Click **Create**
3. Configure **Basic Settings**:
   - **Name**: `Pool-Exchange-EWS`
   - **Default Server Port**: `443`
4. Configure **SSL** tab:
   - Enable **Enable SSL**
   - **PKI Profile**: Select or create profile for backend verification
5. Configure **Servers** tab:
   - Click **Add Server**
   - Add each Exchange CAS server IP
   - Repeat for all CAS servers
6. Configure **Health Monitor** tab:
   - Select `HM-Exchange-EWS`
7. Click **Save**

#### 2.6 Create Virtual Service
1. Navigate to **Applications → Virtual Services**
2. Click **Create Virtual Service** → **Advanced Setup**
3. Configure **Settings** tab:
   - **Name**: `VS-Exchange-EWS`
   - **Application Type**: `HTTP/HTTPS`
   - **Virtual Service IP**: `<Your VIP>`
   - **Port**: `443`
4. Configure **Pool** tab:
   - **Default Pool**: `Pool-Exchange-EWS`
5. Configure **Policies** tab:
   - **SSL/TLS Certificate**: Select imported certificate
   - **SSL Profile**: `SSL-Profile-Exchange-EWS`
6. Configure **Advanced** tab:
   - **Application Profile**: `System-HTTPS`
   - **Network Profile**: `System-TCP-Proxy`
   - **Persistence Profile**: `Persistence-Exchange-EWS`
7. Configure **Analytics** tab:
   - Enable **Client Insights**
   - Enable **Real Time Metrics**
8. Click **Save**

#### 2.7 Configure HTTP to HTTPS Redirect (Optional)
1. Navigate to **Applications → Virtual Services**
2. Click **Create Virtual Service**
3. Configure:
   - **Name**: `VS-Exchange-EWS-HTTP-Redirect`
   - **VIP**: Same as HTTPS VS
   - **Port**: `80`
4. Configure **HTTP Request Policy**:
   - **Action**: `HTTP Redirect`
   - **Protocol**: `HTTPS`
   - **Port**: `443`
5. Click **Save**

#### 2.8 Verification
1. Check Virtual Service status (should be green/up)
2. Verify backend pool members are healthy
3. Test EWS endpoint:
   ```bash
   curl -k https://<VIP>/ews/healthcheck.htm
   ```
4. Test EWS functionality with PowerShell:
   ```powershell
   $ews = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService
   $ews.Url = "https://<VIP>/ews/Exchange.asmx"
   $ews.UseDefaultCredentials = $true
   $ews.FindFolders([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::Inbox, `
     (New-Object Microsoft.Exchange.WebServices.Data.FolderView(10)))
   ```
5. Verify certificate matches Exchange
6. Check session persistence is working

---

## Procedure 3: Identify AVI Service Engine Subnet

### Purpose
Identify the SNAT source IP range (AVI SE subnet) that will be used in Exchange Receive Connector configuration for IP-based trust.

### Steps

#### 3.1 Identify Service Engine IPs
1. Navigate to **Infrastructure → Service Engines**
2. Note the **Management IP** and **Data Network IPs** for all SEs
3. Identify the subnet/CIDR that encompasses these IPs
4. Example: If SEs are `10.10.50.10`, `10.10.50.11`, `10.10.50.12`
   - Subnet: `10.10.50.0/24`

#### 3.2 Document SNAT Configuration
1. Navigate to **Applications → Virtual Services**
2. Select `VS-Exchange-SMTP-587`
3. Navigate to **Advanced** tab
4. Check **SNAT** configuration:
   - If **Auto Allocate**: Uses SE data interface IPs
   - If **SNAT IP Pool**: Note the pool range
5. Document these IP ranges for Exchange configuration

#### 3.3 Output for Exchange Team
Provide the following to Exchange administrators:
```
AVI Service Engine SNAT Source IPs:
- Subnet: 10.10.50.0/24
- Or specific IPs: 10.10.50.10, 10.10.50.11, 10.10.50.12

These IPs should be added to the Exchange Receive Connector
remote IP ranges for IP-based authentication.
```

---

## Troubleshooting

### SMTPS Issues
- **Pool members down**: Check firewall rules, verify Exchange listening on ports 587/465
- **TLS errors**: Verify Exchange certificate validity, check cipher compatibility
- **Extended Protection errors**: Confirm L4 passthrough (not L7), verify SNAT enabled

### EWS Issues
- **Health monitor failing**: Verify `/ews/healthcheck.htm` is accessible, check authentication
- **Certificate errors**: Verify certificate matches Exchange, check SAN entries
- **Session issues**: Confirm persistence profile applied, check timeout values
- **Extended Protection errors**: Verify certificate synchronization between AVI and Exchange

### General
- Review AVI logs: **Operations → Logs → Virtual Service Logs**
- Review pool logs: **Operations → Logs → Pool Logs**
- Check Service Engine logs: **Infrastructure → Service Engines → [SE] → Logs**

---

## Rollback Procedures

### SMTPS
1. Delete Virtual Services `VS-Exchange-SMTP-587` and `VS-Exchange-SMTP-465`
2. Delete Pool `Pool-Exchange-SMTPS`
3. Delete Health Monitor `HM-Exchange-SMTP-TCP`

### EWS
1. Delete Virtual Service `VS-Exchange-EWS`
2. Delete Pool `Pool-Exchange-EWS`
3. Delete Health Monitor `HM-Exchange-EWS`
4. Delete Persistence Profile `Persistence-Exchange-EWS`
5. Delete SSL Profile `SSL-Profile-Exchange-EWS`

---

## Notes
- All changes should be made during maintenance windows
- Test in non-production environment first
- Document all configuration changes
- Keep backup of AVI configuration before changes
