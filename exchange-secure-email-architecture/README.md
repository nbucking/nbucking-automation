# Exchange Server SE: Secure Email Architecture

## Overview

This folder contains documentation and architecture guidelines for modernizing email protocols in Exchange Server Subscription Edition (SE) from legacy plaintext SMTP to secure messaging using EWS and SMTPS.

## Contents

### Documentation

- **exchange-modernization.html** - Interactive HTML whitepaper with visualizations
  - Protocol selection decision trees
  - Architecture diagrams for SMTPS and EWS
  - Load balancer configuration strategies
  - Migration phases and timelines
  - Licensing and compliance guidelines

## Key Concepts

### Protocol Selection

The architecture defines two secure pathways:

1. **SMTPS (Secure SMTP)** - For outbound notifications/alerts
   - Ports: 587 (STARTTLS) or 465 (Implicit TLS)
   - No mailbox required
   - Layer 4 passthrough on load balancer
   - IP-based trust with SNAT

2. **EWS (Exchange Web Services)** - For mailbox processing
   - Protocol: HTTPS with Modern Auth
   - Dedicated mailbox required
   - Layer 7 bridging on load balancer
   - Native move/delete operations

### Load Balancer Integration

- **SMTPS**: L4 Passthrough + SNAT (preserves Extended Protection)
- **EWS**: L7 Bridging + Certificate Sync (enables health checks and session persistence)

### Migration Strategy

1. **Phase 1: Coexistence** (30-60 days)
   - Maintain Port 25 for legacy apps (restricted)
   - Deploy new secure connectors

2. **Phase 2: Migration** (60-90 days)
   - Migrate apps by priority
   - Reduce Port 25 traffic to zero

3. **Phase 3: Decommission** (30 days validation)
   - Disable Port 25 entirely

## Viewing the Documentation

### Browser
```bash
# Open in default browser
open exchange-modernization.html
```

### Convert to PDF
1. Open `exchange-modernization.html` in a web browser
2. Press Ctrl+P (Cmd+P on Mac)
3. Select "Save as PDF"

## Related Automation

This architecture documentation complements the Exchange automation in this repository:

- **exchange-ansible-collection/** - Production-ready roles for Exchange maintenance
- **ansible/exchange-*.yml** - Playbooks for Exchange management

## Target Audience

- Infrastructure Architects
- Security Operations Teams
- Exchange Administrators
- System Engineers implementing Exchange SE

## Environment Support

- Exchange Server Subscription Edition (SE)
- On-premises and air-gapped deployments
- Windows Server 2016/2019/2022
- Avi/Cisco Load Balancers

## License

Part of the nbucking-automation repository.

## Contributing

For updates or corrections to the architecture documentation, please submit pull requests or issues to the main repository.
