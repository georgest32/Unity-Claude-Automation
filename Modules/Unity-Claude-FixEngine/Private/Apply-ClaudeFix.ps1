function Apply-ClaudeFix {
    <#
    .SYNOPSIS
    Applies Claude's suggested fix to the file with safety checks and backup
    
    .DESCRIPTION
    Takes Claude's suggested fix and applies it to the target file using
    atomic operations with comprehensive backup and rollback capability
    
    .PARAMETER FilePath
    Path to the file to modify
    
    .PARAMETER Fix
    Claude's suggested fix (code content)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$Fix
    )
    
    Write-FixEngineLog -Message "Applying Claude's fix to: $FilePath" -Level "INFO"
    
    $result = @{
        Success = $false
        BackupPath = ""
        Error = ""
        FixType = ""
        ModifiedLines = 0
    }
    
    try {
        # Step 1: Create backup
        Write-FixEngineLog -Message "Creating backup before applying fix" -Level "DEBUG"
        $backupPath = New-BackupFile -FilePath $FilePath -BackupReason "Claude Fix Application"
        $result.BackupPath = $backupPath
        
        # Step 2: Read current file content
        $originalContent = Get-Content -Path $FilePath -Raw -Encoding UTF8
        $originalLines = Get-Content -Path $FilePath -Encoding UTF8
        
        # Step 3: Determine fix type and apply
        $fixType = Determine-FixType -Fix $Fix -OriginalContent $originalContent
        $result.FixType = $fixType
        
        Write-FixEngineLog -Message "Applying fix type: $fixType" -Level "DEBUG"
        
        $modifiedContent = switch ($fixType) {
            "FullFileReplacement" {
                Apply-FullFileReplacement -Fix $Fix
            }
            "UsingStatements" {
                Apply-UsingStatements -OriginalContent $originalContent -Fix $Fix
            }
            "CodeBlock" {
                Apply-CodeBlock -OriginalContent $originalContent -Fix $Fix
            }
            "LineInsertion" {
                Apply-LineInsertion -OriginalLines $originalLines -Fix $Fix
            }
            "SmartMerge" {
                Apply-SmartMerge -OriginalContent $originalContent -Fix $Fix
            }
            default {
                throw "Unknown fix type: $fixType"
            }
        }
        
        # Step 4: Validate the modified content
        $validationResult = Test-BasicCodeValidation -Content $modifiedContent
        if (-not $validationResult.IsValid) {
            throw "Fix validation failed: $($validationResult.Errors -join '; ')"
        }
        
        # Step 5: Apply the fix atomically
        Write-FixEngineLog -Message "Applying fix atomically to file" -Level "DEBUG"
        $atomicResult = Invoke-AtomicFileReplace -FilePath $FilePath -NewContent $modifiedContent -BackupReason "Claude Fix"
        
        if ($atomicResult.Success) {
            $result.Success = $true
            $result.ModifiedLines = ($modifiedContent -split "`n").Count - ($originalContent -split "`n").Count
            Write-FixEngineLog -Message "Claude fix applied successfully. Modified lines: $($result.ModifiedLines)" -Level "INFO"
        } else {
            throw "Atomic file replacement failed"
        }
        
    }
    catch {
        $result.Error = "Failed to apply Claude fix: $_"
        Write-FixEngineLog -Message $result.Error -Level "ERROR"
        
        # Attempt rollback if backup exists
        if ($result.BackupPath -and (Test-Path $result.BackupPath)) {
            try {
                Restore-BackupFile -BackupPath $result.BackupPath -TargetPath $FilePath
                Write-FixEngineLog -Message "File restored from backup after failed fix application" -Level "INFO"
            }
            catch {
                Write-FixEngineLog -Message "Failed to restore from backup: $_" -Level "ERROR"
            }
        }
    }
    
    return $result
}

function Determine-FixType {
    <#
    .SYNOPSIS
    Determines how to apply Claude's fix based on its content
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Fix,
        
        [Parameter(Mandatory = $true)]
        [string]$OriginalContent
    )
    
    # Check if fix contains complete file structure (class definitions, full methods)
    if ($Fix -match 'class\s+\w+' -and $Fix -match '\{.*\}' -and $Fix.Length -gt ($OriginalContent.Length * 0.5)) {
        return "FullFileReplacement"
    }
    
    # Check if fix is just using statements
    if ($Fix -match '^\s*using\s+' -and $Fix -notmatch '\{|\}|class|namespace') {
        return "UsingStatements"
    }
    
    # Check if fix contains method bodies or significant code blocks
    if ($Fix -match '\{.*\}' -or $Fix -match 'public|private|protected.*\{') {
        return "CodeBlock"
    }
    
    # Check if fix is single line additions
    if (($Fix -split "`n").Count -le 3 -and $Fix -notmatch '\{|\}') {
        return "LineInsertion"
    }
    
    # Default to smart merge for complex fixes
    return "SmartMerge"
}

function Apply-FullFileReplacement {
    <#
    .SYNOPSIS
    Replaces the entire file content with Claude's fix
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Fix
    )
    
    Write-FixEngineLog -Message "Applying full file replacement" -Level "DEBUG"
    return $Fix
}

