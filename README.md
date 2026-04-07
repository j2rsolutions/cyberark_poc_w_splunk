# CyberArk Splunk Integration Guide

Instructions and resources for integrating CyberArk Privileged Access Security (PAS) vault audit logs with Splunk using the Splunk Add-on for CyberArk.

## Which Splunk Add-on to Use

There are multiple CyberArk-related apps on Splunkbase. For CyberArk PAS (Vault, PVWA, PSM, CPM), you need:

| App | Splunkbase | Use For |
|-----|-----------|---------|
| **Splunk Add-on for CyberArk** | [App 2891](https://splunkbase.splunk.com/app/2891) | EPV and PTA — this is the one you need |
| CyberArk Next-Gen Access Add-on | [App 7005](https://splunkbase.splunk.com/app/7005) | CyberArk Identity (SSO/MFA) — **not applicable here** |
| Splunk Add-on for CyberArk EPM | [App 5160](https://splunkbase.splunk.com/app/5160) | CyberArk Endpoint Privilege Manager — separate product |

**App 7005 (Next-Gen Access) is for CyberArk Identity**, which handles SSO and MFA. It is a completely different product from the PAS suite and is not relevant to this integration.

App 2891 has been archived on Splunkbase but remains functional. The full extracted add-on is included in this repository.

## What's in This Repo

```
Splunk_TA_cyberark/
├── forExport/
│   └── SplunkCIM.xsl          ← XSL translator file for the Vault server
├── default/
│   ├── props.conf              ← Sourcetype definitions and parsing
│   ├── transforms.conf         ← Field extractions
│   ├── eventtypes.conf         ← Event type classifications
│   └── tags.conf               ← CIM tag mappings
├── lookups/                    ← CIM lookup tables for action codes, alerts, etc.
└── ...
```

## The XSL Translator File

The CyberArk Vault generates audit logs internally as XML. The **SplunkCIM.xsl** translator file transforms that XML into CEF-formatted syslog messages that Splunk can parse and map to the Common Information Model (CIM).

**You can get this file from:**
1. **This repository** — [`Splunk_TA_cyberark/forExport/SplunkCIM.xsl`](Splunk_TA_cyberark/forExport/SplunkCIM.xsl)
2. **The TA tarball** — Download the `.tgz` from [Splunkbase App 2891](https://splunkbase.splunk.com/app/2891) and extract it; the file is in the `forExport/` directory

## Installation

### Step 1: Install the Splunk TA on Your Splunk Instance

Copy the `Splunk_TA_cyberark` directory to your Splunk apps folder:

- **Splunk Enterprise**: `$SPLUNK_HOME/etc/apps/Splunk_TA_cyberark`
- **Splunk Cloud**: Install via the self-service app install or work with Splunk support

Restart Splunk after installation.

### Step 2: Deploy the XSL Translator to the CyberArk Vault Server

1. Copy `Splunk_TA_cyberark/forExport/SplunkCIM.xsl` to the Vault server:
   ```
   %ProgramFiles%\PrivateArk\Server\Syslog\
   ```

2. Edit `DBParm.ini` on the Vault server (in the PrivateArk Server installation directory) and add or update the `[SYSLOG]` section:

   ```ini
   [SYSLOG]
   UseLegacySyslogFormat=Yes
   SyslogServerIP=<YOUR_SPLUNK_OR_SC4S_IP>
   SyslogServerProtocol=UDP
   SyslogServerPort=514
   SyslogTranslatorFile=Syslog\SplunkCIM.xsl
   ```

   Replace `<YOUR_SPLUNK_OR_SC4S_IP>` with the IP address of your Splunk instance, SC4S (Splunk Connect for Syslog) server, or syslog aggregator.

3. Restart the **PrivateArk Server** service.

### Step 3: Configure Splunk to Receive Syslog

Set up a UDP syslog input on Splunk (or SC4S) listening on the port configured above (default 514).

**Sourcetypes:**
| Sourcetype | Source |
|-----------|--------|
| `cyberark:epv:cef` | Enterprise Password Vault audit logs |
| `cyberark:pta:cef` | Privileged Threat Analytics events |

### Data Flow

```
CyberArk Vault (XML audit logs)
  → SplunkCIM.xsl transforms XML to CEF syslog
    → UDP/TCP to Splunk / SC4S / syslog aggregator
      → Splunk indexes and CIM-maps the events
```

## References

- [Splunk Add-on for CyberArk — Setup Documentation](https://docs.splunk.com/Documentation/AddOns/released/CyberArk/Setup)
- [Splunk Add-on for CyberArk — Installation Overview](https://docs.splunk.com/Documentation/AddOns/released/CyberArk/Installationoverview)
- [CyberArk — Create a Custom XSL Translator File](https://docs.cyberark.com/Product-Doc/OnlineHelp/PAS/Latest/en/Content/PASIMP/Create-custom-xsl-translator-file.htm)
- [Splunk Connect for Syslog — CyberArk Source](https://splunk.github.io/splunk-connect-for-syslog/1.96.3/sources/CyberArk/)
- [CyberArk SIEM Integration Guide (Privileged Account Security Implementation Guide)](https://docs.cyberark.com/Product-Doc/OnlineHelp/PAS/Latest/en/Content/PASIMP/DV-Integrating-with-SIEM-Applications.htm)
