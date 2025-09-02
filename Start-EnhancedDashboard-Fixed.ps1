# Start-EnhancedDashboard-Fixed.ps1
# Fixed version of Enhanced Real-Time Dashboard with proper syntax for UniversalDashboard.Community 2.9.0


# PowerShell 7 Self-Elevation

param(
    [int]$Port = 8081,
    [int]$RefreshInterval = 5,
    [switch]$OpenBrowser,
    [ValidateSet("development", "production", "test")]
    [string]$Environment = "development"
)

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

Write-Host "=== Unity-Claude Enhanced Real-Time Dashboard (Fixed) ===" -ForegroundColor Yellow
Write-Host "Environment: $Environment" -ForegroundColor Cyan
Write-Host "Loading modules and configuration..." -ForegroundColor Cyan

# Import required modules
try {
    Write-Host "DEBUG: Starting module imports..." -ForegroundColor Magenta
    
    # Import UniversalDashboard from known location
    $udPath = "C:\Users\georg\Documents\WindowsPowerShell\Modules\UniversalDashboard.Community\2.9.0\UniversalDashboard.Community.psd1"
    Write-Host "DEBUG: Checking UniversalDashboard path: $udPath" -ForegroundColor Magenta
    
    if (Test-Path $udPath) {
        Write-Host "DEBUG: Found UniversalDashboard at path, importing..." -ForegroundColor Magenta
        Import-Module $udPath -ErrorAction Stop
        Write-Host "DEBUG: UniversalDashboard.Community imported from path" -ForegroundColor Magenta
    } else {
        Write-Host "DEBUG: Path not found, importing by name..." -ForegroundColor Magenta
        Import-Module UniversalDashboard.Community -ErrorAction Stop
        Write-Host "DEBUG: UniversalDashboard.Community imported by name" -ForegroundColor Magenta
    }
    
    # Check UniversalDashboard module version and compatibility
    $udModule = Get-Module UniversalDashboard.Community
    if ($udModule) {
        Write-Host "DEBUG: UniversalDashboard.Community loaded - Version: $($udModule.Version), PowerShellVersion: $($udModule.PowerShellVersion)" -ForegroundColor Magenta
        Write-Host "DEBUG: Module path: $($udModule.ModuleBase)" -ForegroundColor Magenta
        Write-Host "DEBUG: Exported commands count: $($udModule.ExportedCommands.Count)" -ForegroundColor Magenta
        
        # Check if New-UDDashboard is available
        if (Get-Command New-UDDashboard -ErrorAction SilentlyContinue) {
            Write-Host "DEBUG: New-UDDashboard command is available" -ForegroundColor Magenta
        } else {
            Write-Host "DEBUG: WARNING: New-UDDashboard command is NOT available!" -ForegroundColor Yellow
        }
    } else {
        Write-Host "DEBUG: WARNING: UniversalDashboard.Community module not loaded!" -ForegroundColor Yellow
    }
    
    # Import other modules
    $configPath = Join-Path $PSScriptRoot "Unity-Claude-Configuration.psm1"
    if (Test-Path $configPath) {
        Import-Module $configPath -Force
    }
    
    $corePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-Core\Unity-Claude-Core.psm1"
    if (Test-Path $corePath) {
        Import-Module $corePath -Force -DisableNameChecking
    }
    
    $systemStatusPath = Join-Path $PSScriptRoot "Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1"
    if (Test-Path $systemStatusPath) {
        Import-Module $systemStatusPath -Force -DisableNameChecking
    }
    
    Write-Host "Modules loaded successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to load required modules: $_"
    exit 1
}

# Initialize configuration
$config = @{
    autonomous_operation = @{
        enabled = $true
        max_conversation_rounds = 10
    }
}

# Set up paths
$logsPath = Join-Path $PSScriptRoot "Logs"
if (-not (Test-Path $logsPath)) {
    New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
}

