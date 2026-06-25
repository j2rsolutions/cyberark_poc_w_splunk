# Reattach orphaned CyberArk POC infrastructure (us-gov-east-1, account 172363844851).
# Scope: 5 CyberArk instances + their non-root data volumes + windows_sg.
# Splunk (splunklegion0 / carbide stack) intentionally excluded.
#
# Config for these resources is generated via:
#   terraform plan -generate-config-out=generated.tf
# Volume attachments are hand-written in volume_attachments.tf (config gen
# does not support aws_volume_attachment).

# ---- EC2 instances -------------------------------------------------------
import {
  to = aws_instance.cyberark_vault
  id = "i-0477f851c99653107"
}

import {
  to = aws_instance.cyberark_cpm
  id = "i-09f4aa188caf1794b"
}

import {
  to = aws_instance.cyberark_psm
  id = "i-02eb428b8340b5fa6"
}

import {
  to = aws_instance.cyberark_pvwa
  id = "i-0c81eba78f6b95680"
}

import {
  to = aws_instance.cyberark_dc
  id = "i-00c0ee53e20a035b7"
}

# Non-root /dev/sdf data volumes are managed inline via each instance's
# ebs_block_device (captured automatically by the aws_instance import) —
# no separate aws_ebs_volume / aws_volume_attachment resources needed.

# ---- Security group ------------------------------------------------------
import {
  to = aws_security_group.windows_sg
  id = "sg-01f6fd453e01fb2be"
}
