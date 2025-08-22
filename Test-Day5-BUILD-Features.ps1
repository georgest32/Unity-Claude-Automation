# Test Day 5 BUILD Features - Real Unity Project Testing
# This script demonstrates and tests the actual BUILD command functionality
# Date: 2025-08-18

param(
    [switch]$DryRun = $true,  # Default to dry run for safety
    [string]$ProjectPath = "C:\UnityProjects\Sound-and-Shoal\Dithering",
    [switch]$TestAll
)

Write-Host "=== Testing Day 5 BUILD Command Features ===" -ForegroundColor Cyan
Write-Host "Project Path: $ProjectPath" -ForegroundColor Yellow
Write-Host "Dry Run Mode: $DryRun" -ForegroundColor $(if($DryRun) { "Green" } else { "Red" })
Write-Host ""

# Import the SafeCommandExecution module
$modulePath = Join-Path $PSScriptRoot "Modules\SafeCommandExecution\SafeCommandExecution.psm1"
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
    Write-Host "✅ SafeCommandExecution module loaded" -ForegroundColor Green
} else {
    Write-Host "❌ SafeCommandExecution module not found at: $modulePath" -ForegroundColor Red
    return
}

Write-Host "`n=== Available BUILD Operations ===" -ForegroundColor Cyan
$buildOperations = @(
    @{ Name = "BuildPlayer"; Description = "Build Unity player for specified platform" }
    @{ Name = "ImportAsset"; Description = "Import Unity packages using AssetDatabase API" }
    @{ Name = "ExecuteMethod"; Description = "Execute custom Unity static methods" }
    @{ Name = "ValidateProject"; Description = "Validate Unity project structure and assets" }
    @{ Name = "CompileScripts"; Description = "Verify Unity script compilation" }
)

foreach ($op in $buildOperations) {
    Write-Host "  • $($op.Name): $($op.Description)" -ForegroundColor White
}

