function Get-SubsystemManifests {
    <#
    .SYNOPSIS
    Discovers and loads subsystem manifest files.
    
    .DESCRIPTION
    Scans specified directories for subsystem manifest files (*.manifest.psd1),
    loads them, validates their schema, and returns an array of valid manifests.
    Results are cached for performance.
    
    .PARAMETER Path
    Path(s) to search for manifest files. Defaults to standard locations.
    
    .PARAMETER Force
    Force a refresh of the manifest cache.
    
    .PARAMETER IncludeInvalid
    Include manifests that fail validation (with error information).
    
    .EXAMPLE
    Get-SubsystemManifests
    
    .EXAMPLE
    Get-SubsystemManifests -Path "C:\Subsystems" -Force
    
    .EXAMPLE
    Get-SubsystemManifests -IncludeInvalid | Where-Object { -not $_.IsValid }
    #>
    
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$Path,
        
        [Parameter()]
        [switch]$Force,
        
        [Parameter()]
        [switch]$IncludeInvalid
    )
    
    Write-SystemStatusLog "Discovering subsystem manifests" -Level 'DEBUG'
    
    # Use cached results if available and not forced
    if (-not $Force -and $script:ManifestCache -and 
        $script:ManifestCacheTime -and 
        ((Get-Date) - $script:ManifestCacheTime).TotalSeconds -lt 300) {
        
        Write-SystemStatusLog "Using cached manifest data (age: $(((Get-Date) - $script:ManifestCacheTime).TotalSeconds) seconds)" -Level 'TRACE'
        
        if ($IncludeInvalid) {
            return $script:ManifestCache
        } else {
            return $script:ManifestCache | Where-Object { $_.IsValid }
        }
    }
    
    # Default search paths if none specified
    if (-not $Path) {
        $moduleRoot = if ($script:ModuleRootPath) { 
            $script:ModuleRootPath 
        } else { 
            Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
        }
        
        $Path = @(
            # Primary manifest directory
            Join-Path $moduleRoot "Manifests"
            
            # Module-specific manifests
            Join-Path $moduleRoot "Modules"
            
            # Root directory
            $moduleRoot
            
            # Current directory
            Get-Location
        )
        
        Write-SystemStatusLog "Using default search paths: $($Path -join ', ')" -Level 'TRACE'
    }
    
    # Find all manifest files with duplicate detection
    $manifestFiles = @()
    $foundPaths = @{}
    
    foreach ($searchPath in $Path) {
        if (Test-Path $searchPath) {
            Write-SystemStatusLog "Searching for manifests in: $searchPath" -Level 'TRACE'
            
            # Get manifest files, excluding backup directories
            $files = Get-ChildItem -Path $searchPath -Filter "*.manifest.psd1" -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -notmatch "\\Backups\\" -and $_.FullName -notmatch "/Backups/" }
            
            if ($files) {
                $newFiles = @()
                foreach ($file in $files) {
                    $fullPath = $file.FullName
                    if (-not $foundPaths.ContainsKey($fullPath)) {
                        $foundPaths[$fullPath] = $true
                        $newFiles += $file
                        $manifestFiles += $file
                    } else {
                        Write-SystemStatusLog "Skipping duplicate manifest: $fullPath (already found in previous search path)" -Level 'TRACE'
                    }
                }
                Write-SystemStatusLog "Found $($newFiles.Count) new manifest files in $searchPath ($($files.Count - $newFiles.Count) duplicates skipped)" -Level 'DEBUG'
            }
        } else {
            Write-SystemStatusLog "Search path does not exist: $searchPath" -Level 'TRACE'
        }
    }
    
    Write-SystemStatusLog "Total manifest files found: $($manifestFiles.Count)" -Level 'INFO'
    
    # Load and validate each manifest
    $manifests = @()
    
    foreach ($file in $manifestFiles) {
        Write-SystemStatusLog "Processing manifest: $($file.FullName)" -Level 'DEBUG'
        
        try {
            # Load the manifest (PowerShell 5.1 compatible)
            if (Get-Command Import-PowerShellDataFile -ErrorAction SilentlyContinue) {
                $manifestData = Import-PowerShellDataFile -Path $file.FullName
            } else {
                # PowerShell 5.1 fallback - use Invoke-Expression with safety checks
                $manifestContent = Get-Content -Path $file.FullName -Raw
                $manifestData = Invoke-Expression $manifestContent
            }
            
            # Add metadata
            $manifestData['_ManifestPath'] = $file.FullName
            $manifestData['_ManifestDirectory'] = $file.DirectoryName
            $manifestData['_ManifestFileName'] = $file.Name
            $manifestData['_LoadedAt'] = Get-Date
            
            # If no name specified, derive from filename
            if (-not $manifestData.Name) {
                $manifestData.Name = $file.BaseName -replace '\.manifest$', ''
                Write-SystemStatusLog "Derived subsystem name from filename: $($manifestData.Name)" -Level 'TRACE'
            }
            
            # Validate the manifest
            $validation = Test-SubsystemManifest -Manifest $manifestData
            
            # Perform security validation
            $securityCheck = $null
            if (Get-Command Test-ManifestSecurity -ErrorAction SilentlyContinue) {
                try {
                    $securityCheck = Test-ManifestSecurity -Manifest $manifestData -StrictMode:$Force
                    
                    if (-not $securityCheck.IsSecure) {
                        Write-SystemStatusLog "Security validation failed for $($manifestData.Name): $($securityCheck.SecurityIssues -join '; ')" -Level 'WARN'
                        $validation.IsValid = $false
                        $validation.Errors += $securityCheck.SecurityIssues
                    }
                } catch {
                    Write-SystemStatusLog "Security validation error for $($manifestData.Name): $_" -Level 'WARN'
                }
            }
            
            # Create manifest object
            $manifestObject = [PSCustomObject]@{
                Name = $manifestData.Name
                Version = $manifestData.Version
                Path = $file.FullName
                Directory = $file.DirectoryName
                FileName = $file.Name
                LoadedAt = Get-Date
                IsValid = $validation.IsValid
                Errors = $validation.Errors
                Warnings = $validation.Warnings
                Data = $manifestData
                Priority = if ($manifestData.Priority) { $manifestData.Priority } else { 50 }
            }
            
            $manifests += $manifestObject
            
            if ($validation.IsValid) {
                Write-SystemStatusLog "Successfully loaded manifest: $($manifestData.Name) v$($manifestData.Version)" -Level 'OK'
            } else {
                Write-SystemStatusLog "Loaded invalid manifest: $($manifestData.Name) - $($validation.Errors -join '; ')" -Level 'WARN'
            }
            
        } catch {
            Write-SystemStatusLog "Failed to load manifest $($file.FullName): $_" -Level 'ERROR'
            
            if ($IncludeInvalid) {
                # Add error manifest object
                $manifests += [PSCustomObject]@{
                    Name = $file.BaseName
                    Version = "Unknown"
                    Path = $file.FullName
                    Directory = $file.DirectoryName
                    FileName = $file.Name
                    LoadedAt = Get-Date
                    IsValid = $false
                    Errors = @("Failed to load: $_")
                    Warnings = @()
                    Data = @{}
                    Priority = 100
                }
            }
        }
    }
    
    # Sort by priority and dependencies
    if ($manifests.Count -gt 0) {
        Write-SystemStatusLog "Sorting manifests by priority and dependencies" -Level 'TRACE'
        
        # First sort by priority
        $manifests = $manifests | Sort-Object Priority, Name
        
        # Then sort by dependencies if Get-TopologicalSort is available
        if (Get-Command Get-TopologicalSort -ErrorAction SilentlyContinue) {
            try {
                # Build dependency graph
                $dependencies = @{}
                foreach ($manifest in $manifests) {
                    if ($manifest.Data.DependsOn) {
                        $dependencies[$manifest.Name] = $manifest.Data.DependsOn
                    } else {
                        $dependencies[$manifest.Name] = @()
                    }
                }
                
                # Perform topological sort
                $sortedNames = Get-TopologicalSort -DependencyGraph $dependencies
                
                # Reorder manifests based on sorted names
                $sortedManifests = @()
                foreach ($name in $sortedNames) {
                    $manifest = $manifests | Where-Object { $_.Name -eq $name }
                    if ($manifest) {
                        $sortedManifests += $manifest
                    }
                }
                
                # Add any manifests not in the dependency graph
                foreach ($manifest in $manifests) {
                    if ($manifest.Name -notin $sortedNames) {
                        $sortedManifests += $manifest
                    }
                }
                
                $manifests = $sortedManifests
                Write-SystemStatusLog "Manifests sorted by dependencies" -Level 'DEBUG'
                
            } catch {
                Write-SystemStatusLog "Failed to sort by dependencies: $_" -Level 'WARN'
            }
        }
    }
    
    # Update cache
    $script:ManifestCache = $manifests
    $script:ManifestCacheTime = Get-Date
    
    Write-SystemStatusLog "Manifest discovery complete. Found $($manifests.Count) manifests ($($manifests | Where-Object { $_.IsValid }).Count valid)" -Level 'INFO'
    
    # Return results
    if ($IncludeInvalid) {
        return $manifests
    } else {
        return $manifests | Where-Object { $_.IsValid }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDbPYuen29kj3c9
# H0dQwxgqf+RGn/AxsiTFfKR3l8ScjaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIMLTKu6T4mXkCgLyFSrmCin
# si+aryhrM28wS0xYmnHFMA0GCSqGSIb3DQEBAQUABIIBAETTMegsjxeFadNkPnUU
# VFGV1S2tPNPxg/xf+5TYhefRLp+6e54fHbZNhL3LTO5G08odOMspATkuXyby7H4b
# jeQunjr/JaOAUF8aKtrUewXHARrNfh14MkmaupyTrTK1O3BcPUtDyV0EBBO3W8BS
# BiSVFSoDVxbpPPxnEhoXG9vA0iOT+T2m/2qajQHbfyo0g5fpBxRHUlj+A2PlHqZW
# YWp/v8L18zixjLJ912gwPMz6G7F8Y1QxxdCbuuiMkAR6dJNJji4HeMYbQLYzxWWd
# PXODHESU7U3+01WjxRd1LvknNMTyBkPdYPq1wylwMuc/NYqPHyZ+SU6pLPa7X8Ie
# /vQ=
# SIG # End signature block
