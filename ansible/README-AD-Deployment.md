# Active Directory Deployment Automation

Complete automation for deploying a Windows Server 2019 Active Directory Domain Services (AD DS) environment with the `services.sandbox.local` domain structure on KVM/libvirt.

## Overview

This automation builds a complete virtualization and AD DS infrastructure:

1. **KVM/libvirt Setup** - Installs and configures virtualization on Fedora
2. **VM Provisioning** - Creates Windows Server 2019 VM
3. **AD DS Installation** - Promotes server to Domain Controller for new forest
4. **OU Structure Creation** - Implements complete organizational unit hierarchy

## Architecture

```
Fedora Linux Host (KVM/libvirt)
└── Windows Server 2019 VM (ws2019-dc01)
    └── Domain: services.sandbox.local
        └── Complete OU Structure (130+ OUs)
```

## Prerequisites

### Hardware Requirements
- CPU with virtualization support (Intel VT-x or AMD-V)
- Minimum 16GB RAM (8GB allocated to VM)
- 100GB available disk space
- Fedora Linux (tested on current versions)

### Software Requirements
- Fedora Linux with sudo access
- Internet connection for package downloads
- Windows Server 2019 ISO (evaluation or licensed)

## Quick Start

### Step 1: Install KVM/libvirt

```bash
# Make setup script executable
chmod +x ansible/setup-kvm-host.sh

# Run KVM installation (requires sudo)
sudo ansible/setup-kvm-host.sh

# Logout and login for group membership to take effect
```

### Step 2: Download Windows Server 2019 ISO

```bash
# Download evaluation ISO (180-day trial)
# Visit: https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2019

# Move ISO to libvirt directory
sudo mv ~/Downloads/windows_server_2019.iso /var/lib/libvirt/isos/

# Verify
ls -lh /var/lib/libvirt/isos/
```

### Step 3: Provision Windows Server VM

```bash
cd ansible

# Create VM
sudo ansible-playbook provision-windows-vm.yml

# Connect to VM console to complete Windows installation
virt-viewer ws2019-dc01
```

### Step 4: Complete Windows Installation

In the VM console (virt-viewer):

1. **Start Installation**
   - Press any key to boot from CD
   - Select language and region

2. **Choose Edition**
   - Select: **Windows Server 2019 Datacenter (Desktop Experience)**

3. **Load Storage Drivers**
   - Click "Load driver" when no disks appear
   - Browse to second CD drive (E:\ or D:\)
   - Navigate to: `vioscsi\2k19\amd64`
   - Install Red Hat VirtIO SCSI controller driver

4. **Install Windows**
   - Select the disk and proceed with installation
   - Set Administrator password (remember this!)

5. **Wait for Installation**
   - System will reboot automatically

### Step 5: Configure Windows for Ansible

After Windows installation completes, in the VM console:

```powershell
# Set static IP (optional but recommended)
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.0.2.10 -PrefixLength 24 -DefaultGateway 192.0.2.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 127.0.0.1,8.8.8.8

# Configure WinRM for Ansible
# Copy Configure-WinRM.ps1 to the VM or run commands manually:
Enable-PSRemoting -Force
Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true
New-NetFirewallRule -DisplayName "WinRM HTTP-In" -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow

# Note the IP address
ipconfig
```

### Step 6: Update Ansible Inventory

On your Fedora host:

```bash
# Copy example inventory
cp ansible/inventory/hosts.example ansible/inventory/hosts

# Edit with VM's IP address
vi ansible/inventory/hosts
# Change: dc01 ansible_host=192.0.2.10  (use actual IP)
```

### Step 7: Deploy AD DS and OU Structure

```bash
cd ansible

# Test connectivity
ansible windows_dc -i inventory/hosts -m win_ping -e 'ansible_password=YourAdminPassword'

# Deploy AD DS (installs AD DS, promotes to DC, creates OU structure)
ansible-playbook -i inventory/hosts deploy-complete-ad.yml --tags configure -e 'ansible_password=YourAdminPassword'
```

This will:
- Install AD Domain Services role
- Promote server to DC (creates `services.sandbox.local` forest)
- Reboot the server
- Create complete OU structure (130+ OUs)

### Step 8: Verify Deployment

```bash
# Connect to DC
virt-viewer ws2019-dc01

# In Windows, open Active Directory Users and Computers
# Start -> Run -> dsa.msc

# Verify OUs exist under services.sandbox.local:
# - Computers
# - Desktops (with Physical, VDI's, STAMP sub-structure)
# - Elevated Accounts
# - Groups
# - Linux Systems (AJ and CS divisions)
# - Windows Systems (AJ and CS divisions)
# - Non-Elevated Accounts
# - etc.
```

## Manual Steps (Alternative to Ansible)

If you prefer manual execution:

