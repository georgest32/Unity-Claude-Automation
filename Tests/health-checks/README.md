# Unity-Claude-Automation Health Check System (Refactored)

## Overview

This is a modular health check system that replaces the monolithic `Test-SystemHealth.ps1` script. The new architecture provides better maintainability, reusability, and testability by splitting functionality into focused components.

## Architecture

```
tests/health-checks/
├── shared/                           # Shared utilities
│   └── Test-HealthUtilities.psm1    # Common functions and test result management
├── components/                       # Individual test components  
│   ├── docker/                       # Docker-related health checks
│   │   └── Test-DockerHealth.ps1
│   ├── powershell/                   # PowerShell module health checks
│   │   └── Test-PowerShellModules.ps1
│   ├── api/                         # API and service endpoint tests
│   │   └── Test-APIHealth.ps1
│   ├── filesystem/                   # File system and disk space tests
│   │   └── Test-FileSystemHealth.ps1
│   └── performance/                  # Performance metrics and resource usage
│       └── Test-PerformanceMetrics.ps1
├── Invoke-ModularHealthCheck.ps1     # Main orchestrator script
└── README.md                         # This documentation
```

## Benefits of the Modular Architecture

### 1. **Separation of Concerns**
- Each component focuses on a specific aspect of system health
- Easier to understand, modify, and debug individual components
- Clear boundaries between different types of health checks

### 2. **Maintainability**
- Changes to Docker checks don't affect PowerShell module tests
- Individual components can be updated independently
- Easier to add new health check categories

### 3. **Reusability**
- Components can be run independently for focused testing
- Shared utilities reduce code duplication
- Common patterns available for new components

### 4. **Testability**
- Each component can be unit tested separately
- Mocking and stubbing easier with focused components
- Better isolation of test failures

### 5. **Performance**
- Parallel execution of independent components
- Faster overall execution for comprehensive tests
- Better resource utilization

## Usage

### Basic Usage

```powershell
# Run the refactored system (recommended)
.\Test-SystemHealth-Refactored.ps1 -TestType Full -SaveResults

# Run the modular system directly
.\tests\health-checks\Invoke-ModularHealthCheck.ps1 -TestType Full -SaveResults
```

### Component-Specific Testing

```powershell
# Test only Docker components
.\tests\health-checks\Invoke-ModularHealthCheck.ps1 -Components Docker

# Test multiple specific components
.\tests\health-checks\Invoke-ModularHealthCheck.ps1 -Components Docker,PowerShell,API

# Test with parallel execution
.\tests\health-checks\Invoke-ModularHealthCheck.ps1 -TestType Full -Parallel
```

### Individual Component Testing

```powershell
# Test Docker health independently
.\tests\health-checks\components\docker\Test-DockerHealth.ps1 -TestType Full

# Test PowerShell modules with detailed output
.\tests\health-checks\components\powershell\Test-PowerShellModules.ps1 -Detailed

# Performance metrics only
.\tests\health-checks\components\performance\Test-PerformanceMetrics.ps1
```

## Test Types

### Quick (Default)
- Essential components only (Docker, PowerShell, API)
- Basic connectivity and availability tests
- Fastest execution time

### Full
- All components except performance metrics
- Comprehensive functionality testing
- Recommended for regular health checks

### Critical
- All components with enhanced error detection
- File system integrity checks
- Critical path validation

### Performance  
- All components plus detailed performance metrics
- Resource usage analysis
- System load and responsiveness testing

## Components

### Docker Component
- **Purpose**: Docker daemon and container health
- **Tests**: Daemon status, container health, networks, volumes
- **Critical**: Yes - required for system operation

### PowerShell Component
- **Purpose**: PowerShell module integrity and functionality
- **Tests**: Module loading, function exports, help documentation
- **Critical**: Yes - core system functionality

### API Component
- **Purpose**: Service endpoints and API functionality  
- **Tests**: Endpoint availability, response validation, performance
- **Critical**: Yes - user-facing services

### FileSystem Component
- **Purpose**: Directory structure and disk space
- **Tests**: Critical directories, disk space, permissions
- **Critical**: Partial - disk space is critical

