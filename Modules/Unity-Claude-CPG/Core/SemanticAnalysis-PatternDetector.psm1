#
# SemanticAnalysis-PatternDetector.psm1
# Design pattern detection module using AST analysis and CPG integration
# Part of Unity-Claude-CPG Enhanced Documentation System
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
# Pattern Definition Classes
#

class PatternSignature {
    [string] $Name
    [string] $Category  # Creational, Structural, Behavioral
    [hashtable] $StructuralFeatures
    [hashtable] $BehavioralFeatures
    [string] $Description
    
    PatternSignature([string] $name, [string] $category, [hashtable] $structural, [hashtable] $behavioral) {
        $this.Name = $name
        $this.Category = $category
        $this.StructuralFeatures = $structural
        $this.BehavioralFeatures = $behavioral
        $this.Description = "Pattern signature for $name"
        
        Write-Debug "[PATTERN] Created signature for $name pattern in $category category"
    }
}

class PatternMatch {
    [string] $PatternName
    [string] $Location  # File path or class name
    [float] $Confidence
    [string] $ConfidenceLevel  # High, Medium, Low
    [hashtable] $MatchedFeatures
    [hashtable] $MissingFeatures
    [string] $Explanation
    [DateTime] $DetectedAt
    
    PatternMatch([string] $patternName, [string] $location, [float] $confidence) {
        $this.PatternName = $patternName
        $this.Location = $location
        $this.Confidence = $confidence
        $this.MatchedFeatures = @{}
        $this.MissingFeatures = @{}
        $this.DetectedAt = Get-Date
        
        # Determine confidence level
        if ($confidence -ge 0.8) { $this.ConfidenceLevel = "High" }
        elseif ($confidence -ge 0.5) { $this.ConfidenceLevel = "Medium" }
        else { $this.ConfidenceLevel = "Low" }
        
        Write-Debug "[PATTERN] Created pattern match for $patternName at $location with $($confidence*100)% confidence"
    }
}

#
# Pattern Definitions
#

function Get-SingletonPattern {
    [CmdletBinding()]
    param()
    
    return [PatternSignature]::new(
        "Singleton",
        "Creational",
        @{
            PrivateConstructor = $true
            StaticInstance = $true
            StaticAccessMethod = $true
            NoPublicConstructor = $true
        },
        @{
            GetInstanceMethod = $true
            LazyInstantiation = $false  # Optional
            ThreadSafety = $false       # Optional
        }
    )
}

function Get-FactoryPattern {
    [CmdletBinding()]
    param()
    
    return [PatternSignature]::new(
        "Factory",
        "Creational", 
        @{
            CreationMethod = $true
            AbstractProduct = $true
            ConcreteProducts = $true
            PolymorphicReturn = $true
        },
        @{
            DynamicCreation = $true
            ParameterBasedCreation = $true
            ProductHierarchy = $true
        }
    )
}

function Get-ObserverPattern {
    [CmdletBinding()]
    param()
    
    return [PatternSignature]::new(
        "Observer",
        "Behavioral",
        @{
            SubjectClass = $true
            ObserverInterface = $true
            ObserverList = $true
            NotificationMethod = $true
        },
        @{
            Subscribe = $true
            Unsubscribe = $true
            NotifyObservers = $true
            ObserverUpdate = $true
        }
    )
}

function Get-StrategyPattern {
    [CmdletBinding()]
    param()
    
    return [PatternSignature]::new(
        "Strategy",
        "Behavioral",
        @{
            StrategyInterface = $true
            ConcreteStrategies = $true
            ContextClass = $true
            StrategyReference = $true
        },
        @{
            AlgorithmSelection = $true
            RuntimeSwitching = $true
            StrategyExecution = $true
        }
    )
}

#
# AST Analysis Functions
#

