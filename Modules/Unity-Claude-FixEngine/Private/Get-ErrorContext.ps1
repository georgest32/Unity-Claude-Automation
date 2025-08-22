function Get-ErrorContext {
    <#
    .SYNOPSIS
    Gathers comprehensive error context for Claude analysis
    
    .DESCRIPTION
    Collects file content, project structure, error details, and environment
    information to provide Claude with maximum context for fix generation
    
    .PARAMETER FilePath
    Path to the file containing the error
    
    .PARAMETER ErrorMessage
    The compilation error message
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage
    )
    
    Write-FixEngineLog -Message "Gathering error context for: $FilePath" -Level "DEBUG"
    
    $context = @{
        FilePath = $FilePath
        ErrorMessage = $ErrorMessage
        FileContent = ""
        LineNumber = 0
        ColumnNumber = 0
        RelativeFilePath = ""
        ProjectContext = ""
        UnityVersion = "2021.1.14f1"
        SurroundingFiles = @()
        UsedNamespaces = @()
        RecentErrors = @()
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    try {
        # Read file content
        if (Test-Path $FilePath) {
            $context.FileContent = Get-Content -Path $FilePath -Raw -Encoding UTF8
            Write-FixEngineLog -Message "Read file content: $($context.FileContent.Length) characters" -Level "DEBUG"
        } else {
            Write-FixEngineLog -Message "File not found: $FilePath" -Level "ERROR"
            throw "File not found: $FilePath"
        }
        
        # Extract line and column numbers from error message
        if ($ErrorMessage -match '\((\d+),(\d+)\)') {
            $context.LineNumber = [int]$matches[1]
            $context.ColumnNumber = [int]$matches[2]
            Write-FixEngineLog -Message "Extracted error location: Line $($context.LineNumber), Column $($context.ColumnNumber)" -Level "DEBUG"
        }
        
        # Determine relative file path
        $context.RelativeFilePath = Get-RelativeProjectPath -FilePath $FilePath
        
        # Gather project context
        $context.ProjectContext = Get-ProjectStructureContext -FilePath $FilePath
        
        # Find surrounding files for additional context
        $context.SurroundingFiles = Get-SurroundingFiles -FilePath $FilePath
        
        # Extract used namespaces from file
        $context.UsedNamespaces = Get-UsedNamespaces -FileContent $context.FileContent
        
        # Get recent compilation errors for pattern recognition
        $context.RecentErrors = Get-RecentCompilationErrors
        
        Write-FixEngineLog -Message "Error context gathered successfully" -Level "DEBUG"
        
    }
    catch {
        Write-FixEngineLog -Message "Failed to gather error context: $_" -Level "ERROR"
        throw "Error context gathering failed: $_"
    }
    
    return $context
}

function Get-RelativeProjectPath {
    <#
    .SYNOPSIS
    Converts absolute file path to relative project path
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        # Find Unity project root (contains Assets folder)
        $currentDir = Split-Path $FilePath -Parent
        $projectRoot = $currentDir
        
        while ($projectRoot -and -not (Test-Path (Join-Path $projectRoot "Assets"))) {
            $parent = Split-Path $projectRoot -Parent
            if ($parent -eq $projectRoot) {
                break  # Reached filesystem root
            }
            $projectRoot = $parent
        }
        
        if ($projectRoot -and (Test-Path (Join-Path $projectRoot "Assets"))) {
            $relativePath = $FilePath.Substring($projectRoot.Length).TrimStart('\', '/')
            return $relativePath.Replace('\', '/')
        }
        
        # Fallback to filename if project root not found
        return Split-Path $FilePath -Leaf
    }
    catch {
        Write-FixEngineLog -Message "Failed to determine relative path: $_" -Level "WARN"
        return Split-Path $FilePath -Leaf
    }
}

function Get-ProjectStructureContext {
    <#
    .SYNOPSIS
    Gathers relevant project structure information
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        $fileDir = Split-Path $FilePath -Parent
        $contextInfo = @()
        
        # Check if in Assets folder
        if ($fileDir -match "Assets") {
            $contextInfo += "Unity Assets folder"
            
            # Determine specific Asset folder type
            if ($fileDir -match "Scripts") {
                $contextInfo += "Scripts folder"
            }
            if ($fileDir -match "Editor") {
                $contextInfo += "Editor scripts"
            }
            if ($fileDir -match "Plugins") {
                $contextInfo += "Plugins folder"
            }
        }
        
        # Check for assembly definition files
        $asmdefFiles = Get-ChildItem -Path $fileDir -Filter "*.asmdef" -ErrorAction SilentlyContinue
        if ($asmdefFiles) {
            $contextInfo += "Custom assembly definition: $($asmdefFiles[0].BaseName)"
        }
        
        # Check for package.json (UPM package)
        if (Test-Path (Join-Path $fileDir "package.json")) {
            $contextInfo += "UPM package"
        }
        
        return $contextInfo -join ", "
    }
    catch {
        Write-FixEngineLog -Message "Failed to gather project structure context: $_" -Level "WARN"
        return "Unknown project structure"
    }
}

