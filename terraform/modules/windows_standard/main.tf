# ------------------- EC2 Instance -------------------
resource "aws_instance" "windows_server" {
    provider                  = aws.gov

  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.vpc_security_group_ids]

  tags = {
    Name = var.instance_name
  }

  # Root volume settings
  root_block_device {
    volume_size = 60
    volume_type = "gp3"
  }
}

# ------------------- Additional EBS Volume -------------------
resource "aws_ebs_volume" "additional_disk" {
  availability_zone = aws_instance.windows_server.availability_zone
  size              = var.additional_disk_size
  type              = var.additional_disk_type
  tags = {
    Name = "${var.instance_name}-DataDisk"
  }
}

resource "aws_volume_attachment" "additional_disk_attachment" {
  device_name = var.additional_disk_device_name
  volume_id   = aws_ebs_volume.additional_disk.id
  instance_id = aws_instance.windows_server.id
  force_detach = true
}

