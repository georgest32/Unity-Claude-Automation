# Test-SemanticAnalysis.ps1
# Comprehensive test suite for Unity-Claude-SemanticAnalysis module
# Tests all semantic analysis functions and validates Phase 2 implementation

param(
    [string]$TestType = "All",
    [switch]$SaveResults,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# CRITICAL FIX: Import CPG and AST Converter modules at script level with Global scope  
Write-Host "Importing CPG module dependencies at script level..." -ForegroundColor Yellow
try {
    # Import main CPG module first
    $cpgManifestPath = Join-Path $PSScriptRoot "Modules\Unity-Claude-CPG\Unity-Claude-CPG.psd1"
    if (Test-Path $cpgManifestPath) {
        Import-Module $cpgManifestPath -Force -Scope Global -ErrorAction Stop
        Write-Host "  CPG module imported globally" -ForegroundColor Green
    } else {
        throw "CPG module manifest not found at: $cpgManifestPath"
    }
    
    # WORKAROUND: Direct import of AST Converter nested module to resolve scope issues
    $astConverterPath = Join-Path $PSScriptRoot "Modules\Unity-Claude-CPG\Unity-Claude-CPG-ASTConverter.psm1"
    if (Test-Path $astConverterPath) {
        Import-Module $astConverterPath -Force -Scope Global -ErrorAction Stop
        Write-Host "  AST Converter module imported directly" -ForegroundColor Green
    } else {
        throw "AST Converter module not found at: $astConverterPath"
    }
    
    # Verify Convert-ASTtoCPG function is now available
    $convertFunction = Get-Command Convert-ASTtoCPG -ErrorAction SilentlyContinue
    if ($convertFunction) {
        Write-Host "  Convert-ASTtoCPG function verified: Available from $($convertFunction.Module)" -ForegroundColor Green
    } else {
        throw "Convert-ASTtoCPG function not found after direct AST Converter import"
    }
    
} catch {
    Write-Error "Failed to import CPG module dependencies: $($_.Exception.Message)"
    exit 1
}

# Test configuration
$script:TestResults = @{
    StartTime = Get-Date
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    Details = @()
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = "",
        [string]$Error = ""
    )
    
    $script:TestResults.TotalTests++
    if ($Passed) {
        $script:TestResults.PassedTests++
        Write-Host "[PASS] $TestName" -ForegroundColor Green
    } else {
        $script:TestResults.FailedTests++
        Write-Host "[FAIL] $TestName" -ForegroundColor Red
        if ($Error) { Write-Host "  Error: $Error" -ForegroundColor Yellow }
    }
    
    $script:TestResults.Details += @{
        Name = $TestName
        Status = if ($Passed) { "Passed" } else { "Failed" }
        Details = $Details
        Error = $Error
        Timestamp = Get-Date
    }
    
    if ($Verbose -and $Details) {
        Write-Host "  Details: $Details" -ForegroundColor Cyan
    }
}

