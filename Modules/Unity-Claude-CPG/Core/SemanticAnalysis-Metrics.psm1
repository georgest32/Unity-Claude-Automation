#
# SemanticAnalysis-Metrics.psm1
# Advanced code quality metrics including cohesion, coupling, and maintainability analysis
# Part of Unity-Claude-CPG Enhanced Documentation System
# Created: 2025-08-28
#

# Import required dependencies
$cpgModule = Join-Path (Split-Path $PSScriptRoot -Parent) "Unity-Claude-CPG.psd1"
if (Test-Path $cpgModule) {
    Import-Module $cpgModule -Force -ErrorAction SilentlyContinue
}

# Import complexity metrics for integration
$complexityModule = Join-Path $PSScriptRoot "CodeComplexityMetrics.psm1"
if (Test-Path $complexityModule) {
    Import-Module $complexityModule -Force -ErrorAction SilentlyContinue
}

# Metrics configuration
$script:MetricsConfig = @{
    DefaultCohesionThreshold = 0.7
    DefaultCouplingThreshold = 5
    EnableDetailedLogging = $true
    MaintainabilityIndexVersion = "Enhanced"  # Standard, Enhanced
}

#
# Cohesion Analysis Functions
#

function Get-CHMCohesionAtMessageLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        $ClassInfo,
        
        [Parameter(Mandatory=$true)]
        $AST
    )
    
    # Defensive parameter validation (Research Pattern #5)
    if ($null -eq $ClassInfo) {
        Write-Warning "[CHM] Null ClassInfo parameter received - returning default cohesion value"
        return @{
            CHM = 0.0
            InternalMethodCalls = 0
            TotalMethodInteractions = 0
            CohesionLevel = "Unknown"
            Warning = "ClassInfo was null - unable to calculate cohesion"
        }
    }
    
    # Enhanced class validation
    if (-not $ClassInfo.Methods) {
        Write-Warning "[CHM] ClassInfo missing Methods property - returning default cohesion value"
        return @{
            CHM = 0.0
            InternalMethodCalls = 0  
            TotalMethodInteractions = 0
            CohesionLevel = "Unknown"
            Warning = "ClassInfo missing Methods property"
        }
    }
    
    Write-Debug "[METRICS] Calculating CHM (Cohesion at Message Level) for class: $($ClassInfo.Name)"
    
    # Analyze method-to-method communication patterns within the class
    $internalMethodCalls = 0
    $totalMethodInteractions = 0
    
    foreach ($method in $ClassInfo.Methods) {
        Write-Debug "[METRICS] CHM: Analyzing method $($method.Name) for internal calls"
        
        # Find method calls within this method - focus on member expressions with 'this'
        $memberCalls = $method.Body.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.InvokeMemberExpressionAst] -and
            $node.Expression -is [System.Management.Automation.Language.VariableExpressionAst] -and
            $node.Expression.VariablePath.UserPath -eq "this"
        }, $true)
        
        # Also find direct method calls that could be internal (PowerShell allows omitting 'this')
        $potentialInternalCalls = $method.Body.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.InvokeMemberExpressionAst] -and
            -not ($node.Expression -is [System.Management.Automation.Language.VariableExpressionAst] -and
                  $node.Expression.VariablePath.UserPath -eq "this")
        }, $true)
        
        # Count all method interactions
        $allMethodCalls = $memberCalls + $potentialInternalCalls
        $totalMethodInteractions += $allMethodCalls.Count
        
        Write-Debug "[METRICS] CHM: Found $($memberCalls.Count) explicit 'this' calls and $($potentialInternalCalls.Count) potential internal calls"
        
        # Process explicit 'this' method calls (definitely internal)
        foreach ($call in $memberCalls) {
            $calledMethod = if ($call.Member -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                $call.Member.Value
            } else {
                $call.Member.ToString()
            }
            
            # Verify the called method exists in current class
            $isInternalCall = $ClassInfo.Methods | Where-Object { $_.Name -eq $calledMethod }
            
            if ($isInternalCall) {
                $internalMethodCalls++
                Write-Debug "[METRICS] CHM: Found confirmed internal method call from $($method.Name) to $calledMethod via 'this'"
            }
        }
        
        # Process potential internal calls (check if method name matches class methods)
        foreach ($call in $potentialInternalCalls) {
            $calledMethod = if ($call.Member -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                $call.Member.Value
            } else {
                $call.Member.ToString()
            }
            
            # Only count as internal if it matches a class method AND doesn't appear to be external
            $isInternalCall = $ClassInfo.Methods | Where-Object { $_.Name -eq $calledMethod }
            
            # Additional check: ensure it's not a call on another object/variable
            $isThisImplied = -not ($call.Expression -is [System.Management.Automation.Language.VariableExpressionAst] -and
                                   $call.Expression.VariablePath.UserPath -ne "this")
            
            if ($isInternalCall -and $isThisImplied) {
                $internalMethodCalls++
                Write-Debug "[METRICS] CHM: Found potential internal method call from $($method.Name) to $calledMethod"
            }
        }
    }
    
    # Calculate CHM metric
    $chm = if ($totalMethodInteractions -gt 0) {
        [math]::Round($internalMethodCalls / $totalMethodInteractions, 3)
    } else {
        1.0  # Perfect cohesion if no interactions
    }
    
    Write-Debug "[METRICS] CHM calculated: $chm (Internal: $internalMethodCalls, Total: $totalMethodInteractions)"
    
    return @{
        CHM = $chm
        InternalMethodCalls = $internalMethodCalls
        TotalMethodInteractions = $totalMethodInteractions
        CohesionLevel = if ($chm -ge 0.7) { "High" } elseif ($chm -ge 0.4) { "Medium" } else { "Low" }
    }
}

function Get-CHDCohesionAtDomainLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $ModuleInfo,
        
        [string] $DomainContext = "General"
    )
    
    Write-Debug "[METRICS] Calculating CHD (Cohesion at Domain Level) for module with $($ModuleInfo.Functions.Count) functions"
    
    # Define domain-specific function categories based on naming patterns
    $domainCategories = @{
        DataAccess = @("Get-*", "Set-*", "Find-*", "Search-*", "Query-*", "Read-*", "Write-*")
        Security = @("*Auth*", "*Credential*", "*Permission*", "*Validate*", "*Encrypt*", "*Decrypt*")
        UI = @("Show-*", "Hide-*", "*Window*", "*Dialog*", "*Form*", "Display-*")
        Processing = @("Process-*", "Transform-*", "Convert-*", "Parse-*", "Analyze-*")
        Configuration = @("*Config*", "*Setting*", "Initialize-*", "Setup-*")
        Logging = @("Write-*Log*", "*Debug*", "Trace-*", "Log-*")
        Testing = @("Test-*", "*Mock*", "*Stub*", "Assert-*", "Verify-*")
        Utility = @("*Utility*", "*Helper*", "*Tool*", "Format-*", "Compare-*")
    }
    
    # Categorize functions by domain
    $categorizedFunctions = @{}
    $uncategorizedCount = 0
    
    foreach ($function in $ModuleInfo.Functions) {
        $categorized = $false
        
        foreach ($category in $domainCategories.Keys) {
            $patterns = $domainCategories[$category]
            
            foreach ($pattern in $patterns) {
                if ($function.Name -like $pattern) {
                    if (-not $categorizedFunctions.ContainsKey($category)) {
                        $categorizedFunctions[$category] = @()
                    }
                    $categorizedFunctions[$category] += $function
                    $categorized = $true
                    break
                }
            }
            
            if ($categorized) { break }
        }
        
        if (-not $categorized) {
            $uncategorizedCount++
        }
    }
    
    # Find dominant domain
    $dominantCategory = $null
    $maxCount = 0
    
    foreach ($category in $categorizedFunctions.Keys) {
        $count = $categorizedFunctions[$category].Count
        if ($count -gt $maxCount) {
            $maxCount = $count
            $dominantCategory = $category
        }
    }
    
    # Calculate CHD metric
    $domainRelatedFunctions = if ($dominantCategory) { $maxCount } else { 0 }
    $totalFunctions = $ModuleInfo.Functions.Count
    
    $chd = if ($totalFunctions -gt 0) {
        [math]::Round($domainRelatedFunctions / $totalFunctions, 3)
    } else {
        0.0
    }
    
    Write-Debug "[METRICS] CHD calculated: $chd (Domain: $domainRelatedFunctions, Total: $totalFunctions, Dominant: $dominantCategory)"
    
    return @{
        CHD = $chd
        DominantDomain = $dominantCategory
        DomainRelatedFunctions = $domainRelatedFunctions
        TotalFunctions = $totalFunctions
        UncategorizedFunctions = $uncategorizedCount
        FunctionCategories = $categorizedFunctions
        CohesionLevel = if ($chd -ge 0.7) { "High" } elseif ($chd -ge 0.4) { "Medium" } else { "Low" }
    }
}

