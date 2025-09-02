# Unity-Claude Event Log Source Installation Script
# Run this script as Administrator to create the event source
# This only needs to be run once per machine

#Requires -RunAsAdministrator

param(
    [switch]$Force,
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'

Write-Host "Unity-Claude Event Log Source Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$LogName = 'Unity-Claude-Automation'
$SourceName = 'Unity-Claude-Agent'

try {
    if ($Uninstall) {
        Write-Host "Uninstalling event source..." -ForegroundColor Yellow
        
        if ([System.Diagnostics.EventLog]::SourceExists($SourceName)) {
            [System.Diagnostics.EventLog]::DeleteEventSource($SourceName)
            Write-Host "Event source '$SourceName' removed successfully" -ForegroundColor Green
        }
        else {
            Write-Host "Event source '$SourceName' does not exist" -ForegroundColor Yellow
        }
        
        # Check if log is empty and remove if so
        if ([System.Diagnostics.EventLog]::Exists($LogName)) {
            $log = New-Object System.Diagnostics.EventLog($LogName)
            if ($log.Entries.Count -eq 0) {
                [System.Diagnostics.EventLog]::Delete($LogName)
                Write-Host "Empty log '$LogName' removed" -ForegroundColor Green
            }
            else {
                Write-Host "Log '$LogName' contains entries and was not removed" -ForegroundColor Yellow
            }
            $log.Dispose()
        }
    }
    else {
        Write-Host "Installing event source..." -ForegroundColor Yellow
        Write-Host "Log Name: $LogName" -ForegroundColor Gray
        Write-Host "Source Name: $SourceName" -ForegroundColor Gray
        Write-Host ""
        
        # Check if source exists
        $sourceExists = [System.Diagnostics.EventLog]::SourceExists($SourceName)
        
        if ($sourceExists -and -not $Force) {
            Write-Host "Event source already exists!" -ForegroundColor Green
            
            # Verify it's associated with the correct log
            $currentLog = [System.Diagnostics.EventLog]::LogNameFromSourceName($SourceName, ".")
            if ($currentLog -eq $LogName) {
                Write-Host "Source is correctly associated with log '$LogName'" -ForegroundColor Green
            }
            else {
                Write-Host "WARNING: Source is associated with log '$currentLog' instead of '$LogName'" -ForegroundColor Yellow
                Write-Host "Use -Force parameter to recreate with correct association" -ForegroundColor Yellow
            }
        }
        else {
            if ($sourceExists -and $Force) {
                Write-Host "Removing existing source..." -ForegroundColor Yellow
                [System.Diagnostics.EventLog]::DeleteEventSource($SourceName)
                Start-Sleep -Seconds 1
            }
            
            # Create the event source
            Write-Host "Creating event source..." -ForegroundColor Yellow
            [System.Diagnostics.EventLog]::CreateEventSource($SourceName, $LogName)
            
            # Configure the log
            Write-Host "Configuring event log..." -ForegroundColor Yellow
            $log = New-Object System.Diagnostics.EventLog($LogName)
            $log.MaximumKilobytes = 20480  # 20MB
            $log.ModifyOverflowPolicy([System.Diagnostics.OverflowAction]::OverwriteOlder, 30)
            
            # Write initialization event
            $log.Source = $SourceName
            $log.WriteEntry(
                "Unity-Claude Event Log initialized`nInstalled by: $env:USERNAME`nMachine: $env:COMPUTERNAME`nTimestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
                [System.Diagnostics.EventLogEntryType]::Information,
                1000
            )
            $log.Dispose()
            
            Write-Host "Event source created successfully!" -ForegroundColor Green
            Write-Host ""
            Write-Host "Configuration:" -ForegroundColor Cyan
            Write-Host "  Maximum Size: 20 MB" -ForegroundColor Gray
            Write-Host "  Overflow: Overwrite events older than 30 days" -ForegroundColor Gray
            Write-Host "  Event ID Ranges:" -ForegroundColor Gray
            Write-Host "    1000-1999: Information" -ForegroundColor Gray
            Write-Host "    2000-2999: Warning" -ForegroundColor Gray
            Write-Host "    3000-3999: Error" -ForegroundColor Gray
            Write-Host "    4000-4999: Critical" -ForegroundColor Gray
            Write-Host "    5000-5999: Performance" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "Installation complete!" -ForegroundColor Green
        Write-Host ""
        Write-Host "You can now use the Unity-Claude-EventLog module to write events." -ForegroundColor Cyan
        Write-Host "Example:" -ForegroundColor Yellow
        Write-Host '  Import-Module Unity-Claude-EventLog' -ForegroundColor White
        Write-Host '  Write-UCEventLog -Message "Test event" -EntryType Information -Component Unity' -ForegroundColor White
    }
}
catch {
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host ""
    
    if ($_.Exception.Message -like "*requested registry access*") {
        Write-Host "This script must be run as Administrator!" -ForegroundColor Yellow
        Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    }
    
    exit 1
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD4jsDs2uJ+MmC0
# JFxs4n5P95f9W9IDxvAIJ98DNU9X8aCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINlmUEYXc3eicLBr0z7aCsma
# js3R5NvkB2KeEWTmPY89MA0GCSqGSIb3DQEBAQUABIIBACIvG3sY01UcD6V0iuNT
# 9YxCaqzxegNicCRbhFjkjN6Ez3FHtg9byGIOW9cDbI/zE8v0fMnM/a3T6a6ggMOI
# IZC6A+zlGD29f7XG4Tbp1q9qo1SwpWmbH4Mp6xe+NfYOavZa5ZyCbIRiyEOt0S0/
# +iKsytwTJhH/Z5j+maSGFuoaRgWJXyN6CIQigTN1LBOk4HG2cSQhrGQLbVDG47rv
# lz062uYnhS6RaMesk0ocEoWHxliqycgF3TDjCdJRI/WqOJ2DCsUq0AE/Xv6xkDZk
# 47LNWdxk0shewVR8z3QiQdh7l5mlzMXPoK5jXtGUVbKYPsNEWwmuzjtt1JI87i5J
# oWg=
# SIG # End signature block
