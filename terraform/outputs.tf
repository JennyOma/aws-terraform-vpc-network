
output "vpc_id" {
  description = "ID of the Project 06 VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

output "public_ec2_id" {
  description = "ID of the public EC2 instance"
  value       = aws_instance.public.id
}

output "private_ec2_id" {
  description = "ID of the private EC2 instance"
  value       = aws_instance.private.id
}

output "public_web_url" {
  description = "HTTP address of the public test web server"
  value       = "http://${aws_instance.public.public_ip}"
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.main.id
}
