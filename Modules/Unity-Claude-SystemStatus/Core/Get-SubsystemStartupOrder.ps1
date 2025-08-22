function Get-SubsystemStartupOrder {
    <#
    .SYNOPSIS
    Creates an optimized startup sequence for subsystems based on manifest dependencies.
    
    .DESCRIPTION
    Analyzes subsystem manifests to build dependency graphs and calculate optimal startup
    order with parallel execution groups. Supports both dependency declarations and
    required module specifications.
    
    .PARAMETER Manifests
    Array of manifest objects from Get-SubsystemManifests.
    
    .PARAMETER EnableParallelExecution
    When enabled, identifies subsystems that can be started concurrently.
    
    .PARAMETER Algorithm
    Choose between 'DFS' or 'Kahn' algorithm for dependency resolution.
    
    .PARAMETER IncludeValidation
    Perform comprehensive validation of manifest dependencies and consistency.
    
    .EXAMPLE
    $manifests = Get-SubsystemManifests
    $startupPlan = Get-SubsystemStartupOrder -Manifests $manifests -EnableParallelExecution
    
    .EXAMPLE
    Get-SubsystemStartupOrder -Manifests $manifests -Algorithm 'Kahn' -IncludeValidation
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [array]$Manifests,
        
        [Parameter()]
        [switch]$EnableParallelExecution,
        
        [Parameter()]
        [ValidateSet('DFS', 'Kahn')]
        [string]$Algorithm = 'Kahn',
        
        [Parameter()]
        [switch]$IncludeValidation
    )
    
    Begin {
        Write-SystemStatusLog "Starting subsystem startup order calculation" -Level 'INFO'
        Write-SystemStatusLog "Algorithm: $Algorithm, Parallel: $EnableParallelExecution, Validation: $IncludeValidation" -Level 'DEBUG'
        
        $allManifests = @()
    }
    
    Process {
        $allManifests += $Manifests
    }
    
    End {
        if ($allManifests.Count -eq 0) {
            Write-SystemStatusLog "No manifests provided for startup order calculation" -Level 'WARN'
            return @{
                StartupOrder = @()
                ParallelGroups = @()
                ValidationResults = @{
                    IsValid = $true
                    Errors = @()
                    Warnings = @()
                }
                ExecutionPlan = @{
                    TotalSubsystems = 0
                    EstimatedStartupTime = 0
                    ParallelCapable = $false
                }
            }
        }
        
        Write-SystemStatusLog "Processing $($allManifests.Count) manifests for startup order" -Level 'INFO'
        
        # Step 1: Validate manifests if requested
        $validationResults = @{
            IsValid = $true
            Errors = @()
            Warnings = @()
        }
        
        if ($IncludeValidation) {
            $validationResults = Validate-ManifestDependencies -Manifests $allManifests
            
            if (-not $validationResults.IsValid) {
                Write-SystemStatusLog "Manifest validation failed: $($validationResults.Errors -join '; ')" -Level 'ERROR'
                return @{
                    StartupOrder = @()
                    ParallelGroups = @()
                    ValidationResults = $validationResults
                    ExecutionPlan = @{
                        TotalSubsystems = 0
                        EstimatedStartupTime = 0
                        ParallelCapable = $false
                    }
                }
            }
        }
        
        # Step 2: Build dependency graph from manifests
        $dependencyGraph = Build-DependencyGraphFromManifests -Manifests $allManifests
        
        Write-SystemStatusLog "Built dependency graph with $($dependencyGraph.Keys.Count) nodes" -Level 'DEBUG'
        foreach ($node in $dependencyGraph.Keys) {
            $deps = if ($dependencyGraph[$node]) { $dependencyGraph[$node] -join ', ' } else { 'none' }
            Write-SystemStatusLog "  $node depends on: $deps" -Level 'TRACE'
        }
        
        # Step 3: Calculate topological order with parallel groups
        try {
            if ($EnableParallelExecution) {
                $sortResult = Get-TopologicalSort -DependencyGraph $dependencyGraph -EnableParallelGroups -Algorithm $Algorithm
                
                $startupOrder = $sortResult.TopologicalOrder
                $parallelGroups = $sortResult.ParallelGroups
                
                Write-SystemStatusLog "Parallel execution enabled: $($parallelGroups.Count) parallel groups identified" -Level 'INFO'
                for ($i = 0; $i -lt $parallelGroups.Count; $i++) {
                    $groupNumber = $i + 1
                    $groupNodes = $parallelGroups[$i] -join ', '
                    Write-SystemStatusLog "  Group ${groupNumber}: $groupNodes" -Level 'DEBUG'
                }
            } else {
                $startupOrder = Get-TopologicalSort -DependencyGraph $dependencyGraph -Algorithm $Algorithm
                $parallelGroups = @()
                
                Write-SystemStatusLog "Sequential execution: $($startupOrder.Count) subsystems in order" -Level 'INFO'
                Write-SystemStatusLog "Startup order: $($startupOrder -join ' -> ')" -Level 'DEBUG'
            }
        }
        catch {
            Write-SystemStatusLog "Error in dependency resolution: $($_.Exception.Message)" -Level 'ERROR'
            $validationResults.IsValid = $false
            $validationResults.Errors += "Dependency resolution failed: $($_.Exception.Message)"
            
            return @{
                StartupOrder = @()
                ParallelGroups = @()
                ValidationResults = $validationResults
                ExecutionPlan = @{
                    TotalSubsystems = 0
                    EstimatedStartupTime = 0
                    ParallelCapable = $false
                }
            }
        }
        
        # Step 4: Create execution plan with timing estimates
        $executionPlan = Build-ExecutionPlan -Manifests $allManifests -StartupOrder $startupOrder -ParallelGroups $parallelGroups
        
        # Step 5: Compile final result
        $result = @{
            StartupOrder = $startupOrder
            ParallelGroups = $parallelGroups
            ValidationResults = $validationResults
            ExecutionPlan = $executionPlan
            DependencyGraph = $dependencyGraph
            Algorithm = $Algorithm
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
        
        Write-SystemStatusLog "Startup order calculation completed successfully" -Level 'INFO'
        Write-SystemStatusLog "Total subsystems: $($executionPlan.TotalSubsystems), Estimated time: $($executionPlan.EstimatedStartupTime)s" -Level 'INFO'
        
        return $result
    }
}

