# Test-CLIOrchestratorStatus.ps1
# Functions for monitoring and restarting the CLIOrchestrator
# Date: 2025-08-25

function Test-CLIOrchestratorStatus {
    <#
    .SYNOPSIS
    Tests if the CLIOrchestrator is running
    
    .DESCRIPTION
    Checks if the CLIOrchestrator process is alive and responding
    
    .OUTPUTS
    Boolean indicating if orchestrator is running
    #>
    [CmdletBinding()]
    param()
    
    Write-SystemStatusLog "========== TEST-CLIORCHESTRATORSTATUS START ==========" -Level 'INFO'
    Write-SystemStatusLog "Testing CLIOrchestrator status at $(Get-Date -Format 'HH:mm:ss.fff')..." -Level 'DEBUG'
    
    try {
        # Read current status
        Write-SystemStatusLog "Reading system status..." -Level 'DEBUG'
        $status = Read-SystemStatus
        
        if (-not $status) {
            Write-SystemStatusLog "Read-SystemStatus returned NULL" -Level 'ERROR'
            return $false
        }
        
        if (-not $status.Subsystems) {
            Write-SystemStatusLog "No Subsystems property in status" -Level 'ERROR'
            return $false
        }
        
        Write-SystemStatusLog "Status has $($status.Subsystems.Count) subsystems registered" -Level 'DEBUG'
        Write-SystemStatusLog "Subsystem keys: $($status.Subsystems.Keys -join ', ')" -Level 'DEBUG'
        
        # Check if CLIOrchestrator is registered (try both naming conventions)
        $agentKey = $null
        if ($status.Subsystems.ContainsKey("CLIOrchestrator")) {
            $agentKey = "CLIOrchestrator"
            Write-SystemStatusLog "Found key 'CLIOrchestrator'" -Level 'DEBUG'
        }
        elseif ($status.Subsystems.ContainsKey("Unity-Claude-CLIOrchestrator")) {
            $agentKey = "Unity-Claude-CLIOrchestrator"
            Write-SystemStatusLog "Found key 'Unity-Claude-CLIOrchestrator'" -Level 'DEBUG'
        }
        elseif ($status.Subsystems.ContainsKey("AutonomousAgent")) {
            # Legacy support - still check for old name
            $agentKey = "AutonomousAgent"
            Write-SystemStatusLog "Found legacy key 'AutonomousAgent'" -Level 'DEBUG'
        }
        
        if (-not $agentKey) {
            Write-SystemStatusLog "CLIOrchestrator NOT FOUND in subsystems (checked 'CLIOrchestrator', 'Unity-Claude-CLIOrchestrator', and 'AutonomousAgent')" -Level 'WARN'
            Write-SystemStatusLog "Available subsystem keys: $($status.Subsystems.Keys -join ', ')" -Level 'WARN'
            return $false
        }
        
        $agentInfo = $status.Subsystems[$agentKey]
        Write-SystemStatusLog "Found CLIOrchestrator registered as: '$agentKey'" -Level 'INFO'
        
        # Check if we have a process ID
        if (-not $agentInfo.ProcessId) {
            Write-SystemStatusLog "CLIOrchestrator has no ProcessId recorded" -Level 'WARN'
            return $false
        }
        
        # Check if process is actually running
        $process = Get-Process -Id $agentInfo.ProcessId -ErrorAction SilentlyContinue
        
        if (-not $process) {
            Write-SystemStatusLog "CLIOrchestrator process $($agentInfo.ProcessId) is not running" -Level 'WARN'
            return $false
        }
        
        # Check heartbeat (if it's been more than 5 minutes, consider it unhealthy)
        if ($agentInfo.LastHeartbeat) {
            $lastHeartbeat = [DateTime]::ParseExact($agentInfo.LastHeartbeat, 'yyyy-MM-dd HH:mm:ss.fff', $null)
            $timeSinceHeartbeat = (Get-Date) - $lastHeartbeat
            
            if ($timeSinceHeartbeat.TotalMinutes -gt 5) {
                Write-SystemStatusLog "CLIOrchestrator heartbeat is stale (last: $($agentInfo.LastHeartbeat))" -Level 'WARN'
                return $false
            }
        }
        
        Write-SystemStatusLog "CLIOrchestrator is RUNNING (PID: $($agentInfo.ProcessId))" -Level 'INFO'
        Write-SystemStatusLog "========== TEST-CLIORCHESTRATORSTATUS END (RUNNING) ==========" -Level 'INFO'
        return $true
    }
    catch {
        Write-SystemStatusLog "EXCEPTION testing CLIOrchestrator status: $_" -Level 'ERROR'
        Write-SystemStatusLog "Exception type: $($_.Exception.GetType().FullName)" -Level 'ERROR'
        Write-SystemStatusLog "Stack trace: $($_.ScriptStackTrace)" -Level 'ERROR'
        Write-SystemStatusLog "========== TEST-CLIORCHESTRATORSTATUS END (ERROR) ==========" -Level 'ERROR'
        return $false
    }
}

