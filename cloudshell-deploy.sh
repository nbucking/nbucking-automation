#!/bin/bash
#
# cloudshell-deploy.sh
# Complete AD deployment script for AWS CloudShell
#
# Usage: Run this in AWS CloudShell after uploading the terraform and ansible files

set -e

echo "=== AWS CloudShell AD Deployment ==="
echo ""

# Create directory structure
mkdir -p ~/ad-lab/terraform
mkdir -p ~/ad-lab/ansible/inventory
mkdir -p ~/ad-lab/powershell

# Generate SSH key if not exists
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Generating SSH key..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ''
fi

# Get your CloudShell IP (for security group)
echo "Getting your public IP..."
MY_IP=$(curl -s ifconfig.me)
echo "Your IP: $MY_IP"

# Create Terraform files
echo ""
echo "Creating Terraform configuration..."

cat > ~/ad-lab/terraform/main.tf << 'TERRAFORM_MAIN'
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "AD-Lab"
      Environment = "Sandbox"
      ManagedBy   = "Terraform"
    }
  }
}

data "aws_ami" "windows_2019" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "lab_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "ad-lab-vpc" }
}

resource "aws_internet_gateway" "lab_igw" {
  vpc_id = aws_vpc.lab_vpc.id
  tags = { Name = "ad-lab-igw" }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "ad-lab-public-subnet" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.lab_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab_igw.id
  }
  tags = { Name = "ad-lab-public-rt" }
}

resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "windows_dc_sg" {
  name        = "ad-lab-windows-dc-sg"
  description = "Security group for Windows Domain Controller"
  vpc_id      = aws_vpc.lab_vpc.id

  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr
  }

  ingress {
    description = "WinRM"
    from_port   = 5985
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ad-lab-windows-dc-sg" }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_key_pair" "lab_key" {
  key_name   = "ad-lab-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "windows_dc" {
  ami           = data.aws_ami.windows_2019.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.lab_key.key_name
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.windows_dc_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
  }

  user_data = <<-EOF
    <powershell>
    Set-ExecutionPolicy Unrestricted -Force
    Enable-PSRemoting -Force
    Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
    Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true
    Set-Service -Name WinRM -StartupType Automatic
    Restart-Service -Name WinRM
    New-NetFirewallRule -DisplayName "WinRM-HTTP" -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow -ErrorAction SilentlyContinue
    Rename-Computer -NewName "DC01" -Force -ErrorAction SilentlyContinue
    </powershell>
  EOF

  tags = {
    Name = "ad-lab-dc01"
    Role = "DomainController"
  }
}

resource "aws_eip" "dc_eip" {
  instance = aws_instance.windows_dc.id
  domain   = "vpc"
  tags = { Name = "ad-lab-dc-eip" }
}

variable "aws_region" {
  default = "us-east-1"
}

variable "allowed_cidr" {
  type = list(string)
}

output "instance_id" {
  value = aws_instance.windows_dc.id
}

output "public_ip" {
  value = aws_eip.dc_eip.public_ip
}

output "private_ip" {
  value = aws_instance.windows_dc.private_ip
}

output "rdp_command" {
  value = "xfreerdp /v:${aws_eip.dc_eip.public_ip} /u:Administrator /size:1920x1080"
}

output "password_command" {
  value = "aws ec2 get-password-data --instance-id ${aws_instance.windows_dc.id} --priv-launch-key ~/.ssh/id_rsa --region ${var.aws_region} --query 'PasswordData' --output text"
}
TERRAFORM_MAIN

# Create tfvars
cat > ~/ad-lab/terraform/terraform.tfvars << EOF
aws_region   = "us-east-1"
allowed_cidr = ["${MY_IP}/32"]
EOF

echo "Terraform configuration created!"
echo ""
echo "=== Next Steps ==="
echo ""
echo "1. Deploy infrastructure:"
echo "   cd ~/ad-lab/terraform"
echo "   terraform init"
echo "   terraform plan"
echo "   terraform apply"
echo ""
echo "2. After deployment completes (~5 minutes):"
echo "   Get Windows password:"
echo "   terraform output -raw password_command | bash"
echo ""
echo "3. Get public IP for Ansible:"
echo "   terraform output -raw public_ip"
echo ""
echo "Your files are ready in: ~/ad-lab/"
