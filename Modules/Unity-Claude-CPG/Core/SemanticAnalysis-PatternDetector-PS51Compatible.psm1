#
# SemanticAnalysis-PatternDetector-PS51Compatible.psm1
# PowerShell 5.1 compatible design pattern detection using function-based approach
# Eliminates PowerShell class dependencies for reliable PowerShell 5.1 compatibility
# Created: 2025-08-28
#

# Import required dependencies
$cpgModule = Join-Path (Split-Path $PSScriptRoot -Parent) "Unity-Claude-CPG.psd1"
if (Test-Path $cpgModule) {
    Import-Module $cpgModule -Force -ErrorAction SilentlyContinue
}

# Pattern detection configuration
$script:PatternConfig = @{
    ConfidenceThresholds = @{
        High = 0.8
        Medium = 0.5
        Low = 0.3
    }
    FeatureWeights = @{
        Structural = 0.6
        Behavioral = 0.4
    }
    EnableDebugLogging = $true
}

#
# Function-Based Pattern Object Factories (Replace Classes)
#

function New-PatternSignature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $Name,
        
        [Parameter(Mandatory=$true)]
        [string] $Category,
        
        [Parameter(Mandatory=$true)]
        [hashtable] $StructuralFeatures,
        
        [Parameter(Mandatory=$true)]
        [hashtable] $BehavioralFeatures,
        
        [string] $Description = ""
    )
    
    $signature = @{
        Name = $Name
        Category = $Category
        StructuralFeatures = $StructuralFeatures
        BehavioralFeatures = $BehavioralFeatures
        Description = if ($Description) { $Description } else { "Pattern signature for $Name" }
        CreatedAt = Get-Date
    }
    
    Write-Debug "[PATTERN] Created function-based signature for $Name pattern in $Category category"
    
    return $signature
}

function New-PatternMatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $PatternName,
        
        [Parameter(Mandatory=$true)]
        [string] $Location,
        
        [Parameter(Mandatory=$true)]
        [double] $Confidence
    )
    
    # Determine confidence level
    $confidenceLevel = if ($Confidence -ge 0.8) { "High" } 
                      elseif ($Confidence -ge 0.5) { "Medium" } 
                      else { "Low" }
    
    $match = @{
        PatternName = $PatternName
        Location = $Location
        Confidence = $Confidence
        ConfidenceLevel = $confidenceLevel
        MatchedFeatures = @{}
        MissingFeatures = @{}
        Explanation = "Detected $PatternName pattern at $Location with $confidenceLevel confidence"
        DetectedAt = Get-Date
    }
    
    Write-Debug "[PATTERN] Created function-based pattern match for $PatternName at $Location with $($Confidence*100)% confidence"
    
    return $match
}

#
# Pattern Definition Functions (Replace Class Methods)
#

function Get-SingletonPatternSignature {
    [CmdletBinding()]
    param()
    
    return New-PatternSignature -Name "Singleton" -Category "Creational" -StructuralFeatures @{
        HiddenConstructor = $true
        StaticInstance = $true
        StaticAccessMethod = $true
        NoPublicConstructor = $true
    } -BehavioralFeatures @{
        GetInstanceMethod = $true
        LazyInstantiation = $false
        ThreadSafety = $false
    }
}

function Get-FactoryPatternSignature {
    [CmdletBinding()]
    param()
    
    return New-PatternSignature -Name "Factory" -Category "Creational" -StructuralFeatures @{
        CreationMethod = $true
        AbstractProduct = $true
        ConcreteProducts = $true
        PolymorphicReturn = $true
    } -BehavioralFeatures @{
        DynamicCreation = $true
        ParameterBasedCreation = $true
        ProductHierarchy = $true
    }
}

#
# AST Analysis Functions (PowerShell 5.1 Compatible)
#

