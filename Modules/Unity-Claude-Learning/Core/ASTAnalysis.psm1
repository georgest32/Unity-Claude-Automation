# Unity-Claude-Learning AST Analysis Component
# Abstract Syntax Tree parsing and analysis
# Part of refactored Learning module

$ErrorActionPreference = "Stop"

# Import core component
$CorePath = Join-Path $PSScriptRoot "LearningCore.psm1"
Import-Module $CorePath -Force

function Get-CodeAST {
    <#
    .SYNOPSIS
    Parses code file into Abstract Syntax Tree
    .DESCRIPTION
    Supports PowerShell and C# code parsing for pattern analysis
    .PARAMETER FilePath
    Path to the code file
    .PARAMETER Language
    Programming language (PowerShell or CSharp)
    .EXAMPLE
    Get-CodeAST -FilePath "script.ps1" -Language PowerShell
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [ValidateSet('PowerShell','CSharp')]
        [string]$Language = 'PowerShell'
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return $null
    }
    
    $content = Get-Content $FilePath -Raw
    
    switch ($Language) {
        'PowerShell' {
            try {
                $tokens = $null
                $errors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseInput(
                    $content, 
                    [ref]$tokens, 
                    [ref]$errors
                )
                
                return @{
                    AST = $ast
                    Tokens = $tokens
                    Errors = $errors
                    Language = 'PowerShell'
                }
            } catch {
                Write-Error "Failed to parse PowerShell AST: $_"
                return $null
            }
        }
        
        'CSharp' {
            # For C#, we'll use Roslyn if available, or regex patterns as fallback
            Write-Warning "C# AST parsing requires Roslyn - using pattern matching instead"
            
            # Extract basic structure using regex
            $patterns = @{
                Classes = [regex]::Matches($content, 'class\s+(\w+)')
                Methods = [regex]::Matches($content, '(public|private|protected|internal)\s+\w+\s+(\w+)\s*\(')
                Properties = [regex]::Matches($content, '(public|private|protected|internal)\s+\w+\s+(\w+)\s*{')
                Usings = [regex]::Matches($content, 'using\s+([\w.]+);')
            }
            
            return @{
                AST = $null  # Placeholder for Roslyn AST
                Patterns = $patterns
                Language = 'CSharp'
                Content = $content
            }
        }
    }
}

function Find-CodePattern {
    <#
    .SYNOPSIS
    Finds patterns in code AST that match error signatures
    .DESCRIPTION
    Analyzes AST to find patterns matching error conditions
    .PARAMETER AST
    Abstract Syntax Tree to analyze
    .PARAMETER ErrorMessage
    Error message to match against
    .EXAMPLE
    Find-CodePattern -AST $ast -ErrorMessage "Variable 'x' is not defined"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$AST,
        
        [Parameter(Mandatory)]
        [string]$ErrorMessage
    )
    
    $patterns = @()
    
    # Extract error type from message
    $errorType = switch -Regex ($ErrorMessage) {
        'CS0246' { 'MissingUsing' }
        'CS0103' { 'UndefinedVariable' }
        'CS1061' { 'MissingMethod' }
        'CS0029' { 'TypeMismatch' }
        'null reference' { 'NullReference' }
        default { 'Unknown' }
    }
    
    # Build pattern signature
    $signature = @{
        ErrorType = $errorType
        ErrorMessage = $ErrorMessage
        Timestamp = Get-Date
    }
    
    # PowerShell AST analysis
    if ($AST.Language -eq 'PowerShell' -and $AST.AST) {
        # Find all variable assignments
        $variables = $AST.AST.FindAll({$args[0] -is [System.Management.Automation.Language.VariableExpressionAst]}, $true)
        
        # Find all function calls
        $functions = $AST.AST.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true)
        
        # Find all pipeline operations
        $pipelines = $AST.AST.FindAll({$args[0] -is [System.Management.Automation.Language.PipelineAst]}, $true)
        
        $signature.Variables = $variables.Count
        $signature.Functions = $functions.Count
        $signature.Pipelines = $pipelines.Count
    }
    
    # Generate pattern hash for matching
    $patternHash = [System.BitConverter]::ToString(
        [System.Security.Cryptography.SHA256]::Create().ComputeHash(
            [System.Text.Encoding]::UTF8.GetBytes($ErrorMessage)
        )
    ).Replace("-","").Substring(0,16)
    
    $signature.PatternHash = $patternHash
    
    return $signature
}

