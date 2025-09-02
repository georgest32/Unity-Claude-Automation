# Test Enhanced Documentation Pipeline
Import-Module "$PSScriptRoot\Modules\Unity-Claude-LLM\Unity-Claude-LLM.psd1" -Force
Import-Module "$PSScriptRoot\Modules\Unity-Claude-LLM\Unity-Claude-DocumentationPipeline.psm1" -Force

# Test with a PowerShell module
$sourceFile = "$PSScriptRoot\Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis-Patterns.psm1"
$outputDir = "$PSScriptRoot\docs\generated\enhanced-pipeline"

if (Test-Path $sourceFile) {
    Write-Host "Testing Enhanced Documentation Pipeline" -ForegroundColor Cyan
    Write-Host "Source: $sourceFile" -ForegroundColor Gray
    Write-Host "Output: $outputDir" -ForegroundColor Gray
    Write-Host ""
    
    # Create output directory
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    $outputFile = Join-Path $outputDir "SemanticAnalysis-Patterns-Enhanced.md"
    
    # Run the enhanced documentation pipeline
    $pipeline = New-EnhancedDocumentationPipeline -SourcePath $sourceFile -OutputPath $outputFile -Language 'PowerShell' -DocumentationType 'Module' -IncludeSemanticAnalysis -IncludeCodeAnalysis -IncludeArchitectureInfo -GenerateIndex
    
    if ($pipeline.Success) {
        Write-Host "Pipeline completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Results Summary:" -ForegroundColor Yellow
        Write-Host "- Duration: $($pipeline.Duration.TotalSeconds) seconds"
        Write-Host "- Steps completed: $($pipeline.Steps.Count)"
        
        if ($pipeline.Results.SemanticAnalysis) {
            $semantic = $pipeline.Results.SemanticAnalysis
            Write-Host "- Semantic Analysis: $($semantic.NodeCount) nodes analyzed"
            if ($semantic.Patterns) {
                Write-Host "  - Design patterns: $($semantic.Patterns.Count) detected"
            }
            if ($semantic.Purpose) {
                Write-Host "  - Purpose classifications: $($semantic.Purpose.Count) identified"
            }
        }
        
        if ($pipeline.Results.ArchitectureAnalysis) {
            $arch = $pipeline.Results.ArchitectureAnalysis
            Write-Host "- Architecture Analysis: $($arch.Architecture) style, $($arch.Complexity) complexity"
        }
        
        if ($pipeline.Results.Documentation) {
            Write-Host "- Documentation generated with LLM model: $($pipeline.Results.Documentation.Model)"
            Write-Host "- LLM processing time: $($pipeline.Results.Documentation.Metrics.TotalDurationMs) ms"
        }
        
        if ($pipeline.Results.IndexPath) {
            Write-Host "- Index file: $($pipeline.Results.IndexPath)"
        }
        
        Write-Host ""
        Write-Host "Files created:" -ForegroundColor Green
        Get-ChildItem $outputDir | ForEach-Object {
            Write-Host "  - $($_.Name)" -ForegroundColor Gray
        }
    } else {
        Write-Host "Pipeline failed!" -ForegroundColor Red
        foreach ($error in $pipeline.Errors) {
            Write-Host "  Error: $error" -ForegroundColor Red
        }
    }
    
    return $pipeline
} else {
    Write-Host "Source file not found: $sourceFile" -ForegroundColor Red
    return $null
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCkSPh+NuxUHyB5
# Q4QzbdVwqFu3E/0JjOcJ6qfh1Yqtb6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEII8xdw8SZbjgz6cNjUtyEX1t
# m7zEREvI3+0xN/k0+3KaMA0GCSqGSIb3DQEBAQUABIIBAHfiv65yuibDwH4x50qA
# hiT++dm+Usz76LmROB2vqkw4Fqy2IC2SWlivG/sCSmaiNG7d6EfTyJ5SxtlN+t0h
# O+SeMCTJXnd/SBqGZpK089L5aQlz6wnUnNezzSa44EnxtmJasn+fCUqVIEkxUM0b
# XFiPFcOv+WpaA7IA3C1d5JCKeTNXwu56r7SHxGsGJ4aKs7gQkRyHSftCk4ym+G3s
# hrUQXTnZ3oIg23qko01otkkm9if84c1+AicBNkYg6ieyT4y+6Ykb/Aw7d3KotKGX
# +5k1R2ZRr7j5LY4BcW6bK0LLapldVxn7b79mIkIDvdCj18c/prZBQ53SSZp8b2cP
# EYE=
# SIG # End signature block
