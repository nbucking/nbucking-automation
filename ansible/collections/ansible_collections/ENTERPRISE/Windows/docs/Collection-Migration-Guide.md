# Exchange Maintenance Collection Migration Guide

This guide explains how to migrate the Exchange maintenance automation to your existing ENTERPRISE Windows collection structure.

## Target Collection Structure

Your target structure should be:
```
Automation/collections/ansible_collections/ENTERPRISE/Windows/
├── galaxy.yml
├── meta/
│   └── runtime.yml
├── library/
│   └── win_exchange.ps1             # Custom Exchange PowerShell module
├── roles/
│   ├── exchange-prep/
│   ├── exchange-database-management/
│   ├── exchange-maintenance-mode/
│   ├── exchange-queue-monitoring/
│   └── exchange-service-management/
├── playbooks/                       # Collection playbooks
│   ├── exchange-maintenance-interactive.yml
│   ├── exchange-maintenance-batch.yml
│   ├── exchange-maintenance-aap.yml
│   ├── approval-gate.yml
│   ├── manual-maintenance-window.yml
│   ├── exchange-maintenance-completion.yml
│   ├── exchange-maintenance-rollback.yml
│   ├── maintenance-failure.yml
│   └── maintenance-cancelled.yml
├── inventories/                     # Collection inventories
│   ├── exchange-production/
│   └── exchange-preproduction/
└── group_vars/
    ├── exchange_servers.yml
    ├── exchange_production.yml
    └── exchange_preproduction.yml
```

## Migration Steps

### Step 1: Create Collection Directories
```powershell
# Navigate to your collection root
cd "Automation\collections\ansible_collections\ENTERPRISE\Windows"

# Create required directories
New-Item -Path "library" -ItemType Directory -Force
New-Item -Path "playbooks" -ItemType Directory -Force
New-Item -Path "inventories" -ItemType Directory -Force
New-Item -Path "group_vars" -ItemType Directory -Force
```

### Step 2: Move the Custom Module
```powershell
# Copy the win_exchange PowerShell module to the collection
Copy-Item "C:\Users\Nicholas.Buckingham\exchange-maintenance\library\win_exchange.ps1" `
          "library\win_exchange.ps1"
```

### Step 3: Move Roles
```powershell
# Copy all roles to the collection
$sourceRoles = "C:\Users\Nicholas.Buckingham\exchange-maintenance\roles"
$targetRoles = "roles"

# Copy each role
$roles = @(
    "exchange-prep",
    "exchange-database-management", 
    "exchange-maintenance-mode",
    "exchange-queue-monitoring",
    "exchange-service-management"
)

foreach ($role in $roles) {
    Copy-Item "$sourceRoles\$role" "$targetRoles\" -Recurse -Force
}
```

### Step 4: Move Playbooks
```powershell
# Copy playbooks to collection
$sourcePlaybooks = "C:\Users\Nicholas.Buckingham\exchange-maintenance\playbooks"
Copy-Item "$sourcePlaybooks\*" "playbooks\" -Recurse -Force
```

### Step 5: Move Inventories and Variables
```powershell
# Copy inventories
$sourceInventories = "C:\Users\Nicholas.Buckingham\exchange-maintenance\inventories"
Copy-Item "$sourceInventories\*" "inventories\" -Recurse -Force

# Copy group variables
$sourceGroupVars = "C:\Users\Nicholas.Buckingham\exchange-maintenance\group_vars"
Copy-Item "$sourceGroupVars\*" "group_vars\" -Recurse -Force
```

### Step 6: Update Collection Metadata

#### Update galaxy.yml
```yaml
namespace: ENTERPRISE
name: Windows
version: 1.0.0
readme: README.md
authors:
  - ENTERPRISE Automation Team
description: >-
  Windows automation collection including Exchange Server maintenance
license:
  - GPL-3.0-or-later
tags:
  - windows
  - exchange
  - maintenance
  - automation
dependencies: {}
repository: https://your-repo-url
documentation: https://your-docs-url
homepage: https://your-homepage-url
issues: https://your-issues-url
build_ignore: []
```

#### Update meta/runtime.yml
```yaml
requires_ansible: '>=2.9'
# Note: library/ modules don't require plugin_routing
# They are automatically available to roles and playbooks
```

## Usage After Migration

### In Playbooks
Once migrated, reference the module using the fully qualified collection name:

```yaml
---
- name: Exchange Maintenance Example
  hosts: exchange_servers
  collections:
    - ENTERPRISE.Windows
  tasks:
    # With library/ structure, modules are directly available
    - name: Get Exchange server information
      win_exchange:
        command: "Get-ExchangeServer"
      register: exchange_servers

    - name: Get mailbox databases
      win_exchange:
        command: "Get-MailboxDatabase"
