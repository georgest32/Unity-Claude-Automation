# Unity-Claude-SemanticAnalysis-Purpose.psm1
# Code Purpose Classification Functions
# Part of Unity-Claude-SemanticAnalysis module

#region Purpose Classification

function Get-CodePurpose {
    <#
    .SYNOPSIS
    Classifies the primary purpose of code segments using semantic analysis.
    
    .DESCRIPTION
    Analyzes code structure and naming patterns to determine the primary purpose
    (CRUD operations, validation, transformation, etc.) with confidence scoring.
    
    .PARAMETER Graph
    The CPG graph to analyze
    
    .PARAMETER UseCache
    Whether to use cached results if available
    
    .EXAMPLE
    $purpose = Get-CodePurpose -Graph $graph
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
        
        Write-Verbose "Analyzing code purpose from graph structure"
        
        $cacheKey = Get-CacheKey -Graph $Graph -Prefix "PURPOSE"
        
        if ($UseCache -and $script:UC_SA_Cache.ContainsKey($cacheKey)) {
            Write-Verbose "Get-CodePurpose cache hit"
            return ,$script:UC_SA_Cache[$cacheKey]
        }
    }
    
    process {
        $purposeResults = @()
        
        try {
            # Analyze functions/methods with broader collection
            $funcNodes   = Unity-Claude-CPG\Get-CPGNode -Graph $Graph -Type 'Function'
            $methodNodes = Unity-Claude-CPG\Get-CPGNode -Graph $Graph -Type 'Method'
            $targetNodes = @()
            if ($funcNodes) { $targetNodes += @($funcNodes) }
            if ($methodNodes) { $targetNodes += @($methodNodes) }
            $targetNodes = @($targetNodes | Where-Object { $_ })
            
            foreach ($node in $targetNodes) {
                if (-not $node -or -not $node.Name) { continue }
                
                $quickPurpose = $null
                $nameSafe = $node.Name
                
                # Quick CRUD mapping with fallback
                if ($nameSafe -match '^(get|read|fetch|load|list|find|search|query|select|retrieve|pull)') { 
                    $quickPurpose = 'Read' 
                } elseif ($nameSafe -match '^(new|create|add|insert|post|build|make|generate|init|initialize|provision|allocate)') { 
                    $quickPurpose = 'Create' 
                } elseif ($nameSafe -match '^(set|update|put|patch|edit|modify|change|upsert|save|store|persist|write|sync)') { 
                    $quickPurpose = 'Update' 
                } elseif ($nameSafe -match '^(remove|delete|del|drop|destroy|clear|purge|erase|archive|deactivate)') { 
                    $quickPurpose = 'Delete' 
                } elseif ($nameSafe -match '^(validate|verify|check|ensure|assert|test|confirm|is|has|guard|authorize)') { 
                    $quickPurpose = 'Validation' 
                }
                
                if ($quickPurpose) {
                    $purposeResults += [PSCustomObject]@{
                        NodeId     = $node.Id
                        Name       = $node.Name
                        Purpose    = $quickPurpose
                        Confidence = [double]0.80
                        Evidence   = @("Fallback name match: $($node.Name)")
                        DetectedAt = Get-Date
                    }
                    continue
                }
                
                # Fallback to detailed classification
                $purpose = Classify-CallablePurpose -Node $node -Graph $Graph
                if ($purpose) {
                    $purposeResults += $purpose
                }
            }
            
            # Analyze classes
            $classes = Unity-Claude-CPG\Get-CPGNode -Graph $Graph -Type Class
            foreach ($class in $classes) {
                $purpose = Classify-ClassPurpose -Node $class -Graph $Graph
                if ($purpose) {
                    $purposeResults += $purpose
                }
            }
            
            # Normalize results
            $purposeResults = @($purposeResults | ForEach-Object { 
                Normalize-AnalysisRecord -Record $_ -Kind 'Purpose' 
            })
            
            # Cache results
            if ($UseCache) {
                $script:UC_SA_Cache[$cacheKey] = $purposeResults
            }
            
            Write-Verbose "Code purpose analysis complete. Found $($purposeResults.Count) purposes"
        }
        catch {
            Write-Verbose "Purpose classification error: $($_.Exception.Message)"
            return @()
        }
    }
    
    end {
        # Final normalization and array return
        $purposeResults = @($purposeResults | ForEach-Object { Normalize-AnalysisRecord -Record $_ -Kind 'Purpose' })
        if ($UseCache) { $script:UC_SA_Cache[$cacheKey] = $purposeResults }
        return ,$purposeResults
    }
}

