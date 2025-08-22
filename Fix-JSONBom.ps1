# Fix-JSONBom.ps1 - Remove BOM from JSON file
param(
    [string]$FilePath = ".\system_status.json"
)

if (Test-Path $FilePath) {
    # Read the file as bytes
    $bytes = [System.IO.File]::ReadAllBytes($FilePath)
    
    # Check for UTF-8 BOM (EF BB BF)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        Write-Host "BOM detected, removing..."
        # Skip the first 3 bytes (BOM) and write the rest
        $newBytes = $bytes[3..($bytes.Length-1)]
        [System.IO.File]::WriteAllBytes($FilePath, $newBytes)
        Write-Host "BOM removed from $FilePath"
    } else {
        Write-Host "No BOM found in $FilePath"
    }
    
    # Verify the file is valid JSON
    try {
        $content = Get-Content $FilePath -Raw
        $json = $content | ConvertFrom-Json
        Write-Host "JSON is valid"
    } catch {
        Write-Host "Warning: JSON validation failed: $_"
    }
} else {
    Write-Host "File not found: $FilePath"
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU6EVj8RFvSX0ltPsZMXv1W00W
# gqWgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUSQHPUZtNJELcYZUUCaX/6HbkgyMwDQYJKoZIhvcNAQEBBQAEggEADKGZ
# qj1f2+/xK+R3RekCrv2GTxtqOgLwiNETpZXoBf67yHPZVS5D8iIWNvtejj0rustP
# SD6zpkJBq3s9dFouP3pmrgEVl1rcv5jhLIzoMOGDfaj2U4PBG7qxBh6PQL8OdzkC
# 8JlPRrrdluNSJ137Zxgi+o7CwlDfmQT91QQd9yW+kx1MiFFIJHIYxckLeJpOlEgU
# /ZykrVL901Jw53gJz3fR2vPNolcqB4mjuIlVdtr7Fmc+gh1c4DIoKe1qSbfM9Jsm
# 5izqOxCKhKS6SHbqSQFUdnAR6QVZ5q//cH+rmMnFdQZng4H17h+hbvjftFDxmsKV
# cG7CzgLvc/CDI4QVUw==
# SIG # End signature block
