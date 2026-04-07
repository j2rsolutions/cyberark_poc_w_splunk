output "windows_server_instance_id" {
  description = "Instance ID of the Windows server"
  value       = aws_instance.windows_server.id
}

output "windows_server_public_ip" {
  description = "Public IP of the Windows server"
  value       = aws_instance.windows_server.public_ip
}

output "additional_disk_id" {
  description = "ID of the attached additional EBS volume"
  value       = aws_ebs_volume.additional_disk.id
}