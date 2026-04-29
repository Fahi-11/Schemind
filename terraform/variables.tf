variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "docker_image" {
  description = "Docker image to deploy"
  type        = string
}

variable "tag" {
  description = "Build tag for deployment"
  type        = string
  default     = "latest"
}
