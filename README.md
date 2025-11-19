# Nicholas Buckingham - Enterprise Automation Portfolio

![PowerShell](https://img.shields.io/badge/PowerShell-Expert-blue?logo=powershell)
![Ansible](https://img.shields.io/badge/Ansible-Advanced-red?logo=ansible)
![Python](https://img.shields.io/badge/Python-Intermediate-yellow?logo=python)
![Windows](https://img.shields.io/badge/Windows_Server-Expert-0078D6?logo=windows)
![Azure](https://img.shields.io/badge/Azure-Solutions_Architect-0089D6?logo=microsoft-azure)

> **18+ years** of enterprise Windows infrastructure automation, system administration, and DevOps engineering

## 👨‍💻 About Me

Senior Windows Engineer and Automation Specialist with comprehensive expertise in:
- **PowerShell Automation**: Advanced scripting for Windows Server, Active Directory, Exchange, and system management
- **Configuration Management**: Ansible collections and playbooks for enterprise infrastructure
- **Infrastructure as Code**: Automated deployment and maintenance workflows
- **Integration Development**: Python-based automation for Microsoft Graph API, SharePoint, and CI/CD pipelines
- **Enterprise Systems**: SCCM/MECM, Active Directory, Exchange Server, VMware Horizon/vSphere

### 🏆 Key Achievements
- ⚡ Reduced operational overhead by **40%** through PowerShell automation frameworks
- 🚀 Managed **10,000+** Active Directory user accounts and **5,000+** SCCM endpoints
- 💼 Former **Microsoft Premier Field Engineer** supporting Fortune 500 and DoD organizations
- 🎯 Maintained **99.9%** uptime for mission-critical enterprise infrastructure
- 📦 Designed and implemented enterprise SCCM/MECM infrastructure from scratch

### 🎓 Certifications
- **Microsoft Certified: Azure Solutions Architect Expert**
- **Microsoft Certified Solutions Associate: Windows Server 2016**
- **CompTIA SecurityX** (Advanced Security Certification)
- **CompTIA CASP** | **CEH** | **Security+ CE**

---

## 📁 Repository Structure

### 🔷 [PowerShell Automation](./powershell/)
Enterprise Windows automation scripts demonstrating advanced PowerShell capabilities:

#### **VDI Management** ([powershell/VDI-Management/](./powershell/VDI-Management/))
- **VDI Golden Image Automation**: Comprehensive script for managing VDI golden images
  - OS/Office update management
  - VMware Horizon integration
  - Dynamic Environment Manager configuration
  - FSLogix and App Volumes automation
  - System optimization and finalization workflows
- **Technologies**: PowerShell 5.1+, VMware Horizon, FSLogix, Microsoft Teams for VDI

#### **Domain & Infrastructure Management**
- `powershell/Configure-WinRM.ps1` — WinRM configuration for remote management
- `powershell/New-ServicesSandboxDomain.ps1` — Active Directory domain automation (lab setup)
- Health checks, reporting, and user lifecycle examples

---

### 🔶 [Ansible Automation](./ansible/)
Infrastructure as Code using Ansible for Windows enterprise environments:

#### **ENTERPRISE.Windows Collection** ([ansible/collections/ansible_collections/ENTERPRISE/Windows/](./ansible/collections/ansible_collections/ENTERPRISE/Windows/))
Comprehensive Ansible collection for enterprise Windows automation:

**Features**:
- 🔷 Custom PowerShell modules (`win_exchange`) for native Exchange integration
- 🔷 5 production-ready roles for Exchange Server maintenance
- 🔷 Complete maintenance workflows with AAP integration
- 🔷 Database mobility automation with health checks
- 🔷 Queue monitoring and service management

**Roles**:
- `exchange-prep` — Environment preparation and validation
- `exchange-database-management` — Database mobility and failover
- `exchange-maintenance-mode` — Maintenance mode control
- `exchange-queue-monitoring` — Transport queue monitoring
- `exchange-service-management` — Service lifecycle management

**Playbooks**:
- `exchange-maintenance-aap.yml` — AAP-compatible maintenance workflow
- `maintenance-failure.yml` — Failure notification and rollback
- `maintenance-cancelled.yml` — Cancellation confirmation

**Technologies**: Ansible 2.9+, PowerShell DSC, Exchange Management Shell, VMware vSphere API

📖 [View Collection Documentation](./ansible/collections/ansible_collections/ENTERPRISE/Windows/README.md)

#### **Active Directory** (playbooks in `ansible/`)
- Provision Windows VM (`provision-windows-vm.yml`)
- Install AD DS (`install-adds.yml`)
- Create OU structure (`create-ou-structure.yml`)
- Deploy complete AD (`deploy-complete-ad.yml`)
- AWS variants: `aws-install-adds.yml`, `aws-deploy-complete-ad.yml`

---

### 🐍 [Python Integration](./python/)
Integration scripts for modern cloud and collaboration platforms:

#### **SharePoint Integration** ([python/sharepoint-integration/](./python/sharepoint-integration/))
- Microsoft Graph API integration
- Automated file download from SharePoint Online
- Backup management and versioning
- OAuth authentication handling
- **Technologies**: Python 3.x, Microsoft Graph API, requests library

---

---

## 🛠️ Technical Skills

### **Core Expertise**
| Category | Technologies |
|----------|-------------|
| **Scripting & Automation** | PowerShell (Expert), Python (Intermediate), Bash, WQL |
| **Configuration Management** | Ansible, Puppet, SCCM/MECM, Group Policy |
| **Windows Platforms** | Windows Server 2016/2019/2022, Active Directory, Exchange 2016/2019 |
| **Virtualization** | VMware vSphere/ESXi, VMware Horizon, VDI, Hyper-V |
| **Cloud Platforms** | Azure (IaaS/PaaS), Azure AD, Microsoft 365 |
| **DevOps & CI/CD** | Git, GitLab CI, GitHub Actions, Ansible Automation Platform |
| **Monitoring & Logging** | PowerShell logging, Ansible reporting, ELK Stack integration |
| **Security & Compliance** | DISA STIGs, NIST 800-53, Zero Trust, MFA, PKI |

### **Specialized Skills**
- **SCCM/MECM**: Full lifecycle (installation, CAS design, client deployment, WQL queries, software packaging)
- **Active Directory**: Domain Services, Azure AD, Group Policy, DNS, DHCP, Certificate Services
- **Exchange Server**: Mailbox database management, DAG administration, transport rules
- **Endpoint Management**: Microsoft Intune, Microsoft Store for Business, Winget, MSIX packaging
- **VDI Technologies**: VMware Horizon, FSLogix, App Volumes, Dynamic Environment Manager

---

## 🎯 Project Highlights

### **1. VDI Golden Image Automation**
**Challenge**: Manual VDI golden image maintenance was time-consuming and error-prone, requiring 4-6 hours per update cycle.

**Solution**: Developed comprehensive PowerShell automation script managing the entire golden image lifecycle:
- Automated Windows/Office update management with registry-based controls
- Integrated VMware Horizon Agent, DEM, and App Volumes installation/updates
- Implemented OSOT (OS Optimization Tool) finalization with customizable parameters
- Version detection and intelligent upgrade logic for all VDI components

**Impact**:
- ✅ Reduced golden image update time from 4-6 hours to **45 minutes**
- ✅ Eliminated human error in update processes
- ✅ Enabled consistent deployments across 2,000+ virtual desktops
- ✅ Comprehensive logging and error handling for troubleshooting

**Technologies**: PowerShell 5.1, VMware Horizon 8.x, FSLogix, Microsoft Teams for VDI, OSOT

---

### **2. Exchange Server Maintenance Automation**
**Challenge**: Exchange Server maintenance required manual coordination across multiple administrators, risking downtime and data loss.

**Solution**: Built Ansible collection with custom PowerShell modules for automated Exchange maintenance:
- Automated database mobility and failover management
- Queue monitoring with automatic hold/retry logic
- Service health checks and dependency management
- Integration with VMware snapshots for rollback capability
- Ansible Automation Platform workflow templates

**Impact**:
- ✅ Reduced maintenance window duration by **60%**
- ✅ Eliminated manual database movement errors
- ✅ Enabled 24x7 maintenance capability through automation
- ✅ Zero unplanned downtime incidents since implementation

**Technologies**: Ansible 2.9+, PowerShell DSC, Exchange Management Shell, VMware vSphere API

---

### **3. SharePoint Integration & Automation**
**Challenge**: Manual file synchronization from SharePoint Online to local systems for CI/CD pipelines.

**Solution**: Python-based automation using Microsoft Graph API:
- OAuth token-based authentication
- Automated file download with backup management
- Version control and retention policies
- Error handling and retry logic

**Impact**:
- ✅ Automated daily synchronization of 50+ files
- ✅ Eliminated manual download steps in CI/CD pipelines
- ✅ Implemented automatic backup rotation (3 versions)
- ✅ Reduced pipeline execution time by **15 minutes**

**Technologies**: Python 3.x, Microsoft Graph API, OAuth 2.0, requests library

---

## 🚀 Quick Start Examples

### **PowerShell: Active Directory User Management**
```powershell
# Automated user provisioning with group assignments and mailbox creation
function New-EnterpriseUser {
    param(
        [string]$FirstName,
        [string]$LastName,
        [string]$Department
    )
    
    # Create AD user
    $Username = "$($FirstName.Substring(0,1))$LastName".ToLower()
    New-ADUser -Name "$FirstName $LastName" `
               -SamAccountName $Username `
               -Department $Department `
               -Enabled $true
    
    # Assign groups based on department
    $Groups = Get-DepartmentGroups -Department $Department
    Add-ADGroupMember -Identity $Groups -Members $Username
    
    # Create Exchange mailbox
    Enable-Mailbox -Identity $Username
}
```

### **Ansible: Windows Server Configuration**
```yaml
---
- name: Configure Windows Server
  hosts: windows_servers
  tasks:
    - name: Ensure required Windows features are installed
      win_feature:
        name:
          - Web-Server
          - Web-Asp-Net45
        state: present
    
    - name: Deploy application configuration
      win_template:
        src: app.config.j2
        dest: C:\inetpub\wwwroot\web.config
```

### **Python: Microsoft Graph API Integration**
```python
import requests

def get_sharepoint_file(site_id, file_path, token):
    """Download file from SharePoint using Graph API"""
    headers = {"Authorization": f"Bearer {token}"}
    url = f"https://graph.microsoft.com/v1.0/sites/{site_id}/drive/root:/{file_path}"
    
    response = requests.get(url, headers=headers)
    download_url = response.json()["@microsoft.graph.downloadUrl"]
    
    file_content = requests.get(download_url)
    return file_content.content
```

---

## 📈 Career Impact

### **Efficiency Gains**
- 🎯 **40% reduction** in manual administrative tasks through automation
- 🎯 **120+ hours/month** freed up for strategic initiatives
- 🎯 **60% faster** maintenance windows for critical systems
- 🎯 **85% reduction** in software deployment time via SCCM automation

### **Reliability Improvements**
- 🎯 **99.9% uptime** for enterprise infrastructure (200+ servers)
- 🎯 **98%+ client coverage** for SCCM/MECM deployments
- 🎯 **Zero unplanned downtime** incidents from automated maintenance
- 🎯 **100% error elimination** in repeatable processes

### **Scale Achievements**
- 🎯 Managing **10,000+ AD user accounts** with automated workflows
- 🎯 Deploying updates to **5,000+ endpoints** via SCCM
- 🎯 Supporting **2,000+ VDI virtual desktops**
- 🎯 Maintaining **50+ physical and virtual servers** per environment

---

## 🎓 Continuous Learning

I actively maintain and expand my automation skills through:
- Microsoft Learn modules (Azure, PowerShell, Microsoft 365)
- Ansible Galaxy contributions and community engagement
- Open-source project contributions
- Personal lab environment for testing new technologies

---

## 📫 Connect With Me

- **GitHub**: [@nbucking](https://github.com/nbucking)
- **Email**: nbucking@gmail.com
- **Location**: Colorado Springs, CO
- **Clearance**: Active Secret Clearance (US Citizen)

---

## 📄 License

Scripts and documentation in this repository are provided as examples of professional work. 
Individual scripts may have their own licenses as noted in file headers.

**Note**: All code examples have been sanitized to remove company-specific information and proprietary details while preserving technical demonstration value.

---

## 🌟 Why This Repository?

This portfolio demonstrates:

✅ **Real-world automation** solving actual enterprise challenges  
✅ **Production-grade code** with error handling, logging, and documentation  
✅ **Multi-platform expertise** (PowerShell, Ansible, Python)  
✅ **Modern DevOps practices** (IaC, CI/CD, version control)  
✅ **Enterprise scale** (thousands of users, servers, endpoints)  
✅ **Security awareness** (compliance, hardening, access control)  

### **Perfect for organizations seeking**:
- Senior Windows Engineers with automation expertise
- SCCM/MECM specialists who can code
- Former Microsoft Premier Field Engineers
- Azure Solutions Architects with on-premises depth
- DevOps engineers with Windows platform mastery

---

**Last Updated**: November 2025  
**Portfolio Version**: 1.0.0
