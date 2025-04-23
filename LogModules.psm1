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
                Write-Host "[+] Started transcript on $LogFile2"
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
    Stop-Transcript
}
