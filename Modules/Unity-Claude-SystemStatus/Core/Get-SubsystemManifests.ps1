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
            # Load the manifest
            $manifestData = Import-PowerShellDataFile -Path $file.FullName
            
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
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUZ+2DLwUlZvRD3Sd4ipG3mXAu
# 3KKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUYrURgyxRIPhgrzd1ovfL+n0GWUMwDQYJKoZIhvcNAQEBBQAEggEAahA2
# x4PMkJFBTIC59LpaPYkqZhvw+ZxhdHpej8L9X8nwKnk73C37sOT9+atBxU0Evdp4
# pLAxzkGg2KLCivvOjAcOo77gSu1sFfgrXQJwksBMCxWbMVIaUFysmC/dJ+LubX+T
# jSlwLd9UQZkpLXtpqzTxTSSSemcICiQyh92QYB3xrbxlpOqOjnXuSH69U0M2GxXo
# q27igYNc2zYdMGpI6mwmV4hDDEh7BYB5fink12S6vqrC1MV9oz9FdJgpGYkWHAI+
# AQ4Q+eqG4c8AK86BmB9DHsKCsKwBCOx2is8nZQdLOBHXc4RRP8qzuiHbH3sVgy94
# Wh3HmAzfOwOwkbS0iQ==
# SIG # End signature block
