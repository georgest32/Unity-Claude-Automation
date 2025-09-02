# Unity-Claude-Automation PowerShell Module Health Check Component
# Tests PowerShell module health and functionality
# Version: 2025-08-25

[CmdletBinding()]
param(
    [ValidateSet('Quick', 'Full', 'Critical', 'Performance')]
    [string]$TestType = 'Quick',
    
    [string[]]$ModuleNames = @(
        'Unity-Claude-CPG',
        'Unity-Claude-SemanticAnalysis',
        'Unity-Claude-LLM',
        'Unity-Claude-APIDocumentation',
        'Unity-Claude-CodeQL',
        'Unity-Claude-CLIOrchestrator',
        'Unity-Claude-Cache',
        'Unity-Claude-PredictiveAnalysis'
    ),
    
    [switch]$Detailed,
    [switch]$TestFunctionality
)

# Import shared utilities
Import-Module "$PSScriptRoot\..\..\shared\Test-HealthUtilities.psm1" -Force

function Test-ModuleManifest {
    <#
    .SYNOPSIS
    Test a PowerShell module manifest
    
    .PARAMETER ModuleName
    Name of the module to test
    
    .PARAMETER ModulePath
    Path to the module manifest
    #>
    param(
        [string]$ModuleName,
        [string]$ModulePath
    )
    
    $testName = "PowerShell Module: $ModuleName"
    $startTime = Get-Date
    
    try {
        if (-not (Test-Path $ModulePath)) {
            Add-TestResult -TestName $testName -Status 'Warning' -Details "Module manifest not found at $ModulePath"
            return $null
        }
        
        # Test manifest syntax
        $manifest = Test-ModuleManifest -Path $ModulePath -ErrorAction Stop
        $duration = [int]((Get-Date) - $startTime).TotalMilliseconds
        
        $metrics = @{
            Version = $manifest.Version.ToString()
            ModuleType = $manifest.ModuleType
            PowerShellVersion = $manifest.PowerShellVersion.ToString()
            ManifestPath = $ModulePath
            TestDuration = $duration
        }
        
        # Try importing the module
        try {
            Import-Module $ModulePath -Force -ErrorAction Stop
            
            # Get exported functions
            $exportedFunctions = @(Get-Command -Module $ModuleName -ErrorAction SilentlyContinue)
            $exportedVariables = @(Get-Variable -Scope Global | Where-Object { $_.Name -like "*$ModuleName*" })
            
            $metrics.ExportedFunctions = $exportedFunctions.Count
            $metrics.ExportedVariables = $exportedVariables.Count
            
            if ($exportedFunctions.Count -gt 0) {
                $metrics.FunctionNames = $exportedFunctions.Name
                Add-TestResult -TestName $testName -Status 'Pass' -Details "$($exportedFunctions.Count) functions exported" -Metrics $metrics -Duration $duration
                
                # Test core functions if detailed testing is enabled
                if ($Detailed -and $TestType -in @('Full', 'Critical')) {
                    Test-ModuleFunctionality -ModuleName $ModuleName -Functions $exportedFunctions
                }
            } else {
                Add-TestResult -TestName $testName -Status 'Warning' -Details "Module loaded but no functions exported" -Metrics $metrics -Duration $duration
            }
            
            return $manifest
            
        } catch {
            Add-TestResult -TestName $testName -Status 'Fail' -Details "Module import failed: $($_.Exception.Message)" -Metrics $metrics -Duration $duration
            return $null
        } finally {
            # Clean up - remove module
            Remove-Module $ModuleName -Force -ErrorAction SilentlyContinue
        }
        
    } catch {
        $duration = [int]((Get-Date) - $startTime).TotalMilliseconds
        Add-TestResult -TestName $testName -Status 'Fail' -Details "Manifest test failed: $($_.Exception.Message)" -Duration $duration
        return $null
    }
}

function Test-ModuleFunctionality {
    <#
    .SYNOPSIS
    Test basic functionality of module functions
    
    .PARAMETER ModuleName
    Name of the module
    
    .PARAMETER Functions
    Array of function objects to test
    #>
    param(
        [string]$ModuleName,
        [array]$Functions
    )
    
    Write-TestLog "Testing $ModuleName functionality..." -Level Info
    
    # Test help for key functions
    $corePatterns = @(
        'Get-*', 'New-*', 'Test-*', 'Invoke-*', 'Start-*', 'Initialize-*'
    )
    
    $coreFunctions = $Functions | Where-Object { 
        $funcName = $_.Name
        $corePatterns | ForEach-Object { $funcName -like $_ } | Where-Object { $_ }
    } | Select-Object -First 5  # Limit to avoid long tests
    
    foreach ($func in $coreFunctions) {
        $funcTestName = "Function Help: $($func.Name)"
        
        try {
            $help = Get-Help $func.Name -ErrorAction Stop
            
            if ($help.Synopsis -and $help.Synopsis -ne $func.Name) {
                Add-TestResult -TestName $funcTestName -Status 'Pass' -Details "Help documentation available"
            } else {
                Add-TestResult -TestName $funcTestName -Status 'Warning' -Details "Limited help documentation"
            }
            
        } catch {
            Add-TestResult -TestName $funcTestName -Status 'Warning' -Details "Help not available"
        }
    }
    
    # Test parameter validation for key functions (if enabled)
    if ($TestFunctionality -and $TestType -eq 'Full') {
        Test-ModuleParameters -ModuleName $ModuleName -Functions $coreFunctions
    }
}

