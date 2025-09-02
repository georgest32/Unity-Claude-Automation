#
# LLM-PromptTemplates.psm1
# Comprehensive prompt template system for documentation generation and code analysis
# Part of Unity-Claude-LLM Enhanced Documentation System  
# Created: 2025-08-28
#

#
# Documentation Generation Templates
#

function Get-FunctionDocumentationTemplate {
    [CmdletBinding()]
    param()
    
    return @"
You are a PowerShell documentation expert. Generate comprehensive documentation for the provided function.

REQUIREMENTS:
- Use standard PowerShell help format with .SYNOPSIS, .DESCRIPTION, .PARAMETER, .EXAMPLE, .NOTES
- Include practical usage examples
- Document all parameters with types and descriptions
- Specify return value type and description
- Include any important notes about usage or limitations
- Use clear, professional language suitable for technical documentation

FUNCTION CODE:
```powershell
{{FunctionCode}}
```

CONTEXT INFORMATION:
{{Context}}

EXISTING DOCUMENTATION (if any):
{{ExistingDocs}}

Generate complete function documentation following PowerShell standards:
"@
}

function Get-ModuleDocumentationTemplate {
    [CmdletBinding()]
    param()
    
    return @"
You are a PowerShell module documentation expert. Generate comprehensive module documentation.

REQUIREMENTS:
- Create module overview with purpose and capabilities
- Document all exported functions with brief descriptions  
- Include installation and usage instructions
- Add configuration requirements and dependencies
- Provide practical examples for common use cases
- Include troubleshooting section for common issues
- Use professional technical writing style

MODULE INFORMATION:
- Module Name: {{ModuleName}}
- Version: {{Version}}
- Functions: {{FunctionList}}

MODULE CODE ANALYSIS:
{{CodeAnalysis}}

CONTEXT:
{{Context}}

Generate complete module documentation:
"@
}

function Get-ClassDocumentationTemplate {
    [CmdletBinding()]
    param()
    
    return @"
You are a software architecture documentation expert. Generate comprehensive class documentation.

REQUIREMENTS:
- Document class purpose and responsibilities
- List all properties with types and descriptions
- Document all methods with parameters and return values
- Explain inheritance relationships and dependencies  
- Include usage examples and best practices
- Document any design patterns implemented
- Use object-oriented documentation standards

CLASS DEFINITION:
```{{Language}}
{{ClassCode}}
```

INHERITANCE HIERARCHY:
{{InheritanceInfo}}

USAGE CONTEXT:
{{Context}}

Generate complete class documentation:
"@
}

function Get-APIDocumentationTemplate {
    [CmdletBinding()]
    param()
    
    return @"
You are an API documentation specialist. Generate comprehensive REST API documentation.

REQUIREMENTS:
- Document all endpoints with HTTP methods and paths
- Include request and response schemas  
- Provide authentication requirements
- Add error codes and descriptions
- Include practical usage examples with curl and PowerShell
- Document rate limiting and usage policies
- Use OpenAPI/Swagger compatible format where applicable

API IMPLEMENTATION:
```{{Language}}
{{APICode}}
```

ENDPOINT ANALYSIS:
{{EndpointList}}

AUTHENTICATION SCHEME:
{{AuthInfo}}

Generate complete API documentation:
"@
}

#
# Code Analysis Templates
#

function Get-SecurityAnalysisTemplate {
    [CmdletBinding()]
    param()
    
    return @"
You are a cybersecurity code analysis expert. Perform comprehensive security analysis of the provided code.

ANALYSIS REQUIREMENTS:
- Identify potential security vulnerabilities
- Check for injection attack vectors (SQL, command, script injection)
- Analyze authentication and authorization patterns
- Review data validation and sanitization
- Examine error handling for information leakage
- Check for hardcoded credentials or secrets
- Assess cryptographic implementations
- Provide specific remediation recommendations

CODE TO ANALYZE:
```{{Language}}
{{CodeToAnalyze}}
```

SECURITY CONTEXT:
{{SecurityContext}}

DEPENDENCIES:
{{Dependencies}}

Provide detailed security analysis with specific findings and recommendations:
"@
}

