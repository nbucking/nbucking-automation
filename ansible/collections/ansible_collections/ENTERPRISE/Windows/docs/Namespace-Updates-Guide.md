# Namespace Updates Guide

This guide shows how to update all role task files to use proper FQCN (Fully Qualified Collection Names) for modules.

## Current Module Usage

Your roles currently use these modules:
- `win_exchange` (custom module)
- `win_file` (Ansible Windows collection)
- `set_fact` (Ansible built-in)
- `debug` (Ansible built-in)
- `pause` (Ansible built-in)
- `meta` (Ansible built-in)
- `include_role` (Ansible built-in)

## Required Namespace Updates

When migrating to the ENTERPRISE.Windows collection, you need to update module references to use proper namespacing.

### Option 1: Fully Qualified Collection Names (FQCN)

Use complete namespace for all modules:

```yaml
# Before:
- name: Clean old txt files from c:\temp
  win_file:
    path: "c:\\temp\\{{ item }}"
    state: absent
  loop:
    - "Queue_*.txt"
  register: cleanup_result

- name: Load Exchange Management snap-in
  win_exchange:
    command: "Get-ExchangeServer"
    output_format: "json"
  register: exchange_servers

- name: Display results
  debug:
    msg: "Found servers: {{ exchange_servers.output }}"

# After (with full FQCN):
- name: Clean old txt files from c:\temp
  ansible.windows.win_file:
    path: "c:\\temp\\{{ item }}"
    state: absent
  loop:
    - "Queue_*.txt"
  register: cleanup_result

- name: Load Exchange Management snap-in
  ENTERPRISE.Windows.win_exchange:
    command: "Get-ExchangeServer"
    output_format: "json"
  register: exchange_servers

- name: Display results
  ansible.builtin.debug:
    msg: "Found servers: {{ exchange_servers.output }}"

- name: Set server fact
  ansible.builtin.set_fact:
    server_list: "{{ exchange_servers.output | from_json }}"
```

### Option 2: Collection Declaration (Recommended)

Declare collections at the play or role level:

```yaml
# At the beginning of each role's tasks/main.yml
---
# Collection declarations for complete FQCN support
- name: Set up collections for this role
  ansible.builtin.meta: noop
  vars:
    ansible_collections:
      - ansible.builtin
      - ansible.windows
      - community.windows
      - microsoft.ad
      - ENTERPRISE.Windows

# Then use short names (resolved via collections):
- name: Clean old txt files from c:\temp
  win_file:  # Resolves to ansible.windows.win_file
    path: "c:\\temp\\{{ item }}"
    state: absent
  loop:  # Built-in keyword
    - "Queue_*.txt"
  register: cleanup_result  # Built-in keyword

- name: Load Exchange Management snap-in
  win_exchange:  # Resolves to ENTERPRISE.Windows.win_exchange
    command: "Get-ExchangeServer"
    output_format: "json"
  register: exchange_servers

- name: Display results
  debug:  # Resolves to ansible.builtin.debug
    msg: "Found servers: {{ exchange_servers.output }}"

- name: Set server fact
  set_fact:  # Resolves to ansible.builtin.set_fact
    server_list: "{{ exchange_servers.output | from_json }}"
```

### Option 3: Playbook-Level Collections (Best for Workflows)

Declare collections in your main playbooks:

```yaml
---
- name: Exchange Server Maintenance
  hosts: exchange_servers
  collections:
    - ansible.builtin      # For set_fact, debug, pause, meta, include_role
    - ansible.windows      # For win_file, win_service, win_shell
    - community.windows    # For extended Windows functionality
    - microsoft.ad         # For Active Directory operations (if needed)
    - ENTERPRISE.Windows        # For custom win_exchange module
  gather_facts: true
  
  tasks:
    - name: Include Exchange preparation
      include_role:         # Uses ansible.builtin.include_role
        name: exchange-prep
        
    - name: Set maintenance start time
      set_fact:            # Uses ansible.builtin.set_fact
        maintenance_start: "{{ ansible_date_time.iso8601 }}"
        
    - name: Display maintenance info
      debug:               # Uses ansible.builtin.debug
        msg: "Starting Exchange maintenance at {{ maintenance_start }}"
```

## Complete Module Namespace Reference

### Core Modules Used in Exchange Maintenance

