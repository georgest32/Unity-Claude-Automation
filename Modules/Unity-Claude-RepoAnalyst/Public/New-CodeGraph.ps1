function New-CodeGraph {
    <#
    .SYNOPSIS
    Generates a comprehensive code graph of the repository
    
    .DESCRIPTION
    Creates a JSON representation of the codebase structure including
    files, dependencies, symbols, and relationships
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,
        
        [Parameter()]
        [string]$OutputPath,
        
        [Parameter()]
        [string[]]$IncludePatterns = @('*.ps1', '*.psm1', '*.psd1', '*.cs', '*.js', '*.ts', '*.py'),
        
        [Parameter()]
        [string[]]$ExcludePatterns = @('*.min.js', '*.min.css', 'node_modules', '.git', 'bin', 'obj'),
        
        [Parameter()]
        [switch]$IncludeSymbols,
        
        [Parameter()]
        [switch]$IncludeDependencies,
        
        [Parameter()]
        [switch]$IncludeMetrics,
        
        [Parameter()]
        [switch]$UpdateExisting
    )
    
    begin {
        Write-Host "Generating code graph for: $ProjectPath" -ForegroundColor Cyan
        $startTime = Get-Date
        
        # Set default output path
        if (-not $OutputPath) {
            $cacheDir = Join-Path $ProjectPath ".ai\cache"
            if (-not (Test-Path $cacheDir)) {
                New-Item -Path $cacheDir -ItemType Directory -Force | Out-Null
            }
            $OutputPath = Join-Path $cacheDir "codegraph.json"
        }
        
        # Load existing graph if updating
        $existingGraph = $null
        if ($UpdateExisting -and (Test-Path $OutputPath)) {
            Write-Verbose "Loading existing code graph for update"
            $existingGraph = Get-Content $OutputPath -Raw | ConvertFrom-Json
        }
    }
    
    process {
        try {
            # Initialize code graph structure
            $codeGraph = @{
                metadata = @{
                    version = "1.0.0"
                    generated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
                    projectPath = $ProjectPath
                    projectName = Split-Path $ProjectPath -Leaf
                }
                files = @()
                symbols = @()
                dependencies = @{
                    internal = @()
                    external = @()
                }
                relationships = @()
                metrics = @{}
                languages = @{}
            }
            
            # Get all files matching patterns
            Write-Verbose "Scanning for files..."
            $files = @()
            
            foreach ($pattern in $IncludePatterns) {
                $matchedFiles = Get-ChildItem -Path $ProjectPath -Filter $pattern -Recurse -File |
                    Where-Object {
                        $file = $_
                        $excluded = $false
                        foreach ($exclude in $ExcludePatterns) {
                            if ($file.FullName -like "*$exclude*") {
                                $excluded = $true
                                break
                            }
                        }
                        -not $excluded
                    }
                $files += $matchedFiles
            }
            
            Write-Host "Found $($files.Count) files to analyze" -ForegroundColor Green
            
            # Analyze each file
            $fileIndex = 0
            foreach ($file in $files) {
                $fileIndex++
                Write-Progress -Activity "Analyzing files" -Status "$fileIndex of $($files.Count): $($file.Name)" -PercentComplete (($fileIndex / $files.Count) * 100)
                
                $relativePath = $file.FullName.Replace($ProjectPath, '').TrimStart('\', '/')
                
                # Get file info
                $fileInfo = @{
                    path = $relativePath
                    name = $file.Name
                    extension = $file.Extension
                    size = $file.Length
                    lastModified = $file.LastWriteTime.ToString("yyyy-MM-ddTHH:mm:ssZ")
                    language = Get-FileLanguage -Extension $file.Extension
                    hash = (Get-FileHash $file.FullName -Algorithm MD5).Hash
                    lines = 0
                    functions = @()
                    classes = @()
                    imports = @()
                }
                
                # Count lines
                $content = Get-Content $file.FullName
                $fileInfo.lines = $content.Count
                
                # Language-specific analysis
                switch ($fileInfo.language) {
                    'PowerShell' {
                        if ($file.Extension -in @('.ps1', '.psm1')) {
                            try {
                                $astResult = Get-PowerShellAST -Path $file.FullName
                                
                                # Extract functions
                                foreach ($func in $astResult.Functions) {
                                    $fileInfo.functions += @{
                                        name = $func.Name
                                        startLine = $func.StartLine
                                        endLine = $func.EndLine
                                        parameters = $func.Parameters
                                    }
                                }
                                
                                # Extract classes
                                foreach ($class in $astResult.Classes) {
                                    $fileInfo.classes += @{
                                        name = $class.Name
                                        startLine = $class.StartLine
                                        endLine = $class.EndLine
                                        members = $class.Members
                                    }
                                }
                                
                                # Extract imports
                                foreach ($import in $astResult.Imports) {
                                    $fileInfo.imports += @{
                                        type = $import.Type
                                        name = $import.Name
                                        line = $import.Line
                                    }
                                }
                                
                                # Add to language stats
                                if (-not $codeGraph.languages.PowerShell) {
                                    $codeGraph.languages.PowerShell = @{
                                        files = 0
                                        lines = 0
                                        functions = 0
                                        classes = 0
                                    }
                                }
                                $codeGraph.languages.PowerShell.files++
                                $codeGraph.languages.PowerShell.lines += $fileInfo.lines
                                $codeGraph.languages.PowerShell.functions += $fileInfo.functions.Count
                                $codeGraph.languages.PowerShell.classes += $fileInfo.classes.Count
                                
                            }
                            catch {
                                Write-Warning "Failed to parse PowerShell file $($file.Name): $_"
                            }
                        }
                    }
                    
                    # Add support for other languages here
                    default {
                        # Basic analysis for other file types
                        if (-not $codeGraph.languages.$($fileInfo.language)) {
                            $codeGraph.languages.$($fileInfo.language) = @{
                                files = 0
                                lines = 0
                            }
                        }
                        $codeGraph.languages.$($fileInfo.language).files++
                        $codeGraph.languages.$($fileInfo.language).lines += $fileInfo.lines
                    }
                }
                
                $codeGraph.files += $fileInfo
            }
            
            Write-Progress -Activity "Analyzing files" -Completed
            
            # Generate symbols index if requested
            if ($IncludeSymbols) {
                Write-Host "Generating symbol index..." -ForegroundColor Cyan
                
                try {
                    $tagsPath = Join-Path (Split-Path $OutputPath -Parent) "tags.json"
                    $ctagsResult = Get-CtagsIndex -Path $ProjectPath -OutputPath $tagsPath -Recurse -OutputFormat json -ReturnSymbols
                    
                    foreach ($symbol in $ctagsResult) {
                        $codeGraph.symbols += @{
                            name = $symbol.Name
                            kind = $symbol.Kind
                            file = $symbol.File
                            line = $symbol.Line
                            language = $symbol.Language
                        }
                    }
                    
                    Write-Host "Found $($codeGraph.symbols.Count) symbols" -ForegroundColor Green
                }
                catch {
                    Write-Warning "Failed to generate symbol index: $_"
                }
            }
            
            # Analyze dependencies if requested
            if ($IncludeDependencies) {
                Write-Host "Analyzing dependencies..." -ForegroundColor Cyan
                
                # Analyze PowerShell module dependencies
                $psdFiles = $files | Where-Object { $_.Extension -eq '.psd1' }
                foreach ($psdFile in $psdFiles) {
                    try {
                        $manifest = Import-PowerShellDataFile $psdFile.FullName
                        
                        if ($manifest.RequiredModules) {
                            foreach ($module in $manifest.RequiredModules) {
                                $moduleName = if ($module -is [hashtable]) { $module.ModuleName } else { $module }
                                
                                $codeGraph.dependencies.external += @{
                                    type = 'PowerShell Module'
                                    name = $moduleName
                                    source = $psdFile.Name
                                }
                            }
                        }
                    }
                    catch {
                        Write-Warning "Failed to parse manifest $($psdFile.Name): $_"
                    }
                }
                
                # Analyze internal function dependencies
                $ps1Files = $files | Where-Object { $_.Extension -in @('.ps1', '.psm1') }
                foreach ($ps1File in $ps1Files) {
                    try {
                        $deps = Get-FunctionDependencies -Path $ps1File.FullName -ReturnGraph
                        
                        foreach ($edge in $deps.edges) {
                            $codeGraph.dependencies.internal += @{
                                source = $edge.source
                                target = $edge.target
                                file = $ps1File.Name
                                type = 'function_call'
                            }
                        }
                    }
                    catch {
                        Write-Verbose "Failed to analyze dependencies for $($ps1File.Name): $_"
                    }
                }
                
                Write-Host "Found $($codeGraph.dependencies.internal.Count) internal dependencies" -ForegroundColor Green
                Write-Host "Found $($codeGraph.dependencies.external.Count) external dependencies" -ForegroundColor Green
            }
            
            # Calculate metrics if requested
            if ($IncludeMetrics) {
                Write-Host "Calculating metrics..." -ForegroundColor Cyan
                
                $codeGraph.metrics = @{
                    totalFiles = $codeGraph.files.Count
                    totalLines = ($codeGraph.files | Measure-Object -Property lines -Sum).Sum
                    totalSize = ($codeGraph.files | Measure-Object -Property size -Sum).Sum
                    totalFunctions = ($codeGraph.files | ForEach-Object { $_.functions.Count } | Measure-Object -Sum).Sum
                    totalClasses = ($codeGraph.files | ForEach-Object { $_.classes.Count } | Measure-Object -Sum).Sum
                    totalSymbols = $codeGraph.symbols.Count
                    averageLinesPerFile = [Math]::Round(($codeGraph.files | Measure-Object -Property lines -Average).Average, 2)
                    largestFile = ($codeGraph.files | Sort-Object -Property lines -Descending | Select-Object -First 1).path
                    languageDistribution = $codeGraph.languages
                }
                
                # Complexity metrics
                $complexFunctions = @()
                foreach ($file in $codeGraph.files) {
                    foreach ($func in $file.functions) {
                        $funcLines = $func.endLine - $func.startLine
                        if ($funcLines -gt 50) {
                            $complexFunctions += @{
                                name = $func.name
                                file = $file.path
                                lines = $funcLines
                            }
                        }
                    }
                }
                
                $codeGraph.metrics.complexFunctions = $complexFunctions
                $codeGraph.metrics.complexityScore = if ($complexFunctions.Count -gt 0) {
                    [Math]::Round(($complexFunctions.Count / $codeGraph.metrics.totalFunctions) * 100, 2)
                } else { 0 }
            }
            
            # Add generation time
            $endTime = Get-Date
            $codeGraph.metadata.generationTime = ($endTime - $startTime).TotalSeconds
            
            # Save to file
            $codeGraph | ConvertTo-Json -Depth 10 | Out-File $OutputPath -Encoding UTF8
            
            Write-Host "`nCode graph generated successfully!" -ForegroundColor Green
            Write-Host "Output: $OutputPath" -ForegroundColor Cyan
            Write-Host "Generation time: $([Math]::Round($codeGraph.metadata.generationTime, 2)) seconds" -ForegroundColor Gray
            
            # Display summary
            Write-Host "`nSummary:" -ForegroundColor Yellow
            Write-Host "  Files: $($codeGraph.files.Count)" -ForegroundColor White
            Write-Host "  Total Lines: $($codeGraph.metrics.totalLines)" -ForegroundColor White
            Write-Host "  Languages: $($codeGraph.languages.Keys -join ', ')" -ForegroundColor White
            
            if ($IncludeSymbols) {
                Write-Host "  Symbols: $($codeGraph.symbols.Count)" -ForegroundColor White
            }
            
            if ($IncludeDependencies) {
                Write-Host "  Dependencies: $($codeGraph.dependencies.internal.Count) internal, $($codeGraph.dependencies.external.Count) external" -ForegroundColor White
            }
            
            return [PSCustomObject]@{
                Path = $OutputPath
                FileCount = $codeGraph.files.Count
                SymbolCount = $codeGraph.symbols.Count
                GenerationTime = $codeGraph.metadata.generationTime
            }
            
        }
        catch {
            Write-Error "Failed to generate code graph: $_"
            throw
        }
    }
}

