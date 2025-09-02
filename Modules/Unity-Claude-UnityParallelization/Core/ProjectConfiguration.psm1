#Requires -Version 5.1
<#
.SYNOPSIS
    Unity project discovery and configuration management for UnityParallelization module.

.DESCRIPTION
    Provides Unity project discovery, registration, and configuration management
    for parallel monitoring operations.

.NOTES
    Part of Unity-Claude-UnityParallelization refactored architecture
    Originally from Unity-Claude-UnityParallelization.psm1 (lines 120-461)
    Refactoring Date: 2025-08-25
#>

# Import shared logging module
Import-Module "$PSScriptRoot\ParallelizationCore.psm1" -Force

#region Unity Project Discovery and Configuration

function Find-UnityProjects {
    <#
    .SYNOPSIS
    Discovers Unity projects in specified directories
    .DESCRIPTION
    Searches for Unity projects by looking for ProjectSettings/ProjectVersion.txt files
    .PARAMETER SearchPaths
    Array of directories to search for Unity projects
    .PARAMETER Recursive
    Search recursively through subdirectories
    .PARAMETER IncludeVersion
    Include Unity version information for each project
    .EXAMPLE
    $projects = Find-UnityProjects -SearchPaths @("C:\UnityProjects") -Recursive
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$SearchPaths,
        [switch]$Recursive,
        [switch]$IncludeVersion
    )
    
    Write-UnityParallelLog -Message "Discovering Unity projects in search paths..." -Level "INFO"
    
    try {
        $discoveredProjects = @()
        
        foreach ($searchPath in $SearchPaths) {
            if (-not (Test-Path $searchPath)) {
                Write-UnityParallelLog -Message "Search path not found: $searchPath" -Level "WARNING"
                continue
            }
            
            Write-UnityParallelLog -Message "Searching for Unity projects in: $searchPath" -Level "DEBUG"
            
            # Look for ProjectSettings/ProjectVersion.txt files
            $searchPattern = if ($Recursive) { 
                "$searchPath\*\ProjectSettings\ProjectVersion.txt" 
            } else { 
                "$searchPath\ProjectSettings\ProjectVersion.txt" 
            }
            
            $projectVersionFiles = Get-ChildItem -Path $searchPattern -ErrorAction SilentlyContinue
            
            foreach ($versionFile in $projectVersionFiles) {
                $projectPath = Split-Path (Split-Path $versionFile.FullName -Parent) -Parent
                $projectName = Split-Path $projectPath -Leaf
                
                $projectInfo = @{
                    Name = $projectName
                    Path = $projectPath
                    ProjectSettingsPath = Split-Path $versionFile.FullName -Parent
                    VersionFile = $versionFile.FullName
                    DiscoveredTime = Get-Date
                }
                
                # Include version information if requested
                if ($IncludeVersion) {
                    try {
                        $versionContent = Get-Content $versionFile.FullName
                        $versionLine = $versionContent | Where-Object { $_ -like "m_EditorVersion:*" }
                        if ($versionLine) {
                            $projectInfo.UnityVersion = $versionLine.Split(':')[1].Trim()
                        }
                    } catch {
                        Write-UnityParallelLog -Message "Could not read version from $($versionFile.FullName): $($_.Exception.Message)" -Level "WARNING"
                    }
                }
                
                $discoveredProjects += $projectInfo
                Write-UnityParallelLog -Message "Discovered Unity project: $projectName at $projectPath" -Level "DEBUG"
            }
        }
        
        Write-UnityParallelLog -Message "Unity project discovery completed: $($discoveredProjects.Count) projects found" -Level "INFO"
        
        return $discoveredProjects
        
    } catch {
        Write-UnityParallelLog -Message "Failed to discover Unity projects: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Register-UnityProject {
    <#
    .SYNOPSIS
    Registers a Unity project for parallel monitoring
    .DESCRIPTION
    Registers Unity project with configuration for parallel compilation monitoring
    .PARAMETER ProjectPath
    Path to the Unity project root directory
    .PARAMETER ProjectName
    Optional custom name for the project
    .PARAMETER MonitoringEnabled
    Enable compilation monitoring for this project
    .PARAMETER LogPath
    Custom log file path for Unity Editor.log monitoring
    .EXAMPLE
    Register-UnityProject -ProjectPath "C:\UnityProjects\MyGame" -MonitoringEnabled
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectPath,
        [string]$ProjectName = "",
        [switch]$MonitoringEnabled,
        [string]$LogPath = ""
    )
    
    Write-UnityParallelLog -Message "Registering Unity project for parallel monitoring..." -Level "INFO"
    
    try {
        # Validate project path
        if (-not (Test-Path $ProjectPath)) {
            throw "Unity project path not found: $ProjectPath"
        }
        
        # Validate Unity project structure
        $projectSettingsPath = Join-Path $ProjectPath "ProjectSettings"
        $projectVersionFile = Join-Path $projectSettingsPath "ProjectVersion.txt"
        
        if (-not (Test-Path $projectVersionFile)) {
            throw "Not a valid Unity project: ProjectVersion.txt not found in $projectSettingsPath"
        }
        
        # Generate project name if not provided
        if ([string]::IsNullOrEmpty($ProjectName)) {
            $ProjectName = Split-Path $ProjectPath -Leaf
        }
        
        # Determine log path
        if ([string]::IsNullOrEmpty($LogPath)) {
            $LogPath = "$($script:UnityParallelizationConfig.DefaultLogPath)\Editor.log"
        }
        
        # Create project configuration
        $projectConfig = @{
            Name = $ProjectName
            Path = $ProjectPath
            ProjectSettingsPath = $projectSettingsPath
            LogPath = $LogPath
            MonitoringEnabled = $MonitoringEnabled
            RegisteredTime = Get-Date
            Status = "Registered"
            
            # Monitoring configuration
            MonitoringConfig = @{
                FileSystemWatcher = $null
                LogMonitoring = $false
                ErrorDetection = $false
                CompilationTracking = $false
                LastActivity = $null
            }
            
            # Statistics tracking
            Statistics = @{
                CompilationsDetected = 0
                ErrorsFound = 0
                ErrorsExported = 0
                LastCompilation = $null
                AverageCompilationTime = 0
            }
        }
        
        # Register project
        $script:RegisteredUnityProjects[$ProjectName] = $projectConfig
        
        Write-UnityParallelLog -Message "Unity project registered successfully: $ProjectName at $ProjectPath" -Level "INFO"
        
        return $projectConfig
        
    } catch {
        Write-UnityParallelLog -Message "Failed to register Unity project '$ProjectName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Get-UnityProjectConfiguration {
    <#
    .SYNOPSIS
    Gets configuration for a registered Unity project
    .DESCRIPTION
    Retrieves the configuration and status of a registered Unity project
    .PARAMETER ProjectName
    Name of the registered Unity project
    .EXAMPLE
    $config = Get-UnityProjectConfiguration -ProjectName "MyGame"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectName
    )
    
    try {
        if (-not $script:RegisteredUnityProjects.ContainsKey($ProjectName)) {
            throw "Unity project not registered: $ProjectName"
        }
        
        $projectConfig = $script:RegisteredUnityProjects[$ProjectName]
        
        Write-UnityParallelLog -Message "Retrieved configuration for Unity project: $ProjectName" -Level "DEBUG"
        
        return $projectConfig
        
    } catch {
        Write-UnityParallelLog -Message "Failed to get Unity project configuration '$ProjectName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Get-RegisteredUnityProjects {
    <#
    .SYNOPSIS
    Gets all registered Unity projects
    .DESCRIPTION
    Returns a hashtable of all registered Unity projects with their configurations
    .EXAMPLE
    $projects = Get-RegisteredUnityProjects
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-UnityParallelLog -Message "Getting all registered Unity projects..." -Level "DEBUG"
        return $script:RegisteredUnityProjects
    } catch {
        Write-UnityParallelLog -Message "Failed to get registered Unity projects: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Set-UnityProjectConfiguration {
    <#
    .SYNOPSIS
    Sets configuration for a registered Unity project  
    .DESCRIPTION
    Updates configuration settings for a registered Unity project
    .PARAMETER ProjectName
    Name of the registered Unity project
    .PARAMETER Configuration
    Hashtable containing configuration updates
    .EXAMPLE
    Set-UnityProjectConfiguration -ProjectName "MyGame" -Configuration @{MonitoringEnabled=$true}
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectName,
        [Parameter(Mandatory)]
        [hashtable]$Configuration
    )
    
    Write-UnityParallelLog -Message "Updating Unity project configuration: $ProjectName" -Level "INFO"
    
    try {
        if (-not $script:RegisteredUnityProjects.ContainsKey($ProjectName)) {
            throw "Unity project not registered: $ProjectName"
        }
        
        $projectConfig = $script:RegisteredUnityProjects[$ProjectName]
        
        # Update configuration settings
        foreach ($key in $Configuration.Keys) {
            if ($projectConfig.ContainsKey($key)) {
                $oldValue = $projectConfig[$key]
                $projectConfig[$key] = $Configuration[$key]
                Write-UnityParallelLog -Message "Updated $key from $oldValue to $($Configuration[$key])" -Level "DEBUG"
            } else {
                Write-UnityParallelLog -Message "Unknown configuration key: $key" -Level "WARNING"
            }
        }
        
        Write-UnityParallelLog -Message "Unity project configuration updated successfully: $ProjectName" -Level "INFO"
        
        return $projectConfig
        
    } catch {
        Write-UnityParallelLog -Message "Failed to set Unity project configuration '$ProjectName': $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

function Test-UnityProjectAvailability {
    <#
    .SYNOPSIS
    Tests Unity project availability for parallel monitoring
    .DESCRIPTION
    Validates that Unity project is available and ready for parallel monitoring
    .PARAMETER ProjectName
    Name of the registered Unity project
    .EXAMPLE
    Test-UnityProjectAvailability -ProjectName "MyGame"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectName
    )
    
    try {
        if (-not $script:RegisteredUnityProjects.ContainsKey($ProjectName)) {
            return @{Available = $false; Reason = "Project not registered"}
        }
        
        $projectConfig = $script:RegisteredUnityProjects[$ProjectName]
        $availability = @{
            Available = $true
            ProjectPath = $projectConfig.Path
            ProjectExists = Test-Path $projectConfig.Path
            ProjectSettingsExists = Test-Path $projectConfig.ProjectSettingsPath
            LogPathAccessible = Test-Path (Split-Path $projectConfig.LogPath -Parent)
            Reason = ""
        }
        
        # Check project availability
        if (-not $availability.ProjectExists) {
            $availability.Available = $false
            $availability.Reason = "Project path not found: $($projectConfig.Path)"
        } elseif (-not $availability.ProjectSettingsExists) {
            $availability.Available = $false
            $availability.Reason = "ProjectSettings not found: $($projectConfig.ProjectSettingsPath)"
        } elseif (-not $availability.LogPathAccessible) {
            $availability.Available = $false
            $availability.Reason = "Log path not accessible: $($projectConfig.LogPath)"
        }
        
        Write-UnityParallelLog -Message "Unity project availability check: $ProjectName - Available: $($availability.Available)" -Level "DEBUG"
        
        return $availability
        
    } catch {
        Write-UnityParallelLog -Message "Failed to test Unity project availability '$ProjectName': $($_.Exception.Message)" -Level "ERROR"
        return @{Available = $false; Reason = "Error: $($_.Exception.Message)"}
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Find-UnityProjects',
    'Register-UnityProject',
    'Get-UnityProjectConfiguration',
    'Get-RegisteredUnityProjects',
    'Set-UnityProjectConfiguration',
    'Test-UnityProjectAvailability'
)

#endregion

# REFACTORING MARKER: This module was refactored from Unity-Claude-UnityParallelization.psm1 on 2025-08-25
# Original file size: 2084 lines
# This component: Unity project discovery and configuration (lines 120-461, ~342 lines)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAPoX4YpfAwWVcY
# ZQw1cW1fE3BfP9jvhaIuUpE060iEgKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAvfF/rOMgpAv9WOGAhUpo2e
# IupFc4mn8Ej/XDYAvo+PMA0GCSqGSIb3DQEBAQUABIIBACPoUjOP4A9PqZ+zyS3x
# SDoy/IZTuEzCitrsZLSceOOI5Ow1YlcrMBPanmwICWPRU+qAVKUUsFjUzi77svR5
# LCKXdexef6ayEQXdOTfVbxKQLAjg2Di3mhFvB+cSprUpT36sC2DdrikiWS7baAHu
# gXDmO/rXLVJAgT5RIBjkq5fJpPcdwE/hZNOX/SbkyvmAUWZLeXjlQyJUDgLl/9JK
# WtT+rlMG7jvRhJQ7kEOB5+RmaCNt6NBnx+Eq75NG/brmTqWUvXC3dtPzQRfBbny6
# pbqh15xKXad7bWGJpqpJgdI1MhC/jOhMkTZ2gfXgihwLWFypCZlpKMh+npgcfx4R
# 4ug=
# SIG # End signature block
