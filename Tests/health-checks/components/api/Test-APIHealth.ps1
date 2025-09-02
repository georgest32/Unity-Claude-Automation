# Unity-Claude-Automation API Health Check Component
# Tests service endpoints and API functionality
# Version: 2025-08-25

[CmdletBinding()]
param(
    [ValidateSet('Quick', 'Full', 'Critical', 'Performance')]
    [string]$TestType = 'Quick',
    
    [switch]$Detailed
)

# Import shared utilities
Import-Module "$PSScriptRoot\..\..\shared\Test-HealthUtilities.psm1" -Force

function Get-ServiceEndpoints {
    <#
    .SYNOPSIS
    Get list of service endpoints to test based on test type
    #>
    
    # Core services - always tested
    $coreServices = @(
        @{ 
            Name = "Documentation Web"
            URL = "http://localhost:8080/health"
            Timeout = 30
            Content = "healthy"
            Critical = $true
        },
        @{ 
            Name = "Documentation API"
            URL = "http://localhost:8091/health"
            Timeout = 30
            Content = "healthy"
            Critical = $true
        },
        @{ 
            Name = "PowerShell Modules"
            URL = "http://localhost:5985"
            Timeout = 15
            Content = ""
            Critical = $false
        },
        @{ 
            Name = "LangGraph API"
            URL = "http://localhost:8000/health"
            Timeout = 30
            Content = "healthy"
            Critical = $true
        },
        @{ 
            Name = "AutoGen Service"
            URL = "http://localhost:8001/health"
            Timeout = 30
            Content = "healthy"
            Critical = $true
        }
    )
    
    # Monitoring services - tested in Full/Performance mode
    $monitoringServices = @(
        @{ 
            Name = "Prometheus"
            URL = "http://localhost:9090/-/ready"
            Timeout = 15
            Content = ""
            Critical = $false
        },
        @{ 
            Name = "Grafana"
            URL = "http://localhost:3000/api/health"
            Timeout = 15
            Content = ""
            Critical = $false
        },
        @{ 
            Name = "Loki"
            URL = "http://localhost:3100/ready"
            Timeout = 15
            Content = ""
            Critical = $false
        },
        @{ 
            Name = "Alertmanager"
            URL = "http://localhost:9093/-/ready"
            Timeout = 10
            Content = ""
            Critical = $false
        }
    )
    
    $services = $coreServices
    
    if ($TestType -in @('Full', 'Performance')) {
        $services += $monitoringServices
    }
    
    return $services
}

function Test-ServiceEndpoints {
    <#
    .SYNOPSIS
    Test all configured service endpoints
    #>
    
    Write-TestLog "Testing service endpoints..." -Level Info
    
    $services = Get-ServiceEndpoints
    
    foreach ($service in $services) {
        Test-ServiceHealth -ServiceName $service.Name -URL $service.URL -TimeoutSeconds $service.Timeout -ExpectedContent $service.Content
    }
}

function Test-APIFunctionality {
    <#
    .SYNOPSIS
    Test specific API functionality
    #>
    
    if ($TestType -eq 'Quick') {
        Write-TestLog "Skipping API functionality tests (Quick mode)" -Level Info
        return
    }
    
    Write-TestLog "Testing API functionality..." -Level Info
    
    # Test Documentation API endpoints
    $apiTests = @(
        @{ 
            Endpoint = "/api/modules"
            Name = "Modules List"
            ExpectedType = "Array"
            MinItems = 1
        },
        @{ 
            Endpoint = "/api/functions"
            Name = "Functions List"
            ExpectedType = "Array"
            MinItems = 10
        },
        @{ 
            Endpoint = "/api/search-data"
            Name = "Search Data"
            ExpectedType = "Object"
            MinItems = 1
        }
    )
    
    foreach ($test in $apiTests) {
        Test-APIEndpoint -Endpoint $test.Endpoint -Name $test.Name -ExpectedType $test.ExpectedType -MinItems $test.MinItems
    }
    
    # Test API performance if in Performance mode
    if ($TestType -eq 'Performance') {
        Test-APIPerformance
    }
}

