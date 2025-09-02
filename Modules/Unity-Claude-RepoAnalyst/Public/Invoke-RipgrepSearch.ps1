function Invoke-RipgrepSearch {
    <#
    .SYNOPSIS
    Advanced ripgrep wrapper for code analysis
    
    .DESCRIPTION
    Provides comprehensive search capabilities using ripgrep with support for
    pattern matching, file filtering, context extraction, and change detection
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Pattern,
        
        [Parameter(Position = 1)]
        [string]$Path = ".",
        
        [Parameter()]
        [string[]]$Include,
        
        [Parameter()]
        [string[]]$Exclude,
        
        [Parameter()]
        [ValidateSet('literal', 'regex', 'word', 'line')]
        [string]$SearchType = 'regex',
        
        [Parameter()]
        [string]$FileType,
        
        [Parameter()]
        [int]$ContextBefore = 0,
        
        [Parameter()]
        [int]$ContextAfter = 0,
        
        [Parameter()]
        [int]$MaxCount,
        
        [Parameter()]
        [switch]$CaseSensitive,
        
        [Parameter()]
        [switch]$FilesWithMatches,
        
        [Parameter()]
        [switch]$FilesWithoutMatch,
        
        [Parameter()]
        [switch]$Count,
        
        [Parameter()]
        [switch]$ShowLineNumbers,
        
        [Parameter()]
        [switch]$FollowSymlinks,
        
        [Parameter()]
        [switch]$IncludeHidden,
        
        [Parameter()]
        [switch]$NoIgnore,
        
        [Parameter()]
        [switch]$ReturnObjects
    )
    
    begin {
        Write-Verbose "Starting ripgrep search for pattern: $Pattern"
        $rgPath = Get-Command rg -ErrorAction SilentlyContinue
        
        if (-not $rgPath) {
            throw "ripgrep (rg) is not installed or not in PATH"
        }
        
        # Map file types to ripgrep-compatible types
        $fileTypeMap = @{
            'ps1' = 'powershell'
            'powershell' = 'powershell'
            'cs' = 'csharp'
            'csharp' = 'csharp'
            'js' = 'js'
            'javascript' = 'js'
            'ts' = 'ts'
            'typescript' = 'ts'
            'py' = 'py'
            'python' = 'py'
        }
        
        # Convert file type if needed
        if ($FileType -and $fileTypeMap.ContainsKey($FileType.ToLower())) {
            $FileType = $fileTypeMap[$FileType.ToLower()]
        }
        
        # Build ripgrep arguments
        $rgArgs = [System.Collections.ArrayList]::new()
        
        # Search type
        switch ($SearchType) {
            'literal' { [void]$rgArgs.Add('-F') }
            'word'    { [void]$rgArgs.Add('-w') }
            'line'    { [void]$rgArgs.Add('-x') }
            # 'regex' is default
        }
        
        # Case sensitivity
        if ($CaseSensitive) {
            [void]$rgArgs.Add('-s')
        } else {
            [void]$rgArgs.Add('-i')
        }
        
        # Output format
        if ($FilesWithMatches) {
            [void]$rgArgs.Add('-l')
        } elseif ($FilesWithoutMatch) {
            [void]$rgArgs.Add('--files-without-match')
        } elseif ($Count) {
            [void]$rgArgs.Add('-c')
        }
        
        # Context lines
        if ($ContextBefore -gt 0) {
            [void]$rgArgs.Add("-B")
            [void]$rgArgs.Add($ContextBefore.ToString())
        }
        if ($ContextAfter -gt 0) {
            [void]$rgArgs.Add("-A")
            [void]$rgArgs.Add($ContextAfter.ToString())
        }
        
        # Line numbers
        if ($ShowLineNumbers -or $ReturnObjects) {
            [void]$rgArgs.Add('-n')
        }
        
        # File type filter
        if ($FileType) {
            # Add PowerShell type definition if not already present
            if ($FileType -eq 'powershell') {
                [void]$rgArgs.Add('--type-add')
                [void]$rgArgs.Add('powershell:*.ps1,*.psm1,*.psd1')
            }
            [void]$rgArgs.Add('-t')
            [void]$rgArgs.Add($FileType)
        }
        
        # Include patterns
        foreach ($inc in $Include) {
            [void]$rgArgs.Add('-g')
            [void]$rgArgs.Add($inc)
        }
        
        # Exclude patterns
        foreach ($exc in $Exclude) {
            [void]$rgArgs.Add('-g')
            [void]$rgArgs.Add("!$exc")
        }
        
        # Max matches per file
        if ($MaxCount) {
            [void]$rgArgs.Add('-m')
            [void]$rgArgs.Add($MaxCount.ToString())
        }
        
        # Symlinks and hidden files
        if ($FollowSymlinks) {
            [void]$rgArgs.Add('-L')
        }
        if ($IncludeHidden) {
            [void]$rgArgs.Add('--hidden')
        }
        if ($NoIgnore) {
            [void]$rgArgs.Add('--no-ignore')
        }
        
        # Add pattern and path
        [void]$rgArgs.Add($Pattern)
        [void]$rgArgs.Add($Path)
        
        Write-Verbose "ripgrep arguments: $($rgArgs -join ' ')"
    }
    
    process {
        try {
            # Execute ripgrep
            $output = & rg $rgArgs 2>&1
            $exitCode = $LASTEXITCODE
            
            # Check for errors
            if ($exitCode -eq 2) {
                # Error in ripgrep execution
                throw "ripgrep error: $output"
            } elseif ($exitCode -eq 1) {
                # No matches found (not an error)
                Write-Verbose "No matches found for pattern: $Pattern"
                if ($ReturnObjects) {
                    return @()
                } else {
                    return $null
                }
            }
            
            # Process output
            if ($ReturnObjects -and -not $FilesWithMatches -and -not $Count) {
                # Parse output into objects
                $results = @()
                
                foreach ($line in $output) {
                    if ($line -match '^(.+?):(\d+):(.*)$') {
                        $results += [PSCustomObject]@{
                            File = $Matches[1]
                            Line = [int]$Matches[2]
                            Content = $Matches[3]
                            Pattern = $Pattern
                        }
                    } elseif ($line -match '^(.+?)-(\d+)-(.*)$') {
                        # Context line
                        $results += [PSCustomObject]@{
                            File = $Matches[1]
                            Line = [int]$Matches[2]
                            Content = $Matches[3]
                            Pattern = $Pattern
                            IsContext = $true
                        }
                    }
                }
                
                return $results
            } else {
                return $output
            }
            
        }
        catch {
            Write-Error "Failed to execute ripgrep search: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "Ripgrep search completed"
    }
}

