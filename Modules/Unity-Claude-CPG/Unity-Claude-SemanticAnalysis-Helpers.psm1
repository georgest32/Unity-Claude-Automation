# Unity-Claude-SemanticAnalysis-Helpers.psm1
# Shared helper functions for semantic analysis
# Part of Unity-Claude-SemanticAnalysis module

#region Module Variables and Initialization

# Thread-safe storage for semantic analysis data
$script:PatternCache = [hashtable]::Synchronized(@{})
$script:PurposeClassificationCache = [hashtable]::Synchronized(@{})
$script:QualityMetricsCache = [hashtable]::Synchronized(@{})
$script:BusinessLogicCache = [hashtable]::Synchronized(@{})

# Cache for expensive computations
if (-not $script:UC_SA_Cache) { 
    $script:UC_SA_Cache = @{} 
}

# Pattern confidence thresholds
$script:PatternThresholds = @{
    Singleton = 0.8
    Factory = 0.7
    Observer = 0.75
    Strategy = 0.7
    Command = 0.7
    Decorator = 0.75
}

# Complexity thresholds based on 2025 best practices
$script:ComplexityThresholds = @{
    CyclomaticLow = 5
    CyclomaticModerate = 10
    CyclomaticHigh = 20
    CognitiveLow = 5
    CognitiveModerate = 15
    CognitiveHigh = 25
}

#endregion

#region Helper Functions

function Test-IsCPGraph {
    <#
    .SYNOPSIS
    Tests if an object is a valid CPG graph
    
    .DESCRIPTION
    Validates that an object has the expected CPG graph structure and methods
    
    .PARAMETER Graph
    The object to test
    #>
    param($Graph)
    
    if ($null -eq $Graph) { return $false }
    
    # Check for essential methods (CPG graph uses different method names)
    $requiredMethods = @('GetNodesByType', 'GetNode', 'get_Edges')
    foreach ($method in $requiredMethods) {
        if (-not ($Graph.PSObject.Methods.Name -contains $method)) {
            return $false
        }
    }
    
    return $true
}

function Ensure-GraphDuckType {
    <#
    .SYNOPSIS
    Ensures a graph object has all required methods for semantic analysis
    
    .DESCRIPTION
    Adds missing methods to graph objects to ensure compatibility
    
    .PARAMETER Graph
    The graph to enhance
    #>
    param($Graph)
    
    if ($null -eq $Graph) { 
        throw "Cannot enhance null graph" 
    }
    
    # Add GetNodesByType if missing
    if (-not ($Graph.PSObject.Methods.Name -contains 'GetNodesByType')) {
        Add-Member -InputObject $Graph -MemberType ScriptMethod -Name GetNodesByType -Force -Value {
            param([string]$Type)
            Unity-Claude-CPG\Get-CPGNode -Graph $this -Type $Type
        } | Out-Null
    }
    
    # Add GetEdges if missing
    if (-not ($Graph.PSObject.Methods.Name -contains 'GetEdges')) {
        Add-Member -InputObject $Graph -MemberType ScriptMethod -Name GetEdges -Force -Value {
            Unity-Claude-CPG\Get-CPGEdge -Graph $this
        } | Out-Null
    }
    
    # Add GetNodeById if missing
    if (-not ($Graph.PSObject.Methods.Name -contains 'GetNodeById')) {
        Add-Member -InputObject $Graph -MemberType ScriptMethod -Name GetNodeById -Force -Value {
            param($Id)
            $this.GetNodeById($Id)
        } | Out-Null
    }
    
    # Add GetNeighbors if missing
    if (-not ($Graph.PSObject.Methods.Name -contains 'GetNeighbors')) {
        Add-Member -InputObject $Graph -MemberType ScriptMethod -Name GetNeighbors -Force -Value {
            param($NodeId, [ValidateSet('In','Out','Both')]$Direction = 'Both')
            $neighbors = @()
            $allEdges = Unity-Claude-CPG\Get-CPGEdge -Graph $this
            switch ($Direction) {
                'Out' {
                    $neighbors = $allEdges | Where-Object { $_.SourceId -eq $NodeId } |
                        ForEach-Object { $_.TargetId }
                }
                'In' {
                    $neighbors = $allEdges | Where-Object { $_.TargetId -eq $NodeId } |
                        ForEach-Object { $_.SourceId }
                }
                'Both' {
                    $neighbors = @(
                        ($allEdges | Where-Object { $_.SourceId -eq $NodeId } | ForEach-Object { $_.TargetId }),
                        ($allEdges | Where-Object { $_.TargetId -eq $NodeId } | ForEach-Object { $_.SourceId })
                    )
                }
            }
            # Return node objects if available
            $nodesById = @{}
            foreach ($n in (Unity-Claude-CPG\Get-CPGNode -Graph $this)) { 
                $nodesById[$n.Id] = $n 
            }
            $neighbors | ForEach-Object { 
                if ($nodesById.ContainsKey($_)) { $nodesById[$_] } else { $_ } 
            }
        } | Out-Null
    }
    
    # Add Nodes property if missing
    if (-not ($Graph.PSObject.Properties.Name -contains 'Nodes')) {
        Add-Member -InputObject $Graph -MemberType ScriptProperty -Name Nodes -Force -Value {
            [pscustomobject]@{
                Values = (Unity-Claude-CPG\Get-CPGNode -Graph $this)
            }
        } | Out-Null
    }
    
    # Add Edges property if missing
    if (-not ($Graph.PSObject.Properties.Name -contains 'Edges')) {
        Add-Member -InputObject $Graph -MemberType ScriptProperty -Name Edges -Force -Value {
            [pscustomobject]@{
                Values = (Unity-Claude-CPG\Get-CPGEdge -Graph $this)
            }
        } | Out-Null
    }
    
    return $Graph
}