#
# Coupling Analysis Functions
#

function Get-CBOCouplingBetweenObjects {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $ClassInfo,
        
        [Parameter(Mandatory=$true)]
        $AllClasses,
        
        [Parameter(Mandatory=$true)]
        $AST
    )
    
    Write-Debug "[METRICS] Calculating CBO (Coupling Between Objects) for class: $($ClassInfo.Name)"
    
    $coupledClasses = @{}
    $afferentCoupling = 0  # Classes that depend on this class
    $efferentCoupling = 0  # Classes this class depends on
    
    # Analyze efferent coupling (dependencies this class has)
    foreach ($method in $ClassInfo.Methods) {
        # Find type references in method parameters and body
        $typeReferences = $method.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.TypeExpressionAst] -or
            $node -is [System.Management.Automation.Language.TypeConstraintAst]
        }, $true)
        
        foreach ($typeRef in $typeReferences) {
            $typeName = $typeRef.TypeName.Name
            
            # Check if this is a reference to another class in our analysis
            $referencedClass = $AllClasses | Where-Object { $_.Name -eq $typeName }
            
            if ($referencedClass -and $referencedClass.Name -ne $ClassInfo.Name) {
                if (-not $coupledClasses.ContainsKey($typeName)) {
                    $coupledClasses[$typeName] = @{
                        Name = $typeName
                        CouplingType = "Efferent"
                        References = 0
                    }
                    $efferentCoupling++
                }
                $coupledClasses[$typeName].References++
                
                Write-Debug "[METRICS] CBO: Found efferent coupling to $typeName"
            }
        }
    }
    
    # Analyze afferent coupling (classes that depend on this class)
    foreach ($otherClass in $AllClasses) {
        if ($otherClass.Name -eq $ClassInfo.Name) { continue }
        
        # Check if other class references this class
        $references = $otherClass.AST.FindAll({
            param($node)
            ($node -is [System.Management.Automation.Language.TypeExpressionAst] -and $node.TypeName.Name -eq $ClassInfo.Name) -or
            ($node -is [System.Management.Automation.Language.TypeConstraintAst] -and $node.TypeName.Name -eq $ClassInfo.Name)
        }, $true)
        
        if ($references.Count -gt 0) {
            $afferentCoupling++
            Write-Debug "[METRICS] CBO: Found afferent coupling from $($otherClass.Name)"
        }
    }
    
    $totalCoupling = $efferentCoupling + $afferentCoupling
    $instability = if (($efferentCoupling + $afferentCoupling) -gt 0) {
        [math]::Round($efferentCoupling / ($efferentCoupling + $afferentCoupling), 3)
    } else {
        0.0
    }
    
    Write-Debug "[METRICS] CBO completed: Total=$totalCoupling, Efferent=$efferentCoupling, Afferent=$afferentCoupling, Instability=$instability"
    
    return @{
        CBO = $totalCoupling
        EfferentCoupling = $efferentCoupling
        AfferentCoupling = $afferentCoupling
        Instability = $instability
        CoupledClasses = $coupledClasses
        CouplingLevel = if ($totalCoupling -le 3) { "Low" } elseif ($totalCoupling -le 7) { "Medium" } else { "High" }
    }
}