function Get-SurroundingFiles {
    <#
    .SYNOPSIS
    Gets information about files in the same directory for context
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        $fileDir = Split-Path $FilePath -Parent
        $surroundingFiles = @()
        
        # Get C# files in the same directory
        $csFiles = Get-ChildItem -Path $fileDir -Filter "*.cs" -ErrorAction SilentlyContinue | 
                   Where-Object { $_.Name -ne (Split-Path $FilePath -Leaf) } |
                   Select-Object -First 5
        
        foreach ($file in $csFiles) {
            # Get first few lines to understand the file's purpose
            $firstLines = Get-Content -Path $file.FullName -TotalCount 10 -ErrorAction SilentlyContinue
            $classMatch = $firstLines | Select-String -Pattern "class\s+(\w+)" | Select-Object -First 1
            
            if ($classMatch) {
                $className = $classMatch.Matches[0].Groups[1].Value
                $surroundingFiles += @{
                    FileName = $file.Name
                    ClassName = $className
                }
            } else {
                $surroundingFiles += @{
                    FileName = $file.Name
                    ClassName = "Unknown"
                }
            }
        }
        
        return $surroundingFiles
    }
    catch {
        Write-FixEngineLog -Message "Failed to gather surrounding files context: $_" -Level "WARN"
        return @()
    }
}

function Get-UsedNamespaces {
    <#
    .SYNOPSIS
    Extracts using statements from file content
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileContent
    )
    
    try {
        $namespaces = @()
        
        # Extract using statements
        $usingMatches = [regex]::Matches($FileContent, '^\s*using\s+([^;]+);', [System.Text.RegularExpressions.RegexOptions]::Multiline)
        
        foreach ($match in $usingMatches) {
            $namespace = $match.Groups[1].Value.Trim()
            $namespaces += $namespace
        }
        
        return $namespaces | Sort-Object -Unique
    }
    catch {
        Write-FixEngineLog -Message "Failed to extract namespaces: $_" -Level "WARN"
        return @()
    }
}

function Get-RecentCompilationErrors {
    <#
    .SYNOPSIS
    Gets recent compilation errors for pattern recognition
    #>
    [CmdletBinding()]
    param()
    
    try {
        $recentErrors = @()
        
        # Try to read from Unity Editor log
        $unityLogPath = "$env:LOCALAPPDATA\Unity\Editor\Editor.log"
        if (Test-Path $unityLogPath) {
            $logContent = Get-Content -Path $unityLogPath -Tail 100 -ErrorAction SilentlyContinue
            
            foreach ($line in $logContent) {
                if ($line -match 'error\s+(CS\d+):') {
                    $recentErrors += $line.Trim()
                }
            }
            
            # Limit to last 5 errors to avoid overwhelming Claude
            $recentErrors = $recentErrors | Select-Object -Last 5
        }
        
        return $recentErrors
    }
    catch {
        Write-FixEngineLog -Message "Failed to gather recent compilation errors: $_" -Level "WARN"
        return @()
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU2LtYhHWKW5dA1Aj+aAEFxeBy
# A8KgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUaWrROkQ5jb5gsJI6LLZaQgswPi0wDQYJKoZIhvcNAQEBBQAEggEAQxOX
# 0tCskMr2sqPYuo1dstffzc9YhIy410gp51h9cIEM20MPrd2j3pu3nK1Q4OxHPHO7
# JEtyDWpQaZUsZ+b0Wbn1thpqHRZD6z/1Gdxup+cdPu0mUwsHlMdq+4vX20Ddzw+Z
# MczC8AqKUpz/zXPal0j+4v11IE8HKE+EXoDbKW1a9ZpTK+3JuyZqbaC4wfH+PpPC
# tCIx7zTjOCYQHCx8cJMp38rXof2K/Di7EIJE8gXLQGf0HEMiJNZiUDaJd0IpmHcu
# /1akCJnplZk9RGkBapKT5FrD6ovAG8yIyYuHgpfO2CGgOuEQ6WRsbXJLPDgTK8tT
# Zd6vgUAKFUZnJbEVPw==
# SIG # End signature block
