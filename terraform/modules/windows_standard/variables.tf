variable "ami" {
  description = "AMI ID for the Windows Server"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to deploy the instance in"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the security group"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "security group id"
  type = string
}


variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
}

variable "additional_disk_size" {
  description = "Size (GB) of the additional EBS volume"
  type        = number
  default     = 50
}

variable "additional_disk_type" {
  description = "Type of the additional EBS volume"
  type        = string
  default     = "gp3"
}

variable "additional_disk_device_name" {
  description = "Device name for the additional EBS volume"
  type        = string
  default     = "/dev/sdf"
}