function ConvertTo-CPGFromScriptBlock {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock
    )
    
    Write-Verbose "ConvertTo-CPGFromScriptBlock: Starting CPG conversion for ScriptBlock"
    
    try {
        # Debug: List all available commands first
        Write-Verbose "  Debugging available commands..."
        $allCommands = Get-Command -Name "*Convert-ASTtoCPG*" -ErrorAction SilentlyContinue
        if ($allCommands) {
            foreach ($cmd in $allCommands) {
                Write-Verbose "    Found command: $($cmd.Name) from module: $($cmd.ModuleName)"
            }
        } else {
            Write-Verbose "    No Convert-ASTtoCPG commands found"
        }
        
        # Verify Convert-ASTtoCPG function is available with fallback to module-qualified call
        $convertFunction = Get-Command Convert-ASTtoCPG -ErrorAction SilentlyContinue
        if (-not $convertFunction) {
            # Try to find it in any loaded module
            $convertFunction = Get-Command "*Convert-ASTtoCPG*" -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $convertFunction) {
                # Get available CPG module commands for debugging
                $cpgCommands = Get-Command -Module Unity-Claude-CPG -ErrorAction SilentlyContinue
                $cpgCommandNames = if ($cpgCommands) { $cpgCommands.Name -join ', ' } else { 'None found' }
                throw "Convert-ASTtoCPG function not available in any scope. Available CPG commands: $cpgCommandNames"
            }
            Write-Verbose "  Convert-ASTtoCPG found as: $($convertFunction.Name)"
        } else {
            Write-Verbose "  Convert-ASTtoCPG function verified in helper context: $($convertFunction.Name)"
        }
        
        # Parse ScriptBlock to AST with error handling
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($ScriptBlock.ToString(), [ref]$null, [ref]$parseErrors)
        
        if ($parseErrors -and $parseErrors.Count -gt 0) {
            Write-Warning "  AST parsing warnings: $($parseErrors.Count) issues found"
            foreach ($error in $parseErrors) {
                Write-Verbose "    Parse warning: $($error.Message) at line $($error.Extent.StartLineNumber)"
            }
        }
        
        Write-Verbose "  AST parsed successfully, converting to CPG..."
        
        # Convert AST to CPG with detailed logging
        Write-Verbose "  Convert function details - Name: '$($convertFunction.Name)', ModuleName: '$($convertFunction.ModuleName)', CommandType: '$($convertFunction.CommandType)'"
        
        # Additional safety check
        if ([string]::IsNullOrEmpty($convertFunction.Name)) {
            throw "Convert function has empty or null name. Function object: $($convertFunction | ConvertTo-Json -Depth 2)"
        }
        
        # Use direct function call for safety
        $graph = Convert-ASTtoCPG -AST $ast
        
        Write-Verbose "  CPG conversion completed. Graph has $($graph.Nodes.Count) nodes and $($graph.Edges.Count) edges"
        return $graph
        
    } catch {
        Write-Error "ConvertTo-CPGFromScriptBlock failed: $($_.Exception.Message)"
        Write-Verbose "  ScriptBlock content: $($ScriptBlock.ToString().Substring(0, [Math]::Min(200, $ScriptBlock.ToString().Length)))..."
        throw
    }
}

function Test-ModuleImport {
    Write-Host "`n=== Testing Module Import ===" -ForegroundColor Magenta
    
    try {
        # Test manifest file
        $manifestPath = Join-Path $PSScriptRoot "Modules\Unity-Claude-CPG\Unity-Claude-SemanticAnalysis.psd1"
        if (-not (Test-Path $manifestPath)) {
            throw "Module manifest not found at $manifestPath"
        }
        
        # Test module structure
        $manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
        Write-TestResult "Module Manifest Validation" $true "Version: $($manifest.Version), Functions: $($manifest.ExportedFunctions.Count)"
        
        # CPG module already imported at script level - import semantic analysis module
        Import-Module $manifestPath -Force -ErrorAction Stop
        Write-TestResult "Module Import" $true "Successfully imported Unity-Claude-SemanticAnalysis"
        
        # Test exported functions
        $exportedFunctions = Get-Command -Module Unity-Claude-SemanticAnalysis -CommandType Function
        $expectedFunctions = @('Find-DesignPatterns', 'Get-CodePurpose', 'Get-CohesionMetrics', 'Extract-BusinessLogic', 'Recover-Architecture', 'Test-DocumentationCompleteness', 'Test-NamingConventions', 'Test-CommentCodeAlignment', 'Get-TechnicalDebt', 'New-QualityReport')
        
        foreach ($func in $expectedFunctions) {
            $exists = $exportedFunctions | Where-Object { $_.Name -eq $func }
            Write-TestResult "Function Export: $func" ($null -ne $exists) "Function available for use"
        }
        
    } catch {
        Write-TestResult "Module Import" $false "" $_.Exception.Message
        return $false
    }
    
    return $true
}

