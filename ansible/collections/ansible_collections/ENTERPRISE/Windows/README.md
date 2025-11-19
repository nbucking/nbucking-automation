# ENTERPRISE.Windows Ansible Collection

<div align="center">

![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)
![Exchange](https://img.shields.io/badge/Microsoft_Exchange-0078D4?style=for-the-badge&logo=microsoft-exchange&logoColor=white)

### 🔷 Enterprise Windows Automation Collection 🔷

**Production-grade Ansible collection for Exchange Server maintenance and Windows infrastructure automation**

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Ansible](https://img.shields.io/badge/ansible-%3E%3D2.9-black.svg)](https://www.ansible.com/)
[![Windows Server](https://img.shields.io/badge/Windows%20Server-2016%20%7C%202019%20%7C%202022-blue)](https://www.microsoft.com/windows-server)

</div>

---

This collection provides Windows automation tools for enterprise environments, with a focus on Microsoft Exchange Server maintenance and Active Directory operations.

## Overview

The ENTERPRISE.Windows collection includes:

- **Exchange Server Maintenance**: Comprehensive automation for Exchange 2016, 2019, and Subscription Edition
- **Active Directory Operations**: User, group, and domain management
- **Windows System Management**: Service management, file operations, and system configuration
- **Custom PowerShell Modules**: Native Windows PowerShell integration

## Supported Platforms

- **Exchange Server**: 2016, 2019, Subscription Edition (SE)
- **Windows Server**: 2016, 2019, 2022
- **PowerShell**: 5.1+
- **Ansible**: 2.9+

## Installation

### From Ansible Galaxy (when published)
```bash
ansible-galaxy collection install ENTERPRISE.Windows
```

### From Source
```bash
# Clone the repository
git clone https://github.com/your-org/stamp-windows-collection.git

# Install the collection
ansible-galaxy collection install /path/to/stamp-windows-collection
```

## Quick Start

### Exchange Maintenance Example
```yaml
---
- name: Exchange Server Maintenance
  hosts: exchange_servers
  collections:
    - ENTERPRISE.Windows
  tasks:
    - name: Get Exchange server information
      win_exchange:
        command: "Get-ExchangeServer"
      register: exchange_info
      
    - name: Display server info
      debug:
        msg: "{{ exchange_info.output }}"
```

## Included Content

### Modules

| Module | Description |
|--------|-------------|
| `win_exchange` | Execute Exchange PowerShell commands with native integration |

### Roles

| Role | Description |
|------|-------------|
| `exchange-prep` | Prepare Exchange environment for maintenance |
| `exchange-database-management` | Manage Exchange database operations |
| `exchange-maintenance-mode` | Control Exchange server maintenance mode |
| `exchange-queue-monitoring` | Monitor and export Exchange transport queues |
| `exchange-service-management` | Manage Exchange services |
| `exchange-backup` | ✅ NEW: Backup Exchange databases from active holder |
| `exchange-notification` | ✅ NEW: Send HTML email notifications (success, failure, cancellation) |

### Playbooks

| Playbook | Description |
|----------|-------------|
| `exchange-maintenance.yml` | Interactive Exchange maintenance workflow (CLI) |
| `exchange-maintenance-aap.yml` | AAP-compatible Exchange maintenance workflow |
| `exchange-maintenance-success.yml` | ✅ NEW: Success notification playbook |
| `maintenance-failure.yml` | Failure notification and escalation |
| `maintenance-cancelled.yml` | Cancellation confirmation |
| `manual-maintenance-window.yml` | Manual maintenance pause point |

## Usage Examples

### Basic Exchange Operations
```yaml
- name: Check Exchange server health
  ENTERPRISE.Windows.win_exchange:
    command: "Get-ServerHealth"
    parameters:
      Identity: "{{ ansible_hostname }}"
  register: health_result

- name: Move active database
  ENTERPRISE.Windows.win_exchange:
    command: "Move-ActiveMailboxDatabase"
    parameters:
      Identity: "DB01"
      ActivateOnServer: "SERVER02"
```

### Using Roles
```yaml
- name: Complete Exchange Maintenance
  hosts: exchange_servers
  collections:
    - ENTERPRISE.Windows
  roles:
    - role: exchange-prep
    - role: exchange-database-management
      vars:
        database_name: "EXAMPLE-MB01"
    - role: exchange-maintenance-mode
    - role: exchange-service-management
```

## Dependencies

This collection requires:

- `ansible.windows` (>=1.10.0)
- `community.windows`
- `microsoft.ad`

See `requirements.yml` for complete dependency list.

## Configuration

### Inventory Configuration
```ini
[exchange_servers]
exchange01.domain.com
exchange02.domain.com

[exchange_servers:vars]
ansible_connection=winrm
ansible_winrm_transport=kerberos
ansible_winrm_server_cert_validation=ignore
```

### Group Variables
```yaml
# group_vars/exchange_servers.yml
exchange_databases:
  - "PREPROD-MB01"  # Pre-production
  - "EXAMPLE-MB01"     # Production

maintenance_window_duration: 120  # minutes
auto_move_active_db: false
```

## AAP Integration

This collection is designed for Ansible Automation Platform (AAP) with:

- Pre-built workflows with approval gates
- Survey-driven parameter collection
- Comprehensive error handling and rollback
- Integration with external systems

### Workflow Templates
- Exchange Server Maintenance Workflow
- Database Movement Workflow  
- Emergency Rollback Workflow

## Development

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make changes with tests
4. Submit a pull request

### Testing
```bash
# Run collection tests
ansible-test sanity --docker
ansible-test units --docker
```

### Building
```bash
# Build collection tarball
ansible-galaxy collection build
```

## Support

### Documentation
- [Collection Documentation](https://your-docs-site.com/stamp-windows)
- [Exchange Maintenance Guide](docs/exchange-maintenance-guide.md)
- [AAP Integration Guide](docs/aap-integration-guide.md)

### Issues
- [GitHub Issues](https://github.com/your-org/stamp-windows-collection/issues)
- Internal ENTERPRISE Support Portal

## License

GNU General Public License v3.0 or later

See [LICENSE](LICENSE) file for full license text.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

---

**ENTERPRISE** - Enterprise Windows Automation Collection
