# Exchange Secure Email Migration - Progress Tracker

**Instructions for OneNote:**
1. Copy this entire file into a OneNote page
2. Select all lines that start with "- [ ]"
3. Press Ctrl+1 (Windows) or Cmd+1 (Mac) to convert to interactive checkboxes
4. Check off items as you complete them
5. Use Home → Find Tags to see all unchecked items across your notebook

---

## Phase 0: Firewall Requests

**Goal:** Submit and implement firewall rules before any configuration work begins.
**Timeline:** Submit 1-2 weeks before planned configuration date

### Firewall Change Requests

- [ ] Submit firewall request: Application Servers → Load Balancer VIP (TCP 587, 465, 443)
- [ ] Submit firewall request: AVI Service Engines → Exchange CAS Servers (TCP 587, 465, 443)
- [ ] Submit firewall request: Application Servers → Exchange CAS Servers (TCP 443 for direct EWS)
- [ ] Optional: Submit firewall request: Admin workstations → Exchange CAS (TCP 587, 465, 443 for testing)
- [ ] Verify all firewall rules are implemented and tested
- [ ] Document approved firewall change ticket numbers

---

## Phase 1: AVI Load Balancer Configuration

**Goal:** Configure AVI for SMTPS (L4) and EWS (L7) with proper health checks and persistence.

### SMTPS Configuration (Ports 587/465)

- [ ] Create TCP Health Monitor: HM-Exchange-SMTP-TCP
- [ ] Create Backend Pool: Pool-Exchange-SMTPS (port 587)
- [ ] Add all Exchange CAS server IPs to pool
- [ ] Assign health monitor to pool
- [ ] Create Virtual Service: VS-Exchange-SMTP-587 (L4 application type)
- [ ] Configure Virtual Service with Pool-Exchange-SMTPS
- [ ] Enable SNAT on VS-Exchange-SMTP-587 (Auto Allocate)
- [ ] Optional: Create Virtual Service: VS-Exchange-SMTP-465 (port 465, server port 465)
- [ ] Optional: Enable SNAT on VS-Exchange-SMTP-465
- [ ] Test STARTTLS connectivity: openssl s_client -connect <VIP>:587 -starttls smtp
- [ ] Optional: Test Implicit TLS connectivity: openssl s_client -connect <VIP>:465
- [ ] Verify pool members show as healthy (green/up status)

### Document AVI Service Engine Subnet

- [ ] Navigate to Infrastructure → Service Engines
- [ ] Document all Service Engine Data Network IPs
- [ ] Determine subnet/CIDR (e.g., 10.10.50.0/24)
- [ ] Provide subnet information to Exchange team
- [ ] **Document AVI SE Subnet here: ___________________**

### EWS Configuration (HTTPS/443)

- [ ] Import SSL certificate to AVI (must match Exchange certificate)
- [ ] Verify certificate Common Name/SAN matches Exchange external URL
- [ ] Create SSL/TLS Profile: SSL-Profile-Exchange-EWS (TLS 1.2+)
- [ ] Create HTTPS Health Monitor: HM-Exchange-EWS (path: /ews/healthcheck.htm)
- [ ] Create Persistence Profile: Persistence-Exchange-EWS (HTTP Cookie, 20 min timeout)
- [ ] Create Backend Pool: Pool-Exchange-EWS (port 443, SSL enabled)
- [ ] Add all Exchange CAS server IPs to EWS pool
- [ ] Assign health monitor to EWS pool
- [ ] Create Virtual Service: VS-Exchange-EWS (HTTP/HTTPS application type)
- [ ] Configure VS with Pool-Exchange-EWS
- [ ] Apply SSL certificate to VS-Exchange-EWS
- [ ] Apply persistence profile to VS-Exchange-EWS
- [ ] Test EWS health check: curl -k https://<VIP>/ews/healthcheck.htm
- [ ] Verify pool members show as healthy
- [ ] Optional: Create HTTP→HTTPS redirect on port 80

---

## Phase 2: Exchange Server Configuration

**Goal:** Create secure receive connectors and configure EWS virtual directories.