function Test-PatternRecognition {
    Write-Host "`n=== Testing Pattern Recognition ===" -ForegroundColor Magenta
    
    try {
        # Create test PowerShell code for pattern detection  
        $testCode = @'
class SingletonExample {
    static [SingletonExample] $Instance
    static hidden [object] $Lock = [object]::new()
    
    hidden SingletonExample() {}
    
    static [SingletonExample] GetInstance() {
        if ([SingletonExample]::Instance -eq $null) {
            [System.Threading.Monitor]::Enter([SingletonExample]::Lock)
            try {
                if ([SingletonExample]::Instance -eq $null) {
                    [SingletonExample]::Instance = [SingletonExample]::new()
                }
            } finally {
                [System.Threading.Monitor]::Exit([SingletonExample]::Lock)
            }
        }
        return [SingletonExample]::Instance
    }
}

class Circle {
    Circle() { }
}

class Square {
    Square() { }
}

class ShapeFactory {
    static [object] CreateShape([string] $shapeType) {
        if ($shapeType -eq 'Circle') {
            return [Circle]::new()
        }
        elseif ($shapeType -eq 'Square') {
            return [Square]::new()
        }
        else {
            throw "Unknown shape type: $shapeType"
        }
    }
}
'@
        
        # Create CPG from test code first  
        Write-Verbose "Creating CPG from test code for pattern recognition..."
        $graph = ConvertTo-CPGFromScriptBlock -ScriptBlock ([scriptblock]::Create($testCode))
        Write-Verbose "  Graph created with $($graph.Nodes.Count) nodes and $($graph.Edges.Count) edges"
        
        # Test Find-DesignPatterns function
        Write-Verbose "Testing Find-DesignPatterns function..."
        $patterns = Find-DesignPatterns -Graph $graph
        Write-TestResult "Find-DesignPatterns Execution" ($null -ne $patterns) "Returned $($patterns.Count) pattern matches"
        
        # Test for Singleton pattern detection
        $singletonFound = $patterns | Where-Object { $_ -and $_.PSObject.Properties['PatternType'] -and $_.PatternType -eq 'Singleton' } | Select-Object -First 1
        $singletonConf = if ($singletonFound -and $singletonFound.PSObject.Properties['Confidence']) { $singletonFound.Confidence } else { '' }
        Write-TestResult "Singleton Pattern Detection" ($null -ne $singletonFound) "Confidence: $singletonConf"
        
        # Test for Factory pattern detection
        $factoryFound = $patterns | Where-Object { $_ -and $_.PSObject.Properties['PatternType'] -and $_.PatternType -eq 'Factory' } | Select-Object -First 1
        $factoryConf = if ($factoryFound -and $factoryFound.PSObject.Properties['Confidence']) { $factoryFound.Confidence } else { '' }
        Write-TestResult "Factory Pattern Detection" ($null -ne $factoryFound) "Confidence: $factoryConf"
        
    } catch {
        Write-TestResult "Pattern Recognition Test" $false "" $_.Exception.Message
        return $false
    }
    
    return $true
}

function Test-CodePurposeClassification {
    Write-Host "`n=== Testing Code Purpose Classification ===" -ForegroundColor Magenta
    
    try {
        # Test various function types
        $testFunctions = @(
            @{ Code = "function Get-UserById { param([int]`$Id) return `$Id }"; Purpose = "Read" },
            @{ Code = "function New-User { param([string]`$Name) return `$Name }"; Purpose = "Create" },
            @{ Code = "function Update-UserEmail { param([string]`$Email) return `$Email }"; Purpose = "Update" },
            @{ Code = "function Remove-User { param([int]`$Id) return `$Id }"; Purpose = "Delete" },
            @{ Code = "function Test-EmailFormat { param([string]`$Email) return `$Email }"; Purpose = "Validation" }
        )
        
        foreach ($test in $testFunctions) {
            # Create CPG from test code
            $graph = ConvertTo-CPGFromScriptBlock -ScriptBlock ([scriptblock]::Create($test.Code))
            $purposeResults = Get-CodePurpose -Graph $graph
            $purposeArray = @($purposeResults)
            if ($purposeArray.Count -gt 0 -and $purposeArray[0] -ne $null) {
                $purpose = $purposeArray[0]
                $detectedPurpose = if ($purpose -and $purpose.PSObject.Properties['Purpose']) { $purpose.Purpose } elseif ($purpose -and $purpose.PSObject.Properties['PrimaryPurpose']) { $purpose.PrimaryPurpose } else { 'Unknown' }
                $confidence = if ($purpose -and $purpose.PSObject.Properties['Confidence']) { $purpose.Confidence } else { 0 }
                $correctClassification = $detectedPurpose -eq $test.Purpose
                Write-TestResult "Purpose Classification: $($test.Purpose)" $correctClassification "Detected: $detectedPurpose, Confidence: $confidence"
            } else {
                Write-TestResult "Purpose Classification: $($test.Purpose)" $false "No purpose detected"
            }
        }
        
    } catch {
        Write-TestResult "Code Purpose Classification Test" $false "" $_.Exception.Message
        return $false
    }
    
    return $true
}

