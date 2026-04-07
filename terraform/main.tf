provider "aws" {
  region  = "us-gov-east-1"
  profile = "YOUR_GOV_PROFILE" ## Replace with profile name in credential files for AWS Gov
}

# --- Shared Security Group ---
module "windows_sg" {
  providers = {
    aws.comm = aws.comm_east
    aws.gov = aws.gov_east
  }
  source = "./modules/windows_sg"
  vpc_id = "vpc-097a7d0d3da117447"
}

# --- Domain Controller ---
# module "windows_dc" {
#   providers = {
#     aws.comm = aws.comm_east
#     aws.gov = aws.gov_east
#   }
#   source               = "./modules/windows_dc"
#   ami                  = "ami-0ab86f48a048a68df"  # Replace with your AMI ID
#   key_name             = "win2022"
#   subnet_id            = "subnet-0ea3b6dca06762833"
#   vpc_id               = "vpc-097a7d0d3da117447"
#   instance_type        = "t3.large"
#   vpc_security_group_ids = module.windows_sg.security_group_id
# }

# --- CyberArk Vault Server ---
module "cyberark_vault" {
  providers = {
    aws.comm = aws.comm_east
    aws.gov = aws.gov_east
  }
  source               = "./modules/windows_standard"
  ami                  = "ami-0ab86f48a048a68df"
  key_name             = "win2022"
  subnet_id            = "subnet-0ea3b6dca06762833"
  vpc_id               = "vpc-097a7d0d3da117447"
  instance_type        = "t3.large"
  vpc_security_group_ids = module.windows_sg.security_group_id
    instance_name         = "CyberArk-Vault"

  # Optional overrides for data disk
  additional_disk_size          = 100
  additional_disk_type          = "gp3"
  additional_disk_device_name   = "/dev/sdf"
}

# --- CyberArk PVWA Server ---
module "cyberark_pvwa" {
  providers = {
    aws.comm = aws.comm_east
    aws.gov = aws.gov_east
  }
  source               = "./modules/windows_standard"
  ami                  = "ami-0ab86f48a048a68df"
  key_name             = "win2022"
  subnet_id            = "subnet-0ea3b6dca06762833"
  vpc_id               = "vpc-097a7d0d3da117447"
  instance_type        = "t3.large"
  vpc_security_group_ids = module.windows_sg.security_group_id
    instance_name         = "CyberArk-PVWA"

  # Optional overrides for data disk
  additional_disk_size          = 100
  additional_disk_type          = "gp3"
  additional_disk_device_name   = "/dev/sdf"
}

# --- CyberArk PSM Server ---
module "cyberark_psm" {
  providers = {
    aws.comm = aws.comm_east
    aws.gov = aws.gov_east
  }
  source               = "./modules/windows_standard"
  ami                  = "ami-0ab86f48a048a68df"
  key_name             = "win2022"
  subnet_id            = "subnet-0ea3b6dca06762833"
  vpc_id               = "vpc-097a7d0d3da117447"
  instance_type        = "m6i.2xlarge"
  vpc_security_group_ids = module.windows_sg.security_group_id
    instance_name         = "CyberArk-PSM"

  # Optional overrides for data disk
  additional_disk_size          = 100
  additional_disk_type          = "gp3"
  additional_disk_device_name   = "/dev/sdf"
}

# --- CyberArk CPM Server ---
module "cyberark_cpm" {
  providers = {
    aws.comm = aws.comm_east
    aws.gov = aws.gov_east
  }
  source               = "./modules/windows_standard"
  ami                  = "ami-0ab86f48a048a68df"
  key_name             = "win2022"
  subnet_id            = "subnet-0ea3b6dca06762833"
  vpc_id               = "vpc-097a7d0d3da117447"
  instance_type        = "t3.large"
  vpc_security_group_ids = module.windows_sg.security_group_id
    instance_name         = "CyberArk-CPM"

  # Optional overrides for data disk
  additional_disk_size          = 100
  additional_disk_type          = "gp3"
  additional_disk_device_name   = "/dev/sdf"
}

# module "windows_dc_new" {
#   providers = {
#     aws.comm = aws.comm_east
#     aws.gov = aws.gov_east
#   }
#   source                = "./modules/windows_dc_new"
#   ami                   = "ami-0ab86f48a048a68df"
#   key_name              = "win2022"
#   subnet_id             = "subnet-0ea3b6dca06762833"
#   vpc_security_group_id = module.windows_sg.security_group_id
#   instance_type         = "t3.large"
#   instance_name         = "J2R-Test-DC"

#   # --- Dynamic AD Setup ---
#   domain_name           = "testlab.local"
#   netbios_name          = "TESTLAB"
#   dc_hostname           = "J2R-DC01"
#   safemode_password     = var.safemode_password
# }

module "cyberark_dc" {
  providers = {
    aws.comm = aws.comm_east
    aws.gov = aws.gov_east
  }
  source                = "./modules/windows_dc_new"
  ami                   = "ami-052dcb54a06973f54"
  key_name              = "win2022"
  subnet_id             = "subnet-0ea3b6dca06762833"
  vpc_security_group_id = module.windows_sg.security_group_id
  instance_type         = "t3.large"
  instance_name         = "cyberark-dc"

  # --- Dynamic AD Setup ---
  domain_name           = "testlab.local"
  netbios_name          = "TESTLAB"
  dc_hostname           = "J2R-DC01"
  safemode_password     = var.safemode_password
}

module "vault_fqdn" {
    providers = {
    aws = aws.comm_east
  }
  
  dns_zone = "Z04720411Z538D0M1WL87"
  source   = "./modules/dns_app"
  records  = [module.cyberark_vault.windows_server_public_ip]
  hostname = "vault1"
  type     = "A"

}


module "pvwa_fqdn" {
    providers = {
    aws = aws.comm_east
  }
  
  dns_zone = "Z04720411Z538D0M1WL87"
  source   = "./modules/dns_app"
  records  = [module.cyberark_pvwa.windows_server_public_ip]
  hostname = "pvwa1"
  type     = "A"

}



# --- Consolidated Outputs ---
output "deployment_details" {
  value = {
    domain_controller = {
      instance_id = module.cyberark_dc.dc_instance_id
      public_ip    = module.cyberark_dc.dc_public_ip
    }
    cyberark_vault = {
      instance_id = module.cyberark_vault.windows_server_instance_id
      public_ip    = module.cyberark_vault.windows_server_public_ip
    }
    cyberark_pvwa = {
      instance_id = module.cyberark_pvwa.windows_server_instance_id
      public_ip    = module.cyberark_pvwa.windows_server_public_ip
    }
    cyberark_psm = {
      instance_id = module.cyberark_psm.windows_server_instance_id
      public_ip    = module.cyberark_psm.windows_server_public_ip
    }
    cyberark_cpm = {
      instance_id = module.cyberark_cpm.windows_server_instance_id
      public_ip    = module.cyberark_cpm.windows_server_public_ip
    }
        
    fqdns = {
      vault_fqdn = module.vault_fqdn.dns_app_fqdn
      pvwa_fqdn = module.pvwa_fqdn.dns_app_fqdn
    }
  }
}