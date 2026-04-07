variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

resource "aws_security_group" "windows_sg" {
    provider                  = aws.gov

  name        = "windows_sg"
  description = "Allow RDP, HTTP, HTTPS, and DNS traffic"
  vpc_id      = var.vpc_id

  # Allow all inbound from 172.0.0.0/16
  ingress {
    description = "Allow all from 172.0.0.0/16"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["172.0.0.0/16"]
  }
    ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "security_group_id" {
  description = "The ID of the Windows security group"
  value       = aws_security_group.windows_sg.id
}