output "instance_ip" {
  description = "Public IP address of the instance"
  value       = aws_eip.eboost.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.eboost.id
}

output "instance_dns" {
  description = "Public DNS name of the instance"
  value       = aws_instance.eboost.public_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.eboost.id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}