| Module | Current Usage | FQCN | Collection |
|--------|---------------|------|------------|
| `win_exchange` | Custom module | `ENTERPRISE.Windows.win_exchange` | ENTERPRISE.Windows |
| `win_file` | Windows module | `ansible.windows.win_file` | ansible.windows |
| `win_service` | Windows module | `ansible.windows.win_service` | ansible.windows |
| `win_shell` | Windows module | `ansible.windows.win_shell` | ansible.windows |
| `win_powershell` | Windows module | `ansible.windows.win_powershell` | ansible.windows |
| `set_fact` | Built-in | `ansible.builtin.set_fact` | ansible.builtin |
| `debug` | Built-in | `ansible.builtin.debug` | ansible.builtin |
| `pause` | Built-in | `ansible.builtin.pause` | ansible.builtin |
| `meta` | Built-in | `ansible.builtin.meta` | ansible.builtin |
| `include_role` | Built-in | `ansible.builtin.include_role` | ansible.builtin |
| `loop` | Built-in keyword | N/A | ansible.builtin |
| `when` | Built-in keyword | N/A | ansible.builtin |
| `register` | Built-in keyword | N/A | ansible.builtin |

### Available Collections in Your Environment

| Collection | Version | Primary Use Case |
|------------|---------|------------------|
| `ansible.builtin` | Core | Built-in modules (set_fact, debug, etc.) |
| `ansible.windows` | Latest | Windows system management |
| `ansible.utils` | Latest | Network and utility functions |
| `ansible.netcommon` | Latest | Network automation common functions |
| `ansible.controller` | Latest | AAP/Tower automation |
| `community.general` | Latest | General community modules |
| `community.windows` | Latest | Extended Windows functionality |
| `community.vmware` | 4.5.0 | VMware infrastructure management |
| `community.crypto` | Latest | Certificate and encryption management |
| `microsoft.ad` | Latest | Active Directory management |
| `cisco.fmcansible` | Latest | Cisco FMC firewall management |
| `redhat.satellite` | Latest | Red Hat Satellite management |
| `ENTERPRISE.Windows` | 1.0.0 | Custom ENTERPRISE Windows automation |

## Role-by-Role Updates

### exchange-prep Role
```yaml
---
# tasks/main.yml with collections
- name: Set up collections
  ansible.builtin.meta: noop
  vars:
    ansible_collections:
      - ansible.builtin
      - ansible.windows
      - community.windows
      - microsoft.ad
      - ENTERPRISE.Windows

- name: Clean old txt files from c:\temp
  ansible.windows.win_file:
    path: "c:\\temp\\{{ item }}"
    state: absent
  loop:
    - "Queue_*.txt"
    - "ServerComponentState_*.txt" 
    - "Services_*.txt"
  ignore_errors: true

- name: Load Exchange Management snap-in
  ENTERPRISE.Windows.win_exchange:
    command: "Get-ExchangeServer"
    output_format: "json"
  register: exchange_servers_raw

- name: Parse Exchange servers
  ansible.builtin.set_fact:
    exchange_servers: "{{ (exchange_servers_raw.output | from_json) | map(attribute='Name') | list }}"

- name: Display Exchange servers found
  ansible.builtin.debug:
    msg: "Found Exchange servers: {{ exchange_servers | join(', ') }}"
```

### exchange-database-management Role
```yaml
---
# tasks/main.yml with collections
- name: Set up collections
  ansible.builtin.meta: noop
  vars:
    ansible_collections:
      - ansible.builtin
      - ansible.windows
      - community.windows
      - ENTERPRISE.Windows

- name: Get mailbox database copy status
  ENTERPRISE.Windows.win_exchange:
    command: "Get-MailboxDatabaseCopyStatus"
    parameters:
      Server: "{{ item }}"
    output_format: "json"
  register: db_status_results
  loop: "{{ exchange_server_list }}"
  when: exchange_server_list is defined

- name: Find active database server
  ansible.builtin.set_fact:
    active_database_info: >
      {{
        db_status_results.results
        | selectattr('output', 'defined')
        | map('extract', ['output'])
        | map('from_json')
        | flatten
        | selectattr('Status', 'equalto', 'Mounted')
        | selectattr('DatabaseName', 'equalto', database_name)
        | list
        | first
      }}
  when: 
    - db_status_results is defined
    - database_name is defined

- name: Display active database server
  ansible.builtin.debug:
    msg: "Active server for database '{{ database_name }}' is: {{ active_server }}"
```

### exchange-maintenance-mode Role
```yaml
---
# tasks/main.yml with collections  
- name: Set up collections
  meta: noop
  vars:
    ansible_collections:
      - ansible.windows
      - ENTERPRISE.Windows

- name: Set server component to maintenance
  win_exchange:  # Uses ENTERPRISE.Windows.win_exchange
    command: "Set-ServerComponentState"
    parameters:
      Identity: "{{ ansible_hostname }}"
      Component: "ServerWideOffline"
      State: "Draining"
      Requester: "Maintenance"
  register: maintenance_mode_result
```