function Get-PowerShellAST {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $FilePath
    )
    
    Write-Debug "[AST] Parsing PowerShell file: $FilePath"
    
    try {
        if (-not (Test-Path $FilePath)) {
            throw "File not found: $FilePath"
        }
        
        $content = Get-Content $FilePath -Raw
        $tokens = $null
        $parseErrors = $null
        
        # Parse using PowerShell parser
        $ast = [System.Management.Automation.Language.Parser]::ParseInput(
            $content, 
            [ref] $tokens, 
            [ref] $parseErrors
        )
        
        if ($parseErrors.Count -gt 0) {
            Write-Warning "[AST] Parse errors found in $FilePath"
            Write-Debug "[AST] PowerShell Version: $($PSVersionTable.PSVersion) Edition: $($PSVersionTable.PSEdition)"
            Write-Debug "[AST] File content length: $($content.Length) characters"
            Write-Debug "[AST] First 200 characters of content: $($content.Substring(0, [Math]::Min(200, $content.Length)))"
            
            foreach ($error in $parseErrors) {
                Write-Debug "[AST] Parse error: $($error.Message) at line $($error.Extent.StartLineNumber) column $($error.Extent.StartColumnNumber)"
                Write-Debug "[AST] Error extent: $($error.Extent.Text)"
            }
        }
        
        Write-Debug "[AST] Successfully parsed $FilePath - AST nodes: $($ast.FindAll({$true}, $true).Count)"
        
        return @{
            AST = $ast
            Tokens = $tokens
            ParseErrors = $parseErrors
            FilePath = $FilePath
        }
    }
    catch {
        Write-Error "[AST] Failed to parse $FilePath : $($_.Exception.Message)"
        return $null
    }
}

function Find-ClassDefinitions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $AST
    )
    
    Write-Debug "[AST] Finding class definitions in AST"
    
    # Find all class definitions using AST navigation
    $classes = $AST.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.TypeDefinitionAst] -and 
        $node.IsClass
    }, $true)
    
    $classInfo = @()
    
    foreach ($class in $classes) {
        $constructors = $class.Members | Where-Object { $_ -is [System.Management.Automation.Language.FunctionMemberAst] -and $_.Name -eq $class.Name }
        $methods = $class.Members | Where-Object { $_ -is [System.Management.Automation.Language.FunctionMemberAst] -and $_.Name -ne $class.Name }
        $properties = $class.Members | Where-Object { $_ -is [System.Management.Automation.Language.PropertyMemberAst] }
        
        $classData = @{
            Name = $class.Name
            AST = $class
            Constructors = $constructors
            Methods = $methods
            Properties = $properties
            StartLine = $class.Extent.StartLineNumber
            EndLine = $class.Extent.EndLineNumber
            IsPublic = $class.Attributes | Where-Object { $_.TypeName.Name -eq "public" }
        }
        
        $classInfo += $classData
        
        Write-Debug "[AST] Found class: $($class.Name) with $($methods.Count) methods, $($properties.Count) properties"
    }
    
    return $classInfo
}

function Find-FunctionDefinitions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $AST
    )
    
    Write-Debug "[AST] Finding function definitions in AST"
    
    # Find all function definitions
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
        
        Write-Debug "[AST] Found function: $($function.Name) at lines $($function.Extent.StartLineNumber)-$($function.Extent.EndLineNumber)"
    }
    
    return $functionInfo
}

#
# Pattern Detection Functions
#

