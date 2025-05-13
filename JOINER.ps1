<#
.DESCRIPTION
    This script import users from a sharepoint into your local AD & send an email
    The script has been created by Samuel PAGES
    Creation Date : 25/03/2025
    Updated : 23/04/2025
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
                Write-Host "[i] Created $TargetDir" -ForegroundColor Blue
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
    Start-Logging -LogFile1 "C:\Users\$Username\Desktop\JOINER-1.log" `
                  -LogFile2 "C:\Users\$Username\Desktop\JOINER-2.log" `
                  -LogFile3 "C:\Users\$Username\Desktop\JOINER-3.log"
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
    $tenantId = "<>"
    $clientId = "<>"
    $thumbprint = "<>"
    
    Connect-MgGraph -ClientId $clientId -TenantId $tenantId -CertificateThumbprint $thumbprint -NoWelcome
    $SiteID = "<>"
    $listIdJOINER = "<>"
    $JOINER = Get-MgSiteListItem -SiteId $siteId -ListId $listIdJOINER -ExpandProperty Fields -All 
    $MyEmailAddress = "<MYEMAIL>"
    $Body = ""
    $ErrorList = ""
    foreach ($user in $JOINER)
    {
        $UserFields = $user.Fields.AdditionalProperties
        if ($UserFields.TRAITEPOWERSHELL -like $false) {
            if ( Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=OU=$($UserFields.SERVICE),OU=PROJET_USERS,DC=<DOMAIN>,DC=<DOMAIN>)") {
                Write-Host "[i] The OU $($UserFields.SERVICE) has already been created" -ForegroundColor Blue
            }
            $Password = "Pr0j3t_U5ers@$(Get-Random -Minimum 1000 -Maximum 9999)"
            $SecurePassword = ConvertTo-SecureString -AsPlainText $Password -Force
            $SamAccountName = "$(($UserFields.NOM).ToLower())" + "." + "$(($UserFields.PRENOM).ToLower())"
            $DisplayName = "$($UserFields.NOM)" + " $($UserFields.PRENOM)"
            $PrincipalName = $SamAccountName + "@<DOMAIN>.<DOMAIN>"
            New-ADUser  -Name $DisplayName `
                        -Surname $UserFields.NOM `
                        -Path "OU=$($UserFields.SERVICE),OU=PROJET_USERS,DC=<DOMAIN>,DC=<DOMAIN>" `
                        -SamAccountName $SamAccountName `
                        -Department $UserFields.SERVICE `
                        -DisplayName $DisplayName `
                        -UserPrincipalName $PrincipalName `
                        -EmailAddress $UserFields.MAILUSER `
                        -GivenName $UserFields.PRENOM `
                        -Title $UserFields.INTITULEPOSTE `
                        -AccountPassword $SecurePassword `
                        -ChangePasswordAtLogon $true `
                        -Enabled $true
            if (Get-ADUser -Filter "samaccountname -eq '$($SamAccountName)'") {
                Write-Host "[+] The user $DisplayName has been successfully created with password: $Password" -ForegroundColor Green
            }
            else {
                Write-Error "[-] An error occurred during the user creation: $($users.SamAccountName)"
                $ErrorList += "<br> $($user.SamAccountName)"
            }
            Update-MgSiteListItemField -SiteId $siteId -ListId $listIdJOINER -ListItemId $user.Id -BodyParameter @{"TRAITEPOWERSHELL"="True"} 
            Write-Host "[i] The user $($UserFields.NOM) $($UserFields.PRENOM) updated field : TRAITEPOWERSHELL to True" -ForegroundColor Blue
            $Body += "$($UserFields.NOM) $($UserFields.PRENOM) <br>"
            Write-Host "[i] The user $($UserFields.NOM) $($UserFields.PRENOM) has been added to the mail list" -ForegroundColor Blue
        }
        else {
            Write-Host "[!] The user '$($UserFields.NOM) $($UserFields.PRENOM)' has already been processed by the script" -ForegroundColor Yellow
        }
    } 

    if ($ErrorList -ne "") {
        $Subject = "New JOINERS List & Errors"
        $Content = @"
        Hello, <br><br>

        <strong style="color:green;">This is the list of new joiners that has been successfully processed by the script:</strong><br>
        <span style="color:darkgreen;">$Body</span>
        <br><br>

        <strong style="color:red;">The joiner script has failed during the user creation of :</strong><br>
        <span style="color:crimson;">$ErrorList</span>
"@
    } 
    else { 
        $Subject = "New JOINERS List"
        $Content = @"
        Hello, <br><br>

        <strong style="color:green;">This is the list of new joiners that has been successfully processed by the script :</strong><br>
        <span style="color:darkgreen;">$Body</span>
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
    Write-Host "[+] Joiner List - Mail sent to $MyEmailAddress" -ForegroundColor Green
}

End {
    Disconnect-MgGraph
    Stop-Transcript
}
