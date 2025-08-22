# Find-ImportSideEffects.ps1
# Scanner to find module-scope code that executes during import
# Based on ChatGPT's analysis of the Notepad cascade issue

function Find-ImportSideEffects {
    [CmdletBinding()] 
    param(
        [string]$Path = "."
    )
    
    $files = Get-ChildItem $Path -Recurse -Include *.ps1,*.psm1
    foreach ($f in $files) {
        $t = Get-Content $f.FullName -Raw
        # Remove function bodies to isolate file-scope code
        $t2 = [regex]::Replace($t, '(?s)^\s*function\s+\w[\w-]*\s*\{.*?\}\s*', '')
        $t2 = ($t2 -split '\r?\n' | Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() }) -join "`n"
        if ($t2.Trim()) {
            $hit = $t2 -match '(^|\s)(Invoke-Item|ii|Start-Process|notepad(?:\.exe)?|New-Item|Out-File|Set-Content)\b'
            [pscustomobject]@{
                File          = $f.FullName
                HasFileScope  = $true
                SuspiciousHit = if ($hit) { $matches[0].Trim() } else { '(other code at module scope)' }
                FileScopeCode = $t2.Trim()
            }
        }
    }
}

# Run the scan
Write-Host "=== Scanning for Import Side Effects ===" -ForegroundColor Cyan
Find-ImportSideEffects -Path ".\Modules\Unity-Claude-ParallelProcessing" | Format-List
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUiGawNKC732eIQTU2m7TzTCSa
# HI6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUDZ50KQGDVeg6fMCQqVXat7dfkskwDQYJKoZIhvcNAQEBBQAEggEAr7r+
# t3DOt16HuSibD9e7ORZEx/uAOm8WB1tabhBPi1xNCyJuJ/I96vjYeznxBQGAfysT
# pHceHGehfWqF4su/rZ/KNfYQXsCQWPcAG0e4W7098d3qU6YOPBXYoom1t07yHAGT
# sCNpfX14hH7/ICXqzfARPPMK5uEPDkHWNP32VSEkalUnVp+4EoLSaCrgN4fbDku8
# 2yEqe4ablxEdQ1a6eGfszl0z4/TRkxU7tGvSt3xYIkZBd69Wo7X4zVkr/xf7/Z32
# Y+pWfZFFTAudjeBU1UgjCI8qQzuOfbzKwRtugJgsU9mj7PGlzWXEFaFFYwLsFxWp
# YC/tWJ5z55u4XF4UpA==
# SIG # End signature block