function Classify-CallablePurpose {
    <#
    .SYNOPSIS
    Classifies the purpose of a function or method
    
    .PARAMETER Node
    The function/method node to classify
    
    .PARAMETER Graph
    The containing graph for context
    #>
    param(
        $Node,
        $Graph
    )
    
    $name = $Node.Name
    $confidence = 0.0
    $purpose = 'Unknown'
    $evidence = @()
    
    # CRUD detection patterns
    if ($name -match '^(Get|Read|Fetch|Find|Search|Query|Select|Load|Retrieve)') {
        $purpose = 'Read'
        $confidence = 0.9
        $evidence += "Read operation verb in name: $($Matches[1])"
    }
    elseif ($name -match '^(New|Create|Add|Insert|Post|Make|Build|Generate)') {
        $purpose = 'Create'
        $confidence = 0.9
        $evidence += "Create operation verb in name: $($Matches[1])"
    }
    elseif ($name -match '^(Update|Set|Modify|Change|Edit|Patch|Replace)') {
        $purpose = 'Update'
        $confidence = 0.9
        $evidence += "Update operation verb in name: $($Matches[1])"
    }
    elseif ($name -match '^(Remove|Delete|Destroy|Clear|Purge|Drop|Uninstall)') {
        $purpose = 'Delete'
        $confidence = 0.9
        $evidence += "Delete operation verb in name: $($Matches[1])"
    }
    # Validation patterns
    elseif ($name -match '^(Test|Validate|Check|Verify|Ensure|Assert|Is|Has|Can)') {
        $purpose = 'Validation'
        $confidence = 0.85
        $evidence += "Validation verb in name: $($Matches[1])"
    }
    # Transformation patterns
    elseif ($name -match '^(Convert|Transform|Map|Parse|Format|Serialize|Encode|Decode)') {
        $purpose = 'Transformation'
        $confidence = 0.85
        $evidence += "Transformation verb in name: $($Matches[1])"
    }
    # Calculation patterns
    elseif ($name -match '^(Calculate|Compute|Count|Sum|Average|Aggregate|Measure)') {
        $purpose = 'Calculation'
        $confidence = 0.85
        $evidence += "Calculation verb in name: $($Matches[1])"
    }
    # Helper/Utility patterns
    elseif ($name -match '^(Initialize|Setup|Configure|Register|Start|Stop|Enable|Disable)') {
        $purpose = 'Configuration'
        $confidence = 0.8
        $evidence += "Configuration verb in name: $($Matches[1])"
    }
    # Event handling
    elseif ($name -match '^(On|Handle|Process|Trigger)') {
        $purpose = 'EventHandling'
        $confidence = 0.8
        $evidence += "Event handling prefix in name: $($Matches[1])"
    }
    
    # Analyze body if available for additional evidence
    if ($Node.Properties -and $Node.Properties.Body) {
        $body = $Node.Properties.Body
        
        # Look for database operations
        if ($body -match 'SELECT|INSERT|UPDATE|DELETE|FROM|WHERE') {
            $evidence += "SQL operations detected"
            $confidence = [Math]::Min(1.0, $confidence + 0.1)
        }
        
        # Look for file operations
        if ($body -match 'Get-Content|Set-Content|Out-File|Export-|Import-') {
            $evidence += "File I/O operations detected"
            $confidence = [Math]::Min(1.0, $confidence + 0.05)
        }
        
        # Look for network operations
        if ($body -match 'Invoke-WebRequest|Invoke-RestMethod|HttpClient|WebClient') {
            $evidence += "Network operations detected"
            $confidence = [Math]::Min(1.0, $confidence + 0.05)
        }
    }
    
    if ($confidence -gt 0) {
        return [PSCustomObject]@{
            NodeId = $Node.Id
            NodeName = $Node.Name
            NodeType = $Node.Type
            Purpose = $purpose
            PrimaryPurpose = $purpose  # For compatibility
            Confidence = [Math]::Round($confidence, 2)
            Evidence = $evidence
            FilePath = $Node.FilePath
            StartLine = $Node.StartLine
        }
    }
    
    return @()
}

