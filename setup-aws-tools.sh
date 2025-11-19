#!/bin/bash
#
# setup-aws-tools.sh
# Installs AWS CLI and Terraform on Fedora Linux
#
# Usage: ./setup-aws-tools.sh
#

set -e

echo "=== Installing AWS Tools on Fedora ==="
echo ""

# Install AWS CLI
echo "Installing AWS CLI v2..."
if ! command -v aws &> /dev/null; then
    cd /tmp
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
    echo "✓ AWS CLI installed"
else
    echo "✓ AWS CLI already installed"
fi

# Verify AWS CLI
aws --version

echo ""
echo "Installing Terraform..."
if ! command -v terraform &> /dev/null; then
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
    sudo dnf install -y terraform
    echo "✓ Terraform installed"
else
    echo "✓ Terraform already installed"
fi

# Verify Terraform
terraform version

echo ""
echo "Installing Python packages for Ansible Windows support..."
pip3 install --user pywinrm 2>/dev/null || sudo dnf install -y python3-pip && pip3 install --user pywinrm

echo ""
echo "Installing RDP client (optional, for remote desktop)..."
sudo dnf install -y freerdp || echo "FreeRDP installation failed (optional)"

echo ""
echo "=== AWS Tools Installation Complete ==="
echo ""
echo "Next steps:"
echo ""
echo "1. Configure AWS CLI with your credentials:"
echo "   aws configure"
echo ""
echo "   You'll need:"
echo "   - AWS Access Key ID"
echo "   - AWS Secret Access Key"
echo "   - Default region (e.g., us-east-1)"
echo "   - Default output format (json)"
echo ""
echo "2. Generate SSH key pair if you don't have one:"
echo "   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ''"
echo ""
echo "3. Navigate to terraform directory:"
echo "   cd terraform/aws-windows-server"
echo ""
echo "4. Copy and customize terraform.tfvars:"
echo "   cp terraform.tfvars.example terraform.tfvars"
echo "   vi terraform.tfvars"
echo ""
echo "5. Deploy infrastructure:"
echo "   terraform init"
echo "   terraform plan"
echo "   terraform apply"
echo ""