```

### In Roles
Update your roles to reference the collection:

```yaml
# roles/exchange-prep/tasks/main.yml
---
- name: Load Exchange Management Tools
  win_exchange:
    command: "Get-ExchangeServer"
    parameters:
      Identity: "{{ ansible_hostname }}"
  register: exchange_server_info
```

### AAP Integration
Update your AAP job templates to use the collection:

```yaml
# In job template extra_vars
extra_vars:
  ansible_python_interpreter: auto_silent
  collections:
    - ENTERPRISE.Windows
```

## Role Dependencies Update

Update each role's `meta/main.yml` to reference the collection:

```yaml
# Example: roles/exchange-prep/meta/main.yml
---
galaxy_info:
  author: ENTERPRISE Automation Team
  description: Exchange Server preparation for maintenance
  company: ENTERPRISE
  license: GPL-3.0
  min_ansible_version: 2.9
  platforms:
    - name: Windows
      versions:
        - 2016
        - 2019
        - 2022
  galaxy_tags:
    - exchange
    - exchange-2016
    - exchange-2019
    - exchange-se
    - preparation
    - maintenance

dependencies: []

collections:
  - ENTERPRISE.Windows
```

## Playbook Updates

Update your main playbooks to use the collection:

```yaml
---
# playbooks/exchange-maintenance-aap.yml
- name: Exchange Server Maintenance - AAP Compatible
  hosts: "{{ target_exchange_server | default(groups['exchange_servers']) }}"
  collections:
    - ENTERPRISE.Windows
  gather_facts: true
  vars:
    target_database: "{{ target_database | default('EXAMPLE-MB01') }}"
  
  tasks:
    - name: Include Exchange preparation
      include_role:
        name: ENTERPRISE.Windows.exchange-prep
      when: not exchange_skip_preparation | default(false)
```

## Testing the Migration

### Test 1: Module Functionality
```yaml
---
- name: Test Exchange Module
  hosts: localhost
  collections:
    - ENTERPRISE.Windows
  tasks:
    - name: Test win_exchange module
      win_exchange:
        command: "Get-ExchangeServer"
      delegate_to: your-exchange-server
```

### Test 2: Role Functionality
```yaml
---
- name: Test Exchange Roles
  hosts: exchange_servers
  collections:
    - ENTERPRISE.Windows
  tasks:
    - name: Test exchange preparation role
      include_role:
        name: exchange-prep
```

### Test 3: Full Workflow
```bash
# Test the complete workflow
ansible-playbook ENTERPRISE.Windows.exchange-maintenance-batch \
  -i inventories/exchange-production \
  -e target_database=PREPROD-MB01
```

## AAP Collection Integration

### Collection Installation
```bash
# Install collection in AAP
ansible-galaxy collection install /path/to/ENTERPRISE-Windows-1.0.0.tar.gz
```

### Execution Environment
Update your execution environment to include the collection:

```dockerfile
# execution-environment/requirements.yml
---
collections:
  - name: ENTERPRISE.Windows
    version: ">=1.0.0"
```

### Project Configuration
Update AAP projects to reference collections:

```yaml
# In project configuration
collections:
  requirements_file: requirements.yml
  
# requirements.yml content
---
collections:
  - ENTERPRISE.Windows
```

## Benefits of Collection Structure

### 1. **Namespace Isolation**
- Prevents naming conflicts with other modules
- Clear ownership and organization

### 2. **Version Management**
- Proper versioning of automation components
- Dependency tracking and management

### 3. **Distribution**
- Easy sharing and deployment
- Standardized packaging format

### 4. **AAP Integration**
- Native support in AAP 2.x
- Better performance and caching

### 5. **Maintenance**
- Centralized location for all related components
- Easier updates and bug fixes

## Migration Checklist

- [ ] Create collection directory structure
- [ ] Move `win_exchange.ps1` to `library/`
- [ ] Copy all roles to collection `roles/` directory
- [ ] Move playbooks to collection `playbooks/` directory
- [ ] Copy inventories and variables
- [ ] Update `galaxy.yml` with proper metadata
- [ ] Update `meta/runtime.yml` for plugin routing
- [ ] Update role dependencies to reference collection
- [ ] Update playbooks to use collection namespace
- [ ] Test module functionality
- [ ] Test role execution
- [ ] Test complete workflow
- [ ] Update AAP job templates
- [ ] Update documentation

## Post-Migration Cleanup

After successful migration and testing:

1. **Remove old standalone files**
2. **Update documentation references**
3. **Notify team of new collection usage**
4. **Archive old project structure**
5. **Update CI/CD pipelines if applicable**

---

This migration will integrate your Exchange maintenance automation into the proper Ansible collection structure while maintaining all functionality and improving organization and maintainability.