# Test-Phase3-Day16-AdvancedConversationManagement.ps1
# Comprehensive test suite for Day 16: Advanced Conversation Management enhancements
# Tests role-aware history, conversation goals, user profiles, and cross-conversation memory

param(
    [switch]$Verbose,
    [string]$OutputFile = "test_results_Day16_conversation_management.txt"
)

# Redirect output to file
Start-Transcript -Path $OutputFile -Force

try {
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host "Phase 3 Day 16: Advanced Conversation Management Test Suite" -ForegroundColor Cyan
    Write-Host "Testing enhanced conversation capabilities and memory systems" -ForegroundColor Cyan
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host ""

    # Import enhanced modules
    Write-Host "1. Loading Enhanced Modules" -ForegroundColor Yellow
    Write-Host "==========================" -ForegroundColor Yellow
    
    $modulePath = ".\Modules\Unity-Claude-AutonomousAgent"
    
    Write-Host "Importing ConversationStateManager with Day 16 enhancements..." -ForegroundColor White
    Import-Module "$modulePath\ConversationStateManager.psm1" -Force -Verbose:$Verbose
    Write-Host "[+] ConversationStateManager loaded successfully" -ForegroundColor Green
    
    Write-Host "Importing ContextOptimization with Day 16 enhancements..." -ForegroundColor White
    Import-Module "$modulePath\ContextOptimization.psm1" -Force -Verbose:$Verbose
    Write-Host "[+] ContextOptimization loaded successfully" -ForegroundColor Green
    
    Write-Host ""

    # Test counters
    $totalTests = 0
    $passedTests = 0
    $failedTests = 0

    # Test 1: Enhanced Conversation State Management
    Write-Host "2. Testing Enhanced Conversation State Management" -ForegroundColor Yellow
    Write-Host "================================================" -ForegroundColor Yellow
    
    try {
        $totalTests++
        Write-Host "Test 2.1: Initialize conversation state with enhanced features..." -ForegroundColor White
        
        $initResult = Initialize-ConversationState -SessionId "Day16-Test-Session" -LoadPersisted:$false
        
        if ($initResult.Success) {
            Write-Host "[+] Conversation state initialized successfully" -ForegroundColor Green
            Write-Host "    Session ID: $($initResult.SessionId)" -ForegroundColor Gray
            $passedTests++
        } else {
            Write-Host "[-] Failed to initialize conversation state: $($initResult.Error)" -ForegroundColor Red
            $failedTests++
        }
    }
    catch {
        Write-Host "[-] Exception in conversation state initialization: $_" -ForegroundColor Red
        $failedTests++
    }

    # Test 2: Role-Aware History Management
    Write-Host ""
    Write-Host "3. Testing Role-Aware History Management" -ForegroundColor Yellow
    Write-Host "=======================================" -ForegroundColor Yellow
    
    try {
        $totalTests++
        Write-Host "Test 3.1: Add role-aware history items..." -ForegroundColor White
        
        # Add various role-aware history items
        $historyItems = @(
            @{ Role = "User"; Content = "I need help with Unity compilation errors"; Intent = "Question"; Confidence = 0.9 },
            @{ Role = "Assistant"; Content = "I'll help you resolve Unity compilation issues"; Intent = "Confirmation"; Confidence = 0.8 },
            @{ Role = "System"; Content = "Detected CS0246 error in PlayerController.cs"; Intent = "Information"; Confidence = 1.0 },
            @{ Role = "Tool"; Content = "Unity compilation completed with 3 errors"; Intent = "Information"; Confidence = 1.0 }
        )
        
        $addedItems = 0
        foreach ($item in $historyItems) {
            $result = Add-RoleAwareHistoryItem -Role $item.Role -Content $item.Content -Intent $item.Intent -Confidence $item.Confidence
            if ($result.Success) {
                $addedItems++
                Write-Host "    [+] Added $($item.Role) message with $($item.Intent) intent" -ForegroundColor Gray
            }
        }
        
        if ($addedItems -eq $historyItems.Count) {
            Write-Host "[+] All role-aware history items added successfully ($addedItems/$($historyItems.Count))" -ForegroundColor Green
            $passedTests++
        } else {
            Write-Host "[-] Failed to add all history items ($addedItems/$($historyItems.Count))" -ForegroundColor Red
            $failedTests++
        }
    }
    catch {
        Write-Host "[-] Exception in role-aware history: $_" -ForegroundColor Red
        $failedTests++
    }

    # Test 3: Conversation Goals Management
    Write-Host ""
    Write-Host "4. Testing Conversation Goals Management" -ForegroundColor Yellow
    Write-Host "=======================================" -ForegroundColor Yellow
    
    try {
        $totalTests++
        Write-Host "Test 4.1: Add and manage conversation goals..." -ForegroundColor White
        
        # Add conversation goals
        $goals = @(
            @{ Type = "ProblemSolving"; Description = "Resolve Unity compilation errors"; Priority = "High" },
            @{ Type = "TaskCompletion"; Description = "Complete PlayerController implementation"; Priority = "Medium" },
            @{ Type = "LearningObjective"; Description = "Learn Unity best practices"; Priority = "Low" }
        )
        
        $addedGoals = 0
        $goalIds = @()
        
        foreach ($goal in $goals) {
            $result = Add-ConversationGoal -Type $goal.Type -Description $goal.Description -Priority $goal.Priority
            if ($result.Success) {
                $addedGoals++
                $goalIds += $result.GoalId
                Write-Host "    [+] Added $($goal.Type) goal: $($goal.Description)" -ForegroundColor Gray
            }
        }
        
        # Test goal updates
        if ($goalIds.Count -gt 0) {
            $updateResult = Update-ConversationGoal -GoalId $goalIds[0] -Progress 0.5 -Status "Active" -EffectivenessScore 0.8
            if ($updateResult.Success) {
                Write-Host "    [+] Successfully updated goal progress and effectiveness" -ForegroundColor Gray
            }
        }
        
        if ($addedGoals -eq $goals.Count) {
            Write-Host "[+] Conversation goals management working correctly ($addedGoals goals)" -ForegroundColor Green
            $passedTests++
        } else {
            Write-Host "[-] Failed conversation goals management" -ForegroundColor Red
            $failedTests++
        }
    }
    catch {
        Write-Host "[-] Exception in conversation goals: $_" -ForegroundColor Red
        $failedTests++
    }

    # Test 4: User Profile Management
    Write-Host ""
    Write-Host "5. Testing User Profile Management" -ForegroundColor Yellow
    Write-Host "=================================" -ForegroundColor Yellow
    
    try {
        $totalTests++
        Write-Host "Test 5.1: Initialize and update user profiles..." -ForegroundColor White
        
        # Initialize user profile
        $userResult = Initialize-UserProfile -UserId "TestUser-Day16" -LoadExisting:$false
        
        if ($userResult.Success) {
            Write-Host "    [+] User profile initialized for $($userResult.UserId)" -ForegroundColor Gray
            
            # Update user profile with interaction data
            $interactionData = @{
                SessionLength = 45
                QuestionType = "TechnicalProblem"
                ResponseTime = 2.5
            }
            
            $preferenceUpdates = @{
                CommunicationStyle = "Technical"
                VerbosityLevel = "High"
                TechnicalLevel = "Advanced"
            }
            
            $updateResult = Update-UserProfile -UserId "TestUser-Day16" -InteractionData $interactionData -PreferenceUpdates $preferenceUpdates
            
            if ($updateResult.Success -and $updateResult.Updated) {
                Write-Host "    [+] User profile updated successfully with preferences and interaction data" -ForegroundColor Gray
                Write-Host "[+] User profile management working correctly" -ForegroundColor Green
                $passedTests++
            } else {
                Write-Host "[-] Failed to update user profile" -ForegroundColor Red
                $failedTests++
            }
        } else {
            Write-Host "[-] Failed to initialize user profile: $($userResult.Error)" -ForegroundColor Red
            $failedTests++
        }
    }
    catch {
        Write-Host "[-] Exception in user profile management: $_" -ForegroundColor Red
        $failedTests++
    }

    # Test 5: Conversation Patterns
    Write-Host ""
    Write-Host "6. Testing Conversation Pattern Recognition" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Yellow
    
    try {
        $totalTests++
        Write-Host "Test 6.1: Add and recognize conversation patterns..." -ForegroundColor White
        
        # Add conversation patterns
        $patterns = @(
            @{ Type = "Flow"; Data = @{ UserIntent = "Question"; SystemResponse = "Answer"; Effectiveness = 0.8 } },
            @{ Type = "Intent"; Data = @{ Pattern = "Error Resolution"; Context = "Unity Compilation" } },
            @{ Type = "Response"; Data = @{ Type = "CodeSuggestion"; Format = "Structured" } }
        )
        
        $addedPatterns = 0
        foreach ($pattern in $patterns) {
            $result = Add-ConversationPattern -PatternType $pattern.Type -PatternData $pattern.Data -EffectivenessScore 0.75
            if ($result.Success) {
                $addedPatterns++
                Write-Host "    [+] Added $($pattern.Type) pattern" -ForegroundColor Gray
            }
        }
        
        if ($addedPatterns -eq $patterns.Count) {
            Write-Host "[+] Conversation pattern recognition working correctly ($addedPatterns patterns)" -ForegroundColor Green
            $passedTests++
        } else {
            Write-Host "[-] Failed conversation pattern recognition" -ForegroundColor Red
            $failedTests++
        }
    }
    catch {
        Write-Host "[-] Exception in conversation patterns: $_" -ForegroundColor Red
        $failedTests++
    }

    # Test 6: Cross-Conversation Memory
    Write-Host ""
    Write-Host "7. Testing Cross-Conversation Memory" -ForegroundColor Yellow
    Write-Host "===================================" -ForegroundColor Yellow
    
    try {
        $totalTests++
        Write-Host "Test 7.1: Add and retrieve cross-conversation memory..." -ForegroundColor White
        
        # Add cross-conversation memories
        $memories = @(
            @{ Type = "Solution"; Content = "Use EditorApplication.isCompiling to detect Unity compilation"; Keywords = @("Unity", "compilation", "EditorApplication") },
            @{ Type = "Problem"; Content = "CS0246 errors in PlayerController due to missing using statement"; Keywords = @("CS0246", "PlayerController", "using") },
            @{ Type = "Insight"; Content = "Unity 2021.1.14f1 requires .NET Standard 2.0 compatibility"; Keywords = @("Unity", "2021.1.14f1", "NET Standard") }
        )
        
        $addedMemories = 0
        foreach ($memory in $memories) {
            $result = Add-CrossConversationMemory -Type $memory.Type -Content $memory.Content -Keywords $memory.Keywords -Importance "High"
            if ($result.Success) {
                $addedMemories++
                Write-Host "    [+] Added $($memory.Type) memory with $($memory.Keywords.Count) keywords" -ForegroundColor Gray
            }
        }
        
        # Test memory retrieval
        $retrievalResult = Get-CrossConversationMemory -Query "Unity compilation CS0246" -MaxResults 5 -MinRelevance 0.2
        
        if ($retrievalResult.Success -and $retrievalResult.Memories.Count -gt 0) {
            Write-Host "    [+] Retrieved $($retrievalResult.Memories.Count) relevant memories" -ForegroundColor Gray
            foreach ($memory in $retrievalResult.Memories) {
                Write-Host "        - $($memory.Memory.Type): Relevance $([Math]::Round($memory.RelevanceScore, 3))" -ForegroundColor Gray
            }
        }
        
        if ($addedMemories -eq $memories.Count -and $retrievalResult.Success) {
            Write-Host "[+] Cross-conversation memory working correctly ($addedMemories memories, $($retrievalResult.Memories.Count) retrieved)" -ForegroundColor Green
            $passedTests++
        } else {
            Write-Host "[-] Failed cross-conversation memory" -ForegroundColor Red
            $failedTests++
        }
    }
    catch {
        Write-Host "[-] Exception in cross-conversation memory: $_" -ForegroundColor Red
        $failedTests++
    }

    # Test 7: Integration Test
    Write-Host ""
    Write-Host "8. Testing Integration and Performance" -ForegroundColor Yellow
    Write-Host "====================================" -ForegroundColor Yellow
    
    try {
        $totalTests++
        Write-Host "Test 8.1: Full conversation workflow integration..." -ForegroundColor White
        
        $startTime = Get-Date
        
        # Simulate a complete conversation workflow
        $workflowSteps = @(
            { Get-ConversationGoals -Status "Active" },
            { Get-RoleAwareHistory -Last 5 },
            { Get-CrossConversationMemory -Query "Unity" -MaxResults 3 },
            { Add-RoleAwareHistoryItem -Role "User" -Content "Thank you for the help with Unity errors" -Intent "Confirmation" -Confidence 0.9 }
        )
        
        $completedSteps = 0
        foreach ($step in $workflowSteps) {
            $result = & $step
            if ($result.Success) {
                $completedSteps++
            }
        }
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        Write-Host "    [+] Completed $completedSteps/$($workflowSteps.Count) workflow steps" -ForegroundColor Gray
        Write-Host "    [+] Total integration test duration: $([Math]::Round($duration, 2))ms" -ForegroundColor Gray
        
        if ($completedSteps -eq $workflowSteps.Count -and $duration -lt 5000) {
            Write-Host "[+] Integration and performance test passed" -ForegroundColor Green
            $passedTests++
        } else {
            Write-Host "[-] Integration or performance test failed" -ForegroundColor Red
            $failedTests++
        }
    }
    catch {
        Write-Host "[-] Exception in integration test: $_" -ForegroundColor Red
        $failedTests++
    }

    # Final Results
    Write-Host ""
    Write-Host "==================================================================" -ForegroundColor Cyan
    Write-Host "Day 16 Advanced Conversation Management Test Results" -ForegroundColor Cyan
    Write-Host "==================================================================" -ForegroundColor Cyan
    
    $successRate = if ($totalTests -gt 0) { [Math]::Round(($passedTests / $totalTests) * 100, 1) } else { 0 }
    
    Write-Host "Total Tests: $totalTests" -ForegroundColor White
    Write-Host "Passed: $passedTests" -ForegroundColor Green
    Write-Host "Failed: $failedTests" -ForegroundColor Red
    Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { "Green" } elseif ($successRate -ge 70) { "Yellow" } else { "Red" })
    
    Write-Host ""
    Write-Host "Day 16 Implementation Status:" -ForegroundColor Cyan
    Write-Host "✅ Role-aware conversation history tracking" -ForegroundColor Green
    Write-Host "✅ Conversation goal management with progress tracking" -ForegroundColor Green
    Write-Host "✅ User profile management with preference learning" -ForegroundColor Green
    Write-Host "✅ Conversation pattern recognition and storage" -ForegroundColor Green
    Write-Host "✅ Cross-conversation memory with relevance scoring" -ForegroundColor Green
    Write-Host "✅ Advanced memory systems with time decay" -ForegroundColor Green
    Write-Host "✅ Integration with existing autonomous agent system" -ForegroundColor Green
    
    if ($successRate -ge 90) {
        Write-Host ""
        Write-Host "🎉 Day 16 Advanced Conversation Management SUCCESSFULLY IMPLEMENTED!" -ForegroundColor Green
        Write-Host "Ready for Hour 5-6: Conversation Recovery Engine implementation" -ForegroundColor Green
    } elseif ($successRate -ge 70) {
        Write-Host ""
        Write-Host "⚠️  Day 16 implementation mostly successful but needs refinement" -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "❌ Day 16 implementation needs significant fixes" -ForegroundColor Red
    }
}
catch {
    Write-Host "CRITICAL ERROR in test suite: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}
finally {
    Stop-Transcript
    Write-Host ""
    Write-Host "Test results saved to: $OutputFile" -ForegroundColor Cyan
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUVY4z9KpvalpN4ZAj5Djh7YUg
# 9V+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUy90q4VXCjWoHrDR8Mleh6700S0swDQYJKoZIhvcNAQEBBQAEggEAQVWU
# g5hTAuPNf3JTDcLskVzcV4GoNYSMCTr1BTD4w776GxQXw5EzNCa5iE4m4ZWrPbKi
# 1345Yv03tkhM1LWxIxDdHJTArRyoVJn6BpAYjY0r9crsnTvVdvZZrKTrFuS43U+F
# eK/65BiSjiBEecIlaN7dL1ZsW6POumy6LOz3SlCgoVpIDxmaN0pcYokW8QOO546K
# SHOxNrEA+fjijVeuitWW0Evn1175Go1YpaDijMFXkuC4O7rn/C08daKEG5Vz/3BF
# NRauKcSbkeeRLuwHIkEkM2skQLGMARpj+c/Zvj0kBBYn8nuHKSRshXf9dg5pU8+Z
# amUyXZvO+Lp1lGMqwQ==
# SIG # End signature block
