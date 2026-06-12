output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "Public Subnet ID"
  value       = aws_subnet.public.id
}

output "instance_id" {
  description = "Main EC2 Instance ID"
  value       = aws_instance.main.id
}

output "instance_public_ip" {
  description = "Public IP of EC2 Instance"
  value       = aws_instance.main.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of EC2 Instance"
  value       = aws_instance.main.public_dns
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.main.id
}