# PromptTemplateSystem.psm1
# Template management and rendering for intelligent prompt engine
# Refactored component from IntelligentPromptEngine.psm1
# Component: Template system and rendering (350 lines)

#region Template Management System

function New-PromptTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$TemplateType,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$ResultAnalysis,
        
        [Parameter()]
        [hashtable]$ConversationContext = @{},
        
        [Parameter()]
        [hashtable]$HistoricalData = @{}
    )
    
    Write-AgentLog -Message "Creating prompt template for type: $TemplateType" -Level "DEBUG" -Component "PromptTemplate"
    
    try {
        $config = Get-PromptEngineConfig
        $template = @{
            Type = $TemplateType
            Content = ""
            Metadata = @{
                CreatedAt = Get-Date
                Confidence = 0.0
                ComponentsUsed = @()
            }
            Sections = @{}
        }
        
        switch ($TemplateType) {
            'Debugging' {
                $template = New-DebuggingPromptTemplate -ResultAnalysis $ResultAnalysis -Context $ConversationContext
            }
            'Test Results' {
                $template = New-TestResultsPromptTemplate -ResultAnalysis $ResultAnalysis -Context $ConversationContext
            }
            'Continue' {
                $template = New-ContinuePromptTemplate -ResultAnalysis $ResultAnalysis -Context $ConversationContext
            }
            'ARP' {
                $template = New-ARPPromptTemplate -ResultAnalysis $ResultAnalysis -Context $ConversationContext -HistoricalData $HistoricalData
            }
            default {
                Write-AgentLog -Message "Unknown template type: $TemplateType, using default" -Level "WARNING" -Component "PromptTemplate"
                $template = New-DefaultPromptTemplate -ResultAnalysis $ResultAnalysis -Context $ConversationContext
            }
        }
        
        Write-AgentLog -Message "Prompt template created successfully: $($template.Type)" -Level "INFO" -Component "PromptTemplate"
        
        return @{
            Success = $true
            Template = $template
            Error = $null
        }
    }
    catch {
        Write-AgentLog -Message "Prompt template creation failed: $_" -Level "ERROR" -Component "PromptTemplate"
        return @{
            Success = $false
            Template = $null
            Error = $_.ToString()
        }
    }
}

function New-DebuggingPromptTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$ResultAnalysis,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    Write-AgentLog -Message "Creating debugging prompt template" -Level "DEBUG" -Component "DebuggingTemplate"
    
    $template = @{
        Type = "Debugging"
        Content = ""
        Metadata = @{
            CreatedAt = Get-Date
            Confidence = 0.85
            ComponentsUsed = @("Error Analysis", "Context Integration")
        }
        Sections = @{}
    }
    
    # Build debugging prompt sections
    $sections = @{}
    
    # Error summary section
    if ($ResultAnalysis.Analysis.ErrorMessages -and $ResultAnalysis.Analysis.ErrorMessages.Count -gt 0) {
        $errorSummary = "## Error Analysis`n`n"
        $errorSummary += "The following errors were encountered:`n"
        foreach ($error in $ResultAnalysis.Analysis.ErrorMessages) {
            $errorSummary += "- $error`n"
        }
        $sections['ErrorSummary'] = $errorSummary
    }
    
    # Context section
    if ($Context.Count -gt 0) {
        $contextSection = "## Current Context`n`n"
        if ($Context.ContainsKey('LastCommand')) {
            $contextSection += "**Last Command**: $($Context.LastCommand)`n"
        }
        if ($Context.ContainsKey('WorkingDirectory')) {
            $contextSection += "**Working Directory**: $($Context.WorkingDirectory)`n"
        }
        $sections['Context'] = $contextSection
    }
    
    # Debugging request
    $debugRequest = "## Debugging Request`n`n"
    $debugRequest += "Please analyze the errors above and provide:"
    $debugRequest += "`n1. **Root Cause Analysis**: What caused these errors?"
    $debugRequest += "`n2. **Specific Solutions**: Step-by-step fixes for each error"
    $debugRequest += "`n3. **Verification Steps**: How to confirm the fixes work"
    $debugRequest += "`n4. **Prevention**: How to avoid similar issues in the future"
    $sections['DebugRequest'] = $debugRequest
    
    # Combine sections
    $template.Sections = $sections
    $template.Content = ($sections.Values -join "`n`n")
    
    return $template
}

