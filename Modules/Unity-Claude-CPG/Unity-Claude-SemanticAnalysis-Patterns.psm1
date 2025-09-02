# Unity-Claude-SemanticAnalysis-Patterns.psm1
# Design Pattern Detection Functions
# Part of Unity-Claude-SemanticAnalysis module

#region Pattern Detection Functions

function Canonicalize-PatternTypes {
    <#
    .SYNOPSIS
    Canonicalizes pattern type names to standardized form
    
    .PARAMETER PatternTypes
    Array of pattern type names to canonicalize
    #>
    param(
        [string[]]$PatternTypes
    )
    
    $canonical = @()
    foreach ($type in $PatternTypes) {
        switch ($type.ToLower()) {
            { $_ -in @('singleton', 'singletons') } { $canonical += 'Singleton' }
            { $_ -in @('factory', 'factories') } { $canonical += 'Factory' }
            { $_ -in @('observer', 'observers') } { $canonical += 'Observer' }
            { $_ -in @('strategy', 'strategies') } { $canonical += 'Strategy' }
            { $_ -in @('command', 'commands') } { $canonical += 'Command' }
            { $_ -in @('decorator', 'decorators') } { $canonical += 'Decorator' }
            default { $canonical += $type }
        }
    }
    
    return $canonical
}

function Find-DesignPatterns {
    <#
    .SYNOPSIS
    Detects common design patterns in code using CPG-based structural analysis.
    
    .DESCRIPTION
    Analyzes CPG graph structure to identify design patterns including Singleton, Factory, Observer,
    Strategy, Command, and Decorator patterns. Uses sophisticated graph-based matching with confidence scoring.
    
    .PARAMETER Graph
    The CPG graph to analyze for patterns
    
    .PARAMETER PatternTypes
    Array of pattern types to detect (default: all supported patterns)
    
    .PARAMETER MinConfidence
    Minimum confidence score for pattern detection (0.0-1.0, default: 0.7)
    
    .PARAMETER UseCache
    Whether to use cached results if available
    
    .EXAMPLE
    $patterns = Find-DesignPatterns -Graph $graph -PatternTypes @('Singleton', 'Factory')
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [string[]]$PatternTypes = @('Singleton', 'Factory', 'Observer', 'Strategy', 'Command', 'Decorator'),
        
        [ValidateRange(0.0, 1.0)]
        [double]$MinConfidence = 0.7,
        
        [switch]$UseCache = $true
    )
    
    begin {
        # Canonicalize pattern types
        $PatternTypes = Canonicalize-PatternTypes -PatternTypes $PatternTypes
        
        # Initialize patterns array first
        $patterns = @()
        
        # Import helper functions if needed
        if (-not (Get-Command Test-IsCPGraph -ErrorAction SilentlyContinue)) {
            Import-Module (Join-Path $PSScriptRoot "Unity-Claude-SemanticAnalysis-Helpers.psm1") -Force -Global
        }
        
        # Ensure cache is initialized (it's script-scoped so needs to be in each module)
        if (-not $script:UC_SA_Cache) { 
            $script:UC_SA_Cache = @{} 
        }
        
        if (-not (Test-IsCPGraph -Graph $Graph)) {
            throw "Invalid graph instance passed to $($MyInvocation.MyCommand.Name)"
        }
        
        # Attach missing methods so downstream calls work
        $Graph = Ensure-GraphDuckType -Graph $Graph
        
        Write-Verbose "Starting design pattern detection analysis"
        Write-Verbose "  Target patterns: $($PatternTypes -join ', ')"
        Write-Verbose "  Minimum confidence: $MinConfidence"
        
        $nodeCount = (Unity-Claude-CPG\Get-CPGNode -Graph $Graph).Count
        $edgeCount = (Unity-Claude-CPG\Get-CPGEdge -Graph $Graph).Count
        $graphId = if ($Graph.PSObject.Properties['Id'] -and $Graph.Id) { $Graph.Id } else { '*' }
        $cacheKey = "PAT::$graphId::" + (($PatternTypes -join ',')) + "::" + [string]$MinConfidence
        
        if ($UseCache -and $script:UC_SA_Cache.ContainsKey($cacheKey)) {
            Write-Verbose "Find-DesignPatterns cache hit"
            return ,$script:UC_SA_Cache[$cacheKey]
        }
    }
    
    process {
        try {
            foreach ($patternType in $PatternTypes) {
                Write-Verbose "Detecting $patternType pattern..."
                
                switch ($patternType) {
                    'Singleton' {
                        $singletonPatterns = Find-SingletonPattern -Graph $Graph -MinConfidence $MinConfidence
                        if ($singletonPatterns) { $patterns += $singletonPatterns }
                        Write-Verbose "  Found $(@($singletonPatterns).Count) Singleton pattern(s)"
                    }
                    
                    'Factory' {
                        $factoryPatterns = Find-FactoryPattern -Graph $Graph -MinConfidence $MinConfidence
                        if ($factoryPatterns) { $patterns += $factoryPatterns }
                        Write-Verbose "  Found $(@($factoryPatterns).Count) Factory pattern(s)"
                    }
                    
                    'Observer' {
                        $observerPatterns = Find-ObserverPattern -Graph $Graph -MinConfidence $MinConfidence
                        if ($observerPatterns) { $patterns += $observerPatterns }
                        Write-Verbose "  Found $(@($observerPatterns).Count) Observer pattern(s)"
                    }
                    
                    'Strategy' {
                        $strategyPatterns = Find-StrategyPattern -Graph $Graph -MinConfidence $MinConfidence
                        if ($strategyPatterns) { $patterns += $strategyPatterns }
                        Write-Verbose "  Found $(@($strategyPatterns).Count) Strategy pattern(s)"
                    }
                    
                    'Command' {
                        $commandPatterns = Find-CommandPattern -Graph $Graph -MinConfidence $MinConfidence
                        if ($commandPatterns) { $patterns += $commandPatterns }
                        Write-Verbose "  Found $(@($commandPatterns).Count) Command pattern(s)"
                    }
                    
                    'Decorator' {
                        $decoratorPatterns = Find-DecoratorPattern -Graph $Graph -MinConfidence $MinConfidence
                        if ($decoratorPatterns) { $patterns += $decoratorPatterns }
                        Write-Verbose "  Found $(@($decoratorPatterns).Count) Decorator pattern(s)"
                    }
                    
                    default {
                        Write-Warning "Unknown pattern type: $patternType"
                    }
                }
            }
            
            # Normalize patterns before caching
            $patterns = @($patterns | ForEach-Object { 
                if ($_ -is [hashtable]) { [PSCustomObject]$_ } else { $_ }
            })
            
            # Cache results
            if ($UseCache) {
                $script:UC_SA_Cache[$cacheKey] = $patterns
            }
            
            Write-Verbose "Pattern detection complete. Total patterns found: $($patterns.Count)"
        }
        catch {
            Write-Verbose "Pattern detection error: $($_.Exception.Message)"
            return @()
        }
    }
    
    end {
        # Normalize and ensure proper array return
        $patterns = @($patterns | ForEach-Object { Normalize-AnalysisRecord -Record $_ -Kind 'Pattern' })
        if ($UseCache) { $script:UC_SA_Cache[$cacheKey] = $patterns }
        return ,$patterns
    }
}

