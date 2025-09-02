# Test-ChangeIntelligence.ps1
# Test script for Unity-Claude Change Intelligence Module
# Validates intelligent change detection and classification

param(
    [switch]$Verbose,
    [switch]$TestAI
)

# Set verbose preference
if ($Verbose) {
    $VerbosePreference = "Continue"
}

# Import required modules
$changeIntelligencePath = Join-Path $PSScriptRoot "..\Modules\Unity-Claude-ChangeIntelligence"
$realTimeMonitoringPath = Join-Path $PSScriptRoot "..\Modules\Unity-Claude-RealTimeMonitoring"

Import-Module $changeIntelligencePath -Force
Import-Module $realTimeMonitoringPath -Force

Write-Host "`n===== Unity-Claude Change Intelligence Module Test =====" -ForegroundColor Cyan
Write-Host "Testing intelligent change detection and classification" -ForegroundColor Cyan
Write-Host "========================================================`n" -ForegroundColor Cyan

# Test results collection
$testResults = @{
    TotalTests = 0
    Passed = 0
    Failed = 0
    Details = @()
}

function Test-Functionality {
    param(
        [string]$TestName,
        [scriptblock]$TestScript
    )
    
    $testResults.TotalTests++
    Write-Host "Testing: $TestName" -NoNewline
    
    try {
        $result = & $TestScript
        if ($result) {
            Write-Host " [PASSED]" -ForegroundColor Green
            $testResults.Passed++
            $testResults.Details += @{
                Test = $TestName
                Result = "Passed"
                Details = $result
            }
        }
        else {
            Write-Host " [FAILED]" -ForegroundColor Red
            $testResults.Failed++
            $testResults.Details += @{
                Test = $TestName
                Result = "Failed"
                Details = "Test returned false"
            }
        }
    }
    catch {
        Write-Host " [ERROR]" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        $testResults.Failed++
        $testResults.Details += @{
            Test = $TestName
            Result = "Error"
            Details = $_.Exception.Message
        }
    }
}