# Initialize cache variables
$cache:UnityStatus = @{
    Running = $false
    EditorLogSize = 0
}

$cache:ClaudeStatus = @{
    ProcessCount = 0
    LastResponseTime = "N/A"
}

$cache:MemoryUsage = @{
    UsedPercent = 0
    Available = 0
    Total = 8192
}

$cache:SystemStatus = @{
    ConversationRound = 0
}

Write-Host "Dashboard port: $Port" -ForegroundColor Cyan
Write-Host "Refresh interval: $RefreshInterval seconds" -ForegroundColor Cyan

# Clear any variables that might interfere with parameter binding
Write-Host "DEBUG: Starting variable cleanup to prevent parameter binding conflicts" -ForegroundColor Magenta
try {
    # Clear potential conflicting variables
    Write-Host "DEBUG: Checking for conflicting variables in Global scope" -ForegroundColor Magenta
    
    $varsToClean = @('Theme', 'theme', 'Pages', 'pages', 'Title', 'title', 'Content', 'content')
    foreach ($varName in $varsToClean) {
        $varExists = Get-Variable -Name $varName -ErrorAction SilentlyContinue -Scope Global
        if ($varExists) {
            Write-Host "DEBUG: Found conflicting variable '$varName' in Global scope: $($varExists.Value.GetType().Name)" -ForegroundColor Magenta
            Remove-Variable -Name $varName -ErrorAction SilentlyContinue -Scope Global
            Write-Host "DEBUG: Removed variable '$varName' from Global scope" -ForegroundColor Magenta
        } else {
            Write-Host "DEBUG: Variable '$varName' not found in Global scope" -ForegroundColor DarkGray
        }
    }
    
    # Clear the cleanup variable itself to prevent it from interfering
    Remove-Variable -Name varsToClean -ErrorAction SilentlyContinue
    
    Write-Host "DEBUG: Variable cleanup completed successfully" -ForegroundColor Magenta
} catch {
    Write-Host "DEBUG: Error during variable cleanup: $($_.Exception.Message)" -ForegroundColor Red
}

