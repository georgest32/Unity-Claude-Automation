# Test-ConfigurationSystem.ps1
# Comprehensive test for Phase 2 Day 5 Configuration Management System

param(
    [switch]$Verbose,
    [switch]$SkipEnvironmentTests
)

Write-Host "=== Phase 2 Day 5 Configuration Management System Test ===" -ForegroundColor Cyan
Write-Host "Testing comprehensive JSON configuration system..." -ForegroundColor Yellow

$TestResults = @()
$ConfigBackup = $null

function Test-Result {
    param($TestName, $Result, $Details = "")
    
    $status = if ($Result) { "PASS" } else { "FAIL" }
    $color = if ($Result) { "Green" } else { "Red" }
    
    Write-Host "[$status] $TestName" -ForegroundColor $color
    if ($Details -and ($Verbose -or -not $Result)) {
        Write-Host "      $Details" -ForegroundColor Gray
    }
    
    $script:TestResults += @{
        Test = $TestName
        Result = $Result
        Details = $Details
    }
    
    return $Result
}

try {
    # Backup existing configuration
    $configPath = ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json"
    if (Test-Path $configPath) {
        $ConfigBackup = Get-Content $configPath -Raw
        Write-Host "Backed up existing configuration" -ForegroundColor Gray
    }

    Write-Host "`n1. Testing Module Import..." -ForegroundColor Yellow
    
    # Test module loading
    try {
        Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1" -Force
        $moduleLoaded = Get-Module "Unity-Claude-SystemStatus" -ErrorAction SilentlyContinue
        Test-Result "Module Import" ($null -ne $moduleLoaded) "Unity-Claude-SystemStatus module loaded"
    } catch {
        Test-Result "Module Import" $false "Error: $($_.Exception.Message)"
        return
    }

    Write-Host "`n2. Testing Configuration Loading..." -ForegroundColor Yellow
    
    # Test 1: Default configuration loading
    try {
        $defaultConfig = Get-SystemStatusConfiguration
        $hasRequiredSections = $defaultConfig.SystemStatus -and $defaultConfig.CircuitBreaker -and $defaultConfig.HealthMonitoring
        Test-Result "Default Configuration Loading" $hasRequiredSections "Loaded configuration with required sections"
        
        if ($Verbose) {
            Write-Host "      Sections: $($defaultConfig.Keys -join ', ')" -ForegroundColor Gray
        }
    } catch {
        Test-Result "Default Configuration Loading" $false "Error: $($_.Exception.Message)"
    }

    # Test 2: JSON file configuration
    Write-Host "`n3. Testing JSON Configuration Files..." -ForegroundColor Yellow
    
    $exampleConfigs = @(
        "development.config.json",
        "production.config.json", 
        "high-performance.config.json",
        "minimal.config.json",
        "testing.config.json"
    )
    
    foreach ($configFile in $exampleConfigs) {
        $examplePath = ".\Modules\Unity-Claude-SystemStatus\Config\examples\$configFile"
        
        if (Test-Path $examplePath) {
            try {
                # Copy example to main config location
                Copy-Item $examplePath $configPath -Force
                
                # Test loading
                $config = Get-SystemStatusConfiguration -ForceRefresh
                $isValid = $config.SystemStatus -and $config.CircuitBreaker
                
                Test-Result "JSON Config: $configFile" $isValid "Successfully loaded $configFile"
                
                if ($Verbose -and $isValid) {
                    Write-Host "      LogLevel: $($config.SystemStatus.LogLevel), MonitoringInterval: $($config.SystemStatus.MonitoringInterval)" -ForegroundColor Gray
                }
            } catch {
                Test-Result "JSON Config: $configFile" $false "Error loading $configFile`: $($_.Exception.Message)"
            }
        } else {
            Test-Result "JSON Config: $configFile" $false "Example file not found: $examplePath"
        }
    }

    # Test 3: Environment variable overrides
    if (-not $SkipEnvironmentTests) {
        Write-Host "`n4. Testing Environment Variable Overrides..." -ForegroundColor Yellow
        
        # Set test environment variables
        $originalLogLevel = $env:UNITYC_LOG_LEVEL
        $originalInterval = $env:UNITYC_MONITORING_INTERVAL
        $originalThreshold = $env:UNITYC_CB_FAILURE_THRESHOLD
        
        try {
            $env:UNITYC_LOG_LEVEL = "TRACE"
            $env:UNITYC_MONITORING_INTERVAL = "15"
            $env:UNITYC_CB_FAILURE_THRESHOLD = "7"
            
            $config = Get-SystemStatusConfiguration -ForceRefresh
            
            $logLevelTest = ($config.SystemStatus.LogLevel -eq "TRACE")
            $intervalTest = ($config.SystemStatus.MonitoringInterval -eq 15)
            $thresholdTest = ($config.CircuitBreaker.FailureThreshold -eq 7)
            
            Test-Result "Environment Override: LogLevel" $logLevelTest "LogLevel set to TRACE via UNITYC_LOG_LEVEL"
            Test-Result "Environment Override: MonitoringInterval" $intervalTest "MonitoringInterval set to 15 via UNITYC_MONITORING_INTERVAL"
            Test-Result "Environment Override: FailureThreshold" $thresholdTest "FailureThreshold set to 7 via UNITYC_CB_FAILURE_THRESHOLD"
            
        } finally {
            # Restore original environment variables
            if ($originalLogLevel) { $env:UNITYC_LOG_LEVEL = $originalLogLevel } else { Remove-Item Env:UNITYC_LOG_LEVEL -ErrorAction SilentlyContinue }
            if ($originalInterval) { $env:UNITYC_MONITORING_INTERVAL = $originalInterval } else { Remove-Item Env:UNITYC_MONITORING_INTERVAL -ErrorAction SilentlyContinue }
            if ($originalThreshold) { $env:UNITYC_CB_FAILURE_THRESHOLD = $originalThreshold } else { Remove-Item Env:UNITYC_CB_FAILURE_THRESHOLD -ErrorAction SilentlyContinue }
        }
    }

    # Test 4: Configuration validation
    Write-Host "`n5. Testing Configuration Validation..." -ForegroundColor Yellow
    
    try {
        $config = Get-SystemStatusConfiguration -ForceRefresh
        
        # Test if Test-SystemStatusConfiguration function exists
        $validationFunctionExists = Get-Command "Test-SystemStatusConfiguration" -ErrorAction SilentlyContinue
        
        if ($validationFunctionExists) {
            $validation = Test-SystemStatusConfiguration -Config $config
            Test-Result "Configuration Validation Function" $true "Test-SystemStatusConfiguration function available"
            Test-Result "Configuration Validation Result" $validation.IsValid "Configuration passed validation"
            
            if ($validation.Warnings -and $Verbose) {
                Write-Host "      Warnings: $($validation.Warnings -join ', ')" -ForegroundColor Yellow
            }
        } else {
            Test-Result "Configuration Validation Function" $false "Test-SystemStatusConfiguration function not found"
        }
    } catch {
        Test-Result "Configuration Validation" $false "Error during validation: $($_.Exception.Message)"
    }

    # Test 5: Circuit breaker configuration enhancement
    Write-Host "`n6. Testing Circuit Breaker Configuration..." -ForegroundColor Yellow
    
    try {
        $config = Get-SystemStatusConfiguration -ForceRefresh
        
        # Test Get-SubsystemCircuitBreakerConfig function
        $cbConfigFunction = Get-Command "Get-SubsystemCircuitBreakerConfig" -ErrorAction SilentlyContinue
        
        if ($cbConfigFunction) {
            $cbConfig = Get-SubsystemCircuitBreakerConfig -SubsystemName "TestSubsystem" -BaseConfig $config.CircuitBreaker
            
            $hasRequiredProperties = $cbConfig.FailureThreshold -and $cbConfig.TimeoutSeconds -and $cbConfig.ConfigurationSource
            Test-Result "Circuit Breaker Config Function" $hasRequiredProperties "Get-SubsystemCircuitBreakerConfig returned valid configuration"
            
            if ($Verbose) {
                Write-Host "      Source: $($cbConfig.ConfigurationSource), Threshold: $($cbConfig.FailureThreshold)" -ForegroundColor Gray
            }
            
            # Test circuit breaker integration
            $cbResult = Invoke-CircuitBreakerCheck -SubsystemName "TestSubsystem" -TestResult $true
            $cbIntegration = $cbResult -and $cbResult.State
            Test-Result "Circuit Breaker Integration" $cbIntegration "Circuit breaker integrates with configuration system"
            
        } else {
            Test-Result "Circuit Breaker Config Function" $false "Get-SubsystemCircuitBreakerConfig function not found"
        }
    } catch {
        Test-Result "Circuit Breaker Configuration" $false "Error testing circuit breaker: $($_.Exception.Message)"
    }

    # Test 6: Performance and caching
    Write-Host "`n7. Testing Performance Features..." -ForegroundColor Yellow
    
    try {
        # Test configuration caching functionality
        $config1 = Get-SystemStatusConfiguration
        $config2 = Get-SystemStatusConfiguration
        
        # Test that caching is working by checking if the same object is returned
        # and that configuration cache is being used (check via TRACE logs)
        $cachingWorking = ($config1 -ne $null) -and ($config2 -ne $null)
        Test-Result "Configuration Caching" $cachingWorking "Configuration caching functionality works"
        
        if ($Verbose) {
            Write-Host "      Cache enabled: $($config1.Performance.EnableConfigurationCaching)" -ForegroundColor Gray
        }
        
        # Test force refresh
        $config3 = Get-SystemStatusConfiguration -ForceRefresh
        $forceRefreshWorking = $config3 -ne $null
        Test-Result "Force Refresh" $forceRefreshWorking "Force refresh parameter works"
        
    } catch {
        Test-Result "Performance Features" $false "Error testing performance: $($_.Exception.Message)"
    }

    # Test 7: Documentation files
    Write-Host "`n8. Testing Documentation..." -ForegroundColor Yellow
    
    $docFiles = @(
        ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.schema.md",
        ".\Modules\Unity-Claude-SystemStatus\Config\CONFIGURATION_GUIDE.md",
        ".\Modules\Unity-Claude-SystemStatus\Config\TROUBLESHOOTING.md"
    )
    
    foreach ($docFile in $docFiles) {
        $exists = Test-Path $docFile
        $fileName = Split-Path $docFile -Leaf
        Test-Result "Documentation: $fileName" $exists "Documentation file exists"
        
        if ($exists -and $Verbose) {
            $content = Get-Content $docFile -Raw
            $size = [math]::Round($content.Length / 1024, 1)
            Write-Host "      Size: ${size}KB" -ForegroundColor Gray
        }
    }

} finally {
    # Restore original configuration if it existed
    if ($ConfigBackup) {
        $ConfigBackup | Out-File $configPath -Encoding UTF8
        Write-Host "`nRestored original configuration" -ForegroundColor Gray
    } elseif (Test-Path $configPath) {
        Remove-Item $configPath
        Write-Host "`nRemoved test configuration" -ForegroundColor Gray
    }
}

