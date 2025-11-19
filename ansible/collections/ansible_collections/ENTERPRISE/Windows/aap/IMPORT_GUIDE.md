# How to Import Job Templates into Ansible Automation Platform

## Prerequisites

Before importing, ensure you have:

1. ✅ **AAP Access**: Admin or sufficient permissions to create templates
2. ✅ **Project Created**: "Automation Repo" project synced with your Git repository
3. ✅ **Organization**: "Credentialing" organization exists
4. ✅ **Inventory**: "Exchange Servers" inventory with your servers
5. ✅ **Credentials**: 
   - Windows Domain Admin
   - VMware vCenter
   - SolarWinds API

---

## Method 1: Using AWX CLI (Recommended for Bulk Import)

### Install AWX CLI

```bash
pip install awxkit
```

### Configure AWX CLI

```bash
# Set your AAP/AWX connection details
export CONTROLLER_HOST=https://your-aap-server.com
export CONTROLLER_USERNAME=admin
export CONTROLLER_PASSWORD=your-password

# Or use token authentication
export CONTROLLER_OAUTH_TOKEN=your-token

# Verify connection
awx --conf.host $CONTROLLER_HOST login
```

### Import Job Templates

```bash
# Navigate to the aap directory
cd /config/Automation-Stage/collections/ansible_collections/ENTERPRISE/Windows/aap

# Import all job templates from YAML
awx job_template create --file exchange_job_templates.yml

# Import workflows
awx workflow_job_template create --file exchange_workflow_job_template.yml
awx workflow_job_template create --file exchange_workflow_early_finish.yml
```

### Import Individual Templates

If you need to import one at a time:

```bash
# Example: Import Common: Create a VM Snapshot
awx job_template create \
  --name "Common: Create a VM Snapshot" \
  --description "Create VMware snapshot using ENTERPRISE.Common.TakeASnapshot role" \
  --job_type run \
  --inventory "Exchange Servers" \
  --project "Automation Repo" \
  --playbook "playbooks/common-snapshot.yml" \
  --credential "VMware vCenter" \
  --organization "Credentialing" \
  --extra_vars '{"my_snapshot_name": "Exchange-PreMaint-{{ ansible_date_time.date }}", "snapshot_retention_days": 7, "remove_prev_snapshots": true}' \
  --ask_variables_on_launch true \
  --verbosity 1
```

---

## Method 2: Using Ansible Playbook (Infrastructure as Code)

### Create Import Playbook

Create a file `import-templates.yml`:

```yaml
---
- name: Import Exchange Maintenance Job Templates to AAP
  hosts: localhost
  gather_facts: no
  vars:
    controller_host: "{{ lookup('env', 'CONTROLLER_HOST') }}"
    controller_username: "{{ lookup('env', 'CONTROLLER_USERNAME') }}"
    controller_password: "{{ lookup('env', 'CONTROLLER_PASSWORD') }}"
    validate_certs: false
  
  tasks:
    - name: Include job template definitions
      ansible.builtin.include_vars:
        file: exchange_job_templates.yml
      
    - name: Create job templates in AAP
      ansible.controller.job_template:
        name: "{{ item.job_template.name }}"
        description: "{{ item.job_template.description }}"
        job_type: "{{ item.job_template.job_type }}"
        inventory: "{{ item.job_template.inventory }}"
        project: "{{ item.job_template.project }}"
        playbook: "{{ item.job_template.playbook }}"
        credentials: "{{ item.job_template.credential }}"
        organization: "{{ item.job_template.organization }}"
        extra_vars: "{{ item.job_template.extra_vars | default({}) }}"
        ask_variables_on_launch: "{{ item.job_template.ask_variables_on_launch | default(false) }}"
        verbosity: "{{ item.job_template.verbosity | default(1) }}"
        state: present
      loop: "{{ lookup('file', 'exchange_job_templates.yml') | from_yaml }}"
      when: item.job_template is defined
```

### Run Import Playbook

