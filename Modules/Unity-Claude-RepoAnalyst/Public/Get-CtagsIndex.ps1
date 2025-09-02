function Get-CtagsIndex {
    <#
    .SYNOPSIS
    Generates and manages ctags indexes for code navigation
    
    .DESCRIPTION
    Creates symbol indexes using universal-ctags for fast code navigation
    and cross-reference analysis
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter()]
        [string]$OutputPath,
        
        [Parameter()]
        [string[]]$Languages,
        
        [Parameter()]
        [string[]]$Exclude = @('*.min.js', '*.min.css', 'node_modules', '.git', 'bin', 'obj'),
        
        [Parameter()]
        [switch]$Recurse,
        
        [Parameter()]
        [switch]$UpdateIndex,
        
        [Parameter()]
        [switch]$ReturnSymbols,
        
        [Parameter()]
        [ValidateSet('json', 'tags', 'xml')]
        [string]$OutputFormat = 'json'
    )
    
    begin {
        Write-Verbose "Starting ctags index generation for: $Path"
        
        $ctagsPath = Get-Command ctags -ErrorAction SilentlyContinue
        if (-not $ctagsPath) {
            throw "universal-ctags is not installed or not in PATH"
        }
        
        # Set default output path
        if (-not $OutputPath) {
            $cacheDir = Join-Path (Split-Path $PSScriptRoot -Parent -Parent) ".ai\cache"
            if (-not (Test-Path $cacheDir)) {
                New-Item -Path $cacheDir -ItemType Directory -Force | Out-Null
            }
            $OutputPath = Join-Path $cacheDir "tags.$OutputFormat"
        }
        
        Write-Verbose "Output path: $OutputPath"
    }
    
    process {
        try {
            # Build ctags arguments
            $ctagsArgs = [System.Collections.ArrayList]::new()
            
            # Output format
            switch ($OutputFormat) {
                'json' {
                    [void]$ctagsArgs.Add('--output-format=json')
                    [void]$ctagsArgs.Add('--extras=+fq')
                    [void]$ctagsArgs.Add('--fields=+KSn')
                }
                'xml' {
                    [void]$ctagsArgs.Add('--output-format=e-ctags')
                    [void]$ctagsArgs.Add('--extras=+fq')
                }
                'tags' {
                    # Default tags format
                    [void]$ctagsArgs.Add('--extras=+fq')
                    [void]$ctagsArgs.Add('--fields=+KSn')
                }
            }
            
            # Output file
            [void]$ctagsArgs.Add("-f")
            [void]$ctagsArgs.Add($OutputPath)
            
            # Recursion
            if ($Recurse) {
                [void]$ctagsArgs.Add('-R')
            }
            
            # Language filters
            if ($Languages) {
                foreach ($lang in $Languages) {
                    [void]$ctagsArgs.Add("--languages=$lang")
                }
            }
            
            # Exclusions
            foreach ($exc in $Exclude) {
                [void]$ctagsArgs.Add("--exclude=$exc")
            }
            
            # Update existing index
            if ($UpdateIndex -and (Test-Path $OutputPath)) {
                [void]$ctagsArgs.Add('-a')  # Append to existing
            }
            
            # Add path
            [void]$ctagsArgs.Add($Path)
            
            Write-Verbose "ctags arguments: $($ctagsArgs -join ' ')"
            
            # Execute ctags
            $output = & ctags $ctagsArgs 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -ne 0) {
                throw "ctags failed with exit code $exitCode : $output"
            }
            
            Write-Verbose "Tags file created successfully"
            
            # Return symbols if requested
            if ($ReturnSymbols) {
                return Read-CtagsIndex -IndexPath $OutputPath -Format $OutputFormat
            } else {
                return [PSCustomObject]@{
                    IndexPath = $OutputPath
                    Format = $OutputFormat
                    Created = Get-Date
                    SourcePath = $Path
                }
            }
            
        }
        catch {
            Write-Error "Failed to generate ctags index: $_"
            throw
        }
    }
}

function Read-CtagsIndex {
    <#
    .SYNOPSIS
    Reads and parses a ctags index file
    
    .DESCRIPTION
    Parses ctags output in various formats and returns structured symbol data
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$IndexPath,
        
        [Parameter()]
        [ValidateSet('json', 'tags', 'xml')]
        [string]$Format = 'json',
        
        [Parameter()]
        [string]$SymbolName,
        
        [Parameter()]
        [ValidateSet('function', 'class', 'variable', 'method', 'property', 'all')]
        [string]$SymbolType = 'all'
    )
    
    try {
        if (-not (Test-Path $IndexPath)) {
            throw "Index file not found: $IndexPath"
        }
        
        $symbols = @()
        
        switch ($Format) {
            'json' {
                # Read JSON format line by line (ctags outputs JSON lines)
                $lines = Get-Content $IndexPath
                
                foreach ($line in $lines) {
                    if ($line.Trim()) {
                        $symbol = $line | ConvertFrom-Json
                        
                        # Filter by name if specified
                        if ($SymbolName -and $symbol.name -notlike "*$SymbolName*") {
                            continue
                        }
                        
                        # Filter by type if specified
                        if ($SymbolType -ne 'all') {
                            $kind = $symbol.kind.ToLower()
                            if ($SymbolType -ne $kind -and 
                                -not ($SymbolType -eq 'method' -and $kind -eq 'member')) {
                                continue
                            }
                        }
                        
                        # Create standardized object
                        $symbols += [PSCustomObject]@{
                            Name = $symbol.name
                            Kind = $symbol.kind
                            File = $symbol.path
                            Line = $symbol.line
                            Scope = $symbol.scope
                            Signature = $symbol.signature
                            Language = $symbol.language
                        }
                    }
                }
            }
            
            'tags' {
                # Parse classic tags format
                $lines = Get-Content $IndexPath | Where-Object { -not $_.StartsWith('!') }
                
                foreach ($line in $lines) {
                    $parts = $line -split "`t"
                    
                    if ($parts.Count -ge 4) {
                        $name = $parts[0]
                        $file = $parts[1]
                        $pattern = $parts[2]
                        $kind = $parts[3]
                        
                        # Filter by name
                        if ($SymbolName -and $name -notlike "*$SymbolName*") {
                            continue
                        }
                        
                        # Extract line number from pattern if possible
                        $lineNum = 0
                        if ($pattern -match '^\d+$') {
                            $lineNum = [int]$pattern
                        }
                        
                        $symbols += [PSCustomObject]@{
                            Name = $name
                            Kind = $kind
                            File = $file
                            Line = $lineNum
                            Pattern = $pattern
                        }
                    }
                }
            }
        }
        
        return $symbols
    }
    catch {
        Write-Error "Failed to read ctags index: $_"
        throw
    }
}