function Test-SingletonPattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $ClassInfo
    )
    
    Write-Debug "[PATTERN] Testing Singleton pattern for class: $($ClassInfo.Name)"
    
    $matches = @{}
    $confidence = 0.0
    
    Write-Debug "[PATTERN] Singleton: Analyzing class with $($ClassInfo.Constructors.Count) constructors, $($ClassInfo.Properties.Count) properties, $($ClassInfo.Methods.Count) methods"
    
    # Check for hidden constructors (PowerShell singleton pattern)
    $hiddenConstructor = $ClassInfo.Constructors | Where-Object { 
        $_.Attributes | Where-Object { $_.TypeName.Name -eq "hidden" }
    }
    
    # Also consider constructors without public attribute (PowerShell default)
    $nonPublicConstructor = $ClassInfo.Constructors | Where-Object { 
        -not ($_.Attributes | Where-Object { $_.TypeName.Name -eq "public" })
    }
    
    if ($hiddenConstructor) {
        $matches.HiddenConstructor = $true
        $confidence += 0.4  # Higher weight for explicit hidden
        Write-Debug "[PATTERN] Singleton: Found explicitly hidden constructor"
    }
    elseif ($nonPublicConstructor) {
        $matches.NonPublicConstructor = $true  
        $confidence += 0.25  # Lower weight for implicit non-public
        Write-Debug "[PATTERN] Singleton: Found non-public constructor"
    }
    
    # Check for static instance property or variable
    $staticInstance = $ClassInfo.Properties | Where-Object {
        $_.Attributes | Where-Object { $_.TypeName.Name -eq "static" }
    }
    
    # Also check for static fields in AST (may not appear as Properties)
    $staticFields = $ClassInfo.AST.Members | Where-Object {
        $_ -is [System.Management.Automation.Language.PropertyMemberAst] -and
        ($_.Attributes | Where-Object { $_.TypeName.Name -eq "static" })
    }
    
    if ($staticInstance -or $staticFields) {
        $matches.StaticInstance = $true
        $confidence += 0.3
        Write-Debug "[PATTERN] Singleton: Found static instance property/field"
    }
    
    # Check for static access method (GetInstance, GetSingleton, Instance, etc.)
    $accessMethod = $ClassInfo.Methods | Where-Object {
        ($_.Name -match "(?i)(Get.*Instance|GetSingleton|Instance|GetThis)") -and
        ($_.Attributes | Where-Object { $_.TypeName.Name -eq "static" })
    }
    
    if ($accessMethod) {
        $matches.StaticAccessMethod = $true
        $confidence += 0.35  # Slightly higher weight for access method
        Write-Debug "[PATTERN] Singleton: Found static access method: $($accessMethod.Name)"
    }
    
    # Bonus: Check for lazy initialization pattern in method body
    if ($accessMethod) {
        $lazyInit = $accessMethod.Body.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.IfStatementAst]
        }, $true)
        
        if ($lazyInit.Count -gt 0) {
            $confidence += 0.1  # Bonus for lazy initialization
            Write-Debug "[PATTERN] Singleton: Found lazy initialization pattern"
        }
    }
    
    Write-Debug "[PATTERN] Singleton: Final confidence score: $confidence"
    
    return [PatternMatch]::new("Singleton", $ClassInfo.Name, $confidence)
}

function Test-FactoryPattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $ClassInfo,
        
        [Parameter(Mandatory=$true)]
        $AllClasses
    )
    
    Write-Debug "[PATTERN] Testing Factory pattern for class: $($ClassInfo.Name)"
    
    $matches = @{}
    $confidence = 0.0
    
    # Look for creation methods (Create*, New*, Make*, Build*)
    $creationMethods = $ClassInfo.Methods | Where-Object {
        $_.Name -match "^(Create|New|Make|Build|Get)"
    }
    
    if ($creationMethods.Count -gt 0) {
        $matches.CreationMethod = $true
        $confidence += 0.4
        Write-Debug "[PATTERN] Factory: Found $($creationMethods.Count) creation methods"
    }
    
    # Check for polymorphic return types (methods returning different concrete types)
    $polymorphicReturns = $creationMethods | Where-Object {
        # This is a simplified check - in real implementation would analyze return statements
        $_.Body.FindAll({$args[0] -is [System.Management.Automation.Language.ReturnStatementAst]}, $true).Count -gt 1
    }
    
    if ($polymorphicReturns.Count -gt 0) {
        $matches.PolymorphicReturn = $true
        $confidence += 0.3
        Write-Debug "[PATTERN] Factory: Found polymorphic return patterns"
    }
    
    # Check for product hierarchy (related classes that could be products)
    $relatedProducts = $AllClasses | Where-Object {
        $_.Name -like "*$($ClassInfo.Name.Replace('Factory', ''))Product*" -or
        $_.Name -like "*Product" -or
        $_.Name -like "*Item"
    }
    
    if ($relatedProducts.Count -gt 1) {
        $matches.ProductHierarchy = $true
        $confidence += 0.3
        Write-Debug "[PATTERN] Factory: Found $($relatedProducts.Count) potential product classes"
    }
    
    return [PatternMatch]::new("Factory", $ClassInfo.Name, $confidence)
}