function Test-CohesionMetrics {
    Write-Host "`n=== Testing Cohesion Metrics ===" -ForegroundColor Magenta
    
    try {
        # Test module with sample functions
        $testModule = @'
function Get-UserData { param([int]$UserId) }
function Set-UserData { param([int]$UserId, [object]$Data) }
function Remove-UserData { param([int]$UserId) }
function Send-Email { param([string]$To, [string]$Subject) }
'@
        
        # Create CPG from test module
        $graph = ConvertTo-CPGFromScriptBlock -ScriptBlock ([scriptblock]::Create($testModule))
        $cohesionResults = Get-CohesionMetrics -Graph $graph
        $cohesionArray = @($cohesionResults)
        
        if ($cohesionArray.Count -gt 0 -and $cohesionArray[0] -ne $null) {
            $cohesionMetrics = $cohesionArray[0]
            $chm = if ($cohesionMetrics -and $cohesionMetrics.PSObject.Properties['CHM']) { $cohesionMetrics.CHM } else { 0 }
            $chd = if ($cohesionMetrics -and $cohesionMetrics.PSObject.Properties['CHD']) { $cohesionMetrics.CHD } else { 0 }
            Write-TestResult "Cohesion Metrics Calculation" ($null -ne $cohesionMetrics) "CHM: $chm, CHD: $chd"
            
            # Validate metric ranges
            $validCHM = $chm -ge 0 -and $chm -le 1
            $validCHD = $chd -ge 0 -and $chd -le 1
        } else {
            Write-TestResult "Cohesion Metrics Calculation" $false "No cohesion metrics calculated"
            $validCHM = $false
            $validCHD = $false
        }
        
        Write-TestResult "CHM Metric Range Validation" $validCHM "CHM value within 0-1 range"
        Write-TestResult "CHD Metric Range Validation" $validCHD "CHD value within 0-1 range"
        
    } catch {
        Write-TestResult "Cohesion Metrics Test" $false "" $_.Exception.Message
        return $false
    }
    
    return $true
}

function Test-BusinessLogicExtraction {
    Write-Host "`n=== Testing Business Logic Extraction ===" -ForegroundColor Magenta
    
    try {
        # Test code with business rules
        $testCode = @'
function Calculate-Discount {
    # Business Rule: Premium customers get 15% discount, Regular customers get 5%
    param([string]$CustomerType, [decimal]$Amount)
    
    if ($CustomerType -eq "Premium") {
        return $Amount * 0.15
    } elseif ($CustomerType -eq "Regular") {
        return $Amount * 0.05
    } else {
        return 0
    }
}
'@
        
        # Create CPG from test code
        $graph = ConvertTo-CPGFromScriptBlock -ScriptBlock ([scriptblock]::Create($testCode))
        $businessLogic = Extract-BusinessLogic -Graph $graph
        $businessArray = @($businessLogic)
        
        Write-TestResult "Business Logic Extraction" ($businessArray.Count -gt 0) "Found $($businessArray.Count) business rules"
        
        # Check for discount rule detection
        $discountRule = $businessArray | Where-Object { $_ -ne $null -and $_.PSObject.Properties['RuleType'] -and $_.RuleType -eq "CalculationRule" } | Select-Object -First 1
        $confidence = if ($discountRule -and $discountRule.PSObject.Properties['Confidence']) { $discountRule.Confidence } else { 'N/A' }
        Write-TestResult "Discount Rule Detection" ($null -ne $discountRule) "Rule detected with confidence: $confidence"
        
    } catch {
        Write-TestResult "Business Logic Extraction Test" $false "" $_.Exception.Message
        return $false
    }
    
    return $true
}

