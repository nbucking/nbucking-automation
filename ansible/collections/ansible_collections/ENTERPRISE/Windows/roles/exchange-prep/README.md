# Exchange Prep Role

## Description

Prepares the Exchange environment for maintenance operations by cleaning up temporary files, ensuring required directories exist, and gathering information about all Exchange servers in the environment.

## Requirements

- Ansible 2.9 or higher
- Windows Server 2016/2019/2022/2025
- Exchange Server 2016/2019/SE
- `win_exchange` module

## Role Variables

None required. This role sets the following facts for use by other roles:

- `exchange_server_list` - List of all Exchange server names in the environment

## Features

- **Cleanup Operations**: Removes old queue, component state, and service status files from `c:\temp`
- **Directory Management**: Ensures the `c:\temp` directory exists for output files
- **Server Discovery**: Retrieves and caches the list of all Exchange servers using `Get-ExchangeServer`

## Usage

### Example Playbook

```yaml
- hosts: exchange_servers
  roles:
    - role: ENTERPRISE.Windows.exchange-prep
```

This role is typically run first in maintenance workflows to prepare the environment and gather server information.

## Files Cleaned

The role removes the following file patterns from `c:\temp`:
- `Queue_*.txt`
- `ServerComponentState_*.txt`
- `Services_*.txt`

## Dependencies

None

## License

MIT

## Author

ENTERPRISE Automation Team  
ENTERPRISE Automation Team
