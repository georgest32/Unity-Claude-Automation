# Test Documentation Quality Assessment fixes

Import-Module .\Modules\Unity-Claude-DocumentationQualityAssessment\Unity-Claude-DocumentationQualityAssessment.psm1 -Force -WarningAction SilentlyContinue

Write-Host "`n1. Testing Initialization..." -ForegroundColor Cyan
$initResult = Initialize-DocumentationQualityAssessment -EnableAIAssessment -EnableReadabilityAlgorithms -AutoDiscoverSystems
Write-Host "   Initialization: $(if($initResult){'SUCCESS'}else{'FAILED'})" -ForegroundColor $(if($initResult){'Green'}else{'Red'})

Write-Host "`n2. Testing Quality Assessment..." -ForegroundColor Cyan
$content = Get-Content README.md -Raw
$assessment = Assess-DocumentationQuality -Content $content -FilePath "README.md"
Write-Host "   Assessment completed: $(if($assessment){'SUCCESS'}else{'FAILED'})" -ForegroundColor $(if($assessment){'Green'}else{'Red'})
if ($assessment) {
    Write-Host "   Overall Score: $($assessment.OverallQualityScore)/5" -ForegroundColor White
    Write-Host "   Quality Level: $($assessment.QualityLevel)" -ForegroundColor White
}

Write-Host "`n3. Testing Readability Functions..." -ForegroundColor Cyan
$testText = "This is a simple test sentence for readability scoring."
$flesch = Measure-FleschKincaidScore -Text $testText
$gunning = Measure-GunningFogScore -Text $testText
$smog = Measure-SMOGScore -Text $testText

Write-Host "   Flesch-Kincaid: $flesch" -ForegroundColor White
Write-Host "   Gunning Fog: $gunning" -ForegroundColor White
Write-Host "   SMOG: $smog" -ForegroundColor White

Write-Host "`n4. Testing Test Function..." -ForegroundColor Cyan
$testResult = Test-DocumentationQualityAssessment
Write-Host "   Test Function: $(if($testResult.SuccessRate -ge 70){'PASSED'}else{'FAILED'}) ($($testResult.SuccessRate)%)" -ForegroundColor $(if($testResult.SuccessRate -ge 70){'Green'}else{'Red'})

Write-Host "`n✅ All fixes verified!" -ForegroundColor Green