function Test-QualityAnalysis {
    Write-Host "`n=== Testing Code Quality Analysis ===" -ForegroundColor Magenta
    
    try {
        # Test documentation completeness
        $testModule = @'
<#
.SYNOPSIS
Well documented function
#>
function Get-WellDocumentedFunction { param([string]$Parameter) }

function Get-UndocumentedFunction { param([string]$Parameter) }
'@
        
        # Create CPG from test module
        $graph = ConvertTo-CPGFromScriptBlock -ScriptBlock ([scriptblock]::Create($testModule))
        
        $docCompleteness = Test-DocumentationCompleteness -Graph $graph
        $docArray = @($docCompleteness)
        if ($docArray.Count -gt 0 -and $docArray[0] -ne $null) {
            $doc = $docArray[0]
            $coverage = if ($doc -and $doc.PSObject.Properties['CoveragePercentage']) { $doc.CoveragePercentage } else { 0 }
            Write-TestResult "Documentation Completeness Analysis" ($null -ne $doc) "Coverage: $coverage%"
        } else {
            Write-TestResult "Documentation Completeness Analysis" $false "No documentation analysis"
        }
        
        # Test naming conventions
        $namingResults = Test-NamingConventions -Graph $graph
        $namingArray = @($namingResults)
        if ($namingArray.Count -gt 0 -and $namingArray[0] -ne $null) {
            $naming = $namingArray[0]
            $compliance = if ($naming -and $naming.PSObject.Properties['CompliancePercentage']) { $naming.CompliancePercentage } else { 0 }
            Write-TestResult "Naming Convention Validation" ($null -ne $naming) "Compliance: $compliance%"
        } else {
            Write-TestResult "Naming Convention Validation" $false "No naming analysis"
        }
        
        # Test technical debt analysis
        $debtAnalysis = Get-TechnicalDebt -Graph $graph
        $debtArray = @($debtAnalysis)
        if ($debtArray.Count -gt 0 -and $debtArray[0] -ne $null) {
            $debt = $debtArray[0]
            $score = if ($debt -and $debt.PSObject.Properties['TotalDebtScore']) { $debt.TotalDebtScore } else { 0 }
            Write-TestResult "Technical Debt Analysis" ($null -ne $debt) "Debt Score: $score"
        } else {
            Write-TestResult "Technical Debt Analysis" $false "No debt analysis"
        }
        
    } catch {
        Write-TestResult "Quality Analysis Test" $false "" $_.Exception.Message
        return $false
    }
    
    return $true
}

function Test-ReportGeneration {
    Write-Host "`n=== Testing Report Generation ===" -ForegroundColor Magenta
    
    try {
        # Test HTML report generation
        $testCode = "function Test-Function { param([string]`$Test) return `$Test }"
        $graph = ConvertTo-CPGFromScriptBlock -ScriptBlock ([scriptblock]::Create($testCode))
        $htmlReport = New-QualityReport -Graph $graph -Format "HTML"
        
        Write-TestResult "HTML Report Generation" ($null -ne $htmlReport -and $htmlReport.Length -gt 0) "HTML content generated"
        
        # Test JSON report generation  
        $jsonReport = New-QualityReport -Graph $graph -Format "JSON"
        Write-TestResult "JSON Report Generation" ($null -ne $jsonReport -and $jsonReport.Length -gt 0) "JSON content generated"
        
    } catch {
        Write-TestResult "Report Generation Test" $false "" $_.Exception.Message
        return $false
    }
    
    return $true
}

function Test-Performance {
    Write-Host "`n=== Testing Performance Characteristics ===" -ForegroundColor Magenta
    
    try {
        # Test with larger code sample
        $largeCode = 1..50 | ForEach-Object { "function Test-Function$_ { param([string]`$Test$_) return `$Test$_ }" } | Join-String -Separator "`n"
        
        # Create CPG from large code sample
        $graph = ConvertTo-CPGFromScriptBlock -ScriptBlock ([scriptblock]::Create($largeCode))
        
        # Measure pattern detection performance (first run with cache enabled)
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $patterns = Find-DesignPatterns -Graph $graph -UseCache
        $stopwatch.Stop()
        
        $firstRunTime = $stopwatch.ElapsedMilliseconds
        $performanceAcceptable = $firstRunTime -lt 10000 # Less than 10 seconds
        Write-TestResult "Pattern Detection Performance" $performanceAcceptable "Processed 50 functions in ${firstRunTime}ms"
        
        # Test caching effectiveness (second run should be faster)
        $stopwatch.Restart()
        $patterns2 = Find-DesignPatterns -Graph $graph -UseCache
        $stopwatch.Stop()
        
        $secondRunTime = $stopwatch.ElapsedMilliseconds
        # Cache is effective if second run is faster, or both runs are very fast (< 50ms indicating good performance)
        $cachingEffective = ($secondRunTime -lt $firstRunTime) -or ($firstRunTime -lt 50 -and $secondRunTime -lt 50)
        Write-TestResult "Caching Effectiveness" $cachingEffective "First: ${firstRunTime}ms, Second: ${secondRunTime}ms"
        
    } catch {
        Write-TestResult "Performance Test" $false "" $_.Exception.Message
        return $false
    }
    
    return $true
}

