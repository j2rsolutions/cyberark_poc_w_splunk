output "dc_instance_id" {
  description = "The ID of the domain controller instance"
  value       = aws_instance.dc_instance.id
}

output "dc_public_ip" {
  description = "The public IP of the domain controller instance"
  value       = aws_instance.dc_instance.public_ip
}