function Classify-ClassPurpose {
    <#
    .SYNOPSIS
    Classifies the purpose of a class
    
    .PARAMETER Node
    The class node to classify
    
    .PARAMETER Graph
    The containing graph for context
    #>
    param(
        $Node,
        $Graph
    )
    
    $name = $Node.Name
    $confidence = 0.0
    $purpose = 'Unknown'
    $evidence = @()
    
    # Entity/Model patterns
    if ($name -match '(Model|Entity|Record|Data|Info)$') {
        $purpose = 'DataModel'
        $confidence = 0.8
        $evidence += "Data model suffix in name: $($Matches[1])"
    }
    # Service patterns
    elseif ($name -match '(Service|Manager|Controller|Handler|Processor)$') {
        $purpose = 'Service'
        $confidence = 0.85
        $evidence += "Service suffix in name: $($Matches[1])"
    }
    # Repository/DAO patterns
    elseif ($name -match '(Repository|Repo|DAO|Store|Cache)$') {
        $purpose = 'DataAccess'
        $confidence = 0.85
        $evidence += "Data access suffix in name: $($Matches[1])"
    }
    # Factory patterns
    elseif ($name -match '(Factory|Builder|Creator|Provider)$') {
        $purpose = 'Factory'
        $confidence = 0.85
        $evidence += "Factory suffix in name: $($Matches[1])"
    }
    # Validator patterns
    elseif ($name -match '(Validator|Checker|Verifier|Rule)$') {
        $purpose = 'Validation'
        $confidence = 0.85
        $evidence += "Validation suffix in name: $($Matches[1])"
    }
    # Exception patterns
    elseif ($name -match '(Exception|Error|Fault)$') {
        $purpose = 'Exception'
        $confidence = 0.9
        $evidence += "Exception suffix in name: $($Matches[1])"
    }
    # Configuration patterns
    elseif ($name -match '(Config|Configuration|Settings|Options)$') {
        $purpose = 'Configuration'
        $confidence = 0.85
        $evidence += "Configuration suffix in name: $($Matches[1])"
    }
    
    # Analyze class members for additional evidence
    if ($Graph) {
        $members = $Graph.GetNeighbors($Node.Id, 'Out')
        $methodCount = ($members | Where-Object { $_.Type -eq 'Method' }).Count
        $propertyCount = ($members | Where-Object { $_.Type -eq 'Property' -or $_.Type -eq 'Field' }).Count
        
        # Data model typically has more properties than methods
        if ($propertyCount -gt $methodCount * 2) {
            if ($purpose -eq 'Unknown') {
                $purpose = 'DataModel'
                $confidence = 0.6
            }
            $evidence += "High property to method ratio ($propertyCount`:$methodCount)"
        }
        # Service typically has more methods
        elseif ($methodCount -gt $propertyCount * 2) {
            if ($purpose -eq 'Unknown') {
                $purpose = 'Service'
                $confidence = 0.6
            }
            $evidence += "High method to property ratio ($methodCount`:$propertyCount)"
        }
    }
    
    if ($confidence -gt 0) {
        return [PSCustomObject]@{
            NodeId = $Node.Id
            NodeName = $Node.Name
            NodeType = $Node.Type
            Purpose = $purpose
            PrimaryPurpose = $purpose
            Confidence = [Math]::Round($confidence, 2)
            Evidence = $evidence
            FilePath = $Node.FilePath
            StartLine = $Node.StartLine
        }
    }
    
    return @()
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Get-CodePurpose',
    'Classify-CallablePurpose',
    'Classify-ClassPurpose'
)

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDFq3EMLh12bPD7
# 15gPnvqy1zRo5CMyLFWir0IjXgUJfKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGnI0FVbJhqOnqDIodBzQBcU
# 80kQewdoCAC1I0LlQ+9LMA0GCSqGSIb3DQEBAQUABIIBAEqalViHSsLdiY8AfZH1
# B7P2QE859jsfxshC/jG1Uy82t1l0vSQCCIUaOXkH3pr8che+Eunn2Jn8r1WZtGu7
# ly2WozCY8YLpOumnFsCbgyBf0vErByCV3VBenQ1wvsQ5QJ/FRs3SpTA1MYJniNA0
# OjcmrD+wDBuxnnpTwq2mp55EQJZCKxoJ5DvfnyGDlapFM9mbiPxCF1VmXpXKT+kQ
# UDFa85ZfVspfhUX8WQpYrkjHqGmrgQzLo67u7l3BraqbSV6T2gSynVljLPhuX0p0
# cVxhizdV782j6ifSzvG9QIYfB9eB+VwWKijztklntxMrp/iE+gFb5LJyO8ynmtMd
# X/0=
# SIG # End signature block
