# Edit-AutomationConfig.ps1
# Day 19: Interactive Configuration Editor
# Provides a user-friendly interface for customizing autonomous system settings

param(
    [ValidateSet("development", "production", "test")]
    [string]$Environment = "development",
    
    [switch]$GUI
)

# Import configuration module
Import-Module (Join-Path $PSScriptRoot "Unity-Claude-Configuration.psm1") -Force

function Show-ConfigurationMenu {
    Clear-Host
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  Unity-Claude Automation Configuration Editor" -ForegroundColor Yellow
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Environment: " -NoNewline
    Write-Host $Environment -ForegroundColor Green
    Write-Host ""
    Write-Host "Main Menu:" -ForegroundColor White
    Write-Host "  1. View Current Configuration" -ForegroundColor Gray
    Write-Host "  2. Edit Autonomous Operation Settings" -ForegroundColor Gray
    Write-Host "  3. Edit Claude CLI Settings" -ForegroundColor Gray
    Write-Host "  4. Edit Monitoring Thresholds" -ForegroundColor Gray
    Write-Host "  5. Edit Dashboard Settings" -ForegroundColor Gray
    Write-Host "  6. Edit Error Handling" -ForegroundColor Gray
    Write-Host "  7. Validate Configuration" -ForegroundColor Gray
    Write-Host "  8. Export Configuration" -ForegroundColor Gray
    Write-Host "  9. Import Configuration" -ForegroundColor Gray
    Write-Host "  S. Switch Environment" -ForegroundColor Gray
    Write-Host "  R. Reset to Defaults" -ForegroundColor Gray
    Write-Host "  Q. Quit" -ForegroundColor Gray
    Write-Host ""
}

function Edit-AutonomousOperation {
    Clear-Host
    Write-Host "=== Autonomous Operation Settings ===" -ForegroundColor Yellow
    Write-Host ""
    
    $config = Get-AutomationConfig -Section "autonomous_operation" -Environment $Environment
    
    Write-Host "Current Settings:" -ForegroundColor Cyan
    Write-Host "  Enabled: $($config.enabled)" -ForegroundColor Gray
    Write-Host "  Max Conversation Rounds: $($config.max_conversation_rounds)" -ForegroundColor Gray
    Write-Host "  Response Timeout (ms): $($config.response_timeout_ms)" -ForegroundColor Gray
    Write-Host "  Auto Recovery: $($config.auto_recovery)" -ForegroundColor Gray
    Write-Host "  Pattern Learning: $($config.pattern_learning)" -ForegroundColor Gray
    Write-Host ""
    
    $changes = $false
    
    # Enable/Disable
    $enable = Read-Host "Enable autonomous operation? (Y/N) [Current: $($config.enabled)]"
    if ($enable -ne "") {
        $config.enabled = $enable -eq "Y"
        $changes = $true
    }
    
    # Max rounds
    $rounds = Read-Host "Max conversation rounds (1-100) [Current: $($config.max_conversation_rounds)]"
    if ($rounds -ne "") {
        if ([int]::TryParse($rounds, [ref]$null)) {
            $roundsInt = [int]$rounds
            if ($roundsInt -ge 1 -and $roundsInt -le 100) {
                $config.max_conversation_rounds = $roundsInt
                $changes = $true
            } else {
                Write-Host "Invalid value. Must be between 1 and 100." -ForegroundColor Red
            }
        }
    }
    
    # Response timeout
    $timeout = Read-Host "Response timeout in seconds (1-600) [Current: $($config.response_timeout_ms / 1000)]"
    if ($timeout -ne "") {
        if ([int]::TryParse($timeout, [ref]$null)) {
            $timeoutInt = [int]$timeout
            if ($timeoutInt -ge 1 -and $timeoutInt -le 600) {
                $config.response_timeout_ms = $timeoutInt * 1000
                $changes = $true
            } else {
                Write-Host "Invalid value. Must be between 1 and 600 seconds." -ForegroundColor Red
            }
        }
    }
    
    # Auto recovery
    $recovery = Read-Host "Enable auto recovery? (Y/N) [Current: $($config.auto_recovery)]"
    if ($recovery -ne "") {
        $config.auto_recovery = $recovery -eq "Y"
        $changes = $true
    }
    
    # Pattern learning
    $learning = Read-Host "Enable pattern learning? (Y/N) [Current: $($config.pattern_learning)]"
    if ($learning -ne "") {
        $config.pattern_learning = $learning -eq "Y"
        $changes = $true
    }
    
    if ($changes) {
        $save = Read-Host "`nSave changes? (Y/N)"
        if ($save -eq "Y") {
            Set-AutomationConfig -Section "autonomous_operation" -Value $config -Environment $Environment -Persist
            Write-Host "Settings saved successfully!" -ForegroundColor Green
        } else {
            Write-Host "Changes discarded." -ForegroundColor Yellow
        }
    } else {
        Write-Host "`nNo changes made." -ForegroundColor Gray
    }
    
    Read-Host "`nPress Enter to continue..."
}

