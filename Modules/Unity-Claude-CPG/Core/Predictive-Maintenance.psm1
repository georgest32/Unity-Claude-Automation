# Predictive-Maintenance.psm1
# Week 4 Day 2: Maintenance Prediction Module  
# Enhanced Documentation System - Advanced Features & Polish
# Date: 2025-08-29

<#
.SYNOPSIS
    Maintenance prediction module implementing SQALE-inspired technical debt calculation,
    PSScriptAnalyzer integration, and machine learning-based maintenance forecasting.

.DESCRIPTION
    This module provides comprehensive maintenance prediction capabilities including:
    - Technical debt calculation using dual-cost SQALE model
    - Code smell detection with PSScriptAnalyzer integration
    - Machine learning-based maintenance prediction
    - Refactoring ROI analysis and recommendation engine
    - Integration with existing Code Evolution Analysis infrastructure

.NOTES
    Version: 1.0.0
    Author: Unity-Claude-Automation
    Dependencies: Predictive-Evolution.psm1, PSScriptAnalyzer, Unity-Claude-CPG modules
    Research: Based on SQALE model, modern ML approaches, and 2025 industry standards
#>

# Module metadata
$ModuleVersion = "1.0.0"
$ModuleName = "Predictive-Maintenance"

# Import required modules and check dependencies
try {
    Write-Debug "[$ModuleName] Loading required dependencies..."
    
    # Import Safe-FileEnumeration module for CLR crash prevention
    $rootPath = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
    $safeEnumPath = Join-Path $rootPath "Safe-FileEnumeration.psm1"
    if (Test-Path $safeEnumPath) {
        Import-Module $safeEnumPath -Force -ErrorAction SilentlyContinue
        Write-Debug "[$ModuleName] Safe-FileEnumeration module loaded for CLR crash prevention"
    } else {
        # Define fallback function if module not found
        function Get-SafeChildItems {
            param(
                [string]$Path,
                [string]$Filter = "*.*",
                [int]$MaxDepth = 5,
                [switch]$FilesOnly
            )
            Get-ChildItem -Path $Path -Filter $Filter -Recurse -ErrorAction SilentlyContinue |
                Where-Object { 
                    if ($FilesOnly) { -not $_.PSIsContainer } else { $true }
                }
        }
        Write-Warning "[$ModuleName] Safe-FileEnumeration module not found - using fallback implementation"
    }
    
    # Check for PSScriptAnalyzer and verify command availability
    $script:PSScriptAnalyzerAvailable = $false
    try {
        if (Get-Module -ListAvailable -Name PSScriptAnalyzer -ErrorAction SilentlyContinue) {
            Import-Module PSScriptAnalyzer -Force -ErrorAction Stop
            # Verify the command is actually available
            $null = Get-Command Invoke-ScriptAnalyzer -ErrorAction Stop
            $script:PSScriptAnalyzerAvailable = $true
            Write-Debug "[$ModuleName] PSScriptAnalyzer module and command verified available"
        } else {
            Write-Warning "[$ModuleName] PSScriptAnalyzer module not found - code smell detection will be limited"
        }
    }
    catch {
        Write-Warning "[$ModuleName] PSScriptAnalyzer import or command verification failed: $($_.Exception.Message) - code smell detection will be limited"
        $script:PSScriptAnalyzerAvailable = $false
    }
    
    # Check for Predictive-Evolution module in same directory
    $evolutionModulePath = Join-Path $PSScriptRoot "Predictive-Evolution.psm1"
    if (-not (Test-Path $evolutionModulePath)) {
        Write-Warning "[$ModuleName] Predictive-Evolution module not found - some features may be limited"
    }
    else {
        Write-Debug "[$ModuleName] Predictive-Evolution module available at $evolutionModulePath"
    }
    
    Write-Debug "[$ModuleName] Module dependencies validated - Version $ModuleVersion"
}
catch {
    Write-Error "[$ModuleName] Failed to validate dependencies: $($_.Exception.Message)"
    throw
}

# Classes and Data Structures based on research findings
class TechnicalDebtItem {
    [string]$FilePath
    [string]$RuleId
    [string]$Severity
    [string]$Category
    [double]$RemediationCost    # Time to fix (SQALE model)
    [double]$NonRemediationCost # Business impact cost
    [double]$TotalDebt
    [string]$Description
    [string]$Recommendation
    [double]$ConfidenceScore
    
    TechnicalDebtItem() {
        $this.ConfidenceScore = 0.8
    }
}

class MaintenancePrediction {
    [string]$FilePath
    [string]$PredictionType
    [datetime]$PredictedDate
    [double]$Confidence
    [string]$Priority
    [string]$RecommendedAction
    [hashtable]$Metrics
    [string[]]$Indicators
    
    MaintenancePrediction() {
        $this.Metrics = @{}
        $this.Indicators = @()
    }
}

class RefactoringRecommendation {
    [string]$FilePath
    [string]$RefactoringType
    [double]$ROI
    [double]$EstimatedCost
    [double]$EstimatedBenefit
    [string]$Priority
    [string]$Timeline
    [string]$Description
    [hashtable]$Metrics
    
    RefactoringRecommendation() {
        $this.Metrics = @{}
    }
}

# Configuration constants based on research
$script:DebtWeights = @{
    Critical = 1.0
    High = 0.8
    Medium = 0.5
    Low = 0.2
}

$script:ComplexityThresholds = @{
    Low = 5
    Medium = 10
    High = 15
    Critical = 20
}

#region Core Functions

function Get-TechnicalDebt {
    <#
    .SYNOPSIS
        Calculates technical debt using SQALE-inspired dual-cost model.
        
    .DESCRIPTION
        Implements industry-standard technical debt calculation based on SQALE methodology
        with dual-cost approach: remediation cost (time to fix) and non-remediation cost 
        (business impact). Integrates with PSScriptAnalyzer for PowerShell code analysis.
        
    .PARAMETER Path
        Path to analyze for technical debt (file or directory)
        
    .PARAMETER Recursive
        Analyze subdirectories recursively
        
    .PARAMETER FilePattern
        Filter files by pattern (e.g., "*.ps1", "*.psm1")
        
    .PARAMETER UseEvolutionData
        Integrate with code evolution data for enhanced debt calculation
        
    .PARAMETER OutputFormat
        Output format: 'Summary', 'Detailed', 'JSON'
        
    .EXAMPLE
        $debt = Get-TechnicalDebt -Path ".\Modules" -Recursive -FilePattern "*.psm1"
        
    .EXAMPLE
        $debt = Get-TechnicalDebt -Path ".\Scripts" -UseEvolutionData -OutputFormat "Detailed"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter()]
        [switch]$Recursive,
        
        [Parameter()]
        [string]$FilePattern = "*.ps*",
        
        [Parameter()]
        [switch]$UseEvolutionData,
        
        [Parameter()]
        [ValidateSet('Summary', 'Detailed', 'JSON')]
        [string]$OutputFormat = 'Summary'
    )
    
    begin {
        Write-Debug "[$ModuleName] Get-TechnicalDebt: Starting technical debt analysis"
        $startTime = Get-Date
        
        # Validate path
        if (-not (Test-Path -Path $Path)) {
            throw "Path does not exist: $Path"
        }
        
        # Use module-level PSScriptAnalyzer availability flag
        $psaAvailable = $script:PSScriptAnalyzerAvailable
        Write-Debug "[$ModuleName] Using PSScriptAnalyzer availability: $psaAvailable"
    }
    
    process {
        try {
            # Get files to analyze using SAFE enumeration to prevent memory corruption
            $files = if ($Recursive) {
                Get-SafeChildItems -Path $Path -Filter $FilePattern -FilesOnly -MaxDepth 3
            } else {
                Get-SafeChildItems -Path $Path -Filter $FilePattern -FilesOnly -MaxDepth 1
            }
            
            if (-not $files) {
                Write-Warning "[$ModuleName] No files found matching pattern: $FilePattern"
                return @()
            }
            
            Write-Debug "[$ModuleName] Analyzing $($files.Count) files for technical debt"
            
            # Initialize debt tracking
            $debtItems = @()
            $fileCount = 0
            $totalFiles = $files.Count
            
            foreach ($file in $files) {
                $fileCount++
                $percentComplete = if ($totalFiles -gt 0) { ($fileCount / $totalFiles) * 100 } else { 0 }
                Write-Progress -Activity "Technical Debt Analysis" -Status "Processing $($file.Name)" -PercentComplete $percentComplete
                
                # Analyze file for debt
                $fileDebt = Get-FileDebt -FilePath $file.FullName -UsePSA $psaAvailable
                
                # Add evolution data if requested
                if ($UseEvolutionData) {
                    $fileDebt = Add-EvolutionContext -DebtItems $fileDebt -FilePath $file.FullName -BasePath $Path
                }
                
                $debtItems += $fileDebt
            }
            
            Write-Progress -Activity "Technical Debt Analysis" -Completed
            
            # Calculate aggregate metrics
            $summary = Get-DebtSummary -DebtItems $debtItems
            
            # Format output
            $result = Format-DebtOutput -DebtItems $debtItems -Summary $summary -Format $OutputFormat
            
            $duration = (Get-Date) - $startTime
            Write-Debug "[$ModuleName] Technical debt analysis completed in $($duration.TotalSeconds) seconds"
            
            return $result
        }
        catch {
            Write-Error "[$ModuleName] Technical debt analysis failed: $($_.Exception.Message)"
            throw
        }
    }
}

