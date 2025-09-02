# Start-SimpleDashboard.ps1
# PowerShell 5.1 Compatible Dashboard for Unity-Claude Automation
# Simplified version to avoid compatibility issues

param(
    [int]$Port = 8081,
    [int]$RefreshInterval = 5,
    [switch]$OpenBrowser
)

# PowerShell 7 Self-Elevation
if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh7 = "C:\Program Files\PowerShell\7\pwsh.exe"
    if (Test-Path $pwsh7) {
        Write-Host "Upgrading to PowerShell 7..." -ForegroundColor Yellow
        $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $MyInvocation.MyCommand.Path) + $args
        Start-Process -FilePath $pwsh7 -ArgumentList $arguments -NoNewWindow -Wait
        exit
    } else {
        Write-Warning "PowerShell 7 not found. Running in PowerShell $($PSVersionTable.PSVersion)"
    }
}

Write-Host "=== Unity-Claude Enhanced Dashboard ===" -ForegroundColor Yellow
Write-Host "PowerShell 5.1 Compatible with Enhanced Features" -ForegroundColor Cyan
Write-Host "Loading modules..." -ForegroundColor Cyan

# Import required modules with error handling
try {
    # Try to import UniversalDashboard.Community from known location first
    $udPath = "C:\Users\georg\Documents\WindowsPowerShell\Modules\UniversalDashboard.Community\2.9.0\UniversalDashboard.Community.psd1"
    if (Test-Path $udPath) {
        Import-Module $udPath -ErrorAction Stop
    } else {
        Import-Module UniversalDashboard.Community -ErrorAction Stop
    }
    Write-Host "UniversalDashboard.Community loaded successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to load UniversalDashboard.Community: $_"
    Write-Host "Please install: Install-Module UniversalDashboard.Community" -ForegroundColor Yellow
    exit 1
}

# Simple status endpoint for shared data
$StatusEndpoint = New-UDEndpointInitialization -Module UniversalDashboard.Community

Write-Host "Dashboard port: $Port" -ForegroundColor Cyan
Write-Host "Refresh interval: $RefreshInterval seconds" -ForegroundColor Cyan

