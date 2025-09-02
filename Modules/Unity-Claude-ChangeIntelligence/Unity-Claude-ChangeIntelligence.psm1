# Unity-Claude-ChangeIntelligence.psm1
# Intelligent Change Detection and Classification Module
# Part of Week 3: Real-Time Intelligence - Day 11, Hour 3-4

using namespace System.Collections.Generic
using namespace System.Management.Automation.Language

# Module-level variables for intelligence state
$script:IntelligenceState = @{
    ClassificationRules = [Dictionary[string, PSCustomObject]]::new()
    ImpactCache = [Dictionary[string, PSCustomObject]]::new()
    ChangeHistory = [List[PSCustomObject]]::new()
    AIAvailable = $false
    OllamaEndpoint = "http://localhost:11434/api/generate"
    Statistics = @{
        ChangesAnalyzed = 0
        AIAnalysisCount = 0
        CacheHits = 0
        ClassificationAccuracy = 0
    }
}

# Change classification types
enum ChangeType {
    Structural    # Module/function structure changes
    Behavioral    # Logic and algorithm changes
    Configuration # Settings and parameters
    Documentation # Comments and markdown
    Test          # Test-related changes
    Dependency    # Import and reference changes
    Security      # Security-related changes
    Performance   # Performance-impacting changes
    Unknown       # Cannot classify
}

# Impact severity levels
enum ImpactSeverity {
    Critical  # Breaking changes, security issues
    High      # Major functionality changes
    Medium    # Standard modifications
    Low       # Minor updates
    Minimal   # Documentation, comments
}

# Risk assessment levels
enum RiskLevel {
    VeryHigh  # High probability of breaking something
    High      # Significant risk
    Medium    # Moderate risk
    Low       # Low risk
    VeryLow   # Minimal risk
}

function Initialize-ChangeIntelligence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$OllamaEndpoint = "http://localhost:11434/api/generate",
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableAI
    )
    
    Write-Verbose "Initializing Change Intelligence Module..."
    
    # Set Ollama endpoint
    $script:IntelligenceState.OllamaEndpoint = $OllamaEndpoint
    
    # Check AI availability if requested
    if ($EnableAI) {
        $script:IntelligenceState.AIAvailable = Test-OllamaConnection
    }
    
    # Initialize classification rules
    Initialize-ClassificationRules
    
    Write-Host "Change Intelligence Module initialized $(if ($script:IntelligenceState.AIAvailable) { 'with AI support' } else { 'without AI support' })" -ForegroundColor Green
    
    return $true
}

function Initialize-ClassificationRules {
    [CmdletBinding()]
    param()
    
    # Define classification rules based on patterns
    $rules = @{
        "Module" = @{
            Pattern = @('\.psm1$', '\.psd1$', 'Export-ModuleMember', 'Import-Module')
            Type = [ChangeType]::Structural
            Impact = [ImpactSeverity]::High
        }
        "Function" = @{
            Pattern = @('function\s+\w+', 'filter\s+\w+', 'workflow\s+\w+')
            Type = [ChangeType]::Behavioral
            Impact = [ImpactSeverity]::High
        }
        "Configuration" = @{
            Pattern = @('\.json$', '\.xml$', '\.config$', '\$.*Config', 'Set-.*Configuration')
            Type = [ChangeType]::Configuration
            Impact = [ImpactSeverity]::Medium
        }
        "Documentation" = @{
            Pattern = @('\.md$', '\.txt$', '^\s*#', '<#', 'comment-based help')
            Type = [ChangeType]::Documentation
            Impact = [ImpactSeverity]::Minimal
        }
        "Test" = @{
            Pattern = @('\.tests?\.ps1$', 'Describe\s+', 'It\s+', 'Should', 'BeforeAll', 'AfterAll')
            Type = [ChangeType]::Test
            Impact = [ImpactSeverity]::Low
        }
        "Security" = @{
            Pattern = @('ConvertTo-SecureString', 'Credential', 'Password', 'Token', 'Authentication', 'Authorization')
            Type = [ChangeType]::Security
            Impact = [ImpactSeverity]::Critical
        }
        "Performance" = @{
            Pattern = @('Measure-', '\[System\.Diagnostics\.Stopwatch\]', 'parallel', 'async', 'runspace')
            Type = [ChangeType]::Performance
            Impact = [ImpactSeverity]::Medium
        }
    }
    
    foreach ($ruleName in $rules.Keys) {
        $script:IntelligenceState.ClassificationRules[$ruleName] = [PSCustomObject]$rules[$ruleName]
    }
}