function Test-ObserverPattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $ClassInfo,
        
        [Parameter(Mandatory=$true)]
        $AllClasses
    )
    
    Write-Debug "[PATTERN] Testing Observer pattern for class: $($ClassInfo.Name)"
    
    $matches = @{}
    $confidence = 0.0
    
    # Check for observer list (collection properties)
    $observerList = $ClassInfo.Properties | Where-Object {
        $_.PropertyType.TypeName.Name -like "*List*" -or
        $_.PropertyType.TypeName.Name -like "*Array*" -or
        $_.PropertyType.TypeName.Name -like "*Collection*" -or
        $_.Name -like "*Observer*" -or
        $_.Name -like "*Listener*"
    }
    
    if ($observerList) {
        $matches.ObserverList = $true
        $confidence += 0.3
        Write-Debug "[PATTERN] Observer: Found observer collection property"
    }
    
    # Check for notification methods (Notify*, Update*, Fire*, Trigger*)
    $notificationMethods = $ClassInfo.Methods | Where-Object {
        $_.Name -match "^(Notify|Update|Fire|Trigger|Broadcast)"
    }
    
    if ($notificationMethods.Count -gt 0) {
        $matches.NotificationMethod = $true
        $confidence += 0.4
        Write-Debug "[PATTERN] Observer: Found $($notificationMethods.Count) notification methods"
    }
    
    # Check for subscribe/unsubscribe methods
    $subscriptionMethods = $ClassInfo.Methods | Where-Object {
        $_.Name -match "^(Subscribe|Unsubscribe|Add|Remove)" -and
        $_.Name -like "*Observer*" -or $_.Name -like "*Listener*"
    }
    
    if ($subscriptionMethods.Count -ge 2) {
        $matches.SubscriptionMethods = $true
        $confidence += 0.3
        Write-Debug "[PATTERN] Observer: Found subscription/unsubscription methods"
    }
    
    return [PatternMatch]::new("Observer", $ClassInfo.Name, $confidence)
}

function Test-StrategyPattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $ClassInfo,
        
        [Parameter(Mandatory=$true)]
        $AllClasses
    )
    
    Write-Debug "[PATTERN] Testing Strategy pattern for class: $($ClassInfo.Name)"
    
    $matches = @{}
    $confidence = 0.0
    
    # Check for strategy interface/abstract methods
    $abstractMethods = $ClassInfo.Methods | Where-Object {
        $_.Body.Statements.Count -eq 0 -or  # Empty body (abstract-like)
        ($_.Body.FindAll({$args[0] -is [System.Management.Automation.Language.ThrowStatementAst]}, $false).Count -gt 0)  # Throws NotImplemented
    }
    
    if ($abstractMethods.Count -gt 0) {
        $matches.StrategyInterface = $true
        $confidence += 0.3
        Write-Debug "[PATTERN] Strategy: Found $($abstractMethods.Count) abstract-like methods"
    }
    
    # Check for context class (class that uses strategy)
    $contextClasses = $AllClasses | Where-Object {
        # Look for classes that have properties of current class type
        $_.Properties | Where-Object { $_.PropertyType.TypeName.Name -eq $ClassInfo.Name }
    }
    
    if ($contextClasses.Count -gt 0) {
        $matches.ContextClass = $true
        $confidence += 0.3
        Write-Debug "[PATTERN] Strategy: Found $($contextClasses.Count) potential context classes"
    }
    
    # Check for algorithm methods (Execute*, Process*, Handle*, Perform*)
    $algorithmMethods = $ClassInfo.Methods | Where-Object {
        $_.Name -match "^(Execute|Process|Handle|Perform|Calculate|Compute)"
    }
    
    if ($algorithmMethods.Count -gt 0) {
        $matches.AlgorithmMethods = $true
        $confidence += 0.4
        Write-Debug "[PATTERN] Strategy: Found $($algorithmMethods.Count) algorithm methods"
    }
    
    return [PatternMatch]::new("Strategy", $ClassInfo.Name, $confidence)
}

