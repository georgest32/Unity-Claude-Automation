# Generate-HybridDocumentation.ps1
# Hybrid documentation generator using AI for critical modules and patterns for others

param(
    [string]$OutputPath = ".\docs\generated",
    [string]$Model = "codellama:34b",
    [int]$MaxAIModules = 10,  # Limit AI analysis to most important modules
    [switch]$QuickMode,       # Skip AI entirely for fast generation
    [switch]$TestMode         # Test with just 2 AI modules
)

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Define markdown code fence to avoid PowerShell backtick interpretation
$codeFence = '```'

Write-Host ("=" * 80) -ForegroundColor Cyan
Write-Host "HYBRID SEMANTIC DOCUMENTATION GENERATION" -ForegroundColor Green
Write-Host "AI Analysis: Top $MaxAIModules critical modules only" -ForegroundColor Yellow
Write-Host "Pattern-Based: All remaining modules" -ForegroundColor Yellow
Write-Host ("=" * 80) -ForegroundColor Cyan

# Test mode limits
if ($TestMode) {
    $MaxAIModules = 2
    Write-Host "`nTEST MODE: Limited to $MaxAIModules AI analyses" -ForegroundColor Magenta
}

# Skip AI check if in QuickMode
$useAI = -not $QuickMode
if ($useAI) {
    Write-Host "`nTesting Ollama connectivity..." -ForegroundColor Yellow
    try {
        $testResponse = ollama run $Model "Say 'ready'" 2>&1
        if ($testResponse -match "ready") {
            Write-Host "✅ Ollama is ready!" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠️ Ollama not available. Falling back to pattern-based only." -ForegroundColor Yellow
        $useAI = $false
    }
} else {
    Write-Host "`n⚡ Quick Mode: Skipping AI analysis" -ForegroundColor Cyan
}

#region Critical Module Identification
# Define critical modules that should get AI analysis
$script:CriticalModulePatterns = @(
    # Core Infrastructure (Priority 1)
    "*Core*",
    "*CLIOrchestrator*",
    "*DecisionEngine*",
    "*ResponseAnalysisEngine*",
    
    # AI and Intelligence (Priority 2)
    "*Claude*AI*",
    "*PatternRecognition*",
    "*Learning*",
    "*Bayesian*",
    
    # Critical Operations (Priority 3)
    "*Safety*",
    "*Validation*",
    "*AutonomousAgent*",
    "*MasterOrchestrator*",
    
    # Integration Points (Priority 4)
    "*Unity*Integration*",
    "*GitHub*Integration*",
    "*Docker*",
    "*MCP*"
)

function Get-ModulePriority {
    param([string]$ModuleName)
    
    for ($i = 0; $i -lt $script:CriticalModulePatterns.Count; $i++) {
        if ($ModuleName -like $script:CriticalModulePatterns[$i]) {
            return $i  # Lower number = higher priority
        }
    }
    return 999  # Low priority for non-critical modules
}
#endregion

#region Pattern-Based Description Generator
function Get-PatternBasedDescription {
    param([string]$ModuleName, [string]$Content)
    
    # Base description from pattern matching
    $description = switch -Wildcard ($ModuleName) {
        "*Core*" { 
            "Core infrastructure module providing fundamental functionality for the Unity-Claude system. This module serves as the foundation for other components, offering essential utilities, configuration management, and base services."
        }
        "*Orchestrat*" { 
            "Master orchestration module coordinating complex multi-step workflows. Manages module interactions, handles state transitions, and ensures proper sequencing of automated operations."
        }
        "*Decision*" { 
            "Decision engine module implementing rule-based and ML-enhanced decision trees. Analyzes inputs, evaluates constraints, and determines appropriate actions based on configurable policies."
        }
        "*Pattern*Recognition*" { 
            "Pattern recognition engine that identifies recurring patterns, anomalies, and trends. Uses statistical analysis and machine learning to improve system behavior over time."
        }
        "*Response*Analysis*" { 
            "Response analysis module that processes and interprets Claude AI responses. Extracts actionable information, validates safety constraints, and prepares execution plans."
        }
        "*Safety*" { 
            "Safety and validation framework ensuring all automated operations meet security requirements. Implements sandboxing, command validation, and rollback mechanisms."
        }
        "*Parallel*" { 
            "High-performance parallel processing module for concurrent operations. Manages thread pools, runspace allocation, and synchronization primitives."
        }
        "*Documentation*" { 
            "Documentation automation module providing real-time documentation updates. Generates API docs, maintains cross-references, and ensures documentation accuracy."
        }
        "*GitHub*" { 
            "GitHub integration module for version control operations. Handles commits, pull requests, issue management, and repository automation."
        }
        "*Unity*" { 
            "Unity Editor integration providing direct communication with Unity processes. Monitors compilation, extracts errors, and manages project operations."
        }
        "*Cache*" { 
            "Intelligent caching system optimizing performance through strategic data persistence. Implements LRU policies, dependency tracking, and automatic invalidation."
        }
        "*Monitor*" { 
            "Real-time monitoring module tracking system health and performance metrics. Provides event-driven notifications and automated issue response."
        }
        "*Email*" { 
            "Email notification module for multi-channel alert delivery. Supports SMTP configuration, templated messages, and escalation chains."
        }
        "*Docker*" { 
            "Container orchestration module managing Docker deployments. Handles image building, container lifecycle, and service composition."
        }
        "*MCP*" { 
            "Model Context Protocol integration for enhanced AI interactions. Manages context windows, prompt engineering, and response streaming."
        }
        "*Bayesian*" { 
            "Bayesian inference engine for probabilistic reasoning and confidence scoring. Updates beliefs based on evidence and provides uncertainty quantification."
        }
        "*Learning*" { 
            "Machine learning module that adapts system behavior based on historical data. Implements online learning, model updates, and performance optimization."
        }
        "*Autonomous*" { 
            "Autonomous operation module enabling self-directed task execution. Implements goal-seeking behavior, state management, and recovery mechanisms."
        }
        "*Alert*" { 
            "Alert management system for incident detection and notification. Categorizes alerts, manages thresholds, and coordinates response actions."
        }
        "*Validation*" { 
            "Validation framework ensuring data integrity and operation safety. Implements schema validation, constraint checking, and error prevention."
        }
        default { 
            "Specialized module providing targeted functionality for the Unity-Claude automation system. Integrates with the broader architecture to deliver specific capabilities."
        }
    }
    
    # Add statistics
    $stats = @{
        FunctionCount = ([regex]::Matches($Content, '\bfunction\s+\w+\b')).Count
        ClassCount = ([regex]::Matches($Content, '\bclass\s+\w+\b')).Count
        ExportCount = ([regex]::Matches($Content, 'Export-ModuleMember')).Count
        LineCount = ($Content -split "`n").Count
    }
    
    # Enhance description with capabilities based on function names
    $functions = [regex]::Matches($Content, 'function\s+(\w+-\w+)')
    $capabilities = @()
    
    foreach ($func in $functions | Select-Object -First 5) {
        $funcName = $func.Groups[1].Value
        $verb = $funcName.Split('-')[0]
        
        $capability = switch ($verb) {
            "Get" { "data retrieval" }
            "Set" { "configuration management" }
            "New" { "resource creation" }
            "Remove" { "cleanup operations" }
            "Start" { "process initiation" }
            "Stop" { "process termination" }
            "Test" { "validation and testing" }
            "Invoke" { "action execution" }
            "Submit" { "request processing" }
            "Initialize" { "system initialization" }
            default { "specialized operations" }
        }
        
        if ($capability -notin $capabilities) {
            $capabilities += $capability
        }
    }
    
    if ($capabilities.Count -gt 0) {
        $description += "`n`n**Key Capabilities:** " + ($capabilities -join ", ")
    }
    
    $description += "`n`n**Module Statistics:**`n"
    $description += "- Functions: $($stats.FunctionCount)`n"
    $description += "- Lines of Code: $($stats.LineCount)`n"
    if ($stats.ClassCount -gt 0) {
        $description += "- Classes: $($stats.ClassCount)`n"
    }
    if ($stats.ExportCount -gt 0) {
        $description += "- Exported Members: $($stats.ExportCount)`n"
    }
    
    return $description
}
#endregion

#region AI Description Generator
function Get-AIDescription {
    param(
        [string]$Code,
        [string]$Type,
        [string]$Name
    )
    
    # Limit code sample to prevent timeout
    $codeSnippet = if ($Code.Length -gt 3000) {
        $Code.Substring(0, 3000) + "`n# ... (truncated for analysis)"
    } else {
        $Code
    }
    
    $prompt = @"
Analyze this PowerShell $Type and provide a comprehensive technical description.

Name: $Name

Code snippet:
``````powershell
$codeSnippet
``````

Provide a focused technical analysis with:
1. PRIMARY PURPOSE (2-3 sentences): What this module does and why it exists
2. ARCHITECTURE: Design patterns and architectural approach used
3. KEY FEATURES: Main capabilities (bullet points)
4. INTEGRATION: How it connects with other system components
5. CRITICAL FUNCTIONS: Most important functions and their roles

Keep the response concise and technical. Focus on architecture and design patterns.
"@
    
    try {
        Write-Host "    🤖 AI analyzing $Name..." -ForegroundColor Gray
        $response = ollama run $Model $prompt 2>&1 | Out-String
        
        if ($response -and $response.Length -gt 100) {
            return $response
        } else {
            Write-Host "    ⚠️ AI response too short, using pattern-based fallback" -ForegroundColor Yellow
            return $null
        }
    } catch {
        Write-Host "    ❌ AI analysis failed: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}
#endregion

#region Main Processing
Write-Host "`n[1/5] Scanning codebase structure..." -ForegroundColor Green
$modules = Get-ChildItem -Path ".\Modules" -Filter "*.psm1" -Recurse -ErrorAction SilentlyContinue
$scripts = Get-ChildItem -Path "." -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { $_.FullName -notmatch "\\(node_modules|\.git|temp|backup)\\" }

Write-Host "  Found $($modules.Count) modules and $($scripts.Count) scripts" -ForegroundColor Gray

# Sort modules by priority
Write-Host "`n[2/5] Prioritizing modules for analysis..." -ForegroundColor Green
$prioritizedModules = $modules | ForEach-Object {
    @{
        Module = $_
        Priority = Get-ModulePriority -ModuleName $_.BaseName
    }
} | Sort-Object Priority

$aiModules = $prioritizedModules | Select-Object -First $MaxAIModules | ForEach-Object { $_.Module }
$patternModules = $prioritizedModules | Select-Object -Skip $MaxAIModules | ForEach-Object { $_.Module }

Write-Host "  🤖 AI Analysis: $($aiModules.Count) critical modules" -ForegroundColor Cyan
Write-Host "  📋 Pattern-Based: $($patternModules.Count) standard modules" -ForegroundColor Yellow

# Process modules
Write-Host "`n[3/5] Generating module documentation..." -ForegroundColor Green
$moduleDocumentation = @{}
$processedCount = 0
$totalModules = $modules.Count

# Process AI modules
if ($useAI -and $aiModules.Count -gt 0) {
    Write-Host "`n  Phase 1: AI-Enhanced Analysis" -ForegroundColor Cyan
    foreach ($module in $aiModules) {
        $processedCount++
        $percentComplete = [math]::Round(($processedCount / $totalModules) * 100)
        Write-Host "  [$processedCount/$totalModules] ($percentComplete%) Analyzing $($module.BaseName) with AI..." -ForegroundColor Gray
        
        $content = Get-Content $module.FullName -Raw
        
        # Try AI first
        $description = Get-AIDescription -Code $content -Type "module" -Name $module.BaseName
        
        # Fallback to pattern if AI fails
        if (-not $description) {
            $description = Get-PatternBasedDescription -ModuleName $module.BaseName -Content $content
        }
        
        # Parse AST for functions
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
        $functions = $ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)
        
        $moduleDocumentation[$module.BaseName] = @{
            Path = $module.FullName
            RelativePath = $module.FullName.Replace($PWD.Path, "").TrimStart("\")
            Description = $description
            Functions = $functions | ForEach-Object { 
                @{
                    Name = $_.Name
                    StartLine = $_.Extent.StartLineNumber
                    EndLine = $_.Extent.EndLineNumber
                }
            }
            IsAIEnhanced = $true
            Priority = Get-ModulePriority -ModuleName $module.BaseName
            Size = [math]::Round($module.Length / 1KB, 2)
            LastModified = $module.LastWriteTime
        }
    }
}

# Process pattern-based modules
Write-Host "`n  Phase 2: Pattern-Based Analysis" -ForegroundColor Yellow
foreach ($module in $patternModules) {
    $processedCount++
    $percentComplete = [math]::Round(($processedCount / $totalModules) * 100)
    
    if ($processedCount % 10 -eq 0 -or $processedCount -eq $totalModules) {
        Write-Host "  [$processedCount/$totalModules] ($percentComplete%) Processing remaining modules..." -ForegroundColor Gray
    }
    
    $content = Get-Content $module.FullName -Raw
    $description = Get-PatternBasedDescription -ModuleName $module.BaseName -Content $content
    
    # Parse AST for functions
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
    $functions = $ast.FindAll({
        $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $true)
    
    $moduleDocumentation[$module.BaseName] = @{
        Path = $module.FullName
        RelativePath = $module.FullName.Replace($PWD.Path, "").TrimStart("\")
        Description = $description
        Functions = $functions | ForEach-Object { 
            @{
                Name = $_.Name
                StartLine = $_.Extent.StartLineNumber
                EndLine = $_.Extent.EndLineNumber
            }
        }
        IsAIEnhanced = $false
        Priority = Get-ModulePriority -ModuleName $module.BaseName
        Size = [math]::Round($module.Length / 1KB, 2)
        LastModified = $module.LastWriteTime
    }
}

# Analyze relationships
Write-Host "`n[4/5] Analyzing module relationships..." -ForegroundColor Green
$relationships = @{
    Imports = @{}
    Exports = @{}
    Dependencies = @{}
}

foreach ($moduleName in $moduleDocumentation.Keys) {
    $module = $moduleDocumentation[$moduleName]
    $content = Get-Content $module.Path -Raw
    
    # Find imports
    $imports = [regex]::Matches($content, 'Import-Module\s+["'']?([^"''\s]+)["'']?')
    $relationships.Imports[$moduleName] = $imports | ForEach-Object { $_.Groups[1].Value }
    
    # Find calls to other modules
    $relationships.Dependencies[$moduleName] = @()
    foreach ($otherModule in $moduleDocumentation.Keys) {
        if ($otherModule -ne $moduleName) {
            $pattern = "\b($($moduleDocumentation[$otherModule].Functions.Name -join '|'))\b"
            if ($pattern -ne "\b()\b" -and $content -match $pattern) {
                $relationships.Dependencies[$moduleName] += $otherModule
            }
        }
    }
}

# Generate semantic groups
$semanticGroups = @{
    "🏗️ Core Infrastructure" = $moduleDocumentation.Keys | Where-Object { 
        $_ -match "Core|Base|Foundation|Configuration"
    }
    "🤖 AI & Intelligence" = $moduleDocumentation.Keys | Where-Object { 
        $_ -match "AI|Claude|Learning|Decision|Bayesian|Pattern"
    }
    "📚 Documentation System" = $moduleDocumentation.Keys | Where-Object { 
        $_ -match "Documentation|Semantic|Quality|Report"
    }
    "⚡ Performance & Processing" = $moduleDocumentation.Keys | Where-Object { 
        $_ -match "Parallel|Performance|Cache|Optimization|Thread"
    }
    "🎮 Unity Integration" = $moduleDocumentation.Keys | Where-Object { 
        $_ -match "Unity|Compilation|Editor|Recompile"
    }
    "📊 Monitoring & Analytics" = $moduleDocumentation.Keys | Where-Object { 
        $_ -match "Monitor|Alert|Notification|Status|Metric"
    }
    "🔒 Safety & Validation" = $moduleDocumentation.Keys | Where-Object { 
        $_ -match "Safety|Validation|HITL|Approval|Security"
    }
    "🔧 Integration & Tools" = $moduleDocumentation.Keys | Where-Object { 
        $_ -match "GitHub|Email|Docker|MCP|Integration"
    }
    "🎯 Orchestration & Control" = $moduleDocumentation.Keys | Where-Object { 
        $_ -match "Orchestrat|Workflow|Automation|Agent"
    }
}

# Generate comprehensive documentation
Write-Host "`n[5/5] Building final documentation..." -ForegroundColor Green

$markdown = @"
# Unity-Claude Automation System - Hybrid Semantic Documentation

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Total Modules:** $($moduleDocumentation.Count)  
**AI-Enhanced Modules:** $($aiModules.Count)  
**Pattern-Based Modules:** $($patternModules.Count)  
**Total Functions:** $(($moduleDocumentation.Values | ForEach-Object { $_.Functions.Count } | Measure-Object -Sum).Sum)

## 📑 Table of Contents

1. [System Overview](#-system-overview)
2. [Architecture](#-architecture)
3. [Module Categories](#-module-categories)
4. [Critical Modules (AI-Enhanced)](#-critical-modules-ai-enhanced)
5. [Standard Modules](#-standard-modules)
6. [Module Network](#-module-network)

---

## 🎯 System Overview

The Unity-Claude Automation System is a sophisticated PowerShell-based framework that bridges Unity game development with Claude AI capabilities. This hybrid documentation combines AI-powered analysis for critical components with efficient pattern-based documentation for standard modules.

### Documentation Approach

- **🤖 AI-Enhanced**: Critical infrastructure and complex modules analyzed by $Model
- **📋 Pattern-Based**: Standard modules documented using intelligent pattern matching
- **🔗 Relationship Mapping**: Automatic dependency and interaction analysis

## 🏗️ Architecture

The system implements a microservices-inspired architecture with these layers:

${codeFence}mermaid
graph TB
    subgraph "External Systems"
        Unity[Unity Editor]
        Claude[Claude AI/CLI]
        GitHub[GitHub]
        Docker[Docker]
    end
    
    subgraph "Core Layer"
        Core[Core Infrastructure]
        Config[Configuration]
        Safety[Safety Framework]
    end
    
    subgraph "Intelligence Layer"
        AI[AI Integration]
        Decision[Decision Engine]
        Pattern[Pattern Recognition]
        Learning[Machine Learning]
    end
    
    subgraph "Processing Layer"
        Parallel[Parallel Processing]
        Cache[Caching System]
        Monitor[Monitoring]
    end
    
    subgraph "Orchestration Layer"
        CLIOrch[CLI Orchestrator]
        Master[Master Orchestrator]
        Auto[Autonomous Agents]
    end
    
    Unity --> Core
    Claude --> CLIOrch
    Core --> AI
    AI --> Decision
    Decision --> Pattern
    Pattern --> Parallel
    Parallel --> Cache
    Cache --> Monitor
    Monitor --> CLIOrch
    CLIOrch --> Master
    Master --> GitHub
${codeFence}

## 📦 Module Categories

$(foreach ($group in $semanticGroups.Keys | Sort-Object) {
    $modules = $semanticGroups[$group]
    if ($modules.Count -gt 0) {
        $aiCount = ($modules | Where-Object { $moduleDocumentation[$_].IsAIEnhanced }).Count
        $groupInfo = if ($aiCount -gt 0) { " ($aiCount AI-enhanced)" } else { "" }
        @"

### $group$groupInfo

**Modules:** $($modules.Count) | **Functions:** $(($modules | ForEach-Object { $moduleDocumentation[$_].Functions.Count } | Measure-Object -Sum).Sum)

$(foreach ($moduleName in $modules | Sort-Object) {
    $module = $moduleDocumentation[$moduleName]
    $aiTag = if ($module.IsAIEnhanced) { " 🤖" } else { "" }
    "- [**$moduleName**](#$(($moduleName.ToLower() -replace '[^a-z0-9]', '-')))$aiTag"
})
"@
    }
})

---

## 🤖 Critical Modules (AI-Enhanced)

These modules received detailed AI analysis due to their critical importance:

$(foreach ($moduleName in ($moduleDocumentation.Keys | Where-Object { $moduleDocumentation[$_].IsAIEnhanced } | Sort-Object)) {
    $module = $moduleDocumentation[$moduleName]
    @"

### $moduleName

[⬆ Back to Contents](#-table-of-contents)

$($module.Description)

**Module Details:**
- **Path:** ``$($module.RelativePath)``
- **Size:** $($module.Size) KB
- **Functions:** $($module.Functions.Count)
- **Last Modified:** $($module.LastModified.ToString("yyyy-MM-dd HH:mm"))
- **Analysis:** AI-Enhanced 🤖

$(if ($module.Functions.Count -gt 0) {
@"

**Key Functions:**
$(foreach ($func in $module.Functions | Select-Object -First 10) {
    "- ``$($func.Name)`` (Lines $($func.StartLine)-$($func.EndLine))"
})
$(if ($module.Functions.Count -gt 10) {
    "- *...and $($module.Functions.Count - 10) more functions*"
})
"@
})

$(if ($relationships.Dependencies[$moduleName].Count -gt 0) {
@"

**Dependencies:**
$(foreach ($dep in $relationships.Dependencies[$moduleName] | Select-Object -Unique) {
    "- [``$dep``](#$(($dep.ToLower() -replace '[^a-z0-9]', '-')))"
})
"@
})

---
"@
})

## 📋 Standard Modules

These modules use pattern-based documentation for efficiency:

$(foreach ($moduleName in ($moduleDocumentation.Keys | Where-Object { -not $moduleDocumentation[$_].IsAIEnhanced } | Sort-Object)) {
    $module = $moduleDocumentation[$moduleName]
    @"

### $moduleName

[⬆ Back to Contents](#-table-of-contents)

$($module.Description)

**Module Details:**
- **Path:** ``$($module.RelativePath)``
- **Size:** $($module.Size) KB
- **Functions:** $($module.Functions.Count)
- **Last Modified:** $($module.LastModified.ToString("yyyy-MM-dd HH:mm"))

$(if ($relationships.Dependencies[$moduleName].Count -gt 0) {
@"
**Dependencies:** $(($relationships.Dependencies[$moduleName] | Select-Object -Unique) -join ", ")
"@
})

---
"@
})

## 🕸️ Module Network

### Dependency Statistics

| Metric | Value |
|--------|-------|
| Total Modules | $($moduleDocumentation.Count) |
| Total Dependencies | $(($relationships.Dependencies.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum) |
| AI-Enhanced Modules | $($aiModules.Count) |
| Average Functions per Module | $([math]::Round((($moduleDocumentation.Values | ForEach-Object { $_.Functions.Count } | Measure-Object -Average).Average), 2)) |

### Most Connected Modules

$(
    $connectionCounts = @{}
    foreach ($moduleName in $relationships.Dependencies.Keys) {
        $connectionCounts[$moduleName] = $relationships.Dependencies[$moduleName].Count
    }
    
    $topConnected = $connectionCounts.GetEnumerator() | 
        Sort-Object Value -Descending | 
        Select-Object -First 10
    
    "| Module | Connections | Type |"
    "|--------|-------------|------|"
    foreach ($item in $topConnected) {
        $aiTag = if ($moduleDocumentation[$item.Key].IsAIEnhanced) { "🤖 AI-Enhanced" } else { "📋 Pattern-Based" }
        "| $($item.Key) | $($item.Value) | $aiTag |"
    }
)

---

*Generated by Unity-Claude Hybrid Documentation System*  
*AI Model: $Model | Pattern Engine: v2.0*
"@

# Write main documentation
$markdown | Out-File "$OutputPath\HYBRID_DOCUMENTATION.md" -Encoding UTF8

# Generate module index JSON
$moduleIndex = @{
    generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    stats = @{
        totalModules = $moduleDocumentation.Count
        aiEnhancedModules = $aiModules.Count
        patternBasedModules = $patternModules.Count
        totalFunctions = ($moduleDocumentation.Values | ForEach-Object { $_.Functions.Count } | Measure-Object -Sum).Sum
    }
    modules = $moduleDocumentation.Keys | ForEach-Object {
        @{
            name = $_
            isAIEnhanced = $moduleDocumentation[$_].IsAIEnhanced
            priority = $moduleDocumentation[$_].Priority
            functionCount = $moduleDocumentation[$_].Functions.Count
            size = $moduleDocumentation[$_].Size
            dependencies = $relationships.Dependencies[$_]
        }
    }
    semanticGroups = $semanticGroups
}

$moduleIndex | ConvertTo-Json -Depth 10 | Out-File "$OutputPath\module_index.json" -Encoding UTF8

# Summary
Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
Write-Host "HYBRID DOCUMENTATION COMPLETE!" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Cyan

Write-Host "`nGenerated Files:" -ForegroundColor Yellow
Write-Host "  📄 HYBRID_DOCUMENTATION.md - Complete hybrid documentation" -ForegroundColor Cyan
Write-Host "  📊 module_index.json - Module metadata and relationships" -ForegroundColor Cyan

Write-Host "`nDocumentation Statistics:" -ForegroundColor Yellow
Write-Host "  🤖 AI-Enhanced Modules: $($aiModules.Count)" -ForegroundColor Green
Write-Host "  📋 Pattern-Based Modules: $($patternModules.Count)" -ForegroundColor Green
Write-Host "  📚 Total Functions Documented: $(($moduleDocumentation.Values | ForEach-Object { $_.Functions.Count } | Measure-Object -Sum).Sum)" -ForegroundColor Green
Write-Host "  🔗 Dependencies Mapped: $(($relationships.Dependencies.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum)" -ForegroundColor Green

Write-Host "`n📖 View documentation: $OutputPath\HYBRID_DOCUMENTATION.md" -ForegroundColor Cyan

if ($TestMode) {
    Write-Host "`n⚠️ TEST MODE: Only $MaxAIModules modules were AI-analyzed" -ForegroundColor Magenta
    Write-Host "Run without -TestMode for full analysis of top $($script:CriticalModulePatterns.Count) critical modules" -ForegroundColor Yellow
}