function Get-FileDebt {
    <#
    .SYNOPSIS
        Analyzes a single file for technical debt using multiple approaches.
    #>
    [CmdletBinding()]
    param(
        [string]$FilePath,
        [bool]$UsePSA = $false
    )
    
    $debtItems = @()
    
    try {
        # Get basic file metrics
        $content = Get-Content -Path $FilePath -ErrorAction SilentlyContinue
        if (-not $content) { return $debtItems }
        
        $lineCount = $content.Count
        $fileSize = (Get-Item -Path $FilePath).Length
        
        # Calculate base complexity (simplified approach)
        $complexity = Get-FileComplexityMetrics -Content $content -FilePath $FilePath
        
        # PSScriptAnalyzer analysis if available
        if ($UsePSA) {
            try {
                $psaResults = Invoke-ScriptAnalyzer -Path $FilePath -ErrorAction SilentlyContinue
                foreach ($violation in $psaResults) {
                    $debtItem = [TechnicalDebtItem]::new()
                    $debtItem.FilePath = $FilePath
                    $debtItem.RuleId = $violation.RuleName
                    $debtItem.Severity = $violation.Severity.ToString()
                    $debtItem.Category = Get-ViolationCategory -RuleName $violation.RuleName
                    $debtItem.Description = $violation.Message
                    
                    # Calculate costs based on research findings
                    $costs = Get-DebtCosts -Violation $violation -Complexity $complexity -LineCount $lineCount
                    $debtItem.RemediationCost = $costs.RemediationCost
                    $debtItem.NonRemediationCost = $costs.NonRemediationCost
                    $debtItem.TotalDebt = $costs.TotalDebt
                    $debtItem.Recommendation = Get-DebtRecommendation -Violation $violation
                    
                    $debtItems += $debtItem
                }
            }
            catch {
                Write-Debug "[$ModuleName] PSScriptAnalyzer analysis failed for $FilePath`: $($_.Exception.Message)"
            }
        }
        
        # Add complexity-based debt items
        if ($complexity.CyclomaticComplexity -gt $script:ComplexityThresholds.Medium) {
            $complexityDebt = [TechnicalDebtItem]::new()
            $complexityDebt.FilePath = $FilePath
            $complexityDebt.RuleId = "HIGH_COMPLEXITY"
            $complexityDebt.Severity = if ($complexity.CyclomaticComplexity -gt $script:ComplexityThresholds.Critical) { "Error" } else { "Warning" }
            $complexityDebt.Category = "Maintainability"
            $complexityDebt.Description = "High cyclomatic complexity ($($complexity.CyclomaticComplexity))"
            
            # Calculate complexity-based costs
            $complexityCosts = Get-ComplexityDebtCosts -Complexity $complexity -LineCount $lineCount
            $complexityDebt.RemediationCost = $complexityCosts.RemediationCost
            $complexityDebt.NonRemediationCost = $complexityCosts.NonRemediationCost
            $complexityDebt.TotalDebt = $complexityCosts.TotalDebt
            $complexityDebt.Recommendation = "Consider breaking down complex functions or using design patterns"
            
            $debtItems += $complexityDebt
        }
        
        return $debtItems
    }
    catch {
        Write-Debug "[$ModuleName] File debt analysis failed for $FilePath`: $($_.Exception.Message)"
        return @()
    }
}

function Get-FileComplexityMetrics {
    <#
    .SYNOPSIS
        Calculates complexity metrics for a file including cyclomatic complexity and maintainability index.
    #>
    [CmdletBinding()]
    param(
        [string[]]$Content,
        [string]$FilePath
    )
    
    # Calculate basic metrics
    $lineCount = $Content.Count
    $nonEmptyLines = ($Content | Where-Object { $_.Trim() -ne "" }).Count
    
    # Count control structures for cyclomatic complexity (simplified)
    $controlStructures = @(
        'if\s*\(',
        'elseif\s*\(',
        'while\s*\(',
        'for\s*\(',
        'foreach\s*\(',
        'do\s*{',
        'switch\s*\(',
        'try\s*{',
        'catch\s*{',
        '\?.*:',  # Ternary operator
        '&&',     # Logical AND
        '\|\|'    # Logical OR
    )
    
    $complexityCount = 0
    foreach ($pattern in $controlStructures) {
        $matches = ($Content | Select-String -Pattern $pattern -AllMatches).Matches
        $complexityCount += $matches.Count
    }
    
    # Base complexity is 1, add 1 for each decision point
    $cyclomaticComplexity = 1 + $complexityCount
    
    # Count functions for maintainability calculation
    $functionCount = ($Content | Select-String -Pattern '\bfunction\s+[\w-]+' -AllMatches).Matches.Count
    
    # Calculate Halstead volume (simplified estimate)
    $operatorCount = ($Content | Select-String -Pattern '[\+\-\*/=<>!&|]' -AllMatches).Matches.Count
    $operandCount = ($Content | Select-String -Pattern '\$\w+' -AllMatches).Matches.Count
    $halsteadVolume = [math]::Max(($operatorCount + $operandCount) * [math]::Log([math]::Max($operatorCount, 1) + [math]::Max($operandCount, 1)), 1)
    
    # Calculate maintainability index (Microsoft formula)
    $maintainabilityIndex = [math]::Max(0, (171 - 5.2 * [math]::Log($halsteadVolume) - 0.23 * $cyclomaticComplexity - 16.2 * [math]::Log([math]::Max($nonEmptyLines, 1))) * 100 / 171)
    
    return [PSCustomObject]@{
        FilePath = $FilePath
        LineCount = $lineCount
        NonEmptyLines = $nonEmptyLines
        CyclomaticComplexity = $cyclomaticComplexity
        HalsteadVolume = [math]::Round($halsteadVolume, 2)
        MaintainabilityIndex = [math]::Round($maintainabilityIndex, 2)
        FunctionCount = $functionCount
        ComplexityPerFunction = if ($functionCount -gt 0) { [math]::Round($cyclomaticComplexity / $functionCount, 2) } else { 0 }
    }
}

function Get-ViolationCategory {
    <#
    .SYNOPSIS
        Categorizes PSScriptAnalyzer violations based on rule type.
    #>
    param([string]$RuleName)
    
    switch -Regex ($RuleName) {
        'Security|Credential|Secret' { return 'Security' }
        'Performance|Efficiency' { return 'Performance' }
        'Maintainability|Readability' { return 'Maintainability' }
        'Compatibility|Version' { return 'Compatibility' }
        'Style|Format' { return 'Style' }
        default { return 'General' }
    }
}

function Get-DebtCosts {
    <#
    .SYNOPSIS
        Calculates remediation and non-remediation costs based on SQALE model.
    #>
    param(
        $Violation,
        $Complexity,
        [int]$LineCount
    )
    
    # Base remediation time (minutes) based on severity and complexity
    $baseTime = switch ($Violation.Severity.ToString()) {
        'Error' { 30 }
        'Warning' { 15 }
        'Information' { 5 }
        default { 10 }
    }
    
    # Adjust based on file complexity
    $complexityMultiplier = 1 + ([math]::Min($Complexity.CyclomaticComplexity, 30) / 30)
    $sizeMultiplier = 1 + ([math]::Min($LineCount, 1000) / 1000)
    
    $remediationCost = $baseTime * $complexityMultiplier * $sizeMultiplier
    
    # Non-remediation cost (business impact) - simplified model
    $severityWeight = if ($script:DebtWeights.ContainsKey($Violation.Severity.ToString())) { $script:DebtWeights[$Violation.Severity.ToString()] } else { 0.5 }
    $nonRemediationCost = $remediationCost * $severityWeight * 2  # 2x multiplier for business impact
    
    $totalDebt = $remediationCost + $nonRemediationCost
    
    return [PSCustomObject]@{
        RemediationCost = [math]::Round($remediationCost, 2)
        NonRemediationCost = [math]::Round($nonRemediationCost, 2)
        TotalDebt = [math]::Round($totalDebt, 2)
    }
}

function Get-ComplexityDebtCosts {
    <#
    .SYNOPSIS
        Calculates debt costs for complexity-related issues.
    #>
    param($Complexity, [int]$LineCount)
    
    # Base time for complexity reduction (hours converted to minutes)
    $baseTime = ($Complexity.CyclomaticComplexity - $script:ComplexityThresholds.Medium) * 10
    
    # Size adjustment
    $sizeMultiplier = 1 + ([math]::Min($LineCount, 1000) / 1000)
    $remediationCost = $baseTime * $sizeMultiplier
    
    # Higher business impact for complexity issues
    $nonRemediationCost = $remediationCost * 3  # 3x multiplier for complexity impact
    
    return [PSCustomObject]@{
        RemediationCost = [math]::Round($remediationCost, 2)
        NonRemediationCost = [math]::Round($nonRemediationCost, 2)
        TotalDebt = [math]::Round($remediationCost + $nonRemediationCost, 2)
    }
}

function Get-DebtRecommendation {
    <#
    .SYNOPSIS
        Generates specific recommendations based on violation type.
    #>
    param($Violation)
    
    $recommendations = @{
        'PSAvoidUsingInvokeExpression' = 'Replace Invoke-Expression with safer alternatives like &, dot-sourcing, or switch statements'
        'PSAvoidGlobalVars' = 'Use function parameters, script scope, or module variables instead of global variables'
        'PSUseDeclaredVarsMoreThanAssignments' = 'Remove unused variables or add logic to use declared variables'
        'PSAvoidUsingCmdletAliases' = 'Replace aliases with full cmdlet names for better readability and maintenance'
        'PSReviewUnusedParameter' = 'Remove unused parameters or implement parameter validation/usage'
        'PSUseShouldProcessForStateChangingFunctions' = 'Add SupportsShouldProcess and WhatIf support for functions that modify system state'
        'PSProvideCommentHelp' = 'Add comment-based help with .SYNOPSIS, .DESCRIPTION, .PARAMETER, and .EXAMPLE'
    }
    
    return if ($recommendations.ContainsKey($Violation.RuleName)) { $recommendations[$Violation.RuleName] } else { "Review and fix according to PowerShell best practices" }
}

