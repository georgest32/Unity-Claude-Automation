# Fix-ManifestBOM.ps1
# Removes UTF-8 BOM from manifest files

$manifestFiles = @(
    ".\Manifests\SystemMonitoring.manifest.psd1",
    ".\Manifests\AutonomousAgent.manifest.psd1",
    ".\Manifests\CLISubmission.manifest.psd1"
)

foreach ($file in $manifestFiles) {
    if (Test-Path $file) {
        Write-Host "Processing: $file"
        
        # Read content as bytes
        $bytes = [System.IO.File]::ReadAllBytes($file)
        
        # Check for UTF-8 BOM (EF BB BF)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            Write-Host "  BOM detected, removing..." -ForegroundColor Yellow
            
            # Remove first 3 bytes (BOM)
            $newBytes = $bytes[3..($bytes.Length-1)]
            
            # Write back without BOM
            [System.IO.File]::WriteAllBytes($file, $newBytes)
            Write-Host "  BOM removed successfully" -ForegroundColor Green
        } else {
            Write-Host "  No BOM found" -ForegroundColor Gray
        }
    } else {
        Write-Host "File not found: $file" -ForegroundColor Red
    }
}

Write-Host "`nDone! Manifests cleaned." -ForegroundColor Green
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDiP0BgKTiVj+KM
# W0iViftqJTqniGdvEHxWGtdIfWWUoaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIL2f+msniaKei4iyNR2gRZ1a
# UPLV7tsRFD8ojym+UIuWMA0GCSqGSIb3DQEBAQUABIIBAJl3NXqNlO3K8p4l8rW1
# ZWCWE37KycYXv9oPyZwYPEO58c2sWfEy9zWMuCP/C5mWhJKmrbaZOM2j3SVQ0Pdy
# RcOG+APj25jvN9DMPEKtmIVxMZV4UvPcAq+EAMX9ZVXd2rlvlPDLUNW3Gjt3XUDs
# NuftboAdQGJtJDU2WwpvVsAUY1/+BNajEe42QdjnL/aDDtbP0uDLE651zEMnuXPx
# IEiPK+GcTeGdIZB9i+mN6mHj0DVBlj2oz8iG12X32+/W2rZwUhonJjJR8UU78oFu
# rTpfH/oxRZcfWv5azJgo/e06n5t0+7aVQl2dBvprd9rxwD+2DPgAVpoIA4q74np1
# hSU=
# SIG # End signature block