function Get-ChangeClassification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$FileEvent,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseAI
    )
    
    Write-Verbose "Classifying change for: $($FileEvent.FullPath)"
    
    $classification = @{
        FilePath = $FileEvent.FullPath
        FileName = Split-Path $FileEvent.FullPath -Leaf
        ChangeType = [ChangeType]::Unknown
        ImpactSeverity = [ImpactSeverity]::Medium
        RiskLevel = [RiskLevel]::Medium
        Confidence = 0.5
        Details = @()
        Timestamp = Get-Date
    }
    
    # Check cache first
    $cacheKey = "$($FileEvent.FullPath):$($FileEvent.Type)"
    if ($script:IntelligenceState.ImpactCache.ContainsKey($cacheKey)) {
        $script:IntelligenceState.Statistics.CacheHits++
        Write-Verbose "Cache hit for: $cacheKey"
        return $script:IntelligenceState.ImpactCache[$cacheKey]
    }
    
    # File extension-based classification
    $extension = [System.IO.Path]::GetExtension($FileEvent.FullPath)
    $classification = Get-ExtensionBasedClassification -Extension $extension -Classification $classification
    
    # Content-based classification if file exists
    if (Test-Path $FileEvent.FullPath) {
        $classification = Get-ContentBasedClassification -FilePath $FileEvent.FullPath -Classification $classification
    }
    
    # AST-based analysis for PowerShell files
    if ($extension -in @('.ps1', '.psm1', '.psd1')) {
        $classification = Get-ASTBasedClassification -FilePath $FileEvent.FullPath -Classification $classification
    }
    
    # AI-enhanced classification if available and requested
    if ($UseAI -and $script:IntelligenceState.AIAvailable) {
        $classification = Get-AIEnhancedClassification -Classification $classification
    }
    
    # Calculate overall risk
    $classification.RiskLevel = Calculate-RiskLevel -Classification $classification
    
    # Cache the result
    $result = [PSCustomObject]$classification
    $script:IntelligenceState.ImpactCache[$cacheKey] = $result
    
    # Update statistics
    $script:IntelligenceState.Statistics.ChangesAnalyzed++
    
    # Add to history
    $script:IntelligenceState.ChangeHistory.Add($result)
    
    return $result
}

function Get-ExtensionBasedClassification {
    [CmdletBinding()]
    param(
        [string]$Extension,
        [hashtable]$Classification
    )
    
    switch ($Extension) {
        { $_ -in @('.ps1', '.psm1', '.psd1') } {
            $Classification.ChangeType = [ChangeType]::Behavioral
            $Classification.ImpactSeverity = [ImpactSeverity]::High
            $Classification.Confidence = 0.7
            $Classification.Details += "PowerShell script file"
        }
        { $_ -in @('.json', '.xml', '.config') } {
            $Classification.ChangeType = [ChangeType]::Configuration
            $Classification.ImpactSeverity = [ImpactSeverity]::Medium
            $Classification.Confidence = 0.8
            $Classification.Details += "Configuration file"
        }
        { $_ -in @('.md', '.txt', '.rst') } {
            $Classification.ChangeType = [ChangeType]::Documentation
            $Classification.ImpactSeverity = [ImpactSeverity]::Minimal
            $Classification.Confidence = 0.9
            $Classification.Details += "Documentation file"
        }
        default {
            $Classification.Confidence = 0.3
            $Classification.Details += "Unknown file type"
        }
    }
    
    return $Classification
}

