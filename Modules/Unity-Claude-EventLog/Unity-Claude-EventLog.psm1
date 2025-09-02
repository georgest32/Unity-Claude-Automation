# Unity-Claude-EventLog Module
# Provides Windows Event Log integration for Unity-Claude Automation System
# Supports both PowerShell 5.1 and PowerShell 7+

# Module-level variables
$script:ModuleName = 'Unity-Claude-EventLog'
$script:ModuleVersion = '1.0.0'
$script:LogName = 'Unity-Claude-Automation'
$script:SourceName = 'Unity-Claude-Agent'
$script:IsPSCore = $PSVersionTable.PSEdition -eq 'Core'

# Debug logging
$script:DebugLogPath = Join-Path $PSScriptRoot "..\..\unity_claude_automation.log"

# Load module configuration from manifest
$script:ModuleConfig = $null
try {
    $manifestPath = Join-Path $PSScriptRoot "$ModuleName.psd1"
    if (Test-Path $manifestPath) {
        $manifestData = Import-PowerShellDataFile -Path $manifestPath
        $script:ModuleConfig = $manifestData.PrivateData.EventLogConfig
        
        # Update module variables from config
        if ($script:ModuleConfig) {
            $script:LogName = $script:ModuleConfig.LogName
            $script:SourceName = $script:ModuleConfig.SourceName
        }
    }
}
catch {
    Write-Warning "Failed to load module configuration: $_"
}

# Helper function for debug logging
function Write-UCDebugLog {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logEntry = "[$timestamp] [$Level] [EventLog] $Message"
    
    try {
        Add-Content -Path $script:DebugLogPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Silently fail if unable to write to debug log
    }
}

# Load all function files
$functionFolders = @('Core', 'Query', 'Setup')
foreach ($folder in $functionFolders) {
    $folderPath = Join-Path $PSScriptRoot $folder
    if (Test-Path $folderPath) {
        $files = Get-ChildItem -Path $folderPath -Filter '*.ps1' -File
        foreach ($file in $files) {
            try {
                Write-UCDebugLog "Loading function file: $($file.Name)"
                . $file.FullName
                Write-UCDebugLog "Successfully loaded: $($file.Name)"
            }
            catch {
                Write-Warning "Failed to load $($file.Name): $_"
                Write-UCDebugLog "ERROR loading $($file.Name): $_" -Level 'ERROR'
            }
        }
    }
}

# Module initialization
Write-UCDebugLog "Unity-Claude-EventLog module v$script:ModuleVersion loaded"
Write-UCDebugLog "PowerShell Edition: $($PSVersionTable.PSEdition)"
Write-UCDebugLog "PowerShell Version: $($PSVersionTable.PSVersion)"
Write-UCDebugLog "Event Log Name: $script:LogName"
Write-UCDebugLog "Event Source: $script:SourceName"

# Export module members (defined in manifest)
Write-UCDebugLog "Module initialization complete"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCZZX+C9vDCzfjz
# S1CuZywvppMBSc2RF4hDRqRPw9CeW6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICAfiSTIpf0Avld7lRJgclUg
# oXqAd+Sf3UJmlGSATAD+MA0GCSqGSIb3DQEBAQUABIIBADRLAeFoRwYBGBw9OP8k
# /XJsZjqGte0b6U1ywBkrxb5nv5tjtb9mrJNs4ZpCEiz9U9baOQGu/sLNrlyIWz2u
# zpb0rAYxBdblhVdTKpz6lxFraBbe/1vET/mT+KWj/PwaffKWCCl39IYUFZ3RU+3z
# b814l0mAgPwwIaBOHRN+TdWQPXulOrz3B8+VC+q7G0MZbSLuPFicvfQHh42x3imk
# SBBuwpIeFBaKUwLcHG71cVu7WW71vPuh9npOk3aW2DRQPTCiOugdO2Qhg6HN1rV9
# M8XV9WRzH065G06xI/oXXO/q7vGC++w9cRDDe1ri7J4YGftzv2B8dG6XMmANqKOP
# zSg=
# SIG # End signature block