### Install AD DS Manually

```powershell
# On the Windows Server VM
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promote to DC
Install-ADDSForest `
    -DomainName "services.sandbox.local" `
    -DomainMode WinThreshold `
    -ForestMode WinThreshold `
    -InstallDns `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) `
    -Force
```

### Create OU Structure Manually

```powershell
# Copy the script to the VM (via shared folder or copy/paste)
# Then run:
PowerShell.exe -ExecutionPolicy Bypass -File C:\Path\To\New-ServicesSandboxDomain.ps1
```

## File Structure

```
ansible/
├── README-AD-Deployment.md          # This file
├── setup-kvm-host.sh                # KVM/libvirt installation script
├── provision-windows-vm.yml         # VM provisioning playbook
├── install-adds.yml                 # AD DS installation playbook
├── create-ou-structure.yml          # OU creation playbook
├── deploy-complete-ad.yml           # Master orchestration playbook
└── inventory/
    └── hosts.example                # Inventory template

powershell/
├── New-ServicesSandboxDomain.ps1    # OU structure creation script
└── Configure-WinRM.ps1              # WinRM configuration helper
```

## Troubleshooting

### KVM Installation Issues

```bash
# Verify CPU virtualization
egrep -c '(vmx|svm)' /proc/cpuinfo
# Should return > 0

# Check libvirtd status
sudo systemctl status libvirtd

# Verify user in libvirt group
groups
# Should include 'libvirt'
```

### VM Won't Start

```bash
# Check VM status
virsh list --all

# View VM details
virsh dominfo ws2019-dc01

# Check logs
sudo journalctl -u libvirtd -f
```

### Windows ISO Not Found

```bash
# Verify ISO location
ls -lh /var/lib/libvirt/isos/

# Update playbook variable if ISO is elsewhere:
# Edit provision-windows-vm.yml, line 17
```

### Ansible Can't Connect to Windows

```powershell
# On Windows VM, verify WinRM
Test-WSMan -ComputerName localhost

# Check firewall
Get-NetFirewallRule -DisplayName "*WinRM*"

# Verify WinRM listener
winrm enumerate winrm/config/listener
```

```bash
# From Fedora, test connectivity
ansible windows_dc -i inventory/hosts -m win_ping -e 'ansible_password=Password' -vvv
```

### Domain Promotion Fails

```powershell
# Check AD DS prerequisites
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Review dcpromo logs
Get-Content C:\Windows\debug\dcpromo.log

# Verify DNS
nslookup services.sandbox.local
```

### OU Creation Script Errors

```powershell
# Verify AD PowerShell module
Import-Module ActiveDirectory

# Test manually creating one OU
New-ADOrganizationalUnit -Name "Test" -Path "DC=services,DC=sandbox,DC=local"

# Run script with WhatIf first
.\New-ServicesSandboxDomain.ps1 -WhatIf
```

## Security Considerations

⚠️ **This is a LAB/SANDBOX environment configuration**

For production use, you MUST:

1. **Disable WinRM unencrypted traffic**
   ```powershell
   Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $false
   ```

2. **Use HTTPS/Kerberos for WinRM**
   ```powershell
   # Configure HTTPS listener with certificate
   ```

3. **Use Ansible Vault for credentials**
   ```bash
   ansible-vault create group_vars/windows_dc/vault.yml
   ```

4. **Change default passwords**
   - Administrator password
   - DSRM password (safe mode)

5. **Enable Windows Firewall properly**
6. **Apply security baselines and hardening**
7. **Implement proper backup strategy**

## Next Steps

After successful deployment:

1. **Create User Accounts**
   - Add users to appropriate OUs
   - Implement naming convention

2. **Configure Group Policies**
   - Link GPOs to OUs
   - Test with GPO_TEST accounts

3. **Add Member Servers**
   - Join servers to domain
   - Place in appropriate OUs

4. **Configure DNS**
   - Set up forward/reverse zones
   - Configure forwarders

5. **Implement Backup**
   - System State backups
   - VM snapshots
   - AD snapshots

6. **Monitor and Maintain**
   - Review Event Logs
   - Monitor AD health
   - Plan patching schedule

## Additional Resources

- [Ansible Windows Modules](https://docs.ansible.com/ansible/latest/collections/ansible/windows/)
- [KVM Virtualization Guide](https://docs.fedoraproject.org/en-US/quick-docs/virtualization-getting-started/)
- [Active Directory Best Practices](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/security-best-practices/)

## Support

For issues or questions:
1. Check troubleshooting section above
2. Review Ansible playbook output with `-vvv` flag
3. Check Windows Event Viewer logs
4. Review `/var/log/libvirt/qemu/ws2019-dc01.log`

## License

This automation follows the repository license. Windows Server requires appropriate licensing from Microsoft.
