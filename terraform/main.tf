
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

# Custom VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "project06-vpc"
    Project = "06-networking"
  }
}

# Public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-north-1a"
  map_public_ip_on_launch = false

  tags = {
    Name    = "project06-public-subnet"
    Project = "06-networking"
  }
}

# Private subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name    = "project06-private-subnet"
    Project = "06-networking"
  }
}

# Internet Gateway for the public subnet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "project06-igw"
    Project = "06-networking"
  }
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "project06-public-rt"
    Project = "06-networking"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name    = "project06-nat-eip"
    Project = "06-networking"
  }
}

# NAT Gateway in the public subnet
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name    = "project06-nat"
    Project = "06-networking"
  }
}

# Private route table: outbound internet via NAT
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name    = "project06-private-rt"
    Project = "06-networking"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Latest Amazon Linux 2023 AMI
data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Security group for the public web server
resource "aws_security_group" "public_web" {
  name_prefix = "project06-public-web-"
  description = "Allow HTTP access to public web server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Public HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "project06-public-web-sg"
    Project = "06-networking"
  }
}

# Security group for the private instance
resource "aws_security_group" "private" {
  name_prefix = "project06-private-"
  description = "No inbound access; HTTPS outbound only"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "HTTPS via NAT Gateway"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "project06-private-sg"
    Project = "06-networking"
  }
}

# IAM role for AWS Systems Manager
resource "aws_iam_role" "ssm" {
  name = "project06-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Allow EC2 to connect to Systems Manager
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "project06-ec2-ssm-profile"
  role = aws_iam_role.ssm.name
}

# Public EC2 web server
resource "aws_instance" "public" {
  ami                         = data.aws_ssm_parameter.amazon_linux.value
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.public_web.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ssm.name

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }


  user_data = <<-EOF
    #!/bin/bash
    dnf install -y httpd
    cat > /var/www/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>JennyOma | Cloud Engineer</title>
      <style>
        body {
          background: #f8bbd0;
          color: #552344;
          font-family: Arial, sans-serif;
          text-align: center;
          padding: 90px 20px;
        }
        h1 { color: #9c1459; font-size: 38px; }
        h2 { color: #752052; }
        p { font-size: 21px; }
        footer { margin-top: 55px; color: #713d5a; }
      </style>
    </head>
    <body>
      <h1>Welcome to JennyOma's Cloud! ☁️</h1>
      <h2>Cloud Engineer 🚀</h2>
      <p>I don't just have my head in the clouds...</p>
      <h2>I build them with Terraform! 😎</h2>
      <footer>
        Project 06 | AWS VPC Networking | Amazon EC2
        <p>Designed &amp; Deployed by JennyOma</p>
      </footer>
    </body>
    </html>
    HTML
    systemctl enable --now httpd
  EOF


  tags = {
    Name    = "project06-public-ec2"
    Project = "06-networking"
  }
}

# Private EC2 instance
resource "aws_instance" "private" {
  ami                         = data.aws_ssm_parameter.amazon_linux.value
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.private.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ssm.name

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name    = "project06-private-ec2"
    Project = "06-networking"
  }
}