### SMTPS Receive Connector (Port 587)

- [ ] Identify current Receive Connectors (document legacy Port 25 connector)
- [ ] Backup legacy Port 25 connector configuration
- [ ] **On each CAS server:**
  - [ ] CAS Server 1: Create "Secure Relay - Port 587" connector
  - [ ] CAS Server 1: Configure RequireTLS, ExtendedProtectionPolicy Require
  - [ ] CAS Server 1: Set RemoteIPRanges to AVI SE subnet
  - [ ] CAS Server 1: Grant relay permissions to NT AUTHORITY\ANONYMOUS LOGON
  - [ ] CAS Server 2: Create "Secure Relay - Port 587" connector
  - [ ] CAS Server 2: Configure RequireTLS, ExtendedProtectionPolicy Require
  - [ ] CAS Server 2: Set RemoteIPRanges to AVI SE subnet
  - [ ] CAS Server 2: Grant relay permissions to NT AUTHORITY\ANONYMOUS LOGON
  - [ ] CAS Server 3: Create "Secure Relay - Port 587" connector
  - [ ] CAS Server 3: Configure RequireTLS, ExtendedProtectionPolicy Require
  - [ ] CAS Server 3: Set RemoteIPRanges to AVI SE subnet
  - [ ] CAS Server 3: Grant relay permissions to NT AUTHORITY\ANONYMOUS LOGON
- [ ] Verify all connectors created: Get-ReceiveConnector | Where {$_.Name -like "*Secure Relay*"}
- [ ] Test connectivity from AVI SE subnet to Exchange port 587

### Optional: SMTPS Receive Connector (Port 465)

- [ ] **On each CAS server:**
  - [ ] CAS Server 1: Create "Secure Relay - Port 465" connector
  - [ ] CAS Server 2: Create "Secure Relay - Port 465" connector
  - [ ] CAS Server 3: Create "Secure Relay - Port 465" connector
- [ ] Configure all Port 465 connectors with same settings as Port 587
- [ ] Grant relay permissions on all Port 465 connectors

### EWS Virtual Directory Configuration

- [ ] Review current EWS configuration: Get-WebServicesVirtualDirectory
- [ ] **On each CAS server:**
  - [ ] CAS Server 1: Set InternalUrl and ExternalUrl to https://<VIP>/ews/Exchange.asmx
  - [ ] CAS Server 1: Disable BasicAuthentication, enable OAuth and Windows Auth
  - [ ] CAS Server 1: Set ExtendedProtectionTokenCheck to Require
  - [ ] CAS Server 2: Set InternalUrl and ExternalUrl to https://<VIP>/ews/Exchange.asmx
  - [ ] CAS Server 2: Disable BasicAuthentication, enable OAuth and Windows Auth
  - [ ] CAS Server 2: Set ExtendedProtectionTokenCheck to Require
  - [ ] CAS Server 3: Set InternalUrl and ExternalUrl to https://<VIP>/ews/Exchange.asmx
  - [ ] CAS Server 3: Disable BasicAuthentication, enable OAuth and Windows Auth
  - [ ] CAS Server 3: Set ExtendedProtectionTokenCheck to Require
- [ ] Verify OAuth is enabled organization-wide
- [ ] Test EWS connectivity: Test-WebServicesConnectivity

### EWS Service Accounts

**Note:** If you already have IMAP mailboxes, you can reuse them for EWS. No need to create new ones!

- [ ] Identify existing mailboxes used for IMAP processing
- [ ] Verify EWS is enabled on existing mailboxes: Get-CASMailbox <mailbox> | Select EwsEnabled
- [ ] If needed: Enable EWS on existing mailboxes
- [ ] Verify existing service account permissions apply to EWS
- [ ] Optional: Create NEW mailbox only if you need one that doesn't exist
- [ ] Optional: Grant ApplicationImpersonation role (if needed for multi-mailbox access)
- [ ] Optional: Create custom throttling policy for EWS service accounts
- [ ] Document all mailboxes being used for EWS processing
- [ ] **Mailboxes using EWS: ___________________________________________________**

