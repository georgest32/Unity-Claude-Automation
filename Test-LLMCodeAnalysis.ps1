# Test LLM Code Analysis
Import-Module "$PSScriptRoot\Modules\Unity-Claude-LLM\Unity-Claude-LLM.psd1" -Force

# Test with an existing module for quality analysis
$testFile = "$PSScriptRoot\Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Helpers.psm1"

if (Test-Path $testFile) {
    Write-Host "Performing code analysis on: $testFile" -ForegroundColor Cyan
    
    # Test multiple analysis types
    $analysisTypes = @('Quality', 'Security', 'Performance')
    
    foreach ($analysisType in $analysisTypes) {
        Write-Host "--- $analysisType Analysis ---" -ForegroundColor Yellow
        
        $code = Get-Content $testFile -Raw
        $prompt = New-CodeAnalysisPrompt -AnalysisType $analysisType -Code $code -FocusAreas @('PowerShell best practices', 'Module design')
        
        $result = Invoke-OllamaGenerate -Prompt $prompt -MaxTokens 1024
        
        if ($result.Success) {
            Write-Host "Analysis completed successfully!" -ForegroundColor Green
            Write-Host $result.Response
            
            # Save analysis
            $outputFile = "$PSScriptRoot\CodeAnalysis-$analysisType-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
            $result.Response | Out-File -FilePath $outputFile -Encoding UTF8
            Write-Host "Analysis saved to: $outputFile" -ForegroundColor Gray
        } else {
            Write-Host "Analysis failed: $($result.Error)" -ForegroundColor Red
        }
        
        Write-Host ""
    }
} else {
    Write-Host "Test file not found: $testFile" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD5QQKHl0W6Mdbv
# hCML0EglmWVJx7VjTV3gz4cHYX0SZqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIO0nQlHtbrd1VUBWumxffC8J
# jPUM8RlaYgx+Zv5R4OrWMA0GCSqGSIb3DQEBAQUABIIBAFGf8fXEo+uTWMMdQSIE
# 2LcdiKGTPI6ILMvp8FnmWjx4h32TbmmfwWVursWBEHS1zXWsM5Nf0rOVUU03SKAC
# qaRVRb+YJY0ArNWfv0igIKhaVgU//RX3tejeE54+4oBcWr77f4lmkzhJDeji0o90
# zPcG3GScRuIrC/8VVygSkXzmlkB9E2yaMTjoQ9GQft/GGecnRzmzjFbJRs4aUAWZ
# ytDB3rsJMx5ILQzFODfVi/VVa+OOF/IjrX3DCetW+1i+fCrQd7ueLQiyo6AOQBBM
# ryviYXf2/t8MZOiulD305Im2c8C3+98p4oYoCHd0gJDJv+LDKCHPG+jPAtlCkVir
# YO8=
# SIG # End signature block
