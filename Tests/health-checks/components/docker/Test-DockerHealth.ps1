# Unity-Claude-Automation Docker Health Check Component
# Tests Docker services and containers
# Version: 2025-08-25

[CmdletBinding()]
param(
    [ValidateSet('Quick', 'Full', 'Critical', 'Performance')]
    [string]$TestType = 'Quick',
    
    [switch]$Detailed
)

# Import shared utilities
Import-Module "$PSScriptRoot\..\..\shared\Test-HealthUtilities.psm1" -Force

function Test-DockerDaemon {
    <#
    .SYNOPSIS
    Test if Docker daemon is running and accessible
    #>
    
    Write-TestLog "Testing Docker daemon..." -Level Info
    
    try {
        $dockerInfo = docker info --format "{{.ServerVersion}}" 2>$null
        if ($dockerInfo) {
            Add-TestResult -TestName "Docker Daemon" -Status 'Pass' -Details "Docker version: $dockerInfo" -Metrics @{
                Version = $dockerInfo
            }
            return $true
        } else {
            Add-TestResult -TestName "Docker Daemon" -Status 'Fail' -Details "Docker daemon not running"
            return $false
        }
    } catch {
        Add-TestResult -TestName "Docker Daemon" -Status 'Fail' -Details "Docker not accessible: $($_.Exception.Message)"
        return $false
    }
}

function Test-DockerContainers {
    <#
    .SYNOPSIS
    Test running Docker containers
    #>
    
    Write-TestLog "Testing Docker containers..." -Level Info
    
    try {
        $containers = docker ps --format "{{.Names}};{{.Status}};{{.Image}}" 2>$null
        
        if ($containers) {
            $containerList = $containers | ForEach-Object {
                $parts = $_ -split ';'
                @{
                    Name = $parts[0]
                    Status = $parts[1]
                    Image = $parts[2]
                }
            }
            
            $runningCount = $containerList.Count
            $healthyCount = ($containerList | Where-Object { $_.Status -like "*Up*" }).Count
            
            Add-TestResult -TestName "Docker Containers" -Status 'Pass' -Details "$healthyCount/$runningCount containers running" -Metrics @{
                Total = $runningCount
                Healthy = $healthyCount
                Containers = $containerList
            }
            
            # Test individual container health
            foreach ($container in $containerList) {
                Test-ContainerHealth -Name $container.Name -Status $container.Status -Image $container.Image
            }
            
        } else {
            Add-TestResult -TestName "Docker Containers" -Status 'Warning' -Details "No containers running"
        }
    } catch {
        Add-TestResult -TestName "Docker Containers" -Status 'Fail' -Details "Cannot check container status: $($_.Exception.Message)"
    }
}

function Test-ContainerHealth {
    <#
    .SYNOPSIS
    Test individual container health
    
    .PARAMETER Name
    Container name
    
    .PARAMETER Status
    Container status
    
    .PARAMETER Image
    Container image
    #>
    param(
        [string]$Name,
        [string]$Status,
        [string]$Image
    )
    
    $testName = "Container: $Name"
    
    try {
        # Check if container is running
        if ($Status -like "*Up*") {
            # For detailed tests, check container logs for errors
            if ($Detailed -and $TestType -in @('Full', 'Critical')) {
                $logs = docker logs $Name --tail 10 2>$null
                $errorLines = $logs | Where-Object { $_ -match "(error|fail|exception)" -and $_ -notmatch "(debug|trace)" }
                
                if ($errorLines) {
                    Add-TestResult -TestName $testName -Status 'Warning' -Details "$Status - Recent errors in logs" -Metrics @{
                        Image = $Image
                        ErrorCount = $errorLines.Count
                        RecentErrors = $errorLines | Select-Object -First 3
                    }
                } else {
                    Add-TestResult -TestName $testName -Status 'Pass' -Details $Status -Metrics @{
                        Image = $Image
                    }
                }
            } else {
                Add-TestResult -TestName $testName -Status 'Pass' -Details $Status -Metrics @{
                    Image = $Image
                }
            }
        } else {
            # Container not running - determine severity
            if ($Name -match "(monitor|health|alert)" -and $TestType -in @('Critical', 'Full')) {
                Add-TestResult -TestName $testName -Status 'Fail' -Details $Status
            } else {
                Add-TestResult -TestName $testName -Status 'Fail' -Details $Status
            }
        }
        
    } catch {
        Add-TestResult -TestName $testName -Status 'Fail' -Details "Cannot inspect container: $($_.Exception.Message)"
    }
}

