# CyberArk PoC with Splunk Integration

Lab environment running the full CyberArk PAS suite (Vault, PVWA, CPM, PSM) on AWS GovCloud, plus a Splunk instance for audit-log ingestion via the Splunk Add-on for CyberArk.

## Contents
- [Environment inventory](#environment-inventory)
- [PVWA reinstall at `/pvs`](#pvwa-reinstall-at-pvs) — what changed, what ran, how to repeat
- [Splunk integration guide](#splunk-integration-guide) — XSL translator + TA deployment
- [Operational notes](#operational-notes) — DNS, RDP, SSM, cert renewal
- [References](#references)

---

## Environment inventory

**AWS account:** `172363844851` (GovCloud) — profile `172363844851_AdministratorAccess`, region `us-gov-east-1`.
**DNS zone:** `lab.aws.j2rsolutions.com` (zone ID `Z04720411Z538D0M1WL87`) lives in Commercial account `081006927100` — profile `081006927100_AdministratorAccess`.

### Live EC2 instances

| Role | Instance | Private IP | Public IP | AMI | Instance Type |
|---|---|---|---|---|---|
| Vault | `i-0477f851c99653107` | 172.0.1.63 | 18.253.143.0 | ami-0ab86f48a048a68df | t3.large |
| PVWA | `i-0c81eba78f6b95680` | 172.0.1.242 | 18.252.37.69 | ami-052dcb54a06973f54 | t3.large |
| CPM | `i-09f4aa188caf1794b` | 172.0.1.214 | 18.252.75.56 | ami-0ab86f48a048a68df | t3.large |
| PSM | `i-02eb428b8340b5fa6` | 172.0.1.43 | 18.253.173.41 | ami-0ab86f48a048a68df | m6i.2xlarge |
| DC | `i-00c0ee53e20a035b7` | 172.0.1.45 | 18.253.203.121 | ami-052dcb54a06973f54 | t3.large |
| Splunk | `i-0472127c75105976f` | 172.0.1.23 | 16.64.11.53 | — | m5.xlarge |

### DNS records (zone `lab.aws.j2rsolutions.com`)

| Record | Target |
|---|---|
| `pvwa.lab.aws.j2rsolutions.com` | 18.252.37.69 |
| `pvwa1.lab.aws.j2rsolutions.com` | 18.252.37.69 |
| `vault1.lab.aws.j2rsolutions.com` | 18.253.143.0 |
| `splunklegion0.lab.aws.j2rsolutions.com` | 16.64.11.53 |

### Installed components (status)

| Component | Installed | Notes |
|---|---|---|
| Vault | ✅ | `D:\PrivateArk\Server\` on `CyberArk-Vault`. Vault name: `Demo Vault`. |
| PVWA | ✅ | At `/pvs` — see below |
| CPM | ❌ | EC2 exists, software not installed |
| PSM | ❌ | EC2 exists, software not installed |

---

## PVWA reinstall at `/pvs`

Reinstalled CyberArk PVWA **v14.6.1** with a non-default virtual directory. Completed 2026-04-20.

**URL:** `https://pvwa.lab.aws.j2rsolutions.com/pvs/`

### Final state

| Item | Value |
|---|---|
| PVWA URL | `https://pvwa.lab.aws.j2rsolutions.com/pvs/` |
| Angular SPA base | `/pvs/v10/` |
| IIS physical path | `C:\inetpub\wwwroot\pvs\` |
| Config dir | `C:\CyberArk\Password Vault Web Access\` |
| IIS site | `Default Web Site` (applications `/pvs` and `/pvs/WebCharts`) |
| TLS cert | Let's Encrypt, `CN=pvwa.lab.aws.j2rsolutions.com`, expires **2026-05-25**, thumbprint `B9E60AB3BAEF7A35C943EE1A242505044B2C34F4` |
| Registered vault | `Demo Vault` @ `172.0.1.63:1858` (Casos) |

### Install flow — what actually ran

All install steps were driven remotely via AWS SSM (`aws ssm send-command`) against the PVWA EC2 — no RDP automation needed. SSM coverage was added during this work; see [Operational notes → SSM](#ssm-coverage).

#### Step 1 — Vault-side cleanup (on the Vault box, via RDP)

Before reinstall, delete the leftover PVWA service users so the installer can recreate them cleanly. PACLI standalone lives at `D:\CorePAS\Vault\PACLI-Rls-v14.6\Pacli.exe`:

```cmd
cd /d D:\CorePAS\Vault\PACLI-Rls-v14.6
(echo VAULT="Demo Vault"& echo ADDRESS=127.0.0.1& echo PORT=1858) > Vault.ini

Pacli INIT
Pacli DEFINEFROMFILE VAULT="Demo Vault" PARMFILE=Vault.ini
Pacli LOGON DESTUSER=Administrator
Pacli DELETEUSER DESTUSER=PVWAGWUser
Pacli DELETEUSER DESTUSER=PVWAAppUser
Pacli DELETEUSER DESTUSER=PVWAAppUser1
Pacli DELETEUSER DESTUSER=PVWAAppUser2
Pacli DELETEUSER DESTUSER=PVWAAppUser3
Pacli DELETEUSER DESTUSER=PVWAAppUser4
Pacli DELETEUSER DESTUSER=PVWAAppUser5
Pacli DELETEUSER DESTUSER=PVWAAppUser6
Pacli DELETEUSER DESTUSER=PVWAMonitor
Pacli LOGOFF
Pacli TERM
```

Vault name is in `D:\PrivateArk\Server\Conf\Vault.ini`.

#### Step 2 — Rebuild the PVWA EC2

The pre-existing PVWA box had partial-uninstall residue (registry + IIS + filesystem) causing the MSI to run in maintenance mode and ignore the new vdir setting. Replaced the instance rather than scrub it. The D: volume (installer media) has `DeleteOnTermination=false`, so it survived.

```bash
# terminate old (root volume auto-deletes, D: preserved)
aws ec2 terminate-instances --instance-ids <old-id> \
  --profile 172363844851_AdministratorAccess --region us-gov-east-1

# relaunch — same subnet/SG/key, preserve private IP, attach SSM profile
aws ec2 run-instances \
  --image-id ami-052dcb54a06973f54 \
  --instance-type t3.large \
  --key-name win2022 \
  --security-group-ids sg-01f6fd453e01fb2be \
  --subnet-id subnet-0ea3b6dca06762833 \
  --iam-instance-profile Name=CyberArk-EC2-SSM-Profile \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=CyberArk-PVWA}]' \
  --private-ip-address 172.0.1.242 \
  --profile 172363844851_AdministratorAccess --region us-gov-east-1

# reattach the preserved D: volume
aws ec2 attach-volume \
  --volume-id vol-0de94c0dcd4a0ef98 \
  --instance-id <new-id> --device /dev/sdf \
  --profile 172363844851_AdministratorAccess --region us-gov-east-1
```

Then via SSM: set local `Administrator` password to match `keys/pws` and upload `pvwa.lab.aws.j2rsolutions.com.pfx` to `C:\CyberArk-Install\pvwa.pfx`.

#### Step 3 — Prerequisites (via SSM on the new PVWA)

```powershell
cd "D:\CorePAS\Password Vault Web Access\Password Vault Web Access-Rls-v14.6.1\InstallationAutomation"
powershell -ExecutionPolicy Bypass -File .\PVWA_Prerequisites.ps1
```

Installs IIS roles (Web-Server, Web-Asp-Net45, NET-Framework-45-ASPNET, …), enables TLS 1.2, binds a temporary self-signed cert on 443 (replaced in step 6).

#### Step 4 — Install with `/pvs` — **the key step**

Edit `InstallationAutomation\Installation\InstallationConfig.xml` — three values change from vendor defaults:

```xml
<Parameter Name="PVWAApplicationDirectory" Value="C:\inetpub\wwwroot\pvs\" />
<Parameter Name="PVWAApplicationName" Value="pvs" />
<Parameter Name="PVWAUrl" Value="https://127.0.0.1/pvs" />
```

Then:

```powershell
cd "D:\CorePAS\Password Vault Web Access\Password Vault Web Access-Rls-v14.6.1\InstallationAutomation\Installation"
powershell -ExecutionPolicy Bypass -File .\PVWAInstallation.ps1
```

`PVWAApplicationName=pvs` flows into:
- IIS virtual directory name (`/pvs`)
- IIS web application physical path (`C:\inetpub\wwwroot\pvs\`)
- Angular SPA compiled constants — `baseURL: "/pvs/v10"`, `passwordVault: "/pvs"`
- Registry: `HKLM:\Software\CyberArk\PVWA\WebAppName`

Install takes ~15 min. Logs: `InstallationAutomation\Installation\Script.log` and `C:\Windows\Temp\PVWAInstall.log`.

#### Step 5 — Vault registration

Edit `InstallationAutomation\Registration\PVWARegisterComponentConfig.xml`:

```xml
<Parameter Name="vaultip" Value="172.0.1.63" />
<Parameter Name="vaultname" Value="Demo Vault" />
<Parameter Name="installpackagedir" Value="C:\inetpub\wwwroot\pvs" />
<Parameter Name="virtualDirectoryPath" Value="C:\inetpub\wwwroot\pvs" />
<Parameter Name="pvwaUrl" Value="https://127.0.0.1/pvs" />
<Parameter Name="PVWAApplicationName" Value="pvs" />
```

Then:

```powershell
cd "D:\CorePAS\Password Vault Web Access\Password Vault Web Access-Rls-v14.6.1\InstallationAutomation\Registration"
powershell -ExecutionPolicy Bypass -File .\PVWARegisterComponent.ps1 -pwd "<vault-admin-password>"
```

Runs three vendor binaries in sequence:
1. `ConfigureInstance.exe` — writes local PVWA config
2. `ConfigureVault.exe` — creates `PVWAGWUser`, `PVWAAppUser*`, `PVWAMonitor` accounts in the Vault
3. `RegisterInstance.exe` — registers this PVWA host under the Vault's component registry

Then restarts IIS app pool `PasswordVaultWebAccessPool` and starts service `CyberArk Scheduled Tasks`.

#### Step 6 — HTTPS binding with Let's Encrypt cert

Replace the prereq step's self-signed cert:

```powershell
$pw = ConvertTo-SecureString "<pfx-password>" -AsPlainText -Force
$imp = Import-PfxCertificate -FilePath C:\CyberArk-Install\pvwa.pfx `
       -CertStoreLocation Cert:\LocalMachine\My -Password $pw
$tp = $imp.Thumbprint

Import-Module WebAdministration
Get-WebBinding -Name "Default Web Site" -Port 443 -Protocol https | Remove-WebBinding
Remove-Item "IIS:\SslBindings\0.0.0.0!443" -ErrorAction SilentlyContinue
New-WebBinding -Name "Default Web Site" -Protocol https -Port 443 -IPAddress "*"
(Get-WebBinding -Name "Default Web Site" -Port 443 -Protocol https).AddSslCertificate($tp, "My")
iisreset /noforce
```

### Verification

```
$ echo | openssl s_client -connect pvwa.lab.aws.j2rsolutions.com:443 \
  -servername pvwa.lab.aws.j2rsolutions.com 2>/dev/null | openssl x509 -noout -subject -issuer -dates
subject=CN=pvwa.lab.aws.j2rsolutions.com
issuer=C=US, O=Let's Encrypt, CN=E8
notBefore=Feb 24 14:05:24 2026 GMT
notAfter=May 25 14:05:23 2026 GMT

$ curl -sk -o /dev/null -w "%{http_code}\n" https://pvwa.lab.aws.j2rsolutions.com/pvs/
302
$ curl -sk -o /dev/null -w "%{http_code}\n" https://pvwa.lab.aws.j2rsolutions.com/pvs/v10/
200
$ curl -sk -o /dev/null -w "%{http_code}\n" https://pvwa.lab.aws.j2rsolutions.com/PasswordVault/
404

$ curl -sk https://pvwa.lab.aws.j2rsolutions.com/pvs/v10/ | grep -E "<title>|baseURL|passwordVault"
  <title>Password Vault</title>
      baseURL: "/pvs/v10",
      passwordVault: "/pvs"
```

### Gotchas encountered

1. **First install attempt failed in maintenance mode.** Leftover `HKLM:\Software\CyberArk\PVWA\WebAppName=PasswordVault` + residual `C:\inetpub\wwwroot\PasswordVault\` + nested `/PasswordVault` IIS applications made the MSI ignore the new `/pvs` settings. Recovery: replaced the EC2 entirely.

2. **Original AMI `ami-0ab86f48a048a68df` is no longer launchable.** Used `ami-052dcb54a06973f54` (same as the DC). Vault/CPM/PSM still run on the old AMI — if any of those ever need replacement, expect the same issue.

3. **vcredist downgrade error** (`Error 0x80070666`) in installer logs is non-fatal — newer VC++ runtime already present, installer skips its bundled older version.

4. **PFX export password** is `solutions123!@#` (lowercase `s`) — different from the other admin passwords.

### When installing CPM / PSM next

They register against PVWA via URL. Use the new path:

```
https://pvwa.lab.aws.j2rsolutions.com/pvs/
```

`/pvs` is baked into both the SPA and the Vault's component registry. No additional vault-side changes needed to accept components pointing at the new URL.

---

## Splunk integration guide

Integrating CyberArk PAS vault audit logs with Splunk using the Splunk Add-on for CyberArk.

### Which Splunk Add-on to use

| App | Splunkbase | Use for |
|---|---|---|
| **Splunk Add-on for CyberArk** | [App 2891](https://splunkbase.splunk.com/app/2891) | EPV and PTA — **this is the one** |
| CyberArk Next-Gen Access Add-on | [App 7005](https://splunkbase.splunk.com/app/7005) | CyberArk Identity (SSO/MFA) — **not applicable** |
| Splunk Add-on for CyberArk EPM | [App 5160](https://splunkbase.splunk.com/app/5160) | CyberArk Endpoint Privilege Manager — separate product |

App 2891 is archived on Splunkbase but still functional. Extracted copy is in this repo.

### What's in this repo

```
Splunk_TA_cyberark/
├── forExport/
│   └── SplunkCIM.xsl          ← XSL translator for the Vault server
├── default/
│   ├── props.conf              ← Sourcetype definitions and parsing
│   ├── transforms.conf         ← Field extractions
│   ├── eventtypes.conf         ← Event type classifications
│   └── tags.conf               ← CIM tag mappings
├── lookups/                    ← CIM lookup tables for action codes, alerts, etc.
└── ...
```

### The XSL translator file

The CyberArk Vault emits audit logs as XML. `SplunkCIM.xsl` transforms that XML into CEF-formatted syslog that Splunk parses and maps to the Common Information Model.

Sources:
1. This repo — [`Splunk_TA_cyberark/forExport/SplunkCIM.xsl`](Splunk_TA_cyberark/forExport/SplunkCIM.xsl)
2. Splunkbase App 2891 `.tgz` → `forExport/` directory

### Installation

#### Step 1 — Install the TA on the Splunk instance

Copy `Splunk_TA_cyberark/` to:
- **Splunk Enterprise**: `$SPLUNK_HOME/etc/apps/Splunk_TA_cyberark`
- **Splunk Cloud**: self-service app install or via Splunk support

Restart Splunk.

#### Step 2 — Deploy the XSL translator to the Vault server

1. Copy `Splunk_TA_cyberark/forExport/SplunkCIM.xsl` to the Vault server at:
   ```
   %ProgramFiles%\PrivateArk\Server\Syslog\
   ```

2. Edit `DBParm.ini` on the Vault server (in the PrivateArk Server install directory) and add/update the `[SYSLOG]` section:

   ```ini
   [SYSLOG]
   UseLegacySyslogFormat=Yes
   SyslogServerIP=<YOUR_SPLUNK_OR_SC4S_IP>
   SyslogServerProtocol=UDP
   SyslogServerPort=514
   SyslogTranslatorFile=Syslog\SplunkCIM.xsl
   ```

3. Restart the **PrivateArk Server** service.

#### Step 3 — Configure Splunk to receive syslog

UDP syslog input on Splunk (or SC4S) at the configured port (default 514).

**Sourcetypes:**

| Sourcetype | Source |
|---|---|
| `cyberark:epv:cef` | Enterprise Password Vault audit logs |
| `cyberark:pta:cef` | Privileged Threat Analytics events |

### Data flow

```
CyberArk Vault (XML audit logs)
  → SplunkCIM.xsl transforms XML → CEF syslog
    → UDP/TCP to Splunk / SC4S
      → Splunk indexes and CIM-maps the events
```

---

## Operational notes

### SSM coverage

All 5 CyberArk Windows EC2s are registered with AWS Systems Manager via:
- IAM role `CyberArk-EC2-SSM-Role` (trust: `ec2.amazonaws.com`, policy: `AmazonSSMManagedInstanceCore`)
- Instance profile `CyberArk-EC2-SSM-Profile`

Interactive PowerShell session on any box:
```bash
aws ssm start-session --target <instance-id> \
  --profile 172363844851_AdministratorAccess --region us-gov-east-1
```

One-shot PowerShell:
```bash
aws ssm send-command --instance-ids <id> \
  --document-name AWS-RunPowerShellScript \
  --parameters 'commands=["..."]' \
  --profile 172363844851_AdministratorAccess --region us-gov-east-1
```

Splunk box uses a different profile (`carbide-controlplane-cloud-provider-profile`); SSM was not added to it.

### RDP files

`RDP/cyberark-{dc,vault,pvwa,cpm,psm}.rdp` — each points at the current public IP with `username=Administrator`. Local admin passwords per box are in `keys/pws`.

### Cert renewal

Expires **2026-05-25**. `keys/letsEncryptCommands` has the `openssl pkcs12 -export` command used to build the PFX from certbot output. After renewing via certbot, rebuild the PFX, re-upload to the PVWA box, re-import, rebind — see step 6 above.

### EC2 public-IP rotation

None of these instances have EIPs. Stop/start (not reboot) rotates the public IP. If you stop a box, DNS + RDP files + (if it's the Vault or PVWA) `PARAgent.ini` on the Vault need re-sync. Attaching EIPs to Vault/PVWA/CPM/PSM/DC would prevent this.

### IaC drift

Nothing from the recent infrastructure work (SSM IAM role, new PVWA instance, current DNS records) is in Terraform. The `terraform/` directory on `main` is empty; the original `.tf` sources live on the `infrastructure` branch but haven't been updated. State file at `terraform/terraform.tfstate` is stale. When formalizing, import: the new PVWA instance + volume attachment, the SSM IAM role + profile + its 5 attachments, and the Route 53 records.

### Credentials reference

Local Windows Administrator passwords per box — see `keys/pws`. Vault admin, PVWA admin, domain admin, and PFX export passwords are kept out of this repo.

---

## References

- [Splunk Add-on for CyberArk — Setup](https://docs.splunk.com/Documentation/AddOns/released/CyberArk/Setup)
- [Splunk Add-on for CyberArk — Installation Overview](https://docs.splunk.com/Documentation/AddOns/released/CyberArk/Installationoverview)
- [CyberArk — Create a Custom XSL Translator File](https://docs.cyberark.com/Product-Doc/OnlineHelp/PAS/Latest/en/Content/PASIMP/Create-custom-xsl-translator-file.htm)
- [Splunk Connect for Syslog — CyberArk Source](https://splunk.github.io/splunk-connect-for-syslog/1.96.3/sources/CyberArk/)
- [CyberArk SIEM Integration Guide](https://docs.cyberark.com/Product-Doc/OnlineHelp/PAS/Latest/en/Content/PASIMP/DV-Integrating-with-SIEM-Applications.htm)
