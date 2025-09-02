# Unity-Claude-CLIOrchestrator - Analysis Logging Component
# Refactored from ResponseAnalysisEngine.psm1 for better maintainability
# Compatible with PowerShell 5.1 and Claude Code CLI 2025

#region Module Configuration

# Default log path - can be overridden by parent module
$script:DefaultLogPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log"
$script:LogPath = $script:DefaultLogPath

#endregion

#region Core Logging Functions

function Write-AnalysisLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG", "PERF")]
        [string]$Level = "INFO",
        
        [Parameter()]
        [string]$Component = "ResponseAnalysisEngine",
        
        [Parameter()]
        [string]$LogPath = $script:LogPath
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [$Component] $Message"
    
    try {
        Add-Content -Path $LogPath -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
        # Silently continue if logging fails - avoid recursive errors
    }
    
    # Console output for debugging
    if ($Level -eq "ERROR") {
        Write-Error $Message
    } elseif ($Level -eq "WARN") {
        Write-Warning $Message
    } else {
        $color = switch ($Level) {
            "INFO" { "Green" }
            "DEBUG" { "Gray" }
            "PERF" { "Cyan" }
            default { "White" }
        }
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

function Set-AnalysisLogPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    $script:LogPath = $Path
    Write-AnalysisLog -Message "Log path updated to: $Path" -Level "INFO" -Component "AnalysisLogging"
}

function Get-AnalysisLogPath {
    [CmdletBinding()]
    param()
    
    return $script:LogPath
}

function Test-AnalysisLogging {
    [CmdletBinding()]
    param()
    
    $testResults = @()
    
    try {
        # Test basic logging
        Write-AnalysisLog -Message "Test message" -Level "INFO" -Component "TestComponent"
        $testResults += @{
            Name = "Basic Logging"
            Status = "Passed"
            Details = "Successfully wrote test log entry"
        }
        
        # Test log path functions
        $originalPath = Get-AnalysisLogPath
        $testPath = "$env:TEMP\test_analysis.log"
        Set-AnalysisLogPath -Path $testPath
        
        if ((Get-AnalysisLogPath) -eq $testPath) {
            $testResults += @{
                Name = "Log Path Management"
                Status = "Passed" 
                Details = "Successfully updated and retrieved log path"
            }
        } else {
            $testResults += @{
                Name = "Log Path Management"
                Status = "Failed"
                Details = "Log path not updated correctly"
            }
        }
        
        # Restore original path
        Set-AnalysisLogPath -Path $originalPath
        
    } catch {
        $testResults += @{
            Name = "Logging Component Test"
            Status = "Failed"
            Error = $_.Exception.Message
        }
    }
    
    return $testResults
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Write-AnalysisLog',
    'Set-AnalysisLogPath', 
    'Get-AnalysisLogPath',
    'Test-AnalysisLogging'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDthSBWsbAuatGf
# FOzOACv8YzfjmlcWf1jpDcztvbGEKKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIzzelSz9I3cLLkREbE+yLTb
# AUQsAJ08IDbrsDDaXcX+MA0GCSqGSIb3DQEBAQUABIIBAKtXxSJD99Ft9xTLHav3
# TwWv57K9Y58TwxTrRzJrmM4ZA8Cq05/28lzVyBOnOKXjqGbgGAz3en7YPHcTufGD
# Jw7GDocTlo/ITIBoES5ul1h6k/dzuGogK/Aqcwhe9hyq8AOIAXlJTDbd753vgL71
# 7fpavBUXZDc8iYlYqK2hmi2sSP/smbDirmPlRxyQr9nq1TeZJqR6t4sBavWohaLj
# o3vxunWssOR7vUUkSelWIjBiN+b5Lei/J+GqnhRPwEx00wjk3U3N4uuuOPJzUzjG
# 0XYX8ZWv5hvCvmUyMR/LEWX+xj2GOAkqUQs84ZF1KRPzmV965/eoltt2SgaY3tUY
# Lds=
# SIG # End signature block
