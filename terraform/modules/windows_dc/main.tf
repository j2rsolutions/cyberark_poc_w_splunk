resource "aws_instance" "dc_instance" {
    provider                  = aws.gov

  ami           = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name

  tags = {
    Name = "DomainController"
  }

  subnet_id = var.subnet_id

  provisioner "local-exec" {
    command = <<-EOT
      echo "full address:s:${self.public_ip}" > domain_controller.rdp
      echo "username:s:Administrator" >> domain_controller.rdp
      # Add other RDP parameters as needed...
    EOT
  }
  
  user_data = <<-EOF
      <powershell>
          # Install Active Directory Domain Services and ADDS Management Tools
          Install-WindowsFeature AD-Domain-Services, RSAT-ADDS

          # Import the ADDSDeployment module
          Import-Module ADDSDeployment

          # Install a new AD DS Forest
          Install-ADDSForest `
          -CreateDnsDelegation:$false `
          -DatabasePath "C:\Windows\NTDS" `
          -DomainMode "Win2012R2" `
          -DomainName "j2rlabs.local" `
          -DomainNetbiosName "DOMAIN" `
          -ForestMode "Win2012R2" `
          -InstallDns:$true `
          -LogPath "C:\Windows\NTDS" `
          -NoRebootOnCompletion:$true `
          -SysvolPath "C:\Windows\SYSVOL" `
          -Force:$true

          # Install AD FS (optional)
          # Install-WindowsFeature AD-Federation-Services -IncludeManagementTools

          # Configure AD FS (optional)
          # Replace with your specific configuration parameters
          # Example:
          # Install-AdfsFarm -CertificateThumbprint "YOUR_CERTIFICATE_THUMBPRINT" `
          # -FederationServiceName "YOUR_SERVICE_NAME" -OverwriteConfiguration

      </powershell>
      EOF


  vpc_security_group_ids = [var.vpc_security_group_ids]
}


