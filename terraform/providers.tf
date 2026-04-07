#### default AWS gov provider ####

provider "aws" {
  alias                   = "gov_east"
  region                  = "us-gov-east-1"
  profile                 = "YOUR_GOV_PROFILE" ## Replace with profile name in credential files for AWS Gov
}

provider "aws" {
  alias                   = "gov_west"
  region                  = "us-gov-west-1"
  profile                 = "YOUR_GOV_PROFILE" ## Replace with profile name in credential files for AWS Gov
}

provider "aws" {
  alias                   = "comm_east"
  region                  = "us-east-1"
  profile                 = "YOUR_COMMERCIAL_PROFILE" ## Replace with profile name in credentials file for AWS commercial profile. Used for Route53 pub DNS entries
}

provider "tls"{}