function Edit-ClaudeCLISettings {
    Clear-Host
    Write-Host "=== Claude CLI Settings ===" -ForegroundColor Yellow
    Write-Host ""
    
    $config = Get-AutomationConfig -Section "claude_cli" -Environment $Environment
    
    Write-Host "Current Settings:" -ForegroundColor Cyan
    Write-Host "  Window Title: $($config.window_title)" -ForegroundColor Gray
    Write-Host "  Response Path: $($config.response_path)" -ForegroundColor Gray
    Write-Host "  Submission Delay (ms): $($config.submission_delay_ms)" -ForegroundColor Gray
    Write-Host "  Auto Focus: $($config.auto_focus)" -ForegroundColor Gray
    Write-Host ""
    
    $changes = $false
    
    # Window title
    $title = Read-Host "Window title pattern [Current: $($config.window_title)]"
    if ($title -ne "") {
        $config.window_title = $title
        $changes = $true
    }
    
    # Response path
    $path = Read-Host "Response file path [Current: $($config.response_path)]"
    if ($path -ne "") {
        $config.response_path = $path
        $changes = $true
    }
    
    # Submission delay
    $delay = Read-Host "Submission delay in ms (100-5000) [Current: $($config.submission_delay_ms)]"
    if ($delay -ne "") {
        if ([int]::TryParse($delay, [ref]$null)) {
            $delayInt = [int]$delay
            if ($delayInt -ge 100 -and $delayInt -le 5000) {
                $config.submission_delay_ms = $delayInt
                $changes = $true
            } else {
                Write-Host "Invalid value. Must be between 100 and 5000 ms." -ForegroundColor Red
            }
        }
    }
    
    # Auto focus
    $focus = Read-Host "Enable auto focus? (Y/N) [Current: $($config.auto_focus)]"
    if ($focus -ne "") {
        $config.auto_focus = $focus -eq "Y"
        $changes = $true
    }
    
    if ($changes) {
        $save = Read-Host "`nSave changes? (Y/N)"
        if ($save -eq "Y") {
            Set-AutomationConfig -Section "claude_cli" -Value $config -Environment $Environment -Persist
            Write-Host "Settings saved successfully!" -ForegroundColor Green
        } else {
            Write-Host "Changes discarded." -ForegroundColor Yellow
        }
    } else {
        Write-Host "`nNo changes made." -ForegroundColor Gray
    }
    
    Read-Host "`nPress Enter to continue..."
}

function Edit-MonitoringThresholds {
    Clear-Host
    Write-Host "=== Monitoring Thresholds ===" -ForegroundColor Yellow
    Write-Host ""
    
    $config = Get-AutomationConfig -Section "monitoring" -Environment $Environment
    
    Write-Host "Current Settings:" -ForegroundColor Cyan
    Write-Host "  Check Interval (s): $($config.check_interval_seconds)" -ForegroundColor Gray
    Write-Host "  Memory Warning (MB): $($config.thresholds.memory_warning_mb)" -ForegroundColor Gray
    Write-Host "  Memory Critical (MB): $($config.thresholds.memory_critical_mb)" -ForegroundColor Gray
    Write-Host "  CPU Warning (%): $($config.thresholds.cpu_warning_percent)" -ForegroundColor Gray
    Write-Host "  CPU Critical (%): $($config.thresholds.cpu_critical_percent)" -ForegroundColor Gray
    Write-Host "  Error Rate Warning: $($config.thresholds.error_rate_warning)" -ForegroundColor Gray
    Write-Host "  Error Rate Critical: $($config.thresholds.error_rate_critical)" -ForegroundColor Gray
    Write-Host ""
    
    $changes = $false
    
    # Check interval
    $interval = Read-Host "Check interval in seconds (1-300) [Current: $($config.check_interval_seconds)]"
    if ($interval -ne "") {
        if ([int]::TryParse($interval, [ref]$null)) {
            $intervalInt = [int]$interval
            if ($intervalInt -ge 1 -and $intervalInt -le 300) {
                $config.check_interval_seconds = $intervalInt
                $changes = $true
            }
        }
    }
    
    # Memory thresholds
    $memWarn = Read-Host "Memory warning threshold (MB) [Current: $($config.thresholds.memory_warning_mb)]"
    if ($memWarn -ne "") {
        if ([int]::TryParse($memWarn, [ref]$null)) {
            $config.thresholds.memory_warning_mb = [int]$memWarn
            $changes = $true
        }
    }
    
    $memCrit = Read-Host "Memory critical threshold (MB) [Current: $($config.thresholds.memory_critical_mb)]"
    if ($memCrit -ne "") {
        if ([int]::TryParse($memCrit, [ref]$null)) {
            $config.thresholds.memory_critical_mb = [int]$memCrit
            $changes = $true
        }
    }
    
    # CPU thresholds
    $cpuWarn = Read-Host "CPU warning threshold (%) [Current: $($config.thresholds.cpu_warning_percent)]"
    if ($cpuWarn -ne "") {
        if ([int]::TryParse($cpuWarn, [ref]$null)) {
            $cpuPercent = [int]$cpuWarn
            if ($cpuPercent -ge 0 -and $cpuPercent -le 100) {
                $config.thresholds.cpu_warning_percent = $cpuPercent
                $changes = $true
            }
        }
    }
    
    $cpuCrit = Read-Host "CPU critical threshold (%) [Current: $($config.thresholds.cpu_critical_percent)]"
    if ($cpuCrit -ne "") {
        if ([int]::TryParse($cpuCrit, [ref]$null)) {
            $cpuPercent = [int]$cpuCrit
            if ($cpuPercent -ge 0 -and $cpuPercent -le 100) {
                $config.thresholds.cpu_critical_percent = $cpuPercent
                $changes = $true
            }
        }
    }
    
    if ($changes) {
        $save = Read-Host "`nSave changes? (Y/N)"
        if ($save -eq "Y") {
            Set-AutomationConfig -Section "monitoring" -Value $config -Environment $Environment -Persist
            Write-Host "Settings saved successfully!" -ForegroundColor Green
        } else {
            Write-Host "Changes discarded." -ForegroundColor Yellow
        }
    } else {
        Write-Host "`nNo changes made." -ForegroundColor Gray
    }
    
    Read-Host "`nPress Enter to continue..."
}