### Port 25 Monitoring Setup

- [ ] Document current Port 25 connector configuration
- [ ] Create Port 25 usage monitoring script
- [ ] Set up weekly scheduled task to monitor Port 25 traffic
- [ ] Establish baseline of current Port 25 usage
- [ ] **Baseline Port 25 Message Count: ___________________**

---

## Phase 3: Application Migration

**Goal:** Migrate applications from Port 25 to SMTPS (587/465) or EWS based on requirements.

### Pre-Migration Assessment

- [ ] Complete application inventory (Name, Server, Purpose, Owner, Contact)
- [ ] Analyze Exchange message tracking logs for Port 25 senders (last 30 days)
- [ ] Classify applications: Type A (Simple Relay), Type B (Mailbox Processing), Type C (Legacy)
- [ ] Create migration tracking spreadsheet
- [ ] Prioritize applications: High/Medium/Low criticality
- [ ] Identify applications that cannot be updated (legacy)

### Application Migration Waves

**Wave 1: High-Priority Applications (Week 1-2)**
- [ ] App 1: _________________ - Migration Path: _________ - Owner: _________
- [ ] App 2: _________________ - Migration Path: _________ - Owner: _________
- [ ] App 3: _________________ - Migration Path: _________ - Owner: _________
- [ ] App 4: _________________ - Migration Path: _________ - Owner: _________
- [ ] App 5: _________________ - Migration Path: _________ - Owner: _________

**Wave 2: Medium-Priority Applications (Week 3-4)**
- [ ] App 6: _________________ - Migration Path: _________ - Owner: _________
- [ ] App 7: _________________ - Migration Path: _________ - Owner: _________
- [ ] App 8: _________________ - Migration Path: _________ - Owner: _________
- [ ] App 9: _________________ - Migration Path: _________ - Owner: _________
- [ ] App 10: _________________ - Migration Path: _________ - Owner: _________

**Wave 3: Low-Priority Applications (Week 5-6)**
- [ ] App 11: _________________ - Migration Path: _________ - Owner: _________
- [ ] App 12: _________________ - Migration Path: _________ - Owner: _________
- [ ] App 13: _________________ - Migration Path: _________ - Owner: _________
- [ ] App 14: _________________ - Migration Path: _________ - Owner: _________
- [ ] App 15: _________________ - Migration Path: _________ - Owner: _________

### Per-Application Migration Checklist

For each application, complete these steps:

**SMTPS Applications (Port 587/465)**
- [ ] Test connectivity from app server to AVI VIP
- [ ] Update application configuration (server, port, enable TLS)
- [ ] Send test email
- [ ] Verify in Exchange message tracking
- [ ] Monitor for 48 hours
- [ ] Check for TLS negotiation errors
- [ ] Verify email delivery to recipients
- [ ] Update documentation
- [ ] Mark as complete in tracking spreadsheet

**EWS Applications (Mailbox Processing)**
- [ ] Create/verify dedicated mailbox exists
- [ ] Grant necessary permissions (FullAccess or ApplicationImpersonation)
- [ ] Test EWS connectivity from app server
- [ ] Update application code with EWS library
- [ ] Test mailbox operations (read, move, delete)
- [ ] Schedule application (cron or Task Scheduler)
- [ ] Monitor for 48 hours
- [ ] Check EWS logs for errors
- [ ] Verify folder operations working correctly
- [ ] Update documentation
- [ ] Mark as complete in tracking spreadsheet

### Weekly Monitoring

- [ ] Week 1: Run Port 25 usage report, review progress
- [ ] Week 2: Run Port 25 usage report, review progress
- [ ] Week 3: Run Port 25 usage report, review progress
- [ ] Week 4: Run Port 25 usage report, review progress
- [ ] Week 5: Run Port 25 usage report, review progress
- [ ] Week 6: Run Port 25 usage report, review progress
- [ ] Week 7: Run Port 25 usage report, review progress
- [ ] Week 8: Run Port 25 usage report, review progress

---

