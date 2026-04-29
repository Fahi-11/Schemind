terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
}


# Security Group
resource "aws_security_group" "schemind_sg" {
  name        = "schemind-sg-${var.tag}"
  description = "Security group for Schemind application"

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Application port
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access (optional - you may want to restrict this)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "schemind-sg-${var.tag}"
    Project = "Schemind"
    BuildTag = var.tag
  }
}

# EC2 Instance
resource "aws_instance" "schemind_app" {
  ami           = "ami-0c7217cdde317cfec" # Amazon Linux 2
  instance_type = var.instance_type
  security_groups = [aws_security_group.schemind_sg.name]

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    docker_image = var.docker_image
    tag = var.tag
  }))

  tags = {
    Name = "schemind-app-${var.tag}"
    Project = "Schemind"
    BuildTag = var.tag
  }

  # Ensure instance gets new AMI if changed
  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP (optional - for static IP)
resource "aws_eip" "schemind_eip" {
  instance = aws_instance.schemind_app.id
  domain   = "vpc"

  tags = {
    Name = "schemind-eip-${var.tag}"
    Project = "Schemind"
    BuildTag = var.tag
  }
}