function Get-ContentBasedClassification {
    [CmdletBinding()]
    param(
        [string]$FilePath,
        [hashtable]$Classification
    )
    
    try {
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        
        # Check against classification rules
        foreach ($ruleName in $script:IntelligenceState.ClassificationRules.Keys) {
            $rule = $script:IntelligenceState.ClassificationRules[$ruleName]
            
            foreach ($pattern in $rule.Pattern) {
                if ($content -match $pattern) {
                    $Classification.ChangeType = $rule.Type
                    $Classification.ImpactSeverity = $rule.Impact
                    $Classification.Confidence = [Math]::Min($Classification.Confidence + 0.1, 1.0)
                    $Classification.Details += "Matched rule: $ruleName (pattern: $pattern)"
                    break
                }
            }
        }
        
        # Special checks for security patterns
        if ($content -match 'password|token|secret|key|credential' -and $content -notmatch '^\s*#') {
            $Classification.ChangeType = [ChangeType]::Security
            $Classification.ImpactSeverity = [ImpactSeverity]::Critical
            $Classification.Details += "Security-sensitive content detected"
        }
        
        # Check for potentially dangerous operations
        if ($content -match 'Remove-Item.*-Recurse.*-Force|rm -rf|del.*\/s.*\/q|Format-|Stop-Computer|Restart-Computer') {
            $Classification.ImpactSeverity = [ImpactSeverity]::Critical
            $Classification.Details += "Potentially dangerous operations detected"
        }
    }
    catch {
        Write-Verbose "Could not read file content: $_"
    }
    
    return $Classification
}

function Get-ASTBasedClassification {
    [CmdletBinding()]
    param(
        [string]$FilePath,
        [hashtable]$Classification
    )
    
    try {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $FilePath,
            [ref]$tokens,
            [ref]$errors
        )
        
        if ($errors.Count -gt 0) {
            $Classification.Details += "Parse errors detected: $($errors.Count)"
            $Classification.RiskLevel = [RiskLevel]::High
        }
        
        # Analyze function definitions
        $functions = $ast.FindAll({ $args[0] -is [FunctionDefinitionAst] }, $true)
        if ($functions.Count -gt 0) {
            $Classification.ChangeType = [ChangeType]::Behavioral
            $Classification.Details += "Contains $($functions.Count) function(s)"
            
            # Check for exported functions
            $exportedFunctions = $ast.FindAll({ 
                $args[0] -is [CommandAst] -and 
                $args[0].CommandElements[0].Value -eq 'Export-ModuleMember' 
            }, $true)
            
            if ($exportedFunctions.Count -gt 0) {
                $Classification.ImpactSeverity = [ImpactSeverity]::High
                $Classification.Details += "Module with exported members"
            }
        }
        
        # Analyze variable assignments
        $variables = $ast.FindAll({ $args[0] -is [VariableExpressionAst] }, $true)
        $configVars = $variables | Where-Object { $_.VariablePath.UserPath -match 'config|setting|option' }
        if ($configVars.Count -gt 0) {
            $Classification.ChangeType = [ChangeType]::Configuration
            $Classification.Details += "Configuration variables detected"
        }
        
        # Analyze command usage
        $commands = $ast.FindAll({ $args[0] -is [CommandAst] }, $true)
        $importCommands = $commands | Where-Object { $_.CommandElements[0].Value -match 'Import-Module|Add-Type|using' }
        if ($importCommands.Count -gt 0) {
            $Classification.ChangeType = [ChangeType]::Dependency
            $Classification.ImpactSeverity = [ImpactSeverity]::High
            $Classification.Details += "Dependency changes detected"
        }
        
        # Check for test patterns - only override if we haven't found a more specific classification
        $testPatterns = $ast.FindAll({ 
            $args[0] -is [CommandAst] -and 
            $args[0].CommandElements[0].Value -match 'Describe|It|Should|BeforeAll|AfterAll' 
        }, $true)
        
        if ($testPatterns.Count -gt 0 -and $Classification.ChangeType -eq [ChangeType]::Unknown) {
            $Classification.ChangeType = [ChangeType]::Test
            $Classification.ImpactSeverity = [ImpactSeverity]::Low
            $Classification.Details += "Test file with $($testPatterns.Count) test pattern(s)"
        }
        elseif ($testPatterns.Count -gt 0) {
            # Add test info but don't override existing classification
            $Classification.Details += "Contains $($testPatterns.Count) test pattern(s)"
        }
        
        $Classification.Confidence = [Math]::Min($Classification.Confidence + 0.2, 1.0)
    }
    catch {
        Write-Verbose "AST analysis failed: $_"
    }
    
    return $Classification
}

