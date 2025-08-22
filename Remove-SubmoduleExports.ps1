# Remove-SubmoduleExports.ps1
# Removes Export-ModuleMember from submodules so they work with dot-sourcing
# Date: 2025-08-20

param(
    [string]$ModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-SystemStatus"
)

Write-Host "=== Removing Export-ModuleMember from Submodules ===" -ForegroundColor Cyan
Write-Host "This allows dot-sourcing to work properly" -ForegroundColor Gray

# Get all submodule files
$submoduleFiles = Get-ChildItem -Path $ModulePath -Filter "*.psm1" -Recurse | 
    Where-Object { $_.DirectoryName -ne $ModulePath }

$modifiedCount = 0
foreach ($file in $submoduleFiles) {
    $content = Get-Content $file.FullName -Raw
    
    # Check if file contains Export-ModuleMember
    if ($content -match 'Export-ModuleMember') {
        # Comment out Export-ModuleMember lines instead of removing them
        $newContent = $content -replace '(Export-ModuleMember[^\r\n]+)', '# $1 # Commented for dot-sourcing'
        
        $newContent | Set-Content $file.FullName -Encoding UTF8
        $modifiedCount++
        
        $relativePath = $file.FullName.Replace("$ModulePath\", "")
        Write-Host "Modified: $relativePath" -ForegroundColor Green
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Modified $modifiedCount submodule files" -ForegroundColor Green
Write-Host "Export-ModuleMember statements have been commented out" -ForegroundColor Gray
Write-Host "Submodules can now be dot-sourced successfully" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUkWDLs4Ej2coU1ITngsDDT0Gd
# i2KgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUSG1QRkddx1pduhNGVz35Q85tzn0wDQYJKoZIhvcNAQEBBQAEggEAhgSE
# ppCtYnBhviEopnMnd4u2M9COghyM1GfVLUMXm3YvDZ1yVUSEtllvAnB5MPT5M3g1
# uUqfvnpbDAUcREaM0u+bfy0ZZcVur8KXldkx35Z/7qRcJU13x3dilDdxmmHEwbtw
# marDYbxJUbQWOWbIu2h3xkpOfXKPEQUBIeiZQ9DR9oKjoJ8Vv+B9l3LkwyCtcC+2
# NHqW4zl797tKZAkHjsdpQejr7mPOPc0MdyNKMxZIk/PzAMdQNBjqc1Q6BQeIyN7B
# S2a6zUWVi7WAWiNuM/sTtJAFauIDyr2KfXSXwxbA4jkhDX08Uag5k4eM3Domc5ew
# y4z7ppLowXejUeDuyg==
# SIG # End signature block
