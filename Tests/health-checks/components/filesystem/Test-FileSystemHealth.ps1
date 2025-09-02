# Unity-Claude-Automation Filesystem Health Check Component
# Tests filesystem health, disk space, and directory structure
# Version: 2025-08-25

[CmdletBinding()]
param(
    [ValidateSet('Quick', 'Full', 'Critical', 'Performance')]
    [string]$TestType = 'Quick',
    
    [switch]$Detailed
)

# Import shared utilities
Import-Module "$PSScriptRoot\..\..\shared\Test-HealthUtilities.psm1" -Force

function Get-DirectoryStructure {
    <#
    .SYNOPSIS
    Get expected directory structure for testing
    #>
    
    return @(
        @{ Path = '.\Modules'; Critical = $true; Name = "Modules Directory" },
        @{ Path = '.\docs'; Critical = $false; Name = "Documentation Directory" },
        @{ Path = '.\scripts'; Critical = $false; Name = "Scripts Directory" },
        @{ Path = '.\agents'; Critical = $false; Name = "Agents Directory" },
        @{ Path = '.\docker'; Critical = $true; Name = "Docker Directory" },
        @{ Path = '.\tests'; Critical = $false; Name = "Tests Directory" },
        @{ Path = '.\health-reports'; Critical = $false; Name = "Health Reports Directory" },
        @{ Path = '.\logs'; Critical = $false; Name = "Logs Directory" },
        @{ Path = '.\web'; Critical = $false; Name = "Web Directory" }
    )
}

function Test-DirectoryStructure {
    <#
    .SYNOPSIS
    Test critical directory structure
    #>
    
    Write-TestLog "Testing directory structure..." -Level Info
    
    $directories = Get-DirectoryStructure
    
    foreach ($dir in $directories) {
        $testName = "Directory: $($dir.Name)"
        
        try {
            if (Test-Path $dir.Path) {
                $itemCount = @(Get-ChildItem $dir.Path -ErrorAction SilentlyContinue).Count
                $size = 0
                
                if ($Detailed -and $TestType -in @('Full', 'Performance')) {
                    try {
                        $size = (Get-ChildItem $dir.Path -Recurse -File -ErrorAction SilentlyContinue | 
                               Measure-Object -Property Length -Sum).Sum
                    } catch {
                        # Size calculation failed, continue without it
                    }
                }
                
                $metrics = @{
                    Path = (Resolve-Path $dir.Path -ErrorAction SilentlyContinue).Path
                    ItemCount = $itemCount
                    Critical = $dir.Critical
                }
                
                if ($size -gt 0) {
                    $metrics.SizeBytes = $size
                    $metrics.SizeMB = [math]::Round($size / 1MB, 2)
                }
                
                $details = "$itemCount items"
                if ($size -gt 0) {
                    $details += " ($([math]::Round($size / 1MB, 1))MB)"
                }
                
                Add-TestResult -TestName $testName -Status 'Pass' -Details $details -Metrics $metrics
                
            } else {
                $status = if ($dir.Critical) { 'Fail' } else { 'Warning' }
                Add-TestResult -TestName $testName -Status $status -Details "Directory not found"
            }
            
        } catch {
            $status = if ($dir.Critical) { 'Fail' } else { 'Warning' }
            Add-TestResult -TestName $testName -Status $status -Details "Error accessing directory: $($_.Exception.Message)"
        }
    }
}

