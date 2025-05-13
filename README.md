
# Log-Manager

## Introduction

**Log-Manager** is a PowerShell-based toolkit designed to streamline log management and automate routine administrative tasks across Microsoft services such as Azure, Power Automate, SharePoint, and Microsoft Forms (MForms).

## Summary

- [Features](#features)
- [Detailed Module: Start-Logging](#detailed-module-start-logging)
- [Part 1: JOINER.ps1](#part-1-joinerps1)
- [Joiner Installation](#joiner-installation)
- [Part 2: LEAVER.ps1](#part-2-leaverps1)
- [Leaver Installation](#leaver-installation)
- [Email Behavior](#email-behavior)
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

### Joiner Installation

1. Clone the repo:

```powershell
git clone https://github.com/RedZNouggy/Log-Manager.git
cd Log-Manager
```

2. Replace placeholders in the script:
- `<USERNAMEDIRECTORY>`, `<SiteId>`, `<DOMAIN>`, `<MYEMAIL>`...

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

### Leaver Installation

Same setup as `JOINER.ps1`:

```powershell
git clone https://github.com/RedZNouggy/Log-Manager.git
cd Log-Manager
```

Customize fields in script:
- `<USERNAMEDIRECTORY>`, `<EMAIL>`, `<SiteId>`, `<DOMAIN>`, ...

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

## Email Behavior

### Purpose

Both `JOINER.ps1` and `LEAVER.ps1` send summary reports via Microsoft Graph email to inform administrators of the script execution results.

### Conditions for Sending

- Emails are always sent at the end of script execution.
- The content is dynamically generated depending on the success or failure of actions.

### JOINER.ps1

- **If all users are created successfully**:
  - Lists new users in green with confirmation.
- **If there are failures**:
  - Lists successful users in green.
  - Adds a red section with users for whom account creation failed.

### LEAVER.ps1

- **If all users are disabled successfully**:
  - Lists all processed users.
- **If there are issues**:
  - Includes two red sections:
    - One for accounts that failed to be disabled.
    - Another for email addresses that matched no AD user.

### Format

- Emails are formatted in HTML with inline colors (green for success, red for errors).
- Example subjects:
  - `"New JOINERS List"`
  - `"New JOINERS List & Errors"`
  - `"New LEAVERS List"`
  - `"New LEAVERS List & Errors"`

### Configuration

The recipient email must be configured in the variable:
```powershell
$MyEmailAddress = "<YOUR_EMAIL>"
```

Ensure the Microsoft Graph app has permission to use `Mail.Send` scope.
