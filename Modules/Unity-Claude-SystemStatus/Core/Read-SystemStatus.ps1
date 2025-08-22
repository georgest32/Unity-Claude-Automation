
function Read-SystemStatus {
    [CmdletBinding()]
    param()
    
    Write-SystemStatusLog "Reading system status from file..." -Level 'DEBUG'
    
    try {
        Write-SystemStatusLog "SystemStatusConfig check - file path: $($script:SystemStatusConfig.SystemStatusFile)" -Level 'DEBUG'
        
        if (Test-Path $script:SystemStatusConfig.SystemStatusFile) {
            Write-SystemStatusLog "File exists, reading content..." -Level 'DEBUG'
            $jsonContent = Get-Content $script:SystemStatusConfig.SystemStatusFile -Raw -Encoding UTF8
            
            # Remove BOM if present (fixes ConvertFrom-Json issues)
            if ($jsonContent -and $jsonContent.Length -gt 0) {
                $jsonContent = $jsonContent -replace '^\xEF\xBB\xBF', ''
            }
            
            $contentLength = if ($jsonContent) { $jsonContent.Length } else { 'null' }
            Write-SystemStatusLog "Raw content type: $($jsonContent.GetType().Name), length: $contentLength" -Level 'DEBUG'
            
            if ([string]::IsNullOrWhiteSpace($jsonContent)) {
                Write-SystemStatusLog "System status file is empty, using default data" -Level 'WARN'
                return $script:SystemStatusData.Clone()
            }
            
            Write-SystemStatusLog "Parsing JSON content..." -Level 'DEBUG'
            $statusData = $jsonContent | ConvertFrom-Json
            
            $dataType = if ($statusData) { $statusData.GetType().Name } else { 'null' }
            Write-SystemStatusLog "JSON parsing result - type: $dataType, null check: $($null -eq $statusData)" -Level 'DEBUG'
            
            if ($null -eq $statusData) {
                Write-SystemStatusLog "Failed to parse JSON content, using default data" -Level 'WARN'
                return $script:SystemStatusData.Clone()
            }
            
            # Convert PSCustomObject to hashtable for easier manipulation (PowerShell 5.1 compatibility)
            Write-SystemStatusLog "About to call ConvertTo-HashTable with InputObject type: $($statusData.GetType().Name)" -Level 'DEBUG'
            
            try {
                $result = ConvertTo-HashTable -InputObject $statusData
                Write-SystemStatusLog "ConvertTo-HashTable succeeded, result type: $($result.GetType().Name)" -Level 'DEBUG'
            } catch {
                Write-SystemStatusLog "ConvertTo-HashTable failed: $($_.Exception.Message)" -Level 'ERROR'
                Write-SystemStatusLog "InputObject was: $($statusData | ConvertTo-Json -Compress)" -Level 'DEBUG'
                throw
            }
            
            Write-SystemStatusLog "Successfully read system status file" -Level 'OK'
            return $result
        } else {
            Write-SystemStatusLog "System status file not found, using default data" -Level 'WARN'
            return $script:SystemStatusData.Clone()
        }
    } catch {
        Write-SystemStatusLog "Error reading system status: $($_.Exception.Message)" -Level 'ERROR'
        return $script:SystemStatusData.Clone()
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUV9iK1t1gpMuqFxPEU4k1XYsX
# JkugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUjZhSPjdgnULk4D5On0zDW+C+1P8wDQYJKoZIhvcNAQEBBQAEggEASrxA
# WVx8E1qloeZcQvpiWIeq4NsGST/iUkDBTjZh/rK3as4Zu+Yw2IOhtYMtA7DGyNgC
# /x9WZouwuiNqVOGzVI0PNoIS8LKuMaNLG93RoGrHL4UEuIB6L92ZVk4NZcXhmErI
# jB0VZ3k724Gnrp1/q6s08C/PtlSpFDceYJHcxCTZPUPJBmFqJKuTHxohHRhs2gnI
# MQsrWtIwAlZTo16I4Px97MgPbp2hyNuEyCEO2c7X4FAeu8Uqxfjtpbb+P6qvZvg9
# BQuKuGGgtNW9T2xJRG6CGVZ8JWbeRI0UepV7qTTxTdkAs93DzkQ0IOmrBternduX
# IQnOJ6z3RoFvwDQ5yQ==
# SIG # End signature block