function Get-AIEnhancedClassification {
    [CmdletBinding()]
    param(
        [hashtable]$Classification
    )
    
    if (-not $script:IntelligenceState.AIAvailable) {
        Write-Verbose "AI not available for enhancement"
        return $Classification
    }
    
    try {
        # Prepare prompt for Ollama
        $prompt = @"
Analyze this file change and provide impact assessment:
File: $($Classification.FileName)
Type: $($Classification.ChangeType)
Current Impact: $($Classification.ImpactSeverity)
Details: $($Classification.Details -join '; ')

Provide a brief impact assessment and risk level.
"@
        
        $body = @{
            model = "llama3.1"
            prompt = $prompt
            stream = $false
            options = @{
                temperature = 0.3
                max_tokens = 100
            }
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri $script:IntelligenceState.OllamaEndpoint `
                                      -Method Post `
                                      -Body $body `
                                      -ContentType "application/json" `
                                      -TimeoutSec 5
        
        if ($response.response) {
            $Classification.Details += "AI Assessment: $($response.response)"
            $Classification.Confidence = [Math]::Min($Classification.Confidence + 0.1, 1.0)
            $script:IntelligenceState.Statistics.AIAnalysisCount++
        }
    }
    catch {
        Write-Verbose "AI enhancement failed: $_"
    }
    
    return $Classification
}

function Calculate-RiskLevel {
    [CmdletBinding()]
    param(
        [hashtable]$Classification
    )
    
    # Risk calculation based on multiple factors
    $riskScore = 0
    
    # Impact severity contribution
    switch ($Classification.ImpactSeverity) {
        'Critical' { $riskScore += 5 }
        'High'     { $riskScore += 4 }
        'Medium'   { $riskScore += 3 }
        'Low'      { $riskScore += 2 }
        'Minimal'  { $riskScore += 1 }
    }
    
    # Change type contribution
    switch ($Classification.ChangeType) {
        'Security'      { $riskScore += 3 }
        'Structural'    { $riskScore += 2 }
        'Behavioral'    { $riskScore += 2 }
        'Dependency'    { $riskScore += 2 }
        'Performance'   { $riskScore += 1 }
        'Configuration' { $riskScore += 1 }
        'Test'          { $riskScore += 0 }
        'Documentation' { $riskScore += 0 }
    }
    
    # Confidence adjustment (lower confidence = higher risk)
    if ($Classification.Confidence -lt 0.5) {
        $riskScore += 1
    }
    
    # Map score to risk level
    if ($riskScore -ge 8) {
        return [RiskLevel]::VeryHigh
    }
    elseif ($riskScore -ge 6) {
        return [RiskLevel]::High
    }
    elseif ($riskScore -ge 4) {
        return [RiskLevel]::Medium
    }
    elseif ($riskScore -ge 2) {
        return [RiskLevel]::Low
    }
    else {
        return [RiskLevel]::VeryLow
    }
}

function Get-ImpactAssessment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Classification,
        
        [Parameter(Mandatory = $false)]
        [string[]]$DependentModules
    )
    
    $assessment = @{
        DirectImpact = @()
        IndirectImpact = @()
        AffectedComponents = @()
        RecommendedActions = @()
        EstimatedTestingEffort = "Low"
    }
    
    # Assess direct impact based on change type
    switch ($Classification.ChangeType) {
        'Structural' {
            $assessment.DirectImpact += "Module structure modified"
            $assessment.RecommendedActions += "Full regression testing required"
            $assessment.EstimatedTestingEffort = "High"
        }
        'Behavioral' {
            $assessment.DirectImpact += "Function behavior changed"
            $assessment.RecommendedActions += "Unit and integration testing required"
            $assessment.EstimatedTestingEffort = "Medium"
        }
        'Security' {
            $assessment.DirectImpact += "Security-sensitive changes"
            $assessment.RecommendedActions += "Security review required"
            $assessment.EstimatedTestingEffort = "High"
        }
        'Configuration' {
            $assessment.DirectImpact += "Configuration changes"
            $assessment.RecommendedActions += "Configuration validation required"
            $assessment.EstimatedTestingEffort = "Low"
        }
    }
    
    # Assess indirect impact if dependent modules provided
    if ($DependentModules) {
        $assessment.IndirectImpact += "May affect $($DependentModules.Count) dependent module(s)"
        $assessment.AffectedComponents = $DependentModules
    }
    
    # Risk-based recommendations
    switch ($Classification.RiskLevel) {
        'VeryHigh' {
            $assessment.RecommendedActions += "Manual review required before deployment"
            $assessment.RecommendedActions += "Backup current version"
        }
        'High' {
            $assessment.RecommendedActions += "Thorough testing recommended"
        }
    }
    
    return [PSCustomObject]$assessment
}

