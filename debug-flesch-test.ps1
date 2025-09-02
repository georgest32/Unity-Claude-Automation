# Debug why Flesch-Kincaid test fails

$testContent = @"
# Unity Claude Automation Documentation

## Overview
This system provides comprehensive automation capabilities for Unity development workflows. 
The implementation uses advanced artificial intelligence to enhance productivity and code quality.
Our sophisticated algorithms analyze code patterns and provide intelligent suggestions for improvement.

## Technical Implementation
The system utilizes multiple interconnected modules to facilitate seamless integration.
Subsequently, the framework implements various optimization strategies to enhance performance.
Approximately 95% of common development tasks can be automated using this system.

## Usage Examples
To commence utilizing the system, initialize the primary orchestration module.
The system will endeavor to ascertain the optimal configuration for your environment.
"@

Import-Module .\Modules\Unity-Claude-DocumentationQualityAssessment\Unity-Claude-DocumentationQualityAssessment.psm1 -Force -WarningAction SilentlyContinue

Write-Host "Testing with markdown content:"
$score = Measure-FleschKincaidScore -Text $testContent
Write-Host "Score: $score"
Write-Host "Test condition (score > 0 and score <= 100): $($score -gt 0 -and $score -le 100)"
Write-Host ""

# Test what the test actually does
if (Get-Command Measure-FleschKincaidScore -ErrorAction SilentlyContinue) {
    Write-Host "Command exists: TRUE"
    $score = Measure-FleschKincaidScore -Text $testContent
    Write-Host "  Flesch-Kincaid Score: $score"
    $result = $score -gt 0 -and $score -le 100
    Write-Host "  Test result: $result"
}

Write-Host ""
Write-Host "Testing Calculate-ComprehensiveReadabilityScores:"
$scores = Calculate-ComprehensiveReadabilityScores -Content $testContent
$scores | Format-List