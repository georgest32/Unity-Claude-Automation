# Start-EnhancedDashboard-Working.ps1
# Enhanced Dashboard using working SimpleDashboard pattern with advanced features


# PowerShell 7 Self-Elevation

param(
    [int]$Port = 8081,
    [int]$RefreshInterval = 5,
    [switch]$OpenBrowser,
    [ValidateSet("development", "production", "test")

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

]
    [string]$Environment = "development"
)

Write-Host "=== Unity-Claude Enhanced Real-Time Dashboard ===" -ForegroundColor Yellow
Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "Loading modules and configuration..." -ForegroundColor Cyan

# Import required modules
try {
    # Import UniversalDashboard from known location
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

# Load configuration and other modules (optional)
$config = @{
    autonomous_operation = @{
        enabled = $true
        max_conversation_rounds = 10
    }
}

Write-Host "Dashboard port: $Port" -ForegroundColor Cyan
Write-Host "Refresh interval: $RefreshInterval seconds" -ForegroundColor Cyan

# Create enhanced dashboard pages using working ScriptBlock pattern
try {
    # Overview Page with enhanced content
    $OverviewPageContent = [ScriptBlock]::Create(@"
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Unity-Claude Enhanced Real-Time Dashboard" -Content {
                    New-UDParagraph -Text "Advanced system monitoring with real-time updates"
                    New-UDParagraph -Text "Environment: $Environment | Port: $Port | Refresh: $RefreshInterval sec"
                    New-UDParagraph -Text "Last Update: `$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                }
            }
        }
        
        New-UDRow {
            New-UDColumn -Size 3 {
                New-UDCard -Title "Unity Editor" -Content {
                    New-UDParagraph -Text "Status: `$(if (Get-Process -Name 'Unity*' -ErrorAction SilentlyContinue) { 'RUNNING' } else { 'STOPPED' })"
                    New-UDParagraph -Text "Processes: `$((Get-Process -Name 'Unity*' -ErrorAction SilentlyContinue | Measure-Object).Count)"
                    New-UDParagraph -Text "Memory: `$([Math]::Round((Get-Process -Name 'Unity*' -ErrorAction SilentlyContinue | Measure-Object WorkingSet64 -Sum).Sum / 1MB, 2)) MB"
                }
            }
            New-UDColumn -Size 3 {
                New-UDCard -Title "Claude CLI" -Content {
                    New-UDParagraph -Text "Status: `$(if (Get-Process -Name 'powershell*' -ErrorAction SilentlyContinue) { 'ACTIVE' } else { 'IDLE' })"
                    New-UDParagraph -Text "PowerShell Processes: `$((Get-Process -Name 'powershell*' -ErrorAction SilentlyContinue | Measure-Object).Count)"
                    New-UDParagraph -Text "Current PID: `$PID"
                }
            }
            New-UDColumn -Size 3 {
                New-UDCard -Title "System Memory" -Content {
                    `$mem = Get-CimInstance -ClassName Win32_OperatingSystem
                    `$totalMB = [Math]::Round(`$mem.TotalVisibleMemorySize / 1024, 2)
                    `$freeMB = [Math]::Round(`$mem.FreePhysicalMemory / 1024, 2)
                    `$usedMB = `$totalMB - `$freeMB
                    `$usedPercent = [Math]::Round((`$usedMB / `$totalMB) * 100, 1)
                    
                    New-UDParagraph -Text "Used: `$usedPercent%"
                    New-UDParagraph -Text "`$usedMB / `$totalMB MB"
                    New-UDParagraph -Text "Free: `$freeMB MB"
                }
            }
            New-UDColumn -Size 3 {
                New-UDCard -Title "Autonomous Agent" -Content {
                    New-UDParagraph -Text "Status: ENABLED"
                    New-UDParagraph -Text "Rounds: 0 / 10"
                    New-UDParagraph -Text "Last Action: Dashboard Start"
                }
            }
        }
        
        New-UDRow {
            New-UDColumn -Size 6 {
                New-UDCard -Title "System Performance" -Content {
                    New-UDParagraph -Text "CPU Usage: `$((Get-Counter -Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1).CounterSamples.CookedValue.ToString('F1'))%"
                    New-UDParagraph -Text "Disk Usage: `$([Math]::Round((Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DeviceID=\"C:\"').Size / 1GB - (Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DeviceID=\"C:\"').FreeSpace / 1GB, 2)) / `$([Math]::Round((Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DeviceID=\"C:\"').Size / 1GB, 2)) GB"
                    New-UDParagraph -Text "Uptime: `$((Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime)"
                }
            }
            New-UDColumn -Size 6 {
                New-UDCard -Title "Process Monitor" -Content {
                    `$topProcesses = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 3
                    foreach (`$proc in `$topProcesses) {
                        New-UDParagraph -Text "`$(`$proc.ProcessName): `$([Math]::Round(`$proc.WorkingSet64 / 1MB, 1)) MB"
                    }
                }
            }
        }
"@)

    # Monitoring Page with real-time data
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
                            New-UDParagraph -Text "`$(`$proc.ProcessName) (PID: `$(`$proc.Id)): `$([Math]::Round(`$proc.WorkingSet64 / 1MB, 2)) MB"
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
                            New-UDParagraph -Text "`$(`$proc.ProcessName) (PID: `$(`$proc.Id)): `$([Math]::Round(`$proc.WorkingSet64 / 1MB, 2)) MB"
                        }
                    } else {
                        New-UDParagraph -Text "No PowerShell processes found"
                    }
                }
            }
        }
        
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "System Services" -Content {
                    `$services = Get-Service | Where-Object { `$_.Name -like '*Unity*' -or `$_.Name -like '*Steam*' -or `$_.Name -like '*Visual*' } | Select-Object -First 5
                    foreach (`$svc in `$services) {
                        New-UDParagraph -Text "`$(`$svc.Name): `$(`$svc.Status)"
                    }
                }
            }
        }
"@)

    # Configuration Page
    $ConfigPageContent = [ScriptBlock]::Create(@"
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Enhanced System Configuration" -Content {
                    New-UDParagraph -Text "Environment: $Environment"
                    New-UDParagraph -Text "Dashboard Port: $Port"
                    New-UDParagraph -Text "Refresh Interval: $RefreshInterval seconds"
                    New-UDParagraph -Text "Autonomous Mode: Enabled"
                    New-UDParagraph -Text "Max Conversation Rounds: 10"
                }
            }
        }
        
        New-UDRow {
            New-UDColumn -Size 6 {
                New-UDCard -Title "Module Status" -Content {
                    New-UDParagraph -Text "UniversalDashboard.Community: âœ“ Loaded (v2.9.0)"
                    New-UDParagraph -Text "PowerShell Version: `$(`$PSVersionTable.PSVersion)"
                    New-UDParagraph -Text "Platform: `$(`$PSVersionTable.Platform)"
                    New-UDParagraph -Text "OS: `$(`$PSVersionTable.OS)"
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
                New-UDCard -Title "File System Status" -Content {
                    `$projectPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
                    if (Test-Path `$projectPath) {
                        `$files = Get-ChildItem `$projectPath -File | Measure-Object
                        `$folders = Get-ChildItem `$projectPath -Directory | Measure-Object
                        New-UDParagraph -Text "Project Directory: âœ“ Found"
                        New-UDParagraph -Text "Files: `$(`$files.Count)"
                        New-UDParagraph -Text "Folders: `$(`$folders.Count)"
                    } else {
                        New-UDParagraph -Text "Project Directory: âœ— Not Found"
                    }
                }
            }
        }
"@)

    # Logs Page
    $LogsPageContent = [ScriptBlock]::Create(@"
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "System Logs and Events" -Content {
                    New-UDParagraph -Text "Recent automation logs and system events"
                    New-UDParagraph -Text "Log Location: C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
                }
            }
        }
        
        New-UDRow {
            New-UDColumn -Size 6 {
                New-UDCard -Title "Automation Log" -Content {
                    `$logPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log"
                    if (Test-Path `$logPath) {
                        `$logContent = Get-Content `$logPath -Tail 10 -ErrorAction SilentlyContinue
                        if (`$logContent) {
                            foreach (`$line in `$logContent) {
                                New-UDParagraph -Text `$line
                            }
                        } else {
                            New-UDParagraph -Text "Log file is empty"
                        }
                    } else {
                        New-UDParagraph -Text "Log file not found"
                    }
                }
            }
            New-UDColumn -Size 6 {
                New-UDCard -Title "Recent Windows Events" -Content {
                    `$events = Get-WinEvent -LogName Application -MaxEvents 5 -ErrorAction SilentlyContinue
                    if (`$events) {
                        foreach (`$event in `$events) {
                            New-UDParagraph -Text "`$(`$event.TimeCreated.ToString('HH:mm:ss')): `$(`$event.LevelDisplayName) - `$(`$event.Id)"
                        }
                    } else {
                        New-UDParagraph -Text "No recent events"
                    }
                }
            }
        }
        
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Dashboard Statistics" -Content {
                    New-UDParagraph -Text "Dashboard Started: `$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                    New-UDParagraph -Text "Current Session: `$([Math]::Round(((Get-Date) - [System.Diagnostics.Process]::GetCurrentProcess().StartTime).TotalMinutes, 2)) minutes"
                    New-UDParagraph -Text "Dashboard PID: `$PID"
                    New-UDParagraph -Text "Working Directory: `$(Get-Location)"
                }
            }
        }
"@)

    # Create pages array using explicit ScriptBlock objects (working pattern)
    $Pages = @(
        New-UDPage -Name "Overview" -Icon home -Content $OverviewPageContent
        New-UDPage -Name "Monitoring" -Icon chart_line -Content $MonitoringPageContent  
        New-UDPage -Name "Configuration" -Icon cog -Content $ConfigPageContent
        New-UDPage -Name "Logs" -Icon file_text -Content $LogsPageContent
    )

    Write-Host "Pages created successfully: $($Pages.Count) pages" -ForegroundColor Green

    # Create the dashboard
    $Dashboard = New-UDDashboard -Title "Unity-Claude Enhanced Dashboard" -Pages $Pages

    Write-Host "Dashboard created successfully" -ForegroundColor Green

    # Start the dashboard
    Write-Host "`nStarting dashboard on port $Port..." -ForegroundColor Cyan
    Start-UDDashboard -Dashboard $Dashboard -Port $Port -AutoReload

    Write-Host "`nDashboard started successfully!" -ForegroundColor Green
    Write-Host "Access at: http://localhost:$Port" -ForegroundColor Yellow
    
    if ($OpenBrowser) {
        Start-Process "http://localhost:$Port"
    }

    Write-Host "`nPress Ctrl+C to stop the dashboard..." -ForegroundColor Cyan
    
    # Keep the script running
    try {
        while ($true) {
            Start-Sleep -Seconds 1
        }
    } catch {
        Write-Host "`nDashboard stopped" -ForegroundColor Yellow
    } finally {
        Stop-UDDashboard -Port $Port -ErrorAction SilentlyContinue
    }

} catch {
    Write-Error "Failed to start dashboard: $_"
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Stop-UDDashboard -Port $Port -ErrorAction SilentlyContinue
    exit 1
}