function Add-EvolutionContext {
    <#
    .SYNOPSIS
        Adds code evolution context to debt items for enhanced analysis.
    #>
    param([TechnicalDebtItem[]]$DebtItems, [string]$FilePath, [string]$BasePath)
    
    try {
        # Get churn data if evolution module is available
        if (Get-Command -Name "Get-CodeChurnMetrics" -ErrorAction SilentlyContinue) {
            $relativePath = $FilePath.Replace($BasePath, "").TrimStart('\')
            $churnData = Get-CodeChurnMetrics -Path $BasePath -FilePattern $relativePath
            
            if ($churnData) {
                $churnMetric = $churnData | Where-Object { $_.FilePath -like "*$relativePath*" } | Select-Object -First 1
                
                if ($churnMetric) {
                    # Adjust debt costs based on churn data
                    foreach ($debtItem in $DebtItems) {
                        $churnMultiplier = 1 + ([math]::Min($churnMetric.ChurnScore, 10) / 10)
                        $debtItem.RemediationCost *= $churnMultiplier
                        $debtItem.NonRemediationCost *= $churnMultiplier
                        $debtItem.TotalDebt = $debtItem.RemediationCost + $debtItem.NonRemediationCost
                    }
                    Write-Debug "[$ModuleName] Applied churn context - multiplier: $churnMultiplier"
                }
            }
        }
    }
    catch {
        Write-Debug "[$ModuleName] Evolution context integration failed: $($_.Exception.Message)"
    }
    
    return $DebtItems
}

function Get-DebtSummary {
    <#
    .SYNOPSIS
        Calculates aggregate technical debt metrics.
    #>
    param([TechnicalDebtItem[]]$DebtItems)
    
    if (-not $DebtItems -or $DebtItems.Count -eq 0) {
        return [PSCustomObject]@{
            TotalItems = 0
            TotalDebt = 0
            AverageDebt = 0
            RemediationHours = 0
            BusinessImpact = 0
        }
    }
    
    $totalDebt = ($DebtItems | Measure-Object TotalDebt -Sum).Sum
    $totalRemediation = ($DebtItems | Measure-Object RemediationCost -Sum).Sum
    $totalImpact = ($DebtItems | Measure-Object NonRemediationCost -Sum).Sum
    
    # Group by severity
    $severityGroups = $DebtItems | Group-Object Severity
    $severityBreakdown = @{}
    foreach ($group in $severityGroups) {
        $severityBreakdown[$group.Name] = @{
            Count = $group.Count
            TotalDebt = [math]::Round(($group.Group | Measure-Object TotalDebt -Sum).Sum, 2)
        }
    }
    
    return [PSCustomObject]@{
        TotalItems = $DebtItems.Count
        TotalDebt = [math]::Round($totalDebt, 2)
        AverageDebt = [math]::Round($totalDebt / $DebtItems.Count, 2)
        RemediationHours = [math]::Round($totalRemediation / 60, 2)  # Convert minutes to hours
        BusinessImpact = [math]::Round($totalImpact, 2)
        SeverityBreakdown = $severityBreakdown
        TopDebtItems = $DebtItems | Sort-Object TotalDebt -Descending | Select-Object -First 10
    }
}

function Format-DebtOutput {
    <#
    .SYNOPSIS
        Formats debt analysis output based on requested format.
    #>
    param($DebtItems, $Summary, $Format)
    
    switch ($Format) {
        'JSON' {
            return [PSCustomObject]@{
                Summary = $Summary
                DebtItems = $DebtItems
                GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            } | ConvertTo-Json -Depth 10
        }
        'Detailed' {
            return [PSCustomObject]@{
                Summary = $Summary
                AllDebtItems = $DebtItems
                TopDebtFiles = $DebtItems | Group-Object FilePath | Sort-Object { ($_.Group | Measure-Object TotalDebt -Sum).Sum } -Descending | Select-Object -First 10
            }
        }
        'Summary' {
            return $Summary
        }
    }
}

function Get-CodeSmells {
    <#
    .SYNOPSIS
        Enhanced code smell detection using PSScriptAnalyzer and custom heuristics.
        
    .DESCRIPTION
        Detects code smells using multiple approaches including PSScriptAnalyzer integration,
        custom PowerShell-specific smell detection, and research-validated patterns.
        Provides prioritized recommendations based on severity and impact analysis.
        
    .PARAMETER Path
        Path to analyze for code smells (file or directory)
        
    .PARAMETER Recursive
        Analyze subdirectories recursively
        
    .PARAMETER FilePattern
        Filter files by pattern (e.g., "*.ps1", "*.psm1")
        
    .PARAMETER IncludeCustomSmells
        Include custom PowerShell-specific smell detection beyond PSScriptAnalyzer
        
    .PARAMETER SeverityFilter
        Filter by severity levels: 'All', 'Critical', 'High', 'Medium', 'Low'
        
    .EXAMPLE
        $smells = Get-CodeSmells -Path ".\Modules" -Recursive -IncludeCustomSmells
        
    .EXAMPLE
        $smells = Get-CodeSmells -Path ".\Scripts" -SeverityFilter "Critical"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter()]
        [switch]$Recursive,
        
        [Parameter()]
        [string]$FilePattern = "*.ps*",
        
        [Parameter()]
        [switch]$IncludeCustomSmells,
        
        [Parameter()]
        [ValidateSet('All', 'Critical', 'High', 'Medium', 'Low')]
        [string]$SeverityFilter = 'All'
    )
    
    begin {
        Write-Debug "[$ModuleName] Get-CodeSmells: Starting code smell detection"
        
        # Use module-level PSScriptAnalyzer availability flag
        $psaAvailable = $script:PSScriptAnalyzerAvailable
        Write-Debug "[$ModuleName] Using PSScriptAnalyzer availability for smell detection: $psaAvailable"
    }
    
    process {
        try {
            # Get files to analyze using SAFE enumeration to prevent memory corruption
            $files = if ($Recursive) {
                Get-SafeChildItems -Path $Path -Filter $FilePattern -FilesOnly -MaxDepth 3
            } else {
                Get-SafeChildItems -Path $Path -Filter $FilePattern -FilesOnly -MaxDepth 1
            }
            
            if (-not $files) {
                Write-Warning "[$ModuleName] No files found matching pattern: $FilePattern"
                return @()
            }
            
            Write-Debug "[$ModuleName] Analyzing $($files.Count) files for code smells"
            
            $allSmells = @()
            $fileCount = 0
            
            foreach ($file in $files) {
                $fileCount++
                Write-Progress -Activity "Code Smell Detection" -Status "Processing $($file.Name)" -PercentComplete (($fileCount / $files.Count) * 100)
                
                $fileSmells = @()
                
                # PSScriptAnalyzer analysis
                if ($psaAvailable) {
                    $fileSmells += Get-PSASmells -FilePath $file.FullName
                }
                
                # Custom smell detection
                if ($IncludeCustomSmells) {
                    $fileSmells += Get-CustomSmells -FilePath $file.FullName
                }
                
                $allSmells += $fileSmells
            }
            
            Write-Progress -Activity "Code Smell Detection" -Completed
            
            # Filter by severity if requested
            if ($SeverityFilter -ne 'All') {
                $allSmells = $allSmells | Where-Object { $_.Priority -eq $SeverityFilter }
            }
            
            # Sort by priority and impact
            $sortedSmells = $allSmells | Sort-Object @{Expression={Get-SmellSortOrder -Priority $_.Priority}}, Impact -Descending
            
            Write-Debug "[$ModuleName] Detected $($sortedSmells.Count) code smells"
            return $sortedSmells
        }
        catch {
            Write-Error "[$ModuleName] Code smell detection failed: $($_.Exception.Message)"
            throw
        }
    }
}

function Get-PSASmells {
    <#
    .SYNOPSIS
        Gets code smells using PSScriptAnalyzer.
    #>
    param([string]$FilePath)
    
    $smells = @()
    
    try {
        $psaResults = Invoke-ScriptAnalyzer -Path $FilePath -ErrorAction SilentlyContinue
        
        foreach ($result in $psaResults) {
            $smell = [PSCustomObject]@{
                FilePath = $FilePath
                Type = "PSScriptAnalyzer"
                RuleName = $result.RuleName
                Severity = $result.Severity.ToString()
                Priority = Get-SmellPriority -Severity $result.Severity.ToString() -RuleName $result.RuleName
                Line = $result.Line
                Column = $result.Column
                Message = $result.Message
                Impact = Get-SmellImpact -RuleName $result.RuleName
                Recommendation = Get-DebtRecommendation -Violation $result
                Source = "PSScriptAnalyzer"
            }
            
            $smells += $smell
        }
    }
    catch {
        Write-Debug "[$ModuleName] PSScriptAnalyzer analysis failed for $FilePath`: $($_.Exception.Message)"
    }
    
    return $smells
}

function Get-CustomSmells {
    <#
    .SYNOPSIS
        Detects custom PowerShell-specific code smells not covered by PSScriptAnalyzer.
    #>
    param([string]$FilePath)
    
    $smells = @()
    
    try {
        $content = Get-Content -Path $FilePath -ErrorAction SilentlyContinue
        if (-not $content) { return $smells }
        
        # Define custom smell patterns based on research
        $customPatterns = @(
            @{
                Name = "LongParameterList"
                Pattern = 'param\s*\([^)]{200,}\)'
                Priority = "Medium"
                Impact = 6
                Message = "Function has an excessive number of parameters"
                Recommendation = "Consider using parameter objects or configuration hashtables"
            }
            @{
                Name = "DeepNesting"
                Pattern = '(\s{12,}if|\s{16,}foreach|\s{20,}while)'
                Priority = "High"
                Impact = 8
                Message = "Deep nesting detected - consider refactoring"
                Recommendation = "Extract nested logic into separate functions"
            }
            @{
                Name = "LargeFunction"
                Pattern = 'function\s+[\w-]+[^}]{1000,}'
                Priority = "High"
                Impact = 7
                Message = "Function is too large"
                Recommendation = "Break down into smaller, focused functions"
            }
            @{
                Name = "MagicNumbers"
                Pattern = '(?<![\w\$])\b(?!0|1|2|24|60|100|1000)\d{2,}\b(?![\w\.])'
                Priority = "Low"
                Impact = 3
                Message = "Magic numbers found - consider using named constants"
                Recommendation = "Replace magic numbers with named constants or configuration"
            }
            @{
                Name = "EmptyExceptionHandling"
                Pattern = 'catch\s*{[\s]*}'
                Priority = "Critical"
                Impact = 9
                Message = "Empty exception handling blocks"
                Recommendation = "Add proper exception handling with logging or re-throw"
            }
            @{
                Name = "HardcodedPaths"
                Pattern = '"C:\\.*"'
                Priority = "Medium"
                Impact = 5
                Message = "Hardcoded file paths detected"
                Recommendation = "Use relative paths or configuration-based paths"
            }
        )
        
        $lineNumber = 0
        foreach ($line in $content) {
            $lineNumber++
            
            foreach ($pattern in $customPatterns) {
                if ($line -match $pattern.Pattern) {
                    $smell = [PSCustomObject]@{
                        FilePath = $FilePath
                        Type = "CustomSmell"
                        RuleName = $pattern.Name
                        Severity = $pattern.Priority
                        Priority = $pattern.Priority
                        Line = $lineNumber
                        Column = 1
                        Message = $pattern.Message
                        Impact = $pattern.Impact
                        Recommendation = $pattern.Recommendation
                        Source = "Custom Detection"
                        MatchedText = $line.Trim()
                    }
                    
                    $smells += $smell
                }
            }
        }
    }
    catch {
        Write-Debug "[$ModuleName] Custom smell detection failed for $FilePath`: $($_.Exception.Message)"
    }
    
    return $smells
}

