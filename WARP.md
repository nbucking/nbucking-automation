# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Repository Overview

This is an automation code repository for Ansible playbooks and PowerShell scripts. The repository uses a simple two-directory structure to organize automation code by tool type.

## Repository Workflow

This repository follows a **public-first** approach with three tiers:

1. **nbucking-automation (origin)** - Public repository with sanitized, generic code
   - Must contain NO project-identifiable information
   - No server names, IP addresses, hostnames, or client-specific details
   - Generic examples and templates only
   
2. **Automation-Stage (automation-stage)** - Private staging repository
   - Contains project-specific configurations
   - Used for testing with actual server details before production
   
3. **Production** - Live environment deployment

### Pushing Code

```bash
# Push sanitized code to public repo
git push origin main

# Push project-specific code to private staging
git push automation-stage main

# Push to both (be careful!)
git push origin main && git push automation-stage main
```

### Before Pushing to Origin (Public)

**ALWAYS sanitize your code by:**
- Replacing real hostnames with generic examples (e.g., `server01.example.com`)
- Replacing IP addresses with RFC 5737 documentation IPs (e.g., `192.0.2.1`, `198.51.100.0`)
- Removing client/project names and replacing with generic terms
- Using variable placeholders instead of hardcoded values
- Moving environment-specific configs to ignored files (see `.gitignore`)

**Pre-commit hook will check for:**
- IP addresses in common private ranges
- Common hostname patterns
- Project-specific directory patterns

## Repository Structure

```
ansible/       - Ansible playbooks, roles, inventory files, and configurations
powershell/    - PowerShell scripts and modules
```

## Security and Secrets Management

This repository has strict `.gitignore` rules for sensitive files:

- **Ansible vault files**: `.vault_pass`, `credentials.yml`, `secrets.yml`, `vault.yml`
- **Certificates and keys**: `*.pem`, `*.key`, `*.cer`, `*.pfx`
- **Inventory files**: `ansible/inventory/hosts` (excluded to prevent committing production hosts)

When working with secrets:
- Use Ansible Vault for encrypting sensitive data in playbooks
- Store vault passwords outside the repository
- Never hardcode credentials in scripts or playbooks

## Ansible Development

### File Organization
- Place playbooks in `ansible/`
- Store inventory files in `ansible/inventory/` (these will be ignored by git)
- Organize reusable automation as roles within `ansible/`

### Common Patterns
- Ansible retry files (`*.retry`) are automatically ignored
- Use vault encryption for sensitive variables: `ansible-vault encrypt_string 'secret_value' --name 'var_name'`

## PowerShell Development

### File Organization
- Place scripts in `powershell/`
- Organize related functions as modules within `powershell/`
- Backup files (`*.ps1.bak`) are automatically ignored

### Execution Considerations
- This repository is intended for Linux environments (Fedora)
- PowerShell scripts should be compatible with PowerShell Core (pwsh)
- Ensure cross-platform compatibility when writing new scripts

## Testing and Validation

### Ansible
- Test playbooks with `--check` mode before running: `ansible-playbook playbook.yml --check`
- Use `--diff` to preview changes: `ansible-playbook playbook.yml --check --diff`
- Validate syntax: `ansible-playbook playbook.yml --syntax-check`

### PowerShell
- Validate syntax: `pwsh -Command "Get-Command -Syntax ./script.ps1"`
- Test scripts in non-destructive mode when possible (use `-WhatIf` parameter)
