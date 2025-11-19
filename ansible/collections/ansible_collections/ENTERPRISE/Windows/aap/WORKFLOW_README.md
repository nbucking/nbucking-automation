# Windows: Exchange Server Maintenance Workflow

## Overview

**Workflow Name**: `Windows: Exchange Server Maintenance Workflow`

This workflow orchestrates the complete Exchange Server maintenance process with integrated monitoring alerts and VM snapshots. The workflow includes safety checks, approval gates, and automatic rollback capabilities.

## Workflow Steps

### 1. Preparation Phase (ID: 1)
**Job Template**: `Exchange Maintenance - Preparation Phase`
- Cleans temporary files
- Loads Exchange Management snap-in
- Retrieves Exchange server list
- **On Success**: → Step 2 (Mute Alerts)
- **On Failure**: → Step 99 (Failure Notification)

### 2. SolarWinds - Mute Alerts (ID: 2)
**Job Template**: `SolarWinds - Mute Node Alerts`
**Role**: `ENTERPRISE.Common.Solarwinds_MxMode` (mute action)
- Mutes monitoring alerts for target Exchange servers in SolarWinds
- Prevents alert spam during maintenance
- **On Success**: → Step 3 (Take Snapshot)
- **On Failure**: → Step 99 (Failure Notification)

### 3. VMware - Take Snapshot (ID: 3)
**Job Template**: `VMware - Take VM Snapshot`
**Role**: `ENTERPRISE.Common.TakeASnapshot`
- Takes VM snapshot of Exchange servers before maintenance
- Provides rollback point if needed
- **On Success**: → Step 4 (Database Check)
- **On Failure**: → Step 98 (Rollback Alerts)

### 4. Database Check (ID: 4)
**Job Template**: `Exchange Maintenance - Database Check`
- Checks database copy status across all servers
- Identifies active database locations
- **On Success**: → Step 5 (Database Movement)
- **On Failure**: → Step 98 (Rollback Alerts)

### 5. Database Movement (ID: 5)
**Job Template**: `Exchange Maintenance - Database Movement`
- Moves active databases away from target servers (if needed)
- Interactive or automated based on configuration
- **On Success**: → Step 6 (Enable Maintenance Mode)
- **On Failure**: → Step 98 (Rollback Alerts)

### 6. Enable Maintenance Mode (ID: 6)
**Job Template**: `Exchange Maintenance - Enable Maintenance Mode`
- Sets HubTransport to Draining
- Redirects messages to other servers
- Suspends cluster node
- Blocks database auto-activation
- Sets server components offline
- **On Success**: → Step 7 (Queue Monitoring)
- **On Failure**: → Step 97 (Rollback Maintenance Mode)

### 7. Queue Monitoring (ID: 7)
**Job Template**: `Exchange Maintenance - Queue Monitoring`
- Monitors message queues
- Waits for queues to drain
- **On Success**: → Step 8 (Manual Maintenance Window)
- **On Failure**: → Step 97 (Rollback Maintenance Mode)

### 8. Manual Maintenance Window (ID: 8)
**Job Template**: `Manual Maintenance Window`
- Approval gate for actual maintenance work
- Allows operator to perform patching, reboots, etc.
- **On Success**: → Step 9 (Service Management)
- **On Failure**: → Step 97 (Rollback Maintenance Mode)

### 9. Service Management (ID: 9)
**Job Template**: `Exchange Maintenance - Service Management`
- Checks Exchange service status
- Starts any stopped services
- Verifies services are running
- **On Success**: → Step 10 (Completion Phase)
- **On Failure**: → Step 97 (Rollback Maintenance Mode)

### 10. Completion Phase (ID: 10)
**Job Template**: `Exchange Maintenance - Completion Phase`
- Exits maintenance mode
- Resumes cluster node
- Re-enables database activation
- Sets server components active
- **On Success**: → Step 11 (Unmute Alerts)
- **On Failure**: → Step 11 (Unmute Alerts)

### 11. SolarWinds - Unmute Alerts (ID: 11)
**Job Template**: `SolarWinds - Unmute Node Alerts`
**Role**: `ENTERPRISE.Common.Solarwinds_MxMode` (unmute action)
- Unmutes monitoring alerts in SolarWinds
- Restores normal monitoring
- **Completes**: Workflow ends successfully

---

## Rollback Paths

### Rollback Path A - Maintenance Mode Issues (ID: 97)
**Job Template**: `Exchange Maintenance - Rollback Maintenance Mode`
**Triggered by**: Failures in steps 6-9
- Exits maintenance mode
- Resumes cluster operations
- Re-enables components
- **Next**: → Step 11 (Unmute Alerts)

### Rollback Path B - Pre-Maintenance Issues (ID: 98)
**Job Template**: `SolarWinds - Unmute Node Alerts`
**Triggered by**: Failures in steps 3-5 (after snapshot/alerts muted)
- Unmutes SolarWinds alerts
- **Next**: → Step 99 (Failure Notification)
### 12. Failure Notification (ID: 99)
**Job Template**: `Exchange Maintenance - Failure Notification`
**Triggered by**: Any critical failure
- Sends failure notifications
- Logs failure details
- **Completes**: Workflow ends with failure