function Test-DiskSpace {
    <#
    .SYNOPSIS
    Test available disk space
    #>
    
    Write-TestLog "Testing disk space..." -Level Info
    
    try {
        # Test primary drive (C:)
        $diskSpace = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
        
        if ($diskSpace) {
            $freeSpaceGB = [math]::Round($diskSpace.FreeSpace / 1GB, 2)
            $totalSpaceGB = [math]::Round($diskSpace.Size / 1GB, 2)
            $usedPercentage = [math]::Round((($totalSpaceGB - $freeSpaceGB) / $totalSpaceGB) * 100, 1)
            
            $metrics = @{
                FreeSpaceGB = $freeSpaceGB
                TotalSpaceGB = $totalSpaceGB
                UsedPercentage = $usedPercentage
                FreeSpaceBytes = $diskSpace.FreeSpace
                DriveType = $diskSpace.DriveType
            }
            
            if ($freeSpaceGB -lt 5) {
                Add-TestResult -TestName "Disk Space" -Status 'Fail' -Details "Only ${freeSpaceGB}GB free (${usedPercentage}% used)" -Metrics $metrics
            } elseif ($freeSpaceGB -lt 10) {
                Add-TestResult -TestName "Disk Space" -Status 'Warning' -Details "${freeSpaceGB}GB free (${usedPercentage}% used)" -Metrics $metrics
            } else {
                Add-TestResult -TestName "Disk Space" -Status 'Pass' -Details "${freeSpaceGB}GB free (${usedPercentage}% used)" -Metrics $metrics
            }
        } else {
            Add-TestResult -TestName "Disk Space" -Status 'Fail' -Details "Cannot access C: drive"
        }
        
    } catch {
        Add-TestResult -TestName "Disk Space" -Status 'Fail' -Details "Error checking disk space: $($_.Exception.Message)"
    }
}

function Test-FilePermissions {
    <#
    .SYNOPSIS
    Test file system permissions for critical directories
    #>
    
    if ($TestType -notin @('Full', 'Critical')) {
        return
    }
    
    Write-TestLog "Testing file permissions..." -Level Info
    
    $criticalPaths = @(
        @{ Path = '.\Modules'; Name = "Modules" },
        @{ Path = '.\docker'; Name = "Docker" },
        @{ Path = '.'; Name = "Root" }
    )
    
    foreach ($pathInfo in $criticalPaths) {
        $testName = "File Permissions: $($pathInfo.Name)"
        
        try {
            if (Test-Path $pathInfo.Path) {
                # Test read access
                $items = Get-ChildItem $pathInfo.Path -ErrorAction Stop | Select-Object -First 1
                
                # Test write access by trying to create a temp file
                $tempFile = Join-Path $pathInfo.Path ".temp_permission_test"
                try {
                    "test" | Out-File $tempFile -ErrorAction Stop
                    Remove-Item $tempFile -ErrorAction SilentlyContinue
                    
                    Add-TestResult -TestName $testName -Status 'Pass' -Details "Read/Write access confirmed"
                } catch {
                    Add-TestResult -TestName $testName -Status 'Warning' -Details "Read access only"
                }
            } else {
                Add-TestResult -TestName $testName -Status 'Warning' -Details "Path not found"
            }
            
        } catch {
            Add-TestResult -TestName $testName -Status 'Fail' -Details "Permission error: $($_.Exception.Message)"
        }
    }
}

function Test-FileSystemIntegrity {
    <#
    .SYNOPSIS
    Test filesystem integrity and critical files
    #>
    
    if ($TestType -ne 'Critical') {
        return
    }
    
    Write-TestLog "Testing filesystem integrity..." -Level Info
    
    # Test critical configuration files
    $criticalFiles = @(
        @{ Path = '.\docker-compose.yml'; Name = "Docker Compose" },
        @{ Path = '.\docker-compose.monitoring.yml'; Name = "Monitoring Compose" },
        @{ Path = '.\mkdocs.yml'; Name = "MkDocs Config" },
        @{ Path = '.\CLAUDE.md'; Name = "Claude Config" }
    )
    
    foreach ($fileInfo in $criticalFiles) {
        $testName = "Critical File: $($fileInfo.Name)"
        
        try {
            if (Test-Path $fileInfo.Path) {
                $fileSize = (Get-Item $fileInfo.Path).Length
                $lastModified = (Get-Item $fileInfo.Path).LastWriteTime
                
                $metrics = @{
                    Path = $fileInfo.Path
                    SizeBytes = $fileSize
                    LastModified = $lastModified.ToString('yyyy-MM-dd HH:mm:ss')
                }
                
                if ($fileSize -gt 0) {
                    Add-TestResult -TestName $testName -Status 'Pass' -Details "$fileSize bytes" -Metrics $metrics
                } else {
                    Add-TestResult -TestName $testName -Status 'Warning' -Details "File is empty" -Metrics $metrics
                }
            } else {
                Add-TestResult -TestName $testName -Status 'Warning' -Details "File not found"
            }
            
        } catch {
            Add-TestResult -TestName $testName -Status 'Fail' -Details "Error accessing file: $($_.Exception.Message)"
        }
    }
}