function Get-LCOMCohesionInMethods {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $ClassInfo
    )
    
    Write-Debug "[METRICS] Calculating LCOM (Lack of Cohesion in Methods) for class: $($ClassInfo.Name)"
    
    $methodPairs = 0
    $sharedAttributePairs = 0
    $noSharedAttributePairs = 0
    
    # Get all instance variables (properties) used by methods
    $propertyAccess = @{}
    
    foreach ($method in $ClassInfo.Methods) {
        $propertyAccess[$method.Name] = @()
        
        # Find property access in method body
        $memberAccess = $method.Body.FindAll({
            param($node)
            $node -is [System.Management.Automation.Language.MemberExpressionAst] -and
            $node.Expression -is [System.Management.Automation.Language.VariableExpressionAst] -and
            $node.Expression.VariablePath.UserPath -eq "this"
        }, $true)
        
        foreach ($access in $memberAccess) {
            $propertyName = $access.Member.Value
            if ($propertyName -and $propertyAccess[$method.Name] -notcontains $propertyName) {
                $propertyAccess[$method.Name] += $propertyName
                Write-Debug "[METRICS] LCOM: Method $($method.Name) accesses property $propertyName"
            }
        }
    }
    
    # Calculate method pairs and shared attribute relationships
    $methods = $ClassInfo.Methods
    for ($i = 0; $i -lt $methods.Count; $i++) {
        for ($j = $i + 1; $j -lt $methods.Count; $j++) {
            $methodPairs++
            $method1 = $methods[$i].Name
            $method2 = $methods[$j].Name
            
            # Check for shared attribute access
            $sharedAttributes = $propertyAccess[$method1] | Where-Object { $propertyAccess[$method2] -contains $_ }
            
            if ($sharedAttributes.Count -gt 0) {
                $sharedAttributePairs++
                Write-Debug "[METRICS] LCOM: Methods $method1 and $method2 share $($sharedAttributes.Count) attributes"
            } else {
                $noSharedAttributePairs++
            }
        }
    }
    
    # Calculate LCOM value
    $lcom = [math]::Max(0, $noSharedAttributePairs - $sharedAttributePairs)
    $lcomNormalized = if ($methodPairs -gt 0) {
        [math]::Round($lcom / $methodPairs, 3)
    } else {
        0.0
    }
    
    Write-Debug "[METRICS] LCOM calculated: $lcom (normalized: $lcomNormalized) from $methodPairs method pairs"
    
    return @{
        LCOM = $lcom
        LCOMNormalized = $lcomNormalized
        MethodPairs = $methodPairs
        SharedAttributePairs = $sharedAttributePairs
        NoSharedAttributePairs = $noSharedAttributePairs
        PropertyAccessMap = $propertyAccess
        CohesionQuality = if ($lcomNormalized -le 0.2) { "High" } elseif ($lcomNormalized -le 0.5) { "Medium" } else { "Low" }
    }
}

function Get-CHDCohesionAtDomainLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $ModuleInfo,
        
        [string] $DomainContext = "General"
    )
    
    Write-Debug "[METRICS] Calculating CHD (Cohesion at Domain Level) for module with $($ModuleInfo.Functions.Count) functions"
    
    # Define domain-specific function categories based on naming patterns and functionality
    $domainCategories = @{
        DataAccess = @("Get-*", "Set-*", "Find-*", "Search-*", "Query-*", "Read-*", "Write-*", "Save-*", "Load-*", "Fetch-*")
        Security = @("*Auth*", "*Credential*", "*Permission*", "*Validate*", "*Encrypt*", "*Decrypt*", "*Hash*", "*Sign*")
        UI = @("Show-*", "Hide-*", "*Window*", "*Dialog*", "*Form*", "Display-*", "*View*", "Render-*")
        Processing = @("Process-*", "Transform-*", "Convert-*", "Parse-*", "Analyze-*", "Calculate-*", "Compute-*")
        Configuration = @("*Config*", "*Setting*", "Initialize-*", "Setup-*", "Register-*", "Install-*")
        Logging = @("Write-*Log*", "*Debug*", "Trace-*", "Log-*", "Record-*", "Report-*")
        Testing = @("Test-*", "*Mock*", "*Stub*", "Assert-*", "Verify-*", "Validate-*")
        Networking = @("Connect-*", "Disconnect-*", "Send-*", "Receive-*", "*HTTP*", "*Web*", "*Socket*")
        FileSystem = @("*File*", "*Directory*", "*Path*", "Copy-*", "Move-*", "Remove-*", "New-Item*")
        Utility = @("*Utility*", "*Helper*", "*Tool*", "Format-*", "Compare-*", "Measure-*", "Sort-*")
    }
    
    # Categorize functions by domain
    $categorizedFunctions = @{}
    $functionDomainMap = @{}
    
    foreach ($function in $ModuleInfo.Functions) {
        $matchedCategories = @()
        
        foreach ($category in $domainCategories.Keys) {
            $patterns = $domainCategories[$category]
            
            foreach ($pattern in $patterns) {
                if ($function.Name -like $pattern) {
                    $matchedCategories += $category
                    
                    if (-not $categorizedFunctions.ContainsKey($category)) {
                        $categorizedFunctions[$category] = @()
                    }
                    $categorizedFunctions[$category] += $function
                    break
                }
            }
        }
        
        $functionDomainMap[$function.Name] = if ($matchedCategories.Count -gt 0) { $matchedCategories } else { @("Uncategorized") }
    }
    
    # Find dominant domain and calculate cohesion
    $dominantCategory = $null
    $maxCount = 0
    $totalFunctions = $ModuleInfo.Functions.Count
    
    foreach ($category in $categorizedFunctions.Keys) {
        $count = $categorizedFunctions[$category].Count
        if ($count -gt $maxCount) {
            $maxCount = $count
            $dominantCategory = $category
        }
    }
    
    # Calculate CHD metric
    $domainRelatedFunctions = if ($dominantCategory) { $maxCount } else { 0 }
    $chd = if ($totalFunctions -gt 0) {
        [math]::Round($domainRelatedFunctions / $totalFunctions, 3)
    } else {
        0.0
    }
    
    # Calculate domain distribution entropy (lower entropy = higher cohesion)
    $entropy = 0.0
    if ($categorizedFunctions.Keys.Count -gt 1) {
        foreach ($category in $categorizedFunctions.Keys) {
            $proportion = $categorizedFunctions[$category].Count / $totalFunctions
            if ($proportion -gt 0) {
                $entropy += $proportion * [math]::Log($proportion, 2)
            }
        }
        $entropy = -$entropy
    }
    
    Write-Debug "[METRICS] CHD calculated: $chd (Domain: $domainRelatedFunctions/$totalFunctions, Entropy: $([math]::Round($entropy, 3)))"
    
    return @{
        CHD = $chd
        DominantDomain = $dominantCategory
        DomainRelatedFunctions = $domainRelatedFunctions
        TotalFunctions = $totalFunctions
        DomainEntropy = [math]::Round($entropy, 3)
        FunctionCategories = $categorizedFunctions
        FunctionDomainMap = $functionDomainMap
        CohesionLevel = if ($chd -ge 0.7) { "High" } elseif ($chd -ge 0.4) { "Medium" } else { "Low" }
    }
}

