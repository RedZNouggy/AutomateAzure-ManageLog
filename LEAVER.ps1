<#
.DESCRIPTION
    This script import users from a sharepoint into your local AD & send an email
    The script has been created by Samuel PAGES 
    Date : 25/03/2025
    Edited : 23/04/2025
#>

Begin {
    Remove-Variable * -ErrorAction SilentlyContinue
    Remove-Module * -ErrorAction SilentlyContinue
    $error.Clear()
    Clear-Host
    $Username = "<USERNAMEDIRECTORY>"

    if (-not (Get-Command Start-Logging -ErrorAction SilentlyContinue)) {
        $ModuleName  = "LogModules"
        $ModuleVersion = '1.0.0'
        $SourceDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
        $TargetDir   = Join-Path -Path "C:\Users\$UserName" -ChildPath "Documents\WindowsPowerShell\Modules\$ModuleName"
        $SourceManifestPath = Join-Path $SourceDir "LogModules.psd1"

        if (-not (Test-Path $SourceManifestPath)) {
            Write-Host "[i] LogModules.psd1 not found, generating it..." -ForegroundColor Blue
            try {
                New-ModuleManifest -Path $SourceManifestPath `
                    -RootModule "LogModules.psm1" `
                    -Author "Samuel PAGES" `
                    -Description "Logging module to handle transcript rotation in PowerShell scripts" `
                    -FunctionsToExport "Start-Logging" `
                    -PowerShellVersion "5.1" `
                    -ModuleVersion $ModuleVersion `
                    -GUID ([guid]::NewGuid())
                Write-Host "[+] Manifest created: $SourceManifestPath" -ForegroundColor Green
            } 
            catch {
                Write-Error "[-] Failed to create manifest: $_"
                exit 1
            }
        }
        $SourceVersion = (Test-ModuleManifest -Path $SourceManifestPath).ModuleVersion
        $InstalledModule = Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1
        $NeedsInstall = $true
        if ($InstalledModule) {
            $InstalledVersion = $InstalledModule.Version
            if ($InstalledVersion -ge $SourceVersion) {
                Write-Host "[i] Installed version is up-to-date. Skipping install." -ForegroundColor Blue
                $NeedsInstall = $false
            } else {
                Write-Warning "[!] Installed version is outdated. Proceeding with update..."
            }
        } else {
            Write-Host "[i] Module not installed. Proceeding with initial install..." -ForegroundColor Blue
        }

        if ($NeedsInstall) {
            if (-not (Test-Path $TargetDir)) {
                New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
            }
            $ModuleFiles = @("LogModules.psm1", "LogModules.psd1")
            foreach ($file in $ModuleFiles) {
                $SrcFile = Join-Path $SourceDir $file
                $DstFile = Join-Path $TargetDir $file

                if (Test-Path $SrcFile) {
                    Copy-Item -Path $SrcFile -Destination $DstFile -Force
                } 
                else {
                    Write-Error "[-] Missing file: $SrcFile"
                    exit 1
                }
            }
            try {
                Import-Module $ModuleName -Force
                Write-Host "[+] Module '$ModuleName' imported successfully." -ForegroundColor Green
            } catch {
                Write-Error "[-] Failed to import module after install: $_"
                exit 1
            }
        }
    }
    Start-Logging -LogFile1 "C:\Users\$Username\Desktop\LEAVER-1.log" `
                  -LogFile2 "C:\Users\$Username\Desktop\LEAVER-2.log" `
                  -LogFile3 "C:\Users\$Username\Desktop\LEAVER-3.log"
    function EnsureModule {
        param (
            [Parameter(Mandatory=$true)]
            [string]$ModuleName
        )
    
        if (Get-InstalledModule -Name $ModuleName -ErrorAction SilentlyContinue) {
            Import-Module $ModuleName -ErrorAction Stop
            Write-Host "[i] The Module '$ModuleName' has been imported" -ForegroundColor Blue
        }
        else {
            try {
                Install-Module -Name $ModuleName -Force -Scope CurrentUser -ErrorAction Stop
                Import-Module $ModuleName -ErrorAction Stop
                Write-Host "[i] The Module '$ModuleName' has been installed and imported" -ForegroundColor Blue
            }
            catch {
                Write-Error "[-] The Module '$ModuleName' cannot be installed or imported"
            }
        }
    }
    EnsureModule -ModuleName 'Microsoft.Graph.Sites'
    EnsureModule -ModuleName 'Microsoft.Graph.Users.Actions'
}

Process {
    $scopes = "Sites.ReadWrite.All","Mail.Send"
    Connect-MgGraph -Scopes $scopes -NoWelcome
    $SiteID = "<>"
    $listIdLEAVER = "<>"
    $LEAVER = Get-MgSiteListItem -SiteId $siteId -ListId $listIdLEAVER -ExpandProperty Fields -All 
    $Body = ""
    $ErrorList1 = ""
    $ErrorList2 = ""
    $MyEmailAddress = "<EMAIL>"
    foreach ($user in $LEAVER)
    {
        $UserFields = $user.Fields.AdditionalProperties
        if ($UserFields.TRAITEPOWERSHELL -like $false) {
            $filter = "EmailAddress -eq '$($UserFields.MAILDEPART)'"
            $user = Get-ADUser -Filter $filter
            if ($user) {
                Disable-ADAccount -Identity $user
                if ($user.disabled) {
                    Write-Host "[+] The account $($user.Name) has been successfully disabled." -ForegroundColor Green
                    Update-MgSiteListItemField -SiteId $siteId -ListId $listIdLEAVER -ListItemId 1 -BodyParameter @{"TRAITEPOWERSHELL"="True"} 
                    $Body +=  "<br> $($UserFields.NOM) $($UserFields.PRENOM)"
                }
                else {
                    Write-Error "[-] An error occurred trying to disabling the account : $($user.Name)" -ForegroundColor Red
                    $ErrorList1 += "<br> $($user.Name) ($($UserFields.MAILDEPART))"
                }
            } else {
                Write-Error "[-] No user has been found with the following email address : $($UserFields.MAILDEPART)" -ForegroundColor Red
                $ErrorList2 += "<br> $($UserFields.MAILDEPART)"
            }
        }
    }
    
    if(($ErrorList1 -ne "") -or ($ErrorList2 -ne "")) {
        $Subject = "New LEAVERS List & Errors"
        $Content = @"
        Hello, <br><br>

        <strong style="color:green;">This is the list of leavers that has been successfully processed by the script:</strong><br>
        <span style="color:darkgreen;">$Body</span>
        <br><br>

        <strong style='color:red;'>An error occurred trying to disable the following accounts :</strong><br>
        <span style='color:crimson;'>$ErrorList1</span>
        <br><br>

        <strong style='color:red;'>No user has been found with the following email addresses :</strong><br>
        <span style='color:crimson;'>$ErrorList2</span>
"@
    }
    else { 
        $Subject = "New LEAVERS List"
        $Content = @"
        Hello, <br><br>

        <strong style="color:green;">This is the list of leavers that has been successfully processed by the script:</strong><br>
        <span style="color:darkgreen;">$Body</span>
        <br><br>
"@
    }
    $params = @{
        Message = @{
            Subject = $Subject
            Body = @{
                ContentType = "HTML"
                Content = $Content
            }
            ToRecipients = @(
                @{
                    EmailAddress = @{
                        Address = "$MyEmailAddress"
                    }
                }
            )
        }
    }
    Send-MgUserMail -UserId "$MyEmailAddress" -BodyParameter $params      
    Write-Host "[+] Leavers List - Mail sent to $MyEmailAddress" -ForegroundColor Green
}

End {
    Disconnect-MgGraph
    Stop-Transcript
}