function Test-LogDirectories {
    <#
    .SYNOPSIS
    Test log directories and cleanup status
    #>
    
    if ($TestType -notin @('Full', 'Performance')) {
        return
    }
    
    Write-TestLog "Testing log directories..." -Level Info
    
    $logPaths = @(
        @{ Path = '.\logs'; Name = "Main Logs" },
        @{ Path = '.\health-reports'; Name = "Health Reports" },
        @{ Path = '.\AutomationLogs'; Name = "Automation Logs" }
    )
    
    foreach ($logPath in $logPaths) {
        $testName = "Log Directory: $($logPath.Name)"
        
        try {
            if (Test-Path $logPath.Path) {
                $files = Get-ChildItem $logPath.Path -File -ErrorAction SilentlyContinue
                $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
                $oldFiles = $files | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
                
                $metrics = @{
                    FileCount = $files.Count
                    TotalSizeMB = [math]::Round($totalSize / 1MB, 2)
                    OldFileCount = $oldFiles.Count
                    Path = $logPath.Path
                }
                
                if ($totalSize -lt 100MB) {
                    Add-TestResult -TestName $testName -Status 'Pass' -Details "$($files.Count) files, $([math]::Round($totalSize / 1MB, 1))MB" -Metrics $metrics
                } elseif ($totalSize -lt 500MB) {
                    Add-TestResult -TestName $testName -Status 'Warning' -Details "$($files.Count) files, $([math]::Round($totalSize / 1MB, 1))MB (cleanup recommended)" -Metrics $metrics
                } else {
                    Add-TestResult -TestName $testName -Status 'Fail' -Details "$($files.Count) files, $([math]::Round($totalSize / 1MB, 1))MB (cleanup required)" -Metrics $metrics
                }
            } else {
                Add-TestResult -TestName $testName -Status 'Warning' -Details "Directory not found"
            }
            
        } catch {
            Add-TestResult -TestName $testName -Status 'Warning' -Details "Error accessing logs: $($_.Exception.Message)"
        }
    }
}

# Main execution function
function Invoke-FileSystemHealthCheck {
    <#
    .SYNOPSIS
    Execute filesystem health checks based on test type
    #>
    
    Write-TestLog "Starting filesystem health checks (Type: $TestType)" -Level Info
    
    # Core tests - always run
    Test-DirectoryStructure
    Test-DiskSpace
    
    # Extended tests based on type
    if ($TestType -in @('Full', 'Critical')) {
        Test-FilePermissions
    }
    
    if ($TestType -eq 'Critical') {
        Test-FileSystemIntegrity
    }
    
    if ($TestType -in @('Full', 'Performance')) {
        Test-LogDirectories
    }
    
    Write-TestLog "Filesystem health checks completed" -Level Info
}

# Execute if run directly
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-FileSystemHealthCheck
}

# Export functions for module use
Export-ModuleMember -Function @(
    'Invoke-FileSystemHealthCheck',
    'Test-DirectoryStructure',
    'Test-DiskSpace',
    'Test-FilePermissions',
    'Test-FileSystemIntegrity',
    'Test-LogDirectories'
)