function New-TestResultsPromptTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$ResultAnalysis,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    Write-AgentLog -Message "Creating test results prompt template" -Level "DEBUG" -Component "TestResultsTemplate"
    
    $template = @{
        Type = "Test Results"
        Content = ""
        Metadata = @{
            CreatedAt = Get-Date
            Confidence = 0.80
            ComponentsUsed = @("Result Analysis", "Pattern Recognition")
        }
        Sections = @{}
    }
    
    # Build test results prompt sections
    $sections = @{}
    
    # Results summary
    $resultsSummary = "## Test Results Summary`n`n"
    $resultsSummary += "**Classification**: $($ResultAnalysis.Analysis.Classification)`n"
    $resultsSummary += "**Severity**: $($ResultAnalysis.Analysis.Severity)`n"
    $resultsSummary += "**Confidence**: $($ResultAnalysis.Analysis.Confidence * 100)%`n"
    $sections['ResultsSummary'] = $resultsSummary
    
    # Pattern analysis
    if ($ResultAnalysis.Analysis.Patterns -and $ResultAnalysis.Analysis.Patterns.Count -gt 0) {
        $patternsSection = "## Identified Patterns`n`n"
        foreach ($pattern in $ResultAnalysis.Analysis.Patterns) {
            $patternsSection += "- **$($pattern.Type)**: $($pattern.Description) (Confidence: $($pattern.Confidence * 100)%)`n"
        }
        $sections['Patterns'] = $patternsSection
    }
    
    # Analysis request
    $analysisRequest = "## Analysis Request`n`n"
    $analysisRequest += "Based on the test results above, please provide:"
    $analysisRequest += "`n1. **Interpretation**: What do these results indicate?"
    $analysisRequest += "`n2. **Next Steps**: What should be done based on these results?"
    $analysisRequest += "`n3. **Risk Assessment**: Are there any concerns or issues to address?"
    if ($ResultAnalysis.Analysis.Classification -eq "Failure") {
        $analysisRequest += "`n4. **Failure Analysis**: Why did the tests fail and how to fix them?"
    }
    $sections['AnalysisRequest'] = $analysisRequest
    
    # Combine sections
    $template.Sections = $sections
    $template.Content = ($sections.Values -join "`n`n")
    
    return $template
}

function New-ContinuePromptTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$ResultAnalysis,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    Write-AgentLog -Message "Creating continue prompt template" -Level "DEBUG" -Component "ContinueTemplate"
    
    $template = @{
        Type = "Continue"
        Content = ""
        Metadata = @{
            CreatedAt = Get-Date
            Confidence = 0.90
            ComponentsUsed = @("Workflow Continuation", "Success Analysis")
        }
        Sections = @{}
    }
    
    # Build continuation prompt sections
    $sections = @{}
    
    # Success confirmation
    $successSection = "## Operation Successful`n`n"
    $successSection += "The previous operation completed successfully:"
    $successSection += "`n- **Classification**: $($ResultAnalysis.Analysis.Classification)"
    $successSection += "`n- **Confidence**: $($ResultAnalysis.Analysis.Confidence * 100)%"
    if ($ResultAnalysis.Analysis.SuccessIndicators -and $ResultAnalysis.Analysis.SuccessIndicators.Count -gt 0) {
        $successSection += "`n- **Success Indicators**: " + ($ResultAnalysis.Analysis.SuccessIndicators -join ", ")
    }
    $sections['Success'] = $successSection
    
    # Continuation request
    $continuationRequest = "## Continuation Request`n`n"
    $continuationRequest += "Please continue with the next logical step in the workflow:"
    $continuationRequest += "`n1. **Assessment**: Evaluate the current state"
    $continuationRequest += "`n2. **Next Action**: Determine and execute the next step"
    $continuationRequest += "`n3. **Monitoring**: Watch for any issues or changes"
    $continuationRequest += "`n4. **Progress**: Report on overall progress toward goals"
    $sections['ContinuationRequest'] = $continuationRequest
    
    # Combine sections
    $template.Sections = $sections
    $template.Content = ($sections.Values -join "`n`n")
    
    return $template
}