function Get-CodeChanges {
    <#
    .SYNOPSIS
    Detects code changes using git diff and ripgrep
    
    .DESCRIPTION
    Identifies modified files and specific changes for targeted analysis
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Since = "HEAD~1",
        
        [Parameter()]
        [string]$Path = ".",
        
        [Parameter()]
        [switch]$IncludeUntracked
    )
    
    try {
        # Get changed files from git with timeout and error handling
        $changedFiles = @()
        
        # Use shorter timeout and ignore problematic directories
        $gitDiffJob = Start-Job -ScriptBlock {
            param($Since)
            git diff --name-only $Since 2>&1 | Where-Object { $_ -notmatch 'warning:.*could not open directory' }
        } -ArgumentList $Since
        
        if (Wait-Job $gitDiffJob -Timeout 10) {
            $changedFiles = Receive-Job $gitDiffJob
            Remove-Job $gitDiffJob
        } else {
            Remove-Job $gitDiffJob -Force
            Write-Warning "Git diff timed out, using alternative method"
            # Fallback to git status for quick results
            $changedFiles = git status --porcelain | ForEach-Object { $_.Substring(3) } | Where-Object { Test-Path $_ }
        }
        
        if ($IncludeUntracked) {
            $untrackedJob = Start-Job -ScriptBlock {
                git ls-files --others --exclude-standard 2>&1 | Where-Object { $_ -notmatch 'warning:.*could not open directory' }
            }
            
            if (Wait-Job $untrackedJob -Timeout 5) {
                $untrackedFiles = Receive-Job $untrackedJob
                $changedFiles = @($changedFiles) + @($untrackedFiles)
                Remove-Job $untrackedJob
            } else {
                Remove-Job $untrackedJob -Force
                Write-Warning "Git ls-files timed out, skipping untracked files"
            }
        }
        
        $results = @()
        
        foreach ($file in $changedFiles) {
            if (Test-Path $file) {
                # Get file info
                $fileInfo = Get-Item $file
                
                # Get diff for tracked files
                $diff = $null
                if (git ls-files --error-unmatch $file 2>$null) {
                    $diff = git diff $Since -- $file
                }
                
                $results += [PSCustomObject]@{
                    Path = $file
                    ChangeType = if ($diff) { "Modified" } else { "Untracked" }
                    Size = $fileInfo.Length
                    LastModified = $fileInfo.LastWriteTime
                    Diff = $diff
                }
            }
        }
        
        return $results
    }
    catch {
        Write-Error "Failed to get code changes: $_"
        throw
    }
}