#
# Enhanced Maintainability Index
#

function Get-EnhancedMaintainabilityIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        $CodeAnalysisResult,
        
        [hashtable] $CohesionMetrics,
        [hashtable] $CouplingMetrics
    )
    
    Write-Debug "[METRICS] Calculating Enhanced Maintainability Index"
    
    # Get base metrics (integrate with existing CodeComplexityMetrics if available)
    $cyclomaticComplexity = if ($CodeAnalysisResult.CyclomaticComplexity) { 
        $CodeAnalysisResult.CyclomaticComplexity 
    } else { 
        10  # Default moderate complexity
    }
    
    $halsteadVolume = if ($CodeAnalysisResult.HalsteadVolume) { 
        $CodeAnalysisResult.HalsteadVolume 
    } else { 
        100  # Default moderate volume
    }
    
    $linesOfCode = if ($CodeAnalysisResult.LinesOfCode) { 
        $CodeAnalysisResult.LinesOfCode 
    } else { 
        50  # Default moderate LOC
    }
    
    # Standard Maintainability Index formula
    $standardMI = [math]::Max(0, 
        171 - 
        5.2 * [math]::Log($halsteadVolume) - 
        0.23 * $cyclomaticComplexity - 
        16.2 * [math]::Log($linesOfCode)
    )
    
    # Enhanced formula incorporating cohesion and coupling
    $cohesionBonus = 0.0
    $couplingPenalty = 0.0
    
    if ($CohesionMetrics) {
        # Higher cohesion improves maintainability
        $avgCohesion = 0
        $cohesionCount = 0
        
        if ($CohesionMetrics.CHM) { $avgCohesion += $CohesionMetrics.CHM; $cohesionCount++ }
        if ($CohesionMetrics.CHD) { $avgCohesion += $CohesionMetrics.CHD; $cohesionCount++ }
        if ($CohesionMetrics.LCOM -and $CohesionMetrics.LCOMNormalized) { 
            $avgCohesion += (1.0 - $CohesionMetrics.LCOMNormalized); $cohesionCount++ 
        }
        
        if ($cohesionCount -gt 0) {
            $avgCohesion = $avgCohesion / $cohesionCount
            $cohesionBonus = $avgCohesion * 20  # Up to 20 point bonus for high cohesion
        }
    }
    
    if ($CouplingMetrics) {
        # Higher coupling reduces maintainability
        $couplingScore = if ($CouplingMetrics.CBO) { $CouplingMetrics.CBO } else { 0 }
        $couplingPenalty = [math]::Min(30, $couplingScore * 3)  # Up to 30 point penalty for high coupling
    }
    
    $enhancedMI = [math]::Max(0, [math]::Min(100, $standardMI + $cohesionBonus - $couplingPenalty))
    
    Write-Debug "[METRICS] Maintainability Index: Standard=$([math]::Round($standardMI, 1)), Enhanced=$([math]::Round($enhancedMI, 1))"
    
    return @{
        StandardMI = [math]::Round($standardMI, 1)
        EnhancedMI = [math]::Round($enhancedMI, 1)
        CohesionBonus = [math]::Round($cohesionBonus, 1)
        CouplingPenalty = [math]::Round($couplingPenalty, 1)
        BaseMetrics = @{
            CyclomaticComplexity = $cyclomaticComplexity
            HalsteadVolume = $halsteadVolume
            LinesOfCode = $linesOfCode
        }
        QualityLevel = if ($enhancedMI -ge 85) { "Excellent" } 
                      elseif ($enhancedMI -ge 70) { "Good" } 
                      elseif ($enhancedMI -ge 50) { "Fair" } 
                      else { "Poor" }
    }
}