function Build-DependencyGraphFromManifests {
    <#
    .SYNOPSIS
    Builds a dependency graph hashtable from subsystem manifests.
    #>
    [CmdletBinding()]
    param(
        [array]$Manifests
    )
    
    Write-SystemStatusLog "Building dependency graph from $($Manifests.Count) manifests" -Level 'DEBUG'
    
    $dependencyGraph = @{}
    $allSubsystemNames = @()
    
    # First pass: collect all subsystem names and initialize empty dependencies
    foreach ($manifest in $Manifests) {
        $name = $manifest.Name
        $allSubsystemNames += $name
        $dependencyGraph[$name] = @()
        
        Write-SystemStatusLog "Initialized subsystem: $name" -Level 'TRACE'
    }
    
    # Second pass: build dependency relationships
    foreach ($manifest in $Manifests) {
        $name = $manifest.Name
        $dependencies = @()
        
        # Process DependsOn field (direct subsystem dependencies)
        if ($manifest.DependsOn) {
            foreach ($dep in $manifest.DependsOn) {
                if ($dep -and $dep.Trim()) {
                    $dependencies += $dep.Trim()
                    Write-SystemStatusLog "$name depends on subsystem: $dep" -Level 'TRACE'
                }
            }
        }
        
        # Process RequiredModules field (module dependencies)
        if ($manifest.RequiredModules) {
            foreach ($module in $manifest.RequiredModules) {
                if ($module -and $module.Trim()) {
                    # Check if required module corresponds to another subsystem
                    $matchingSubsystem = $allSubsystemNames | Where-Object { $_ -like "*$module*" -or $module -like "*$_*" }
                    if ($matchingSubsystem) {
                        $dependencies += $matchingSubsystem
                        Write-SystemStatusLog "$name depends on module/subsystem: $module -> $matchingSubsystem" -Level 'TRACE'
                    } else {
                        Write-SystemStatusLog "$name requires external module: $module (not managed by orchestrator)" -Level 'DEBUG'
                    }
                }
            }
        }
        
        # Remove duplicates and self-references
        $dependencies = $dependencies | Where-Object { $_ -ne $name } | Sort-Object -Unique
        $dependencyGraph[$name] = $dependencies
        
        if ($dependencies.Count -gt 0) {
            Write-SystemStatusLog "$name final dependencies: $($dependencies -join ', ')" -Level 'DEBUG'
        } else {
            Write-SystemStatusLog "$name has no dependencies (can start immediately)" -Level 'DEBUG'
        }
    }
    
    return $dependencyGraph
}