function Get-ASTStatistics {
    <#
    .SYNOPSIS
    Generates statistics from AST analysis
    .DESCRIPTION
    Provides detailed metrics about code structure
    .PARAMETER AST
    AST object to analyze
    .EXAMPLE
    Get-ASTStatistics -AST $ast
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$AST
    )
    
    $stats = @{
        Language = $AST.Language
        TotalLines = 0
        Functions = 0
        Variables = 0
        Commands = 0
        Comments = 0
        Errors = 0
    }
    
    if ($AST.Language -eq 'PowerShell' -and $AST.AST) {
        # Count various AST elements
        $stats.Functions = $AST.AST.FindAll({$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]}, $true).Count
        $stats.Variables = $AST.AST.FindAll({$args[0] -is [System.Management.Automation.Language.VariableExpressionAst]}, $true).Count
        $stats.Commands = $AST.AST.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true).Count
        
        # Count errors
        if ($AST.Errors) {
            $stats.Errors = $AST.Errors.Count
        }
        
        # Count lines
        $stats.TotalLines = $AST.AST.Extent.EndLineNumber - $AST.AST.Extent.StartLineNumber + 1
    }
    
    return $stats
}

function Compare-ASTStructures {
    <#
    .SYNOPSIS
    Compares two AST structures for similarities
    .DESCRIPTION
    Identifies structural similarities between code patterns
    .PARAMETER AST1
    First AST to compare
    .PARAMETER AST2
    Second AST to compare
    .EXAMPLE
    Compare-ASTStructures -AST1 $ast1 -AST2 $ast2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$AST1,
        
        [Parameter(Mandatory)]
        [object]$AST2
    )
    
    if ($AST1.Language -ne $AST2.Language) {
        Write-Warning "ASTs are from different languages"
        return @{
            Similarity = 0.0
            LanguageMatch = $false
        }
    }
    
    $stats1 = Get-ASTStatistics -AST $AST1
    $stats2 = Get-ASTStatistics -AST $AST2
    
    # Calculate structural similarity
    $similarities = @()
    
    foreach ($key in $stats1.Keys) {
        if ($key -eq 'Language' -or $key -eq 'Errors') { continue }
        
        $val1 = $stats1[$key]
        $val2 = $stats2[$key]
        
        if ($val1 -eq 0 -and $val2 -eq 0) {
            $similarity = 1.0
        } elseif ($val1 -eq 0 -or $val2 -eq 0) {
            $similarity = 0.0
        } else {
            $similarity = 1.0 - ([Math]::Abs($val1 - $val2) / [Math]::Max($val1, $val2))
        }
        
        $similarities += $similarity
    }
    
    $overallSimilarity = if ($similarities.Count -gt 0) {
        ($similarities | Measure-Object -Average).Average
    } else {
        0.0
    }
    
    return @{
        Similarity = [Math]::Round($overallSimilarity, 3)
        LanguageMatch = $true
        Stats1 = $stats1
        Stats2 = $stats2
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-CodeAST',
    'Find-CodePattern',
    'Get-ASTStatistics',
    'Compare-ASTStructures'
)

if (Get-Command Write-ModuleLog -ErrorAction SilentlyContinue) {
    Write-ModuleLog -Message "ASTAnalysis component loaded successfully" -Level "DEBUG"
} else {
    Write-Verbose "[ASTAnalysis] Component loaded successfully"
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAYY7oOFvwQQopq
# 7MWwZEQHmwjIFIfReh0r+tYpFY5uDKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOFE94XDN7NXMVDz7KUHH+Mx
# MXzkEgjkmXeK6W7Kv0dTMA0GCSqGSIb3DQEBAQUABIIBAD+zCbtQ8aDzwORmjbSM
# v4MUloUymMpzSZwteE1xg5BjhUOW0iOBORoJYYJ0th0DClCLsuoOBQsbg0kYE44S
# Am+hFcplH1vdPU8tb6o9B/p2tfEyNNFcvktdSyI63NSeQ+w1QEECzovyHQErad+D
# oaOqD+BShKLM+Y/IDIeV8+6zepSvNJQV84fkBEx6udyXhLTEF9l+IaVbATPpUELE
# yKtOAHsMHytB2yBxa1KKcYAUG5weRd2OuvIlpYrin6eo0JavAaElDO+4NY44Yzdb
# ZZvXfX2sJcuH8sOnLU39/nCtCU4kcyIyYEyM4Vc8wY1gHNgqI80D0SNvPKueOkSy
# 374=
# SIG # End signature block