function Ensure-Array {
    <#
    .SYNOPSIS
    Ensures a value is an array
    
    .DESCRIPTION
    Converts single values to arrays and returns arrays as-is
    
    .PARAMETER Value
    The value to ensure is an array
    #>
    param($Value)
    
    if ($null -eq $Value) { return @() }
    if ($Value -is [array]) { return $Value }
    return @($Value)
}

function Normalize-AnalysisRecord {
    <#
    .SYNOPSIS
    Normalizes analysis records to ensure consistent structure
    
    .DESCRIPTION
    Ensures all analysis records have required properties with appropriate types
    
    .PARAMETER Record
    The record to normalize
    
    .PARAMETER Kind
    The type of record (Pattern, Purpose, Business, Cohesion)
    #>
    param(
        [Parameter(Mandatory)] $Record,
        [ValidateSet('Pattern','Purpose','Business','Cohesion')]
        [string]$Kind
    )
    
    # Coerce hashtable to PSCustomObject for consistent property access
    if ($Record -is [hashtable]) {
        $Record = [PSCustomObject]$Record
    }
    
    switch ($Kind) {
        'Pattern' {
            if (-not $Record.PSObject.Properties['Type'])       { $Record | Add-Member Type 'Unknown' -Force }
            if (-not $Record.PSObject.Properties['PatternType']) { 
                $patternType = if ($Record.PSObject.Properties['Type']) { $Record.Type } else { 'Unknown' }
                $Record | Add-Member PatternType $patternType -Force 
            }
            if (-not $Record.PSObject.Properties['Confidence']) { $Record | Add-Member Confidence ([double]0.6) -Force }
            if (-not $Record.PSObject.Properties['Evidence'])   { $Record | Add-Member Evidence @() -Force }
            if ($Record.Confidence -isnot [double])             { $Record.Confidence = [double]$Record.Confidence }
            $Record.Evidence = Ensure-Array $Record.Evidence
        }
        
        'Purpose' {
            if (-not $Record.PSObject.Properties['Purpose'])    { $Record | Add-Member Purpose 'Unknown' -Force }
            if (-not $Record.PSObject.Properties['Confidence']) { $Record | Add-Member Confidence ([double]0.2) -Force }
            if (-not $Record.PSObject.Properties['Evidence'])   { $Record | Add-Member Evidence @() -Force }
            if ($Record.Confidence -isnot [double])             { $Record.Confidence = [double]$Record.Confidence }
            $Record.Evidence = Ensure-Array $Record.Evidence
        }
        
        'Business' {
            if (-not $Record.PSObject.Properties['Type'])       { $Record | Add-Member Type 'BusinessRule' -Force }
            if (-not $Record.PSObject.Properties['Category'])   { $Record | Add-Member Category 'General' -Force }
            if (-not $Record.PSObject.Properties['Confidence']) { $Record | Add-Member Confidence ([double]0.5) -Force }
            if (-not $Record.PSObject.Properties['Evidence'])   { $Record | Add-Member Evidence @() -Force }
            if ($Record.Confidence -isnot [double])             { $Record.Confidence = [double]$Record.Confidence }
            $Record.Evidence = Ensure-Array $Record.Evidence
        }
        
        'Cohesion' {
            foreach ($k in 'CHM','CHD','OverallCohesion') {
                if (-not $Record.PSObject.Properties[$k]) { $Record | Add-Member -Name $k -Value ([double]0) -Force }
                $v = [double]$Record.$k
                if ([double]::IsNaN($v)) { $v = 0 }
                $Record.$k = [Math]::Round([double](Clamp01 $v), 3)
            }
        }
    }
    
    return $Record
}