function Test-APIEndpoint {
    <#
    .SYNOPSIS
    Test a specific API endpoint
    
    .PARAMETER Endpoint
    API endpoint path
    
    .PARAMETER Name
    Test name
    
    .PARAMETER ExpectedType
    Expected response type
    
    .PARAMETER MinItems
    Minimum expected items in response
    #>
    param(
        [string]$Endpoint,
        [string]$Name,
        [string]$ExpectedType,
        [int]$MinItems = 0
    )
    
    $testName = "API: $Name"
    $url = "http://localhost:8091$Endpoint"
    $startTime = Get-Date
    
    try {
        $response = Invoke-RestMethod -Uri $url -TimeoutSec 15 -ErrorAction Stop
        $duration = [int]((Get-Date) - $startTime).TotalMilliseconds
        
        $metrics = @{
            ResponseTime = $duration
            ResponseType = $response.GetType().Name
            Endpoint = $Endpoint
        }
        
        if ($response) {
            $itemCount = if ($response -is [array]) { 
                $response.Count 
            } elseif ($response -is [hashtable] -or $response.GetType().Name -like "*PSCustomObject*") {
                $response.PSObject.Properties.Count
            } else { 
                1 
            }
            
            $metrics.ItemCount = $itemCount
            
            # Validate response type and content
            if ($ExpectedType -eq "Array" -and $response -is [array]) {
                if ($itemCount -ge $MinItems) {
                    Add-TestResult -TestName $testName -Status 'Pass' -Details "$itemCount items returned" -Metrics $metrics -Duration $duration
                } else {
                    Add-TestResult -TestName $testName -Status 'Warning' -Details "Only $itemCount items returned (expected $MinItems+)" -Metrics $metrics -Duration $duration
                }
            } elseif ($ExpectedType -eq "Object") {
                if ($itemCount -ge $MinItems) {
                    Add-TestResult -TestName $testName -Status 'Pass' -Details "Object with $itemCount properties" -Metrics $metrics -Duration $duration
                } else {
                    Add-TestResult -TestName $testName -Status 'Warning' -Details "Object has only $itemCount properties" -Metrics $metrics -Duration $duration
                }
            } else {
                Add-TestResult -TestName $testName -Status 'Warning' -Details "Unexpected response type: $($response.GetType().Name)" -Metrics $metrics -Duration $duration
            }
        } else {
            Add-TestResult -TestName $testName -Status 'Warning' -Details "Empty response" -Duration $duration
        }
        
    } catch {
        $duration = [int]((Get-Date) - $startTime).TotalMilliseconds
        Add-TestResult -TestName $testName -Status 'Fail' -Details $_.Exception.Message -Duration $duration
    }
}

function Test-APIPerformance {
    <#
    .SYNOPSIS
    Test API performance characteristics
    #>
    
    Write-TestLog "Testing API performance..." -Level Info
    
    $perfTests = @(
        @{ Endpoint = "/api/modules"; Name = "Modules Performance"; Iterations = 5 },
        @{ Endpoint = "/api/functions"; Name = "Functions Performance"; Iterations = 3 },
        @{ Endpoint = "/api/search-data"; Name = "Search Performance"; Iterations = 3 }
    )
    
    foreach ($test in $perfTests) {
        Test-APIEndpointPerformance -Endpoint $test.Endpoint -Name $test.Name -Iterations $test.Iterations
    }
}

