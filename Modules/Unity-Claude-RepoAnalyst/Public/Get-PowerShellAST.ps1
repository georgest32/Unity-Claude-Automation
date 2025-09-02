function Get-PowerShellAST {
    <#
    .SYNOPSIS
    Parses PowerShell scripts using the Abstract Syntax Tree
    
    .DESCRIPTION
    Provides comprehensive AST analysis for PowerShell scripts including
    function extraction, variable analysis, and dependency mapping
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Path')]
        [string]$Path,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'ScriptBlock')]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'Content')]
        [string]$Content,
        
        [Parameter()]
        [switch]$IncludeNestedFunctions,
        
        [Parameter()]
        [switch]$ResolveAliases
    )
    
    begin {
        Write-Verbose "Starting PowerShell AST parsing"
    }
    
    process {
        try {
            # Get AST based on input type
            $ast = $null
            $tokens = $null
            $errors = $null
            
            switch ($PSCmdlet.ParameterSetName) {
                'Path' {
                    if (-not (Test-Path $Path)) {
                        throw "File not found: $Path"
                    }
                    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                        $Path,
                        [ref]$tokens,
                        [ref]$errors
                    )
                }
                
                'ScriptBlock' {
                    $ast = $ScriptBlock.Ast
                }
                
                'Content' {
                    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
                        $Content,
                        [ref]$tokens,
                        [ref]$errors
                    )
                }
            }
            
            # Check for parse errors
            if ($errors) {
                Write-Warning "Parse errors found: $($errors -join '; ')"
            }
            
            # Create result object
            $result = [PSCustomObject]@{
                AST = $ast
                Functions = @()
                Variables = @()
                Commands = @()
                Parameters = @()
                Classes = @()
                Imports = @()
                Comments = @()
                Errors = $errors
                Statistics = @{}
            }
            
            # Extract functions
            $functionPredicate = { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }
            $functions = $ast.FindAll($functionPredicate, $IncludeNestedFunctions)
            
            foreach ($func in $functions) {
                $result.Functions += [PSCustomObject]@{
                    Name = $func.Name
                    Parameters = $func.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath }
                    Body = $func.Body.ToString()
                    StartLine = $func.Extent.StartLineNumber
                    EndLine = $func.Extent.EndLineNumber
                    IsWorkflow = $func.IsWorkflow
                    IsFilter = $func.IsFilter
                }
            }
            
            # Extract variables
            $variablePredicate = { $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }
            $variables = $ast.FindAll($variablePredicate, $true)
            
            $uniqueVars = @{}
            foreach ($var in $variables) {
                $varName = $var.VariablePath.UserPath
                if (-not $uniqueVars.ContainsKey($varName)) {
                    $scope = if ($var.VariablePath.IsGlobal) { 'Global' } 
                             elseif ($var.VariablePath.IsScript) { 'Script' } 
                             elseif ($var.VariablePath.IsPrivate) { 'Private' } 
                             else { 'Local' }
                    
                    $uniqueVars[$varName] = [PSCustomObject]@{
                        Name = $varName
                        Scope = $scope
                        FirstUseLine = $var.Extent.StartLineNumber
                        UsageCount = 1
                    }
                } else {
                    $uniqueVars[$varName].UsageCount++
                }
            }
            $result.Variables = $uniqueVars.Values
            
            # Extract commands
            $commandPredicate = { $args[0] -is [System.Management.Automation.Language.CommandAst] }
            $commands = $ast.FindAll($commandPredicate, $true)
            
            $commandStats = @{}
            foreach ($cmd in $commands) {
                $cmdName = $cmd.GetCommandName()
                if ($cmdName) {
                    if (-not $commandStats.ContainsKey($cmdName)) {
                        $commandStats[$cmdName] = 0
                    }
                    $commandStats[$cmdName]++
                }
            }
            
            foreach ($cmdName in $commandStats.Keys) {
                $result.Commands += [PSCustomObject]@{
                    Name = $cmdName
                    Count = $commandStats[$cmdName]
                }
            }
            
            # Extract classes (PowerShell 5+)
            $classPredicate = { $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] }
            $classes = $ast.FindAll($classPredicate, $true)
            
            foreach ($class in $classes) {
                $result.Classes += [PSCustomObject]@{
                    Name = $class.Name
                    Members = $class.Members | ForEach-Object { $_.Name }
                    StartLine = $class.Extent.StartLineNumber
                    EndLine = $class.Extent.EndLineNumber
                    IsClass = $class.IsClass
                    IsInterface = $class.IsInterface
                    IsEnum = $class.IsEnum
                }
            }
            
            # Extract imports (using statements and module imports)
            $usingPredicate = { $args[0] -is [System.Management.Automation.Language.UsingStatementAst] }
            $usingStatements = $ast.FindAll($usingPredicate, $true)
            
            foreach ($using in $usingStatements) {
                $result.Imports += [PSCustomObject]@{
                    Type = 'Using'
                    Name = $using.Name
                    Line = $using.Extent.StartLineNumber
                }
            }
            
            # Find Import-Module and using module statements
            foreach ($cmd in $commands) {
                $cmdName = $cmd.GetCommandName()
                if ($cmdName -eq 'Import-Module') {
                    $moduleArg = $cmd.CommandElements | Select-Object -Skip 1 -First 1
                    if ($moduleArg) {
                        $result.Imports += [PSCustomObject]@{
                            Type = 'Import-Module'
                            Name = $moduleArg.ToString().Trim('"', "'")
                            Line = $cmd.Extent.StartLineNumber
                        }
                    }
                }
            }
            
            # Extract comments
            if ($tokens) {
                $commentTokens = $tokens | Where-Object { $_.Kind -eq 'Comment' }
                foreach ($comment in $commentTokens) {
                    $result.Comments += [PSCustomObject]@{
                        Text = $comment.Text
                        Line = $comment.Extent.StartLineNumber
                        Type = if ($comment.Text -match '^<#') { 'Block' } else { 'Line' }
                    }
                }
            }
            
            # Calculate statistics
            $result.Statistics = [PSCustomObject]@{
                TotalLines = $ast.Extent.EndLineNumber
                FunctionCount = $result.Functions.Count
                VariableCount = $result.Variables.Count
                UniqueCommandCount = $result.Commands.Count
                ClassCount = $result.Classes.Count
                CommentCount = $result.Comments.Count
                ImportCount = $result.Imports.Count
                ErrorCount = if ($errors) { $errors.Count } else { 0 }
            }
            
            return $result
        }
        catch {
            Write-Error "Failed to parse PowerShell AST: $_"
            throw
        }
    }
}

