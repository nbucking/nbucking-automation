# AWS Active Directory Lab Deployment

Complete automation to deploy Windows Server 2019 Active Directory Domain Services on AWS EC2 using the **12-month free tier**.

## Overview

This solution provisions a complete AD DS environment in AWS:

1. **Infrastructure as Code** - Terraform provisions VPC, EC2, security groups
2. **Automated Configuration** - Ansible installs AD DS and creates OU structure
3. **Cost Optimized** - Uses AWS Free Tier (750 hours/month for 12 months)
4. **Production-Ready Structure** - 130+ OUs for `services.sandbox.local` domain

## Architecture

```
AWS Cloud (Free Tier)
└── VPC (10.0.0.0/16)
    └── Public Subnet (10.0.1.0/24)
        └── EC2 Instance (Windows Server 2019)
            ├── t2.micro (1 vCPU, 1GB RAM) - Free Tier
            ├── Domain Controller (DC01)
            ├── DNS Server
            └── services.sandbox.local domain
                └── Complete OU Structure (130+ OUs)
```

## Prerequisites

### 1. AWS Account
- Sign up at https://aws.amazon.com/free/
- Free tier includes:
  - 750 hours/month of t2.micro Windows instances (12 months)
  - 30GB EBS storage
  - 15GB data transfer out