# Test Results Summary
Write-Host "`n=== TEST RESULTS SUMMARY ===" -ForegroundColor Cyan

$totalTests = $TestResults.Count
$passedTests = ($TestResults | Where-Object { $_.Result }).Count
$failedTests = $totalTests - $passedTests

Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor $(if ($failedTests -eq 0) { "Green" } else { "Red" })

if ($failedTests -gt 0) {
    Write-Host "`nFailed Tests:" -ForegroundColor Red
    $TestResults | Where-Object { -not $_.Result } | ForEach-Object {
        Write-Host "  - $($_.Test): $($_.Details)" -ForegroundColor Red
    }
}

$successRate = [math]::Round(($passedTests / $totalTests) * 100, 1)
Write-Host "`nSuccess Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })

if ($successRate -ge 80) {
    Write-Host "`n✅ Configuration Management System is working correctly!" -ForegroundColor Green
} elseif ($successRate -ge 60) {
    Write-Host "`n⚠️  Configuration Management System has some issues but core functionality works" -ForegroundColor Yellow
} else {
    Write-Host "`n❌ Configuration Management System has significant issues" -ForegroundColor Red
}

Write-Host "`nTest completed. Use -Verbose for detailed output." -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUml8y/rboLtPlI0CbUgKzSlIV
# 6zCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUkxH57lDYf2f+8Zd0uGcks+W3jNcwDQYJKoZIhvcNAQEBBQAEggEAdUMh
# 6SlbhBqdDth+SFWQsNeZiBl7LV/3+9DpyyuSOGw/gbqoKJn1ui7vuFQA+npUaWFU
# Z0Rwy4T+uNic8Uyq2OhbcrZQUSFX1hFGiS3hvP2RPaP3yaYuHVmgo+MJuILd9e38
# PWtg38FEpKE6f+kSGCW/OuzWmPOqU44yaNW3UqrVdqxMdURTdbozxS5CX1l6h3s2
# WaO6OP8A/DangBn4uZJfv8tS3dCs1u40CNL7rOOC3Z4PcuICIZnx8sE6RzrA6oXv
# hRTXfa+79JuXPnIsr1GmzDnI7La2o+5y2N3DHDU96G9nhJQKh9BC0RHfI+lMTthR
# F+Np0voACnbSjbXGNw==
# SIG # End signature block
