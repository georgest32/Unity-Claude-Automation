# Start-RealAutonomy.ps1
# Start the working autonomous feedback loop that submits to Claude Code CLI
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "STARTING REAL AUTONOMOUS CLAUDE CODE CLI SYSTEM" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "This will:" -ForegroundColor White
Write-Host "1. Monitor Unity compilation errors continuously" -ForegroundColor Gray
Write-Host "2. Generate intelligent prompts when errors detected" -ForegroundColor Gray
Write-Host "3. Submit prompts to THIS Claude Code CLI window automatically" -ForegroundColor Gray
Write-Host "4. Process your responses and apply fixes" -ForegroundColor Gray
Write-Host "" -ForegroundColor White

try {
    # Load working modules
    Write-Host "Loading autonomous modules..." -ForegroundColor Yellow
    Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force
    Import-Module ".\Modules\Unity-Claude-SessionManager.psm1" -Force
    Import-Module ".\Modules\Unity-Claude-AutonomousStateTracker.psm1" -Force
    Write-Host "  All modules loaded successfully" -ForegroundColor Green
    
    # Create Unity test script with errors for immediate testing
    Write-Host "Creating Unity test script with compilation errors..." -ForegroundColor Yellow
    $testScript = @"
using UnityEngine;
using System.Collections.Generic;

// Autonomous system test script - contains intentional errors
public class AutonomousErrorTest : MonoBehaviour
{
    // Error 1: Missing semicolon
    public string message = "Testing autonomous system"
    
    // Error 2: Unknown type
    public MysteryType component;
    
    // Error 3: Wrong return type
    public int GetName()
    {
        return gameObject.name; // Should return string
    }
    
    // Error 4: Missing using statement
    void Start()
    {
        List<int> numbers = new List<int> {1, 2, 3};
        var filtered = numbers.Where(x => x > 1).ToList(); // Missing System.Linq
    }
}
"@
    
    $scriptPath = "C:\UnityProjects\Sound-and-Shoal\Dithering\Assets\Scripts\AutonomousErrorTest.cs"
    $testScript | Set-Content -Path $scriptPath -Encoding UTF8
    Write-Host "  Test script created: AutonomousErrorTest.cs" -ForegroundColor Green
    
    # Initialize session
    Write-Host "Initializing autonomous session..." -ForegroundColor Yellow
    $session = New-ConversationSession -SessionName "RealAutonomy" -SessionType "FullAutonomous"
    $sessionId = $session.Session.SessionId
    Write-Host "  Session ID: $sessionId" -ForegroundColor Green
    
    # Initialize state tracking
    $agentId = "RealAgent_$(Get-Date -Format 'HHmmss')"
    $stateResult = Initialize-AutonomousStateTracking -AgentId $agentId
    Write-Host "  Agent ID: $agentId" -ForegroundColor Green
    
    # Start the autonomous feedback loop
    Write-Host "" -ForegroundColor White
    Write-Host "STARTING AUTONOMOUS FEEDBACK LOOP..." -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    
    $loopResult = Start-AutonomousFeedbackLoop
    
    if ($loopResult.Success) {
        # Log session start
        Add-ConversationHistoryEntry -SessionId $sessionId -Type "SystemAction" -Content "Real autonomous feedback loop started - will submit prompts to Claude Code CLI"
        Set-AutonomousState -AgentId $agentId -NewState "Active" -Reason "Real autonomous operation initiated"
        
        Write-Host "" -ForegroundColor White
        Write-Host "🚀 REAL AUTONOMOUS SYSTEM NOW ACTIVE! 🚀" -ForegroundColor Green
        Write-Host "=======================================" -ForegroundColor Green
        Write-Host "" -ForegroundColor White
        Write-Host "The system is now:" -ForegroundColor Cyan
        Write-Host "✓ Monitoring Unity Editor.log for compilation errors" -ForegroundColor Green
        Write-Host "✓ Ready to generate intelligent prompts" -ForegroundColor Green
        Write-Host "✓ Ready to submit prompts to Claude Code CLI" -ForegroundColor Green
        Write-Host "✓ Ready to process your responses automatically" -ForegroundColor Green
        Write-Host "" -ForegroundColor White
        Write-Host "TEST SCENARIO:" -ForegroundColor Yellow
        Write-Host "1. Open Unity" -ForegroundColor White
        Write-Host "2. The test script has 4 compilation errors" -ForegroundColor White
        Write-Host "3. Unity will compile and generate errors" -ForegroundColor White
        Write-Host "4. This system will detect errors automatically" -ForegroundColor White
        Write-Host "5. It will generate and submit a prompt to THIS window" -ForegroundColor White
        Write-Host "6. Respond normally - the system processes your reply" -ForegroundColor White
        Write-Host "" -ForegroundColor White
        Write-Host "AUTONOMOUS OPERATION DETAILS:" -ForegroundColor Magenta
        Write-Host "Session ID: $sessionId" -ForegroundColor Gray
        Write-Host "Agent ID: $agentId" -ForegroundColor Gray
        Write-Host "Error monitoring: Unity Editor.log" -ForegroundColor Gray
        Write-Host "Target window: Claude Code CLI" -ForegroundColor Gray
        Write-Host "" -ForegroundColor White
        Write-Host "To stop autonomous mode: Press Ctrl+C or run Stop-AutonomousFeedbackLoop" -ForegroundColor Yellow
        Write-Host "To view status: The system will show activity in this window" -ForegroundColor Yellow
        Write-Host "" -ForegroundColor White
        Write-Host "🎯 AUTONOMOUS PROMPT SUBMISSION TO CLAUDE CODE CLI IS NOW LIVE! 🎯" -ForegroundColor Green
        
    } else {
        Write-Host "❌ Failed to start autonomous feedback loop" -ForegroundColor Red
    }
    
} catch {
    Write-Host "Error starting real autonomy: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to continue monitoring or Ctrl+C to stop..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUpj/NwfiJLitH5by2fzAYSSch
# t4agggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU4Ph7Hkrtg9lBMmiWovh/ig1JJpkwDQYJKoZIhvcNAQEBBQAEggEAOedF
# QyJLsd1MMjuRz1n5+Bo2JRekFmKYbbXWFgE4/cXWKNo+H4qnRupAID0lGgCer/Dv
# iM0ev+X4O0QF1zlV1wjf0RjLd/2WPl427NzCz4JsCPptDuy1lC7Y6pJzZtFUf5Qh
# B/oj5nRsa9v5h0/eyIIWhSoPJzHcN+7K8Mu8fzznlvJdfntTjxbtUSTMceV7nEZq
# wrzI1eJdth1+ms3fnsWxEsEVMV7ofa7qpl2PKcl6lTxzLVC7emUIm3B3HMON1oAI
# /qQC3kn1oMikNTo/vmFCWKkf4JVFDfu3AE5tkxSdGY/NLK9M9L9bZ8KYclg6EVTS
# Fc2kjk99qcSorQxLyA==
# SIG # End signature block