function Search-CodePattern {
    <#
    .SYNOPSIS
    High-level code pattern search with multiple strategies
    
    .DESCRIPTION
    Combines ripgrep with pattern analysis for intelligent code search
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        
        [Parameter()]
        [string]$Path = ".",
        
        [Parameter()]
        [ValidateSet('Function', 'Class', 'Variable', 'Import', 'Comment', 'String', 'Any')]
        [string]$PatternType = 'Any',
        
        [Parameter()]
        [string]$Language,
        
        [Parameter()]
        [switch]$IncludeTests
    )
    
    # Build search pattern based on type
    $searchPattern = $Pattern
    $includePatterns = @()
    $excludePatterns = @()
    
    # Language-specific file types
    $fileType = switch ($Language) {
        'PowerShell' { 'ps1' }
        'CSharp'     { 'cs' }
        'JavaScript' { 'js' }
        'TypeScript' { 'ts' }
        'Python'     { 'py' }
        default      { $null }
    }
    
    # Pattern type specific searches
    switch ($PatternType) {
        'Function' {
            switch ($Language) {
                'PowerShell' { $searchPattern = "function\s+$Pattern" }
                'CSharp'     { $searchPattern = "(public|private|protected|internal).*\s+$Pattern\s*\(" }
                'JavaScript' { $searchPattern = "(function\s+$Pattern|const\s+$Pattern\s*=.*=>)" }
                'Python'     { $searchPattern = "def\s+$Pattern" }
                default      { $searchPattern = "(function|def|func)\s+$Pattern" }
            }
        }
        'Class' {
            switch ($Language) {
                'PowerShell' { $searchPattern = "class\s+$Pattern" }
                'CSharp'     { $searchPattern = "(class|interface|struct)\s+$Pattern" }
                'JavaScript' { $searchPattern = "class\s+$Pattern" }
                'Python'     { $searchPattern = "class\s+$Pattern" }
                default      { $searchPattern = "class\s+$Pattern" }
            }
        }
        'Variable' {
            switch ($Language) {
                'PowerShell' { $searchPattern = "`$script:$Pattern|`$global:$Pattern|`$$Pattern" }
                'CSharp'     { $searchPattern = "(var|int|string|bool|float|double)\s+$Pattern" }
                'JavaScript' { $searchPattern = "(let|const|var)\s+$Pattern" }
                'Python'     { $searchPattern = "$Pattern\s*=" }
            }
        }
        'Import' {
            switch ($Language) {
                'PowerShell' { $searchPattern = "Import-Module.*$Pattern|using module" }
                'CSharp'     { $searchPattern = "using\s+.*$Pattern" }
                'JavaScript' { $searchPattern = "import.*$Pattern|require.*$Pattern" }
                'Python'     { $searchPattern = "import.*$Pattern|from.*import" }
            }
        }
    }
    
    # Exclude test files unless requested
    if (-not $IncludeTests) {
        $excludePatterns += @("*test*", "*Test*", "*spec*", "*Spec*")
    }
    
    # Execute search
    $searchParams = @{
        Pattern = $searchPattern
        Path = $Path
        ReturnObjects = $true
        ShowLineNumbers = $true
    }
    
    if ($fileType) {
        # Map to ripgrep-compatible file type
        $mappedFileType = switch ($fileType) {
            'ps1' { 'powershell' }
            default { $fileType }
        }
        $searchParams.FileType = $mappedFileType
    }
    
    if ($excludePatterns) {
        $searchParams.Exclude = $excludePatterns
    }
    
    $results = Invoke-RipgrepSearch @searchParams
    
    # Enhance results with pattern type info
    foreach ($result in $results) {
        $result | Add-Member -NotePropertyName 'PatternType' -NotePropertyValue $PatternType
        $result | Add-Member -NotePropertyName 'Language' -NotePropertyValue $Language
    }
    
    return $results
}

# Export functions
Export-ModuleMember -Function Invoke-RipgrepSearch, Get-CodeChanges, Search-CodePattern
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCuW4ptgczDqfLU
# gvgZllmh4ENG+iVbcqisS9DAkqZQyKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGCf1BEiNGcPKx6ZU0rumY9d
# IP5Ije66RuvuvtYhb1qSMA0GCSqGSIb3DQEBAQUABIIBAGYa/dWCrP0TFWDkVAya
# eJ+SpfWbizWmYfM97PM0h3K8bBxu1KkaKgNHiNPDGmn+HN6wRx+fS6bsCZ+PQLOE
# 9bSp4dEa3T8Zmg+PDi/iDdVKVwqpgWTrK/vYljdrHXnDDM1zJes/8CB2akJnzTs2
# jsUkO9j+73DO7SmoFZ2WspCmPlI3QcvTV0WZZBln2R4G7M1yE+mH83EaVRm7GiBn
# NFhu0fswp+dfBCXHhQKp25F3jt8niFUWeDJYBwSVO7el1K7WTYskFHXFGobFelqn
# RXdgcuUhsA4Gj5Dyf3oJmg6fkUi/11YHVf5HBy8oythJ/hkIQF7MSoUoSx/99tlm
# W58=
# SIG # End signature block
