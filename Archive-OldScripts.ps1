# Archive-OldScripts.ps1
# Move old debugging scripts to archive directory

$archiveDir = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Archive"
$sourceDir = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

# Files to archive
$filesToArchive = @(
    "Test-ModuleRefactoring.ps1",
    "Test-ModuleRefactoring-Enhanced.ps1", 
    "Check-UnicodeChars.ps1",
    "Validate-PowerShellSyntax.ps1",
    "Check-RefactoredModuleUnicode.ps1",
    "Validate-RefactoredModule.ps1"
)

$movedCount = 0
Write-Host "Archiving old debugging scripts..." -ForegroundColor Cyan

foreach ($file in $filesToArchive) {
    $sourcePath = Join-Path $sourceDir $file
    if (Test-Path $sourcePath) {
        $targetPath = Join-Path $archiveDir $file
        Move-Item $sourcePath $targetPath -Force
        Write-Host "  Archived: $file" -ForegroundColor Green
        $movedCount++
    } else {
        Write-Host "  Not found: $file" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Archived $movedCount old scripts to Archive directory" -ForegroundColor Cyan
Write-Host "Archive location: $archiveDir" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU4Z3k9Lp///eRFfeCD/sfUwjZ
# QF6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUuVNK+iFVTJrKFyUnOlX3+HItPoswDQYJKoZIhvcNAQEBBQAEggEAUQbH
# 264XiMo3GXMac63RbB2yseZWjdKF/GbKLslUrJqtZRZef1otjvUy2QzKSh/kFjhA
# KNQqaa8GCNxX88JPIYfF41yeA0ifamhkQCIWhRix9ug7ED4V14gRP1mvHDgRpZWR
# Vq6vsd0FjGr+6x1k9TJzERFtqrdo6JTTE9iqG6m48qfWBDQg7W5OQyvdKuVSPuEX
# n81Is0C6KJq+PenQBvE/CxwbslbzhFs4RXnHt2iX3G1sVOtPiL7i70RoibiBIvQn
# MjBoxqEMzpAwJD4mlCHfst0i9QJYwooWHPtumiSPVl5ZZ8AIn/mUl+WapA5tuDoI
# IORQfpxyhK2BoXtt2Q==
# SIG # End signature block
