# AAP Job Template Variable Reference

## Common Collection Variables

This document provides a reference for all variables used in the Common collection job templates.

---

## SolarWinds Node MX Mode Variables

**Job Template**: `Common: SolarWinds Node MX Mode`  
**Role**: `ENTERPRISE.Common.Solarwinds_MxMode`

### Required Variables

| Variable | Type | Description | Valid Values | Example |
|----------|------|-------------|--------------|---------|
| `nodestatus` | String | Node maintenance status action | `"mute"` or `"unmute"` | `"mute"` |
| `maintenance_window_duration` | Integer | Maintenance window in minutes | Any positive integer | `120` |
| `hours` | Integer | Hours until automatic unmute (calculated) | Any positive integer | `2` |

### Usage Examples

**Mute alerts for 2 hours (120 minutes):**
```yaml
extra_vars:
  nodestatus: "mute"
  maintenance_window_duration: 120  # Minutes
  hours: "{{ (maintenance_window_duration | default(120) / 60) | round(0, 'ceil') | int }}"  # Auto-calculated
```

**Mute alerts for 3 hours (180 minutes):**
```yaml
extra_vars:
  nodestatus: "mute"
  maintenance_window_duration: 180  # Minutes
  hours: 3  # Auto-calculated from 180/60
```

**Unmute alerts immediately:**
```yaml
extra_vars:
  nodestatus: "unmute"
```

### Variable Calculation

The `hours` parameter is **automatically calculated** from `maintenance_window_duration`:

```jinja2
hours = {{ (maintenance_window_duration / 60) | round(0, 'ceil') | int }}
```

- **Input**: `maintenance_window_duration` in minutes (e.g., 120)
- **Calculation**: Divide by 60, round up to nearest whole hour
- **Output**: `hours` as integer (e.g., 2)

**Examples:**
- 120 minutes → 2 hours
- 180 minutes → 3 hours
- 90 minutes → 2 hours (rounded up)
- 150 minutes → 3 hours (rounded up)

### Workflow Integration

- **Step 2 (Mute)**: Sets `nodestatus: "mute"` and calculates `hours` from `maintenance_window_duration`
  - Default: 120 minutes (2 hours)
  - SolarWinds will auto-unmute after calculated hours if workflow doesn't complete
  - Provides failsafe for stuck/failed workflows
  
- **Step 11 (Unmute)**: Sets `nodestatus: "unmute"`
  - Immediately unmutes alerts when maintenance completes successfully
  - Overrides any pending auto-unmute timer
  - Restores monitoring earlier than the scheduled auto-unmute

---

## VM Snapshot Variables

**Job Template**: `Common: Create a VM Snapshot`  
**Role**: `ENTERPRISE.Common.TakeASnapshot`

### Required Variables

| Variable | Type | Description | Format/Values | Example |
|----------|------|-------------|---------------|---------|
| `my_snapshot_name` | String | Name for the snapshot | Any valid string | `"Exchange-PreMaint-2025-11-03"` |
| `my_description` | String | Snapshot description | Any string | `"Pre-maintenance snapshot taken before Exchange Server maintenance"` |
| `snapshot_retention_days` | Integer | Days until snapshot removal | Any positive integer | `7` |
| `my_snapshot_removal_date` | String | Date to remove snapshot (calculated) | `MM/DD/YYYY` | `"11/10/2025"` |
| `remove_prev_snapshots` | Boolean | Remove previous snapshots | `true` or `false` | `true` |

### Usage Example

**Job Template Configuration:**
```yaml
extra_vars:
  my_snapshot_name: "Exchange-PreMaint-{{ ansible_date_time.date }}"
  my_description: "Pre-maintenance snapshot taken before Exchange Server maintenance"
  snapshot_retention_days: 7  # Days until removal
  remove_prev_snapshots: true
```

**Playbook Implementation:**
```yaml
- name: Take Exchange Server Snapshot
  hosts: all
  gather_facts: yes
  vars:
    # Calculate removal date from snapshot_retention_days
    my_snapshot_removal_date: "{{ '%m/%d/%Y' | strftime(ansible_date_time.epoch | int + (snapshot_retention_days | default(7) * 86400)) }}"
  
  tasks:
    - name: Create VM Snapshot
      ansible.builtin.include_role:
        name: ENTERPRISE.Common.TakeASnapshot
```

### Variable Details

#### `my_snapshot_name`
- **Purpose**: Identifies the snapshot in vCenter
- **Best Practice**: Include date and purpose in name
- **Template Variables**: Can use Ansible facts like `{{ ansible_date_time.date }}`

#### `my_description`
- **Purpose**: Provides context for the snapshot
- **Best Practice**: Include reason for snapshot and any relevant details

#### `snapshot_retention_days`
- **Purpose**: Number of days to keep the snapshot before automatic deletion
- **Format**: Integer (number of days)
- **Default**: 7 days
- **Best Practice**: 7 days for maintenance snapshots, longer for major changes