#
# Main Pattern Detection Functions
#

function Invoke-PatternDetection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $FilePath,
        
        [string[]] $PatternsToDetect = @("Singleton", "Factory", "Observer", "Strategy"),
        [float] $MinimumConfidence = 0.3
    )
    
    Write-Debug "[PATTERN] Starting pattern detection for: $FilePath"
    
    # Parse the file
    $astResult = Get-PowerShellAST -FilePath $FilePath
    if (-not $astResult) {
        Write-Error "[PATTERN] Failed to parse file: $FilePath"
        return @()
    }
    
    # Extract class and function information
    $classes = Find-ClassDefinitions -AST $astResult.AST
    $functions = Find-FunctionDefinitions -AST $astResult.AST
    
    Write-Debug "[PATTERN] Found $($classes.Count) classes and $($functions.Count) functions"
    
    $detectedPatterns = @()
    
    # Test each class against requested patterns
    foreach ($class in $classes) {
        Write-Debug "[PATTERN] Analyzing class: $($class.Name)"
        
        foreach ($patternName in $PatternsToDetect) {
            $patternMatch = switch ($patternName) {
                "Singleton" { Test-SingletonPattern -ClassInfo $class }
                "Factory" { Test-FactoryPattern -ClassInfo $class -AllClasses $classes }
                "Observer" { Test-ObserverPattern -ClassInfo $class -AllClasses $classes }
                "Strategy" { Test-StrategyPattern -ClassInfo $class -AllClasses $classes }
                default { 
                    Write-Warning "[PATTERN] Unknown pattern type: $patternName"
                    $null
                }
            }
            
            if ($patternMatch -and $patternMatch.Confidence -ge $MinimumConfidence) {
                $patternMatch.Location = "$FilePath : $($class.Name)"
                $patternMatch.Explanation = "Detected $patternName pattern in class $($class.Name) with $($patternMatch.ConfidenceLevel) confidence"
                $detectedPatterns += $patternMatch
                
                Write-Debug "[PATTERN] Detected $patternName pattern in $($class.Name) with confidence $($patternMatch.Confidence)"
            }
        }
    }
    
    Write-Debug "[PATTERN] Pattern detection complete: $($detectedPatterns.Count) patterns detected"
    
    return $detectedPatterns
}