function New-ARPPromptTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$ResultAnalysis,
        
        [Parameter()]
        [hashtable]$Context = @{},
        
        [Parameter()]
        [hashtable]$HistoricalData = @{}
    )
    
    Write-AgentLog -Message "Creating ARP (Analyze, Research, Plan) prompt template" -Level "DEBUG" -Component "ARPTemplate"
    
    $template = @{
        Type = "ARP"
        Content = ""
        Metadata = @{
            CreatedAt = Get-Date
            Confidence = 0.75
            ComponentsUsed = @("Analysis Framework", "Research Context", "Planning Structure")
        }
        Sections = @{}
    }
    
    # Build ARP prompt sections
    $sections = @{}
    
    # Current situation analysis
    $analysisSection = "## Current Situation Analysis`n`n"
    $analysisSection += "**Problem Classification**: $($ResultAnalysis.Analysis.Classification)`n"
    $analysisSection += "**Severity Level**: $($ResultAnalysis.Analysis.Severity)`n"
    if ($ResultAnalysis.Analysis.ErrorMessages -and $ResultAnalysis.Analysis.ErrorMessages.Count -gt 0) {
        $analysisSection += "**Key Issues**:`n"
        foreach ($error in $ResultAnalysis.Analysis.ErrorMessages) {
            $analysisSection += "- $error`n"
        }
    }
    $sections['Analysis'] = $analysisSection
    
    # Research requirements
    $researchSection = "## Research Requirements`n`n"
    $researchSection += "Please research and gather information on:"
    $researchSection += "`n1. **Root Causes**: What underlying issues led to this situation?"
    $researchSection += "`n2. **Best Practices**: What are the recommended approaches for this type of problem?"
    $researchSection += "`n3. **Similar Cases**: Have similar issues been resolved before, and how?"
    $researchSection += "`n4. **Dependencies**: What other systems or components might be affected?"
    $sections['Research'] = $researchSection
    
    # Planning framework
    $planningSection = "## Planning Framework`n`n"
    $planningSection += "Based on your analysis and research, create a comprehensive plan that includes:"
    $planningSection += "`n### Immediate Actions (0-1 hour)"
    $planningSection += "- Critical fixes or workarounds needed immediately"
    $planningSection += "`n### Short-term Plan (1-24 hours)"
    $planningSection += "- Steps to address the core issues"
    $planningSection += "- Testing and validation procedures"
    $planningSection += "`n### Long-term Strategy (1-7 days)"
    $planningSection += "- Preventive measures and system improvements"
    $planningSection += "- Monitoring and maintenance considerations"
    $planningSection += "`n### Success Criteria"
    $planningSection += "- How will we know when the problem is fully resolved?"
    $planningSection += "- What metrics or indicators should be monitored?"
    $sections['Planning'] = $planningSection
    
    # Combine sections
    $template.Sections = $sections
    $template.Content = ($sections.Values -join "`n`n")
    
    return $template
}