# Create test files for classification
$testDir = Join-Path $PSScriptRoot "TestChangeIntelligence"
if (-not (Test-Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Test 1: Module Initialization
Test-Functionality "Module Initialization" {
    $result = Initialize-ChangeIntelligence -EnableAI:$TestAI
    
    if ($result) {
        $stats = Get-ChangeIntelligenceStatistics
        return ($null -ne $stats)
    }
    return $false
}

# Test 2: PowerShell File Classification
Test-Functionality "PowerShell File Classification" {
    # Create a test PowerShell file
    $testFile = Join-Path $testDir "TestModule.psm1"
    @"
function Test-Function {
    param([string]`$Name)
    Write-Host "Hello, `$Name"
}

Export-ModuleMember -Function Test-Function
"@ | Out-File -FilePath $testFile -Force
    
    $event = [PSCustomObject]@{
        Type = "Created"
        FullPath = $testFile
        Name = "TestModule.psm1"
        TimeStamp = Get-Date
    }
    
    $classification = Get-ChangeClassification -FileEvent $event
    
    # Clean up
    Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
    
    return ($classification.ChangeType -eq 'Behavioral' -and 
            $classification.ImpactSeverity -eq 'High')
}

# Test 3: Configuration File Classification
Test-Functionality "Configuration File Classification" {
    $testFile = Join-Path $testDir "config.json"
    @{
        Setting1 = "Value1"
        Setting2 = "Value2"
    } | ConvertTo-Json | Out-File -FilePath $testFile -Force
    
    $event = [PSCustomObject]@{
        Type = "Modified"
        FullPath = $testFile
        Name = "config.json"
        TimeStamp = Get-Date
    }
    
    $classification = Get-ChangeClassification -FileEvent $event
    
    # Clean up
    Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
    
    return ($classification.ChangeType -eq 'Configuration' -and 
            $classification.ImpactSeverity -eq 'Medium')
}

# Test 4: Documentation File Classification
Test-Functionality "Documentation File Classification" {
    $testFile = Join-Path $testDir "README.md"
    @"
# Test Documentation
This is a test documentation file.
"@ | Out-File -FilePath $testFile -Force
    
    $event = [PSCustomObject]@{
        Type = "Created"
        FullPath = $testFile
        Name = "README.md"
        TimeStamp = Get-Date
    }
    
    $classification = Get-ChangeClassification -FileEvent $event
    
    # Clean up
    Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
    
    return ($classification.ChangeType -eq 'Documentation' -and 
            $classification.ImpactSeverity -eq 'Minimal')
}

# Test 5: Test File Classification
Test-Functionality "Test File Classification" {
    $testFile = Join-Path $testDir "Module.Tests.ps1"
    @"
Describe 'Module Tests' {
    It 'Should pass' {
        `$true | Should -Be `$true
    }
}
"@ | Out-File -FilePath $testFile -Force
    
    $event = [PSCustomObject]@{
        Type = "Modified"
        FullPath = $testFile
        Name = "Module.Tests.ps1"
        TimeStamp = Get-Date
    }
    
    $classification = Get-ChangeClassification -FileEvent $event
    
    # Clean up
    Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
    
    return ($classification.ChangeType -eq 'Test' -and 
            $classification.ImpactSeverity -eq 'Low')
}

# Test 6: Security-Sensitive File Detection
Test-Functionality "Security-Sensitive File Detection" {
    $testFile = Join-Path $testDir "Security.ps1"
    @"
`$credential = Get-Credential
`$securePassword = ConvertTo-SecureString -String "P@ssw0rd" -AsPlainText -Force
`$token = "Bearer eyJhbGciOiJIUzI1NiIs..."
"@ | Out-File -FilePath $testFile -Force
    
    $event = [PSCustomObject]@{
        Type = "Created"
        FullPath = $testFile
        Name = "Security.ps1"
        TimeStamp = Get-Date
    }
    
    $classification = Get-ChangeClassification -FileEvent $event
    
    # Clean up
    Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
    
    return ($classification.ChangeType -eq 'Security' -and 
            $classification.ImpactSeverity -eq 'Critical')
}

# Test 7: Risk Level Calculation
Test-Functionality "Risk Level Calculation" {
    $testFile = Join-Path $testDir "HighRisk.ps1"
    @"
function Remove-Everything {
    Remove-Item -Path C:\* -Recurse -Force
}
"@ | Out-File -FilePath $testFile -Force
    
    $event = [PSCustomObject]@{
        Type = "Created"
        FullPath = $testFile
        Name = "HighRisk.ps1"
        TimeStamp = Get-Date
    }
    
    $classification = Get-ChangeClassification -FileEvent $event
    
    # Clean up
    Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
    
    return ($classification.RiskLevel -in @('High', 'VeryHigh'))
}

# Test 8: Impact Assessment
Test-Functionality "Impact Assessment" {
    $testFile = Join-Path $testDir "Module.psm1"
    "function Test-Impact { }" | Out-File -FilePath $testFile -Force
    
    $event = [PSCustomObject]@{
        Type = "Modified"
        FullPath = $testFile
        Name = "Module.psm1"
        TimeStamp = Get-Date
    }
    
    $classification = Get-ChangeClassification -FileEvent $event
    $assessment = Get-ImpactAssessment -Classification $classification -DependentModules @("Module1", "Module2")
    
    # Clean up
    Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
    
    return ($assessment.DirectImpact.Count -gt 0 -and 
            $assessment.RecommendedActions.Count -gt 0)
}

# Test 9: Change History Tracking
Test-Functionality "Change History Tracking" {
    # Create multiple test files to generate history
    $files = @()
    for ($i = 1; $i -le 3; $i++) {
        $testFile = Join-Path $testDir "History$i.ps1"
        "# Test file $i" | Out-File -FilePath $testFile -Force
        $files += $testFile
        
        $event = [PSCustomObject]@{
            Type = "Created"
            FullPath = $testFile
            Name = "History$i.ps1"
            TimeStamp = Get-Date
        }
        
        Get-ChangeClassification -FileEvent $event | Out-Null
    }
    
    $history = Get-ChangeHistory -Last 3
    
    # Clean up
    foreach ($file in $files) {
        Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
    }
    
    return ($history.Count -ge 3)
}

# Test 10: Cache Performance
Test-Functionality "Cache Performance" {
    $testFile = Join-Path $testDir "CacheTest.ps1"
    "# Cache test" | Out-File -FilePath $testFile -Force
    
    $event = [PSCustomObject]@{
        Type = "Modified"
        FullPath = $testFile
        Name = "CacheTest.ps1"
        TimeStamp = Get-Date
    }
    
    # First call - should cache
    Get-ChangeClassification -FileEvent $event | Out-Null
    
    # Second call - should hit cache
    Get-ChangeClassification -FileEvent $event | Out-Null
    
    $stats = Get-ChangeIntelligenceStatistics
    
    # Clean up
    Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
    
    return ($stats.CacheHits -gt 0)
}

# Test 11: AST Analysis
Test-Functionality "AST Analysis for PowerShell" {
    $testFile = Join-Path $testDir "ASTTest.ps1"
    @"
Import-Module TestModule
`$config = @{
    Setting1 = 'Value1'
    Option2 = 'Value2'
}

function Test-AST {
    param([string]`$Input)
    return `$Input.ToUpper()
}

Describe 'Test' {
    It 'Works' {
        Test-AST 'test' | Should -Be 'TEST'
    }
}
"@ | Out-File -FilePath $testFile -Force
    
    $event = [PSCustomObject]@{
        Type = "Created"
        FullPath = $testFile
        Name = "ASTTest.ps1"
        TimeStamp = Get-Date
    }
    
    $classification = Get-ChangeClassification -FileEvent $event
    
    # Clean up
    Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
    
    # Should detect multiple change types
    return ($classification.Details.Count -gt 2 -and 
            $classification.Confidence -gt 0.5)
}

# Test 12: AI Enhancement (if enabled)
if ($TestAI) {
    Test-Functionality "AI-Enhanced Classification" {
        $testFile = Join-Path $testDir "AITest.ps1"
        @"
function Complex-Function {
    # This function has complex logic that could benefit from AI analysis
    param([hashtable]`$Data)
    
    foreach (`$key in `$Data.Keys) {
        if (`$Data[`$key] -match 'pattern') {
            Invoke-Command -ScriptBlock { }
        }
    }
}
"@ | Out-File -FilePath $testFile -Force
        
        $event = [PSCustomObject]@{
            Type = "Modified"
            FullPath = $testFile
            Name = "AITest.ps1"
            TimeStamp = Get-Date
        }
        
        $classification = Get-ChangeClassification -FileEvent $event -UseAI
        
        # Clean up
        Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
        
        # Check if AI assessment was added
        $aiAssessment = $classification.Details | Where-Object { $_ -match 'AI Assessment' }
        return ($null -ne $aiAssessment)
    }
}

# Clean up test directory
if (Test-Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Display test summary
Write-Host "`n===== Test Summary =====" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.TotalTests)" -ForegroundColor White
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor $(if ($testResults.Failed -eq 0) { "Green" } else { "Red" })

# Calculate success rate
if ($testResults.TotalTests -gt 0) {
    $successRate = [Math]::Round(($testResults.Passed / $testResults.TotalTests) * 100, 2)
    Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 95) { "Green" } elseif ($successRate -ge 80) { "Yellow" } else { "Red" })
}

# Get final statistics
$finalStats = Get-ChangeIntelligenceStatistics
Write-Host "`n===== Module Statistics =====" -ForegroundColor Cyan
Write-Host "Changes Analyzed: $($finalStats.ChangesAnalyzed)" -ForegroundColor White
Write-Host "Cache Hits: $($finalStats.CacheHits)" -ForegroundColor White
Write-Host "AI Analysis Count: $($finalStats.AIAnalysisCount)" -ForegroundColor White
if ($finalStats.ChangesAnalyzed -gt 0) {
    Write-Host "Cache Hit Rate: $($finalStats.CacheHitRate)%" -ForegroundColor White
}

# Export results
$resultsFile = Join-Path $PSScriptRoot "ChangeIntelligence-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding UTF8
Write-Host "`nTest results saved to: $resultsFile" -ForegroundColor Gray

# Return success/failure for CI/CD integration
exit $(if ($testResults.Failed -eq 0) { 0 } else { 1 })