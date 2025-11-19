# Exchange Database Management Role

## Description

Manages Exchange database operations during maintenance, including detecting active databases, moving them between servers, and handling database management decisions during maintenance workflows.

## Requirements

- Ansible 2.9 or higher
- Windows Server 2016/2019/2022/2025
- Exchange Server 2016/2019/SE
- `win_exchange` module

## Role Variables

### Required Variables

- `exchange_server_list` - List of Exchange servers in the environment
- `database_name` - Name of the database to manage
- `target_servers` - List of servers being targeted for maintenance

### Optional Variables

- `auto_move_active_db` - (default: `false`) Automatically move active databases without prompting
- `interactive_mode` - (default: `true`) Enable interactive prompts for database move decisions
- `move_database` - (default: `'no'`) Non-interactive decision: `yes`, `no`, or `auto`
- `target_server_index` - (default: `'1'`) Index of target server for non-interactive manual moves

## Features

- **Active Database Detection**: Identifies which server hosts the active copy of a database
- **Database Movement**: Moves active databases to different servers using `Move-ActiveMailboxDatabase`
- **Interactive Mode**: Prompts users for decisions about moving databases
- **Auto-Move Mode**: Automatically selects the best available server for database moves
- **Server Filtering**: Filters out servers with active databases from maintenance operations if database is not moved

## Usage

### Example Playbook

```yaml
- hosts: exchange_servers
  roles:
    - role: ENTERPRISE.Windows.exchange-database-management
      vars:
        database_name: "DB01"
        auto_move_active_db: false
        interactive_mode: true
```

### Non-Interactive Mode

```yaml
- hosts: exchange_servers
  roles:
    - role: ENTERPRISE.Windows.exchange-database-management
      vars:
        database_name: "DB01"
        interactive_mode: false
        move_database: "auto"
```

## Dependencies

None

## License

MIT

## Author

ENTERPRISE Automation Team  
ENTERPRISE Automation Team