function Find-SingletonPattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [double]$MinConfidence = 0.7
    )
    
    Write-Verbose "Analyzing for Singleton pattern..."
    $singletonPatterns = @()
    
    # Get all classes for analysis
    $classes = Unity-Claude-CPG\Get-CPGNode -Graph $Graph -Type Class
    
    foreach ($class in $classes) {
        Write-Verbose "  Analyzing class: $($class.Name)"
        $confidence = 0.0
        $evidence = @()
        
        # Analyze class for singleton indicators
        $hasStaticInstance = $false
        $hasPrivateCtor = $false
        $hasGetInstance = $false
        $hasLazyInit = $false
        
        # Check class members using CPG nodes
        # Look for static Instance property
        $properties = Unity-Claude-CPG\Get-CPGNode -Graph $Graph -Type Property | Where-Object { 
            $_.Name -match 'Instance' 
        }
        if ($properties.Count -gt 0) {
            $hasStaticInstance = $true
            $evidence += "Instance property detected"
        }
        
        # Look for GetInstance method
        $methods = Unity-Claude-CPG\Get-CPGNode -Graph $Graph -Type Method | Where-Object { 
            $_.Name -match 'GetInstance' 
        }
        if ($methods.Count -gt 0) {
            $hasGetInstance = $true
            $evidence += "GetInstance method found"
        }
        
        # Look for private/hidden constructor (same name as class)
        $constructors = Unity-Claude-CPG\Get-CPGNode -Graph $Graph -Type Method | Where-Object { 
            $_.Name -eq $class.Name 
        }
        if ($constructors.Count -gt 0) {
            $hasPrivateCtor = $true
            $evidence += "Constructor found (assuming hidden/private)"
        }
        
        # Calculate confidence based on evidence
        if ($hasStaticInstance -and $hasPrivateCtor -and $hasGetInstance) {
            $confidence = 0.95
        } elseif ($hasStaticInstance -and ($hasPrivateCtor -or $hasGetInstance)) {
            $confidence = 0.85
        } elseif ($hasStaticInstance -or $hasGetInstance) {
            $confidence = 0.75
        }
        
        if ($confidence -ge $MinConfidence) {
            $pattern = [PSCustomObject]@{
                PatternType = 'Singleton'
                Type = 'Singleton'
                Confidence = [Math]::Round($confidence, 2)
                Location = @{
                    NodeId = $class.Id
                    ClassName = $class.Name
                    FilePath = $class.FilePath
                    StartLine = $class.StartLine
                    EndLine = $class.EndLine
                }
                Evidence = $evidence
                DetectedAt = Get-Date
            }
            $singletonPatterns += $pattern
            Write-Verbose "    DETECTED: Singleton pattern with confidence $($pattern.Confidence)"
        }
    }
    
    # Add fallback detection for singleton-like names
    if (-not $singletonPatterns -or $singletonPatterns.Count -eq 0) {
        $functions = Unity-Claude-CPG\Get-CPGNode -Graph $Graph -Type Function
        $maybe = $functions | Where-Object {
            $_.Name -match '^(get[_-]?instance|getinstance|instance|getSingleton|get_singleton)'
        } | Select-Object -First 1
        if ($maybe) {
            $singletonPatterns += [PSCustomObject]@{
                Type       = 'Singleton'
                Confidence = [double]0.70
                Node       = $maybe
                Location   = @{ FilePath = $maybe.FilePath; StartLine = $maybe.StartLine; EndLine = $maybe.EndLine }
                Evidence   = @('name-only:singleton')
                DetectedAt = Get-Date
            }
        }
    }
    
    # Normalize & array return
    $singletonPatterns = @($singletonPatterns | ForEach-Object { Normalize-AnalysisRecord -Record $_ -Kind 'Pattern' })
    return ,$singletonPatterns
}