function Apply-UsingStatements {
    <#
    .SYNOPSIS
    Adds or modifies using statements at the top of the file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OriginalContent,
        
        [Parameter(Mandatory = $true)]
        [string]$Fix
    )
    
    Write-FixEngineLog -Message "Applying using statements fix" -Level "DEBUG"
    
    $lines = $OriginalContent -split "`n"
    $newUsingStatements = $Fix -split "`n" | Where-Object { $_ -match '^\s*using\s+' }
    
    # Find where to insert using statements
    $insertIndex = 0
    $lastUsingIndex = -1
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*using\s+') {
            $lastUsingIndex = $i
        } elseif ($lines[$i] -match '^\s*namespace\s+' -or $lines[$i] -match '^\s*public\s+class') {
            break
        }
    }
    
    if ($lastUsingIndex -ge 0) {
        $insertIndex = $lastUsingIndex + 1
    } else {
        # Insert at beginning, but after any comments
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -notmatch '^\s*//') {
                $insertIndex = $i
                break
            }
        }
    }
    
    # Remove duplicates and insert new using statements
    $existingUsings = $lines | Where-Object { $_ -match '^\s*using\s+' }
    $uniqueNewUsings = @()
    
    foreach ($newUsing in $newUsingStatements) {
        $namespace = ($newUsing -replace '^\s*using\s+', '' -replace ';.*$', '').Trim()
        $isDuplicate = $false
        
        foreach ($existing in $existingUsings) {
            $existingNamespace = ($existing -replace '^\s*using\s+', '' -replace ';.*$', '').Trim()
            if ($namespace -eq $existingNamespace) {
                $isDuplicate = $true
                break
            }
        }
        
        if (-not $isDuplicate) {
            $uniqueNewUsings += $newUsing
        }
    }
    
    # Insert unique using statements
    $newLines = @()
    $newLines += $lines[0..($insertIndex - 1)]
    $newLines += $uniqueNewUsings
    $newLines += $lines[$insertIndex..($lines.Count - 1)]
    
    return $newLines -join "`n"
}

function Apply-CodeBlock {
    <#
    .SYNOPSIS
    Applies code block fixes by replacing specific methods or classes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OriginalContent,
        
        [Parameter(Mandatory = $true)]
        [string]$Fix
    )
    
    Write-FixEngineLog -Message "Applying code block fix" -Level "DEBUG"
    
    # For now, use smart merge approach for code blocks
    # This could be enhanced with more sophisticated AST-based replacement
    return Apply-SmartMerge -OriginalContent $OriginalContent -Fix $Fix
}

function Apply-LineInsertion {
    <#
    .SYNOPSIS
    Inserts single lines or small blocks at appropriate locations
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$OriginalLines,
        
        [Parameter(Mandatory = $true)]
        [string]$Fix
    )
    
    Write-FixEngineLog -Message "Applying line insertion fix" -Level "DEBUG"
    
    $fixLines = $Fix -split "`n" | Where-Object { $_.Trim() -ne "" }
    
    # Simple heuristic: insert at end of using statements if it's a using,
    # otherwise insert at a logical location (like after class declaration)
    if ($fixLines[0] -match '^\s*using\s+') {
        # Insert after last using statement
        $insertIndex = 0
        for ($i = 0; $i -lt $OriginalLines.Count; $i++) {
            if ($OriginalLines[$i] -match '^\s*using\s+') {
                $insertIndex = $i + 1
            }
        }
        
        $newLines = @()
        $newLines += $OriginalLines[0..($insertIndex - 1)]
        $newLines += $fixLines
        $newLines += $OriginalLines[$insertIndex..($OriginalLines.Count - 1)]
        
        return $newLines -join "`n"
    } else {
        # Insert at end of file or before closing brace
        $insertIndex = $OriginalLines.Count
        
        # Look for last closing brace
        for ($i = $OriginalLines.Count - 1; $i -ge 0; $i--) {
            if ($OriginalLines[$i] -match '^\s*\}\s*$') {
                $insertIndex = $i
                break
            }
        }
        
        $newLines = @()
        $newLines += $OriginalLines[0..($insertIndex - 1)]
        $newLines += $fixLines
        $newLines += $OriginalLines[$insertIndex..($OriginalLines.Count - 1)]
        
        return $newLines -join "`n"
    }
}

