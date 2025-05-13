
# Log-Manager

## Introduction

**Log-Manager** is a PowerShell-based toolkit designed to streamline log management and automate routine administrative tasks across Microsoft services such as Azure, Power Automate, SharePoint, and Microsoft Forms (MForms).

## Summary

- [Features](#features)
- [Detailed Module: Start-Logging](#detailed-module-start-logging)
- [Part 1: JOINER.ps1](#part-1-joinerps1)
- [Part 2: LEAVER.ps1](#part-2-leaverps1)
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Automated Logging**: Manage logs efficiently across multiple Microsoft platforms with rotation support.
- **JOINER.ps1**: Onboard new users from SharePoint into Active Directory with mail reporting.
- **LEAVER.ps1**: Offboard users from SharePoint, disable their AD accounts, and report via email.
- **LogModules.psm1**: PowerShell module for managing log transcripts with rotation.

---

## Detailed Module: Start-Logging

**Start-Logging** is a function that enables PowerShell transcript logging with automatic rotation between up to three log files.

### Parameters

- `LogFile1`, `LogFile2`, `LogFile3`: Required paths for log rotation.
- `LimitSize`: Optional size threshold in bytes (default 10MB).

### Example

```powershell
Start-Logging -LogFile1 "C:\Logs\log1.txt" -LogFile2 "C:\Logs\log2.txt" -LogFile3 "C:\Logs\log3.txt"
```

---

## Part 1: JOINER.ps1

### Explanation

Automates onboarding by:

- Connecting to Microsoft Graph
- Fetching SharePoint list of new users
- Creating AD user accounts
- Logging all actions
- Sending HTML email summary

### Installation

1. Clone the repo:

```powershell
git clone https://github.com/RedZNouggy/Log-Manager.git
cd Log-Manager
```

2. Replace placeholders in the script:
- `<USERNAMEDIRECTORY>`, `<SiteId>`, `<DOMAIN>`, `<MYEMAIL>`,...`

3. Prepare your environment:
- OU structure for user accounts
- Valid certificate-based authentication for Microsoft Graph

### How to Start

```powershell
.\JOINER.ps1
```

Script will:
- Create users in AD with generated passwords
- Update SharePoint field `TRAITEPOWERSHELL`
- Send results via email

---

## Part 2: LEAVER.ps1

### Explanation

Automates offboarding by:

- Connecting to Microsoft Graph
- Fetching SharePoint list of departing users
- Disabling corresponding AD accounts
- Logging all actions
- Sending HTML email report with success and error summary

### Installation

Same setup as `JOINER.ps1`:

```powershell
git clone https://github.com/RedZNouggy/Log-Manager.git
cd Log-Manager
```

Customize fields in script:
- `<USERNAMEDIRECTORY>`, `<EMAIL>`, `<SiteId>`, `<DOMAIN>`...

### How to Start

```powershell
.\LEAVER.ps1
```

Script will:
- Disable existing AD accounts matching SharePoint entries
- Update SharePoint field `TRAITEPOWERSHELL`
- Send email with lists of successes and failures

---

## Utility Function: Ensure-Module

### Purpose

`Ensure-Module` is a helper function used in both JOINER and LEAVER scripts to make sure required PowerShell modules are available.

### Behavior

- Checks if a module is already installed
- Installs it if missing (scope: current user)
- Imports the module once verified

### Example

```powershell
EnsureModule -ModuleName 'Microsoft.Graph.Users.Actions'
```

This function simplifies module management and reduces external setup friction.
