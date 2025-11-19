variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "ad-lab"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type (t2.micro is free tier eligible)"
  type        = string
  default     = "t2.micro"
  # For better performance: t3.medium or t3.large
}

variable "root_volume_size" {
  description = "Size of root EBS volume in GB"
  type        = number
  default     = 30
}

variable "allowed_rdp_cidr" {
  description = "CIDR blocks allowed to RDP to the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: Restrict this to your IP in production!
}

variable "allowed_winrm_cidr" {
  description = "CIDR blocks allowed to use WinRM (Ansible)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: Restrict this to your IP in production!
}

variable "windows_admin_password" {
  description = "Administrator password for Windows Server"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.windows_admin_password) >= 8
    error_message = "Password must be at least 8 characters long."
  }
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 key pair (leave empty to use ~/.ssh/id_rsa.pub)"
  type        = string
  default     = ""
}

variable "use_elastic_ip" {
  description = "Whether to allocate an Elastic IP (recommended to avoid IP changes on stop/start)"
  type        = bool
  default     = true
}
