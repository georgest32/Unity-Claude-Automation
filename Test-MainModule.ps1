# Test the main refactored DocumentationQualityAssessment module
Write-Host 'Testing main refactored DocumentationQualityAssessment module...' -ForegroundColor Cyan
$mainModulePath = '.\Modules\Unity-Claude-DocumentationQualityAssessment\Unity-Claude-DocumentationQualityAssessment.psm1'

try {
    $errors = $null
    $tokens = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $mainModulePath,
        [ref]$tokens,
        [ref]$errors
    )
    
    if ($errors.Count -eq 0) {
        Write-Host '[PASS] Main module parses successfully' -ForegroundColor Green
        try {
            Import-Module $mainModulePath -Force -ErrorAction Stop
            Write-Host '[PASS] Main module loads successfully' -ForegroundColor Green
            
            # Test basic functionality
            Write-Host 'Testing basic functionality...' -ForegroundColor Blue
            $testContent = "This is a comprehensive test document for quality assessment analysis."
            $result = Assess-DocumentationQuality -Content $testContent
            if ($result) {
                Write-Host '[PASS] Basic functionality test passed' -ForegroundColor Green
                Write-Host "Overall quality score: $($result.QualityMetrics.OverallScore)" -ForegroundColor White
            } else {
                Write-Host '[FAIL] Basic functionality test failed' -ForegroundColor Red
            }
        } catch {
            Write-Host '[FAIL] Main module failed to load' -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Yellow
        }
    } else {
        Write-Host '[FAIL] Main module has parse errors' -ForegroundColor Red
        $errors | ForEach-Object {
            Write-Host "  Line $($_.Extent.StartLineNumber): $($_.Message)" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host '[ERROR] Error testing main module' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
}

Write-Host "`nMain module testing complete" -ForegroundColor Cyan