function View-Configuration {
    Clear-Host
    Write-Host "=== Current Configuration ===" -ForegroundColor Yellow
    Write-Host "Environment: $Environment" -ForegroundColor Cyan
    Write-Host ""
    
    $config = Get-AutomationConfig -Environment $Environment
    
    function Show-ConfigTree {
        param($Object, $Indent = 0)
        
        foreach ($key in $Object.Keys) {
            $value = $Object[$key]
            $spaces = " " * $Indent
            
            if ($value -is [hashtable]) {
                Write-Host "$spaces$key:" -ForegroundColor Cyan
                Show-ConfigTree -Object $value -Indent ($Indent + 2)
            } else {
                Write-Host "$spaces$key: " -NoNewline -ForegroundColor Gray
                Write-Host $value -ForegroundColor White
            }
        }
    }
    
    Show-ConfigTree -Object $config
    
    Write-Host ""
    Read-Host "Press Enter to continue..."
}

function Validate-Configuration {
    Clear-Host
    Write-Host "=== Configuration Validation ===" -ForegroundColor Yellow
    Write-Host "Environment: $Environment" -ForegroundColor Cyan
    Write-Host ""
    
    $validation = Test-AutomationConfig -Environment $Environment
    
    if ($validation.Valid) {
        Write-Host "Configuration is VALID" -ForegroundColor Green
    } else {
        Write-Host "Configuration has ERRORS" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Validation Results:" -ForegroundColor Cyan
    
    foreach ($result in $validation.Results) {
        $symbol = if ($result.Valid) { "" } else { "" }
        $color = if ($result.Valid) { "Green" } else { "Red" }
        
        Write-Host "  $symbol " -NoNewline -ForegroundColor $color
        Write-Host "$($result.Section): " -NoNewline
        Write-Host $result.Message -ForegroundColor Gray
    }
    
    Write-Host ""
    Read-Host "Press Enter to continue..."
}

function Export-Configuration {
    Clear-Host
    Write-Host "=== Export Configuration ===" -ForegroundColor Yellow
    Write-Host ""
    
    $config = Get-AutomationConfig -Environment $Environment
    
    $filename = Read-Host "Enter export filename (without extension)"
    if ($filename -eq "") {
        $filename = "config_export_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    }
    
    $filepath = Join-Path $PSScriptRoot "$filename.json"
    
    try {
        $config | ConvertTo-Json -Depth 10 | Set-Content $filepath
        Write-Host "Configuration exported to: $filepath" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to export configuration: $_" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue..."
}

function Import-Configuration {
    Clear-Host
    Write-Host "=== Import Configuration ===" -ForegroundColor Yellow
    Write-Host ""
    
    $filepath = Read-Host "Enter path to configuration file"
    
    if (Test-Path $filepath) {
        try {
            $importedConfig = Get-Content $filepath -Raw | ConvertFrom-Json -AsHashtable
            
            Write-Host "`nImported configuration preview:" -ForegroundColor Cyan
            $importedConfig | ConvertTo-Json -Depth 3 | Write-Host
            
            $confirm = Read-Host "`nImport this configuration? This will overwrite current settings. (Y/N)"
            
            if ($confirm -eq "Y") {
                # Save imported config
                $configPath = Join-Path $PSScriptRoot "autonomous_config.$Environment.json"
                $importedConfig | ConvertTo-Json -Depth 10 | Set-Content $configPath
                
                Write-Host "Configuration imported successfully!" -ForegroundColor Green
                Write-Host "Restart the application for changes to take effect." -ForegroundColor Yellow
            } else {
                Write-Host "Import cancelled." -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "Failed to import configuration: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "File not found: $filepath" -ForegroundColor Red
    }
    
    Read-Host "`nPress Enter to continue..."
}

function Reset-Configuration {
    Clear-Host
    Write-Host "=== Reset Configuration to Defaults ===" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "WARNING: This will reset all settings to default values!" -ForegroundColor Red
    Write-Host ""
    
    $confirm = Read-Host "Are you sure you want to reset? (Type 'RESET' to confirm)"
    
    if ($confirm -eq "RESET") {
        $envConfigPath = Join-Path $PSScriptRoot "autonomous_config.$Environment.json"
        $cachePath = Join-Path $PSScriptRoot "config_cache.json"
        
        if (Test-Path $envConfigPath) {
            Remove-Item $envConfigPath -Force
            Write-Host "Environment-specific configuration removed." -ForegroundColor Yellow
        }
        
        if (Test-Path $cachePath) {
            Remove-Item $cachePath -Force
            Write-Host "Configuration cache cleared." -ForegroundColor Yellow
        }
        
        Write-Host "Configuration reset to defaults!" -ForegroundColor Green
    } else {
        Write-Host "Reset cancelled." -ForegroundColor Yellow
    }
    
    Read-Host "`nPress Enter to continue..."
}

# Main loop
if ($GUI) {
    Write-Host "GUI mode not yet implemented. Using text interface." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
}

$running = $true
while ($running) {
    Show-ConfigurationMenu
    $choice = Read-Host "Enter your choice"
    
    switch ($choice.ToUpper()) {
        "1" { View-Configuration }
        "2" { Edit-AutonomousOperation }
        "3" { Edit-ClaudeCLISettings }
        "4" { Edit-MonitoringThresholds }
        "5" { 
            Write-Host "Dashboard settings editor not yet implemented." -ForegroundColor Yellow
            Read-Host "Press Enter to continue..."
        }
        "6" { 
            Write-Host "Error handling editor not yet implemented." -ForegroundColor Yellow
            Read-Host "Press Enter to continue..."
        }
        "7" { Validate-Configuration }
        "8" { Export-Configuration }
        "9" { Import-Configuration }
        "S" {
            Clear-Host
            Write-Host "Select Environment:" -ForegroundColor Yellow
            Write-Host "  1. Development" -ForegroundColor Gray
            Write-Host "  2. Production" -ForegroundColor Gray
            Write-Host "  3. Test" -ForegroundColor Gray
            
            $envChoice = Read-Host "Enter choice"
            switch ($envChoice) {
                "1" { $Environment = "development" }
                "2" { $Environment = "production" }
                "3" { $Environment = "test" }
            }
        }
        "R" { Reset-Configuration }
        "Q" { 
            $running = $false
            Write-Host "Goodbye!" -ForegroundColor Green
        }
        default {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUCzKXwMc6B1zUql1nsNc1rRse
# OsagggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQU9m9VjqbMdleAPEUHvsNWVUCPzVowDQYJKoZIhvcNAQEBBQAEggEAb4Fv
# jKi7NbEiLSGSIpmcjc2xTfuQnBuNYhtcWk7PLv8REC1SIWpB1ZU/9OH/EwTG71zc
# Odz3yQciX8r6H17fEdiipcKZT9FaPecdc7MUkDoBmdX4JTUsaK5cZCfRFc3ZttDf
# 4BbZfuufoEiNF+sUUEeYM9zkQYQ4CIRxuzgks+EfbvDcHqAr64B627ywNPawW9GE
# OMYXSWt0c4wI428rAWgoIaut6pgqDFuuEBcjZ7grPFkxSIWgG95HBX9WTIySxSZC
# 88tNXb1rOcnYTJIDJwJuQC4GGQ+2wfxHVD8xRQM/+BZEYlK7I0zrwNjTrcTdo/wJ
# OtbEspxe3OPFCcp65g==
# SIG # End signature block
