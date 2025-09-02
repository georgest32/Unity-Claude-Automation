# Quick diagnostic test for ParallelProcessor refactored module

Write-Host "=== Quick ParallelProcessor Diagnostic Test ===" -ForegroundColor Cyan

try {
    Write-Host "1. Cleaning existing modules..." -ForegroundColor Yellow
    Get-Module Unity-Claude-ParallelProcessor* | Remove-Module -Force -ErrorAction SilentlyContinue
    
    Write-Host "2. Importing refactored module..." -ForegroundColor Yellow
    Import-Module ".\Modules\Unity-Claude-ParallelProcessor\Unity-Claude-ParallelProcessor.psd1" -Force -Verbose
    
    Write-Host "3. Testing module info..." -ForegroundColor Yellow
    $moduleInfo = Get-UnityClaudeParallelProcessorInfo
    Write-Host "Module Version: $($moduleInfo.Version)" -ForegroundColor Green
    
    Write-Host "4. Testing helper functions..." -ForegroundColor Yellow
    
    # Test Get-OptimalThreadCount
    if (Get-Command Get-OptimalThreadCount -ErrorAction SilentlyContinue) {
        $threads = Get-OptimalThreadCount -WorkloadType CPU
        Write-Host "Get-OptimalThreadCount: AVAILABLE - Result: $threads" -ForegroundColor Green
    } else {
        Write-Host "Get-OptimalThreadCount: NOT AVAILABLE" -ForegroundColor Red
    }
    
    # Test New-RunspacePoolManager
    if (Get-Command New-RunspacePoolManager -ErrorAction SilentlyContinue) {
        Write-Host "New-RunspacePoolManager: AVAILABLE" -ForegroundColor Green
    } else {
        Write-Host "New-RunspacePoolManager: NOT AVAILABLE" -ForegroundColor Red
    }
    
    # Test New-StatisticsTracker
    if (Get-Command New-StatisticsTracker -ErrorAction SilentlyContinue) {
        Write-Host "New-StatisticsTracker: AVAILABLE" -ForegroundColor Green
    } else {
        Write-Host "New-StatisticsTracker: NOT AVAILABLE" -ForegroundColor Red
    }
    
    Write-Host "5. Testing processor creation..." -ForegroundColor Yellow
    $processor = New-ParallelProcessor -MaxThreads 2
    if ($processor) {
        Write-Host "New-ParallelProcessor: SUCCESS - ID: $($processor.ProcessorId)" -ForegroundColor Green
        
        Write-Host "6. Testing processor cleanup..." -ForegroundColor Yellow
        Stop-ParallelProcessor -Processor $processor
        Write-Host "Stop-ParallelProcessor: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "New-ParallelProcessor: FAILED" -ForegroundColor Red
    }
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
}

Write-Host "=== Diagnostic Test Complete ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAsQ8WbXtw7K5uI
# aOrobxSFZ+H42LMVAm4EAZ5HF24Zt6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDbU6KUlSdGEM6UtfPTN5DKH
# mpwYIgkhpQaZ84a1ycJ2MA0GCSqGSIb3DQEBAQUABIIBACvcM60/VZ/VO6w7HSj8
# iQdJLl8SkiMWos21bg7Hln0K+CPwRP5OVNGLixHMPpLheZ5yBEoVFiEMHDxyNKHN
# E0O8Z+PGuAlajHmgnD6ByQXz+lWEJG4dk3aXTjh0k6VA5Svf71SCQvVSSeI7zhde
# xT9MTCaj+bTItwTpr1xBkQCJFn0AOZQMi/9zRxd1VtJMK9G04XhhGeas9LPLnB+c
# eFZRSDT5kDtC6P5Zqcbu1JGQGVyOpSSBjXCtyq2IWqhkzkovRCzflOZ+I6IEkBtV
# 6ScARSSB77fYceoUq/SycZ9b/HVKN1Hd2Ajb6TbJIkQxxSfIpD5wb8m3hL/K9LlJ
# tdI=
# SIG # End signature block