function Get-FunctionDependencies {
    <#
    .SYNOPSIS
    Analyzes function dependencies in PowerShell scripts
    
    .DESCRIPTION
    Maps out which functions call which other functions to understand dependencies
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter()]
        [switch]$IncludeExternal,
        
        [Parameter()]
        [switch]$ReturnGraph
    )
    
    try {
        # Parse the script
        $astResult = Get-PowerShellAST -Path $Path -IncludeNestedFunctions
        
        $dependencies = @{}
        
        # Get all function names in this script
        $localFunctions = $astResult.Functions | ForEach-Object { $_.Name }
        
        # Analyze each function
        foreach ($func in $astResult.Functions) {
            $funcDeps = @()
            
            # Parse function body as AST
            $funcAst = [System.Management.Automation.Language.Parser]::ParseInput(
                $func.Body,
                [ref]$null,
                [ref]$null
            )
            
            # Find all command calls
            $commandPredicate = { $args[0] -is [System.Management.Automation.Language.CommandAst] }
            $commands = $funcAst.FindAll($commandPredicate, $true)
            
            foreach ($cmd in $commands) {
                $cmdName = $cmd.GetCommandName()
                
                if ($cmdName) {
                    # Check if it's a local function
                    if ($cmdName -in $localFunctions) {
                        if ($cmdName -notin $funcDeps) {
                            $funcDeps += $cmdName
                        }
                    } elseif ($IncludeExternal) {
                        # Include external commands
                        if ($cmdName -notin $funcDeps) {
                            $funcDeps += $cmdName
                        }
                    }
                }
            }
            
            $dependencies[$func.Name] = $funcDeps
        }
        
        # Return as graph if requested
        if ($ReturnGraph) {
            $graph = @{
                nodes = @()
                edges = @()
            }
            
            # Add nodes
            foreach ($funcName in $localFunctions) {
                $graph.nodes += @{
                    id = $funcName
                    label = $funcName
                    type = 'function'
                }
            }
            
            # Add edges
            foreach ($func in $dependencies.Keys) {
                foreach ($dep in $dependencies[$func]) {
                    $graph.edges += @{
                        source = $func
                        target = $dep
                        type = 'calls'
                    }
                }
            }
            
            return $graph
        } else {
            return $dependencies
        }
    }
    catch {
        Write-Error "Failed to analyze function dependencies: $_"
        throw
    }
}