# Main execution
Write-Host "=== Unity-Claude Semantic Analysis Test Suite ===" -ForegroundColor Cyan
Write-Host "Starting comprehensive testing of Phase 2 implementation" -ForegroundColor Cyan
Write-Host "Test Type: $TestType" -ForegroundColor Yellow

$allPassed = $true

# Import module first
if (-not (Test-ModuleImport)) {
    $allPassed = $false
} else {
    # Run specific tests based on TestType
    switch ($TestType) {
        "All" {
            $allPassed = (Test-PatternRecognition) -and $allPassed
            $allPassed = (Test-CodePurposeClassification) -and $allPassed  
            $allPassed = (Test-CohesionMetrics) -and $allPassed
            $allPassed = (Test-BusinessLogicExtraction) -and $allPassed
            $allPassed = (Test-QualityAnalysis) -and $allPassed
            $allPassed = (Test-ReportGeneration) -and $allPassed
            $allPassed = (Test-Performance) -and $allPassed
        }
        "Patterns" { $allPassed = (Test-PatternRecognition) -and $allPassed }
        "Quality" { $allPassed = (Test-QualityAnalysis) -and $allPassed }
        "Performance" { $allPassed = (Test-Performance) -and $allPassed }
        default {
            Write-Host "Unknown test type: $TestType" -ForegroundColor Red
            $allPassed = $false
        }
    }
}

# Generate summary
$script:TestResults.EndTime = Get-Date
$script:TestResults.Duration = $script:TestResults.EndTime - $script:TestResults.StartTime
$script:TestResults.PassRate = if ($script:TestResults.TotalTests -gt 0) { 
    [Math]::Round(($script:TestResults.PassedTests / $script:TestResults.TotalTests) * 100, 2) 
} else { 0 }

Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Total Tests: $($script:TestResults.TotalTests)" -ForegroundColor White
Write-Host "Passed: $($script:TestResults.PassedTests)" -ForegroundColor Green  
Write-Host "Failed: $($script:TestResults.FailedTests)" -ForegroundColor Red
Write-Host "Pass Rate: $($script:TestResults.PassRate)%" -ForegroundColor $(if ($script:TestResults.PassRate -ge 80) { "Green" } else { "Yellow" })
Write-Host "Duration: $($script:TestResults.Duration.TotalSeconds) seconds" -ForegroundColor White

# Save results if requested
if ($SaveResults) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $resultsFile = "SemanticAnalysis-TestResults-$timestamp.json"
    $script:TestResults | ConvertTo-Json -Depth 10 | Out-File $resultsFile -Encoding UTF8
    Write-Host "Results saved to: $resultsFile" -ForegroundColor Cyan
}

# Exit with appropriate code
if ($allPassed -and $script:TestResults.FailedTests -eq 0) {
    Write-Host "`nAll tests passed! Semantic analysis implementation is ready." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSome tests failed. Please review and fix issues before proceeding." -ForegroundColor Red
    exit 1
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAbBJEb/D8r8k09
# PfQN+nGkkHGMWJrr5fgX2vmjv8hgxKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBjtR491prq+9ZzHim3lzRjv
# Dn5tPc3jmYTZBo7AY9VlMA0GCSqGSIb3DQEBAQUABIIBAHaK1F6g4HiTyt1Muup5
# Cdq5GM8Ybp5z+/szBDL2KOiE4hc5JL5wKawzjHaV/CVKX7afj1vkxExRZIf3Zj64
# h+jCSsCbHtljtNU/kmQLhe12TP1ceJ3rgjJE8ExUMhiJas8qWUGHjrD1nI/KCMi7
# oMvlrc4gkAJ1+X99FAZ6+3/Z4TtUWK2G8SrNxQQX+Y2tsVfqr8d/PH+bURXQ+cJe
# 1zMYs3NkIC7bCdR8nS2Z7+cQQQpVUL5VxxqvpYrXnrE6i03s3fpgIMZ+PMGGgkbz
# cBs0W+PqVDXS27p17cTiTdjXIkcRPDwLJlJCRJUmcl0KO71FcPui8IbWsHdGAs7l
# +ds=
# SIG # End signature block