function New-DefaultPromptTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$ResultAnalysis,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    Write-AgentLog -Message "Creating default prompt template" -Level "DEBUG" -Component "DefaultTemplate"
    
    $template = @{
        Type = "Default"
        Content = ""
        Metadata = @{
            CreatedAt = Get-Date
            Confidence = 0.60
            ComponentsUsed = @("Basic Analysis", "General Request")
        }
        Sections = @{}
    }
    
    # Build default prompt sections
    $sections = @{}
    
    # Basic analysis
    $analysisSection = "## Situation Analysis`n`n"
    $analysisSection += "**Result Classification**: $($ResultAnalysis.Analysis.Classification)`n"
    $analysisSection += "**Confidence Level**: $($ResultAnalysis.Analysis.Confidence * 100)%`n"
    if ($ResultAnalysis.Analysis.KeyMetrics) {
        $analysisSection += "**Key Metrics**: " + ($ResultAnalysis.Analysis.KeyMetrics -join ", ") + "`n"
    }
    $sections['Analysis'] = $analysisSection
    
    # General request
    $requestSection = "## General Request`n`n"
    $requestSection += "Please analyze the situation described above and provide:"
    $requestSection += "`n1. **Assessment**: What is the current state and any issues present?"
    $requestSection += "`n2. **Recommendations**: What actions should be taken?"
    $requestSection += "`n3. **Next Steps**: What should happen next?"
    $requestSection += "`n4. **Monitoring**: What should be watched for going forward?"
    $sections['Request'] = $requestSection
    
    # Combine sections
    $template.Sections = $sections
    $template.Content = ($sections.Values -join "`n`n")
    
    return $template
}

function Invoke-TemplateRendering {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Template,
        
        [Parameter()]
        [hashtable]$AdditionalContext = @{}
    )
    
    Write-AgentLog -Message "Rendering prompt template: $($Template.Type)" -Level "DEBUG" -Component "TemplateRenderer"
    
    try {
        $renderedContent = $Template.Content
        
        # Apply any additional context substitutions
        if ($AdditionalContext.Count -gt 0) {
            foreach ($key in $AdditionalContext.Keys) {
                $placeholder = "{$key}"
                if ($renderedContent -like "*$placeholder*") {
                    $renderedContent = $renderedContent -replace [regex]::Escape($placeholder), $AdditionalContext[$key]
                }
            }
        }
        
        # Add timestamp and metadata
        $finalPrompt = "# Generated Prompt - $($Template.Type)`n"
        $finalPrompt += "*Generated at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*`n"
        $finalPrompt += "*Confidence: $($Template.Metadata.Confidence * 100)%*`n`n"
        $finalPrompt += $renderedContent
        
        Write-AgentLog -Message "Template rendering completed successfully" -Level "DEBUG" -Component "TemplateRenderer"
        
        return @{
            Success = $true
            RenderedPrompt = $finalPrompt
            Metadata = $Template.Metadata
            Error = $null
        }
    }
    catch {
        Write-AgentLog -Message "Template rendering failed: $_" -Level "ERROR" -Component "TemplateRenderer"
        return @{
            Success = $false
            RenderedPrompt = ""
            Metadata = @{}
            Error = $_.ToString()
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'New-PromptTemplate',
    'New-DebuggingPromptTemplate',
    'New-TestResultsPromptTemplate',
    'New-ContinuePromptTemplate',
    'New-ARPPromptTemplate',
    'New-DefaultPromptTemplate',
    'Invoke-TemplateRendering'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBJ6gLomLDXO5e+
# lbLZTB9N3P1YX5UM+mrGt1Mk+CKm7aCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOLd4xiQfOZYP1yUSnVnFpyH
# 9ItPfQIVUsBkaCN2XrTPMA0GCSqGSIb3DQEBAQUABIIBAC93ne5hXC380XayO8Ug
# lI7+j+W6heX6toRgSKrM9ESLw1mHW6OUpLqZ7AbHaoptBvQgAJs/qhiZgzcXIvx5
# Jme+kYCsrWCqgvCheOdbvpQPnd1PaI7r1w+rsjddyi3StPCKYC5XmwDSqeaa984T
# 1TwVCD+XDt+XROItX3W/pyAVqXl44SN3HfUsHBktC948BkcX6FQCst8wf0KFs6sD
# NuLc6MW2HWV0ZcnUcvNukvysHAI07km3ywi/bKDj+v9FWrounNYI2bCwbcn+2W97
# RLz5IncOBF033d9/e4vqakl2DrzO+fhgyMbTClDvMgN+udn7Msk5cezve/KZh4Sv
# /1k=
# SIG # End signature block
