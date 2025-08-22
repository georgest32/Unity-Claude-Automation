
function ConvertTo-HashTable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $InputObject
    )
    
    # Handle null input
    if ($null -eq $InputObject) {
        return @{}
    }
    
    # Recursively convert PSCustomObject to HashTable for PowerShell 5.1 compatibility
    if ($InputObject -is [PSCustomObject]) {
        $hash = @{}
        foreach ($property in $InputObject.PSObject.Properties) {
            # Add null validation for recursive calls to prevent "Cannot bind argument" errors
            if ($null -ne $property.Value) {
                $hash[$property.Name] = ConvertTo-HashTable -InputObject $property.Value
            } else {
                $hash[$property.Name] = $null
            }
        }
        return $hash
    } elseif ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        $array = @()
        foreach ($item in $InputObject) {
            # Add null validation for recursive calls to prevent "Cannot bind argument" errors
            if ($null -ne $item) {
                $array += ConvertTo-HashTable -InputObject $item
            } else {
                $array += $null
            }
        }
        return $array
    } else {
        return $InputObject
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU88nT4JfNGm5m23eCVh8cFpkb
# CQGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUq03KmWM6zA3eekv6A2Q/sYB/xIYwDQYJKoZIhvcNAQEBBQAEggEAmbtv
# P6ow7YMpczwvZLsCImAbFOTbxSVhZJq4jnK3mvS+o+YhYy/1+cGnndMeI2IFolWV
# mFCwIc0Q8PNHDaIGH1dL6ZolmiKzQ3NXNBzlITXNiywDERVu30og7Od6cJJA4a5f
# +3ItFaIKK9qGDTQMFpTcs3LG/4Xb4br5rJSM6Rysb+FK/yUlP9dSiDWam1QO/Oix
# vKs5NFgHxxq9T4DUFlNLuFSyMQCELl9yF37N9y0aft2ku5UteIqZSjanXwbwoNKB
# QdO07zJopbqw89samALxkBNvcEUL4w7UCZPg+sH4JerXaZhUlRcE8PwI/CNWLf5g
# +2//nXxAKDWq3pPU4A==
# SIG # End signature block