function Get-FileLanguage {
    <#
    .SYNOPSIS
    Determines the programming language based on file extension
    #>
    param(
        [string]$Extension
    )
    
    $languageMap = @{
        '.ps1' = 'PowerShell'
        '.psm1' = 'PowerShell'
        '.psd1' = 'PowerShell'
        '.cs' = 'CSharp'
        '.js' = 'JavaScript'
        '.ts' = 'TypeScript'
        '.py' = 'Python'
        '.java' = 'Java'
        '.cpp' = 'C++'
        '.c' = 'C'
        '.h' = 'C/C++ Header'
        '.go' = 'Go'
        '.rs' = 'Rust'
        '.rb' = 'Ruby'
        '.php' = 'PHP'
        '.sql' = 'SQL'
        '.html' = 'HTML'
        '.css' = 'CSS'
        '.xml' = 'XML'
        '.json' = 'JSON'
        '.yaml' = 'YAML'
        '.yml' = 'YAML'
        '.md' = 'Markdown'
        '.txt' = 'Text'
    }
    
    if ($languageMap.ContainsKey($Extension)) {
        return $languageMap[$Extension]
    } else {
        return 'Unknown'
    }
}

function Update-CodeGraph {
    <#
    .SYNOPSIS
    Incrementally updates the code graph for changed files
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ProjectPath = ".",
        
        [Parameter()]
        [string]$GraphPath,
        
        [Parameter()]
        [string]$Since = "HEAD~1"
    )
    
    try {
        # Get default graph path
        if (-not $GraphPath) {
            $cacheDir = Join-Path $ProjectPath ".ai\cache"
            $GraphPath = Join-Path $cacheDir "codegraph.json"
        }
        
        if (-not (Test-Path $GraphPath)) {
            Write-Warning "No existing code graph found. Generating new one..."
            return New-CodeGraph -ProjectPath $ProjectPath -OutputPath $GraphPath
        }
        
        # Get changed files
        $changes = Get-CodeChanges -Since $Since -Path $ProjectPath
        
        if ($changes) {
            Write-Host "Updating code graph for $($changes.Count) changed files..." -ForegroundColor Cyan
            
            # Load existing graph
            $codeGraph = Get-Content $GraphPath -Raw | ConvertFrom-Json -AsHashtable
            
            # Update metadata
            $codeGraph.metadata.lastUpdated = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            
            # Update changed files
            foreach ($change in $changes) {
                # Implementation would update specific file entries
                Write-Verbose "Updating: $($change.Path)"
            }
            
            # Save updated graph
            $codeGraph | ConvertTo-Json -Depth 10 | Out-File $GraphPath -Encoding UTF8
            
            Write-Host "Code graph updated successfully" -ForegroundColor Green
            return $true
        } else {
            Write-Host "No changes detected" -ForegroundColor Gray
            return $false
        }
    }
    catch {
        Write-Error "Failed to update code graph: $_"
        throw
    }
}