function Get-PatternDetectionReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $SourcePath,
        
        [string] $OutputPath,
        [string[]] $PatternsToDetect = @("Singleton", "Factory", "Observer", "Strategy"),
        [float] $MinimumConfidence = 0.3
    )
    
    Write-Debug "[PATTERN] Starting pattern detection report for: $SourcePath"
    
    $allPatterns = @()
    $processedFiles = 0
    $startTime = Get-Date
    
    # Get all PowerShell files
    $psFiles = if (Test-Path $SourcePath -PathType Container) {
        Get-ChildItem -Path $SourcePath -Filter "*.ps*1" -Recurse | Where-Object { -not $_.PSIsContainer }
    } else {
        @(Get-Item $SourcePath)
    }
    
    foreach ($file in $psFiles) {
        Write-Debug "[PATTERN] Processing file: $($file.FullName)"
        
        try {
            $patterns = Invoke-PatternDetection -FilePath $file.FullName -PatternsToDetect $PatternsToDetect -MinimumConfidence $MinimumConfidence
            $allPatterns += $patterns
            $processedFiles++
            
            Write-Debug "[PATTERN] Found $($patterns.Count) patterns in $($file.Name)"
        }
        catch {
            Write-Warning "[PATTERN] Failed to process $($file.FullName): $($_.Exception.Message)"
        }
    }
    
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    # Generate report
    $report = @{
        Summary = @{
            SourcePath = $SourcePath
            ProcessedFiles = $processedFiles
            TotalFiles = $psFiles.Count
            TotalPatterns = $allPatterns.Count
            PatternsDetected = $PatternsToDetected
            MinimumConfidence = $MinimumConfidence
            Duration = $duration
            GeneratedAt = $endTime
        }
        Patterns = $allPatterns
        Statistics = @{
            ByPattern = @{}
            ByConfidence = @{
                High = ($allPatterns | Where-Object { $_.ConfidenceLevel -eq "High" }).Count
                Medium = ($allPatterns | Where-Object { $_.ConfidenceLevel -eq "Medium" }).Count
                Low = ($allPatterns | Where-Object { $_.ConfidenceLevel -eq "Low" }).Count
            }
        }
    }
    
    # Calculate pattern statistics
    foreach ($pattern in $PatternsToDetect) {
        $patternMatches = $allPatterns | Where-Object { $_.PatternName -eq $pattern }
        $report.Statistics.ByPattern[$pattern] = @{
            Count = $patternMatches.Count
            AverageConfidence = if ($patternMatches.Count -gt 0) { 
                ($patternMatches | Measure-Object -Property Confidence -Average).Average 
            } else { 0 }
            HighConfidenceCount = ($patternMatches | Where-Object { $_.ConfidenceLevel -eq "High" }).Count
        }
    }
    
    # Save report if output path specified
    if ($OutputPath) {
        $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Debug "[PATTERN] Report saved to: $OutputPath"
    }
    
    return $report
}

function Get-AvailablePatterns {
    [CmdletBinding()]
    param()
    
    return @{
        SupportedPatterns = @("Singleton", "Factory", "Observer", "Strategy")
        Categories = @{
            Creational = @("Singleton", "Factory")
            Behavioral = @("Observer", "Strategy")
            Structural = @()  # Future implementation
        }
        ConfidenceThresholds = $script:PatternConfig.ConfidenceThresholds
        FeatureWeights = $script:PatternConfig.FeatureWeights
    }
}

function Set-PatternDetectionConfiguration {
    [CmdletBinding()]
    param(
        [hashtable] $ConfidenceThresholds,
        [hashtable] $FeatureWeights,
        [bool] $EnableDebugLogging
    )
    
    if ($ConfidenceThresholds) { 
        $script:PatternConfig.ConfidenceThresholds = $ConfidenceThresholds 
        Write-Debug "[PATTERN] Updated confidence thresholds"
    }
    
    if ($FeatureWeights) { 
        $script:PatternConfig.FeatureWeights = $FeatureWeights 
        Write-Debug "[PATTERN] Updated feature weights"
    }
    
    if ($PSBoundParameters.ContainsKey('EnableDebugLogging')) { 
        $script:PatternConfig.EnableDebugLogging = $EnableDebugLogging 
        Write-Debug "[PATTERN] Debug logging enabled: $EnableDebugLogging"
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Get-PowerShellAST',
    'Find-ClassDefinitions',
    'Find-FunctionDefinitions',
    'Get-SingletonPattern',
    'Get-FactoryPattern', 
    'Get-ObserverPattern',
    'Get-StrategyPattern',
    'Test-SingletonPattern',
    'Test-FactoryPattern',
    'Test-ObserverPattern',
    'Test-StrategyPattern',
    'Invoke-PatternDetection',
    'Get-PatternDetectionReport',
    'Get-AvailablePatterns',
    'Set-PatternDetectionConfiguration'
)