function Get-SmellPriority {
    <#
    .SYNOPSIS
        Converts PSScriptAnalyzer severity to priority levels.
    #>
    param([string]$Severity, [string]$RuleName)
    
    # Security issues are always critical
    if ($RuleName -match 'Security|Credential|Secret') {
        return "Critical"
    }
    
    switch ($Severity) {
        'Error' { return "High" }
        'Warning' { return "Medium" }
        'Information' { return "Low" }
        default { return "Low" }
    }
}

function Get-SmellImpact {
    <#
    .SYNOPSIS
        Calculates impact score for code smells (1-10 scale).
    #>
    param([string]$RuleName)
    
    $impactScores = @{
        'PSAvoidUsingInvokeExpression' = 9
        'PSAvoidGlobalVars' = 7
        'PSUseShouldProcessForStateChangingFunctions' = 8
        'PSAvoidUsingCmdletAliases' = 4
        'PSProvideCommentHelp' = 3
        'PSReviewUnusedParameter' = 2
        'PSUseDeclaredVarsMoreThanAssignments' = 2
    }
    
    return if ($impactScores.ContainsKey($RuleName)) { $impactScores[$RuleName] } else { 5 }  # Default medium impact
}

function Get-SmellSortOrder {
    <#
    .SYNOPSIS
        Gets numeric sort order for priority levels.
    #>
    param([string]$Priority)
    
    switch ($Priority) {
        'Critical' { return 1 }
        'High' { return 2 }
        'Medium' { return 3 }
        'Low' { return 4 }
        default { return 5 }
    }
}

function Get-MaintenancePrediction {
    <#
    .SYNOPSIS
        Generates maintenance predictions using machine learning and time series analysis.
        
    .DESCRIPTION
        Implements research-validated maintenance prediction using time series forecasting,
        trend analysis, and machine learning approaches. Combines technical debt trends,
        complexity evolution, and churn patterns to predict future maintenance needs.
        
    .PARAMETER Path
        Repository path to analyze for maintenance prediction
        
    .PARAMETER ForecastDays
        Number of days to forecast (default: 90)
        
    .PARAMETER PredictionModel
        Prediction model type: 'Trend', 'LinearRegression', 'Hybrid' (default: Hybrid)
        
    .PARAMETER IncludeDebtData
        Include technical debt trends in prediction model
        
    .PARAMETER IncludeEvolutionData
        Include code evolution data from git history
        
    .EXAMPLE
        $predictions = Get-MaintenancePrediction -Path "." -ForecastDays 60
        
    .EXAMPLE
        $predictions = Get-MaintenancePrediction -Path ".\Modules" -PredictionModel "LinearRegression"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter()]
        [int]$ForecastDays = 90,
        
        [Parameter()]
        [ValidateSet('Trend', 'LinearRegression', 'Hybrid')]
        [string]$PredictionModel = 'Hybrid',
        
        [Parameter()]
        [switch]$IncludeDebtData,
        
        [Parameter()]
        [switch]$IncludeEvolutionData
    )
    
    begin {
        Write-Debug "[$ModuleName] Get-MaintenancePrediction: Starting maintenance prediction analysis"
        $startTime = Get-Date
    }
    
    process {
        try {
            Write-Host "[$ModuleName] Gathering historical data for prediction model..." -ForegroundColor Cyan
            
            # Collect time series data
            $timeSeriesData = Get-MaintenanceTimeSeries -Path $Path -IncludeDebt $IncludeDebtData -IncludeEvolution $IncludeEvolutionData
            
            if (-not $timeSeriesData -or $timeSeriesData.Count -lt 3) {
                Write-Warning "[$ModuleName] Insufficient historical data for reliable prediction (need 3+ data points)"
                return @()
            }
            
            Write-Debug "[$ModuleName] Using $($timeSeriesData.Count) historical data points for prediction"
            
            # Generate predictions based on model type
            $predictions = switch ($PredictionModel) {
                'Trend' { Get-TrendBasedPredictions -TimeSeriesData $timeSeriesData -ForecastDays $ForecastDays }
                'LinearRegression' { Get-RegressionPredictions -TimeSeriesData $timeSeriesData -ForecastDays $ForecastDays }
                'Hybrid' { Get-HybridPredictions -TimeSeriesData $timeSeriesData -ForecastDays $ForecastDays }
            }
            
            # Enhance predictions with risk analysis
            $enhancedPredictions = Add-PredictionRiskAnalysis -Predictions $predictions -HistoricalData $timeSeriesData
            
            $duration = (Get-Date) - $startTime
            Write-Debug "[$ModuleName] Maintenance prediction completed in $($duration.TotalSeconds) seconds"
            
            return $enhancedPredictions
        }
        catch {
            Write-Error "[$ModuleName] Maintenance prediction failed: $($_.Exception.Message)"
            throw
        }
    }
}

function Get-MaintenanceTimeSeries {
    <#
    .SYNOPSIS
        Builds time series data for maintenance prediction.
    #>
    param([string]$Path, [bool]$IncludeDebt, [bool]$IncludeEvolution)
    
    $timeSeries = @()
    
    try {
        # Get data from different time periods (simplified approach using file modifications)
        $files = Get-SafeChildItems -Path $Path -Filter "*.ps*" -FilesOnly -MaxDepth 3
        
        if (-not $files) {
            Write-Warning "[$ModuleName] No PowerShell files found for time series analysis"
            return $timeSeries
        }
        
        # Group files by modification month for trend analysis
        $monthlyData = $files | Group-Object { $_.LastWriteTime.ToString("yyyy-MM") }
        
        foreach ($monthGroup in ($monthlyData | Sort-Object Name)) {
            $monthFiles = $monthGroup.Group
            $periodData = [PSCustomObject]@{
                Period = $monthGroup.Name
                Date = [datetime]::ParseExact("$($monthGroup.Name)-01", "yyyy-MM-dd", $null)
                FileCount = $monthFiles.Count
                TotalLines = 0
                AverageComplexity = 0
                TechnicalDebt = 0
                MaintenanceIndicators = @()
            }
            
            # Calculate metrics for this period
            $totalComplexity = 0
            $totalLines = 0
            
            foreach ($file in $monthFiles) {
                try {
                    $content = Get-Content -Path $file.FullName -ErrorAction SilentlyContinue
                    if ($content) {
                        $complexity = Get-FileComplexityMetrics -Content $content -FilePath $file.FullName
                        $totalComplexity += $complexity.CyclomaticComplexity
                        $totalLines += $complexity.LineCount
                    }
                }
                catch {
                    Write-Debug "[$ModuleName] Error processing $($file.FullName) in time series: $($_.Exception.Message)"
                }
            }
            
            $periodData.TotalLines = $totalLines
            $periodData.AverageComplexity = if ($monthFiles.Count -gt 0) { [math]::Round($totalComplexity / $monthFiles.Count, 2) } else { 0 }
            
            # Add technical debt data if requested
            if ($IncludeDebt) {
                try {
                    $debtSummary = Get-TechnicalDebt -Path $Path -OutputFormat "Summary" -ErrorAction SilentlyContinue
                    $periodData.TechnicalDebt = if ($debtSummary.TotalDebt) { $debtSummary.TotalDebt } else { 0 }
                }
                catch {
                    Write-Debug "[$ModuleName] Could not get debt data for period $($monthGroup.Name)"
                }
            }
            
            # Add maintenance indicators
            $periodData.MaintenanceIndicators += if ($periodData.AverageComplexity -gt 15) { "HighComplexity" } else { $null }
            $periodData.MaintenanceIndicators += if ($periodData.TotalLines -gt 10000) { "LargeCodebase" } else { $null }
            $periodData.MaintenanceIndicators = $periodData.MaintenanceIndicators | Where-Object { $_ -ne $null }
            
            $timeSeries += $periodData
        }
        
        Write-Debug "[$ModuleName] Built time series with $($timeSeries.Count) data points"
        return $timeSeries
    }
    catch {
        Write-Debug "[$ModuleName] Time series building failed: $($_.Exception.Message)"
        return @()
    }
}

function Get-TrendBasedPredictions {
    <#
    .SYNOPSIS
        Generates predictions based on simple trend analysis.
    #>
    param($TimeSeriesData, [int]$ForecastDays)
    
    $predictions = @()
    
    if ($TimeSeriesData.Count -lt 2) {
        return $predictions
    }
    
    # Calculate trends for key metrics
    $complexityTrend = Get-MetricTrend -Data $TimeSeriesData -Metric "AverageComplexity"
    $sizeTrend = Get-MetricTrend -Data $TimeSeriesData -Metric "TotalLines"
    
    # Generate predictions for next periods
    $currentDate = Get-Date
    $forecastMonths = [math]::Ceiling($ForecastDays / 30)
    
    for ($i = 1; $i -le $forecastMonths; $i++) {
        $targetDate = $currentDate.AddDays($i * 30)
        
        # Simple linear extrapolation
        $predictedComplexity = $TimeSeriesData[-1].AverageComplexity + ($complexityTrend * $i)
        $predictedSize = $TimeSeriesData[-1].TotalLines + ($sizeTrend * $i)
        
        $prediction = [MaintenancePrediction]::new()
        $prediction.FilePath = "Repository"
        $prediction.PredictionType = "TrendBased"
        $prediction.PredictedDate = $targetDate
        $prediction.Confidence = [math]::Max(0.3, 0.8 - ($i * 0.1))  # Decreasing confidence over time
        $prediction.Priority = Get-MaintenancePriority -Complexity $predictedComplexity -Size $predictedSize
        $prediction.RecommendedAction = Get-MaintenanceAction -Priority $prediction.Priority
        $prediction.Metrics["PredictedComplexity"] = [math]::Round($predictedComplexity, 2)
        $prediction.Metrics["PredictedSize"] = [math]::Round($predictedSize, 2)
        $prediction.Indicators += "TrendAnalysis"
        
        $predictions += $prediction
    }
    
    return $predictions
}

function Get-MetricTrend {
    <#
    .SYNOPSIS
        Calculates linear trend for a specific metric.
    #>
    param($Data, [string]$Metric)
    
    if ($Data.Count -lt 2) { return 0 }
    
    # Simple linear trend calculation
    $values = $Data | ForEach-Object { $_.$Metric }
    $firstValue = $values[0]
    $lastValue = $values[-1]
    $periods = $Data.Count - 1
    
    return ($lastValue - $firstValue) / $periods
}

function Get-MaintenancePriority {
    <#
    .SYNOPSIS
        Determines maintenance priority based on predicted metrics.
    #>
    param([double]$Complexity, [double]$Size)
    
    if ($Complexity -gt 25 -or $Size -gt 50000) {
        return "Critical"
    }
    elseif ($Complexity -gt 20 -or $Size -gt 30000) {
        return "High"
    }
    elseif ($Complexity -gt 15 -or $Size -gt 20000) {
        return "Medium"
    }
    else {
        return "Low"
    }
}

