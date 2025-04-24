<#
.SYNOPSIS
    Starts a PowerShell transcript with automatic log file rotation.

.DESCRIPTION
    The Start-Logging function initiates PowerShell session logging using the Start-Transcript cmdlet and manages up to three rotating log files.
    It checks whether the specified log files exist and whether their sizes exceed a defined limit. If all logs exist and are over the limit, it deletes the oldest one and starts logging into it again.
    
    This is useful for maintaining consistent logs in long-running or recurring scripts without allowing log files to grow indefinitely.

.PARAMETER LogFile1
    Path to the primary log file.

.PARAMETER LogFile2
    Path to the secondary log file, used if LogFile1 exceeds the size limit.

.PARAMETER LogFile3
    Path to the tertiary log file, used if both LogFile1 and LogFile2 exceed the size limit.

.PARAMETER LimitSize
    Maximum allowed size for a log file in bytes before rotating to the next file. Default is 10MB.

.EXAMPLE
    Start-Logging -LogFile1 "C:\Logs\log1.txt" -LogFile2 "C:\Logs\log2.txt" -LogFile3 "C:\Logs\log3.txt"

    Starts a PowerShell transcript and writes to the appropriate log file depending on file size and availability.
#>

function Start-Logging {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [System.String]$LogFile1,

        [Parameter(Mandatory=$true)]
        [System.String]$LogFile2,
        
        [Parameter(Mandatory=$true)]
        [System.String]$LogFile3,

        [Parameter(Mandatory=$false)]
        [System.Int32]$LimitSize = 10MB
    )

    function Get-CreationTime {
        param (
            [Parameter(Mandatory=$true)]
            [System.String]$Path
        )

        if (Test-Path $Path) {
            return (Get-Item $Path).CreationTime
        } else {
            return $null
        }
    }
    function Get-FileSize {
        param (
            [Parameter(Mandatory)]
            [System.String]$Path
        )

        if (Test-Path $Path) {
            return (Get-Item $Path).Length
        } else {
            return $null
        }
    }

    $CreationTimeFileLog1 = Get-CreationTime $LogFile1
    $CreationTimeFileLog2 = Get-CreationTime $LogFile2
    $CreationTimeFileLog3 = Get-CreationTime $LogFile3

    $SizeFileLog1 = Get-FileSize $LogFile1
    $SizeFileLog2 = Get-FileSize $LogFile2
    $SizeFileLog3 = Get-FileSize $LogFile3

    if ((-not(Test-Path -Path $LogFile1)) -and (-not(Test-Path -Path $LogFile2)) -and (-not(Test-Path -Path $LogFile3))) {
        Start-Transcript -Append -Path $LogFile1 -Force
        Write-Host "[+] Started transcript on $LogFile1" -ForegroundColor Green
    }
    else {     
        if ((Test-Path -Path $LogFile1) -and (-not(Test-Path -Path $LogFile2)) -and (-not(Test-Path -Path $LogFile3))) {
            if ($SizeFileLog1 -gt $LimitSize) {
                Start-Transcript -Append -Path $LogFile2 -Force
                Write-Host "[+] Started transcript on $LogFile2" -ForegroundColor Green
            }
            else {
                Start-Transcript -Append -Path $LogFile1 -Force
                Write-Host "[+] Started transcript on $LogFile1" -ForegroundColor Green
            }
        }
        elseif ((Test-Path -Path $LogFile1) -and (Test-Path -Path $LogFile2) -and (-not(Test-Path -Path $LogFile3))) {
            if ($SizeFileLog2 -gt $LimitSize) {
                Start-Transcript -Append -Path $LogFile3 -Force
                Write-Host "[+] Started transcript on $LogFile3" -ForegroundColor Green
            }
            else {
                Start-Transcript -Append -Path $LogFile2 -Force
                Write-Host "[+] Started transcript on $LogFile2" -ForegroundColor Green
            }
        }
        elseif ((Test-Path $LogFile1) -and (Test-Path $LogFile2) -and (Test-Path $LogFile3)) {
            if (($SizeFileLog3 -gt $LimitSize) -and ($SizeFileLog2 -gt $LimitSize) -and ($SizeFileLog1 -gt $LimitSize)) {
                $AllLogFiles = @{
                    $LogFile1 = $CreationTimeFileLog1
                    $LogFile2 = $CreationTimeFileLog2
                    $LogFile3 = $CreationTimeFileLog3
                }
                $OldestLogFile = $AllLogFiles.GetEnumerator() | Sort-Object Value | Select-Object -First 1
                try {
                    Remove-Item -Path $OldestLogFile.Key -Force -ErrorAction Stop
                    Start-Transcript -Append -Path $OldestLogFile.Key -Force
                    Write-Host "[+] Started transcript on $($OldestLogFile.Key)" -ForegroundColor Green
                } catch {
                    Write-Error "[-] Failed to remove or write to $($OldestLogFile.Key): $_"
                }
            }
            elseif ($SizeFileLog1 -lt $LimitSize) {
                Start-Transcript -Append -Path $LogFile1 -Force
                Write-Host "[+] Started transcript on $LogFile2" -ForegroundColor Green
            }
            elseif ($SizeFileLog2 -lt $LimitSize) {
                Start-Transcript -Append -Path $LogFile2 -Force
                Write-Host "[+] Started transcript on $LogFile2" -ForegroundColor Green
            }
            elseif ($SizeFileLog3 -lt $LimitSize) {
                Start-Transcript -Append -Path $LogFile3 -Force
                Write-Host "[+] Started transcript on $LogFile2" -ForegroundColor Green
            }
        }
        else {
            Start-Transcript -Append -Path $LogFile3 -Force
            Write-Host "[+] Started transcript on $LogFile2" -ForegroundColor Green
        }
    }
}
