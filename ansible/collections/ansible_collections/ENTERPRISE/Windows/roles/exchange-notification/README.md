# Exchange Notification Role

Sends HTML email notifications for Exchange maintenance events. Replaces inline playbook email logic with a reusable, modular role.

## Requirements

- Ansible 2.9 or higher
- `community.general.mail` module
- SMTP server access (configured in group_vars)

## Role Variables

### Required Variables

- `notification_type` - Type of notification: `success`, `failure`, or `cancellation`
- `target_database` - Name of the Exchange database (e.g., `EXAMPLE-MB01`)
- `environment_type` - Environment: `production` or `preproduction`

### Optional Variables

- `recipient_emails` - List of email addresses (defaults to `notifications.default_contacts`)
- `smtp_server` - SMTP server address (defaults from group_vars)
- `smtp_port` - SMTP port (defaults to 25)
- `from_address` - Sender email address (defaults from group_vars)
- `failure_reason` - Reason for failure (for failure notifications)
- `failure_severity` - Severity level: CRITICAL or WARNING (defaults based on environment)
- `cancellation_reason` - Reason for cancellation (for cancellation notifications)
- `change_request_number` - Change request ID (optional, included in email)
- `maintenance_reason` - Reason for maintenance (optional, included in success email)
- `tower_job_id` - AAP job ID (optional, included in email)
- `completion_time` - Completion timestamp (optional, defaults to current time)

## Group Variables Required

```yaml
notifications:
  email_enabled: true
  smtp_server: "smtp.services.stamp.tsa.dhs.gov"
  smtp_port: 25
  from_address: "ansible-automation@stamp.tsa.dhs.gov"
  default_contacts:
    - "stampwinsysadmin@tsa.dhs.gov"
    - "stampautomation@tsa.dhs.gov"
```

## Usage Examples

### Success Notification

```yaml
- name: Send success notification
  ansible.builtin.include_role:
    name: ENTERPRISE.Windows.exchange-notification
  vars:
    notification_type: "success"
    target_database: "EXAMPLE-MB01"
    environment_type: "production"
    change_request_number: "CHG12345"
    maintenance_reason: "Windows updates and Exchange patches"
```

### Failure Notification

```yaml
- name: Send failure notification
  ansible.builtin.include_role:
    name: ENTERPRISE.Windows.exchange-notification
  vars:
    notification_type: "failure"
    target_database: "PREPROD-MB01"
    environment_type: "preproduction"
    failure_reason: "Database move failed - insufficient disk space"
    failure_severity: "ERROR"
```

### Cancellation Notification

```yaml
- name: Send cancellation notification
  ansible.builtin.include_role:
    name: ENTERPRISE.Windows.exchange-notification
  vars:
    notification_type: "cancellation"
    target_database: "EXAMPLE-MB01"
    environment_type: "production"
    cancellation_reason: "User cancelled workflow due to scheduling conflict"
```

## Features

- **Three notification types**: Success, Failure, and Cancellation
- **HTML email templates**: Professional formatted emails with colored headers
- **Environment awareness**: Different severity levels for production vs. preproduction
- **Default recipients**: Uses organization-wide contacts automatically
- **Customizable**: Easy to override recipients or add custom information
- **Error handling**: Gracefully handles missing SMTP configuration
- **Reusable**: Single role replaces multiple inline mail tasks

## Email Templates

### Success Notification Template
- Green header indicating success
- Maintenance summary with status checks
- List of performed actions
- Change request and support contact information

### Failure Notification Template
- Red header for production, orange for preproduction
- Failure reason with highlighted error message
- Critical production warning banner
- Immediate action items and troubleshooting steps
- Links to support contacts

### Cancellation Notification Template
- Blue header indicating cancellation
- Cancellation reason
- Server status confirmation
- Rescheduling instructions
- Support contact information

## Migration from Inline Playbook Email

### Before (Playbook with inline mail):
```yaml
- name: Send email notification
  mail:
    to: "{{ notification_email }}"
    subject: "[SUCCESS] Exchange Maintenance Completed"
    body: "{{ email_body }}"
    from: "ansible@{{ ansible_domain }}"
```

### After (Using notification role):
```yaml
- name: Send success notification
  ansible.builtin.include_role:
    name: ENTERPRISE.Windows.exchange-notification
  vars:
    notification_type: "success"
    target_database: "{{ target_database }}"
    environment_type: "{{ environment_type }}"
```

**Benefits:**
- ✅ Consistent email formatting across all notifications
- ✅ Centralized maintenance of email templates
- ✅ Reusable in any playbook or workflow
- ✅ Easier to test and debug
- ✅ Professional HTML emails
- ✅ Reduced playbook complexity

## Dependencies

None

## License

MIT

## Author

ENTERPRISE Automation Team  
ENTERPRISE Automation Team