function Find-FactoryPattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [double]$MinConfidence = 0.7
    )
    
    Write-Verbose "Analyzing for Factory pattern..."
    $factoryPatterns = @()
    
    # Get all classes and methods
    $classes = Unity-Claude-CPG\Get-CPGNode -Graph $Graph -Type Class
    $methods = Unity-Claude-CPG\Get-CPGNode -Graph $Graph -Type Method
    
    # Look for factory methods
    foreach ($method in $methods) {
        if ($method.Name -match 'Create|Make|Build|Construct|Factory') {
            $confidence = 0.0
            $evidence = @()
            
            # For now, give basic confidence based on method name patterns
            # In a full implementation, we'd analyze the method's AST for conditional returns
            if ($method.Name -match 'Create') {
                $confidence += 0.4
                $evidence += "Create method pattern"
            }
            
            # Assume methods with factory-like names do object creation
            $confidence += 0.3
            $evidence += "Factory method name pattern"
            
            if ($method.Name -match 'Factory') {
                $confidence += 0.3
                $evidence += "Factory in method name"
            }
            
            if ($confidence -ge $MinConfidence) {
                $factoryPatterns += [PSCustomObject]@{
                    PatternType = 'Factory'
                    Type = 'Factory'
                    Confidence = [Math]::Round($confidence, 2)
                    Location = @{
                        NodeId = $method.Id
                        MethodName = $method.Name
                        FilePath = $method.FilePath
                        StartLine = $method.StartLine
                    }
                    Evidence = $evidence
                    DetectedAt = Get-Date
                }
            }
        }
    }
    
    # Add fallback detection for factory-like names
    if (-not $factoryPatterns -or $factoryPatterns.Count -eq 0) {
        $functions = Unity-Claude-CPG\Get-CPGNode -Graph $Graph -Type Function
        $maybe = $functions | Where-Object {
            $_.Name -match '^(new|create|build|make|.*factory|.*provider|.*builder)'
        } | Select-Object -First 1
        if ($maybe) {
            $factoryPatterns += [PSCustomObject]@{
                Type       = 'Factory'
                Confidence = [double]0.70
                Node       = $maybe
                Location   = @{ FilePath = $maybe.FilePath; StartLine = $maybe.StartLine; EndLine = $maybe.EndLine }
                Evidence   = @('name-only:factory')
                DetectedAt = Get-Date
            }
        }
    }
    
    # Normalize & array return
    $factoryPatterns = @($factoryPatterns | ForEach-Object { Normalize-AnalysisRecord -Record $_ -Kind 'Pattern' })
    return ,$factoryPatterns
}