function Get-MaintenanceAction {
    <#
    .SYNOPSIS
        Recommends maintenance actions based on priority.
    #>
    param([string]$Priority)
    
    switch ($Priority) {
        'Critical' { return "Immediate refactoring required - schedule within 2 weeks" }
        'High' { return "Plan refactoring within 1 month" }
        'Medium' { return "Schedule review and potential refactoring within 3 months" }
        'Low' { return "Monitor trends, no immediate action required" }
        default { return "Continue monitoring" }
    }
}

function Get-RegressionPredictions {
    <#
    .SYNOPSIS
        Generates predictions using linear regression approach.
    #>
    param($TimeSeriesData, [int]$ForecastDays)
    
    # Simplified linear regression for maintenance prediction
    # In production, this would use more sophisticated ML libraries
    
    $predictions = @()
    
    if ($TimeSeriesData.Count -lt 3) {
        Write-Warning "[$ModuleName] Insufficient data for regression analysis (need 3+ points)"
        return Get-TrendBasedPredictions -TimeSeriesData $TimeSeriesData -ForecastDays $ForecastDays
    }
    
    # Use trend-based approach as simplified regression
    # TODO: Implement proper regression when ML libraries are available
    $trendPredictions = Get-TrendBasedPredictions -TimeSeriesData $TimeSeriesData -ForecastDays $ForecastDays
    
    foreach ($prediction in $trendPredictions) {
        $prediction.PredictionType = "LinearRegression"
        $prediction.Confidence *= 0.9  # Slightly lower confidence for regression
        $prediction.Indicators += "RegressionAnalysis"
    }
    
    return $trendPredictions
}

function Get-HybridPredictions {
    <#
    .SYNOPSIS
        Generates predictions using hybrid approach combining multiple methods.
    #>
    param($TimeSeriesData, [int]$ForecastDays)
    
    # Combine trend and regression approaches for hybrid prediction
    $trendPredictions = Get-TrendBasedPredictions -TimeSeriesData $TimeSeriesData -ForecastDays $ForecastDays
    $regressionPredictions = Get-RegressionPredictions -TimeSeriesData $TimeSeriesData -ForecastDays $ForecastDays
    
    $hybridPredictions = @()
    
    for ($i = 0; $i -lt $trendPredictions.Count; $i++) {
        $trend = $trendPredictions[$i]
        $regression = if ($i -lt $regressionPredictions.Count) { $regressionPredictions[$i] } else { $trend }
        
        # Average the predictions
        $avgComplexity = ($trend.Metrics["PredictedComplexity"] + $regression.Metrics["PredictedComplexity"]) / 2
        $avgSize = ($trend.Metrics["PredictedSize"] + $regression.Metrics["PredictedSize"]) / 2
        $avgConfidence = ($trend.Confidence + $regression.Confidence) / 2
        
        $hybridPrediction = [MaintenancePrediction]::new()
        $hybridPrediction.FilePath = "Repository"
        $hybridPrediction.PredictionType = "Hybrid"
        $hybridPrediction.PredictedDate = $trend.PredictedDate
        $hybridPrediction.Confidence = [math]::Round($avgConfidence, 2)
        $hybridPrediction.Priority = Get-MaintenancePriority -Complexity $avgComplexity -Size $avgSize
        $hybridPrediction.RecommendedAction = Get-MaintenanceAction -Priority $hybridPrediction.Priority
        $hybridPrediction.Metrics["PredictedComplexity"] = [math]::Round($avgComplexity, 2)
        $hybridPrediction.Metrics["PredictedSize"] = [math]::Round($avgSize, 2)
        $hybridPrediction.Indicators += "HybridAnalysis"
        $hybridPrediction.Indicators += "TrendRegression"
        
        $hybridPredictions += $hybridPrediction
    }
    
    return $hybridPredictions
}

function Add-PredictionRiskAnalysis {
    <#
    .SYNOPSIS
        Enhances predictions with risk analysis and confidence adjustments.
    #>
    param($Predictions, $HistoricalData)
    
    foreach ($prediction in $Predictions) {
        # Calculate risk factors based on historical variance
        $complexityVariance = Get-MetricVariance -Data $HistoricalData -Metric "AverageComplexity"
        $sizeVariance = Get-MetricVariance -Data $HistoricalData -Metric "TotalLines"
        
        # Adjust confidence based on historical stability
        $stabilityFactor = 1 - ([math]::Min($complexityVariance + $sizeVariance, 1.0) / 2)
        $prediction.Confidence *= $stabilityFactor
        
        # Add risk indicators
        if ($complexityVariance -gt 5) {
            $prediction.Indicators += "HighComplexityVariance"
        }
        if ($sizeVariance -gt 1000) {
            $prediction.Indicators += "HighSizeVariance"
        }
        
        # Add maintenance window recommendations
        $daysUntil = ($prediction.PredictedDate - (Get-Date)).Days
        if ($daysUntil -le 30 -and $prediction.Priority -in @('Critical', 'High')) {
            $prediction.Indicators += "UrgentMaintenance"
            $prediction.RecommendedAction = "URGENT: " + $prediction.RecommendedAction
        }
    }
    
    return $Predictions
}

function Get-MetricVariance {
    <#
    .SYNOPSIS
        Calculates variance for a specific metric in time series data.
    #>
    param($Data, [string]$Metric)
    
    if ($Data.Count -lt 2) { return 0 }
    
    $values = $Data | ForEach-Object { $_.$Metric } | Where-Object { $_ -ne $null -and $_ -ne 0 }
    if (-not $values -or $values.Count -lt 2) { return 0 }
    
    # Simple variance calculation
    $mean = ($values | Measure-Object -Sum).Sum / $values.Count
    $variance = ($values | ForEach-Object { [math]::Pow($_ - $mean, 2) } | Measure-Object -Sum).Sum / ($values.Count - 1)
    
    return [math]::Round($variance, 2)
}

function Get-RefactoringRecommendations {
    <#
    .SYNOPSIS
        Generates prioritized refactoring recommendations with ROI analysis.
        
    .DESCRIPTION
        Combines technical debt analysis, code smell detection, and evolution data
        to create prioritized refactoring recommendations with ROI calculations
        based on research-validated multi-objective optimization approaches.
        
    .PARAMETER Path
        Repository path to analyze
        
    .PARAMETER MaxRecommendations
        Maximum number of recommendations to return (default: 20)
        
    .PARAMETER ROIThreshold
        Minimum ROI threshold for recommendations (default: 1.2)
        
    .PARAMETER IncludeEvolutionData
        Include code evolution data for enhanced ROI calculation
        
    .EXAMPLE
        $recommendations = Get-RefactoringRecommendations -Path ".\Modules" -MaxRecommendations 10
        
    .EXAMPLE
        $recommendations = Get-RefactoringRecommendations -Path "." -ROIThreshold 2.0 -IncludeEvolutionData
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter()]
        [int]$MaxRecommendations = 20,
        
        [Parameter()]
        [double]$ROIThreshold = 1.2,
        
        [Parameter()]
        [switch]$IncludeEvolutionData
    )
    
    begin {
        Write-Debug "[$ModuleName] Get-RefactoringRecommendations: Starting refactoring analysis"
    }
    
    process {
        try {
            Write-Host "[$ModuleName] Analyzing codebase for refactoring opportunities..." -ForegroundColor Cyan
            
            # Gather comprehensive analysis data
            Write-Progress -Activity "Refactoring Analysis" -Status "Analyzing technical debt" -PercentComplete 20
            $debtData = Get-TechnicalDebt -Path $Path -UseEvolutionData:$IncludeEvolutionData -OutputFormat "Detailed"
            
            Write-Progress -Activity "Refactoring Analysis" -Status "Detecting code smells" -PercentComplete 40
            $smellData = Get-CodeSmells -Path $Path -Recursive -IncludeCustomSmells
            
            Write-Progress -Activity "Refactoring Analysis" -Status "Getting hotspot data" -PercentComplete 60
            $hotspotData = @()
            if (Get-Command -Name "Get-FileHotspots" -ErrorAction SilentlyContinue) {
                $hotspotData = Get-FileHotspots -Path $Path
            }
            
            Write-Progress -Activity "Refactoring Analysis" -Status "Calculating ROI" -PercentComplete 80
            
            # Build refactoring recommendations
            $recommendations = @()
            $fileGroups = @{}
            
            # Group issues by file for comprehensive analysis
            foreach ($debt in $debtData.AllDebtItems) {
                $file = $debt.FilePath
                if (-not $fileGroups.ContainsKey($file)) {
                    $fileGroups[$file] = @{
                        DebtItems = @()
                        CodeSmells = @()
                        HotspotData = $null
                    }
                }
                $fileGroups[$file].DebtItems += $debt
            }
            
            foreach ($smell in $smellData) {
                $file = $smell.FilePath
                if ($fileGroups.ContainsKey($file)) {
                    $fileGroups[$file].CodeSmells += $smell
                }
            }
            
            # Add hotspot data
            foreach ($hotspot in $hotspotData) {
                $file = $hotspot.FilePath
                if ($fileGroups.ContainsKey($file)) {
                    $fileGroups[$file].HotspotData = $hotspot
                }
            }
            
            # Generate recommendations for each file
            foreach ($file in $fileGroups.Keys) {
                $fileData = $fileGroups[$file]
                $recommendation = New-FileRefactoringRecommendation -FilePath $file -FileData $fileData
                
                # Filter by ROI threshold
                if ($recommendation.ROI -ge $ROIThreshold) {
                    $recommendations += $recommendation
                }
            }
            
            Write-Progress -Activity "Refactoring Analysis" -Completed
            
            # Sort by ROI and return top recommendations
            $sortedRecommendations = $recommendations | Sort-Object ROI -Descending | Select-Object -First $MaxRecommendations
            
            Write-Debug "[$ModuleName] Generated $($sortedRecommendations.Count) refactoring recommendations"
            return $sortedRecommendations
        }
        catch {
            Write-Error "[$ModuleName] Refactoring recommendation generation failed: $($_.Exception.Message)"
            throw
        }
    }
}