### Performance Component
- **Purpose**: System performance and resource usage
- **Tests**: CPU, memory, disk I/O, network performance
- **Critical**: No - monitoring and optimization

## Shared Utilities

The `Test-HealthUtilities.psm1` module provides common functionality:

- **Initialize-HealthCheck**: Set up test session
- **Write-TestLog**: Formatted logging with timestamps
- **Add-TestResult**: Standardized result tracking
- **Test-ServiceHealth**: HTTP endpoint testing
- **Save-TestResults**: JSON and HTML report generation
- **Show-TestSummary**: Results summary and exit codes

## Adding New Components

### 1. Create Component Directory
```powershell
New-Item -Path "tests\health-checks\components\newcomponent" -ItemType Directory
```

### 2. Create Component Script
```powershell
# Template structure
[CmdletBinding()]
param(
    [ValidateSet('Quick', 'Full', 'Critical', 'Performance')]
    [string]$TestType = 'Quick'
)

# Import shared utilities
Import-Module "$PSScriptRoot\..\..\shared\Test-HealthUtilities.psm1" -Force

function Test-YourFeature {
    # Implementation here
    Add-TestResult -TestName "Your Feature" -Status 'Pass' -Details "Working correctly"
}

function Invoke-YourComponentHealthCheck {
    Write-TestLog "Starting your component health checks..." -Level Info
    Test-YourFeature
    Write-TestLog "Your component health checks completed" -Level Info
}

# Execute if run directly
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-YourComponentHealthCheck
}
```

### 3. Update Orchestrator Configuration
Add your component to the `$ComponentConfig` hashtable in `Invoke-ModularHealthCheck.ps1`:

```powershell
YourComponent = @{
    Name = "Your Component Name"
    ScriptPath = "components\newcomponent\Test-YourComponent.ps1"
    Priority = 6
    Required = $false
    Description = "Description of what this component tests"
}
```

## Migration from Monolithic Script

The original `Test-SystemHealth.ps1` has been preserved and a new `Test-SystemHealth-Refactored.ps1` wrapper provides backward compatibility while using the modular system.

### Key Differences

| Aspect | Monolithic | Modular |
|--------|------------|---------|
| **Structure** | Single 555-line file | Multiple focused files |
| **Maintainability** | Difficult to modify | Easy to maintain components |
| **Testing** | All-or-nothing | Component-specific testing |
| **Performance** | Sequential execution | Optional parallel execution |
| **Reusability** | Minimal | High - components are reusable |
| **Debugging** | Complex | Component isolation |

### Migration Benefits

1. **Reduced Complexity**: Each component handles 50-150 lines instead of 555
2. **Better Error Isolation**: Failures in one component don't affect others  
3. **Easier Debugging**: Focus on specific component functionality
4. **Enhanced Testing**: Individual components can be thoroughly tested
5. **Future Extensibility**: New health checks easily added as components

## Troubleshooting

### Component Not Found
```powershell
# Verify component structure
Get-ChildItem .\tests\health-checks\components -Recurse -Name "*.ps1"
```

### Missing Shared Utilities
```powershell
# Check shared utilities
Test-Path .\tests\health-checks\shared\Test-HealthUtilities.psm1
```

### Permission Issues
```powershell
# Run with appropriate execution policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Parallel Execution Issues
```powershell
# Use sequential execution if parallel fails
.\tests\health-checks\Invoke-ModularHealthCheck.ps1 -TestType Full -ShowProgress
```

## Best Practices

### For Component Development
1. Import shared utilities at the top
2. Use consistent naming conventions
3. Provide meaningful test names and details
4. Include proper error handling
5. Export only necessary functions
6. Follow the established parameter patterns

### For System Operations
1. Use Quick tests for routine monitoring
2. Use Full tests for comprehensive health checks
3. Use Critical tests before deployments
4. Use Performance tests for optimization
5. Always save results for trending analysis
6. Consider parallel execution for time-sensitive operations

---

## Version History

- **v1.0** (2025-08-25): Initial modular refactoring
  - Split monolithic script into focused components
  - Added parallel execution capability
  - Implemented shared utilities framework
  - Created component-based architecture