#### `my_snapshot_removal_date`
- **Purpose**: Schedules automatic snapshot deletion
- **Format**: Must be `MM/DD/YYYY` (e.g., `11/10/2025`)
- **Calculated**: Automatically computed in playbook from `snapshot_retention_days`
- **Formula**: Current date + (snapshot_retention_days × 86400 seconds)
  ```jinja2
  my_snapshot_removal_date: "{{ '%m/%d/%Y' | strftime(ansible_date_time.epoch | int + (snapshot_retention_days * 86400)) }}"
  ```
- **Examples**:
  - `snapshot_retention_days: 7` → 7 days from now
  - `snapshot_retention_days: 14` → 14 days from now
  - `snapshot_retention_days: 30` → 30 days from now

#### `remove_prev_snapshots`
- **Purpose**: Controls cleanup of old snapshots
- **Default**: `true` (recommended for maintenance workflows)
- **When `true`**: Removes any previous snapshots with similar names
- **When `false`**: Keeps all existing snapshots (use with caution - disk space)

### Snapshot Lifecycle

```
Day 0 (Maintenance - Nov 3, 2025):
  - Job template sets: snapshot_retention_days: 7
  - Playbook calculates: my_snapshot_removal_date: "11/10/2025"
  - Create snapshot: "Exchange-PreMaint-2025-11-03"
  - Remove previous snapshots: Yes

Day 1-6:
  - Snapshot available for rollback if issues arise
  
Day 7 (Nov 10, 2025):
  - Automatic removal at midnight
  - Frees up datastore space
```

### Why Use snapshot_retention_days Instead of Hardcoded Date?

**Reason**: `ansible_date_time` facts are only available during playbook execution, not when defining job templates in AAP.

**Solution**:
1. Job template passes `snapshot_retention_days` (e.g., 7)
2. Playbook gathers facts (gets current date/time)
3. Playbook calculates `my_snapshot_removal_date` using the formula
4. Role receives properly formatted MM/DD/YYYY date

**Benefits**:
- ✅ Works correctly in AAP workflows
- ✅ Easy to adjust retention period
- ✅ No hardcoded dates that become stale
- ✅ Consistent calculation every time

---

## Windows Collection Variables

The Windows collection job templates use phase-based execution with skip flags. These are automatically set by the workflow and typically don't need manual override.

### Common Windows Variables

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `exchange_maintenance_phase` | String | Current phase identifier | `"preparation"`, `"database_check"`, etc. |
| `interactive_mode` | Boolean | Enable interactive prompts | `false` (AAP always uses false) |
| `exchange_skip_preparation` | Boolean | Skip preparation phase | `true` |
| `exchange_skip_database_movement` | Boolean | Skip database movement | `true` |
| `exchange_skip_maintenance_mode` | Boolean | Skip maintenance mode | `true` |
| `exchange_skip_queue_monitoring` | Boolean | Skip queue monitoring | `true` |
| `exchange_skip_service_management` | Boolean | Skip service management | `true` |

---

## Workflow-Specific Variable Usage

### Main Maintenance Workflow

**Step 2 - Mute Alerts:**
```json
{
  "nodestatus": "mute",
  "maintenance_window_duration": 120,
  "hours": "{{ (maintenance_window_duration | default(120) / 60) | round(0, 'ceil') | int }}"
}
```

*Note: The `hours` value is calculated from `maintenance_window_duration` (120 minutes = 2 hours)*

**Step 3 - Create Snapshot:**
```json
{
  "my_snapshot_name": "Exchange-PreMaint-{{ ansible_date_time.date }}",
  "my_description": "Pre-maintenance snapshot taken before Exchange Server maintenance",
  "snapshot_retention_days": 7,
  "remove_prev_snapshots": true
}
```

*Note: The playbook will calculate `my_snapshot_removal_date` from `snapshot_retention_days` at runtime*

**Step 11 - Unmute Alerts:**
```json
{
  "nodestatus": "unmute"
}
```

### Early Finish Workflow

**Step 3 - Unmute Alerts:**
```json
{
  "nodestatus": "unmute"
}
```

---

## Troubleshooting

### SolarWinds Issues

**Problem**: Alerts don't mute
- Verify `nodestatus` is exactly `"mute"` (lowercase, quoted)
- Check SolarWinds API credentials in AAP
- Verify node names match between inventory and SolarWinds

**Problem**: Auto-unmute doesn't work
- Check `hours` is a positive integer
- Verify SolarWinds API is accessible
- Check SolarWinds scheduled task configuration

### Snapshot Issues

**Problem**: Snapshot creation fails
- Verify `my_snapshot_removal_date` is in `MM/DD/YYYY` format
- Check vCenter credentials
- Ensure sufficient datastore space
- Verify VM is powered on

**Problem**: Old snapshots not removed
- Check `remove_prev_snapshots` is `true`
- Verify snapshot naming pattern matches
- Check vCenter permissions for snapshot deletion

---

## Best Practices

1. **Always use quoted strings** for `nodestatus` values
2. **Set removal dates** for all snapshots to prevent disk space issues
3. **Use consistent naming** for snapshots to enable proper cleanup
4. **Test variables** in a non-production environment first
5. **Document any custom values** in your AAP job template descriptions
6. **Monitor SolarWinds** to verify mute/unmute actions complete
7. **Check vCenter** after snapshot creation to verify success