#
# Comprehensive Quality Analysis
#

function Get-ComprehensiveQualityMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $FilePath,
        
        [string] $OutputPath
    )
    
    Write-Debug "[METRICS] Starting comprehensive quality analysis for: $FilePath"
    
    $startTime = Get-Date
    
    # Parse the file
    $astResult = Get-PowerShellAST -FilePath $FilePath
    if (-not $astResult) {
        Write-Error "[METRICS] Failed to parse file: $FilePath"
        return $null
    }
    
    # Get structural information
    $classes = Find-ClassDefinitions -AST $astResult.AST
    $functions = Find-FunctionDefinitions -AST $astResult.AST
    
    Write-Debug "[METRICS] Analysis scope: $($classes.Count) classes, $($functions.Count) functions"
    
    $qualityReport = @{
        FilePath = $FilePath
        AnalysisDate = $startTime
        Summary = @{
            TotalClasses = $classes.Count
            TotalFunctions = $functions.Count
            OverallQuality = "Pending"
        }
        ClassMetrics = @()
        ModuleMetrics = $null
        Recommendations = @()
    }
    
    # Analyze each class
    foreach ($class in $classes) {
        Write-Debug "[METRICS] Analyzing class: $($class.Name)"
        
        # Calculate cohesion metrics
        $chmResult = Get-CHMCohesionAtMessageLevel -ClassInfo $class -AST $astResult.AST
        $lcomResult = Get-LCOMCohesionInMethods -ClassInfo $class
        
        # Calculate coupling metrics  
        $cboResult = Get-CBOCouplingBetweenObjects -ClassInfo $class -AllClasses $classes -AST $astResult.AST
        
        # Calculate maintainability index
        $miResult = Get-EnhancedMaintainabilityIndex -CodeAnalysisResult @{} -CohesionMetrics @{
            CHM = $chmResult.CHM
            LCOM = $lcomResult.LCOM
            LCOMNormalized = $lcomResult.LCOMNormalized
        } -CouplingMetrics @{
            CBO = $cboResult.CBO
        }
        
        $classMetrics = @{
            ClassName = $class.Name
            Cohesion = @{
                CHM = $chmResult
                LCOM = $lcomResult
            }
            Coupling = $cboResult
            Maintainability = $miResult
            QualityScore = [math]::Round(($chmResult.CHM * 0.3 + (1.0 - $lcomResult.LCOMNormalized) * 0.3 + (1.0 - $cboResult.Instability) * 0.4), 3)
        }
        
        $qualityReport.ClassMetrics += $classMetrics
    }
    
    # Module-level analysis
    if ($functions.Count -gt 0) {
        $moduleInfo = @{
            Functions = $functions
            Classes = $classes
        }
        
        $chdResult = Get-CHDCohesionAtDomainLevel -ModuleInfo $moduleInfo
        $qualityReport.ModuleMetrics = @{
            CHD = $chdResult
            FunctionCount = $functions.Count
            ClassCount = $classes.Count
            DomainCohesion = $chdResult.CHD
        }
    }
    
    # Generate recommendations
    $avgQualityScore = if ($qualityReport.ClassMetrics.Count -gt 0) {
        ($qualityReport.ClassMetrics | ForEach-Object { $_.QualityScore } | Measure-Object -Average).Average
    } else {
        0.5
    }
    
    $qualityReport.Summary.OverallQuality = if ($avgQualityScore -ge 0.8) { "Excellent" }
                                          elseif ($avgQualityScore -ge 0.6) { "Good" }
                                          elseif ($avgQualityScore -ge 0.4) { "Fair" }
                                          else { "Poor" }
    
    # Add specific recommendations
    foreach ($classMetric in $qualityReport.ClassMetrics) {
        if ($classMetric.Cohesion.CHM.CHM -lt 0.5) {
            $qualityReport.Recommendations += "Consider improving method cohesion in class $($classMetric.ClassName) (CHM: $($classMetric.Cohesion.CHM.CHM))"
        }
        
        if ($classMetric.Coupling.CouplingLevel -eq "High") {
            $qualityReport.Recommendations += "Reduce coupling for class $($classMetric.ClassName) (CBO: $($classMetric.Coupling.CBO))"
        }
        
        if ($classMetric.Maintainability.QualityLevel -eq "Poor") {
            $qualityReport.Recommendations += "Improve maintainability of class $($classMetric.ClassName) (MI: $($classMetric.Maintainability.EnhancedMI))"
        }
    }
    
    $endTime = Get-Date
    $qualityReport.AnalysisDuration = $endTime - $startTime
    
    Write-Debug "[METRICS] Quality analysis complete for $FilePath in $($qualityReport.AnalysisDuration.TotalSeconds) seconds"
    
    # Save report if output path specified
    if ($OutputPath) {
        $qualityReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Debug "[METRICS] Quality report saved to: $OutputPath"
    }
    
    return $qualityReport
}

