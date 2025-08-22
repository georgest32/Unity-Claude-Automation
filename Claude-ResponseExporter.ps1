# Claude-ResponseExporter.ps1
# Export Claude Code CLI responses for autonomous system monitoring
# Run this script in Claude Code CLI window (Window 1) after receiving responses
# Date: 2025-08-18

param(
    [Parameter(Mandatory = $false)]
    [string]$ResponseType = "Success",
    
    [Parameter(Mandatory = $false)]
    [string]$Summary = "",
    
    [Parameter(Mandatory = $false)]
    [array]$ActionsTaken = @(),
    
    [Parameter(Mandatory = $false)]
    [array]$RemainingIssues = @(),
    
    [Parameter(Mandatory = $false)]
    [array]$Recommendations = @(),
    
    [Parameter(Mandatory = $false)]
    [string]$Confidence = "High",
    
    [Parameter(Mandatory = $false)]
    [bool]$RequiresFollowUp = $false,
    
    [Parameter(Mandatory = $false)]
    [string]$SessionId = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$Interactive
)

$exportPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\claude_responses.json"

function Export-ClaudeResponse {
    param(
        [string]$Type,
        [string]$SummaryText,
        [array]$Actions,
        [array]$Issues,
        [array]$Recommends,
        [string]$ConfidenceLevel,
        [bool]$FollowUp,
        [string]$Session
    )
    
    try {
        # Generate session ID if not provided
        if ([string]::IsNullOrEmpty($Session)) {
            $Session = "session_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        }
        
        # Create response entry
        $responseEntry = @{
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            sessionId = $Session
            promptType = "Debugging"  # Default for autonomous error resolution
            responseType = $Type
            summary = $SummaryText
            actionsTaken = $Actions
            remainingIssues = $Issues
            recommendations = $Recommends
            confidence = $ConfidenceLevel
            requiresFollowUp = $FollowUp
        }
        
        # Read existing responses or create new structure
        $responseData = @{
            responses = @()
            totalResponses = 0
            exportTime = ""
            lastSessionId = ""
        }
        
        if (Test-Path $exportPath) {
            try {
                $content = Get-Content $exportPath -Raw -Encoding UTF8
                if ($content[0] -eq [char]0xFEFF) {
                    $content = $content.Substring(1)
                }
                $responseData = $content | ConvertFrom-Json
                
                # Convert to proper array if needed
                if ($responseData.responses -isnot [array]) {
                    $responseData.responses = @($responseData.responses)
                }
            } catch {
                Write-Host "Warning: Could not read existing responses, creating new file" -ForegroundColor Yellow
            }
        }
        
        # Add new response
        $responseData.responses += $responseEntry
        $responseData.totalResponses = $responseData.responses.Count
        $responseData.exportTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $responseData.lastSessionId = $Session
        
        # Export to JSON
        $jsonContent = $responseData | ConvertTo-Json -Depth 4
        
        # Ensure directory exists
        $directory = Split-Path $exportPath -Parent
        if (-not (Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        
        # Write JSON file
        [System.IO.File]::WriteAllText($exportPath, $jsonContent, [System.Text.Encoding]::UTF8)
        
        Write-Host "[Claude-ResponseExporter] Response exported successfully!" -ForegroundColor Green
        Write-Host "  Type: $Type" -ForegroundColor Gray
        Write-Host "  Session: $Session" -ForegroundColor Gray  
        Write-Host "  Confidence: $ConfidenceLevel" -ForegroundColor Gray
        Write-Host "  Actions: $($Actions.Count)" -ForegroundColor Gray
        Write-Host "  Total Responses: $($responseData.totalResponses)" -ForegroundColor Gray
        Write-Host "  File: $exportPath" -ForegroundColor Gray
        
        return @{
            Success = $true
            SessionId = $Session
            ResponseCount = $responseData.totalResponses
        }
        
    } catch {
        Write-Host "[Claude-ResponseExporter] Export failed: $($_.Exception.Message)" -ForegroundColor Red
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Show-InteractiveMenu {
    Write-Host ""
    Write-Host "CLAUDE RESPONSE EXPORTER" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    Write-Host "Export Claude Code CLI response for autonomous monitoring" -ForegroundColor White
    Write-Host ""
    
    # Response Type
    Write-Host "1. Response Type:" -ForegroundColor Yellow
    Write-Host "   [S] Success - Fixes implemented successfully" -ForegroundColor Green
    Write-Host "   [P] Partial - Some fixes applied, issues remain" -ForegroundColor Yellow
    Write-Host "   [F] Failed - Unable to resolve errors" -ForegroundColor Red
    Write-Host "   [Q] Questions - Claude needs clarification" -ForegroundColor Cyan
    Write-Host "   [I] Instructions - Manual steps required" -ForegroundColor Magenta
    $typeChoice = Read-Host "Select response type (S/P/F/Q/I)"
    
    $responseType = switch ($typeChoice.ToUpper()) {
        "S" { "Success" }
        "P" { "Partial" }
        "F" { "Failed" }
        "Q" { "Questions" }
        "I" { "Instructions" }
        default { "Success" }
    }
    
    Write-Host ""
    Write-Host "2. Summary:" -ForegroundColor Yellow
    $summaryText = Read-Host "Brief summary of Claude's response"
    
    Write-Host ""
    Write-Host "3. Actions Taken:" -ForegroundColor Yellow
    Write-Host "   Enter actions one per line, empty line to finish:" -ForegroundColor Gray
    $actions = @()
    do {
        $action = Read-Host "Action"
        if (-not [string]::IsNullOrEmpty($action)) {
            $actions += $action
        }
    } while (-not [string]::IsNullOrEmpty($action))
    
    Write-Host ""
    Write-Host "4. Remaining Issues:" -ForegroundColor Yellow
    Write-Host "   Enter issues one per line, empty line to finish:" -ForegroundColor Gray
    $issues = @()
    do {
        $issue = Read-Host "Issue"
        if (-not [string]::IsNullOrEmpty($issue)) {
            $issues += $issue
        }
    } while (-not [string]::IsNullOrEmpty($issue))
    
    Write-Host ""
    Write-Host "5. Recommendations:" -ForegroundColor Yellow
    Write-Host "   Enter recommendations one per line, empty line to finish:" -ForegroundColor Gray
    $recommendations = @()
    do {
        $recommendation = Read-Host "Recommendation"
        if (-not [string]::IsNullOrEmpty($recommendation)) {
            $recommendations += $recommendation
        }
    } while (-not [string]::IsNullOrEmpty($recommendation))
    
    Write-Host ""
    Write-Host "6. Confidence Level:" -ForegroundColor Yellow
    Write-Host "   [H] High - Very confident in resolution" -ForegroundColor Green
    Write-Host "   [M] Medium - Moderately confident" -ForegroundColor Yellow
    Write-Host "   [L] Low - Uncertain about resolution" -ForegroundColor Red
    $confChoice = Read-Host "Select confidence (H/M/L)"
    
    $confidence = switch ($confChoice.ToUpper()) {
        "H" { "High" }
        "M" { "Medium" }
        "L" { "Low" }
        default { "Medium" }
    }
    
    Write-Host ""
    Write-Host "7. Follow-up Required:" -ForegroundColor Yellow
    $followUpChoice = Read-Host "Requires follow-up action? (y/n)"
    $requiresFollowUp = $followUpChoice.ToLower() -eq "y"
    
    return Export-ClaudeResponse -Type $responseType -SummaryText $summaryText -Actions $actions -Issues $issues -Recommends $recommendations -ConfidenceLevel $confidence -FollowUp $requiresFollowUp -Session $SessionId
}

# Main execution
if ($Interactive) {
    $result = Show-InteractiveMenu
} else {
    $result = Export-ClaudeResponse -Type $ResponseType -SummaryText $Summary -Actions $ActionsTaken -Issues $RemainingIssues -Recommends $Recommendations -ConfidenceLevel $Confidence -FollowUp $RequiresFollowUp -Session $SessionId
}

if ($result.Success) {
    Write-Host ""
    Write-Host "Response exported! Autonomous system will monitor this file." -ForegroundColor Green
    Write-Host "Session ID: $($result.SessionId)" -ForegroundColor Cyan
} else {
    Write-Host "Export failed: $($result.Error)" -ForegroundColor Red
    exit 1
}

# Quick usage examples
Write-Host ""
Write-Host "USAGE EXAMPLES:" -ForegroundColor Cyan
Write-Host "Interactive mode: .\Claude-ResponseExporter.ps1 -Interactive" -ForegroundColor White
Write-Host "Quick success: .\Claude-ResponseExporter.ps1 -ResponseType 'Success' -Summary 'Fixed CS0116 error' -ActionsTaken @('Edited file', 'Removed syntax error')" -ForegroundColor White
Write-Host "With follow-up: .\Claude-ResponseExporter.ps1 -ResponseType 'Partial' -Summary 'Some fixes applied' -RequiresFollowUp `$true" -ForegroundColor White
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdNmbB/U2MCAytn7XkkycMvBA
# oY2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUix8q3tP91N0sA1967lEN4KlihZowDQYJKoZIhvcNAQEBBQAEggEAPJkE
# YywdUlGJOgIxVvLlU8q+JqhQqsMU3J1xPwdYuFMo/Z1gA+ABBgVMBQOJz/z10q6f
# bpMBY9CSYXhG4DHURmMEMFIHKNJA4csLoRF/UhTC11GXmJhEHzvVvaDLLDjYfTKf
# 1N1i0xR7f0vqU8K0Kql1KE998nh5eZ0dQ8JbYXfRt4ZepVo9QH2Ccgvoc9b4uzk0
# rrMzywTvABU+IKrvGMupwZ+R95+PG4mPpI6GQHKon6l7YU3HaJdB0+nQgCf4e3LW
# FuEyVPRuJWF8TKX7BvFiPH8RrIsm3TbD7W5J2DCslbY1m7EXNX2ZN+NE9Gq583Bj
# KuC74ZpXLcdB3UC0/w==
# SIG # End signature block
