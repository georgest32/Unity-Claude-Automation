# Direct ESLint test
Write-Host "Testing ESLint directly..." -ForegroundColor Cyan

# Find eslint.cmd
$eslintCmd = Get-Command "eslint.cmd" -ErrorAction SilentlyContinue
if (-not $eslintCmd) {
    Write-Host "[ERROR] eslint.cmd not found" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Found eslint.cmd at: $($eslintCmd.Source)" -ForegroundColor Green

# Create test file
$testFile = "$env:TEMP\test-eslint.js"
@'
const x = 1;
console.log("Hello");
const unused = 42;
'@ | Out-File -FilePath $testFile -Encoding UTF8

Write-Host "[INFO] Created test file: $testFile" -ForegroundColor Yellow

# Run ESLint with timeout
try {
    Write-Host "[INFO] Running ESLint..." -ForegroundColor Yellow
    
    $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c eslint.cmd --format json `"$testFile`"" -NoNewWindow -PassThru -RedirectStandardOutput "$env:TEMP\eslint-out.txt" -RedirectStandardError "$env:TEMP\eslint-err.txt"
    
    # Wait max 5 seconds
    $process | Wait-Process -Timeout 5 -ErrorAction SilentlyContinue
    
    if (-not $process.HasExited) {
        Write-Host "[WARNING] ESLint is taking too long, stopping..." -ForegroundColor Yellow
        $process | Stop-Process -Force
        Write-Host "[ERROR] ESLint timed out" -ForegroundColor Red
    } else {
        Write-Host "[OK] ESLint completed with exit code: $($process.ExitCode)" -ForegroundColor Green
        
        # Read output
        if (Test-Path "$env:TEMP\eslint-out.txt") {
            $output = Get-Content "$env:TEMP\eslint-out.txt" -Raw
            if ($output) {
                Write-Host "[INFO] ESLint output (first 500 chars):" -ForegroundColor Yellow
                Write-Host ($output.Substring(0, [Math]::Min(500, $output.Length))) -ForegroundColor Gray
            }
        }
        
        if (Test-Path "$env:TEMP\eslint-err.txt") {
            $errors = Get-Content "$env:TEMP\eslint-err.txt" -Raw
            if ($errors) {
                Write-Host "[WARNING] ESLint errors:" -ForegroundColor Yellow
                Write-Host $errors -ForegroundColor Red
            }
        }
    }
} catch {
    Write-Host "[ERROR] Failed to run ESLint: $_" -ForegroundColor Red
} finally {
    # Cleanup
    Remove-Item $testFile -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:TEMP\eslint-out.txt" -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:TEMP\eslint-err.txt" -Force -ErrorAction SilentlyContinue
    Write-Host "[INFO] Cleaned up test files" -ForegroundColor Gray
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCwWNYuMJ5kay9E
# VSv09Hpuu0lCg9HEBR6qbvh5T5cQaqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMdSOwCZ7CfowbF51GGD/PM5
# iZieX6GwQaXgwxT5h+dpMA0GCSqGSIb3DQEBAQUABIIBAHmmTCU64kIp3gFI3K8a
# 7TL/uILx3fLH+96TMgfgx0ukJt19rIWoG2K1ry5/e+oqE2+uJ0ZOfKKd4sEGX0Sq
# v2sTEsckd3FgzufUMyDZ6Q/vyCfq1rPHyKccf0DsvA2C+Z1lgg6qNo36uAQe0A6I
# DIx4QuwcocWfRlFivl/9tgyzypbhFkIg0IZemqVCHHHOYhkmzUAX8mWTTS7uRXIX
# FcKCdI4wotnJH2Ytez8AZugrMD/dCXp6mi7Anpc4HVBCTbgQ+1Xk2fwIF1dBj/jC
# 3nWsKmQJf/D494Jf1L7Ijaydzajt49XFMGSEwkLWhFcuzUt+Gw4mcR+vdTiJ57lj
# 2qU=
# SIG # End signature block
