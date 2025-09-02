# Test the refactored DocumentationQualityAssessment module components
Write-Host 'Testing refactored DocumentationQualityAssessment module...' -ForegroundColor Cyan

# Test each component individually
$componentsDir = '.\Modules\Unity-Claude-DocumentationQualityAssessment\Components'
$components = @('SystemIntegration', 'ReadabilityAlgorithms', 'AIAssessment', 'ContentAnalysis')

foreach ($component in $components) {
    $componentPath = "$componentsDir\$component.psm1"
    Write-Host "Testing $component component..." -ForegroundColor Yellow
    
    if (-not (Test-Path $componentPath)) {
        Write-Host "  [ERROR] Component file not found: $componentPath" -ForegroundColor Red
        continue
    }
    
    try {
        $errors = $null
        $tokens = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $componentPath,
            [ref]$tokens,
            [ref]$errors
        )
        
        if ($errors.Count -eq 0) {
            Write-Host "  [PASS] $component parses successfully" -ForegroundColor Green
            try {
                Import-Module $componentPath -Force -ErrorAction Stop
                Write-Host "  [PASS] $component loads successfully" -ForegroundColor Green
            } catch {
                Write-Host "  [FAIL] $component failed to load`: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "  [FAIL] $component has $($errors.Count) parse errors:" -ForegroundColor Red
            $errors | ForEach-Object {
                Write-Host "    Line $($_.Extent.StartLineNumber): $($_.Message)" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "  [ERROR] Error testing $component`: $_" -ForegroundColor Red
    }
}

Write-Host "`nComponent testing complete" -ForegroundColor Cyan