### exchange-queue-monitoring Role
```yaml
---
# tasks/main.yml with collections
- name: Set up collections
  meta: noop
  vars:
    ansible_collections:
      - ansible.windows
      - ENTERPRISE.Windows

- name: Export queue information
  win_exchange:  # Uses ENTERPRISE.Windows.win_exchange
    command: "Get-Queue"
    output_format: "json"
  register: queue_status

- name: Save queue status to file
  win_file:  # Uses ansible.windows.win_file
    path: "c:\\temp\\Queue_{{ ansible_date_time.epoch }}.txt"
    content: "{{ queue_status.output }}"
```

### exchange-service-management Role
```yaml
---
# tasks/main.yml with collections
- name: Set up collections
  meta: noop
  vars:
    ansible_collections:
      - ansible.windows
      - ENTERPRISE.Windows

- name: Get Exchange service status
  win_service:  # Uses ansible.windows.win_service
    name: "{{ item }}"
  register: exchange_services
  loop:
    - "MSExchangeServiceHost"
    - "MSExchangeADTopology"
    - "MSExchangeIS"
    - "MSExchangeRPC"

- name: Check Exchange server health
  win_exchange:  # Uses ENTERPRISE.Windows.win_exchange  
    command: "Get-ServerHealth"
    parameters:
      Identity: "{{ ansible_hostname }}"
  register: server_health
```

## Automated Update Script

Here's a PowerShell script to automatically update your role files:

```powershell
# Update-RoleNamespaces.ps1
$roleFiles = Get-ChildItem "C:\Users\Nicholas.Buckingham\exchange-maintenance\roles" -Recurse -Name "main.yml" | 
    Where-Object { $_ -like "*tasks*" }

foreach ($roleFile in $roleFiles) {
    $fullPath = "C:\Users\Nicholas.Buckingham\exchange-maintenance\roles\$roleFile"
    $content = Get-Content $fullPath -Raw
    
    # Add collections declaration at the top
    $collectionsHeader = @"
---
# Collection declarations for proper module namespacing
- name: Set up collections for this role
  meta: noop
  vars:
    ansible_collections:
      - ansible.windows
      - ENTERPRISE.Windows

"@
    
    # Only add if not already present
    if ($content -notlike "*ansible_collections*") {
        # Remove existing --- if present and add our header
        $content = $content -replace "^---\s*`n", ""
        $content = $collectionsHeader + $content
        
        # Write back to file
        Set-Content -Path $fullPath -Value $content -Encoding UTF8
        Write-Host "Updated: $roleFile"
    }
}
```

## AAP Integration with Collections

### Execution Environment Requirements

Update your execution environment `requirements.yml` to include all collections:

```yaml
---
collections:
  # Core Ansible collections
  - name: ansible.windows
    version: ">=1.10.0"
  - name: ansible.utils
  - name: ansible.netcommon
  - name: ansible.controller
  
  # Community collections
  - name: community.general
  - name: community.windows
  - name: community.vmware
    version: "4.5.0"
  - name: community.crypto
  
  # Vendor-specific collections
  - name: microsoft.ad
  - name: cisco.fmcansible
  - name: redhat.satellite
  
  # Custom ENTERPRISE collection
  - name: ENTERPRISE.Windows  
    version: ">=1.0.0"
```

### Project Configuration

In your AAP project, ensure collection requirements:

```yaml
# collections/requirements.yml
---
collections:
  - ansible.windows
  - ENTERPRISE.Windows
```

## Testing Namespace Updates

### Test Individual Roles
```bash
ansible-playbook -i localhost, test-role.yml -e ansible_connection=local

# test-role.yml content:
---
- name: Test Role with Collections
  hosts: localhost
  collections:
    - ansible.windows
    - ENTERPRISE.Windows
  tasks:
    - name: Test role execution
      include_role:
        name: exchange-prep
```

### Test Complete Workflow
```bash
# Test with your collection
ansible-playbook -i inventories/exchange-preproduction ENTERPRISE.Windows.exchange-maintenance-batch \
  -e target_database=PREPROD-MB01 \
  -e collections='["ansible.windows", "ENTERPRISE.Windows"]'
```

## Validation Checklist

- [ ] All `win_exchange` calls work with ENTERPRISE.Windows collection
- [ ] All `win_file` calls work with ansible.windows collection
- [ ] All `win_service` calls work with ansible.windows collection
- [ ] Collections are declared in playbooks or roles
- [ ] AAP execution environment includes required collections
- [ ] Test runs complete successfully
- [ ] No module resolution errors in logs

## Benefits of Proper Namespacing

1. **✅ Clear Dependencies** - Explicit about which collections are needed
2. **✅ Version Control** - Can specify exact collection versions  
3. **✅ Conflict Prevention** - Avoid module name collisions
4. **✅ AAP Compatibility** - Better integration with AAP 2.x
5. **✅ Future Proofing** - Ready for collection updates and changes

This ensures your Exchange maintenance automation works reliably in the ENTERPRISE.Windows collection environment!