function Find-ASTPattern {
    <#
    .SYNOPSIS
    Searches for specific patterns in PowerShell AST
    
    .DESCRIPTION
    Advanced pattern matching using AST predicates
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$Predicate,
        
        [Parameter()]
        [switch]$Recurse,
        
        [Parameter()]
        [switch]$ShowContext
    )
    
    try {
        # Get files to search
        $files = if ($Recurse) {
            Get-ChildItem -Path $Path -Filter "*.ps1" -Recurse
        } else {
            if (Test-Path $Path -PathType Container) {
                Get-ChildItem -Path $Path -Filter "*.ps1"
            } else {
                Get-Item $Path
            }
        }
        
        $results = @()
        
        foreach ($file in $files) {
            Write-Verbose "Searching in: $($file.FullName)"
            
            # Parse file
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $file.FullName,
                [ref]$tokens,
                [ref]$errors
            )
            
            # Find matches
            $matches = $ast.FindAll($Predicate, $true)
            
            foreach ($match in $matches) {
                $result = [PSCustomObject]@{
                    File = $file.FullName
                    Match = $match
                    Type = $match.GetType().Name
                    StartLine = $match.Extent.StartLineNumber
                    EndLine = $match.Extent.EndLineNumber
                    Text = $match.Extent.Text
                }
                
                # Add context if requested
                if ($ShowContext) {
                    $content = Get-Content $file.FullName
                    $startLine = [Math]::Max(0, $match.Extent.StartLineNumber - 3)
                    $endLine = [Math]::Min($content.Count - 1, $match.Extent.EndLineNumber + 2)
                    
                    $result | Add-Member -NotePropertyName 'Context' -NotePropertyValue ($content[$startLine..$endLine] -join "`n")
                }
                
                $results += $result
            }
        }
        
        return $results
    }
    catch {
        Write-Error "Failed to find AST pattern: $_"
        throw
    }
}

# Common AST pattern predicates
$Script:ASTPatterns = @{
    HardcodedPaths = { $args[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and 
                      $args[0].Value -match '^[A-Z]:\\|^\\\\' }
    
    EmptyCatch = { $args[0] -is [System.Management.Automation.Language.CatchClauseAst] -and 
                  $args[0].Body.Statements.Count -eq 0 }
    
    GlobalVariables = { $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] -and 
                       $args[0].VariablePath.IsGlobal }
    
    WriteHost = { $args[0] -is [System.Management.Automation.Language.CommandAst] -and 
                 $args[0].GetCommandName() -eq 'Write-Host' }
    
    LargeFunction = { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and 
                     ($args[0].Extent.EndLineNumber - $args[0].Extent.StartLineNumber) -gt 100 }
}

# Export functions and patterns
Export-ModuleMember -Function Get-PowerShellAST, Get-FunctionDependencies, Find-ASTPattern -Variable ASTPatterns
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBnobApa4JoyiXX
# Uwll12/+zoV3JOSAvx0tYqlfj6ZTY6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIH19E/25lp6Qo7unFtHBA/wj
# MR0OOfZg++OfZnsXjQt9MA0GCSqGSIb3DQEBAQUABIIBAF1DCDZ34XI0uLaizMKj
# z77lXv/UFTRHtX9pfCXMybcdbrPYE4VzlHrTWvdY5Ci+wnvnZaTt5ij4FbIE1Ivo
# XwVg1XPNjKqZLgK8qfeW9l400xnFP0hDmgWdIoCIoFrCFBsB7Vy+lR0OyUdjxg1p
# bZgeTwc+aB6ImFpQhLF74kQZZU1oGyzb6g/Dh/AJXAIQiRKIvvYSPdVxtndxTdC0
# 1dgau5srLp67ayCO/OGE0vYVb/zrqCgweGbfl1b6aqSCFNnJYi+54n3vRaQQ2owh
# 3qdK+3v36/I2fffpgxRDm6m3TjomS9gwwT5fwKWTFyKW/cBB/V00d+C9gzkE6u6Q
# CkU=
# SIG # End signature block
