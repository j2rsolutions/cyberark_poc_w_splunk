# CLAUDE.md

Orientation for anyone (human or AI assistant) working in this repo. For deep
operational detail — PVWA reinstall steps, Splunk TA deployment, cert renewal —
see `README.md`. This file is the high-level "what and why."

## Purpose

This is a **proof-of-concept lab** that stands up the full **CyberArk Privileged
Access Security (PAS) suite** on **AWS GovCloud** and integrates its audit logs
with **Splunk** via the Splunk Add-on for CyberArk. It exists to demonstrate and
validate privileged access management with security monitoring — it is a
demo/lab environment, not production.

Owner: Jonathan Spigler, J2R Solutions.

## What's deployed

CyberArk components run as Windows Server EC2 instances in GovCloud
(`us-gov-east-1`, account `172363844851`):

| Role | Purpose | Software installed? |
|---|---|---|
| Vault | PrivateArk Server — the encrypted credential store (`Demo Vault`) | ✅ |
| PVWA | Password Vault Web Access — web UI, served at `/pvs` (not the default `/PasswordVault`) | ✅ |
| CPM | Central Policy Manager — credential rotation | ❌ EC2 only |
| PSM | Privileged Session Manager — session brokering/recording | ❌ EC2 only |
| DC | Domain Controller (`testlab.local` / Active Directory) | ✅ |
| Splunk | Audit-log ingestion (separate account/profile) | ✅ |

Authoritative instance IDs, IPs, AMIs, and DNS records live in
`README.md → Environment inventory` — that table is the source of truth.

## Repo layout

- `README.md` — primary runbook: environment inventory, PVWA `/pvs` reinstall, Splunk integration, operational notes (DNS, RDP, SSM, cert renewal).
- `terraform/` — IaC for reattaching/importing existing infra (`imports.tf`, `generated.tf`, `providers.tf`). See "Terraform state" below — this lags the live environment.
- `Splunk_TA_cyberark/` — extracted Splunk Add-on for CyberArk (App 2891). Contains `forExport/SplunkCIM.xsl`, the XSL translator that turns Vault XML audit logs into CEF syslog Splunk can CIM-map.
- `splunk-add-on-for-cyberark_120.tgz` — original packaged add-on (gitignored).
- `RDP/` — `.rdp` files per box, each pointing at the current public IP, `username=Administrator`.
- `powershell/` — AD setup / DNS helper scripts.
- `keys/` — key pair (`win2022.pem`) and `pws` (per-box local Administrator passwords). **Secret material — do not commit beyond what's already here, do not exfiltrate.**
- `vault.crt` / `vault.key`, `pvwa.lab.aws.j2rsolutions.com.pfx` — TLS cert material.

## Key conventions

- **AWS profiles** (named CLI profiles, not keys in this repo):
  - `172363844851_AdministratorAccess` — **GovCloud**, `us-gov-east-1`. Default for almost everything; all CyberArk infra lives here.
  - `081006927100_AdministratorAccess` — **Commercial**, `us-east-1`. Only for Route 53 DNS in zone `lab.aws.j2rsolutions.com`.
- **Remote administration is via AWS SSM, not RDP automation.** All 5 CyberArk Windows boxes carry instance profile `CyberArk-EC2-SSM-Profile` (role `CyberArk-EC2-SSM-Role`). Use `aws ssm start-session` for interactive, `aws ssm send-command` (`AWS-RunPowerShellScript`) for one-shot. The Splunk box is not SSM-managed.
- **PVWA path is `/pvs`**, not the vendor default `/PasswordVault`. `https://pvwa.lab.aws.j2rsolutions.com/pvs/`. This is baked into the IIS vdir, the Angular SPA, and the Vault's component registry — any future CPM/PSM registration must point at the `/pvs` URL.
- **No EIPs.** Stopping (vs. rebooting) any instance rotates its public IP, which then desyncs DNS, the `RDP/` files, and Vault-side configs. Prefer not to stop boxes; consider EIPs if formalizing.

## Gotchas

- Original AMI `ami-0ab86f48a048a68df` (Vault/CPM/PSM) is **no longer launchable**. Replacements must use `ami-052dcb54a06973f54`.
- PFX export password is `solutions123!@#` (lowercase `s`) — different from the box admin passwords in `keys/pws`.
- TLS cert (Let's Encrypt, `CN=pvwa.lab.aws.j2rsolutions.com`) expires **2026-05-25**; renewal flow is in `README.md → Cert renewal`.

## Terraform state

`terraform/` does **not** reflect the live environment. Recent infra changes
(SSM IAM role, the rebuilt PVWA instance, current Route 53 records) were made
out-of-band and are not yet captured in IaC. Treat the AWS account + `README.md`
as ground truth; treat Terraform here as a work-in-progress reattach effort.
When formalizing, import: the current PVWA instance + volume attachment, the SSM
IAM role/profile and its 5 attachments, and the Route 53 records.

## Working norms

- Jonathan prefers autonomous execution with minimal tool prompts.
- This is sensitive security infrastructure: never exfiltrate credentials, keys, or vault contents; confine destructive AWS actions (terminate, delete) to explicit instruction and double-check the target instance/account/region first.
