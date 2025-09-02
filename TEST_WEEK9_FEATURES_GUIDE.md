# Testing Guide: Week 9 GitHub Integration Features
*Created: 2025-08-23*

## Prerequisites

### 1. GitHub Personal Access Token (PAT)
```powershell
# First, set up your GitHub PAT if not already done
Import-Module ".\Modules\Unity-Claude-GitHub" -Force
Set-GitHubPAT

# Test the PAT is working
Test-GitHubPAT
```

### 2. Test Repository Setup
You'll need a GitHub repository for testing. You can:
- Use an existing repository you own
- Create a test repository on GitHub
- Use the Unity-Claude-Automation repository itself

## Quick Test: Run the Automated Test Suite

```powershell
# Run the basic test suite (no API calls)
.\Test-Week9-AdvancedFeatures.ps1 -SkipAPITests -SaveResults

# Run full test suite (requires PAT)
.\Test-Week9-AdvancedFeatures.ps1 -SaveResults

# Run with specific test repository
.\Test-Week9-AdvancedFeatures.ps1 -TestOwner "YourGitHubUsername" -TestRepository "YourRepoName"
```

## Manual Testing: Step-by-Step

### Test 1: Issue Lifecycle Management

```powershell
# Import the module
Import-Module ".\Modules\Unity-Claude-GitHub" -Force

# 1. Get status of an existing issue (replace with your repo/issue)
$status = Get-GitHubIssueStatus -Owner "YourUsername" -Repository "YourRepo" -IssueNumber 1
$status | Format-List

# 2. Test Unity error resolution detection
# Create a mock error file
$mockErrors = @{
    errors = @()
    compilationSucceeded = $true
    errorCount = 0
    timestamp = (Get-Date).ToString("o")
} | ConvertTo-Json | Set-Content ".\current_errors.json"

# Test if an error is resolved
$resolved = Test-UnityErrorResolved -IssueNumber 1 -ErrorSignature "CS0246"
$resolved

# 3. Test automated closing (dry run - won't actually close)
Close-GitHubIssueIfResolved -Owner "YourUsername" -Repository "YourRepo" `
    -IssueNumber 1 -ErrorSignature "CS0246" -DryRun

# 4. Update issue state (be careful - this will modify the issue!)
# Update-GitHubIssueState -Owner "YourUsername" -Repository "YourRepo" `
#     -IssueNumber 1 -State "closed" -Comment "Testing Week 9 features"
```

### Test 2: Repository Management

```powershell
# 1. Test repository access
$access = Test-GitHubRepositoryAccess -Owner "microsoft" -Repository "PowerShell" `
    -TestIssueOperations -TestLabelOperations
$access | Format-List

# 2. Get Unity project category based on error context
$category = Get-UnityProjectCategory -ProjectName "MyGame" `
    -ErrorContext "Shader compilation failed with HLSL error"
$category
# Should return: Category = "graphics", Labels contains "shader"

# Test different categories
@(
    "NetworkManager connection failed",
    "Rigidbody collision error",
    "TextMeshPro component missing",
    "AudioSource not found",
    "Build failed for iOS platform"
) | ForEach-Object {
    $cat = Get-UnityProjectCategory -ProjectName "Test" -ErrorContext $_
    "$_ -> Category: $($cat.Category), Labels: $($cat.Labels -join ', ')"
}

# 3. Search across multiple repositories
$repos = @("microsoft/PowerShell", "PowerShell/PowerShell-Docs")
$results = Search-GitHubIssuesMultiRepo -Repositories $repos -Query "error" -MaxPerRepo 5
Write-Host "Found $($results.TotalCount) issues across $($repos.Count) repositories"
```

### Test 3: Performance & Analytics

```powershell
# 1. Get API usage statistics
$stats = Get-GitHubAPIUsageStats
$stats | Format-List

# Show rate limit status
Write-Host "Core API: $($stats.Core.Used)/$($stats.Core.Limit) used ($($stats.Core.PercentUsed)%)"
Write-Host "Reset in: $($stats.Core.MinutesUntilReset) minutes"

# 2. Get usage with history (if available)
$statsWithHistory = Get-GitHubAPIUsageStats -IncludeHistory -Since (Get-Date).AddHours(-24)
$statsWithHistory.History

# 3. Test cache system (internal functions)
$module = Get-Module Unity-Claude-GitHub
& $module {
    # Initialize cache
    $cache = Initialize-GitHubIssueCache -MaxCacheAge 30
    $cache
    
    # Store something in cache
    $testData = @{Issue = "Test"; Number = 123}
    Set-CachedGitHubIssue -CacheKey "test/repo/123" -Data $testData
    
    # Retrieve from cache
    $cached = Get-CachedGitHubIssue -CacheKey "test/repo/123"
    $cached
}
```

### Test 4: Configuration Management

```powershell
# 1. Get current configuration
$config = Get-GitHubIntegrationConfig
$config | ConvertTo-Json -Depth 3

# 2. Test configuration validation
Test-GitHubIntegrationConfig

# 3. Get configured repositories
$repos = Get-GitHubRepositories -IncludeMetadata -TestAccess
$repos | Format-Table FullName, IsDefault, AccessTestPassed

