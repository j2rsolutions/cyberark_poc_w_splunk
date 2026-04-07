# Define parameters for the new forest and domain
$domainName = "j2r.local"
$safeModeAdministratorPassword = ConvertTo-SecureString -String "YourSafeModePassword!" -AsPlainText -Force

# Install the required Active Directory feature
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# Import the Active Directory module for further configurations
Import-Module ADDSDeployment

# Install a new forest
Install-ADDSForest `
    -DomainName $domainName `
    -SafeModeAdministratorPassword $safeModeAdministratorPassword `
    -InstallDns `
    -Force `
    -Confirm:$false

# Restart the server after promotion
Restart-Computer -Force
