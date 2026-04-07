
resource "aws_instance" "dc_instance" {
    provider                  = aws.gov

  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.vpc_security_group_id]

  tags = {
    Name = var.instance_name
  }

  user_data = <<-EOF
  <powershell>
    # --- Dynamic Variables from Terraform ---
    $DomainName = "${var.domain_name}"
    $NetBIOSName = "${var.netbios_name}"
    $SafeModePassword = (ConvertTo-SecureString "${var.safemode_password}" -AsPlainText -Force)
    $ComputerName = "${var.dc_hostname}"
    $LogFile = "C:\\ADSetup.log"

    # Rename the computer
    Rename-Computer -NewName $ComputerName -Force

    # Create a post-reboot script
    $Script = @"
    <powershell>
      \$DomainName = "${var.domain_name}"
      \$NetBIOSName = "${var.netbios_name}"
      \$SafeModePassword = (ConvertTo-SecureString "${var.safemode_password}" -AsPlainText -Force)
      Install-WindowsFeature AD-Domain-Services, RSAT-ADDS
      Import-Module ADDSDeployment

      Install-ADDSForest `
        -DomainName \$DomainName `
        -DomainNetbiosName \$NetBIOSName `
        -SafeModeAdministratorPassword \$SafeModePassword `
        -InstallDns:\$true `
        -Force:\$true

      Add-Content "C:\\ADSetup.log" "Forest installation completed at \$(Get-Date)"
    </powershell>
"@

    # Save post-reboot script
    Set-Content -Path "C:\\ADSetupPost.ps1" -Value $Script

    # Register script for one-time execution on next boot
    New-ItemProperty -Path "HKLM:\\Software\\Microsoft\\Windows\\CurrentVersion\\RunOnce" `
      -Name "CompleteADSetup" `
      -Value "powershell.exe -ExecutionPolicy Bypass -File C:\\ADSetupPost.ps1" `
      -PropertyType String

    Add-Content $LogFile "Initial setup complete. Machine will reboot to continue AD configuration."
    Restart-Computer -Force
  </powershell>
  EOF
}