function Test-OllamaConnection {
    [CmdletBinding()]
    param()
    
    try {
        $response = Invoke-RestMethod -Uri "$($script:IntelligenceState.OllamaEndpoint -replace '/api/generate','')" `
                                      -Method Get `
                                      -TimeoutSec 2 `
                                      -ErrorAction Stop
        
        Write-Verbose "Ollama connection successful"
        return $true
    }
    catch {
        Write-Verbose "Ollama connection failed: $_"
        return $false
    }
}

function Get-ChangeIntelligenceStatistics {
    [CmdletBinding()]
    param()
    
    $stats = $script:IntelligenceState.Statistics.Clone()
    $stats.HistoryCount = $script:IntelligenceState.ChangeHistory.Count
    $stats.CacheSize = $script:IntelligenceState.ImpactCache.Count
    $stats.AIAvailable = $script:IntelligenceState.AIAvailable
    
    if ($stats.ChangesAnalyzed -gt 0) {
        $stats.CacheHitRate = [Math]::Round(($stats.CacheHits / $stats.ChangesAnalyzed) * 100, 2)
        $stats.AIUsageRate = [Math]::Round(($stats.AIAnalysisCount / $stats.ChangesAnalyzed) * 100, 2)
    }
    
    return [PSCustomObject]$stats
}

function Get-ChangeHistory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$Last = 10,
        
        [Parameter(Mandatory = $false)]
        [ChangeType]$Type,
        
        [Parameter(Mandatory = $false)]
        [RiskLevel]$MinRiskLevel
    )
    
    $history = $script:IntelligenceState.ChangeHistory
    
    if ($Type) {
        $history = $history | Where-Object { $_.ChangeType -eq $Type }
    }
    
    if ($MinRiskLevel) {
        $history = $history | Where-Object { $_.RiskLevel -ge $MinRiskLevel }
    }
    
    return $history | Select-Object -Last $Last
}

function Clear-ChangeIntelligenceCache {
    [CmdletBinding()]
    param()
    
    $cacheSize = $script:IntelligenceState.ImpactCache.Count
    $script:IntelligenceState.ImpactCache.Clear()
    
    Write-Verbose "Cleared $cacheSize cached entries"
    return $cacheSize
}

# Export module functions
Export-ModuleMember -Function @(
    'Initialize-ChangeIntelligence',
    'Get-ChangeClassification',
    'Get-ImpactAssessment',
    'Get-ChangeIntelligenceStatistics',
    'Get-ChangeHistory',
    'Clear-ChangeIntelligenceCache'
)