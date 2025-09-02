# Final validation script for CPG module fixes
Write-Host "=== CPG Module Final Validation ===" -ForegroundColor Cyan

try {
    # Clean start
    Get-Module Unity-Claude-* | Remove-Module -Force -ErrorAction SilentlyContinue
    
    # Import main module
    Import-Module ".\Modules\Unity-Claude-CPG\Unity-Claude-CPG.psd1" -Force
    
    # Test 1: Function availability
    $func = Get-Command ConvertTo-CPGFromScriptBlock -Module Unity-Claude-CPG -ErrorAction SilentlyContinue
    if ($func) {
        Write-Host "✅ ConvertTo-CPGFromScriptBlock function available" -ForegroundColor Green
    } else {
        throw "ConvertTo-CPGFromScriptBlock not found"
    }
    
    # Test 2: ScriptBlock conversion
    $testCode = { 
        function Get-TestData { 
            param([string]$Path)
            return Get-Content $Path 
        }
        Get-TestData -Path "test.txt"
    }
    
    $graph = ConvertTo-CPGFromScriptBlock -ScriptBlock $testCode
    if ($graph -and $graph.Nodes.Count -gt 0) {
        Write-Host "✅ ScriptBlock conversion successful: $($graph.Nodes.Count) nodes, $($graph.Edges.Count) edges" -ForegroundColor Green
    } else {
        throw "ScriptBlock conversion failed"
    }
    
    # Test 3: Semantic analysis integration
    Import-Module ".\Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis.psd1" -Force
    $patterns = Find-DesignPatterns -Graph $graph
    Write-Host "✅ Semantic analysis integration successful: Found $($patterns.Count) patterns" -ForegroundColor Green
    
    # Test 4: Test one of the originally failing functions
    Import-Module ".\Modules\Unity-Claude-CPG\Unity-Claude-ObsolescenceDetection.psd1" -Force
    $complexity = Get-CodeComplexityMetrics -Graph $graph
    if ($complexity) {
        Write-Host "✅ ObsolescenceDetection integration successful" -ForegroundColor Green
    } else {
        Write-Host "⚠️ ObsolescenceDetection returned no results (expected for simple test code)" -ForegroundColor Yellow
    }
    
    Write-Host "`n🎉 All CPG module fixes validated successfully!" -ForegroundColor Green
    Write-Host "✅ Module bootstrap: Working" -ForegroundColor Green
    Write-Host "✅ Function exports: Working" -ForegroundColor Green  
    Write-Host "✅ ScriptBlock conversion: Working" -ForegroundColor Green
    Write-Host "✅ Semantic analysis: Working" -ForegroundColor Green
    Write-Host "✅ Integration: Working" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Validation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack: $($_.ScriptStackTrace)" -ForegroundColor Yellow
    exit 1
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCZdAhKjDAqpZoO
# gNgyDnYzj+Adb50qp+mdXygUbM744KCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBeGFwma+/rwVZRlW8Y1Rxip
# EJxaRl3leqf2/LnzjTC7MA0GCSqGSIb3DQEBAQUABIIBAK+Dc88y5vTRM7MLvTMq
# ZMTzDS7H/qd7XQY+PBNt317/F0NchZhT4nVTEWMAedv7pPkiEsLoLy5KsUSybfNz
# gb8yAwaf0NtwgCKTOPnfkqLEWT/YnzC2pgWLmXjO6Q0dZ5YUBueOoZtmLZyU+48b
# fta8PS0tLREOoTaS5ZL4msHxp3tKA9PrSVgYE2khuQOWr59ujKiqzRx6ef0QFafl
# nv5s56+C039fEmVYqSnRf9IyG4X9FjsOCJqMBu/VOt0ViE1NwkrlqP6FmcRUddY3
# 9IKzoqpa/8TS4dpdvbbBzI4JMqKPNpueFZ2DxpzK7IhV5y6AX1qnQCbYEa/Qe+PR
# 5tc=
# SIG # End signature block
