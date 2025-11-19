# Exchange Maintenance Mode Role

## Description

Puts Exchange servers into maintenance mode by redirecting connections, draining active queues, and setting server component states. This role handles the entire maintenance mode workflow including site selection and redirect server configuration.

## Requirements

- Ansible 2.9 or higher
- Windows Server 2016/2019/2022/2025
- Exchange Server 2016/2019/SE
- `win_exchange` module

## Role Variables

### Required Variables

- `exchange_server_list` - List of all Exchange servers in the environment

### Optional Variables

- `interactive_mode` - (default: `true`) Enable interactive prompts for server and site selection
- `redirect_server_index` - (default: `'1'`) Index of redirect server for non-interactive mode
- `maintenance_site` - (default: `'localhost'`) Site selection for non-interactive mode: `localhost`, `AJ`, or `CS`

## Features

- **Redirect Server Selection**: Prompts user to select a server for redirect operations
- **Site-Based Targeting**: Supports maintenance on specific sites (localhost, AJ, CS)
- **Server Component Management**: Handles server component state changes
- **Interactive/Non-Interactive Modes**: Supports both interactive prompts and automated workflows

## Usage

### Example Playbook (Interactive)

```yaml
- hosts: exchange_servers
  roles:
    - role: ENTERPRISE.Windows.exchange-maintenance-mode
      vars:
        interactive_mode: true
```

### Example Playbook (Non-Interactive)

```yaml
- hosts: exchange_servers
  roles:
    - role: ENTERPRISE.Windows.exchange-maintenance-mode
      vars:
        interactive_mode: false
        redirect_server_index: "2"
        maintenance_site: "AJ"
```

## Site Options

- `localhost` - Only the current server
- `AJ` - All servers starting with "AJ"
- `CS` - All servers starting with "CS"

## Dependencies

None

## License

MIT

## Author

ENTERPRISE Automation Team  
ENTERPRISE Automation Team