function Get-PerformanceAnalysisTemplate {
    [CmdletBinding()]
    param()
    
    return @"
You are a software performance optimization expert. Analyze the provided code for performance issues and optimization opportunities.

ANALYSIS REQUIREMENTS:
- Identify performance bottlenecks and inefficiencies
- Analyze algorithmic complexity (time and space)
- Review memory usage patterns and potential leaks
- Examine I/O operations and blocking calls
- Check for unnecessary computations or redundant operations
- Analyze concurrency and parallelization opportunities
- Provide specific optimization recommendations with code examples

CODE TO ANALYZE:
```{{Language}}
{{CodeToAnalyze}}
```

PERFORMANCE METRICS (if available):
{{PerformanceData}}

USAGE PATTERNS:
{{UsageContext}}

Provide detailed performance analysis with optimization recommendations:
"@
}

function Get-QualityAnalysisTemplate {
    [CmdletBinding()]
    param()
    
    return @"
You are a software quality assurance expert. Perform comprehensive code quality analysis.

ANALYSIS REQUIREMENTS:
- Evaluate code maintainability and readability
- Check adherence to coding standards and best practices
- Analyze code complexity and technical debt
- Review error handling and logging practices
- Examine test coverage and testability
- Assess documentation quality and completeness
- Check for code smells and anti-patterns
- Provide refactoring recommendations

CODE TO ANALYZE:
```{{Language}}
{{CodeToAnalyze}}
```

CODING STANDARDS:
{{CodingStandards}}

QUALITY METRICS:
{{QualityMetrics}}

Provide detailed quality analysis with improvement recommendations:
"@
}

#
# Relationship Explanation Templates
#

function Get-DependencyAnalysisTemplate {
    [CmdletBinding()]
    param()
    
    return @"
You are a software architecture analyst. Explain the dependency relationships in the provided code structure.

ANALYSIS REQUIREMENTS:
- Map all dependencies between components
- Identify circular dependencies and their implications
- Analyze coupling levels (tight, loose, none)
- Explain dependency injection patterns (if present)
- Document interface dependencies and abstractions
- Assess dependency complexity and maintainability
- Provide dependency management recommendations

DEPENDENCY GRAPH DATA:
{{DependencyGraph}}

COMPONENT INFORMATION:
{{ComponentList}}

ARCHITECTURAL CONTEXT:
{{ArchitecturalContext}}

Provide comprehensive dependency analysis and explanation:
"@
}

function Get-InheritanceAnalysisTemplate {
    [CmdletBinding()]
    param()
    
    return @"
You are an object-oriented design expert. Explain the inheritance hierarchy and relationships.

ANALYSIS REQUIREMENTS:
- Map complete inheritance hierarchy
- Explain polymorphism implementations  
- Identify abstract classes and interfaces
- Document method overriding and virtual methods
- Analyze composition vs inheritance usage
- Assess design pattern implementations
- Provide inheritance design recommendations

INHERITANCE HIERARCHY:
{{InheritanceHierarchy}}

CLASS DEFINITIONS:
{{ClassDefinitions}}

DESIGN CONTEXT:
{{DesignContext}}

Provide detailed inheritance analysis and explanation:
"@
}

#
# Refactoring Suggestion Templates
#

function Get-PatternDetectionTemplate {
    [CmdletBinding()]
    param()
    
    return @"
You are a software design pattern expert. Analyze the code for design pattern implementations and opportunities.

ANALYSIS REQUIREMENTS:
- Identify existing design patterns (Singleton, Factory, Observer, Strategy, etc.)
- Suggest applicable design patterns for improvement
- Analyze pattern implementation quality
- Recommend pattern-based refactoring opportunities
- Explain benefits and trade-offs of suggested patterns
- Provide specific implementation examples

CODE TO ANALYZE:
```{{Language}}
{{CodeToAnalyze}}
```

ARCHITECTURAL REQUIREMENTS:
{{ArchitecturalRequirements}}

CURRENT PATTERNS DETECTED:
{{ExistingPatterns}}

Provide detailed pattern analysis and recommendations:
"@
}

function Get-RefactoringTemplate {
    [CmdletBinding()]
    param()
    
    return @"
You are a code refactoring specialist. Analyze the code and provide specific refactoring recommendations.

REFACTORING REQUIREMENTS:
- Identify code duplication and suggest consolidation
- Recommend function/method extraction opportunities  
- Suggest variable and function naming improvements
- Identify opportunities to reduce complexity
- Recommend modularization and separation of concerns
- Provide specific before/after code examples
- Prioritize refactoring suggestions by impact

CODE TO REFACTOR:
```{{Language}}
{{CodeToRefactor}}
```

QUALITY METRICS:
{{QualityMetrics}}

REFACTORING GOALS:
{{RefactoringGoals}}

Provide specific refactoring recommendations with code examples:
"@
}