---

## Standalone Backup Job Template

### Windows: Exchange Database Backup (Standalone)
**Job Template**: `Windows: Exchange Database Backup (Standalone)`

**Purpose**: Run database backups separately from maintenance workflow

**Features**:
- Can be run independently before, after, or separately from maintenance
- Uses `exchange-backup` role
- Backs up only server with `exchange_database_preference: 1`
- Moves active database if needed
- Backs up to environment-specific DFS share
- Cycles logs after backup
- **Timeout**: 6 hours (realistic for large database backups)

**When to Use**:
- Regular scheduled backups (separate from maintenance)
- Pre-backup before maintenance windows (plan accordingly for 4+ hour backups)
- Ad-hoc backups requested by operations team
- Emergency backup requirements

**Does Not Block Maintenance**: Backups can be run independently and do not need to be part of the main maintenance workflow
- **Completes**: Workflow ends with failure

---

## Workflow Diagram

```
START
  ↓
[1] Pre-Maintenance Backup ✅ NEW
  ↓
[2] Preparation Phase
  ↓
[3] Mute SolarWinds Alerts
  ↓
[4] Take VM Snapshot
  ↓
[5] Database Check
  ↓
[6] Database Movement
  ↓
[7] Enable Maintenance Mode ────→ [97] Rollback Maintenance Mode
  ↓                                  ↓
[8] Queue Monitoring          ────→ [13] Unmute Alerts
  ↓                                  ↓
[9] Manual Maintenance        END (Success/Rollback)
  ↓
[10] Service Management
  ↓
[11] Completion Phase
  ↓
[12] Success Notification ✅ NEW
  ↓
[13] Unmute SolarWinds Alerts
  ↓
END (Success)

Failures in [4-6] → [98] Unmute Alerts → [99] Failure Notification → END
Failures in [2-3] → [99] Failure Notification → END
```

---

## Required Job Templates

The following job templates must be created in AAP:

### Exchange Maintenance Templates
1. `Windows: Exchange Database Backup` ✅ NEW (uses `exchange-backup` role)
2. `Exchange Maintenance - Preparation Phase`
3. `Exchange Maintenance - Database Check`
4. `Exchange Maintenance - Database Movement`
5. `Exchange Maintenance - Enable Maintenance Mode`
6. `Exchange Maintenance - Queue Monitoring`
7. `Manual Maintenance Window`
8. `Exchange Maintenance - Service Management`
9. `Exchange Maintenance - Completion Phase`
10. `Windows: Exchange Maintenance - Success Notification` ✅ NEW (uses `exchange-notification` role)
11. `Exchange Maintenance - Rollback Maintenance Mode`
12. `Exchange Maintenance - Failure Notification`

### Common/Integration Templates
11. `SolarWinds - Mute Node Alerts` (uses `ENTERPRISE.Common.Solarwinds_MxMode`)
12. `SolarWinds - Unmute Node Alerts` (uses `ENTERPRISE.Common.Solarwinds_MxMode`)
13. `VMware - Take VM Snapshot` (uses `ENTERPRISE.Common.TakeASnapshot`)

---

## Configuration Requirements

### Collections Required
- `ENTERPRISE.Windows` - Exchange maintenance roles
- `ENTERPRISE.Common` - SolarWinds and VMware snapshot roles

### Variables
Standard Exchange maintenance variables apply (see main documentation).

Additional variables for integration:

**SolarWinds Variables:**
- `nodestatus`: "mute" or "unmute" - Node maintenance mode status
- `maintenance_window_duration`: Integer (minutes) - Duration of maintenance window (default: 120)
- `hours`: Integer - Hours until auto-unmute (auto-calculated from maintenance_window_duration)

**Snapshot Variables:**
- `my_snapshot_name`: Snapshot name (default: "Exchange-PreMaint-YYYY-MM-DD")
- `my_description`: Snapshot description
- `snapshot_retention_days`: Days until removal (default: 7)
- `my_snapshot_removal_date`: MM/DD/YYYY format (calculated from snapshot_retention_days)
- `remove_prev_snapshots`: Boolean - Remove previous snapshots (default: true)

---

## Benefits of This Workflow

1. **Pre-Maintenance Protection**
   - SolarWinds alerts muted to prevent noise
   - VM snapshots taken for quick rollback
   
2. **Comprehensive Error Handling**
   - Multiple rollback paths based on failure point
   - Always unmutes alerts regardless of outcome
   
3. **Safety Gates**
   - Manual approval window for actual maintenance
   - Automated pre/post checks
   
4. **Monitoring Integration**
   - Seamless SolarWinds integration
   - Proper alert lifecycle management

5. **Recovery Options**
   - VM snapshots for disaster recovery
   - Automated rollback of Exchange settings