function Get-CacheKey {
    <#
    .SYNOPSIS
    Generates a cache key for analysis results
    
    .DESCRIPTION
    Creates a unique cache key based on graph characteristics and parameters
    
    .PARAMETER Graph
    The graph being analyzed
    
    .PARAMETER Prefix
    A prefix for the cache key
    
    .PARAMETER Parameters
    Additional parameters to include in the key
    #>
    param(
        $Graph,
        [string]$Prefix,
        [hashtable]$Parameters = @{}
    )
    
    $graphId = if ($Graph.PSObject.Properties['Id'] -and $Graph.Id) { 
        $Graph.Id 
    } else { 
        $nodeCount = (Unity-Claude-CPG\Get-CPGNode -Graph $Graph).Count
        $edgeCount = (Unity-Claude-CPG\Get-CPGEdge -Graph $Graph).Count
        "graph-$nodeCount-$edgeCount"
    }
    
    $paramString = ($Parameters.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ':'
    
    return "$Prefix::$graphId::$paramString"
}

#endregion

#region Export

Export-ModuleMember -Function @(
    'Test-IsCPGraph',
    'Ensure-GraphDuckType',
    'Ensure-Array',
    'Normalize-AnalysisRecord',
    'Get-CacheKey',
    'Clamp01'
) -Variable @(
    'UC_SA_Cache',
    'PatternThresholds',
    'ComplexityThresholds'
)
#region Missing Helper Functions

function Get-CacheKey {
    param(
        $Graph,
        [string]$Prefix
    )
    
    $graphId = if ($Graph -and $Graph.PSObject.Properties['Id'] -and $Graph.Id) { 
        $Graph.Id 
    } else { 
        "ANON" 
    }
    
    return "$Prefix::$graphId"
}

function Ensure-GraphDuckType {
    param($Graph)
    
    # Add missing methods/properties if needed
    if (-not $Graph.PSObject.Properties['Nodes'] -or -not $Graph.Nodes) {
        Add-Member -InputObject $Graph -MemberType NoteProperty -Name 'Nodes' -Value @{} -Force
    }
    
    if (-not $Graph.PSObject.Properties['Edges'] -or -not $Graph.Edges) {
        Add-Member -InputObject $Graph -MemberType NoteProperty -Name 'Edges' -Value @{} -Force
    }
    
    return $Graph
}

function Normalize-AnalysisRecord {
    param(
        $Record,
        [string]$Kind
    )
    
    if (-not $Record) { 
        return $null 
    }
    
    # Ensure consistent structure while preserving pattern-specific properties
    $normalized = [PSCustomObject]@{
        Kind = $Kind
        Purpose = if ($Record.PSObject.Properties['Purpose']) { $Record.Purpose } else { "Unknown" }
        Confidence = if ($Record.PSObject.Properties['Confidence']) { $Record.Confidence } else { 0.5 }
        Analysis = if ($Record.PSObject.Properties['Analysis']) { $Record.Analysis } else { @{} }
        Location = if ($Record.PSObject.Properties['Location']) { $Record.Location } else { @{} }
        Timestamp = Get-Date
    }
    
    # Preserve PatternType property for patterns
    if ($Kind -eq 'Pattern' -and $Record.PSObject.Properties['PatternType']) {
        Add-Member -InputObject $normalized -MemberType NoteProperty -Name 'PatternType' -Value $Record.PatternType -Force
    }
    
    # Preserve Type property as an alias for PatternType
    if ($Kind -eq 'Pattern' -and $Record.PSObject.Properties['Type']) {
        Add-Member -InputObject $normalized -MemberType NoteProperty -Name 'Type' -Value $Record.Type -Force
        # Also add PatternType if not already present
        if (-not $normalized.PSObject.Properties['PatternType']) {
            Add-Member -InputObject $normalized -MemberType NoteProperty -Name 'PatternType' -Value $Record.Type -Force
        }
    }
    
    # Preserve Cohesion-specific properties
    if ($Kind -eq 'Cohesion') {
        if ($Record.PSObject.Properties['CHM']) {
            Add-Member -InputObject $normalized -MemberType NoteProperty -Name 'CHM' -Value $Record.CHM -Force
        }
        if ($Record.PSObject.Properties['CHD']) {
            Add-Member -InputObject $normalized -MemberType NoteProperty -Name 'CHD' -Value $Record.CHD -Force
        }
        if ($Record.PSObject.Properties['OverallCohesion']) {
            Add-Member -InputObject $normalized -MemberType NoteProperty -Name 'OverallCohesion' -Value $Record.OverallCohesion -Force
        }
        if ($Record.PSObject.Properties['Module']) {
            Add-Member -InputObject $normalized -MemberType NoteProperty -Name 'Module' -Value $Record.Module -Force
        }
        if ($Record.PSObject.Properties['Coupling']) {
            Add-Member -InputObject $normalized -MemberType NoteProperty -Name 'Coupling' -Value $Record.Coupling -Force
        }
    }
    
    # Preserve Business Logic-specific properties
    if ($Kind -eq 'Business') {
        if ($Record.PSObject.Properties['RuleType']) {
            Add-Member -InputObject $normalized -MemberType NoteProperty -Name 'RuleType' -Value $Record.RuleType -Force
        }
        if ($Record.PSObject.Properties['Category']) {
            Add-Member -InputObject $normalized -MemberType NoteProperty -Name 'Category' -Value $Record.Category -Force
        }
        if ($Record.PSObject.Properties['Rules']) {
            Add-Member -InputObject $normalized -MemberType NoteProperty -Name 'Rules' -Value $Record.Rules -Force
        }
        if ($Record.PSObject.Properties['Evidence']) {
            Add-Member -InputObject $normalized -MemberType NoteProperty -Name 'Evidence' -Value $Record.Evidence -Force
        }
    }
    
    return $normalized
}

function Classify-CallablePurpose {
    param(
        $Node,
        $Graph
    )
    
    if (-not $Node -or -not $Node.Name) {
        return $null
    }
    
    $name = $Node.Name
    $confidence = 0.5
    $purpose = "General"
    
    # Simple heuristics based on naming patterns
    switch -Regex ($name) {
        '^Get-|^Retrieve-|^Find-|^Search-' { 
            $purpose = "DataRetrieval"
            $confidence = 0.8
        }
        '^Set-|^Update-|^Modify-|^Change-' { 
            $purpose = "DataModification"
            $confidence = 0.8
        }
        '^New-|^Create-|^Add-|^Insert-' { 
            $purpose = "DataCreation"
            $confidence = 0.8
        }
        '^Remove-|^Delete-|^Clear-' { 
            $purpose = "DataDeletion"
            $confidence = 0.8
        }
        '^Test-|^Validate-|^Check-|^Verify-' { 
            $purpose = "Validation"
            $confidence = 0.8
        }
        '^Convert-|^Transform-|^Parse-|^Format-' { 
            $purpose = "DataTransformation"
            $confidence = 0.8
        }
        '^Send-|^Submit-|^Post-|^Publish-' { 
            $purpose = "Communication"
            $confidence = 0.8
        }
    }
    
    return [PSCustomObject]@{
        NodeId = if ($Node.PSObject.Properties['Id']) { $Node.Id } else { [guid]::NewGuid().ToString() }
        Name = $name
        Purpose = $purpose
        Confidence = $confidence
        Type = "Function"
        Analysis = @{
            NamingPattern = $true
            ParameterCount = if ($Node.PSObject.Properties['Parameters']) { $Node.Parameters.Count } else { 0 }
        }
        Location = @{
            FilePath = if ($Node.PSObject.Properties['FilePath']) { $Node.FilePath } else { "Unknown" }
            StartLine = if ($Node.PSObject.Properties['StartLine']) { $Node.StartLine } else { 0 }
        }
    }
}

function Classify-ClassPurpose {
    param(
        $Node,
        $Graph
    )
    
    if (-not $Node -or -not $Node.Name) {
        return $null
    }
    
    $name = $Node.Name
    $confidence = 0.5
    $purpose = "General"
    
    # Simple heuristics for class purposes
    switch -Regex ($name) {
        'Manager$|Controller$|Service$' { 
            $purpose = "BusinessLogic"
            $confidence = 0.8
        }
        'Model$|Entity$|Data$' { 
            $purpose = "DataModel"
            $confidence = 0.8
        }
        'View$|UI$|Form$|Dialog$' { 
            $purpose = "UserInterface"
            $confidence = 0.8
        }
        'Helper$|Utility$|Utils$' { 
            $purpose = "Utility"
            $confidence = 0.8
        }
        'Test$|Mock$|Stub$' { 
            $purpose = "Testing"
            $confidence = 0.9
        }
    }
    
    return [PSCustomObject]@{
        NodeId = if ($Node.PSObject.Properties['Id']) { $Node.Id } else { [guid]::NewGuid().ToString() }
        Name = $name
        Purpose = $purpose
        Confidence = $confidence
        Type = "Class"
        Analysis = @{
            NamingPattern = $true
            MethodCount = 0  # Could be enhanced
        }
        Location = @{
            FilePath = if ($Node.PSObject.Properties['FilePath']) { $Node.FilePath } else { "Unknown" }
            StartLine = if ($Node.PSObject.Properties['StartLine']) { $Node.StartLine } else { 0 }
        }
    }
}

# --- Session-persistent cache bootstrap (re-import safe) ---
if (-not $script:UC_SA_Cache) {
    if ($global:UC_SA_Cache -and $global:UC_SA_Cache -is [hashtable]) {
        $script:UC_SA_Cache = $global:UC_SA_Cache
    } else {
        $script:UC_SA_Cache = @{}
        $global:UC_SA_Cache = $script:UC_SA_Cache
    }
}

function Ensure-Array {
    param($x)
    if ($null -eq $x) { return @() }
    if ($x -is [System.Array]) { return $x }
    return @($x)
}

function Clamp01 {
    param($Value)
    if ($null -eq $Value) { return 0 }
    $d = [double]$Value
    if ($d -lt 0) { return 0 }
    if ($d -gt 1) { return 1 }
    return $d
}

function Canonicalize-PatternTypes {
    param([string[]]$PatternTypes)
    $allSupported = @('Singleton','Factory') # extend if you add more
    if (-not $PatternTypes -or $PatternTypes.Count -eq 0) { return $allSupported }
    $norm = foreach ($p in $PatternTypes) {
        switch -Regex ($p) {
            '^(singleton)' { 'Singleton' ; break }
            '^(factory)'   { 'Factory'   ; break }
            default        { $p }
        }
    }
    $norm = @($norm | Where-Object { $_ -in $allSupported })
    if ($norm.Count -eq 0) { $norm = $allSupported }
    return @($norm | Sort-Object)
}

#endregion


# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDAdA8rWdd/gpLJ
# e8aZ9FeEhBvkNusjerSPu5XjyvZbuKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOextSoSvO7C4PxuiNPV3imD
# 9amyE05O45MDAG4XTW4kMA0GCSqGSIb3DQEBAQUABIIBAJ+309SvNSHQSjeucHCk
# iJFMbPMe4/6A5dA3OkCZQHGKv6Ye77520oE0+pJZr10LhzZf8bxYC5ZjM4m/MoNy
# zvn5T4jvOts+U7aMoYtlHJ9gDggJ/UTOiQvWeB2XVa7LxsOb81Brj+pFavZI6D+j
# zi2H/oIjwU7RCCjBqigAEoFvkhTQcxmz6ZdWzxo2lgEmetwlBYk+9exJe9jnkrrO
# kn2QWWweH3o05bJQmCy+AaYh+txRmnJyGJLgXWYKj/Hpejuz5MZfSmi/NZq4+j04
# o6LI+2K6Zcv+u72k/8Il7sF3NYyObQkfxDFsq31XpvBNnaoxqphf8Pt+8bfu+PLR
# Pg0=
# SIG # End signature block