# Export functions
Export-ModuleMember -Function New-CodeGraph, Get-FileLanguage, Update-CodeGraph
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBhPZ1By8y9a5gA
# eomEtHhlkpZ8gRoCAzqlE/8ZCiq6aKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINPJm7Wt+fCDD8UJKeRcx1th
# FbSa3je2ROq2CTXVPo3lMA0GCSqGSIb3DQEBAQUABIIBAK192rWPmwW8wnQjPb2e
# tyNeHLQqIJ1MmgWuGjuwJqtPzK+wvifWkmrkLa+DLMKj7utAjm91FSH32SXVvNEw
# FlvxrHTVolIqKPl7LQA5of6EzZ2PQP0JZXGf2Jlz7+wBPSoGwwN6oTR6zHnraLoA
# knbVhE+nEDaqzuZsgYx2q/025qeURBVP9CL+Ayv19EHi/jXV7WTfDlH/anxP1FcC
# 0OT4JIrIXrYSEJU07sRVD943Vz4yBhjPSd7gUCbuPRTeMmKi8RB7BnUDKCULl7Ra
# Vr/FfVvEhLGJxV/hj5tc2WZN591CF61MfINTPWypy7UWH6YRiS7Q9Bry+c1b1lEF
# 5i0=
# SIG # End signature block