function Validate-ManifestDependencies {
    <#
    .SYNOPSIS
    Validates manifest dependencies for consistency and completeness.
    #>
    [CmdletBinding()]
    param(
        [array]$Manifests
    )
    
    Write-SystemStatusLog "Validating manifest dependencies" -Level 'DEBUG'
    
    $errors = @()
    $warnings = @()
    $subsystemNames = $Manifests | ForEach-Object { $_.Name }
    
    foreach ($manifest in $Manifests) {
        $name = $manifest.Name
        
        # Validate required fields exist
        if (-not $manifest.Name -or $manifest.Name.Trim() -eq '') {
            $errors += "Manifest missing required Name field"
            continue
        }
        
        if (-not $manifest.Version) {
            $warnings += "Manifest $name missing Version field"
        }
        
        # Validate DependsOn references
        if ($manifest.DependsOn) {
            foreach ($dependency in $manifest.DependsOn) {
                if ($dependency -and $dependency.Trim()) {
                    $depName = $dependency.Trim()
                    
                    # Check if dependency exists
                    if ($depName -notin $subsystemNames) {
                        $errors += "Subsystem $name depends on '$depName' which is not defined in any manifest"
                    }
                    
                    # Check for self-reference
                    if ($depName -eq $name) {
                        $errors += "Subsystem $name cannot depend on itself"
                    }
                }
            }
        }
        
        # Validate manifest-specific fields
        if ($manifest.StartScript -and -not (Test-Path (Join-Path (Split-Path $manifest._ManifestPath -Parent) $manifest.StartScript))) {
            $warnings += "Subsystem $name StartScript '$($manifest.StartScript)' not found"
        }
        
        # Validate restart policy
        if ($manifest.RestartPolicy -and $manifest.RestartPolicy -notin @('OnFailure', 'Always', 'Never')) {
            $errors += "Subsystem $name has invalid RestartPolicy '$($manifest.RestartPolicy)'"
        }
        
        # Validate resource limits
        if ($manifest.MaxMemoryMB -and ($manifest.MaxMemoryMB -lt 0 -or $manifest.MaxMemoryMB -gt 32768)) {
            $warnings += "Subsystem $name MaxMemoryMB value '$($manifest.MaxMemoryMB)' may be unrealistic"
        }
        
        if ($manifest.MaxCpuPercent -and ($manifest.MaxCpuPercent -lt 0 -or $manifest.MaxCpuPercent -gt 100)) {
            $errors += "Subsystem $name MaxCpuPercent value '$($manifest.MaxCpuPercent)' is invalid (must be 0-100)"
        }
    }
    
    # Check for duplicate names
    $duplicateNames = $subsystemNames | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name }
    foreach ($duplicate in $duplicateNames) {
        $errors += "Duplicate subsystem name: $duplicate"
    }
    
    $isValid = $errors.Count -eq 0
    
    Write-SystemStatusLog "Validation completed: $($errors.Count) errors, $($warnings.Count) warnings" -Level 'DEBUG'
    
    return @{
        IsValid = $isValid
        Errors = $errors
        Warnings = $warnings
    }
}