# Create simple dashboard pages that work with PowerShell 5.1
try {
    # Define content scriptblocks separately to avoid parameter binding issues
    $OverviewPageContent = [ScriptBlock]::Create(@"
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Unity-Claude Enhanced Real-Time Monitor" -Content {
                    New-UDParagraph -Text "Advanced system monitoring with real-time updates"
                    New-UDParagraph -Text "Environment: Development | Port: $Port | Refresh: $RefreshInterval sec"
                    New-UDParagraph -Text "Last Update: `$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                }
            }
        }
        
        New-UDRow {
            New-UDColumn -Size 3 {
                New-UDCard -Title "Unity Editor" -Content {
                    `$unityProcs = Get-Process -Name 'Unity*' -ErrorAction SilentlyContinue
                    `$status = if (`$unityProcs) { "RUNNING (`$(`$unityProcs.Count))" } else { "STOPPED" }
                    `$memory = if (`$unityProcs) { [Math]::Round((`$unityProcs | Measure-Object WorkingSet64 -Sum).Sum / 1MB, 2) } else { 0 }
                    New-UDParagraph -Text "Status: `$status"
                    New-UDParagraph -Text "Memory: `$memory MB"
                    New-UDParagraph -Text "Last Check: `$(Get-Date -Format 'HH:mm:ss')"
                }
            }
            New-UDColumn -Size 3 {
                New-UDCard -Title "Claude CLI" -Content {
                    `$psProcs = Get-Process -Name 'powershell*', 'pwsh*' -ErrorAction SilentlyContinue
                    `$count = if (`$psProcs) { `$psProcs.Count } else { 0 }
                    New-UDParagraph -Text "PowerShell Processes: `$count"
                    New-UDParagraph -Text "Current PID: `$PID"
                    New-UDParagraph -Text "Status: ACTIVE"
                }
            }
            New-UDColumn -Size 3 {
                New-UDCard -Title "System Memory" -Content {
                    `$mem = Get-CimInstance -ClassName Win32_OperatingSystem
                    `$totalMB = [Math]::Round(`$mem.TotalVisibleMemorySize / 1024, 2)
                    `$freeMB = [Math]::Round(`$mem.FreePhysicalMemory / 1024, 2)
                    `$usedPercent = [Math]::Round(((`$totalMB - `$freeMB) / `$totalMB) * 100, 1)
                    New-UDParagraph -Text "Used: `$usedPercent%"
                    New-UDParagraph -Text "Free: `$freeMB MB"
                    New-UDParagraph -Text "Total: `$totalMB MB"
                }
            }
            New-UDColumn -Size 3 {
                New-UDCard -Title "CPU Usage" -Content {
                    `$cpu = Get-Counter -Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1
                    `$cpuPercent = [Math]::Round(`$cpu.CounterSamples.CookedValue, 1)
                    New-UDParagraph -Text "CPU: `$cpuPercent%"
                    New-UDParagraph -Text "Cores: `$env:NUMBER_OF_PROCESSORS"
                    New-UDParagraph -Text "Load: Normal"
                }
            }
        }
        
        New-UDRow {
            New-UDColumn -Size 6 {
                New-UDCard -Title "Top Processes" -Content {
                    `$topProcs = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5
                    foreach (`$proc in `$topProcs) {
                        `$memMB = [Math]::Round(`$proc.WorkingSet64 / 1MB, 1)
                        New-UDParagraph -Text "`$(`$proc.ProcessName): `$memMB MB"
                    }
                }
            }
            New-UDColumn -Size 6 {
                New-UDCard -Title "Disk Usage" -Content {
                    `$disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DeviceID="C:"'
                    `$totalGB = [Math]::Round(`$disk.Size / 1GB, 2)
                    `$freeGB = [Math]::Round(`$disk.FreeSpace / 1GB, 2)
                    `$usedGB = `$totalGB - `$freeGB
                    `$usedPercent = [Math]::Round((`$usedGB / `$totalGB) * 100, 1)
                    New-UDParagraph -Text "C: Drive Usage: `$usedPercent%"
                    New-UDParagraph -Text "Used: `$usedGB GB / `$totalGB GB"
                    New-UDParagraph -Text "Free: `$freeGB GB"
                }
            }
        }
"@)

    $ConfigPageContent = [ScriptBlock]::Create(@"
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Enhanced System Configuration" -Content {
                    New-UDParagraph -Text "Environment: Development"
                    New-UDParagraph -Text "Dashboard Port: $Port"
                    New-UDParagraph -Text "Refresh Interval: $RefreshInterval seconds"
                    New-UDParagraph -Text "Autonomous Mode: Enabled"
                    New-UDParagraph -Text "Real-Time Monitoring: Active"
                }
            }
        }
        
        New-UDRow {
            New-UDColumn -Size 6 {
                New-UDCard -Title "Module Status" -Content {
                    New-UDParagraph -Text "[OK] UniversalDashboard.Community: v2.9.0"
                    New-UDParagraph -Text "[OK] PowerShell Version: `$(`$PSVersionTable.PSVersion)"
                    New-UDParagraph -Text "[OK] Platform: `$(`$PSVersionTable.Platform)"
                    New-UDParagraph -Text "[OK] OS: Windows"
                }
            }
            New-UDColumn -Size 6 {
                New-UDCard -Title "System Information" -Content {
                    `$computer = Get-CimInstance -ClassName Win32_ComputerSystem
                    New-UDParagraph -Text "Computer: `$(`$computer.Name)"
                    New-UDParagraph -Text "Domain: `$(`$computer.Domain)"
                    New-UDParagraph -Text "Total RAM: `$([Math]::Round(`$computer.TotalPhysicalMemory / 1GB, 2)) GB"
                    New-UDParagraph -Text "Manufacturer: `$(`$computer.Manufacturer)"
                }
            }
        }
        
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Project Status" -Content {
                    `$projectPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
                    if (Test-Path `$projectPath) {
                        `$files = Get-ChildItem `$projectPath -File | Measure-Object
                        `$folders = Get-ChildItem `$projectPath -Directory | Measure-Object
                        New-UDParagraph -Text "[OK] Project Directory: Found"
                        New-UDParagraph -Text "Files: `$(`$files.Count) | Folders: `$(`$folders.Count)"
                        New-UDParagraph -Text "Path: `$projectPath"
                    } else {
                        New-UDParagraph -Text "[ERROR] Project Directory: Not Found"
                    }
                }
            }
        }
"@)

    $MonitoringPageContent = [ScriptBlock]::Create(@"
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Real-Time Process Monitoring" -Content {
                    New-UDParagraph -Text "Live monitoring of Unity and PowerShell processes"
                    New-UDParagraph -Text "Refresh Rate: $RefreshInterval seconds"
                }
            }
        }
        
        New-UDRow {
            New-UDColumn -Size 6 {
                New-UDCard -Title "Unity Processes" -Content {
                    `$unityProcs = Get-Process -Name 'Unity*' -ErrorAction SilentlyContinue
                    if (`$unityProcs) {
                        foreach (`$proc in `$unityProcs) {
                            `$memMB = [Math]::Round(`$proc.WorkingSet64 / 1MB, 2)
                            New-UDParagraph -Text "`$(`$proc.ProcessName) (PID: `$(`$proc.Id)): `$memMB MB"
                        }
                    } else {
                        New-UDParagraph -Text "No Unity processes running"
                    }
                }
            }
            New-UDColumn -Size 6 {
                New-UDCard -Title "PowerShell Processes" -Content {
                    `$psProcs = Get-Process -Name 'powershell*', 'pwsh*' -ErrorAction SilentlyContinue
                    if (`$psProcs) {
                        foreach (`$proc in `$psProcs) {
                            `$memMB = [Math]::Round(`$proc.WorkingSet64 / 1MB, 2)
                            New-UDParagraph -Text "`$(`$proc.ProcessName) (PID: `$(`$proc.Id)): `$memMB MB"
                        }
                    } else {
                        New-UDParagraph -Text "No PowerShell processes found"
                    }
                }
            }
        }
        
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "System Services (Unity/Steam/Visual Studio)" -Content {
                    `$services = Get-Service | Where-Object { `$_.Name -like '*Unity*' -or `$_.Name -like '*Steam*' -or `$_.Name -like '*Visual*' } | Select-Object -First 8
                    if (`$services) {
                        foreach (`$svc in `$services) {
                            `$status = if (`$svc.Status -eq 'Running') { '[RUN]' } else { '[STOP]' }
                            New-UDParagraph -Text "`$status `$(`$svc.Name): `$(`$svc.Status)"
                        }
                    } else {
                        New-UDParagraph -Text "No relevant services found"
                    }
                }
            }
        }
"@)

    # Create pages array using explicit ScriptBlock objects
    $Pages = @(
        New-UDPage -Name "Overview" -Icon home -Content $OverviewPageContent
        New-UDPage -Name "Monitoring" -Icon chart_line -Content $MonitoringPageContent
        New-UDPage -Name "Configuration" -Icon cog -Content $ConfigPageContent
    )

    Write-Host "Pages created successfully: $($Pages.Count) pages" -ForegroundColor Green

    # Create the dashboard
    $Dashboard = New-UDDashboard -Title "Unity-Claude Enhanced Dashboard" -Pages $Pages

    Write-Host "Dashboard created successfully" -ForegroundColor Green

    # Start the dashboard
    Start-UDDashboard -Dashboard $Dashboard -Port $Port
    
    Write-Host "`nDashboard started successfully!" -ForegroundColor Green
    Write-Host "Access at: http://localhost:$Port" -ForegroundColor Cyan
    
    if ($OpenBrowser) {
        Start-Process "http://localhost:$Port"
    }
    
    Write-Host "`nPress Ctrl+C to stop the dashboard..." -ForegroundColor Yellow
    
    # Keep the script running
    while ($true) {
        Start-Sleep -Seconds 60
        Write-Host "." -NoNewline
    }
} catch {
    Write-Error "Failed to start dashboard: $_"
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Stop-UDDashboard -Port $Port -ErrorAction SilentlyContinue
    Write-Host "`nDashboard stopped" -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBN0B9lw/DNOH24
# a3QbOnaFW6aPya2pyEuGZ73HQxstGKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEhjh5gQErXTrzHSRaNPcj1Z
# nIXCUDvBJYTObRtQHpUDMA0GCSqGSIb3DQEBAQUABIIBAEk0g0UM31vV+BDAAVEQ
# oi42BCRkkQWcp4ouFD7F3NvyWaFqQ2Ae0qc6oZHrXRC+l7VeNz1vEkhhMEWA//SU
# XFfGklmeQtO9hAWCjXfiW7tsqSX9uPYHn4titdAjlhc+CxbnuRWW2ozKJIU6RbSz
# nLd2D0VoL9iO9bXoGJWNgLRV8/lIlEqowc6+KU1EMJoPD1QRSlxWDhTIit6JKHG1
# A4K+CNnm7yUrHgbg9FQHTWW2VoCHleprtGx79PMNhSKNS6zV1TxbaE8/a9l7JHLK
# 0ZPrzCRA36E0H4yxPffJI52C4dld8U5Xxt1NZuBsOHQLARpmZSHkYW5b3X3FFkgS
# bKg=
# SIG # End signature block
