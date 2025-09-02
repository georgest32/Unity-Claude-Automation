# Unity-Claude-SemanticAnalysis-Business.psm1
# Business Logic Extraction Functions
# Part of Unity-Claude-SemanticAnalysis module

#region Business Logic Extraction

function Extract-BusinessLogic {
    <#
    .SYNOPSIS
    Extracts and categorizes business logic from code using semantic analysis.
    
    .DESCRIPTION
    Identifies business rules, validation logic, workflow patterns, and domain-specific
    operations within the codebase using CPG structural analysis.
    
    .PARAMETER Graph
    The CPG graph to analyze for business logic
    
    .PARAMETER UseCache
    Whether to use cached results if available
    
    .EXAMPLE
    $businessLogic = Extract-BusinessLogic -Graph $graph
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [switch]$UseCache = $true
    )
    
    begin {
        # Import helpers if needed
        if (-not (Get-Command Test-IsCPGraph -ErrorAction SilentlyContinue)) {
            Import-Module (Join-Path $PSScriptRoot "Unity-Claude-SemanticAnalysis-Helpers.psm1") -Force -Global
        }
        
        # Initialize cache if needed
        if (-not $script:UC_SA_Cache) { 
            $script:UC_SA_Cache = @{} 
        }
        
        if (-not (Test-IsCPGraph -Graph $Graph)) {
            throw "Invalid graph instance passed to $($MyInvocation.MyCommand.Name)"
        }
        
        $Graph = Ensure-GraphDuckType -Graph $Graph
        
        Write-Verbose "Extracting business logic from graph structure"
        
        $cacheKey = Get-CacheKey -Graph $Graph -Prefix "BUSINESS"
        
        if ($UseCache -and $script:UC_SA_Cache.ContainsKey($cacheKey)) {
            Write-Verbose "Extract-BusinessLogic cache hit"
            return ,$script:UC_SA_Cache[$cacheKey]
        }
    }
    
    process {
        $businessResults = @()
        
        try {
            # Extract validation rules
            $validationRules = Find-ValidationRules -Graph $Graph
            $businessResults += $validationRules
            
            # Extract business rules  
            $businessRules = Find-BusinessRules -Graph $Graph
            $businessResults += $businessRules
            
            # Extract workflow patterns
            $workflows = Find-WorkflowPatterns -Graph $Graph
            $businessResults += $workflows
            
            # Extract domain calculations
            $calculations = Find-DomainCalculations -Graph $Graph
            $businessResults += $calculations
            
            # Normalize results
            $businessResults = @($businessResults | ForEach-Object { 
                Normalize-AnalysisRecord -Record $_ -Kind 'Business' 
            })
            
            # Cache results
            if ($UseCache) {
                $script:UC_SA_Cache[$cacheKey] = $businessResults
            }
            
            Write-Verbose "Business logic extraction complete. Found $($businessResults.Count) logic patterns"
        }
        catch {
            Write-Verbose "Business logic extraction error: $($_.Exception.Message)"
            return @()
        }
    }
    
    end {
        if ($businessResults -eq $null) {
            return @()
        }
        return ,$businessResults
    }
}

function Find-ValidationRules {
    <#
    .SYNOPSIS
    Identifies validation rules in the code
    
    .PARAMETER Graph
    The CPG graph to analyze
    #>
    param($Graph)
    
    $validationRules = @()
    $functions = Unity-Claude-CPG\Get-CPGNode -Graph $Graph -Type Function
    $methods = Unity-Claude-CPG\Get-CPGNode -Graph $Graph -Type Method
    $allCallables = @()
    if ($functions) { $allCallables += @($functions) }
    if ($methods) { $allCallables += @($methods) }
    
    foreach ($callable in $allCallables) {
        $rules = @()
        $confidence = 0.0
        
        # Check function name patterns
        if ($callable.Name -match 'Valid|Check|Verify|Ensure|Test|Is[A-Z]') {
            $confidence += 0.4
            $rules += "Validation function name pattern"
        }
        
        # Check function body for validation patterns
        if ($callable.Properties -and $callable.Properties.Body) {
            $body = $callable.Properties.Body
            
            # Length/range validation
            if ($body -match 'length|count|size.*[<>=]') {
                $confidence += 0.3
                $rules += "Length/size validation"
            }
            
            # Format validation (email, phone, etc.)
            if ($body -match 'match.*@|phone|email|regex|pattern') {
                $confidence += 0.3
                $rules += "Format validation"
            }
            
            # Required field validation
            if ($body -match 'null|empty|blank|required') {
                $confidence += 0.2
                $rules += "Required field validation"
            }
            
            # Range validation
            if ($body -match 'minimum|maximum|range|between') {
                $confidence += 0.2
                $rules += "Range validation"
            }
            
            # Business rule validation
            if ($body -match 'discount|price|age|limit|quota|threshold') {
                $confidence += 0.3
                $rules += "Business rule validation detected"
            }
        }
        
        if ($confidence -gt 0.3 -and $rules.Count -gt 0) {
            $validationRules += [PSCustomObject]@{
                Type = 'ValidationRule'
                NodeId = $callable.Id
                NodeName = $callable.Name
                Confidence = [Math]::Round($confidence, 2)
                Rules = $rules
                FilePath = $callable.FilePath
                StartLine = $callable.StartLine
                Category = 'Validation'
                RuleType = 'ValidationRule'  # Added for test compatibility
            }
        }
    }
    
    return $validationRules
}

