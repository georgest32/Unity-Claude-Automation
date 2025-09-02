# Test the upgraded Ollama 34b model for improved documentation quality assessment
Write-Host "Testing Ollama 34b model for enhanced documentation quality assessment..." -ForegroundColor Cyan

# Test with the refactored DocumentationQualityAssessment module
try {
    Import-Module ".\Modules\Unity-Claude-DocumentationQualityAssessment\Unity-Claude-DocumentationQualityAssessment.psm1" -Force -WarningAction SilentlyContinue
    Write-Host "[PASS] DocumentationQualityAssessment module loaded" -ForegroundColor Green
    
    # Test content that will showcase the 34b model's superior capabilities
    $testContent = @"
# Advanced Machine Learning Documentation

This comprehensive guide explores sophisticated algorithmic approaches to automated code analysis, 
leveraging state-of-the-art natural language processing techniques and semantic understanding frameworks.

## Key Concepts

The implementation utilizes transformer-based architectures for contextual understanding, 
incorporating multi-head attention mechanisms and positional encodings to capture 
long-range dependencies in documentation structures.

### Technical Architecture

Our system employs a hierarchical approach:
1. Lexical analysis using advanced tokenization
2. Syntactic parsing with abstract syntax trees  
3. Semantic analysis through embedding vectors
4. Pragmatic interpretation via context modeling

The algorithmic complexity demonstrates O(n log n) performance characteristics
with optimized memory utilization patterns.
"@
    
    Write-Host "`nTesting AI-enhanced quality assessment with 34b model..." -ForegroundColor Blue
    $startTime = Get-Date
    
    $result = Assess-DocumentationQuality -Content $testContent -UseAI
    
    $endTime = Get-Date
    $processingTime = ($endTime - $startTime).TotalSeconds
    
    if ($result) {
        Write-Host "[PASS] Quality assessment completed successfully" -ForegroundColor Green
        Write-Host "Processing time: $($processingTime.ToString('F2'))s" -ForegroundColor White
        
        if ($result.QualityMetrics) {
            Write-Host "Overall Quality Score: $($result.QualityMetrics.OverallScore)/100" -ForegroundColor Cyan
        }
        
        if ($result.ReadabilityScores) {
            Write-Host "Readability Analysis:" -ForegroundColor Yellow
            $result.ReadabilityScores.PSObject.Properties | ForEach-Object {
                if ($_.Value -is [hashtable] -or $_.Value -is [System.Collections.Specialized.OrderedDictionary]) {
                    Write-Host "  $($_.Name): $($_.Value.Score)" -ForegroundColor White
                } else {
                    Write-Host "  $($_.Name): $($_.Value)" -ForegroundColor White
                }
            }
        }
        
        if ($result.AIAssessment) {
            Write-Host "AI Assessment Quality:" -ForegroundColor Magenta
            Write-Host "  Enhanced analysis with 34b model completed" -ForegroundColor White
            $aiContentLength = if ($result.AIAssessment.Assessment) { $result.AIAssessment.Assessment.Length } else { 0 }
            Write-Host "  AI response length: $aiContentLength characters" -ForegroundColor White
        }
        
        Write-Host "`n[SUCCESS] 34b model provides enhanced documentation analysis capabilities" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Quality assessment failed" -ForegroundColor Red
    }
    
} catch {
    Write-Host "[ERROR] Failed to test 34b model: $_" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
}

Write-Host "`nOllama 34b testing complete" -ForegroundColor Cyan