- **Credit card required** (but won't be charged with free tier usage)

### 2. System Requirements
- Fedora Linux (your current system)
- Internet connection
- ~2GB disk space for tools

## Quick Start Guide

### Step 1: Install AWS Tools

```bash
cd /config/nbucking-automation

# Install AWS CLI, Terraform, and dependencies
./setup-aws-tools.sh
```

### Step 2: Configure AWS Credentials

1. **Create AWS Access Keys:**
   - Log into AWS Console: https://console.aws.amazon.com
   - Navigate to: IAM → Users → Your User → Security Credentials
   - Click "Create access key"
   - Choose "Command Line Interface (CLI)"
   - Save the Access Key ID and Secret Access Key

2. **Configure AWS CLI:**
   ```bash
   aws configure
   ```
   
   Enter:
   - AWS Access Key ID: `[Your Access Key]`
   - AWS Secret Access Key: `[Your Secret Key]`
   - Default region: `us-east-1` (or closest to you)
   - Default output format: `json`

3. **Test AWS access:**
   ```bash
   aws sts get-caller-identity
   ```

### Step 3: Generate SSH Key (if needed)

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ''

# Verify
ls -l ~/.ssh/id_rsa*
```

### Step 4: Configure Terraform Variables

```bash
cd terraform/aws-windows-server

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit configuration
vi terraform.tfvars
```

**Required changes in terraform.tfvars:**

```hcl
# Set a strong password for Windows Administrator
windows_admin_password = "YourStrong-P@ssw0rd123!"

# Restrict access to your IP for security
# Get your IP: curl -s ifconfig.me
allowed_rdp_cidr   = ["YOUR.IP.ADDRESS/32"]
allowed_winrm_cidr = ["YOUR.IP.ADDRESS/32"]

# Optional: Change region if preferred
aws_region = "us-east-1"
```

### Step 5: Deploy Infrastructure with Terraform

```bash
# Still in terraform/aws-windows-server/

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy infrastructure (takes ~5 minutes)
terraform apply

# Type 'yes' when prompted
```

**Terraform will create:**
- VPC and networking
- Security groups
- EC2 Windows Server 2019 instance
- Elastic IP (so IP doesn't change)

**Save the outputs:**
```bash
# Display outputs
terraform output

# Save for later use
terraform output public_ip
terraform output windows_password_command
```

### Step 6: Get Windows Administrator Password

```bash
# Retrieve password (wait 5-10 minutes after instance creation)
aws ec2 get-password-data \
    --instance-id $(terraform output -raw instance_id) \
    --priv-launch-key ~/.ssh/id_rsa \
    --region $(terraform output -raw aws_region) \
    --query 'PasswordData' \
    --output text

# Save this password!
```

### Step 7: Configure Ansible Inventory

```bash
cd ../../ansible

# Copy example inventory
cp inventory/hosts-aws.example inventory/hosts-aws

# Edit inventory with actual IP
vi inventory/hosts-aws
```

Replace `TERRAFORM_OUTPUT_PUBLIC_IP` with the actual IP:
```bash
# Get the IP from Terraform
cd ../terraform/aws-windows-server
terraform output public_ip
```

Update `inventory/hosts-aws`:
```ini
[windows_dc]
dc01 ansible_host=YOUR_ACTUAL_PUBLIC_IP

[windows_dc:vars]
ansible_user=Administrator
ansible_connection=winrm
ansible_winrm_transport=basic
ansible_winrm_server_cert_validation=ignore
ansible_port=5985
ansible_winrm_scheme=http
```

### Step 8: Test Ansible Connectivity

```bash
cd ../../ansible

# Test WinRM connection
ansible windows_dc -i inventory/hosts-aws -m win_ping \
    -e 'ansible_password=YourWindowsPassword'

# Should return: "pong"
```

### Step 9: Deploy Active Directory

```bash
# Deploy AD DS and create OU structure (~15-20 minutes)
ansible-playbook -i inventory/hosts-aws aws-deploy-complete-ad.yml \
    -e 'ansible_password=YourWindowsPassword'
```

This will:
1. Install AD Domain Services role
2. Promote server to Domain Controller
3. Create `services.sandbox.local` domain
4. Reboot the server
5. Create complete OU structure (130+ OUs)

### Step 10: Verify Deployment

**Option A: Via RDP (Recommended)**

```bash
# Get RDP connection command
cd ../terraform/aws-windows-server
terraform output rdp_connection

# Connect via RDP
xfreerdp /v:YOUR_PUBLIC_IP /u:Administrator /size:1920x1080

# Enter the Windows password when prompted

# In Windows:
# Open Active Directory Users and Computers
# Run: dsa.msc
# Verify OUs exist under services.sandbox.local
```

**Option B: Via Ansible**

```bash
cd ../../ansible

# Query AD structure
ansible windows_dc -i inventory/hosts-aws -m win_shell \
    -a "Import-Module ActiveDirectory; Get-ADOrganizationalUnit -Filter * | Measure-Object" \
    -e 'ansible_password=YourPassword'

# Should show 130+ OUs
```

## Cost Management

### Free Tier Limits (12 Months)
- ✅ **750 hours/month** of t2.micro (enough for 24/7 operation)
- ✅ **30GB EBS storage** (Windows Server uses ~30GB)
- ✅ **15GB data transfer out**

### Best Practices

**Stop Instance When Not in Use:**
```bash
# Stop instance (keeps your data, stops charges)
aws ec2 stop-instances --instance-ids $(terraform output -raw instance_id)

# Start instance when needed
aws ec2 start-instances --instance-ids $(terraform output -raw instance_id)

# Note: Elastic IP keeps the same public IP across stop/start
```

**Monitor Usage:**
- Check: https://console.aws.amazon.com/billing/home#/freetier
- Set up billing alerts at $5, $10, $15

**After 12 Months:**
- t2.micro costs ~$9-12/month
- Consider stopping/terminating if not needed

## Managing Your Lab

### Common Operations

**RDP to Server:**
```bash
xfreerdp /v:$(terraform output -raw public_ip) /u:Administrator /size:1920x1080
```

**Stop Instance (Save Costs):**
```bash
aws ec2 stop-instances --instance-ids $(terraform output -raw instance_id)
```

**Start Instance:**
```bash
aws ec2 start-instances --instance-ids $(terraform output -raw instance_id)

# Wait for it to start (~2 minutes)
aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id) \
    --query 'Reservations[0].Instances[0].State.Name' --output text
```

**Destroy Everything (Clean Up):**
```bash
cd terraform/aws-windows-server
terraform destroy

# Type 'yes' to confirm
```

### Adding More Servers

To add Exchange, SQL, or other servers:

1. **Modify Terraform:**
   ```hcl
   # Add to main.tf
   resource "aws_instance" "exchange_server" {
     ami           = data.aws_ami.windows_2019.id
     instance_type = "t3.medium"  # Exchange needs more resources
     # ... other configuration
   }
   ```

2. **Deploy:**
   ```bash
   terraform apply
   ```

3. **Join to Domain (via Ansible):**
   ```yaml
   - name: Join Exchange server to domain
     win_domain_membership:
       dns_domain_name: services.sandbox.local
       domain_admin_user: Administrator@services.sandbox.local
       domain_admin_password: "{{ admin_password }}"
       state: domain
   ```

## Troubleshooting

### Can't Connect via RDP

```bash
# Check instance status
aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id)

# Check security group allows your IP
aws ec2 describe-security-groups \
    --group-ids $(terraform output -raw security_group_id) \
    | grep -A5 IpPermissions