## Phase 4: Validation and Decommission (30 days)

**Goal:** Validate zero Port 25 traffic and safely decommission legacy connector.

### 30-Day Validation Period

- [ ] Week 1: Monitor Port 25 traffic = 0 messages
- [ ] Week 2: Monitor Port 25 traffic = 0 messages
- [ ] Week 3: Monitor Port 25 traffic = 0 messages
- [ ] Week 4: Monitor Port 25 traffic = 0 messages
- [ ] Confirm all applications migrated and functioning
- [ ] Run security audit/compliance check
- [ ] Review service desk tickets for email-related issues
- [ ] Verify no user complaints or escalations
- [ ] Document rollback plan (just in case)

### Port 25 Decommission

- [ ] Obtain change approval for Port 25 connector decommission
- [ ] Schedule maintenance window
- [ ] Run final Port 25 usage verification script
- [ ] Disable Port 25 Receive Connector (Set-ReceiveConnector -Enabled $false)
- [ ] Monitor for 7 days for any issues
- [ ] Review service desk tickets
- [ ] Check application logs
- [ ] Verify no emergency requests to re-enable
- [ ] **After 30 days:** Remove Port 25 connector completely (optional)
- [ ] Update network documentation
- [ ] Update firewall rules (remove Port 25 if desired)

---

## Post-Migration Activities

### Documentation

- [ ] Update Exchange architecture diagrams
- [ ] Update application configuration documentation
- [ ] Document all service accounts and credentials
- [ ] Update runbooks and operational procedures
- [ ] Create knowledge base articles for common issues
- [ ] Document lessons learned

### Knowledge Transfer

- [ ] Train Exchange administrators on new configuration
- [ ] Train application support teams on SMTPS/EWS
- [ ] Create troubleshooting guides
- [ ] Schedule knowledge transfer sessions
- [ ] Update on-call procedures

### Compliance and Security

- [ ] Run security compliance scan
- [ ] Update security documentation
- [ ] Verify TLS 1.2+ enforcement
- [ ] Verify Extended Protection enabled
- [ ] Review audit logs
- [ ] Update security policies
- [ ] Document for compliance audits (SOX, PCI, HIPAA, etc.)

### Final Review

- [ ] Hold project retrospective meeting
- [ ] Document what went well
- [ ] Document challenges and how they were resolved
- [ ] Update procedures based on lessons learned
- [ ] Archive project documentation
- [ ] Celebrate success! 🎉

---

## Migration Statistics (Track Your Progress)

**Infrastructure Setup:**
- Total Tasks: 30
- Completed: _____
- Remaining: _____
- % Complete: _____

**Exchange Configuration:**
- Total Tasks: 20
- Completed: _____
- Remaining: _____
- % Complete: _____

**Application Migration:**
- Total Applications: _____
- Migrated to SMTPS: _____
- Migrated to EWS: _____
- Remaining: _____
- % Complete: _____

**Overall Project:**
- Start Date: _____________________
- Target Completion Date: _____________________
- Actual Completion Date: _____________________
- Total Duration: _____ days

---

## Key Contacts

**Project Team:**
- Project Manager: _____________________
- Exchange Administrator: _____________________
- Network/Firewall Administrator: _____________________
- AVI Administrator: _____________________
- Application Support Lead: _____________________

**Escalation Contacts:**
- IT Director: _____________________
- Security Team: _____________________
- Change Management: _____________________

---

## Important Links & References

- GitHub Repository: https://github.com/nbucking/nbucking-automation
- Procedures Location: /exchange-secure-email-architecture/procedures/
- HTML Interactive Guide: migration-procedures.html
- AVI Procedures: 01-avi-load-balancer-configuration.md
- Exchange Procedures: 02-exchange-cas-configuration.md
- Application Migration: 03-application-migration.md
- Architecture Document: exchange-modernization.html

---

## Notes & Decisions

Use this space to track important decisions, blockers, or notes during migration:

**Date: __________ Note:**


**Date: __________ Note:**


**Date: __________ Note:**


**Date: __________ Note:**


**Date: __________ Note:**