function Test-APIEndpointPerformance {
    <#
    .SYNOPSIS
    Test performance of a specific API endpoint
    
    .PARAMETER Endpoint
    API endpoint
    
    .PARAMETER Name
    Test name
    
    .PARAMETER Iterations
    Number of test iterations
    #>
    param(
        [string]$Endpoint,
        [string]$Name,
        [int]$Iterations = 5
    )
    
    $testName = "API Performance: $Name"
    $url = "http://localhost:8091$Endpoint"
    $responseTimes = @()
    
    try {
        Write-TestLog "Running $Iterations iterations for $Name..." -Level Test
        
        for ($i = 1; $i -le $Iterations; $i++) {
            $startTime = Get-Date
            $response = Invoke-RestMethod -Uri $url -TimeoutSec 10 -ErrorAction Stop
            $duration = [int]((Get-Date) - $startTime).TotalMilliseconds
            $responseTimes += $duration
        }
        
        $avgTime = ($responseTimes | Measure-Object -Average).Average
        $minTime = ($responseTimes | Measure-Object -Minimum).Minimum
        $maxTime = ($responseTimes | Measure-Object -Maximum).Maximum
        
        $metrics = @{
            Iterations = $Iterations
            AverageResponseTime = [int]$avgTime
            MinResponseTime = $minTime
            MaxResponseTime = $maxTime
            ResponseTimes = $responseTimes
            Endpoint = $Endpoint
        }
        
        if ($avgTime -lt 500) {
            Add-TestResult -TestName $testName -Status 'Pass' -Details "Avg: $([int]$avgTime)ms" -Metrics $metrics
        } elseif ($avgTime -lt 1000) {
            Add-TestResult -TestName $testName -Status 'Warning' -Details "Avg: $([int]$avgTime)ms (acceptable)" -Metrics $metrics
        } else {
            Add-TestResult -TestName $testName -Status 'Fail' -Details "Avg: $([int]$avgTime)ms (too slow)" -Metrics $metrics
        }
        
    } catch {
        Add-TestResult -TestName $testName -Status 'Fail' -Details "Performance test failed: $($_.Exception.Message)"
    }
}

function Test-APIConnectivity {
    <#
    .SYNOPSIS
    Test basic API connectivity and response
    #>
    
    Write-TestLog "Testing API connectivity..." -Level Info
    
    $connectivityTests = @(
        @{ URL = "http://localhost:8091/"; Name = "API Root" },
        @{ URL = "http://localhost:8080/"; Name = "Web Root" },
        @{ URL = "http://localhost:8000/"; Name = "LangGraph Root" }
    )
    
    foreach ($test in $connectivityTests) {
        $testName = "API Connectivity: $($test.Name)"
        
        try {
            $response = Invoke-WebRequest -Uri $test.URL -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
            
            $metrics = @{
                StatusCode = $response.StatusCode
                ContentLength = $response.Content.Length
                URL = $test.URL
            }
            
            if ($response.StatusCode -in @(200, 404, 405)) {  # 404/405 are OK for root endpoints
                Add-TestResult -TestName $testName -Status 'Pass' -Details "HTTP $($response.StatusCode)" -Metrics $metrics
            } else {
                Add-TestResult -TestName $testName -Status 'Warning' -Details "HTTP $($response.StatusCode)" -Metrics $metrics
            }
            
        } catch {
            Add-TestResult -TestName $testName -Status 'Fail' -Details $_.Exception.Message
        }
    }
}

# Main execution function
function Invoke-APIHealthCheck {
    <#
    .SYNOPSIS
    Execute API health checks based on test type
    #>
    
    Write-TestLog "Starting API health checks (Type: $TestType)" -Level Info
    
    # Core tests - always run
    Test-ServiceEndpoints
    
    if ($TestType -in @('Full', 'Critical', 'Performance')) {
        Test-APIConnectivity
        Test-APIFunctionality
    }
    
    Write-TestLog "API health checks completed" -Level Info
}

# Execute if run directly
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-APIHealthCheck
}

# Export functions for module use
Export-ModuleMember -Function @(
    'Invoke-APIHealthCheck',
    'Test-ServiceEndpoints',
    'Test-APIFunctionality',
    'Test-APIEndpoint',
    'Test-APIPerformance',
    'Test-APIEndpointPerformance',
    'Test-APIConnectivity'
)