function Find-Symbol {
    <#
    .SYNOPSIS
    Finds symbols in the ctags index
    
    .DESCRIPTION
    Quick symbol lookup with filtering and cross-reference support
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter()]
        [string]$IndexPath,
        
        [Parameter()]
        [ValidateSet('function', 'class', 'variable', 'method', 'property', 'all')]
        [string]$Type = 'all',
        
        [Parameter()]
        [switch]$ExactMatch,
        
        [Parameter()]
        [switch]$ShowContext
    )
    
    # Get default index path if not specified
    if (-not $IndexPath) {
        $cacheDir = Join-Path (Split-Path $PSScriptRoot -Parent -Parent) ".ai\cache"
        $IndexPath = Join-Path $cacheDir "tags.json"
        
        if (-not (Test-Path $IndexPath)) {
            Write-Warning "No index found. Generate one with Get-CtagsIndex first."
            return $null
        }
    }
    
    # Read index
    $searchName = if ($ExactMatch) { $Name } else { "*$Name*" }
    $symbols = Read-CtagsIndex -IndexPath $IndexPath -SymbolName $searchName -SymbolType $Type
    
    # Add context if requested
    if ($ShowContext -and $symbols) {
        foreach ($symbol in $symbols) {
            if ($symbol.File -and (Test-Path $symbol.File)) {
                $content = Get-Content $symbol.File
                
                $startLine = [Math]::Max(0, $symbol.Line - 3)
                $endLine = [Math]::Min($content.Count - 1, $symbol.Line + 3)
                
                $context = $content[$startLine..$endLine] -join "`n"
                $symbol | Add-Member -NotePropertyName 'Context' -NotePropertyValue $context
            }
        }
    }
    
    return $symbols
}

function Update-CtagsIndex {
    <#
    .SYNOPSIS
    Updates the ctags index for changed files only
    
    .DESCRIPTION
    Incrementally updates the ctags index based on git changes
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path = ".",
        
        [Parameter()]
        [string]$IndexPath,
        
        [Parameter()]
        [string]$Since = "HEAD~1"
    )
    
    try {
        # Get changed files
        $changedFiles = git diff --name-only $Since 2>&1
        
        if ($changedFiles) {
            Write-Verbose "Updating index for $($changedFiles.Count) changed files"
            
            # Get existing index path
            if (-not $IndexPath) {
                $cacheDir = Join-Path (Split-Path $PSScriptRoot -Parent -Parent) ".ai\cache"
                $IndexPath = Join-Path $cacheDir "tags.json"
            }
            
            # Update index for each changed file
            foreach ($file in $changedFiles) {
                if (Test-Path $file) {
                    Get-CtagsIndex -Path $file -OutputPath $IndexPath -UpdateIndex
                }
            }
            
            Write-Verbose "Index update completed"
            return $true
        } else {
            Write-Verbose "No changes detected"
            return $false
        }
    }
    catch {
        Write-Error "Failed to update ctags index: $_"
        throw
    }
}

# Export functions
Export-ModuleMember -Function Get-CtagsIndex, Read-CtagsIndex, Find-Symbol, Update-CtagsIndex
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAlCJVtS1ekYP2T
# pfSF3l0RDFCm0mzcwAzxLs0fiXBlAKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIIxTBKcVZRqSyANDK3olc7Y
# FGOmrO0ynUW5pKopyvvUMA0GCSqGSIb3DQEBAQUABIIBABL2zDs1D39ka1vWnCQs
# yxO/iRvdojgKp+Wav/A5UtbZ9lWx4DfnDB5fdL9xDZ9vehZQB0fdGfweeNd2Aiz1
# IGukHVDyxLEZe1/5JpGf76GsMie/96BdEoE3n5hyRx4x+XC2wYFxoXIDzgNlPD0G
# DbqTIY0jgmb3jZC5zvTtjCKQU5xbFfYJZXgPpPFnQHLCyvEPxTTdF6xHUroZ4M6N
# Sdh7i/ZDu4gLGlXY+eDjpIAnfLIIE07Px7o5QWebX+OG3YaQ+EB5u82CZJXw9PS/
# s7wSJ2L0hpkNrBJey87LPpN29KkeBbv71iITy7LtrFfuPUseZvp4WaqtwRIuzucj
# KLA=
# SIG # End signature block