function Find-BusinessRules {
    <#
    .SYNOPSIS
    Identifies business rules and domain logic
    
    .PARAMETER Graph
    The CPG graph to analyze
    #>
    param($Graph)
    
    $businessRules = @()
    $functions = Unity-Claude-CPG\Get-CPGNode -Graph $Graph -Type Function
    $methods = Unity-Claude-CPG\Get-CPGNode -Graph $Graph -Type Method
    $allCallables = @()
    if ($functions) { $allCallables += @($functions) }
    if ($methods) { $allCallables += @($methods) }
    
    foreach ($callable in $allCallables) {
        $rules = @()
        $confidence = 0.0
        
        if ($callable.Properties -and $callable.Properties.Body) {
            $body = $callable.Properties.Body
            
            # Discount/pricing rules
            if ($body -match 'discount|price|cost|fee|charge|rate') {
                $confidence += 0.4
                $rules += "Pricing/discount logic"
            }
            
            # Inventory/stock rules
            if ($body -match 'inventory|stock|quantity|available|instock') {
                $confidence += 0.3
                $rules += "Inventory management"
            }
            
            # User/role rules  
            if ($body -match 'role|permission|access|authorize|admin|user') {
                $confidence += 0.3
                $rules += "Access control logic"
            }
            
            # Tax calculation
            if ($body -match 'tax|vat|gst|duty') {
                $confidence += 0.4
                $rules += "Tax calculation"
            }
            
            # Date/time business rules
            if ($body -match 'business.*hours|working.*days|holiday|weekend') {
                $confidence += 0.3
                $rules += "Business hours/calendar logic"
            }
            
            # Status/workflow rules
            if ($body -match 'status|state|pending|approved|rejected|cancelled') {
                $confidence += 0.3
                $rules += "Status/workflow management"
            }
        }
        
        if ($confidence -gt 0.3 -and $rules.Count -gt 0) {
            $businessRules += [PSCustomObject]@{
                Type = 'BusinessRule'
                NodeId = $callable.Id
                NodeName = $callable.Name
                Confidence = [Math]::Round($confidence, 2)
                Rules = $rules
                FilePath = $callable.FilePath
                StartLine = $callable.StartLine
                Category = 'Business'
                RuleType = 'BusinessRule'  # Added for test compatibility
            }
        }
    }
    
    return $businessRules
}

function Find-WorkflowPatterns {
    <#
    .SYNOPSIS
    Identifies workflow and process patterns
    
    .PARAMETER Graph
    The CPG graph to analyze
    #>
    param($Graph)
    
    $workflows = @()
    $functions = Unity-Claude-CPG\Get-CPGNode -Graph $Graph -Type Function
    $methods = Unity-Claude-CPG\Get-CPGNode -Graph $Graph -Type Method
    $allCallables = @()
    if ($functions) { $allCallables += @($functions) }
    if ($methods) { $allCallables += @($methods) }
    
    foreach ($callable in $allCallables) {
        $patterns = @()
        $confidence = 0.0
        
        # Check for workflow indicators in names
        if ($callable.Name -match 'Process|Handle|Execute|Run|Start|Complete|Finish') {
            $confidence += 0.3
            $patterns += "Workflow verb in name"
        }
        
        if ($callable.Properties -and $callable.Properties.Body) {
            $body = $callable.Properties.Body
            
            # Sequential processing patterns
            if ($body -match 'step|stage|phase|sequence') {
                $confidence += 0.3
                $patterns += "Sequential processing"
            }
            
            # State machine patterns
            if ($body -match 'switch.*state|if.*status.*else') {
                $confidence += 0.3
                $patterns += "State machine logic"
            }
            
            # Approval workflow
            if ($body -match 'approve|reject|review|submit') {
                $confidence += 0.4
                $patterns += "Approval workflow"
            }
            
            # Pipeline patterns
            if ($body -match 'pipeline|queue|batch|job') {
                $confidence += 0.3
                $patterns += "Pipeline/batch processing"
            }
        }
        
        if ($confidence -gt 0.3 -and $patterns.Count -gt 0) {
            $workflows += [PSCustomObject]@{
                Type = 'WorkflowPattern'
                NodeId = $callable.Id
                NodeName = $callable.Name
                Confidence = [Math]::Round($confidence, 2)
                Rules = $patterns
                FilePath = $callable.FilePath
                StartLine = $callable.StartLine
                Category = 'Workflow'
                RuleType = 'WorkflowRule'  # Added for test compatibility
            }
        }
    }
    
    return $workflows
}

