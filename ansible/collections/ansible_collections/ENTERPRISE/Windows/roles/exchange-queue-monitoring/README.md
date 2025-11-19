# Exchange Queue Monitoring Role

## Description

Monitors Exchange message queues during maintenance operations. This role iterates through target servers and performs queue monitoring checks using a sub-task workflow.

## Requirements

- Ansible 2.9 or higher
- Windows Server 2016/2019/2022/2025
- Exchange Server 2016/2019/SE
- `win_exchange` module

## Role Variables

### Required Variables

- `target_servers` - List of servers to monitor queues on

## Features

- **Queue Monitoring**: Monitors message queues on specified Exchange servers
- **Multi-Server Support**: Iterates through multiple target servers
- **Sub-Task Integration**: Uses `server_queue_monitoring.yml` for actual monitoring operations

## Usage

### Example Playbook

```yaml
- hosts: exchange_servers
  roles:
    - role: ENTERPRISE.Windows.exchange-queue-monitoring
      vars:
        target_servers:
          - EXCH01
          - EXCH02
```

This role is typically used during maintenance workflows to ensure message queues are draining properly before proceeding with maintenance operations.

## Dependencies

None

## License

MIT

## Author

ENTERPRISE Automation Team  
ENTERPRISE Automation Team