function Test-DockerNetworks {
    <#
    .SYNOPSIS
    Test Docker networks (for Full/Performance tests)
    #>
    
    if ($TestType -notin @('Full', 'Performance')) {
        return
    }
    
    Write-TestLog "Testing Docker networks..." -Level Info
    
    try {
        $networks = docker network ls --format "{{.Name}};{{.Driver}};{{.Scope}}" 2>$null
        
        if ($networks) {
            $networkList = $networks | ForEach-Object {
                $parts = $_ -split ';'
                @{
                    Name = $parts[0]
                    Driver = $parts[1]
                    Scope = $parts[2]
                }
            }
            
            $customNetworks = $networkList | Where-Object { $_.Name -notmatch "^(bridge|host|none)$" }
            
            Add-TestResult -TestName "Docker Networks" -Status 'Pass' -Details "$($customNetworks.Count) custom networks found" -Metrics @{
                TotalNetworks = $networkList.Count
                CustomNetworks = $customNetworks.Count
                Networks = $networkList
            }
            
        } else {
            Add-TestResult -TestName "Docker Networks" -Status 'Warning' -Details "No networks found"
        }
        
    } catch {
        Add-TestResult -TestName "Docker Networks" -Status 'Fail' -Details "Cannot list networks: $($_.Exception.Message)"
    }
}

function Test-DockerVolumes {
    <#
    .SYNOPSIS
    Test Docker volumes (for Full/Performance tests)
    #>
    
    if ($TestType -notin @('Full', 'Performance')) {
        return
    }
    
    Write-TestLog "Testing Docker volumes..." -Level Info
    
    try {
        $volumes = docker volume ls --format "{{.Name}};{{.Driver}}" 2>$null
        
        if ($volumes) {
            $volumeCount = ($volumes | Measure-Object).Count
            
            Add-TestResult -TestName "Docker Volumes" -Status 'Pass' -Details "$volumeCount volumes found" -Metrics @{
                VolumeCount = $volumeCount
            }
            
        } else {
            Add-TestResult -TestName "Docker Volumes" -Status 'Warning' -Details "No volumes found"
        }
        
    } catch {
        Add-TestResult -TestName "Docker Volumes" -Status 'Fail' -Details "Cannot list volumes: $($_.Exception.Message)"
    }
}

function Test-DockerResources {
    <#
    .SYNOPSIS
    Test Docker resource usage (for Performance tests)
    #>
    
    if ($TestType -ne 'Performance') {
        return
    }
    
    Write-TestLog "Testing Docker resource usage..." -Level Info
    
    try {
        # Get Docker system info
        $systemInfo = docker system df --format "table {{.Type}}\t{{.TotalCount}}\t{{.Size}}\t{{.Reclaimable}}" 2>$null
        
        if ($systemInfo) {
            $lines = $systemInfo -split "`n" | Select-Object -Skip 1 # Skip header
            $diskUsage = @{}
            
            foreach ($line in $lines) {
                if ($line -match "^(\w+)\s+(\d+)\s+([\d.]+\w+)\s+([\d.]+\w+)") {
                    $diskUsage[$matches[1]] = @{
                        Count = [int]$matches[2]
                        Size = $matches[3]
                        Reclaimable = $matches[4]
                    }
                }
            }
            
            Add-TestResult -TestName "Docker Resources" -Status 'Pass' -Details "Resource usage analyzed" -Metrics $diskUsage
        } else {
            Add-TestResult -TestName "Docker Resources" -Status 'Warning' -Details "Cannot get resource usage"
        }
        
    } catch {
        Add-TestResult -TestName "Docker Resources" -Status 'Fail' -Details "Cannot analyze resources: $($_.Exception.Message)"
    }
}

# Main execution function
function Invoke-DockerHealthCheck {
    <#
    .SYNOPSIS
    Execute Docker health checks based on test type
    #>
    
    Write-TestLog "Starting Docker health checks (Type: $TestType)" -Level Info
    
    # Core tests - always run
    $daemonHealthy = Test-DockerDaemon
    
    if ($daemonHealthy) {
        Test-DockerContainers
        
        # Extended tests based on type
        if ($TestType -in @('Full', 'Performance')) {
            Test-DockerNetworks
            Test-DockerVolumes
        }
        
        if ($TestType -eq 'Performance') {
            Test-DockerResources
        }
    } else {
        Write-TestLog "Skipping Docker container tests - daemon not healthy" -Level Warning
    }
    
    Write-TestLog "Docker health checks completed" -Level Info
}

# Execute if run directly
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-DockerHealthCheck
}

# Export functions for module use
Export-ModuleMember -Function @(
    'Invoke-DockerHealthCheck',
    'Test-DockerDaemon',
    'Test-DockerContainers',
    'Test-ContainerHealth',
    'Test-DockerNetworks',
    'Test-DockerVolumes',
    'Test-DockerResources'
)