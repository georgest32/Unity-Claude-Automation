# Unity-Claude-DocumentationAnalytics Module Manifest
# Week 3 Day 13 Hour 7-8: Documentation Analytics and Optimization
@{
    RootModule = 'Unity-Claude-DocumentationAnalytics.psm1'
    ModuleVersion = '1.0.0'
    GUID = '7a2f4c8d-9e3b-4a6f-8c2d-1e5f7a9b3c6e'
    Author = 'Unity-Claude-Automation'
    CompanyName = 'Unity-Claude-Automation Project'
    Copyright = '(c) 2025 Unity-Claude-Automation. All rights reserved.'
    Description = 'Documentation Analytics and Optimization module with AI-enhanced recommendations and usage pattern analysis. Implements research-validated 2025 analytics patterns for comprehensive documentation performance measurement and optimization.'
    
    PowerShellVersion = '5.1'
    
    FunctionsToExport = @(
        'Initialize-DocumentationAnalytics',
        'Start-DocumentationAnalytics', 
        'Get-DocumentationUsageMetrics',
        'Get-ContentOptimizationRecommendations',
        'Measure-DocumentationEffectiveness',
        'Get-DocumentationMetrics',
        'Analyze-UserJourney',
        'Get-ImprovementSuggestions',
        'Start-AutomatedDocumentationMaintenance',
        'Invoke-ContentFreshnessCheck',
        'Remove-ObsoleteDocumentation',
        'Send-MaintenanceReport',
        'Export-AnalyticsReport',
        'Analyze-AccessPatterns'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    RequiredModules = @()
    
    ModuleList = @('Unity-Claude-DocumentationAnalytics')
    
    FileList = @(
        'Unity-Claude-DocumentationAnalytics.psm1',
        'Unity-Claude-DocumentationAnalytics.psd1'
    )
    
    PrivateData = @{
        PSData = @{
            Tags = @('Documentation', 'Analytics', 'Optimization', 'Usage-Patterns', 'AI-Enhanced', 'Content-Analysis', 'Maintenance', 'PowerShell')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = @'
Version 1.0.0 (2025-08-30)
- Initial release implementing Week 3 Day 13 Hour 7-8: Documentation Analytics and Optimization
- Research-validated analytics patterns with 14 core content performance metrics
- AI-enhanced optimization recommendations using Ollama 34B integration
- Comprehensive usage pattern analysis and user journey tracking
- Automated documentation maintenance and cleanup procedures
- Time to First Hello World (TTFHW) metric implementation
- Real-time analytics tracking infrastructure
- Content effectiveness measurement with improvement suggestions
- PowerShell 5.1 compatible with zero external dependencies
'@
        }
        
        AnalyticsFeatures = @{
            CoreMetrics = @('PageViews', 'UniqueAccesses', 'TimeOnPage', 'BounceRate', 'ConversionRate', 'TTFHW')
            AIOptimization = 'Ollama 34B Integration'
            UsagePatterns = 'Behavioral Analysis and User Journey Tracking'
            AutomatedMaintenance = 'Scheduled Cleanup and Content Freshness'
            ReportingFormats = @('JSON', 'HTML', 'PowerShell Object')
        }
    }
}