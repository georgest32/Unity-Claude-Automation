# Extract and test a function from the module
$content = Get-Content 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psm1'

$startLine = -1
$endLine = -1
$braceCount = 0

for ($i = 0; $i -lt $content.Count; $i++) {
    if ($content[$i] -match '^function New-AutonomousPrompt') {
        $startLine = $i
        $braceCount = 0
        
        # Find the end of the function
        for ($j = $i; $j -lt $content.Count; $j++) {
            $line = $content[$j]
            $braceCount += ([regex]::Matches($line, '\{').Count)
            $braceCount -= ([regex]::Matches($line, '\}').Count)
            
            if ($braceCount -eq 0 -and $j -gt $i) {
                $endLine = $j
                break
            }
        }
        break
    }
}

if ($startLine -ge 0 -and $endLine -ge 0) {
    Write-Host "Found function from line $($startLine+1) to $($endLine+1)" -ForegroundColor Green
    
    # Extract function
    $functionCode = $content[$startLine..$endLine] -join "`n"
    
    Write-Host "`nFirst 200 characters of function:" -ForegroundColor Cyan
    Write-Host $functionCode.Substring(0, [Math]::Min(200, $functionCode.Length))
    
    Write-Host "`nTrying to define function..." -ForegroundColor Yellow
    try {
        Invoke-Expression $functionCode
        
        if (Get-Command New-AutonomousPrompt -ErrorAction SilentlyContinue) {
            Write-Host "SUCCESS: Function defined!" -ForegroundColor Green
            
            # Test it
            Write-Host "`nTesting function with simple parameters..." -ForegroundColor Cyan
            $result = New-AutonomousPrompt -RecommendationType "TEST" -ActionDetails "test.ps1"
            Write-Host "Result length: $($result.Length) characters" -ForegroundColor Green
        } else {
            Write-Host "Function not found after definition" -ForegroundColor Red
        }
    } catch {
        Write-Host "ERROR defining function: $_" -ForegroundColor Red
    }
} else {
    Write-Host "Could not find function in file" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCwEFhE7JGHocrp
# 1IaQiQt8BkkADqPGhXmU8+fI2ENjpqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHlHITGicUI2Pp2MajJHVxqN
# UMr6yf4TJFH4axLnqR7lMA0GCSqGSIb3DQEBAQUABIIBAG7ARMXWEZtVu0MwL1st
# cR9EbcfVivHGovifeCqquDW2RbUCsmesKx6NUUGvN4nk36VzI3xG83s98oiWweA4
# B1hGJ7a6cp4Fyx32Hy3WomhEk/xJa6pcnOn/w2Yb0S3fRcmEUzfrzZmhRoTGjwHo
# q/XUg3L8WcXr1f0JjXZD8fszUkOtetv23rY/xKkdnO/HpihjyJ8z4dEDy+ZU+1Cd
# 4Nm1rmDVLM/VafhK0da377NNE4vvkISnrvc88aN7IlxZAyweFUnPp9vbIRiJq8h5
# n998Y4cbcpItFCABR+CsIVncpM5V278wgn1bfuN3Tm7p/+DIPDZ/9PGnpQaBbMtS
# Yok=
# SIG # End signature block
