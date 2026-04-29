output "ec2_public_ip" {
  description = "Public IP address of EC2 instance"
  value       = aws_instance.schemind_app.public_ip
}

output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.schemind_app.id
}

output "application_url" {
  description = "URL of the deployed application"
  value       = "http://${aws_instance.schemind_app.public_ip}:3000"
}

output "docker_image_used" {
  description = "Docker image deployed"
  value       = "${var.docker_image}:${var.tag}"
}