function Find-DomainCalculations {
    <#
    .SYNOPSIS
    Identifies domain-specific calculations and formulas
    
    .PARAMETER Graph
    The CPG graph to analyze
    #>
    param($Graph)
    
    $calculations = @()
    $functions = Unity-Claude-CPG\Get-CPGNode -Graph $Graph -Type Function
    $methods = Unity-Claude-CPG\Get-CPGNode -Graph $Graph -Type Method
    $allCallables = @()
    if ($functions) { $allCallables += @($functions) }
    if ($methods) { $allCallables += @($methods) }
    
    foreach ($callable in $allCallables) {
        $formulas = @()
        $confidence = 0.0
        
        # Check for calculation indicators in names
        if ($callable.Name -match 'Calcul|Comput|Total|Sum|Average|Rate|Percent') {
            $confidence += 0.4
            $formulas += "Calculation function name"
        }
        
        if ($callable.Properties -and $callable.Properties.Body) {
            $body = $callable.Properties.Body
            
            # Mathematical operations
            if ($body -match '\+|\-|\*|\/|\%|\^|sqrt|pow|round') {
                $confidence += 0.2
                $formulas += "Mathematical operations"
            }
            
            # Financial calculations
            if ($body -match 'interest|principal|compound|amortize|depreciat') {
                $confidence += 0.4
                $formulas += "Financial calculations"
            }
            
            # Statistical calculations
            if ($body -match 'average|median|variance|deviation|correlation') {
                $confidence += 0.4
                $formulas += "Statistical calculations"
            }
            
            # Domain-specific formulas
            if ($body -match 'formula|equation|algorithm') {
                $confidence += 0.3
                $formulas += "Domain formula implementation"
            }
        }
        
        if ($confidence -gt 0.3 -and $formulas.Count -gt 0) {
            $calculations += [PSCustomObject]@{
                Type = 'DomainCalculation'
                NodeId = $callable.Id
                NodeName = $callable.Name
                Confidence = [Math]::Round($confidence, 2)
                Rules = $formulas
                FilePath = $callable.FilePath
                StartLine = $callable.StartLine
                Category = 'Calculation'
                RuleType = 'CalculationRule'  # Added for test compatibility
            }
        }
    }
    
    return $calculations
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Extract-BusinessLogic',
    'Find-ValidationRules',
    'Find-BusinessRules',
    'Find-WorkflowPatterns',
    'Find-DomainCalculations'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBEUF0SgLz8Jbzs
# kI7BVz8qeUpO64c1noUV4HV2sJ0P06CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMY2nwvcGs2XJfGKoBr2eSm6
# 9Ic7OjhDuNQfQadyEfaFMA0GCSqGSIb3DQEBAQUABIIBAG+BML8DkiDGFLKSp9I2
# bHFvq4Yl/JMMSrHQVUcrE7DVkw1BGoa40BsaAwBTDu2OyRTTU3cJQzxRpUbDY+0K
# dOuzChHNsNcmIzMKasW9pJ38Xgf762PzViHh0cn2/CuUBvLkXRS3qfweX4H8757y
# lRtWw1HnaI4MyTPOTEQg+H7cqiiYaXf9qZeDkvfyoiTeuIOwD1Czm/GXivexg/5k
# yBp5yOMC7mOy63MCN20/onVtwElTjAX137ac6pZENCYQ1TZM3se5mvKrYOwMa0Ww
# KOTbEom9lA+jZHtj6DPGvdxi6Z/8oLfsjo9o+R+JRpwzNPuYnr2D+HpG2WntvDfS
# 644=
# SIG # End signature block