function Test-ModuleParameters {
    <#
    .SYNOPSIS
    Test parameter validation for module functions
    
    .PARAMETER ModuleName
    Module name
    
    .PARAMETER Functions
    Functions to test
    #>
    param(
        [string]$ModuleName,
        [array]$Functions
    )
    
    foreach ($func in $Functions) {
        $paramTestName = "Function Parameters: $($func.Name)"
        
        try {
            $parameters = $func.Parameters
            $mandatoryParams = $parameters.Values | Where-Object { $_.Attributes.Mandatory -eq $true }
            
            Add-TestResult -TestName $paramTestName -Status 'Pass' -Details "$($mandatoryParams.Count) mandatory parameters" -Metrics @{
                TotalParameters = $parameters.Count
                MandatoryParameters = $mandatoryParams.Count
            }
            
        } catch {
            Add-TestResult -TestName $paramTestName -Status 'Warning' -Details "Cannot analyze parameters"
        }
    }
}

function Test-ModuleDependencies {
    <#
    .SYNOPSIS
    Test module dependencies
    
    .PARAMETER ModuleName
    Module name
    
    .PARAMETER Manifest
    Module manifest object
    #>
    param(
        [string]$ModuleName,
        [object]$Manifest
    )
    
    if ($TestType -notin @('Full', 'Critical')) {
        return
    }
    
    $depTestName = "Module Dependencies: $ModuleName"
    
    try {
        $requiredModules = $Manifest.RequiredModules
        $nestedModules = $Manifest.NestedModules
        
        $metrics = @{
            RequiredModules = $requiredModules.Count
            NestedModules = $nestedModules.Count
        }
        
        if ($requiredModules) {
            $metrics.RequiredModuleNames = $requiredModules | ForEach-Object { 
                if ($_ -is [string]) { $_ } else { $_.ModuleName }
            }
        }
        
        if ($nestedModules) {
            $metrics.NestedModuleNames = $nestedModules
        }
        
        Add-TestResult -TestName $depTestName -Status 'Pass' -Details "Dependencies analyzed" -Metrics $metrics
        
    } catch {
        Add-TestResult -TestName $depTestName -Status 'Warning' -Details "Cannot analyze dependencies: $($_.Exception.Message)"
    }
}

function Test-ModulePerformance {
    <#
    .SYNOPSIS
    Test module performance metrics
    
    .PARAMETER ModuleName
    Module name
    #>
    param([string]$ModuleName)
    
    if ($TestType -ne 'Performance') {
        return
    }
    
    $perfTestName = "Module Performance: $ModuleName"
    
    try {
        $modulePath = ".\Modules\$ModuleName\$ModuleName.psd1"
        
        # Measure import time
        $importTime = Measure-Command {
            Import-Module $modulePath -Force -ErrorAction Stop
        }
        
        # Measure memory usage
        $beforeMemory = [GC]::GetTotalMemory($false)
        $functions = Get-Command -Module $ModuleName
        $afterMemory = [GC]::GetTotalMemory($false)
        $memoryDelta = $afterMemory - $beforeMemory
        
        $metrics = @{
            ImportTimeMs = [int]$importTime.TotalMilliseconds
            MemoryDeltaBytes = $memoryDelta
            FunctionCount = $functions.Count
        }
        
        if ($importTime.TotalMilliseconds -lt 1000) {
            Add-TestResult -TestName $perfTestName -Status 'Pass' -Details "Import: $([int]$importTime.TotalMilliseconds)ms" -Metrics $metrics
        } elseif ($importTime.TotalMilliseconds -lt 3000) {
            Add-TestResult -TestName $perfTestName -Status 'Warning' -Details "Slow import: $([int]$importTime.TotalMilliseconds)ms" -Metrics $metrics
        } else {
            Add-TestResult -TestName $perfTestName -Status 'Fail' -Details "Very slow import: $([int]$importTime.TotalMilliseconds)ms" -Metrics $metrics
        }
        
        Remove-Module $ModuleName -Force -ErrorAction SilentlyContinue
        
    } catch {
        Add-TestResult -TestName $perfTestName -Status 'Fail' -Details "Performance test failed: $($_.Exception.Message)"
    }
}

# Main execution function
function Invoke-PowerShellModuleHealthCheck {
    <#
    .SYNOPSIS
    Execute PowerShell module health checks
    #>
    
    Write-TestLog "Starting PowerShell module health checks (Type: $TestType)" -Level Info
    Write-TestLog "Testing $($ModuleNames.Count) modules..." -Level Info
    
    foreach ($moduleName in $ModuleNames) {
        $modulePath = ".\Modules\$moduleName\$moduleName.psd1"
        
        Write-TestLog "Testing module: $moduleName" -Level Test
        
        # Core manifest test
        $manifest = Test-ModuleManifest -ModuleName $moduleName -ModulePath $modulePath
        
        # Extended tests if manifest is valid
        if ($manifest) {
            Test-ModuleDependencies -ModuleName $moduleName -Manifest $manifest
            Test-ModulePerformance -ModuleName $moduleName
        }
    }
    
    Write-TestLog "PowerShell module health checks completed" -Level Info
}

# Execute if run directly
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-PowerShellModuleHealthCheck
}

# Export functions for module use
Export-ModuleMember -Function @(
    'Invoke-PowerShellModuleHealthCheck',
    'Test-ModuleManifest',
    'Test-ModuleFunctionality',
    'Test-ModuleParameters',
    'Test-ModuleDependencies',
    'Test-ModulePerformance'
)