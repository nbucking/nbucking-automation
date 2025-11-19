# Exchange Backup Role

Backs up Exchange database files (EDB and logs) from the server with `exchange_database_preference: 1`. Handles automatic database movement if the active database is on the backup target and cycles logs after successful backup.

## Requirements

- Ansible 2.9 or higher
- Windows Server 2016/2019/2022+
- Exchange Server 2016/2019/SE
- `win_exchange` module
- Access to backup DFS shares
- Sufficient disk space on backup target and DFS share

## Role Variables

### Required Variables

- `target_database` - Name of the Exchange database (e.g., `EXAMPLE-MB01`)
- `environment_type` - Environment: `production` or `preproduction`

### Configuration from group_vars

```yaml
backup_settings:
  enabled: true                                    # Enable backups
  backup_only_active_database: true               # Only backup server with preference: 1
  edb_path: "edbfilepath"                          # Database file path
  log_path: "logfolderpath"                        # Log file path
  backup_locations:
    preproduction: "\\services.ppstamp.example.com\stamp\Admin_Area\Exchange\Backups"
    production: "\\services.stamp.tsa.dhs.gov\Stamp\Admin Area\Exchange\Backups"
  retention_policy: "cycle_logs_after_backup"     # Cycle logs to reclaim space
  schedule: "before_maintenance_window"
```

### Inventory Configuration

```yaml
exchange_servers:
  hosts:
    exchange-prod-01:
      exchange_database_preference: 1   # Primary - will be backed up
    exchange-prod-02:
      exchange_database_preference: 2   # Secondary
```

## Usage

### Basic Backup

```yaml
- name: Backup Exchange database
  ansible.builtin.include_role:
    name: ENTERPRISE.Windows.exchange-backup
  vars:
    target_database: "EXAMPLE-MB01"
    environment_type: "production"
```

### In Maintenance Workflow

```yaml
- name: Phase 0 - Pre-maintenance Backup
  ansible.builtin.include_role:
    name: ENTERPRISE.Windows.exchange-backup
  vars:
    target_database: "{{ selected_database }}"
    environment_type: "{{ environment_type }}"
  tags:
    - backup
    - pre-maintenance
```

## Backup Process

1. **Identify Backup Target**: Finds the server with `exchange_database_preference: 1`
2. **Check Active Database**: Determines if the active database is on the backup target
3. **Move if Needed**: Automatically moves the database to another server (preference > 1)
4. **Create Backup**: Uses Windows Backup (wbadmin) with VSS Full to backup EDB and log files (4+ hours for large databases)
5. **Organize**: Creates dated subdirectories (YYYY-MM-DD_HHMMSS format)
6. **Log Truncation**: Automatic via Windows Backup VSS Full (no manual cycling required)
7. **Manifest**: Creates a backup manifest file with metadata

## Backup File Structure

```
\\services.ppstamp.example.com\stamp\Admin_Area\Exchange\Backups\
└── 2025-11-06\                                    (Date-based)
    ├── EDB_20251106_093045\                       (Timestamp)
    │   ├── Database1.edb
    │   ├── Database1.chk
    │   └── ...
    ├── LOGS_20251106_093045\                      (Timestamp)
    │   ├── E0000001.log
    │   ├── E0000002.log
    │   └── ...
    └── BACKUP_MANIFEST_20251106_093045.txt        (Metadata)
```

## Features

- **Selective Backup**: Only backs up the active database holder (preference: 1)
- **Automatic Movement**: Moves active database if needed to allow backup
- **Log Cycling**: Truncates Exchange logs to reclaim disk space
- **DFS Integration**: Backs up to environment-specific DFS-replicated shares
- **Manifest Tracking**: Creates backup metadata for recovery reference
- **Timestamped**: All backups timestamped for easy organization
- **Error Handling**: Validates backup success and reports detailed status

## Database Movement

If the active database is on the backup target server:

1. Role finds an alternate server (preference > 1)
2. Moves database using `Move-ActiveMailboxDatabase`
3. Waits 30 seconds for move to complete
4. Proceeds with backup on now-inactive target

**Example**:
- Backup target: exchange-prod-01 (preference: 1)
- Active database is on exchange-prod-01
- Role automatically moves to exchange-prod-02 (preference: 2)
- Backs up exchange-prod-01

## Log Truncation

Windows Backup with VSS Full automatically truncates transaction logs:

1. **VSS Full Backup**: Creates a complete backup using Volume Shadow Copy Service
2. **Automatic Log Truncation**: Windows Backup truncates committed logs after successful backup
3. **No Manual Cycling Required**: The backup process handles log cleanup automatically

**Command Used**: `wbadmin start backup -backupTarget:"path" -include:"edb_path","log_path" -vssFull -quiet`

## Backup Locations

### Pre-Production (PPD)
```
\\services.ppstamp.example.com\stamp\Admin_Area\Exchange\Backups
```
Note: `Admin_Area` (underscore) for PPD

### Production (ENTERPRISE)
```
\\services.stamp.tsa.dhs.gov\Stamp\Admin Area\Exchange\Backups
```
Note: `Admin Area` (space) for ENTERPRISE

## Variables Reference

| Variable | Default | Description |
|----------|---------|-------------|
| `target_database` | Required | Exchange database name |
| `environment_type` | Required | `production` or `preproduction` |
| `backup_timestamp` | Auto | Generated backup timestamp |
| `backup_target_server` | Auto | Server with preference: 1 |
| `backup_share_path` | From group_vars | DFS share path |
| `backup_subdirectory` | Auto | Date-based subdirectory |

## Troubleshooting

### "No server found with exchange_database_preference: 1"
- Check inventory configuration
- Verify `exchange_database_preference` is set on all servers
- Ensure at least one server has preference: 1

### "Backup failed - check file permissions"
- Verify DFS share is accessible from backup target server
- Check folder permissions on DFS share
- Verify Ansible service account has write access

### "Database move failed"
- Check if alternate servers are available
- Verify no maintenance mode is active on alternate servers
- Review Exchange logs for move failures

### "Windows Backup failed"
- Check Event Logs for detailed error information
- Verify Windows Backup service is running
- Ensure sufficient disk space on backup target and source
- Check DFS share permissions and connectivity

## Integration with Maintenance Workflow

Typically called before maintenance mode:

```yaml
- name: Phase 0 - Pre-maintenance Backup
  ansible.builtin.include_role:
    name: ENTERPRISE.Windows.exchange-backup
  tags: [backup]

- name: Phase 1 - Preparation
  ansible.builtin.include_role:
    name: ENTERPRISE.Windows.exchange-prep
  tags: [prep]

- name: Phase 2 - Database Management
  ansible.builtin.include_role:
    name: ENTERPRISE.Windows.exchange-database-management
  tags: [database]

# ... rest of maintenance
```

## Dependencies

None

## License

MIT

## Author

ENTERPRISE Automation Team  
ENTERPRISE Automation Team