# Update security group if needed
# Edit terraform.tfvars with your current IP and run:
terraform apply
```

### Ansible Connection Fails

```bash
# Verify WinRM is accessible
nc -zv $(terraform output -raw public_ip) 5985

# Check Windows firewall (via RDP)
# PowerShell: Get-NetFirewallRule -DisplayName "*WinRM*"

# Re-run userdata script (via AWS console)
# EC2 → Instances → Actions → Instance Settings → Edit user data
```

### Domain Promotion Fails

```bash
# Check logs via RDP
# C:\Windows\debug\dcpromo.log

# Or via Ansible
ansible windows_dc -i inventory/hosts-aws -m win_shell \
    -a "Get-Content C:\Windows\debug\dcpromo.log -Tail 50" \
    -e 'ansible_password=YourPassword'
```

### Out of Free Tier Hours

```bash
# Check free tier usage
aws ce get-cost-and-usage \
    --time-period Start=2025-01-01,End=2025-01-31 \
    --granularity MONTHLY \
    --metrics UsageQuantity \
    --filter file://filter.json

# If over limit, stop instance
aws ec2 stop-instances --instance-ids $(terraform output -raw instance_id)
```

## Security Considerations

⚠️ **This is a LAB environment**. For production:

1. **Restrict IP Access:**
   ```hcl
   allowed_rdp_cidr   = ["YOUR.IP/32"]  # Only your IP
   allowed_winrm_cidr = ["YOUR.IP/32"]  # Only your IP
   ```

2. **Use Strong Passwords:**
   - Minimum 14 characters
   - Mix of upper, lower, numbers, special chars

3. **Enable CloudWatch Logging:**
   ```bash
   # Add to Terraform
   cloudwatch_log_group = true
   ```

4. **Use Systems Manager Instead of WinRM:**
   - More secure than WinRM
   - No open ports needed

5. **Enable MFA on AWS Account**

6. **Regular Patching:**
   ```powershell
   # Via RDP or Ansible
   Install-WindowsUpdate -AcceptAll -AutoReboot
   ```

## File Structure

```
nbucking-automation/
├── README-AWS-Deployment.md              # This file
├── setup-aws-tools.sh                    # Tool installation script
├── terraform/
│   └── aws-windows-server/
│       ├── main.tf                       # Main Terraform config
│       ├── variables.tf                  # Variable definitions
│       ├── outputs.tf                    # Output definitions
│       ├── userdata.ps1                  # Windows bootstrap script
│       ├── terraform.tfvars.example      # Example variables
│       └── terraform.tfvars              # Your customized variables (gitignored)
├── ansible/
│   ├── aws-install-adds.yml              # AD DS installation playbook
│   ├── create-ou-structure.yml           # OU creation playbook
│   ├── aws-deploy-complete-ad.yml        # Master playbook
│   └── inventory/
│       └── hosts-aws.example             # Inventory template
└── powershell/
    └── New-ServicesSandboxDomain.ps1     # OU structure script
```

## Next Steps After Deployment

1. **Create User Accounts**
   - Add to appropriate OUs
   - Set up PIV accounts
   - Configure elevated accounts

2. **Configure Group Policies**
   - Link GPOs to OUs
   - Test with GPO_TEST accounts
   - Apply security baselines

3. **Add Member Servers**
   - Deploy additional EC2 instances
   - Join to domain
   - Place in appropriate OUs

4. **Install Exchange Server** (if needed)
   - Deploy t3.medium instance
   - Run Exchange prerequisites
   - Install Exchange 2019

5. **Set Up Monitoring**
   - CloudWatch for EC2 metrics
   - AD health checks
   - Billing alerts

6. **Implement Backup Strategy**
   - EBS snapshots
   - AWS Backup
   - System State backups

## Additional Resources

- [AWS Free Tier FAQ](https://aws.amazon.com/free/free-tier-faqs/)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible Windows Modules](https://docs.ansible.com/ansible/latest/collections/ansible/windows/)
- [Active Directory Best Practices](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/security-best-practices/)
- [AWS EC2 Windows Guide](https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/)

## Support

For issues:
1. Check troubleshooting section above
2. Review Terraform output: `terraform show`
3. Check AWS CloudWatch logs
4. Review Ansible output with `-vvv` flag

## License

This automation follows the repository license. Windows Server and AWS services require appropriate licensing/billing from Microsoft and Amazon.

---

**Cost Estimate Summary:**
- **Month 1-12:** FREE (within 750 hours/month free tier)
- **After 12 months:** ~$9-12/month if running 24/7
- **Stop when not in use:** $0-2/month (EBS storage only)