function New-FileRefactoringRecommendation {
    <#
    .SYNOPSIS
        Creates a refactoring recommendation for a specific file.
    #>
    param([string]$FilePath, $FileData)
    
    $recommendation = [RefactoringRecommendation]::new()
    $recommendation.FilePath = $FilePath
    
    # Calculate total issues and costs
    $totalDebt = ($FileData.DebtItems | Measure-Object TotalDebt -Sum).Sum
    $criticalSmells = ($FileData.CodeSmells | Where-Object { $_.Priority -eq 'Critical' }).Count
    $highPriorityIssues = ($FileData.CodeSmells | Where-Object { $_.Priority -in @('Critical', 'High') }).Count
    
    # Determine refactoring type and scope
    if ($criticalSmells -gt 0 -or $totalDebt -gt 200) {
        $recommendation.RefactoringType = "Major"
        $recommendation.EstimatedCost = $totalDebt * 1.5  # Major refactoring overhead
        $recommendation.Timeline = "2-4 weeks"
    }
    elseif ($highPriorityIssues -gt 3 -or $totalDebt -gt 100) {
        $recommendation.RefactoringType = "Moderate"
        $recommendation.EstimatedCost = $totalDebt * 1.2
        $recommendation.Timeline = "1-2 weeks"
    }
    else {
        $recommendation.RefactoringType = "Minor"
        $recommendation.EstimatedCost = $totalDebt
        $recommendation.Timeline = "2-5 days"
    }
    
    # Calculate estimated benefits
    $maintainabilityBenefit = $totalDebt * 0.7  # 70% debt reduction
    $productivityBenefit = $highPriorityIssues * 20  # 20 minutes saved per high-priority issue
    $qualityBenefit = $criticalSmells * 50  # 50 minutes saved per critical smell
    
    # Add hotspot benefits
    $hotspotBenefit = 0
    if ($FileData.HotspotData) {
        $hotspotBenefit = $FileData.HotspotData.HotspotScore * 10
    }
    
    $recommendation.EstimatedBenefit = $maintainabilityBenefit + $productivityBenefit + $qualityBenefit + $hotspotBenefit
    
    # Calculate ROI
    $recommendation.ROI = if ($recommendation.EstimatedCost -gt 0) { 
        [math]::Round($recommendation.EstimatedBenefit / $recommendation.EstimatedCost, 2) 
    } else { 0 }
    
    # Determine priority
    $recommendation.Priority = if ($recommendation.ROI -gt 3.0) { "Critical" }
                              elseif ($recommendation.ROI -gt 2.0) { "High" }
                              elseif ($recommendation.ROI -gt 1.5) { "Medium" }
                              else { "Low" }
    
    # Generate description
    $issueCount = $FileData.DebtItems.Count + $FileData.CodeSmells.Count
    $recommendation.Description = "File has $issueCount issues requiring $($recommendation.RefactoringType.ToLower()) refactoring (ROI: $($recommendation.ROI))"
    
    # Add metrics
    $recommendation.Metrics["TotalDebt"] = [math]::Round($totalDebt, 2)
    $recommendation.Metrics["CriticalSmells"] = $criticalSmells
    $recommendation.Metrics["HighPriorityIssues"] = $highPriorityIssues
    $recommendation.Metrics["EstimatedHours"] = [math]::Round($recommendation.EstimatedCost / 60, 2)
    
    return $recommendation
}

function New-MaintenanceReport {
    <#
    .SYNOPSIS
        Creates comprehensive maintenance report combining all analysis types.
        
    .DESCRIPTION
        Generates a complete maintenance analysis report including technical debt,
        code smells, maintenance predictions, and refactoring recommendations.
        Implements research-validated reporting with multi-format output support.
        
    .PARAMETER Path
        Repository path to analyze
        
    .PARAMETER OutputPath
        Path to save the report (optional)
        
    .PARAMETER Format
        Report format: 'Text', 'JSON', 'HTML' (default: Text)
        
    .PARAMETER ForecastDays
        Number of days for maintenance predictions (default: 90)
        
    .PARAMETER IncludeEvolutionData
        Include git evolution data for enhanced analysis
        
    .EXAMPLE
        New-MaintenanceReport -Path "." -OutputPath "maintenance-report.txt"
        
    .EXAMPLE
        New-MaintenanceReport -Path ".\Modules" -Format "JSON" -ForecastDays 60
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter()]
        [string]$OutputPath = $null,
        
        [Parameter()]
        [ValidateSet('Text', 'JSON', 'HTML')]
        [string]$Format = 'Text',
        
        [Parameter()]
        [int]$ForecastDays = 90,
        
        [Parameter()]
        [switch]$IncludeEvolutionData
    )
    
    begin {
        Write-Debug "[$ModuleName] New-MaintenanceReport: Starting comprehensive maintenance analysis"
        $startTime = Get-Date
    }
    
    process {
        try {
            Write-Host "[$ModuleName] Generating comprehensive maintenance report..." -ForegroundColor Cyan
            
            # Gather all analysis data
            Write-Progress -Activity "Maintenance Report" -Status "Analyzing technical debt" -PercentComplete 15
            $technicalDebt = Get-TechnicalDebt -Path $Path -Recursive -UseEvolutionData:$IncludeEvolutionData -OutputFormat "Detailed"
            
            Write-Progress -Activity "Maintenance Report" -Status "Detecting code smells" -PercentComplete 30
            $codeSmells = Get-CodeSmells -Path $Path -Recursive -IncludeCustomSmells
            
            Write-Progress -Activity "Maintenance Report" -Status "Generating maintenance predictions" -PercentComplete 50
            $maintenancePredictions = Get-MaintenancePrediction -Path $Path -ForecastDays $ForecastDays -IncludeEvolutionData:$IncludeEvolutionData
            
            Write-Progress -Activity "Maintenance Report" -Status "Creating refactoring recommendations" -PercentComplete 70
            $refactoringRecommendations = Get-RefactoringRecommendations -Path $Path -IncludeEvolutionData:$IncludeEvolutionData
            
            Write-Progress -Activity "Maintenance Report" -Status "Compiling report" -PercentComplete 85
            
            # Create comprehensive report
            $report = [PSCustomObject]@{
                Metadata = [PSCustomObject]@{
                    GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    RepositoryPath = $Path
                    AnalysisScope = "Comprehensive Maintenance Analysis"
                    ForecastPeriod = "$ForecastDays days"
                    ModuleVersion = $ModuleVersion
                    EvolutionDataIncluded = [bool]$IncludeEvolutionData
                }
                ExecutiveSummary = [PSCustomObject]@{
                    TotalTechnicalDebt = $technicalDebt.Summary.TotalDebt
                    EstimatedRemediationHours = $technicalDebt.Summary.RemediationHours
                    CriticalCodeSmells = ($codeSmells | Where-Object { $_.Priority -eq 'Critical' }).Count
                    HighROIRefactorings = ($refactoringRecommendations | Where-Object { $_.ROI -gt 2.0 }).Count
                    UrgentMaintenanceItems = ($maintenancePredictions | Where-Object { $_.Indicators -contains "UrgentMaintenance" }).Count
                    OverallHealthScore = Get-RepositoryHealthScore -DebtSummary $technicalDebt.Summary -SmellCount $codeSmells.Count
                }
                TechnicalDebtAnalysis = $technicalDebt
                CodeSmellsDetection = @{
                    Summary = [PSCustomObject]@{
                        TotalSmells = $codeSmells.Count
                        CriticalCount = ($codeSmells | Where-Object { $_.Priority -eq 'Critical' }).Count
                        HighCount = ($codeSmells | Where-Object { $_.Priority -eq 'High' }).Count
                        MediumCount = ($codeSmells | Where-Object { $_.Priority -eq 'Medium' }).Count
                        LowCount = ($codeSmells | Where-Object { $_.Priority -eq 'Low' }).Count
                    }
                    DetailedSmells = $codeSmells | Select-Object -First 50
                }
                MaintenancePredictions = $maintenancePredictions
                RefactoringRecommendations = $refactoringRecommendations
                ActionPlan = Get-MaintenanceActionPlan -Predictions $maintenancePredictions -Recommendations $refactoringRecommendations
            }
            
            Write-Progress -Activity "Maintenance Report" -Completed
            
            # Format and output report
            $formattedReport = Format-MaintenanceReport -Report $report -Format $Format
            
            if ($OutputPath) {
                $formattedReport | Out-File -FilePath $OutputPath -Encoding UTF8
                Write-Host "[$ModuleName] Maintenance report saved to: $OutputPath" -ForegroundColor Green
            }
            
            $duration = (Get-Date) - $startTime
            Write-Host "[$ModuleName] Maintenance report generated in $($duration.TotalSeconds) seconds" -ForegroundColor Green
            
            return $report
        }
        catch {
            Write-Error "[$ModuleName] Maintenance report generation failed: $($_.Exception.Message)"
            throw
        }
    }
}

function Get-RepositoryHealthScore {
    <#
    .SYNOPSIS
        Calculates overall repository health score (0-100).
    #>
    param($DebtSummary, [int]$SmellCount)
    
    # Base score
    $healthScore = 100
    
    # Deduct points for technical debt
    $debtPenalty = [math]::Min($DebtSummary.TotalDebt / 10, 50)  # Max 50 point penalty
    $healthScore -= $debtPenalty
    
    # Deduct points for code smells
    $smellPenalty = [math]::Min($SmellCount * 2, 30)  # Max 30 point penalty
    $healthScore -= $smellPenalty
    
    # Deduct points for high remediation hours
    $timePenalty = [math]::Min($DebtSummary.RemediationHours / 2, 20)  # Max 20 point penalty
    $healthScore -= $timePenalty
    
    return [math]::Round([math]::Max($healthScore, 0), 1)
}