function Apply-SmartMerge {
    <#
    .SYNOPSIS
    Intelligently merges Claude's fix with original content
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OriginalContent,
        
        [Parameter(Mandatory = $true)]
        [string]$Fix
    )
    
    Write-FixEngineLog -Message "Applying smart merge fix" -Level "DEBUG"
    
    # For complex fixes where we can't determine the exact merge strategy,
    # we'll use a conservative approach: prepend any using statements,
    # then append the rest of the fix with clear markers
    
    $originalLines = $OriginalContent -split "`n"
    $fixLines = $Fix -split "`n"
    
    # Extract using statements from fix
    $usingLines = $fixLines | Where-Object { $_ -match '^\s*using\s+' }
    $codeLines = $fixLines | Where-Object { $_ -notmatch '^\s*using\s+' -and $_.Trim() -ne "" }
    
    # Apply using statements first
    $modifiedContent = $OriginalContent
    if ($usingLines.Count -gt 0) {
        $modifiedContent = Apply-UsingStatements -OriginalContent $modifiedContent -Fix ($usingLines -join "`n")
    }
    
    # Add code lines at appropriate location
    if ($codeLines.Count -gt 0) {
        $modifiedLines = $modifiedContent -split "`n"
        
        # Find insertion point (before last closing brace or at end)
        $insertIndex = $modifiedLines.Count
        for ($i = $modifiedLines.Count - 1; $i -ge 0; $i--) {
            if ($modifiedLines[$i] -match '^\s*\}\s*$') {
                $insertIndex = $i
                break
            }
        }
        
        $newLines = @()
        $newLines += $modifiedLines[0..($insertIndex - 1)]
        $newLines += ""  # Empty line for separation
        $newLines += "// Claude-generated fix"
        $newLines += $codeLines
        $newLines += $modifiedLines[$insertIndex..($modifiedLines.Count - 1)]
        
        $modifiedContent = $newLines -join "`n"
    }
    
    return $modifiedContent
}

function Apply-FixToContent {
    <#
    .SYNOPSIS
    Applies fix to content without modifying the file (for preview)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$Fix,
        
        [Parameter()]
        [switch]$Preview
    )
    
    if (-not $Preview) {
        throw "This function is only for preview mode"
    }
    
    $originalContent = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $originalLines = Get-Content -Path $FilePath -Encoding UTF8
    
    $fixType = Determine-FixType -Fix $Fix -OriginalContent $originalContent
    
    $modifiedContent = switch ($fixType) {
        "FullFileReplacement" { Apply-FullFileReplacement -Fix $Fix }
        "UsingStatements" { Apply-UsingStatements -OriginalContent $originalContent -Fix $Fix }
        "CodeBlock" { Apply-CodeBlock -OriginalContent $originalContent -Fix $Fix }
        "LineInsertion" { Apply-LineInsertion -OriginalLines $originalLines -Fix $Fix }
        "SmartMerge" { Apply-SmartMerge -OriginalContent $originalContent -Fix $Fix }
        default { $originalContent }
    }
    
    return $modifiedContent
}

function Test-BasicCodeValidation {
    <#
    .SYNOPSIS
    Performs basic validation on modified code content
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    $result = @{
        IsValid = $true
        Errors = @()
    }
    
    try {
        # Check for balanced braces
        $openBraces = ($Content | Select-String -Pattern '{' -AllMatches).Matches.Count
        $closeBraces = ($Content | Select-String -Pattern '}' -AllMatches).Matches.Count
        if ($openBraces -ne $closeBraces) {
            $result.Errors += "Unbalanced braces: $openBraces open, $closeBraces close"
            $result.IsValid = $false
        }
        
        # Check for balanced parentheses
        $openParens = ($Content | Select-String -Pattern '\(' -AllMatches).Matches.Count
        $closeParens = ($Content | Select-String -Pattern '\)' -AllMatches).Matches.Count
        if ($openParens -ne $closeParens) {
            $result.Errors += "Unbalanced parentheses: $openParens open, $closeParens close"
            $result.IsValid = $false
        }
        
        # Check for basic syntax issues
        $lines = $Content -split "`n"
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i].Trim()
            
            # Check for unterminated strings (basic check)
            if ($line -match '"[^"]*$' -and $line -notmatch '\\["`]$') {
                $result.Errors += "Possible unterminated string on line $($i + 1)"
                $result.IsValid = $false
            }
        }
        
        Write-FixEngineLog -Message "Basic code validation completed. Valid: $($result.IsValid)" -Level "DEBUG"
    }
    catch {
        $result.IsValid = $false
        $result.Errors += "Validation exception: $_"
        Write-FixEngineLog -Message "Code validation failed: $_" -Level "ERROR"
    }
    
    return $result
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU7rlUHevW9JgjG3ygoFsSj3ui
# H5mgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUgdEIzm9+qORJgCqB1n3V9B0EJfswDQYJKoZIhvcNAQEBBQAEggEAr4DZ
# fWnO8nTif80Alu/5/zuwgYp5RIquv75BGuhuZUT6qqdyzRJAByppCudMug+DrY0d
# r57eoZnSBaVaeTIra14NNeTCUyvQuLc/Qp5qNz1n3fPJKqA0lTHGu0+OwKVHkISD
# ONpJrkl8RrpzlzaIntM2kyqKzfphbB21pkttlkiRr4D2VZxuRKpSBbSJDbp5agK9
# xhibU6LdquP3fJG1/jNqKcxrb+Q8e2OEo3hqnLmKjOcYlDoFCMweWWz/aJ35ooj/
# b4e5iLvoCM8VgR3WAADS3jMR+awRIfhKDvM2mZUenOSFCs9Azc89COPdHolP/uSW
# JAJf712hcHmsdUQMMg==
# SIG # End signature block