function Build-ExecutionPlan {
    <#
    .SYNOPSIS
    Creates detailed execution plan with timing estimates and resource requirements.
    #>
    [CmdletBinding()]
    param(
        [array]$Manifests,
        [array]$StartupOrder,
        [array]$ParallelGroups
    )
    
    Write-SystemStatusLog "Building execution plan" -Level 'DEBUG'
    
    # Create lookup table for manifest data
    $manifestLookup = @{}
    foreach ($manifest in $Manifests) {
        $manifestLookup[$manifest.Name] = $manifest
    }
    
    # Estimate startup times (simplified model)
    $baseStartupTime = 2  # seconds per subsystem
    $parallelOverhead = 0.5  # additional overhead for parallel execution
    
    $estimatedTime = 0
    $parallelCapable = $ParallelGroups.Count -gt 0
    
    if ($parallelCapable) {
        # Parallel execution: time = max(group_time) for each group
        foreach ($group in $ParallelGroups) {
            $groupTime = $baseStartupTime + $parallelOverhead
            $estimatedTime += $groupTime
        }
    } else {
        # Sequential execution: time = sum of all startup times
        $estimatedTime = $StartupOrder.Count * $baseStartupTime
    }
    
    # Calculate resource requirements
    $totalMemoryMB = 0
    $maxCpuPercent = 0
    
    foreach ($name in $StartupOrder) {
        if ($manifestLookup.ContainsKey($name)) {
            $manifest = $manifestLookup[$name]
            if ($manifest.MaxMemoryMB) {
                $totalMemoryMB += $manifest.MaxMemoryMB
            }
            if ($manifest.MaxCpuPercent) {
                $maxCpuPercent = [Math]::Max($maxCpuPercent, $manifest.MaxCpuPercent)
            }
        }
    }
    
    $executionPlan = @{
        TotalSubsystems = $StartupOrder.Count
        EstimatedStartupTime = [Math]::Round($estimatedTime, 1)
        ParallelCapable = $parallelCapable
        ParallelGroups = $ParallelGroups.Count
        ResourceRequirements = @{
            TotalMemoryMB = $totalMemoryMB
            MaxCpuPercent = $maxCpuPercent
        }
        StartupSequence = @()
    }
    
    # Build detailed startup sequence
    if ($parallelCapable) {
        $step = 1
        foreach ($group in $ParallelGroups) {
            $executionPlan.StartupSequence += @{
                Step = $step
                Type = if ($group.Count -gt 1) { 'Parallel' } else { 'Sequential' }
                Subsystems = $group
                EstimatedDuration = $baseStartupTime + $parallelOverhead
            }
            $step++
        }
    } else {
        for ($i = 0; $i -lt $StartupOrder.Count; $i++) {
            $executionPlan.StartupSequence += @{
                Step = $i + 1
                Type = 'Sequential'
                Subsystems = @($StartupOrder[$i])
                EstimatedDuration = $baseStartupTime
            }
        }
    }
    
    Write-SystemStatusLog "Execution plan: $($executionPlan.TotalSubsystems) subsystems, $($executionPlan.EstimatedStartupTime)s, parallel: $($executionPlan.ParallelCapable)" -Level 'INFO'
    
    return $executionPlan
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUtA+G5yrcrktTorFFgTJQJmdB
# UrWgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUPlMdy++ZEjQLoCmuHnoY7p8I86EwDQYJKoZIhvcNAQEBBQAEggEAGmQr
# iDGzlZF1u8N/HD7OxfUga4Etzk9X03gurIcFdzimVlUd3X61dB+yFGo2NE/suMsE
# /xnDPV/6+uls1fgWNVOfl5N5E7k0yeLyTtKDjPK7PQZ7l84APWi51y+2TBfBVFm3
# SFQKUkU5FECFCUAAbx9VP7l25pqyUwSkmJ9ZSbVxq+scJU/UWKPiQMvmsNfMh6IU
# jUmQ2kX7Avx3Ja8BnkXRwohrDzz7HmC162ETPXfVDRfrZqGlLByOuSiEG0ULJysp
# +zzK8x/9Ri8HA9difDb4J1TW7Um5rXts4O8x2UiP9IOmYFAnzd2oHgcP0BnRdgbq
# QOrExs5Maxch1pCZTA==
# SIG # End signature block
