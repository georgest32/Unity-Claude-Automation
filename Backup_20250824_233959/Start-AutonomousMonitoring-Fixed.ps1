# Start-AutonomousMonitoring-Fixed.ps1
# Stable autonomous monitoring launcher that imports core functionality as module
# Date: 2025-08-21


# PowerShell 7 Self-Elevation

param(
    [int]$PollIntervalSeconds = 5,
    [switch]$DebugMode
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

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "AUTONOMOUS MONITORING LAUNCHER" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Get process ID for tracking
# When launched with powershell -NoExit -File, the script runs in the PowerShell host process
# So $PID is the actual process ID that will be running
$agentPID = $PID
Write-Host "AutonomousAgent Process ID: $agentPID" -ForegroundColor Yellow

# IMPORTANT: When this script is started via Start-Process with -NoExit, 
# the $PID here IS the actual PowerShell process that will keep running
# This is the correct PID to register

# Set working directory
Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

# Load required assemblies first
Write-Host "Loading assemblies..." -ForegroundColor Gray
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Import required modules first for deduplication check
Write-Host "Loading modules..." -ForegroundColor Gray
try {
    Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force
    Write-Host "  SystemStatus module loaded" -ForegroundColor Green
} catch {
    Write-Host "  Warning: Could not load SystemStatus module: $_" -ForegroundColor Yellow
}

# NOTE: Duplicate agent prevention is now handled by SystemStatus module during registration
# The Register-Subsystem function will automatically kill any existing AutonomousAgent process
Write-Host "Duplicate prevention handled by SystemStatus module" -ForegroundColor Gray

try {
    Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force
    Write-Host "  CLISubmission module loaded" -ForegroundColor Green
} catch {
    Write-Host "  Warning: Could not load CLISubmission module: $_" -ForegroundColor Yellow
}

# Import the autonomous monitoring module
Write-Host "Loading autonomous monitoring module..." -ForegroundColor Yellow
try {
    Import-Module ".\Modules\Unity-Claude-AutonomousMonitoring\Unity-Claude-AutonomousMonitoring.psd1" -Force
    Write-Host "  Autonomous monitoring module loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Could not load autonomous monitoring module: $_" -ForegroundColor Red
    Write-Host "  This is critical - cannot continue without core monitoring functionality" -ForegroundColor Red
    throw "Failed to load Unity-Claude-AutonomousMonitoring module: $_"
}

# Register with SystemStatus (if available)
try {
    Register-Subsystem -SubsystemName "AutonomousAgent" -ModulePath ".\Modules\Unity-Claude-AutonomousAgent" -HealthCheckLevel "Standard" -ProcessId $agentPID
    Write-Host "Registered AutonomousAgent subsystem with PID $agentPID" -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not register with SystemStatus: $_" -ForegroundColor Yellow
}

# Start the autonomous monitoring
Write-Host ""
Write-Host "Starting autonomous monitoring..." -ForegroundColor Cyan

try {
    # Call the main monitoring function from the module
    Start-AutonomousMonitoring -PollIntervalSeconds $PollIntervalSeconds -DebugMode:$DebugMode
} catch {
    Write-Host "CRITICAL ERROR: Autonomous monitoring failed: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    
    # Log the error
    $errorLog = @{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        Error = $_.Exception.Message
        StackTrace = $_.ScriptStackTrace
        ProcessId = $PID
    }
    $errorLog | ConvertTo-Json | Add-Content -Path ".\autonomous_monitoring_errors.log"
    
    throw $_
}

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDvZFzxwZ8u2YZs
# zSFFl9bxyK/npgR1YBg4bSHL7UrpJaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPRlmiaFv5Miq+mLFUesbBCg
# lsLsFCHw6O1GAKLQ8Hb2MA0GCSqGSIb3DQEBAQUABIIBAKELDfhhKEtIE/PdlOjM
# c/MIUVpLZpIfwzADuHgdmN3KbD2go5yS6hd0NGDa1DfhxE45d0NUN/tIe1DUeB4b
# WpJVl4g/wY3FckoyG1KGTsKDt46yPIUPwb3AgGWn4YEZfu5s2Hec667MYv+gNlsP
# Jao1x/0TkA2iHz7lLiD22eGkLHHwWQGkM2MQ3y3OJMEwt9a0Hm/ScvMzsWoFCeM4
# 8vwGphN3eXh89ftdZb1EDshnJsBce6aRfY+0hpD5VAT8RihadSy2BuNgO91UywBo
# iFKexkE9kch2iaeh0cByrZ3FqUOtrvLoCdMzBKH9LYrztUJth+s9+lEjr5l/5AVt
# rqE=
# SIG # End signature block