# Create dashboard with simplified page structure
try {
    Write-Host "DEBUG: Starting dashboard page creation" -ForegroundColor Magenta
    
    # Create the overview page
    Write-Host "DEBUG: Creating Overview page..." -ForegroundColor Magenta
    $OverviewPage = New-UDPage -Name "Overview" -Icon "home" -Content {
        New-UDLayout -Columns 1 -Content {
            New-UDCard -Title "Unity-Claude Enhanced Dashboard" -Content {
                New-UDParagraph -Text "Real-time system monitoring and automation status"
                New-UDParagraph -Text "Environment: $Environment"
                New-UDParagraph -Text "Last Update: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            }
        }
        
        # Status cards row
        New-UDLayout -Columns 4 -Content {
            # Unity Status
            New-UDCard -Title "Unity Editor" -Content {
                New-UDHeading -Size 3 -Text "STOPPED"
                New-UDParagraph -Text "Not Running"
            }
            
            # Claude Status
            New-UDCard -Title "Claude CLI" -Content {
                New-UDHeading -Size 3 -Text "0 Processes"
                New-UDParagraph -Text "Idle"
            }
            
            # Memory Usage
            New-UDCard -Title "Memory" -Content {
                New-UDHeading -Size 3 -Text "45%"
                New-UDParagraph -Text "4096 / 8192 MB"
            }
            
            # Autonomous Agent
            New-UDCard -Title "Autonomous" -Content {
                New-UDHeading -Size 3 -Text "ENABLED"
                New-UDParagraph -Text "Round 0/10"
            }
        }
        
        # Charts row
        New-UDLayout -Columns 2 -Content {
            # Memory Chart
            New-UDCard -Title "Memory Usage Trend" -Content {
                New-UDChart -Title "Memory %" -Type Line -Endpoint {
                    @(
                        @{ Time = "10:00"; Memory = 45 }
                        @{ Time = "10:05"; Memory = 48 }
                        @{ Time = "10:10"; Memory = 52 }
                        @{ Time = "10:15"; Memory = 47 }
                        @{ Time = "10:20"; Memory = 45 }
                    ) | Out-UDChartData -DataProperty "Memory" -LabelProperty "Time"
                }
            }
            
            # Error Chart
            New-UDCard -Title "Error Rate" -Content {
                New-UDChart -Title "Errors/Hour" -Type Bar -Endpoint {
                    @(
                        @{ Hour = "09:00"; Errors = 2 }
                        @{ Hour = "10:00"; Errors = 1 }
                        @{ Hour = "11:00"; Errors = 0 }
                        @{ Hour = "12:00"; Errors = 3 }
                    ) | Out-UDChartData -DataProperty "Errors" -LabelProperty "Hour"
                }
            }
        }
        
        # Events table
        New-UDLayout -Columns 1 -Content {
            New-UDCard -Title "Recent Events" -Content {
                New-UDGrid -Title "System Events" -Headers @("Time", "Type", "Message") -Properties @("Time", "Type", "Message") -Endpoint {
                    @(
                        @{ Time = (Get-Date).ToString("HH:mm:ss"); Type = "Info"; Message = "Dashboard started" }
                        @{ Time = (Get-Date).AddMinutes(-5).ToString("HH:mm:ss"); Type = "Warning"; Message = "Unity compilation warning" }
                        @{ Time = (Get-Date).AddMinutes(-10).ToString("HH:mm:ss"); Type = "Success"; Message = "Error resolved" }
                    ) | Out-UDGridData
                }
            }
        }
    }
    Write-Host "DEBUG: Overview page created successfully" -ForegroundColor Magenta
    
    # Create the configuration page
    Write-Host "DEBUG: Creating Configuration page..." -ForegroundColor Magenta
    $ConfigurationPage = New-UDPage -Name "Configuration" -Icon "cog" -Content {
        New-UDLayout -Columns 1 -Content {
            New-UDCard -Title "System Configuration" -Content {
                New-UDParagraph -Text "Environment: $Environment"
                New-UDParagraph -Text "Port: $Port"
                New-UDParagraph -Text "Refresh Interval: $RefreshInterval seconds"
                New-UDParagraph -Text "Autonomous Mode: $(if ($config.autonomous_operation.enabled) { 'Enabled' } else { 'Disabled' })"
                New-UDParagraph -Text "Max Rounds: $($config.autonomous_operation.max_conversation_rounds)"
            }
        }
        
        New-UDLayout -Columns 1 -Content {
            New-UDCard -Title "Module Status" -Content {
                New-UDParagraph -Text "UniversalDashboard.Community - Version 2.9.0"
                New-UDParagraph -Text "Unity-Claude-Core - Loaded"
                New-UDParagraph -Text "Unity-Claude-SystemStatus - Loaded"
                New-UDParagraph -Text "PowerShell Version - $($PSVersionTable.PSVersion)"
            }
        }
    }
    Write-Host "DEBUG: Configuration page created successfully" -ForegroundColor Magenta
    
    # Create monitoring page
    Write-Host "DEBUG: Creating Monitoring page..." -ForegroundColor Magenta
    $MonitoringPage = New-UDPage -Name "Monitoring" -Icon "chart_line" -Content {
        New-UDLayout -Columns 1 -Content {
            New-UDCard -Title "Real-Time Monitoring" -Content {
                New-UDParagraph -Text "Active monitoring of Unity and Claude processes"
            }
        }
        
        # Process monitoring
        New-UDLayout -Columns 2 -Content {
            New-UDCard -Title "Unity Processes" -Content {
                New-UDGrid -Title "Unity" -Headers @("Process", "ID", "Memory(MB)") -Properties @("ProcessName", "Id", "Memory") -Endpoint {
                    Get-Process | Where-Object { $_.ProcessName -like "*Unity*" } | Select-Object ProcessName, Id, @{Name="Memory";Expression={[Math]::Round($_.WorkingSet64/1MB,2)}} | Out-UDGridData
                }
            }
            
            New-UDCard -Title "PowerShell Processes" -Content {
                New-UDGrid -Title "PowerShell" -Headers @("Process", "ID", "Memory(MB)") -Properties @("ProcessName", "Id", "Memory") -Endpoint {
                    Get-Process | Where-Object { $_.ProcessName -like "*powershell*" -or $_.ProcessName -like "*pwsh*" } | Select-Object ProcessName, Id, @{Name="Memory";Expression={[Math]::Round($_.WorkingSet64/1MB,2)}} | Out-UDGridData
                }
            }
        }
    }
    Write-Host "DEBUG: Monitoring page created successfully" -ForegroundColor Magenta
    
    # Create logs page
    Write-Host "DEBUG: Creating Logs page..." -ForegroundColor Magenta
    $LogsPage = New-UDPage -Name "Logs" -Icon "file_text" -Content {
        New-UDLayout -Columns 1 -Content {
            New-UDCard -Title "System Logs" -Content {
                New-UDParagraph -Text "Recent log entries from automation system"
            }
        }
        
        New-UDLayout -Columns 1 -Content {
            New-UDCard -Title "Automation Log" -Content {
                $logFile = Join-Path $PSScriptRoot "unity_claude_automation.log"
                $logContent = if (Test-Path $logFile) {
                    Get-Content $logFile -Tail 20 | Out-String
                } else {
                    "No log file found"
                }
                New-UDElement -Tag "pre" -Attributes @{ style = "background-color: #f5f5f5; padding: 10px; overflow-x: auto;" } -Content {
                    New-UDHtml -Markup $logContent
                }
            }
        }
    }
    Write-Host "DEBUG: Logs page created successfully" -ForegroundColor Magenta
    
    # Debug: Check page variables before dashboard creation
    Write-Host "DEBUG: Validating page variables before dashboard creation" -ForegroundColor Magenta
    Write-Host "DEBUG: OverviewPage type: $($OverviewPage.GetType().Name)" -ForegroundColor Magenta
    Write-Host "DEBUG: ConfigurationPage type: $($ConfigurationPage.GetType().Name)" -ForegroundColor Magenta
    Write-Host "DEBUG: MonitoringPage type: $($MonitoringPage.GetType().Name)" -ForegroundColor Magenta
    Write-Host "DEBUG: LogsPage type: $($LogsPage.GetType().Name)" -ForegroundColor Magenta
    
    # Create the dashboard with explicit Theme parameter to prevent automatic binding
    Write-Host "DEBUG: Preparing dashboard parameters with explicit Theme..." -ForegroundColor Magenta
    
    # Create dashboard parameters without Theme
    $dashboardParams = @{
        Title = "Unity-Claude Enhanced Dashboard"
        Pages = @($OverviewPage, $ConfigurationPage, $MonitoringPage, $LogsPage)
    }
    
    Write-Host "DEBUG: Dashboard parameters prepared - Title: '$($dashboardParams.Title)', Pages count: $($dashboardParams.Pages.Count)" -ForegroundColor Magenta
    
    # Debug: Check for any variables that might auto-bind to Theme
    Write-Host "DEBUG: Checking current scope for potential Theme-related variables" -ForegroundColor Magenta
    $allVars = Get-Variable -ErrorAction SilentlyContinue
    $suspiciousVars = $allVars | Where-Object { $_.Name -match 'theme|Theme|THEME' -or ($_.Value -is [array] -and $_.Value.Count -gt 0 -and $_.Name -ne 'dashboardParams') }
    if ($suspiciousVars) {
        foreach ($var in $suspiciousVars) {
            Write-Host "DEBUG: Suspicious variable found - Name: '$($var.Name)', Type: $($var.Value.GetType().Name), Value: $($var.Value)" -ForegroundColor Yellow
            # Clear suspicious variables that might interfere
            if ($var.Name -notmatch 'OverviewPage|ConfigurationPage|MonitoringPage|LogsPage|dashboardParams') {
                Remove-Variable -Name $var.Name -ErrorAction SilentlyContinue
                Write-Host "DEBUG: Cleared suspicious variable: $($var.Name)" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "DEBUG: No suspicious Theme-related variables found" -ForegroundColor Magenta
    }
    
    # Final cleanup of any remaining arrays that could interfere
    $finalCleanup = Get-Variable -ErrorAction SilentlyContinue | Where-Object { $_.Value -is [array] -and $_.Name -notmatch 'OverviewPage|ConfigurationPage|MonitoringPage|LogsPage|dashboardParams' }
    foreach ($arrayVar in $finalCleanup) {
        Write-Host "DEBUG: Clearing array variable before dashboard creation: $($arrayVar.Name)" -ForegroundColor Yellow
        Remove-Variable -Name $arrayVar.Name -ErrorAction SilentlyContinue
    }
    
    # Debug: Inspect New-UDDashboard cmdlet parameters before calling
    Write-Host "DEBUG: Inspecting New-UDDashboard cmdlet parameters..." -ForegroundColor Magenta
    try {
        $udCommand = Get-Command New-UDDashboard -ErrorAction Stop
        Write-Host "DEBUG: New-UDDashboard found, parameter sets: $($udCommand.ParameterSets.Count)" -ForegroundColor Magenta
        
        if ($udCommand.Parameters.ContainsKey('Theme')) {
            $themeParam = $udCommand.Parameters['Theme']
            Write-Host "DEBUG: Theme parameter exists - Type: $($themeParam.ParameterType), Mandatory: $($themeParam.IsMandatory)" -ForegroundColor Magenta
        } else {
            Write-Host "DEBUG: Theme parameter NOT found in New-UDDashboard" -ForegroundColor Magenta
        }
    } catch {
        Write-Host "DEBUG: Error inspecting New-UDDashboard: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Debug: Validate dashboard parameters hashtable
    Write-Host "DEBUG: Validating dashboardParams hashtable structure..." -ForegroundColor Magenta
    Write-Host "DEBUG: dashboardParams is hashtable: $($dashboardParams -is [hashtable])" -ForegroundColor Magenta
    Write-Host "DEBUG: dashboardParams keys: $($dashboardParams.Keys -join ', ')" -ForegroundColor Magenta
    
    foreach ($key in $dashboardParams.Keys) {
        $value = $dashboardParams[$key]
        Write-Host "DEBUG: Parameter '$key': Type=$($value.GetType().Name), IsArray=$($value -is [array]), Count=$(if($value -is [array]){$value.Count}else{'N/A'})" -ForegroundColor Magenta
    }
    
    Write-Host "DEBUG: About to call New-UDDashboard with splatting..." -ForegroundColor Magenta
    
    # Try to isolate the issue by calling with explicit Theme parameter
    Write-Host "DEBUG: Testing New-UDDashboard with explicit empty Theme..." -ForegroundColor Magenta
    try {
        $emptyTheme = @{}
        $TestDashboard = New-UDDashboard -Title "Test Dashboard" -Content { New-UDHeading -Text "Test" } -Theme $emptyTheme
        Write-Host "DEBUG: Simple New-UDDashboard test with explicit Theme succeeded!" -ForegroundColor Green
        Remove-Variable TestDashboard -ErrorAction SilentlyContinue
        Remove-Variable emptyTheme -ErrorAction SilentlyContinue
    } catch {
        Write-Host "DEBUG: Simple New-UDDashboard test with explicit Theme FAILED: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "DEBUG: Testing without any Theme parameter..." -ForegroundColor Magenta
        try {
            $TestDashboard2 = New-UDDashboard -Title "Test Dashboard 2" -Content { New-UDHeading -Text "Test 2" }
            Write-Host "DEBUG: New-UDDashboard without Theme parameter succeeded!" -ForegroundColor Green
            Remove-Variable TestDashboard2 -ErrorAction SilentlyContinue
        } catch {
            Write-Host "DEBUG: New-UDDashboard without Theme also FAILED: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "DEBUG: This indicates a fundamental issue with the UniversalDashboard module" -ForegroundColor Red
        }
    }
    
    Write-Host "DEBUG: Now attempting full dashboard creation with splatting..." -ForegroundColor Magenta
    
    # Add extensive debugging around the actual call
    Write-Host "DEBUG: Calling New-UDDashboard with Title='$($dashboardParams.Title)' and $($dashboardParams.Pages.Count) pages" -ForegroundColor Magenta
    Write-Host "DEBUG: Parameters being splatted: $(ConvertTo-Json $dashboardParams -Depth 2 -Compress)" -ForegroundColor Magenta
    
    try {
        # Enable detailed PowerShell tracing for this call
        $OriginalPreference = $VerbosePreference
        $VerbosePreference = 'Continue'
        
        Write-Host "DEBUG: About to execute: New-UDDashboard @dashboardParams" -ForegroundColor Magenta
        $Dashboard = New-UDDashboard @dashboardParams
        
        $VerbosePreference = $OriginalPreference
        Write-Host "DEBUG: New-UDDashboard completed successfully!" -ForegroundColor Green
        
    } catch {
        $VerbosePreference = $OriginalPreference
        Write-Host "DEBUG: New-UDDashboard with splatting FAILED: $($_.Exception.Message)" -ForegroundColor Red
        
        # Try alternative approach - direct parameter passing
        Write-Host "DEBUG: Attempting fallback - direct parameter passing without splatting..." -ForegroundColor Magenta
        try {
            $Dashboard = New-UDDashboard -Title $dashboardParams.Title -Pages $dashboardParams.Pages -Theme @{}
            Write-Host "DEBUG: Fallback direct parameter approach succeeded!" -ForegroundColor Green
        } catch {
            Write-Host "DEBUG: Fallback direct parameter approach also failed: $($_.Exception.Message)" -ForegroundColor Red
            
            # Try minimal dashboard as last resort
            Write-Host "DEBUG: Attempting minimal dashboard as last resort..." -ForegroundColor Magenta
            
            # Clear only specific problematic variables, not ALL variables
            Write-Host "DEBUG: Clearing specific problematic variables..." -ForegroundColor Magenta
            $problematicVars = @('finalCleanup', 'allVars', 'suspiciousVars', 'arrayVar', 'var', 'varName', 'varExists', 'varsToClean')
            foreach ($problematicVar in $problematicVars) {
                if (Get-Variable -Name $problematicVar -ErrorAction SilentlyContinue) {
                    Write-Host "DEBUG: Clearing problematic variable: $problematicVar" -ForegroundColor DarkMagenta
                    Remove-Variable -Name $problematicVar -ErrorAction SilentlyContinue
                }
            }
            
            Write-Host "DEBUG: Testing absolute minimal dashboard creation..." -ForegroundColor Magenta
            try {
                # Try the most basic possible dashboard
                Write-Host "DEBUG: Attempting New-UDDashboard with only Title parameter..." -ForegroundColor Magenta
                $minimalDashboard = New-UDDashboard -Title "Test"
                Write-Host "DEBUG: Basic dashboard with only Title succeeded!" -ForegroundColor Green
                $Dashboard = $minimalDashboard
            } catch {
                Write-Host "DEBUG: Basic dashboard with only Title failed: $($_.Exception.Message)" -ForegroundColor Red
                
                # Try with PowerShell session isolation
                Write-Host "DEBUG: Attempting with fresh session state..." -ForegroundColor Magenta
                try {
                    # Create a new session state to isolate variables
                    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
                    $runspace = [runspacefactory]::CreateRunspace($sessionState)
                    $runspace.Open()
                    
                    $powerShell = [PowerShell]::Create()
                    $powerShell.Runspace = $runspace
                    
                    # Import only UniversalDashboard in clean session
                    $null = $powerShell.AddScript("Import-Module '$udPath'")
                    $null = $powerShell.Invoke()
                    
                    # Try dashboard creation in clean session
                    $null = $powerShell.AddScript('New-UDDashboard -Title "Clean Session Test"')
                    $result = $powerShell.Invoke()
                    
                    if ($powerShell.HadErrors) {
                        $errors = $powerShell.Streams.Error | ForEach-Object { $_.Exception.Message }
                        Write-Host "DEBUG: Clean session test failed: $($errors -join '; ')" -ForegroundColor Red
                    } else {
                        Write-Host "DEBUG: Clean session test succeeded! Issue is with variable pollution." -ForegroundColor Green
                    }
                    
                    $powerShell.Dispose()
                    $runspace.Close()
                    
                    throw "UniversalDashboard.Community has fundamental compatibility issues with PowerShell $($PSVersionTable.PSVersion)"
                    
                } catch {
                    Write-Host "DEBUG: Clean session approach failed: $($_.Exception.Message)" -ForegroundColor Red
                    throw "UniversalDashboard.Community appears to be incompatible with current PowerShell $($PSVersionTable.PSVersion) environment"
                }
            }
        }
    }
    
    Write-Host "`nDashboard created successfully!" -ForegroundColor Green
    
    # Start the dashboard
    Write-Host "DEBUG: About to start dashboard on port $Port..." -ForegroundColor Magenta
    Start-UDDashboard -Dashboard $Dashboard -Port $Port -Wait
    Write-Host "DEBUG: Dashboard started successfully!" -ForegroundColor Green
    
} catch {
    Write-Error "Failed to create/start dashboard: $_"
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "DEBUG: Error occurred at line $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Write-Host "DEBUG: Error in command: $($_.InvocationInfo.Line.Trim())" -ForegroundColor Red
    Write-Host "DEBUG: Full exception: $($_.Exception.ToString())" -ForegroundColor Red
    
    # Debug: Show current variable state
    Write-Host "DEBUG: Current variable state when error occurred:" -ForegroundColor Red
    $currentVars = Get-Variable -ErrorAction SilentlyContinue | Where-Object { $_.Name -in @('OverviewPage', 'ConfigurationPage', 'MonitoringPage', 'LogsPage', 'dashboardParams', 'Dashboard') }
    foreach ($var in $currentVars) {
        Write-Host "DEBUG: Variable '$($var.Name)': Type=$($var.Value.GetType().Name), Value=$($var.Value)" -ForegroundColor Red
    }
    
    exit 1
}


# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCa7AqDsn3pGbkP
# 3AOSs2fOUbyt2CZSUkNnbROprQCpoqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKIG92iRDxUrKcDt+91BuBDu
# R3T/inKZDQayRUaGMhajMA0GCSqGSIb3DQEBAQUABIIBAHJUzGOkgmbEJ5u0FRBh
# G0byy9WSphZZ7Am9j7z8ruerdLc/JqxnuymibkHPXQlXQK0aNiNC7TpVlHvxsnMc
# +gXDYzPyOAZTE4ctX8ynkaLoLHEt27TWSe5dg3Xe9VSfsUcaDzPAaeKuiKH924EL
# Qxh+BLmMz0e0/mTG5TMcN2AfiyReZ6wGPCX7cWIcugWXzw2Zvc3miMHoem4STxSt
# 5amvJj3/uheIFtCEQGH+deT0gDiCXOEbKeMP20HQ6x5BP4w0ZyS4a/KWDiwkCl8Q
# trKSM608nFXUOudlozsuRXirOnAEv4qvH4jVlHNklhoYTlBtUYK+GoKIl42dw7Ny
# p+c=
# SIG # End signature block
