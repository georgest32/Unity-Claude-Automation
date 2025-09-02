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
$score = Measure-FleschKincaidScore -Text $testContent
Write-Host "Score: $score"
Write-Host "Test would pass: $($score -gt 0 -and $score -le 100)"