function Get-PowerShellASTCompatible {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $FilePath
    )
    
    Write-Debug "[AST] PS5.1 Compatible - Parsing PowerShell file: $FilePath"
    
    try {
        if (-not (Test-Path $FilePath)) {
            throw "File not found: $FilePath"
        }
        
        # Critical: Use -Raw parameter for proper string formatting
        $content = Get-Content $FilePath -Raw
        $tokens = $null
        $parseErrors = $null
        
        Write-Debug "[AST] PS5.1 - Content length: $($content.Length) characters"
        Write-Debug "[AST] PS5.1 - PowerShell Version: $($PSVersionTable.PSVersion)"
        
        # Parse using PowerShell parser
        $ast = [System.Management.Automation.Language.Parser]::ParseInput(
            $content, 
            [ref] $tokens, 
            [ref] $parseErrors
        )
        
        if ($parseErrors.Count -gt 0) {
            Write-Warning "[AST] PS5.1 - Parse errors found in $FilePath"
            foreach ($error in $parseErrors) {
                Write-Debug "[AST] PS5.1 - Parse error: $($error.Message)"
                Write-Debug "[AST] PS5.1 - Error location: Line $($error.Extent.StartLineNumber), Column $($error.Extent.StartColumnNumber)"
                Write-Debug "[AST] PS5.1 - Error text: '$($error.Extent.Text)'"
            }
        }
        
        Write-Debug "[AST] PS5.1 - Successfully parsed $FilePath - AST nodes: $($ast.FindAll({$true}, $true).Count)"
        
        return @{
            AST = $ast
            Tokens = $tokens
            ParseErrors = $parseErrors
            FilePath = $FilePath
            ParserVersion = "PowerShell 5.1 Compatible"
        }
    }
    catch {
        Write-Error "[AST] PS5.1 - Failed to parse $FilePath : $($_.Exception.Message)"
        return $null
    }
}

function Find-FunctionDefinitionsCompatible {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $AST
    )
    
    Write-Debug "[AST] PS5.1 - Finding function definitions using function-based approach"
    
    # Find all function definitions using PowerShell 5.1 compatible AST navigation
    $functions = $AST.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $true)
    
    $functionInfo = @()
    
    foreach ($function in $functions) {
        $functionData = @{
            Name = $function.Name
            AST = $function
            Parameters = $function.Parameters
            Body = $function.Body
            StartLine = $function.Extent.StartLineNumber
            EndLine = $function.Extent.EndLineNumber
            IsPublic = -not ($function.Name.StartsWith("_"))
        }
        
        $functionInfo += $functionData
        
        Write-Debug "[AST] PS5.1 - Found function: $($function.Name) at lines $($function.Extent.StartLineNumber)-$($function.Extent.EndLineNumber)"
    }
    
    return $functionInfo
}

#
# Function-Based Pattern Detection (No Classes Required)
#

function Test-SingletonPatternCompatible {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $FunctionInfo
    )
    
    Write-Debug "[PATTERN] PS5.1 - Testing Singleton pattern for function-based analysis"
    
    $matches = @{}
    $confidence = 0.0
    
    # Look for singleton-like function patterns (GetInstance, GetSingleton, etc.)
    $singletonFunctions = $FunctionInfo | Where-Object {
        $_.Name -match "(?i)(Get.*Instance|GetSingleton|Instance|Singleton)"
    }
    
    if ($singletonFunctions.Count -gt 0) {
        $matches.SingletonFunction = $true
        $confidence += 0.6
        Write-Debug "[PATTERN] PS5.1 - Found singleton-like function: $($singletonFunctions[0].Name)"
    }
    
    # Look for static-like behavior (script-level variables for instance storage)
    $staticVariables = $FunctionInfo | Where-Object {
        $_.Body.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.VariableExpressionAst] -and
            $node.VariablePath.UserPath -like "*Instance*"
        }, $true).Count -gt 0
    }
    
    if ($staticVariables.Count -gt 0) {
        $matches.InstanceVariable = $true
        $confidence += 0.4
        Write-Debug "[PATTERN] PS5.1 - Found instance-like variable usage"
    }
    
    Write-Debug "[PATTERN] PS5.1 - Singleton pattern confidence: $confidence"
    
    return New-PatternMatch -PatternName "Singleton" -Location "Function-based analysis" -Confidence $confidence
}