#
# Template Processing Functions
#

function Invoke-TemplateSubstitution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Template,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Variables
    )
    
    Write-Debug "[TEMPLATE] Processing template with $($Variables.Count) variables"
    
    $processedTemplate = $Template
    
    # Substitute variables using PowerShell string interpolation patterns
    foreach ($variableName in $Variables.Keys) {
        $variableValue = $Variables[$variableName]
        $placeholder = "{{$variableName}}"
        
        # Handle null or empty values
        if (-not $variableValue) {
            $variableValue = "[Not provided]"
        }
        
        # Perform substitution
        $processedTemplate = $processedTemplate.Replace($placeholder, $variableValue)
        
        Write-Debug "[TEMPLATE] Substituted $placeholder with $($variableValue.ToString().Length) characters"
    }
    
    # Check for remaining unsubstituted variables
    $remainingPlaceholders = [regex]::Matches($processedTemplate, '\{\{([^}]+)\}\}')
    if ($remainingPlaceholders.Count -gt 0) {
        $unsubstituted = $remainingPlaceholders | ForEach-Object { $_.Groups[1].Value }
        Write-Warning "[TEMPLATE] Unsubstituted variables: $($unsubstituted -join ', ')"
    }
    
    return $processedTemplate
}

function New-DocumentationPromptFromTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Function', 'Module', 'Class', 'API')]
        [string]$DocumentationType,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$TemplateVariables
    )
    
    Write-Debug "[TEMPLATE] Creating $DocumentationType documentation prompt"
    
    # Get appropriate template
    $template = switch ($DocumentationType) {
        'Function' { Get-FunctionDocumentationTemplate }
        'Module' { Get-ModuleDocumentationTemplate }
        'Class' { Get-ClassDocumentationTemplate }
        'API' { Get-APIDocumentationTemplate }
    }
    
    # Process template with variables
    $prompt = Invoke-TemplateSubstitution -Template $template -Variables $TemplateVariables
    
    Write-Debug "[TEMPLATE] Generated prompt of $($prompt.Length) characters"
    
    return $prompt
}

function New-AnalysisPromptFromTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Security', 'Performance', 'Quality', 'Dependency', 'Inheritance', 'Pattern', 'Refactoring')]
        [string]$AnalysisType,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$TemplateVariables
    )
    
    Write-Debug "[TEMPLATE] Creating $AnalysisType analysis prompt"
    
    # Get appropriate template
    $template = switch ($AnalysisType) {
        'Security' { Get-SecurityAnalysisTemplate }
        'Performance' { Get-PerformanceAnalysisTemplate }
        'Quality' { Get-QualityAnalysisTemplate }
        'Dependency' { Get-DependencyAnalysisTemplate }
        'Inheritance' { Get-InheritanceAnalysisTemplate }
        'Pattern' { Get-PatternDetectionTemplate }
        'Refactoring' { Get-RefactoringTemplate }
    }
    
    # Process template with variables
    $prompt = Invoke-TemplateSubstitution -Template $template -Variables $TemplateVariables
    
    Write-Debug "[TEMPLATE] Generated analysis prompt of $($prompt.Length) characters"
    
    return $prompt
}

function Get-AvailableTemplates {
    [CmdletBinding()]
    param()
    
    return @{
        DocumentationTemplates = @('Function', 'Module', 'Class', 'API')
        AnalysisTemplates = @('Security', 'Performance', 'Quality', 'Dependency', 'Inheritance', 'Pattern', 'Refactoring')
        TemplateEngine = "PowerShell string interpolation with {{variable}} placeholders"
        SupportedLanguages = @('PowerShell', 'CSharp', 'Python', 'JavaScript', 'TypeScript')
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Get-FunctionDocumentationTemplate',
    'Get-ModuleDocumentationTemplate', 
    'Get-ClassDocumentationTemplate',
    'Get-APIDocumentationTemplate',
    'Get-SecurityAnalysisTemplate',
    'Get-PerformanceAnalysisTemplate',
    'Get-QualityAnalysisTemplate',
    'Get-DependencyAnalysisTemplate',
    'Get-InheritanceAnalysisTemplate',
    'Get-PatternDetectionTemplate',
    'Get-RefactoringTemplate',
    'Invoke-TemplateSubstitution',
    'New-DocumentationPromptFromTemplate',
    'New-AnalysisPromptFromTemplate',
    'Get-AvailableTemplates'
)