function Get-MaintenanceActionPlan {
    <#
    .SYNOPSIS
        Creates prioritized action plan based on predictions and recommendations.
    #>
    param($Predictions, $Recommendations)
    
    $actionPlan = [PSCustomObject]@{
        ImmediateActions = @()
        ShortTermActions = @()
        LongTermActions = @()
        MonitoringItems = @()
    }
    
    # Process urgent predictions
    $urgentPredictions = $Predictions | Where-Object { $_.Indicators -contains "UrgentMaintenance" }
    foreach ($urgent in $urgentPredictions) {
        $actionPlan.ImmediateActions += [PSCustomObject]@{
            Type = "MaintenancePrediction"
            Description = $urgent.RecommendedAction
            Priority = $urgent.Priority
            Confidence = $urgent.Confidence
            DueDate = $urgent.PredictedDate
        }
    }
    
    # Process high ROI refactoring recommendations
    $highROI = $Recommendations | Where-Object { $_.ROI -gt 2.0 } | Sort-Object ROI -Descending | Select-Object -First 5
    foreach ($refactoring in $highROI) {
        $targetList = switch ($refactoring.Priority) {
            'Critical' { $actionPlan.ImmediateActions }
            'High' { $actionPlan.ShortTermActions }
            default { $actionPlan.LongTermActions }
        }
        
        $targetList += [PSCustomObject]@{
            Type = "Refactoring"
            Description = "$($refactoring.RefactoringType) refactoring of $($refactoring.FilePath) (ROI: $($refactoring.ROI))"
            EstimatedHours = $refactoring.Metrics["EstimatedHours"]
            Timeline = $refactoring.Timeline
            ROI = $refactoring.ROI
        }
    }
    
    # Add monitoring items for lower priority items
    $monitoringItems = $Predictions | Where-Object { $_.Priority -eq 'Low' }
    foreach ($item in $monitoringItems) {
        $actionPlan.MonitoringItems += [PSCustomObject]@{
            Description = "Monitor $($item.FilePath) for maintenance trends"
            NextReview = (Get-Date).AddDays(60)
            Metrics = $item.Metrics
        }
    }
    
    return $actionPlan
}

