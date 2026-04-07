variable "ami" {
  description = "AMI ID for the Windows Server image"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the domain controller"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name for RDP access"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the DC will be deployed"
  type        = string
}

variable "vpc_security_group_id" {
  description = "Security Group ID to associate with this instance"
  type        = string
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

variable "domain_name" {
  description = "Fully Qualified Domain Name (e.g., j2rlabs.local)"
  type        = string
}

variable "netbios_name" {
  description = "NetBIOS name for the domain (e.g., J2RLABS)"
  type        = string
}

variable "dc_hostname" {
  description = "Hostname for the Domain Controller (e.g., J2R-DC01)"
  type        = string
}

variable "safemode_password" {
  description = "DSRM Safe Mode Administrator password"
  type        = string
  sensitive   = true
}