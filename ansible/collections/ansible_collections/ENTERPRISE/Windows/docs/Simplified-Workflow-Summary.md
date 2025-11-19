# Simplified Exchange Maintenance Workflow

## Overview

This AAP workflow provides automated Exchange Server maintenance without approval gates - designed for streamlined execution while maintaining safety through structured phases and rollback procedures.

## Workflow Structure

```
1. Pre-Backup ✅ → 2. Preparation → 3. Database Check → 4. Database Movement → 5. Maintenance Mode
                                                                        ↓
11. Success Email ✅ ← 10. Completion ← 9. Service Mgmt ← 8. Manual Window ← 6. Queue Monitoring
      ↓                                                  ↓
12. Unmute Alerts                                    Emergency Rollback
```

## Key Features

### ✅ **Streamlined Execution**
- No manual approval gates
- Automatic progression through phases
- Single manual confirmation during maintenance window

### 🛡️ **Built-in Safety**
- Comprehensive rollback procedures
- Database movement validation
- Service health monitoring
- Queue status verification

### 🎛️ **User-Friendly Interface**
- Survey-driven parameter collection
- Real-time progress monitoring
- Flexible maintenance windows

## Workflow Phases

| Phase | Name | Duration | Manual Action Required |
|-------|------|----------|----------------------|
| 1 | Pre-Maintenance Backup ✅ (Optional - Run Separately) | 4+ hours | None |
| 2 | Preparation | 2-3 mins | None |
| 3 | Database Check | 1-2 mins | None |
| 4 | Database Movement | 5-15 mins | None |
| 5 | Maintenance Mode | 1-2 mins | None |
| 6 | Queue Monitoring | 2-5 mins | None |
| 7 | Manual Window | 30-480 mins | **Yes - Maintenance Confirmation** |
| 8 | Service Management | 2-5 mins | None |
| 9 | Completion | 1-2 mins | None |
| 10 | Success Notification ✅ NEW | 1 min | None |
| 11 | Unmute Alerts | 1 min | None |

## Quick Start

### 1. Launch Workflow
1. Navigate to **Templates** in AAP
2. Find "Exchange Server Maintenance Workflow"
3. Click **Launch**

### 2. Complete Survey
- **Target Database**: `PREPROD-MB01` or `EXAMPLE-MB01`
- **Maintenance Duration**: 120 minutes (default)
- **Maintenance Reason**: Brief description
- **Rollback Plan**: Your recovery procedures

### 3. Monitor Execution
- Watch progress in AAP dashboard
- Phases 1-5 run automatically
- Phase 6 pauses for your manual maintenance
- Phases 7-8 complete automatically

### 4. During Manual Window
1. Perform your maintenance tasks:
   - Windows updates
   - Exchange patches
   - Configuration changes
   - Server reboots (if needed)

2. When finished, respond to prompt:
   - Type `completed` to continue
   - Type `extend` for more time
   - Type `abort` for emergency exit

## Environment Support

### Pre-Production (PREPROD-MB01)
- Ideal for testing procedures
- Same safety checks as production
- Lower impact if issues occur

### Production (EXAMPLE-MB01)
- Full production maintenance
- Comprehensive logging and monitoring
- Emergency rollback available

## Safety Features

### Automatic Rollback
- Triggers on any phase failure
- Exits maintenance mode
- Restarts Exchange services
- Logs all recovery actions

### Manual Abort
- Available during maintenance window
- Emergency exit from maintenance mode
- Immediate service recovery
- Alert notifications sent

### Comprehensive Monitoring
- Service status tracking
- Database health verification
- Queue monitoring and export
- Complete audit trail

## Survey Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| Target Database | Choice | Yes | PREPROD-MB01 or EXAMPLE-MB01 |
| Environment Type | Choice | Yes | preproduction or production |
| Maintenance Duration | Integer | Yes | 30-480 minutes |
| Change Request | Text | No | Tracking number |
| Maintenance Reason | Text Area | Yes | Description of work |
| Notification Email | Text | No | Alert recipient |
| Rollback Plan | Text Area | Yes | Recovery procedures |

## Emergency Procedures

### If Workflow Fails
1. **Check Status**: Review job logs in AAP
2. **Manual Rollback**: Run emergency rollback playbook
3. **Verify Services**: Ensure Exchange services running
4. **Check Databases**: Confirm database accessibility

### Emergency Commands
```powershell
# Check server component states
Get-ServerComponentState -Identity server-name

# Exit maintenance mode manually
Set-ServerComponentState server-name -Component ServerWideOffline -State Active -Requester Maintenance
Resume-ClusterNode server-name
Set-MailboxServer server-name -DatabaseCopyActivationDisabledAndMoveNow $false

# Restart Exchange services
Get-Service MSExchange* | Where-Object {$_.Status -eq 'Stopped'} | Start-Service
```

### Emergency Rollback via AAP
```bash
# Launch emergency rollback
ansible-playbook exchange-maintenance-rollback.yml \
  -e target_database=EXAMPLE-MB01 \
  -e emergency_rollback=true
```

## Best Practices

### Scheduling
- ✅ Test in pre-production first
- ✅ Schedule during maintenance windows
- ✅ Notify stakeholders in advance
- ✅ Have rollback plan documented

### During Maintenance
- ✅ Monitor AAP dashboard
- ✅ Keep change documentation ready
- ✅ Test functionality after changes
- ✅ Complete within planned window

### After Maintenance
- ✅ Verify Exchange services running
- ✅ Check database mount status
- ✅ Test mail flow functionality
- ✅ Document any issues encountered

## Troubleshooting

### Common Issues
1. **PowerShell Connectivity**: Test with `Test-WSMan`
2. **Database Movement**: Check DAG health
3. **Service Startup**: Review Windows Event Logs
4. **Maintenance Mode**: Verify component states

### Support Resources
- **Ansible Logs**: Available in AAP job output
- **Exchange Logs**: `C:\Program Files\Microsoft\Exchange Server\V15\Logging`
- **PowerShell Transcripts**: Enabled in automation
- **Event Logs**: Application and System logs

## Integration Options

### Notification Systems
- Email alerts for failures
- ITSM ticket creation
- Slack/Teams notifications
- Custom monitoring integration

### External Systems
- ServiceNow integration
- PagerDuty escalation
- Monitoring system alerts
- Documentation updates

---

## Summary

This simplified workflow provides:
- **Fast Execution**: No approval delays
- **Comprehensive Safety**: Rollback and monitoring
- **User Control**: Manual maintenance window
- **Full Automation**: Setup to completion
- **Production Ready**: Both PPD and production support

Perfect for teams that need reliable Exchange maintenance automation without the complexity of approval workflows.

**Total Typical Duration**: 45-180 minutes (depending on your maintenance tasks)
**Manual Intervention**: Only during maintenance window
**Safety Level**: High with automatic rollback
**Complexity**: Low - survey driven with clear progression