function Test-BuildOperation {
    param(
        [hashtable]$Command,
        [string]$TestName,
        [switch]$ExecuteReal
    )
    
    Write-Host "`n--- Testing: $TestName ---" -ForegroundColor Yellow
    
    if ($DryRun -and -not $ExecuteReal) {
        Write-Host "🔍 DRY RUN - Command validation only" -ForegroundColor Blue
        
        # Test command safety validation
        try {
            $safety = Test-CommandSafety -Command $Command
            if ($safety.IsSafe) {
                Write-Host "✅ Command passed safety validation" -ForegroundColor Green
                Write-Host "   Reason: $($safety.Reason)" -ForegroundColor Gray
            } else {
                Write-Host "❌ Command failed safety validation" -ForegroundColor Red
                Write-Host "   Reason: $($safety.Reason)" -ForegroundColor Gray
            }
        } catch {
            Write-Host "❌ Error during safety validation: $_" -ForegroundColor Red
        }
        
        # Display command details
        Write-Host "📋 Command Details:" -ForegroundColor Cyan
        Write-Host "   Type: $($Command.CommandType)" -ForegroundColor Gray
        Write-Host "   Operation: $($Command.Operation)" -ForegroundColor Gray
        if ($Command.Arguments -is [hashtable]) {
            foreach ($key in $Command.Arguments.Keys) {
                Write-Host "   $key`: $($Command.Arguments[$key])" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "🚀 EXECUTING REAL BUILD COMMAND" -ForegroundColor Magenta
        try {
            $result = Invoke-SafeCommand -Command $Command -TimeoutSeconds 180
            if ($result.Success) {
                Write-Host "✅ BUILD command executed successfully" -ForegroundColor Green
                if ($result.Output) {
                    Write-Host "📄 Output:" -ForegroundColor Cyan
                    $result.Output | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
                }
            } else {
                Write-Host "❌ BUILD command failed" -ForegroundColor Red
                Write-Host "   Error: $($result.Error)" -ForegroundColor Gray
            }
        } catch {
            Write-Host "❌ Exception during BUILD execution: $_" -ForegroundColor Red
        }
    }
}

# Test 1: Project Validation (Safe to run)
Write-Host "`n🔍 TEST 1: Unity Project Validation" -ForegroundColor Cyan
$projectValidationCommand = @{
    CommandType = 'Build'
    Operation = 'ValidateProject'
    Arguments = @{
        ProjectPath = $ProjectPath
    }
}
Test-BuildOperation -Command $projectValidationCommand -TestName "Project Structure Validation" -ExecuteReal

# Test 2: Script Compilation Check (Safe to run)
Write-Host "`n🔍 TEST 2: Unity Script Compilation Verification" -ForegroundColor Cyan
$compilationCommand = @{
    CommandType = 'Build'
    Operation = 'CompileScripts'
    Arguments = @{
        ProjectPath = $ProjectPath
    }
}
Test-BuildOperation -Command $compilationCommand -TestName "Script Compilation Check"

# Test 3: Windows Build (Requires confirmation if not dry run)
Write-Host "`n🔍 TEST 3: Unity Windows Build" -ForegroundColor Cyan
$windowsBuildCommand = @{
    CommandType = 'Build'
    Operation = 'BuildPlayer'
    Arguments = @{
        BuildTarget = 'Windows'
        ProjectPath = $ProjectPath
        OutputPath = "$ProjectPath\Builds\Windows_Test"
    }
}
Test-BuildOperation -Command $windowsBuildCommand -TestName "Windows Platform Build"

# Test 4: Custom Method Execution (Safe example)
Write-Host "`n🔍 TEST 4: Unity Custom Method Execution" -ForegroundColor Cyan
$customMethodCommand = @{
    CommandType = 'Build'
    Operation = 'ExecuteMethod'
    Arguments = @{
        MethodName = 'UnityEditor.EditorApplication.Exit'
        ProjectPath = $ProjectPath
    }
}
Test-BuildOperation -Command $customMethodCommand -TestName "Custom Method Execution (Exit)"

# Test 5: Asset Import (Requires a test package)
Write-Host "`n🔍 TEST 5: Unity Asset Import" -ForegroundColor Cyan
$assetImportCommand = @{
    CommandType = 'Build'
    Operation = 'ImportAsset'
    Arguments = @{
        PackagePath = "C:\TestPackage.unitypackage"  # Would need a real package
        ProjectPath = $ProjectPath
    }
}
Test-BuildOperation -Command $assetImportCommand -TestName "Asset Package Import"

# Advanced Tests (if TestAll is specified)
if ($TestAll) {
    Write-Host "`n🔍 ADVANCED TESTS: Additional Platform Builds" -ForegroundColor Cyan
    
    $advancedBuilds = @(
        @{ Target = "Android"; Name = "Android APK Build" }
        @{ Target = "WebGL"; Name = "WebGL Build" }
        @{ Target = "Linux"; Name = "Linux Build" }
    )
    
    foreach ($build in $advancedBuilds) {
        $command = @{
            CommandType = 'Build'
            Operation = 'BuildPlayer'
            Arguments = @{
                BuildTarget = $build.Target
                ProjectPath = $ProjectPath
                OutputPath = "$ProjectPath\Builds\$($build.Target)_Test"
            }
        }
        Test-BuildOperation -Command $command -TestName $build.Name
    }
}

# Security Testing
Write-Host "`n🔒 SECURITY TESTS: Command Injection Prevention" -ForegroundColor Cyan

# Test dangerous command injection
$dangerousCommand = @{
    CommandType = 'Build'
    Operation = 'BuildPlayer'
    Arguments = @{
        BuildTarget = 'Windows; rm -rf /'
        ProjectPath = $ProjectPath
    }
}
Test-BuildOperation -Command $dangerousCommand -TestName "Command Injection Prevention Test"

# Test path traversal
$pathTraversalCommand = @{
    CommandType = 'Build'
    Operation = 'ValidateProject'
    Arguments = @{
        ProjectPath = "../../Windows/System32"
    }
}
Test-BuildOperation -Command $pathTraversalCommand -TestName "Path Traversal Prevention Test"

Write-Host "`n=== BUILD Feature Testing Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "To run REAL BUILD commands (not dry run):" -ForegroundColor Yellow
Write-Host "  .\Test-Day5-BUILD-Features.ps1 -DryRun:`$false" -ForegroundColor White
Write-Host ""
Write-Host "To test all platform builds:" -ForegroundColor Yellow
Write-Host "  .\Test-Day5-BUILD-Features.ps1 -TestAll" -ForegroundColor White
Write-Host ""
Write-Host "To use a different Unity project:" -ForegroundColor Yellow
Write-Host "  .\Test-Day5-BUILD-Features.ps1 -ProjectPath 'C:\Your\Unity\Project'" -ForegroundColor White
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUwhT+dvRDxF6ve+rnTo23egco
# iHWgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUN8Ms0R6u8fkVh+TZW6VQwCRZNQQwDQYJKoZIhvcNAQEBBQAEggEAU3Fo
# hDLsiGiYaFng/sTiBYddKmVCqR/ZPSOEAlJxVy/MTnurYHjcv1vkWZ4AOm4dP+G5
# srrcmefsQMqJnIuBN3VPBbPvpLgpGx02fvmQ50JSm7NUhTjY1yRtF82Pq3wx2/U1
# a5Uf/4qMgMkqJHS0TVAWWSKQpxbYPhCwP789GRuPDUJD9Zs5dOuHHzwi4+MOdvDJ
# Ho6kVVV3upujtZxKLPoowQ99vxNO7E+U3xMCtPg2RLsOCdGk0v2nfRni80yPe9Dn
# oit2exHPhrfWA0J/5Y8YdASFC8mX5GZrFr7wm/MUTHTdCEkXgSefozqtxBIPZzWj
# jMzXYhwUzugKNaoEBw==
# SIG # End signature block
