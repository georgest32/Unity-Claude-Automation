# Debug Flesch-Kincaid test in detail
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

# Simulate the cleaning logic
Write-Host "Original text length: $($testContent.Length)"

# Clean text (preserve periods, exclamation marks, and question marks for sentence detection)
# Remove markdown headers but keep the text
$cleanText = $testContent -replace '^#{1,6}\s+', '' -replace '\n#{1,6}\s+', '. '
Write-Host "After removing headers: $cleanText"
Write-Host ""

# Replace newlines with spaces
$cleanText = $cleanText -replace '\r?\n', ' '
# Clean up extra whitespace
$cleanText = $cleanText -replace '\s+', ' '

Write-Host "Cleaned text: $cleanText"
Write-Host ""

# Split into words and sentences
$words = $cleanText -split '\s+' | Where-Object { $_ -match '\w' }
$sentences = $cleanText -split '[.!?]+' | Where-Object { $_.Trim() -match '\w' }

Write-Host "Words count: $($words.Count)"
Write-Host "First 10 words: $($words[0..9] -join ', ')"
Write-Host ""
Write-Host "Sentences count: $($sentences.Count)"
Write-Host "Sentences:"
$sentences | ForEach-Object { Write-Host "  - $_" }

if ($words.Count -eq 0 -or $sentences.Count -eq 0) {
    Write-Host "ERROR: No words or sentences detected!"
} else {
    Write-Host ""
    Write-Host "Calculating Flesch-Kincaid score..."
    Write-Host "Words per sentence: $($words.Count / $sentences.Count)"
}