```bash
ansible-playbook import-templates.yml
```

---

## Method 3: Using AAP Web UI (Manual Import)

### Step-by-Step for Each Template

1. **Navigate to Templates**
   - Log into AAP Web UI
   - Go to **Resources** → **Templates**
   - Click **Add** → **Add job template**

2. **Configure Template** (Example: Common: Create a VM Snapshot)
   
   **General:**
   - Name: `Common: Create a VM Snapshot`
   - Description: `Create VMware snapshot using ENTERPRISE.Common.TakeASnapshot role`
   - Job Type: `Run`
   
   **Details:**
   - Inventory: `Exchange Servers`
   - Project: `Automation Repo`
   - Playbook: `playbooks/common-snapshot.yml`
   - Credentials: `VMware vCenter`
   - Organization: `Credentialing`
   
   **Variables:**
   ```yaml
   my_snapshot_name: "Exchange-PreMaint-{{ ansible_date_time.date }}"
   my_description: "Pre-maintenance snapshot taken before Exchange Server maintenance"
   snapshot_retention_days: 7
   remove_prev_snapshots: true
   ```
   
   **Options:**
   - ☑️ Prompt on launch (Variables)
   - Verbosity: `1 (Verbose)`
   
3. **Save Template**

4. **Repeat for all 12 templates** (refer to `exchange_job_templates.yml` for details)

---

## Method 4: Using Ansible Automation Platform API

### Using cURL

```bash
# Set variables
AAP_HOST="https://your-aap-server.com"
AAP_TOKEN="your-api-token"

# Create job template
curl -X POST "${AAP_HOST}/api/v2/job_templates/" \
  -H "Authorization: Bearer ${AAP_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Common: Create a VM Snapshot",
    "description": "Create VMware snapshot using ENTERPRISE.Common.TakeASnapshot role",
    "job_type": "run",
    "inventory": 1,
    "project": 1,
    "playbook": "playbooks/common-snapshot.yml",
    "credential": 1,
    "organization": 1,
    "extra_vars": "{\"my_snapshot_name\": \"Exchange-PreMaint-{{ ansible_date_time.date }}\", \"snapshot_retention_days\": 7, \"remove_prev_snapshots\": true}",
    "ask_variables_on_launch": true,
    "verbosity": 1
  }'
```

### Using Python

```python
#!/usr/bin/env python3
import requests
import yaml

AAP_HOST = "https://your-aap-server.com"
AAP_TOKEN = "your-api-token"

headers = {
    "Authorization": f"Bearer {AAP_TOKEN}",
    "Content-Type": "application/json"
}

# Load template definitions
with open('exchange_job_templates.yml', 'r') as f:
    templates = yaml.safe_load(f)

# Create each template
for template_def in templates:
    if 'job_template' in template_def:
        template = template_def['job_template']
        
        # Resolve IDs for inventory, project, credential, org
        # (You'll need to query AAP API to get these IDs)
        
        response = requests.post(
            f"{AAP_HOST}/api/v2/job_templates/",
            headers=headers,
            json=template,
            verify=False
        )
        
        if response.status_code == 201:
            print(f"✅ Created: {template['name']}")
        else:
            print(f"❌ Failed: {template['name']} - {response.text}")
```

---

## Import Order

Import templates in this order to avoid dependency issues:

### 1. Common Collection Templates (2)
1. `Common: Create a VM Snapshot`
2. `Common: SolarWinds Node MX Mode`

### 2. Windows Collection Templates (10)
3. `Windows: Exchange Maintenance - Preparation Phase`
4. `Windows: Exchange Maintenance - Database Check`
5. `Windows: Exchange Maintenance - Database Movement`
6. `Windows: Exchange Maintenance - Enable Maintenance Mode`
7. `Windows: Exchange Maintenance - Queue Monitoring`
8. `Windows: Manual Maintenance Window`
9. `Windows: Exchange Maintenance - Service Management`
10. `Windows: Exchange Maintenance - Completion Phase`
11. `Windows: Exchange Maintenance - Rollback Maintenance Mode`
12. `Windows: Exchange Maintenance - Failure Notification`

