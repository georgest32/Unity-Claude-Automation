# Fix the here-string issue in DocumentationQualityAssessment module
# Replace problematic here-string with programmatically built string

$modulePath = ".\Modules\Unity-Claude-DocumentationQualityAssessment\Unity-Claude-DocumentationQualityAssessment.psm1"

# Read the current content
$content = Get-Content $modulePath -Raw

# Create the replacement string using concatenation to avoid here-string issues
$replacementCode = @'
        # Create AI quality assessment prompt (research-validated)
        $qualityPrompt = "Analyze this technical documentation for quality and provide detailed assessment:`n`n"
        $qualityPrompt += "CONTENT TO ASSESS:`n"
        $qualityPrompt += "$Content`n`n"
        $qualityPrompt += "ASSESSMENT CRITERIA:`n"
        $qualityPrompt += "1. Readability: Is the content clear and easy to understand?`n"
        $qualityPrompt += "2. Completeness: Does it cover all necessary information?`n"
        $qualityPrompt += "3. Accuracy: Is the technical information correct and current?`n"
        $qualityPrompt += "4. Structure: Is the content well-organized and logical?`n"
        $qualityPrompt += "5. Clarity: Are explanations clear and unambiguous?`n"
        $qualityPrompt += "6. Consistency: Is terminology and style consistent?`n"
        $qualityPrompt += "7. Usability: Can users easily find and apply the information?`n`n"
        $qualityPrompt += "Provide scores (1-5) for each criterion and specific improvement recommendations.`n`n"
        $qualityPrompt += "FORMAT:`n"
        $qualityPrompt += "Readability: score - brief assessment`n"
        $qualityPrompt += "Completeness: score - brief assessment`n"
        $qualityPrompt += "Accuracy: score - brief assessment`n"
        $qualityPrompt += "Structure: score - brief assessment`n"
        $qualityPrompt += "Clarity: score - brief assessment`n"
        $qualityPrompt += "Consistency: score - brief assessment`n"
        $qualityPrompt += "Usability: score - brief assessment`n`n"
        $qualityPrompt += "IMPROVEMENT RECOMMENDATIONS:`n"
        $qualityPrompt += "- specific suggestion 1`n"
        $qualityPrompt += "- specific suggestion 2`n"
        $qualityPrompt += "- specific suggestion 3`n`n"
        $qualityPrompt += "OVERALL ASSESSMENT: summary with overall score"
'@

# Find and replace the problematic section
$pattern = '(?s)\s+# Create AI quality assessment prompt.*?"@'
if ($content -match $pattern) {
    Write-Host "Found here-string section to replace" -ForegroundColor Yellow
    $newContent = $content -replace $pattern, $replacementCode
    
    # Write the fixed content back
    Set-Content -Path $modulePath -Value $newContent -Encoding UTF8
    Write-Host "Replaced here-string with concatenated string approach" -ForegroundColor Green
    
    # Test if the module can now be parsed
    $errors = $null
    $tokens = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $modulePath,
        [ref]$tokens,
        [ref]$errors
    )
    
    if ($errors.Count -eq 0) {
        Write-Host "Module now parses without errors!" -ForegroundColor Green
    } else {
        Write-Host "Still has $($errors.Count) parse errors:" -ForegroundColor Red
        $errors | ForEach-Object {
            Write-Host "  Line $($_.Extent.StartLineNumber): $($_.Message)" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "Could not find here-string pattern to replace" -ForegroundColor Red
}

Write-Host "`nTesting module loading..." -ForegroundColor Cyan
try {
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Host "Module loaded successfully!" -ForegroundColor Green
} catch {
    Write-Host "Module failed to load: $_" -ForegroundColor Red
}