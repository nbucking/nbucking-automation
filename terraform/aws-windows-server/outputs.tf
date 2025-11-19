output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.windows_dc.id
}

output "public_ip" {
  description = "Public IP address of the Windows Server"
  value       = var.use_elastic_ip ? aws_eip.dc_eip[0].public_ip : aws_instance.windows_dc.public_ip
}

output "private_ip" {
  description = "Private IP address of the Windows Server"
  value       = aws_instance.windows_dc.private_ip
}

output "rdp_connection" {
  description = "RDP connection command"
  value       = "xfreerdp /v:${var.use_elastic_ip ? aws_eip.dc_eip[0].public_ip : aws_instance.windows_dc.public_ip} /u:Administrator /size:1920x1080"
}

output "ansible_host" {
  description = "Add this to your Ansible inventory"
  value       = "dc01 ansible_host=${var.use_elastic_ip ? aws_eip.dc_eip[0].public_ip : aws_instance.windows_dc.public_ip}"
}

output "windows_password_command" {
  description = "Command to retrieve Windows Administrator password"
  value       = "aws ec2 get-password-data --instance-id ${aws_instance.windows_dc.id} --priv-launch-key ~/.ssh/id_rsa --region ${var.aws_region}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.lab_vpc.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = aws_subnet.public_subnet.id
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.windows_dc_sg.id
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = data.aws_ami.windows_2019.id
}
