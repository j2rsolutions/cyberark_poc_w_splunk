# CyberArk POC with Splunk Integration

This repository contains Terraform infrastructure-as-code for deploying a CyberArk Privileged Access Security (PAS) environment on AWS GovCloud, along with instructions for integrating CyberArk vault audit logs with Splunk.

## Infrastructure Overview

The Terraform configuration deploys the following components in AWS GovCloud (us-gov-east-1):

| Component | Module | Instance Type | Purpose |
|-----------|--------|---------------|---------|
| Domain Controller | windows_dc_new | t3.large | Active Directory (testlab.local) |
| CyberArk Vault | windows_standard | t3.large | Core secrets storage |
| CyberArk PVWA | windows_standard | t3.large | Password Vault Web Access |
| CyberArk PSM | windows_standard | m6i.2xlarge | Privileged Session Manager |
| CyberArk CPM | windows_standard | t3.large | Central Policy Manager |

DNS records for the Vault and PVWA are created in AWS Commercial Route 53.

## Splunk Add-on for CyberArk - Installation Guide

### Which Add-on to Use

There are multiple CyberArk-related apps on Splunkbase. For this deployment (CyberArk PAS suite), you need:

- **Splunk Add-on for CyberArk (TA)** — [Splunkbase App 2891](https://splunkbase.splunk.com/app/2891)
  - This is the correct add-on for **Enterprise Password Vault (EPV)** and **Privileged Threat Analytics (PTA)**
  - Ingests syslog/CEF from Vault audit logs and PTA alerts
  - Note: This app has been archived on Splunkbase but is still functional

- **CyberArk Next-Gen Access Add-on** — [Splunkbase App 7005](https://splunkbase.splunk.com/app/7005)
  - This add-on is **NOT applicable** to this deployment
  - It is designed for **CyberArk Identity** (SSO, MFA, workforce identity management), which is a completely separate product from the PAS suite we are running

### The XSL Translator File

The CyberArk Vault generates audit logs internally as XML. To send these logs to Splunk via syslog, you need an XSL translator file (`SplunkCIM.xsl`) that transforms the Vault's native XML into CEF-formatted syslog messages compatible with Splunk's Common Information Model (CIM).

**Where to get it:**

1. **From this repository** — The file is included at [`Splunk_TA_cyberark/forExport/SplunkCIM.xsl`](Splunk_TA_cyberark/forExport/SplunkCIM.xsl)
2. **From the TA package** — Download the Splunk Add-on for CyberArk `.tgz` from [Splunkbase](https://splunkbase.splunk.com/app/2891), extract it, and find the file in the `forExport/` directory

### Installation Steps

#### Step 1: Install the Splunk TA

Install the `Splunk_TA_cyberark` directory (included in this repo) on your Splunk instance:

- **Splunk Enterprise**: Copy to `$SPLUNK_HOME/etc/apps/`
- **Splunk Cloud**: Install via the Splunk Cloud self-service app install, or work with Splunk support

This provides the `props.conf`, `transforms.conf`, `eventtypes.conf`, `tags.conf`, and lookup tables needed to parse and CIM-map incoming CyberArk events.

#### Step 2: Deploy the XSL Translator to the Vault Server

1. Copy `Splunk_TA_cyberark/forExport/SplunkCIM.xsl` to the CyberArk Vault server at:
   ```
   %ProgramFiles%\PrivateArk\Server\Syslog\
   ```

2. Edit `DBParm.ini` on the Vault server (located in the PrivateArk Server installation directory) and add or update the `[SYSLOG]` section:

   ```ini
   [SYSLOG]
   UseLegacySyslogFormat=Yes
   SyslogServerIP=<YOUR_SPLUNK_OR_SC4S_IP>
   SyslogServerProtocol=UDP
   SyslogServerPort=514
   SyslogTranslatorFile=Syslog\SplunkCIM.xsl
   ```

   Replace `<YOUR_SPLUNK_OR_SC4S_IP>` with the IP address of your Splunk instance, SC4S (Splunk Connect for Syslog) server, or syslog aggregator.

3. Restart the PrivateArk Server service for the changes to take effect.

#### Step 3: Configure Splunk to Receive Syslog

Set up a syslog input on your Splunk instance (or SC4S) listening on the port configured above (default UDP 514).

**Sourcetypes:**
- `cyberark:epv:cef` — for Enterprise Password Vault audit logs
- `cyberark:pta:cef` — for Privileged Threat Analytics events

#### Data Flow

```
CyberArk Vault (XML audit logs)
  → SplunkCIM.xsl transforms XML to CEF syslog
    → UDP/TCP to Splunk / SC4S / syslog aggregator
      → Splunk indexes and CIM-maps the events
```

### References

- [Splunk Add-on for CyberArk Setup Documentation](https://docs.splunk.com/Documentation/AddOns/released/CyberArk/Setup)
- [Splunk Add-on for CyberArk Installation Overview](https://docs.splunk.com/Documentation/AddOns/released/CyberArk/Installationoverview)
- [CyberArk - Create a Custom XSL Translator File](https://docs.cyberark.com/Product-Doc/OnlineHelp/PAS/Latest/en/Content/PASIMP/Create-custom-xsl-translator-file.htm)
- [Splunk Connect for Syslog - CyberArk](https://splunk.github.io/splunk-connect-for-syslog/1.96.3/sources/CyberArk/)

## Terraform Usage

### Prerequisites

- Terraform installed
- AWS CLI configured with profiles for GovCloud and Commercial accounts
- An EC2 key pair named `win2022` in the target region

### Setup

1. Update `terraform/providers.tf` with your AWS profile names
2. Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` and set your values
3. Update VPC, subnet, and AMI IDs in `terraform/main.tf` for your environment

```bash
cd terraform
terraform init
terraform plan
terraform apply
```