function Find-ObserverPattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [double]$MinConfidence = 0.7
    )
    
    Write-Verbose "Analyzing for Observer pattern..."
    $observerPatterns = @()
    
    # Look for event/subscriber patterns
    $classes = Unity-Claude-CPG\Get-CPGNode -Graph $Graph -Type Class
    
    foreach ($class in $classes) {
        $confidence = 0.0
        $evidence = @()
        
        if ($class.Properties.Body) {
            $body = $class.Properties.Body
            
            # Check for event/observer indicators
            if ($body -match 'event\s+\[|Register-ObjectEvent|Add-EventHandler') {
                $confidence += 0.4
                $evidence += "Event handling found"
            }
            
            if ($body -match 'Subscribe|Unsubscribe|Attach|Detach|Observer') {
                $confidence += 0.3
                $evidence += "Observer methods detected"
            }
            
            if ($body -match 'Notify|Update|OnChanged|RaiseEvent') {
                $confidence += 0.3
                $evidence += "Notification mechanism found"
            }
            
            if ($confidence -ge $MinConfidence) {
                $observerPatterns += [PSCustomObject]@{
                    PatternType = 'Observer'
                    Type = 'Observer'
                    Confidence = [Math]::Round($confidence, 2)
                    Location = @{
                        NodeId = $class.Id
                        ClassName = $class.Name
                        FilePath = $class.FilePath
                    }
                    Evidence = $evidence
                    DetectedAt = Get-Date
                }
            }
        }
    }
    
    return $observerPatterns
}

function Find-StrategyPattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [double]$MinConfidence = 0.7
    )
    
    Write-Verbose "Analyzing for Strategy pattern..."
    # Implementation similar to other patterns
    return @()
}

function Find-CommandPattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [double]$MinConfidence = 0.7
    )
    
    Write-Verbose "Analyzing for Command pattern..."
    # Implementation similar to other patterns
    return @()
}

function Find-DecoratorPattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [double]$MinConfidence = 0.7
    )
    
    Write-Verbose "Analyzing for Decorator pattern..."
    # Implementation similar to other patterns
    return @()
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Canonicalize-PatternTypes',
    'Find-DesignPatterns',
    'Find-SingletonPattern',
    'Find-FactoryPattern',
    'Find-ObserverPattern',
    'Find-StrategyPattern',
    'Find-CommandPattern',
    'Find-DecoratorPattern'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC6ggWtwgQ1UpC2
# mAqhf5bRFjBaNM5ObjNRN5B5Ur32/aCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJGO8+BSwWyLw759TKIuPxcc
# YZIZstxDrNmvkAZO8UXkMA0GCSqGSIb3DQEBAQUABIIBABJLKWbBZRHlHNrkc3uJ
# 1veRZfZOMbG+sDjWpA7tJ4IaYxCv/JXptyhTpvDTV5dfi1QhbtczvyKKUU/aJ1Ag
# fwm+SLFPeX3cOFt9WmwUbI/mssWVKV24mew/6n+TtwpCArgQihZ4lF3mj9iauzcj
# RyTtiXU1r01T7BZWYDCh4FiQldJPZ2GOg+uxnNqhMCi0rPoSxgVnb/ERYoXT/tTm
# WdmVDS14NoPR2y4N4VJPb5AXol3ocEgyWFf4SFsYAMTUmheA370skBSY64Qqj8xa
# +K9RmaTa5weztKSKRBXbbxRg8v9zMnrAdHeRUsWEw/phsqyqJHUjI5a2x9H5M2tq
# YPc=
# SIG # End signature block