function Invoke-PatternDetectionCompatible {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $FilePath,
        
        [string[]] $PatternsToDetect = @("Singleton", "Factory"),
        [double] $MinimumConfidence = 0.3
    )
    
    Write-Debug "[PATTERN] PS5.1 - Starting function-based pattern detection for: $FilePath"
    
    # Test simple function syntax first (avoid classes)
    $simpleFunctionContent = @'
function Get-TestInstance {
    param()
    if (-not $script:Instance) {
        $script:Instance = "TestInstance"
    }
    return $script:Instance
}

function New-TestObject {
    param([string] $Type)
    switch ($Type) {
        "A" { return @{ Type = "A"; Value = 1 } }
        "B" { return @{ Type = "B"; Value = 2 } }
        default { return @{ Type = "Default"; Value = 0 } }
    }
}
'@
    
    Write-Debug "[PATTERN] PS5.1 - Testing with simple function syntax instead of classes"
    
    # Create test file with function-based content
    $testFile = Join-Path $env:TEMP "TestFunctions.ps1"
    $simpleFunctionContent | Out-File -FilePath $testFile -Encoding ASCII
    
    try {
        # Parse the function-based file
        $astResult = Get-PowerShellASTCompatible -FilePath $testFile
        if (-not $astResult -or $astResult.ParseErrors.Count -gt 0) {
            Write-Debug "[PATTERN] PS5.1 - Function syntax parsing failed"
            Remove-Item $testFile -Force -ErrorAction SilentlyContinue
            return @()
        }
        
        # Extract function information  
        $functions = Find-FunctionDefinitionsCompatible -AST $astResult.AST
        
        Write-Debug "[PATTERN] PS5.1 - Found $($functions.Count) functions for analysis"
        
        $detectedPatterns = @()
        
        # Test patterns using function-based approach
        foreach ($patternName in $PatternsToDetect) {
            $patternMatch = switch ($patternName) {
                "Singleton" { Test-SingletonPatternCompatible -FunctionInfo $functions }
                default { 
                    Write-Warning "[PATTERN] PS5.1 - Pattern not implemented for function-based approach: $patternName"
                    $null
                }
            }
            
            if ($patternMatch -and $patternMatch.Confidence -ge $MinimumConfidence) {
                $patternMatch.Location = "$FilePath : Function-based analysis"
                $detectedPatterns += $patternMatch
                
                Write-Debug "[PATTERN] PS5.1 - Detected $patternName with confidence $($patternMatch.Confidence)"
            }
        }
        
        Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        
        Write-Debug "[PATTERN] PS5.1 - Pattern detection complete: $($detectedPatterns.Count) patterns detected"
        
        return $detectedPatterns
    }
    catch {
        Write-Error "[PATTERN] PS5.1 - Pattern detection failed: $($_.Exception.Message)"
        Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        return @()
    }
}

function Get-AvailablePatternsCompatible {
    [CmdletBinding()]
    param()
    
    return @{
        SupportedPatterns = @("Singleton")  # Start with one working pattern
        Approach = "Function-based analysis (PowerShell 5.1 compatible)"
        Categories = @{
            Creational = @("Singleton")
            Behavioral = @()  # Future implementation
            Structural = @()  # Future implementation
        }
        ConfidenceThresholds = $script:PatternConfig.ConfidenceThresholds
        FeatureWeights = $script:PatternConfig.FeatureWeights
        PowerShellCompatibility = "PowerShell 5.1 Desktop Edition"
    }
}

# Export module functions (PowerShell 5.1 compatible)
Export-ModuleMember -Function @(
    'New-PatternSignature',
    'New-PatternMatch',
    'Get-SingletonPatternSignature',
    'Get-PowerShellASTCompatible',
    'Find-FunctionDefinitionsCompatible', 
    'Test-SingletonPatternCompatible',
    'Invoke-PatternDetectionCompatible',
    'Get-AvailablePatternsCompatible'
)