# 4. Set up multi-repository configuration (example)
$newConfig = @{
    repositories = @(
        @{
            owner = "YourUsername"
            name = "YourRepo1"
            isDefault = $true
            unityProjects = @(
                @{name = "Project1"; pathPattern = "*Project1*"}
            )
        },
        @{
            owner = "YourUsername"
            name = "YourRepo2"
            isDefault = $false
            unityProjects = @(
                @{name = "Project2"; pathPattern = "*Project2*"}
            )
        }
    )
}
# Set-GitHubIntegrationConfig -Config $newConfig
```

## Integration Test: Complete Workflow

```powershell
# Complete workflow test
function Test-CompleteWorkflow {
    param(
        [string]$Owner = "YourUsername",
        [string]$Repository = "YourRepo"
    )
    
    Write-Host "Starting Complete Workflow Test" -ForegroundColor Cyan
    
    # 1. Check repository access
    Write-Host "`n1. Testing repository access..." -ForegroundColor Yellow
    $access = Test-GitHubRepositoryAccess -Owner $Owner -Repository $Repository
    if (-not $access.Success) {
        Write-Error "Cannot access repository"
        return
    }
    Write-Host "   Access confirmed: $($access.Permissions -join ', ')" -ForegroundColor Green
    
    # 2. Check API rate limits
    Write-Host "`n2. Checking API rate limits..." -ForegroundColor Yellow
    $stats = Get-GitHubAPIUsageStats
    Write-Host "   Rate limit: $($stats.Core.Remaining)/$($stats.Core.Limit) remaining" -ForegroundColor Green
    
    # 3. Search for existing issues
    Write-Host "`n3. Searching for Unity error issues..." -ForegroundColor Yellow
    $issues = Search-GitHubIssues -Owner $Owner -Repository $Repository -Query "Unity error"
    Write-Host "   Found $($issues.Count) related issues" -ForegroundColor Green
    
    # 4. Test error categorization
    Write-Host "`n4. Testing error categorization..." -ForegroundColor Yellow
    $errorContexts = @{
        "Shader compilation error" = "graphics"
        "NetworkManager failed" = "networking"
        "Rigidbody2D error" = "physics"
        "Canvas rendering issue" = "ui"
    }
    
    foreach ($context in $errorContexts.Keys) {
        $cat = Get-UnityProjectCategory -ProjectName "TestProject" -ErrorContext $context
        $expected = $errorContexts[$context]
        if ($cat.Category -eq $expected) {
            Write-Host "   ✓ '$context' -> $($cat.Category)" -ForegroundColor Green
        } else {
            Write-Host "   ✗ '$context' -> Expected: $expected, Got: $($cat.Category)" -ForegroundColor Red
        }
    }
    
    # 5. Test Unity error resolution
    Write-Host "`n5. Testing Unity error resolution detection..." -ForegroundColor Yellow
    $resolved = Test-UnityErrorResolved -IssueNumber 999 -ErrorSignature "CS0246"
    Write-Host "   Resolution check complete: IsResolved=$($resolved.IsResolved)" -ForegroundColor Green
    
    Write-Host "`nWorkflow test complete!" -ForegroundColor Cyan
}

# Run the workflow test
Test-CompleteWorkflow -Owner "YourUsername" -Repository "YourRepo"
```

## Troubleshooting

### Common Issues and Solutions

1. **"GitHub PAT not configured"**
   ```powershell
   Set-GitHubPAT
   # Enter your PAT when prompted
   ```

2. **"Cannot access repository"**
   - Verify PAT has appropriate scopes (repo, read:org)
   - Check repository exists and you have access
   
3. **"Rate limit exceeded"**
   ```powershell
   # Check when rate limit resets
   $stats = Get-GitHubAPIUsageStats
   Write-Host "Reset at: $($stats.Core.ResetTime)"
   ```

4. **Module not loading**
   ```powershell
   # Force reload the module
   Remove-Module Unity-Claude-GitHub -ErrorAction SilentlyContinue
   Import-Module ".\Modules\Unity-Claude-GitHub" -Force -Verbose
   
   # Check exported functions
   Get-Command -Module Unity-Claude-GitHub | Where-Object { $_.Name -like "*GitHub*" }
   ```

5. **Cache issues**
   ```powershell
   # Clear cache
   Remove-Item "$env:TEMP\GitHubIssueCache" -Recurse -Force -ErrorAction SilentlyContinue
   ```

## Performance Benchmarks

Run these to verify performance improvements:

```powershell
# Measure API call performance
Measure-Command {
    Get-GitHubIssueStatus -Owner "microsoft" -Repository "PowerShell" -IssueNumber 1
} | Select-Object TotalMilliseconds

# Test cache performance (second call should be faster)
Measure-Command {
    # First call - hits API
    Search-GitHubIssues -Owner "microsoft" -Repository "PowerShell" -Query "test"
} | Select-Object TotalMilliseconds

Measure-Command {
    # Second call - should use cache if implemented
    Search-GitHubIssues -Owner "microsoft" -Repository "PowerShell" -Query "test"
} | Select-Object TotalMilliseconds
```

## Expected Results

When all tests pass, you should see:
- ✅ All 9 public functions accessible
- ✅ Repository access validation working
- ✅ Error categorization accurate
- ✅ API rate limit monitoring functional
- ✅ Cache system operational
- ✅ Multi-repository search working
- ✅ Issue lifecycle management functional

## Next Steps

After testing:
1. Configure for your actual Unity projects
2. Set up automated issue creation workflow
3. Enable issue auto-closing for resolved errors
4. Monitor API usage and optimize as needed