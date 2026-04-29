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

# -----------------------------
# SECURITY GROUP (STATIC NAME)
# -----------------------------
resource "aws_security_group" "schemind_sg" {
  name        = "schemind-sg"   # ❌ removed ${var.tag}
  description = "Security group for Schemind application"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
    Name    = "schemind-sg"
    Project = "Schemind"
  }
}

# -----------------------------
# EC2 INSTANCE (REUSED)
# -----------------------------
resource "aws_instance" "schemind_app" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.schemind_sg.id]

  # 🚀 Runs only on FIRST creation
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install docker -y
              service docker start
              usermod -aG docker ec2-user

              docker pull ${var.docker_image}
              docker run -d -p 3000:3000 --name schemind ${var.docker_image}
              EOF

  tags = {
    Name    = "schemind-app"
    Project = "Schemind"
  }

  # 🧠 CRITICAL FIX
  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------
# OUTPUT
# -----------------------------
output "ec2_public_ip" {
  value = aws_instance.schemind_app.public_ip
}