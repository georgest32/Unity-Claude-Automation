# Fix-SystemStatusMerge.ps1
# Fixes the Write-SystemStatus function to merge data instead of overwriting
# This preserves the ClaudeCodeCLI field and other fields that may not be in every update

$modulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1"

# Read the current module content
$content = Get-Content $modulePath -Raw

# Create the new Write-SystemStatus function that merges data
$newFunction = @'
function Write-SystemStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$StatusData
    )
    
    Write-SystemStatusLog "Writing system status to file (with merge)..." -Level 'DEBUG'
    
    try {
        # IMPORTANT: Read existing data first to preserve fields
        $existingData = $null
        if (Test-Path $script:SystemStatusConfig.SystemStatusFile) {
            try {
                $existingJson = Get-Content $script:SystemStatusConfig.SystemStatusFile -Raw
                $existingData = $existingJson | ConvertFrom-Json
            } catch {
                Write-SystemStatusLog "Could not read existing status file, will overwrite" -Level 'WARN'
            }
        }
        
        # If we have existing data, merge it
        if ($existingData) {
            # Deep merge function to preserve existing fields
            function Merge-DeepHashtable {
                param($Target, $Source)
                
                foreach ($key in $Source.Keys) {
                    if ($Target.ContainsKey($key)) {
                        if ($Source[$key] -is [hashtable] -and $Target[$key] -is [hashtable]) {
                            # Recursively merge hashtables
                            Merge-DeepHashtable -Target $Target[$key] -Source $Source[$key]
                        } else {
                            # Overwrite with new value
                            $Target[$key] = $Source[$key]
                        }
                    } else {
                        # Add new key
                        $Target[$key] = $Source[$key]
                    }
                }
            }
            
            # Convert existing PSCustomObject to hashtable for merging
            $existingHash = @{}
            foreach ($prop in $existingData.PSObject.Properties) {
                $existingHash[$prop.Name] = $prop.Value
            }
            
            # Merge the new data into existing data
            Merge-DeepHashtable -Target $existingHash -Source $StatusData
            
            # Use the merged data
            $StatusData = $existingHash
        }
        
        # Update last update timestamp
        if (-not $StatusData.ContainsKey('SystemInfo')) {
            $StatusData['SystemInfo'] = @{}
        }
        $StatusData.SystemInfo.LastUpdate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        
        # Validate data before writing
        if (-not (Test-SystemStatusSchema -StatusData $StatusData)) {
            Write-SystemStatusLog "System status data failed validation, writing anyway with warning" -Level 'WARN'
        }
        
        # Convert to JSON and write (following existing JSON file patterns)
        $jsonContent = $StatusData | ConvertTo-Json -Depth 10
        $jsonContent | Out-File -FilePath $script:SystemStatusConfig.SystemStatusFile -Encoding UTF8
        
        Write-SystemStatusLog "Successfully wrote system status file (with merge)" -Level 'OK'
        return $true
    } catch {
        Write-SystemStatusLog "Error writing system status: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}
'@

# Find the old function and replace it
$pattern = 'function Write-SystemStatus \{[\s\S]*?\n\}\s*\n'
if ($content -match $pattern) {
    $content = $content -replace $pattern, "$newFunction`n"
    
    # Write the updated content back
    $content | Set-Content $modulePath -Encoding UTF8
    
    Write-Host "Successfully updated Write-SystemStatus function to preserve existing fields" -ForegroundColor Green
    Write-Host "The function now merges updates with existing data instead of overwriting" -ForegroundColor Cyan
} else {
    Write-Host "Could not find Write-SystemStatus function to replace" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUbmfij/fSsQWHFN85HUg4fd4l
# jlugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUc0ecKfe2YrzdpTluZ3E7C0jW1cgwDQYJKoZIhvcNAQEBBQAEggEAMAoP
# rTocNPPgFslB0Dg0wX8ACB8mQJe1Xu1EQD55IlT96Yv+q0QJRZiIM4BFu3qK1I5n
# ZHpMQKgU0NmmrWfosiGwfsZsyo6UtANoEtUfUd5J9ho5prVwhAw8m9SPwR9eQiob
# CZIBxyzdkQku02ji1TJH8QwzmVPN6R5I2639I19JTOIwKjNOi2XN61DdTnAOHbQt
# /zt8wj2Mm6lNfoyMDFbIIKjy5DehuKUWz5xSnb821ENt66Wzw9rtQKpaxPCirTn+
# JFQ58fzlCscAWl+ESoX6fJMzaCZtV4J0kcHK3EWGb2Jr1h0n3NRhOy4BR4I/u0Z5
# cbFsY83/MzIkq2axAg==
# SIG # End signature block
