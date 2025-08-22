# Unity-Project-TestMocks.psm1
# Phase 2: Unity Project Mock Infrastructure for Testing
# Mock Unity project registration and availability functions
# Date: 2025-08-21

Write-Host "[DEBUG] [TestMocks] Loading Unity Project Test Mocks module..." -ForegroundColor Gray

# Mock Unity projects registry
$script:MockUnityProjects = @{
    "Unity-Project-1" = @{
        Name = "Unity-Project-1"
        Path = "C:\MockProjects\Unity-Project-1"
        Available = $true
        Status = "Available"
        LastChecked = Get-Date
        Version = "2021.1.14f1"
        ApiCompatibilityLevel = ".NET Standard 2.0"
    }
    "Unity-Project-2" = @{
        Name = "Unity-Project-2"
        Path = "C:\MockProjects\Unity-Project-2"
        Available = $true
        Status = "Available"
        LastChecked = Get-Date
        Version = "2021.1.14f1"
        ApiCompatibilityLevel = ".NET Standard 2.0"
    }
    "Unity-Project-3" = @{
        Name = "Unity-Project-3"
        Path = "C:\MockProjects\Unity-Project-3"
        Available = $true
        Status = "Available"
        LastChecked = Get-Date
        Version = "2021.1.14f1"
        ApiCompatibilityLevel = ".NET Standard 2.0"
    }
}

# Mock function: Test-UnityProjectAvailability
function Test-UnityProjectAvailability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectName,
        [switch]$Detailed
    )
    
    Write-Host "[DEBUG] [TestMocks] Testing availability for mock project: $ProjectName" -ForegroundColor Gray
    
    if ($script:MockUnityProjects.ContainsKey($ProjectName)) {
        $project = $script:MockUnityProjects[$ProjectName]
        Write-Host "[DEBUG] [TestMocks] Mock project found: $ProjectName" -ForegroundColor Green
        
        if ($Detailed) {
            return @{
                Available = $project.Available
                Status = $project.Status
                Details = "Mock Unity project for testing purposes"
                Project = $project
            }
        } else {
            return @{
                Available = $project.Available
                Status = $project.Status
            }
        }
    } else {
        Write-Host "[DEBUG] [TestMocks] Mock project not found: $ProjectName" -ForegroundColor Red
        
        if ($Detailed) {
            return @{
                Available = $false
                Status = "Project not registered"
                Details = "Mock project not found in test registry"
                Project = $null
            }
        } else {
            return @{
                Available = $false
                Status = "Project not registered"
            }
        }
    }
}

# Mock function: Register-UnityProject
function Register-UnityProject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectName,
        [string]$ProjectPath = "C:\MockProjects\$ProjectName",
        [string]$UnityVersion = "2021.1.14f1",
        [switch]$Force
    )
    
    Write-Host "[DEBUG] [TestMocks] Registering mock Unity project: $ProjectName" -ForegroundColor Gray
    
    if ($script:MockUnityProjects.ContainsKey($ProjectName) -and -not $Force) {
        Write-Warning "[TestMocks] Project $ProjectName already registered. Use -Force to overwrite."
        return $false
    }
    
    $script:MockUnityProjects[$ProjectName] = @{
        Name = $ProjectName
        Path = $ProjectPath
        Available = $true
        Status = "Available"
        LastChecked = Get-Date
        Version = $UnityVersion
        ApiCompatibilityLevel = ".NET Standard 2.0"
        Registered = Get-Date
    }
    
    Write-Host "[DEBUG] [TestMocks] Successfully registered mock project: $ProjectName at $ProjectPath" -ForegroundColor Green
    return $true
}

# Mock function: Get-UnityProjectStatus
function Get-UnityProjectStatus {
    [CmdletBinding()]
    param(
        [string]$ProjectName,
        [switch]$All
    )
    
    Write-Host "[DEBUG] [TestMocks] Getting status for mock Unity project(s)" -ForegroundColor Gray
    
    if ($All) {
        return $script:MockUnityProjects.Values | ForEach-Object {
            @{
                Name = $_.Name
                Available = $_.Available
                Status = $_.Status
                Path = $_.Path
                LastChecked = $_.LastChecked
            }
        }
    } elseif ($ProjectName) {
        if ($script:MockUnityProjects.ContainsKey($ProjectName)) {
            $project = $script:MockUnityProjects[$ProjectName]
            return @{
                Name = $project.Name
                Available = $project.Available
                Status = $project.Status
                Path = $project.Path
                LastChecked = $project.LastChecked
            }
        } else {
            return @{
                Name = $ProjectName
                Available = $false
                Status = "Not found"
                Path = $null
                LastChecked = Get-Date
            }
        }
    }
}

# Mock function: Unregister-UnityProject
function Unregister-UnityProject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProjectName
    )
    
    Write-Host "[DEBUG] [TestMocks] Unregistering mock Unity project: $ProjectName" -ForegroundColor Gray
    
    if ($script:MockUnityProjects.ContainsKey($ProjectName)) {
        $script:MockUnityProjects.Remove($ProjectName)
        Write-Host "[DEBUG] [TestMocks] Successfully unregistered mock project: $ProjectName" -ForegroundColor Green
        return $true
    } else {
        Write-Warning "[TestMocks] Project $ProjectName not found in registry"
        return $false
    }
}

# Mock function: Get-RegisteredUnityProjects  
function Get-RegisteredUnityProjects {
    [CmdletBinding()]
    param()
    
    Write-Host "[DEBUG] [TestMocks] Getting all registered mock Unity projects" -ForegroundColor Gray
    
    return $script:MockUnityProjects.Keys | ForEach-Object {
        $project = $script:MockUnityProjects[$_]
        @{
            Name = $project.Name
            Available = $project.Available
            Status = $project.Status
            Path = $project.Path
            Version = $project.Version
        }
    }
}

# Mock function: Initialize-UnityProjectRegistry
function Initialize-UnityProjectRegistry {
    [CmdletBinding()]
    param(
        [switch]$ClearExisting
    )
    
    Write-Host "[DEBUG] [TestMocks] Initializing Unity project mock registry" -ForegroundColor Gray
    
    if ($ClearExisting) {
        $script:MockUnityProjects.Clear()
        Write-Host "[DEBUG] [TestMocks] Cleared existing mock project registry" -ForegroundColor Yellow
    }
    
    # Ensure default test projects are available
    $defaultProjects = @("Unity-Project-1", "Unity-Project-2", "Unity-Project-3")
    foreach ($projectName in $defaultProjects) {
        if (-not $script:MockUnityProjects.ContainsKey($projectName)) {
            Register-UnityProject -ProjectName $projectName -Force
        }
    }
    
    Write-Host "[DEBUG] [TestMocks] Unity project mock registry initialized with $($script:MockUnityProjects.Count) projects" -ForegroundColor Green
    return $true
}

# Auto-initialize registry when module loads
Initialize-UnityProjectRegistry

# Export mock functions (REMOVED conflicting functions to prevent conflicts with UnityParallelization module)
# NOTE: Using only real UnityParallelization module functions for registration and availability testing
Export-ModuleMember -Function @(
    'Get-UnityProjectStatus',
    'Unregister-UnityProject', 
    'Get-RegisteredUnityProjects',
    'Initialize-UnityProjectRegistry'
)

Write-Host "[INFO] [TestMocks] Unity Project Test Mocks module loaded successfully (4 mock functions - conflicts removed)" -ForegroundColor Green