function Start-CLIOrchestratorSafe {
    <#
    .SYNOPSIS
    Safely starts the CLIOrchestrator, checking if it's already running
    
    .DESCRIPTION
    Starts the CLIOrchestrator if not already running, with proper registration
    
    .OUTPUTS
    Boolean indicating success
    #>
    [CmdletBinding()]
    param()
    
    Write-SystemStatusLog "========== START-CLIORCHESTRATORAFE BEGIN ==========" -Level 'INFO'
    Write-SystemStatusLog "Starting CLIOrchestrator at $(Get-Date -Format 'HH:mm:ss.fff')..." -Level 'INFO'
    
    try {
        # First check if already running
        if (Test-CLIOrchestratorStatus) {
            Write-SystemStatusLog "CLIOrchestrator is already running - no action needed" -Level 'INFO'
            Write-SystemStatusLog "========== START-CLIORCHESTRATORAFE END (ALREADY RUNNING) ==========" -Level 'INFO'
            return $true
        }
        
        Write-SystemStatusLog "CLIOrchestrator is NOT running - proceeding with restart" -Level 'INFO'
        
        # Read current status to clear any stale registrations
        $status = Read-SystemStatus
        
        # Look for the start script (prioritize current naming convention)
        $startScript = $null
        $primaryScript = ".\Start-CLIOrchestrator.ps1"
        $fixedScript = ".\Start-CLIOrchestrator-Fixed.ps1"
        $legacyScript = ".\Start-AutonomousMonitoring-Simple.ps1"
        
        if (Test-Path $primaryScript) {
            $startScript = $primaryScript
            Write-SystemStatusLog "Using primary orchestrator: $primaryScript" -Level 'INFO'
        }
        elseif (Test-Path $fixedScript) {
            $startScript = $fixedScript
            Write-SystemStatusLog "Using fixed version: $fixedScript" -Level 'INFO'
        }
        elseif (Test-Path $legacyScript) {
            $startScript = $legacyScript
            Write-SystemStatusLog "Using legacy version: $legacyScript" -Level 'WARN'
        }
        else {
            Write-SystemStatusLog "No start script found!" -Level 'ERROR'
            Write-SystemStatusLog "Searched for: $primaryScript, $fixedScript, $legacyScript" -Level 'ERROR'
            Write-SystemStatusLog "========== START-CLIORCHESTRATORAFE END (NO SCRIPT) ==========" -Level 'ERROR'
            return $false
        }
        
        Write-SystemStatusLog "Starting CLIOrchestrator from: $startScript" -Level 'INFO'
        
        # Start the process
        $startInfo = @{
            FilePath = "pwsh.exe"
            ArgumentList = @(
                "-NoExit",
                "-ExecutionPolicy", "Bypass",
                "-File", $startScript
            )
            WindowStyle = "Normal"
            PassThru = $true
        }
        
        $process = Start-Process @startInfo
        
        if ($process -and $process.Id) {
            Write-SystemStatusLog "PowerShell wrapper started with PID: $($process.Id)" -Level 'INFO'
            
            # Wait for CLIOrchestrator to self-register
            Write-SystemStatusLog "Waiting for CLIOrchestrator to self-register..." -Level 'INFO'
            Start-Sleep -Seconds 5
            
            # Check if it registered successfully
            if (Test-CLIOrchestratorStatus) {
                Write-SystemStatusLog "CLIOrchestrator started successfully and is running" -Level 'OK'
                Write-SystemStatusLog "========== START-CLIORCHESTRATORAFE END (SUCCESS) ==========" -Level 'OK'
                
                # Log the restart event
                $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - CLIOrchestrator restarted by Start-CLIOrchestratorSafe"
                $logEntry | Add-Content -Path ".\agent_restart_log.txt"
                
                return $true
            }
            else {
                Write-SystemStatusLog "CLIOrchestrator failed to register after starting" -Level 'ERROR'
                Write-SystemStatusLog "========== START-CLIORCHESTRATORAFE END (FAILED TO REGISTER) ==========" -Level 'ERROR'
                return $false
            }
        }
        else {
            Write-SystemStatusLog "Failed to start PowerShell process" -Level 'ERROR'
            Write-SystemStatusLog "========== START-CLIORCHESTRATORAFE END (PROCESS FAILED) ==========" -Level 'ERROR'
            return $false
        }
    }
    catch {
        Write-SystemStatusLog "EXCEPTION starting CLIOrchestrator: $_" -Level 'ERROR'
        Write-SystemStatusLog "Exception type: $($_.Exception.GetType().FullName)" -Level 'ERROR'
        Write-SystemStatusLog "Stack trace: $($_.ScriptStackTrace)" -Level 'ERROR'
        Write-SystemStatusLog "========== START-CLIORCHESTRATORAFE END (EXCEPTION) ==========" -Level 'ERROR'
        return $false
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Test-CLIOrchestratorStatus',
    'Start-CLIOrchestratorSafe'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBUFqHPPkaqleCD
# yhY/LQa7lXjI63HytnokyhPAz9ZOlKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIH7O6FEoUocJRk8OihGTLsrm
# 5KcuitZSmbmROmdhdIuwMA0GCSqGSIb3DQEBAQUABIIBACf8ste2/B5h1QtQW2wY
# 5hbGElg67UrErWLmHKWIxTunyOuk4Prg0WCVupMTm+Cs+BAv2XbDsbFAbTGjrPpW
# KmD9ejUEDTh7aCruX7Eu/TTdWMOMbrVVWbDGbiZoC2CAFWWxcF1E9n2V18z0PLcZ
# FfrzPoypZmmBdfhB86OC84o2hqsoAVQIWbJ+RxxnfQuRzdcOp5lUWhnZilHsPWPh
# 8cyK4FHU3WFIWePCLPIXeSswYpihIf9CLiwuX+FRxq+WsZOu56mo6GPfvybt7jGO
# +5nRWj/BZZdvQ8o2VOA+GwEr1mbgeN4ToCccldruVSTbcAgAVhvMLLxzky7U4BYL
# V98=
# SIG # End signature block