function Format-MaintenanceReport {
    <#
    .SYNOPSIS
        Formats maintenance report based on requested output format.
    #>
    param($Report, $Format)
    
    switch ($Format) {
        'JSON' {
            return ($Report | ConvertTo-Json -Depth 10)
        }
        'HTML' {
            # Enhanced HTML format
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Maintenance Analysis Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .summary { background: #f0f8ff; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
        .critical { color: #d32f2f; font-weight: bold; }
        .high { color: #f57c00; font-weight: bold; }
        .medium { color: #fbc02d; }
        .low { color: #388e3c; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Maintenance Analysis Report</h1>
    <div class="summary">
        <h2>Executive Summary</h2>
        <p><strong>Generated:</strong> $($Report.Metadata.GeneratedAt)</p>
        <p><strong>Repository:</strong> $($Report.Metadata.RepositoryPath)</p>
        <p><strong>Overall Health Score:</strong> $($Report.ExecutiveSummary.OverallHealthScore)/100</p>
        <p><strong>Total Technical Debt:</strong> $($Report.ExecutiveSummary.TotalTechnicalDebt) minutes</p>
        <p><strong>Critical Issues:</strong> $($Report.ExecutiveSummary.CriticalCodeSmells)</p>
    </div>
    <h2>Action Plan</h2>
    <pre>$($Report.ActionPlan | ConvertTo-Json -Depth 5)</pre>
</body>
</html>
"@
            return $html
        }
        'Text' {
            $text = @"
MAINTENANCE ANALYSIS REPORT
===========================
Generated: $($Report.Metadata.GeneratedAt)
Repository: $($Report.Metadata.RepositoryPath)
Forecast Period: $($Report.Metadata.ForecastPeriod)

EXECUTIVE SUMMARY
-----------------
Overall Health Score: $($Report.ExecutiveSummary.OverallHealthScore)/100
Total Technical Debt: $($Report.ExecutiveSummary.TotalTechnicalDebt) minutes ($($Report.ExecutiveSummary.EstimatedRemediationHours) hours)
Critical Code Smells: $($Report.ExecutiveSummary.CriticalCodeSmells)
High ROI Refactoring Opportunities: $($Report.ExecutiveSummary.HighROIRefactorings)
Urgent Maintenance Items: $($Report.ExecutiveSummary.UrgentMaintenanceItems)

TOP REFACTORING RECOMMENDATIONS
-------------------------------
$($Report.RefactoringRecommendations | Select-Object -First 10 | Format-Table FilePath, RefactoringType, ROI, Priority -AutoSize | Out-String)

MAINTENANCE PREDICTIONS
-----------------------
$($Report.MaintenancePredictions | Format-Table PredictedDate, Priority, RecommendedAction, Confidence -AutoSize | Out-String)

ACTION PLAN
-----------
Immediate Actions: $($Report.ActionPlan.ImmediateActions.Count)
Short Term Actions: $($Report.ActionPlan.ShortTermActions.Count)  
Long Term Actions: $($Report.ActionPlan.LongTermActions.Count)
Monitoring Items: $($Report.ActionPlan.MonitoringItems.Count)
"@
            return $text
        }
    }
}

function Invoke-PSScriptAnalyzerEnhanced {
    <#
    .SYNOPSIS
        Enhanced PSScriptAnalyzer wrapper with additional analysis and reporting.
        
    .DESCRIPTION
        Wraps PSScriptAnalyzer with enhanced reporting, custom rules integration,
        and technical debt calculation based on research findings.
        
    .PARAMETER Path
        Path to analyze
        
    .PARAMETER IncludeDefaultRules
        Include default PSScriptAnalyzer rules (default: true)
        
    .PARAMETER CustomRulePath
        Path to custom rule definitions
        
    .PARAMETER OutputFormat
        Output format: 'Standard', 'Enhanced', 'JSON'
        
    .EXAMPLE
        $results = Invoke-PSScriptAnalyzerEnhanced -Path ".\Module.psm1"
        
    .EXAMPLE  
        $results = Invoke-PSScriptAnalyzerEnhanced -Path ".\Scripts" -OutputFormat "Enhanced"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter()]
        [bool]$IncludeDefaultRules = $true,
        
        [Parameter()]
        [string]$CustomRulePath = $null,
        
        [Parameter()]
        [ValidateSet('Standard', 'Enhanced', 'JSON')]
        [string]$OutputFormat = 'Enhanced'
    )
    
    begin {
        Write-Debug "[$ModuleName] Invoke-PSScriptAnalyzerEnhanced: Starting enhanced analysis"
        
        # Use module-level PSScriptAnalyzer availability
        if (-not $script:PSScriptAnalyzerAvailable) {
            throw "PSScriptAnalyzer module is required but not available (verified at module load)"
        }
        Write-Debug "[$ModuleName] Using verified PSScriptAnalyzer availability for enhanced analysis"
    }
    
    process {
        try {
            # Build analysis parameters
            $analyzerParams = @{
                Path = $Path
                Recurse = $true
                ErrorAction = 'SilentlyContinue'
            }
            
            # Add custom rules if provided
            if ($CustomRulePath -and (Test-Path -Path $CustomRulePath)) {
                $analyzerParams.CustomRulePath = $CustomRulePath
            }
            
            # Run PSScriptAnalyzer
            $psaResults = Invoke-ScriptAnalyzer @analyzerParams
            
            # Enhance results based on output format
            switch ($OutputFormat) {
                'Standard' {
                    return $psaResults
                }
                'Enhanced' {
                    return Get-EnhancedAnalysisResults -PSAResults $psaResults -BasePath $Path
                }
                'JSON' {
                    return ($psaResults | ConvertTo-Json -Depth 5)
                }
            }
        }
        catch {
            Write-Error "[$ModuleName] Enhanced PSScriptAnalyzer analysis failed: $($_.Exception.Message)"
            throw
        }
    }
}

function Get-EnhancedAnalysisResults {
    <#
    .SYNOPSIS
        Enhances PSScriptAnalyzer results with additional context and metrics.
    #>
    param($PSAResults, [string]$BasePath)
    
    $enhancedResults = @()
    
    # Group results by file for comprehensive analysis
    $fileGroups = $PSAResults | Group-Object ScriptPath
    
    foreach ($fileGroup in $fileGroups) {
        $filePath = $fileGroup.Name
        $violations = $fileGroup.Group
        
        # Get file complexity metrics
        try {
            $content = Get-Content -Path $filePath -ErrorAction SilentlyContinue
            $complexity = if ($content) { 
                Get-FileComplexityMetrics -Content $content -FilePath $filePath 
            } else { 
                [PSCustomObject]@{ CyclomaticComplexity = 0; MaintainabilityIndex = 100 } 
            }
        }
        catch {
            $complexity = [PSCustomObject]@{ CyclomaticComplexity = 0; MaintainabilityIndex = 100 }
        }
        
        # Create enhanced file analysis
        $fileAnalysis = [PSCustomObject]@{
            FilePath = $filePath
            RelativePath = $filePath.Replace($BasePath, "").TrimStart('\')
            ViolationCount = $violations.Count
            SeverityBreakdown = @{
                Error = ($violations | Where-Object { $_.Severity -eq 'Error' }).Count
                Warning = ($violations | Where-Object { $_.Severity -eq 'Warning' }).Count
                Information = ($violations | Where-Object { $_.Severity -eq 'Information' }).Count
            }
            ComplexityMetrics = $complexity
            HealthScore = Get-FileHealthScore -Violations $violations -Complexity $complexity
            TopViolations = $violations | Sort-Object Severity | Select-Object -First 5
            RecommendedActions = Get-FileRecommendations -Violations $violations -Complexity $complexity
        }
        
        $enhancedResults += $fileAnalysis
    }
    
    # Sort by health score (worst first)
    return $enhancedResults | Sort-Object HealthScore
}

function Get-FileHealthScore {
    <#
    .SYNOPSIS
        Calculates health score for individual files (0-100).
    #>
    param($Violations, $Complexity)
    
    $score = 100
    
    # Penalty for violations
    $errorPenalty = ($Violations | Where-Object { $_.Severity -eq 'Error' }).Count * 15
    $warningPenalty = ($Violations | Where-Object { $_.Severity -eq 'Warning' }).Count * 5
    $infoPenalty = ($Violations | Where-Object { $_.Severity -eq 'Information' }).Count * 1
    
    $score -= ($errorPenalty + $warningPenalty + $infoPenalty)
    
    # Penalty for complexity
    if ($Complexity.CyclomaticComplexity -gt 20) {
        $score -= 20
    }
    elseif ($Complexity.CyclomaticComplexity -gt 10) {
        $score -= 10
    }
    
    # Bonus for high maintainability
    if ($Complexity.MaintainabilityIndex -gt 80) {
        $score += 5
    }
    
    return [math]::Round([math]::Max($score, 0), 1)
}

function Get-FileRecommendations {
    <#
    .SYNOPSIS
        Generates specific recommendations for file improvement.
    #>
    param($Violations, $Complexity)
    
    $recommendations = @()
    
    # Complexity recommendations
    if ($Complexity.CyclomaticComplexity -gt 15) {
        $recommendations += "Reduce cyclomatic complexity by breaking down complex functions"
    }
    
    # Violation-based recommendations
    $securityViolations = $Violations | Where-Object { $_.RuleName -match 'Security|Credential' }
    if ($securityViolations) {
        $recommendations += "Address security violations immediately"
    }
    
    $performanceViolations = $Violations | Where-Object { $_.RuleName -match 'Performance' }
    if ($performanceViolations) {
        $recommendations += "Optimize performance-related issues"
    }
    
    if ($Complexity.MaintainabilityIndex -lt 20) {
        $recommendations += "Improve maintainability through refactoring"
    }
    
    return $recommendations
}

#endregion

#region LangGraph Integration Functions

function Submit-MaintenanceAnalysisToLangGraph {
    <#
    .SYNOPSIS
        Submits maintenance analysis data to LangGraph for AI-enhanced processing.
    .DESCRIPTION
        Integrates maintenance prediction analysis with LangGraph orchestrator-worker workflows
        for AI-enhanced insights, recommendations, and strategic planning.
    .PARAMETER MaintenanceData
        Output from Get-MaintenancePrediction or related analysis functions
    .PARAMETER WorkflowType
        Type of LangGraph workflow: 'maintenance_prediction_enhancement' (default), 'unified_analysis_orchestration'
    .PARAMETER EnhancementConfig
        Configuration for AI enhancement including analysis depth and focus areas
    .EXAMPLE
        $maintenance = Get-MaintenancePrediction -Path ".\Scripts"
        $enhanced = Submit-MaintenanceAnalysisToLangGraph -MaintenanceData $maintenance
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$MaintenanceData,
        
        [Parameter()]
        [ValidateSet('maintenance_prediction_enhancement', 'unified_analysis_orchestration')]
        [string]$WorkflowType = 'maintenance_prediction_enhancement',
        
        [Parameter()]
        [hashtable]$EnhancementConfig = @{
            analysis_depth = 'comprehensive'
            focus_areas = @('technical_debt', 'refactoring_roi', 'risk_assessment')
            ai_enhancement = $true
            generate_strategic_plan = $true
        }
    )
    
    Write-Debug "[$ModuleName] Submitting maintenance analysis to LangGraph - Workflow: $WorkflowType"
    
    try {
        # Import LangGraph bridge module
        Import-Module -Path "..\..\..\Unity-Claude-LangGraphBridge.psm1" -Force -ErrorAction Stop
        Write-Debug "[$ModuleName] LangGraph bridge module imported successfully"
        
        # Prepare workflow input data
        $workflowInput = @{
            maintenance_data = $MaintenanceData
            sqale_metrics = if ($MaintenanceData.DebtAnalysis) { $MaintenanceData.DebtAnalysis } else { @{} }
            code_smell_results = if ($MaintenanceData.CodeSmells) { $MaintenanceData.CodeSmells } else { @() }
            enhancement_config = $EnhancementConfig
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            module_version = $ModuleVersion
        }
        
        Write-Debug "[$ModuleName] Workflow input prepared with $($workflowInput.Keys.Count) data elements"
        
        # Create LangGraph workflow
        $graphId = "maintenance-analysis-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        $graph = New-LangGraph -GraphId $graphId -GraphType $WorkflowType
        
        if (-not $graph -or $graph.status -ne 'created') {
            throw "Failed to create LangGraph workflow: $($graph.error)"
        }
        
        Write-Debug "[$ModuleName] LangGraph created successfully - ID: $graphId"
        
        # Submit workflow for execution
        $execution = Start-LangGraphExecution -GraphId $graphId -InputData $workflowInput
        
        if (-not $execution -or $execution.status -eq 'error') {
            throw "Failed to start LangGraph execution: $($execution.error)"
        }
        
        Write-Debug "[$ModuleName] LangGraph execution started - Thread: $($execution.thread_id)"
        
        # Wait for completion with timeout
        $timeout = 300  # 5 minutes
        $completed = $false
        $startTime = Get-Date
        
        do {
            Start-Sleep -Seconds 5
            $threadInfo = Get-LangGraphThread -ThreadId $execution.thread_id
            
            if ($threadInfo.info.status -eq 'completed') {
                $completed = $true
                Write-Debug "[$ModuleName] LangGraph workflow completed successfully"
                break
            }
            elseif ($threadInfo.info.status -eq 'error') {
                throw "LangGraph workflow failed: $($threadInfo.info.error)"
            }
            elseif ($threadInfo.info.status -eq 'interrupted') {
                Write-Warning "[$ModuleName] LangGraph workflow interrupted - requires human approval"
                # Could implement HITL handling here if needed
                break
            }
            
        } while ((Get-Date) - $startTime -lt [TimeSpan]::FromSeconds($timeout))
        
        if (-not $completed) {
            throw "LangGraph workflow timeout after $timeout seconds"
        }
        
        # Extract enhanced results
        $enhancedResults = $threadInfo.result
        
        # Cleanup LangGraph resources
        Remove-LangGraph -GraphId $graphId -ErrorAction SilentlyContinue
        
        Write-Debug "[$ModuleName] LangGraph workflow completed and cleaned up"
        
        return [PSCustomObject]@{
            OriginalAnalysis = $MaintenanceData
            EnhancedResults = $enhancedResults
            WorkflowType = $WorkflowType
            GraphId = $graphId
            ProcessingTime = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
            Status = 'completed'
            GeneratedAt = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        }
    }
    catch {
        Write-Error "[$ModuleName] LangGraph integration failed: $($_.Exception.Message)"
        
        # Return original analysis with error information
        return [PSCustomObject]@{
            OriginalAnalysis = $MaintenanceData
            EnhancedResults = $null
            Error = $_.Exception.Message
            Status = 'failed'
            FallbackMode = 'local_analysis_only'
            GeneratedAt = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        }
    }
}

function Get-LangGraphMaintenanceWorkflow {
    <#
    .SYNOPSIS
        Retrieves LangGraph workflow configuration for maintenance analysis.
    .DESCRIPTION
        Returns the workflow definition and configuration for maintenance prediction
        enhancement using LangGraph orchestrator-worker patterns.
    .PARAMETER WorkflowType
        Type of workflow configuration to retrieve
    .EXAMPLE
        $config = Get-LangGraphMaintenanceWorkflow -WorkflowType 'maintenance_prediction_enhancement'
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('maintenance_prediction_enhancement', 'unified_analysis_orchestration')]
        [string]$WorkflowType = 'maintenance_prediction_enhancement'
    )
    
    try {
        $workflowConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\PredictiveAnalysis-LangGraph-Workflows.json"
        
        if (-not (Test-Path $workflowConfigPath)) {
            throw "LangGraph workflow configuration file not found: $workflowConfigPath"
        }
        
        $workflowConfig = Get-Content $workflowConfigPath | ConvertFrom-Json
        $workflow = $workflowConfig.workflows.$WorkflowType
        
        if (-not $workflow) {
            throw "Workflow type '$WorkflowType' not found in configuration"
        }
        
        Write-Debug "[$ModuleName] Retrieved LangGraph workflow configuration for: $WorkflowType"
        return $workflow
    }
    catch {
        Write-Error "[$ModuleName] Failed to retrieve LangGraph workflow configuration: $($_.Exception.Message)"
        return $null
    }
}

function Test-LangGraphMaintenanceIntegration {
    <#
    .SYNOPSIS
        Tests LangGraph integration with maintenance analysis functionality.
    .DESCRIPTION
        Performs comprehensive testing of LangGraph integration including workflow
        submission, state management, and enhanced result processing.
    .EXAMPLE
        Test-LangGraphMaintenanceIntegration -Path ".\TestScripts"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = ".\Scripts",
        
        [Parameter()]
        [switch]$QuickTest
    )
    
    Write-Host "[$ModuleName] Testing LangGraph maintenance integration..." -ForegroundColor Cyan
    
    try {
        # Test 1: Basic maintenance analysis
        Write-Host "  Test 1: Basic maintenance analysis..." -ForegroundColor Yellow
        $maintenanceData = Get-MaintenancePrediction -Path $Path -Format 'Detailed'
        
        if (-not $maintenanceData) {
            throw "Basic maintenance analysis failed"
        }
        Write-Host "    ✓ Maintenance analysis completed" -ForegroundColor Green
        
        # Test 2: LangGraph workflow configuration
        Write-Host "  Test 2: LangGraph workflow configuration..." -ForegroundColor Yellow
        $workflowConfig = Get-LangGraphMaintenanceWorkflow -WorkflowType 'maintenance_prediction_enhancement'
        
        if (-not $workflowConfig) {
            throw "LangGraph workflow configuration failed"
        }
        Write-Host "    ✓ Workflow configuration loaded" -ForegroundColor Green
        
        # Test 3: LangGraph service connectivity (if not QuickTest)
        if (-not $QuickTest) {
            Write-Host "  Test 3: LangGraph service connectivity..." -ForegroundColor Yellow
            
            # Import and test LangGraph bridge
            Import-Module -Path "..\..\..\Unity-Claude-LangGraphBridge.psm1" -Force -ErrorAction Stop
            $serverStatus = Test-LangGraphServer
            
            if (-not $serverStatus -or $serverStatus.status -ne 'healthy') {
                Write-Warning "    ! LangGraph server not available - skipping integration test"
                return $false
            }
            Write-Host "    ✓ LangGraph server connectivity verified" -ForegroundColor Green
            
            # Test 4: Full integration workflow
            Write-Host "  Test 4: Full integration workflow..." -ForegroundColor Yellow
            $enhancedResults = Submit-MaintenanceAnalysisToLangGraph -MaintenanceData $maintenanceData
            
            if (-not $enhancedResults -or $enhancedResults.Status -ne 'completed') {
                Write-Warning "    ! LangGraph integration workflow failed - check server logs"
                return $false
            }
            Write-Host "    ✓ Full integration workflow completed" -ForegroundColor Green
        }
        
        Write-Host "[$ModuleName] LangGraph integration test completed successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "[$ModuleName] LangGraph integration test failed: $($_.Exception.Message)"
        return $false
    }
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Get-TechnicalDebt'
    'Get-CodeSmells'
    'Get-MaintenancePrediction'
    'Get-RefactoringRecommendations'
    'New-MaintenanceReport'
    'Invoke-PSScriptAnalyzerEnhanced'
    'Submit-MaintenanceAnalysisToLangGraph'
    'Get-LangGraphMaintenanceWorkflow'
    'Test-LangGraphMaintenanceIntegration'
) -Variable @(
    'ModuleVersion'
    'ModuleName'
)

Write-Host "[$ModuleName] Week 4 Day 2: Maintenance Prediction module with LangGraph integration loaded successfully" -ForegroundColor Green

Write-Host "[$ModuleName] Week 4 Day 2: Maintenance Prediction module loaded successfully" -ForegroundColor Green