### 3. Workflows (2)
13. `Windows: Exchange Server Maintenance Workflow`
14. `Windows: Exchange Server Maintenance Early Finish`

---

## Verification

After import, verify templates:

### Using AWX CLI

```bash
# List all templates
awx job_template list --name__icontains "Exchange"

# List workflows
awx workflow_job_template list --name__icontains "Exchange"

# Test a template
awx job_template launch --name "Common: Create a VM Snapshot" --monitor
```

### Using Web UI

1. Go to **Resources** → **Templates**
2. Filter by name: "Exchange" or "Common"
3. Verify all 12 job templates exist
4. Go to **Resources** → **Workflows**
5. Verify 2 workflows exist

### Test Run

1. Select `Windows: Exchange Maintenance - Preparation Phase`
2. Click **Launch**
3. Verify it runs successfully

---

## Troubleshooting

### Common Issues

**1. "Project not found"**
- Ensure "Automation Repo" project exists
- Sync the project with your Git repository
- Verify playbook paths are correct

**2. "Inventory not found"**
- Create "Exchange Servers" inventory
- Add your Exchange servers to it
- Set proper connection variables (ansible_connection: winrm, etc.)

**3. "Credential not found"**
- Create required credentials:
  - Windows Domain Admin (Machine credential with username/password)
  - VMware vCenter (VMware vCenter credential)
  - SolarWinds API (Custom credential for API access)

**4. "Organization not found"**
- Create "Credentialing" organization
- Or change organization name in templates to match your setup

**5. "Playbook not found"**
- Ensure project is synced
- Verify playbook paths match repository structure
- Check `playbooks/` directory exists in project

**6. "Module not found" when running**
- Install required collections in AAP:
  ```bash
  ansible-galaxy collection install ansible.windows
  ansible-galaxy collection install community.windows
  ansible-galaxy collection install ENTERPRISE.Windows
  ansible-galaxy collection install ENTERPRISE.Common
  ```

---

## Best Practices

1. **Use Version Control**: Keep your template YAML files in Git
2. **Test in Pre-Prod**: Import to pre-production AAP first
3. **Backup Existing**: Export existing templates before importing
4. **Use CLI for Bulk**: AWX CLI is fastest for importing many templates
5. **Document Changes**: Add notes in template descriptions
6. **Set Permissions**: Configure RBAC after import
7. **Enable Surveys**: Add surveys to workflows for user input
8. **Configure Notifications**: Set up notification templates for failures
9. **Tag Templates**: Use labels/tags to organize templates
10. **Regular Audits**: Review templates periodically for updates

---

## Export Templates (Backup)

Before making changes, export existing templates:

### Export All Templates

```bash
# Export to YAML
awx job_template list --all -f yaml > backup-job-templates.yml

# Export workflows
awx workflow_job_template list --all -f yaml > backup-workflows.yml
```

### Export Specific Template

```bash
awx job_template get "Windows: Exchange Maintenance - Preparation Phase" -f yaml > prep-phase-backup.yml
```

---

## Next Steps After Import

1. ✅ Import all job templates
2. ✅ Import workflows
3. ✅ Test each template individually
4. ✅ Configure workflow survey (see `exchange_workflow_survey.yml`)
5. ✅ Set up RBAC permissions
6. ✅ Configure notifications
7. ✅ Test complete workflow end-to-end
8. ✅ Document runbook for operators
9. ✅ Schedule regular maintenance windows
10. ✅ Monitor and iterate

---

## Additional Resources

- **AAP Documentation**: https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform
- **AWX CLI Docs**: https://docs.ansible.com/ansible-tower/latest/html/towercli/index.html
- **Ansible Controller Collection**: https://galaxy.ansible.com/ansible/controller
- **VARIABLES_REFERENCE.md**: Detailed variable documentation
- **WORKFLOW_README.md**: Complete workflow documentation