function Get-QualityMetricsConfiguration {
    [CmdletBinding()]
    param()
    
    return @{
        SupportedMetrics = @("CHM", "CHD", "LCOM", "CBO", "MaintainabilityIndex")
        CohesionMetrics = @{
            CHM = "Cohesion at Message Level - Method interaction analysis"
            CHD = "Cohesion at Domain Level - Functional domain grouping"
            LCOM = "Lack of Cohesion in Methods - Attribute sharing analysis"
        }
        CouplingMetrics = @{
            CBO = "Coupling Between Objects - Class dependency analysis"
            EfferentCoupling = "Outgoing dependencies"
            AfferentCoupling = "Incoming dependencies"
            Instability = "Coupling instability metric"
        }
        QualityThresholds = @{
            Cohesion = @{ High = 0.7; Medium = 0.4; Low = 0.0 }
            Coupling = @{ Low = 3; Medium = 7; High = 999 }
            Maintainability = @{ Excellent = 85; Good = 70; Fair = 50; Poor = 0 }
        }
    }
}

function Set-QualityMetricsConfiguration {
    [CmdletBinding()]
    param(
        [hashtable] $CohesionThresholds,
        [hashtable] $CouplingThresholds,
        [bool] $EnableDetailedLogging
    )
    
    if ($CohesionThresholds) {
        $script:MetricsConfig.DefaultCohesionThreshold = $CohesionThresholds.High
        Write-Debug "[METRICS] Updated cohesion thresholds"
    }
    
    if ($CouplingThresholds) {
        $script:MetricsConfig.DefaultCouplingThreshold = $CouplingThresholds.Medium
        Write-Debug "[METRICS] Updated coupling thresholds"
    }
    
    if ($PSBoundParameters.ContainsKey('EnableDetailedLogging')) {
        $script:MetricsConfig.EnableDetailedLogging = $EnableDetailedLogging
        Write-Debug "[METRICS] Detailed logging enabled: $EnableDetailedLogging"
    }
}

# Import AST analysis functions if they don't exist
if (-not (Get-Command Get-PowerShellAST -ErrorAction SilentlyContinue)) {
    # Include basic AST functions from pattern detector if needed
    Write-Debug "[METRICS] AST functions not available, using internal implementations"
}

# Export module functions
Export-ModuleMember -Function @(
    'Get-CHMCohesionAtMessageLevel',
    'Get-CHDCohesionAtDomainLevel',
    'Get-LCOMCohesionInMethods',
    'Get-CBOCouplingBetweenObjects',
    'Get-EnhancedMaintainabilityIndex',
    'Get-ComprehensiveQualityMetrics',
    'Get-QualityMetricsConfiguration',
    'Set-QualityMetricsConfiguration'
)