# Exchange Service Management Role

## Description

Manages Exchange services during maintenance operations. This role iterates through target servers and handles service status checks and management using a sub-task workflow.

## Requirements

- Ansible 2.9 or higher
- Windows Server 2016/2019/2022/2025
- Exchange Server 2016/2019/SE
- `win_exchange` module

## Role Variables

### Required Variables

- `target_servers` - List of servers to manage services on

## Features

- **Service Management**: Manages Exchange service states on specified servers
- **Multi-Server Support**: Iterates through multiple target servers
- **Sub-Task Integration**: Uses `server_service_management.yml` for actual service management operations

## Usage

### Example Playbook

```yaml
- hosts: exchange_servers
  roles:
    - role: ENTERPRISE.Windows.exchange-service-management
      vars:
        target_servers:
          - EXCH01
          - EXCH02
```

This role is typically used during maintenance workflows to check service status and start services after maintenance operations are complete.

## Dependencies

None

## License

MIT

## Author

ENTERPRISE Automation Team  
ENTERPRISE Automation Team
