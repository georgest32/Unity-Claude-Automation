
function Restart-ServiceWithDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServiceName,
        
        [switch]$Force
    )
    
    Write-SystemStatusLog "Starting cascade restart for service: $ServiceName (Force=$Force)" -Level 'INFO'
    
    try {
        # Integration Point 15: Use existing SafeCommandExecution (Query 7 research finding)
        $constrainedCommands = @(
            'Restart-Service', 'Stop-Service', 'Start-Service', 'Get-Service'
        )
        
        # Get dependency order using topological sort
        $dependencyGraph = Get-ServiceDependencyGraph -ServiceName $ServiceName
        $restartOrder = Get-TopologicalSort -DependencyGraph $dependencyGraph
        
        if ($restartOrder.Count -eq 0) {
            Write-SystemStatusLog "No dependencies found, restarting single service: $ServiceName" -Level 'INFO'
            $restartOrder = @($ServiceName)
        }
        
        $successCount = 0
        $totalServices = $restartOrder.Count
        
        # Enterprise recovery pattern (Query 10 research finding)
        foreach ($service in $restartOrder) {
            Write-SystemStatusLog "Processing service restart: $service (Step $($successCount + 1) of $totalServices)" -Level 'INFO'
            
            try {
                # Use -Force flag for dependency handling (Query 2 research finding)
                $restartParams = @{
                    Name = $service
                    Force = $Force
                    ErrorAction = 'Stop'
                }
                
                # Check if SafeCommandExecution module is available
                if (Get-Module -Name SafeCommandExecution -ListAvailable) {
                    Import-Module SafeCommandExecution -Force -ErrorAction SilentlyContinue
                    if (Get-Command -Name Invoke-SafeCommand -ErrorAction SilentlyContinue) {
                        Invoke-SafeCommand -Command "Restart-Service" -Parameters $restartParams -AllowedCommands $constrainedCommands
                    } else {
                        Restart-Service @restartParams
                    }
                } else {
                    Restart-Service @restartParams
                }
                
                # Verify service started successfully
                Start-Sleep -Seconds 2  # Allow service time to start
                $serviceStatus = Get-Service -Name $service -ErrorAction SilentlyContinue
                
                if ($serviceStatus -and $serviceStatus.Status -eq 'Running') {
                    Write-SystemStatusLog "Service restart successful: $service" -Level 'OK'
                    $successCount++
                    
                    # Verify dependent services restarted (Query 2 enterprise best practice)
                    $dependentServices = $serviceStatus.DependentServices
                    foreach ($dependent in $dependentServices) {
                        if ($dependent.Status -ne 'Running') {
                            Write-SystemStatusLog "Warning: Dependent service $($dependent.Name) not running after $service restart" -Level 'WARNING'
                        } else {
                            Write-SystemStatusLog "Dependent service validated: $($dependent.Name)" -Level 'DEBUG'
                        }
                    }
                } else {
                    $currentStatus = if ($serviceStatus) { $serviceStatus.Status } else { "Not Found" }
                    throw "Service $service failed to start. Current status: $currentStatus"
                }
                
            }
            catch {
                Write-SystemStatusLog "Failed to restart service $service - $($_.Exception.Message)" -Level 'ERROR'
                # Implement recovery options pattern (Query 10 research finding)
                Start-ServiceRecoveryAction -ServiceName $service -FailureReason $_.Exception.Message
            }
        }
        
        $successRate = [math]::Round(($successCount / $totalServices) * 100, 1)
        Write-SystemStatusLog "Cascade restart completed. Success rate: $successRate% ($successCount/$totalServices services)" -Level 'INFO'
        
        return @{
            Success = ($successCount -eq $totalServices)
            ServicesProcessed = $totalServices
            ServicesSuccessful = $successCount
            SuccessRate = $successRate
            RestartOrder = $restartOrder
        }
        
    }
    catch {
        Write-SystemStatusLog "Error in cascade restart for $ServiceName - $($_.Exception.Message)" -Level 'ERROR'
        return @{
            Success = $false
            ServicesProcessed = 0
            ServicesSuccessful = 0
            SuccessRate = 0
            Error = $_.Exception.Message
        }
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAy7EKsvIMZIy4qrxbVIkXLMd
# EnugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUOHuTi//Za5+x+1/V8+8UHCIRf98wDQYJKoZIhvcNAQEBBQAEggEARYTj
# H7suGW16dzQPobvxR/NBhzqgAm6zoJ4cmD30jsOKX//zCG1JPSL7OyjJxGV5XGUA
# HTznKPbRjEKCj+Ik5Zzp+MvY9o5zueZIH49kuiId6rh3OVat+Dx1T5Hsh/qvovWQ
# lTUGQvkoAnQ4VSxFwlqaFLqrjQskNZZ+tdU1i4v8D5oJEFuvbrboZvpX3BoS0AIq
# bPzdPgQWWib+8UE9uIvGi45fyBhduymr8y1fnBN480UTd/vn1tL93H6OS0v0Jg1P
# GSrPhKOuZiTCk/E64ktpM3Q7VDlVGiBYYrJCY53J80GI+qdyYoy7+aGv9ibqVcLk
# 1Dt+fghakpwxlBRNzA==
# SIG # End signature block
