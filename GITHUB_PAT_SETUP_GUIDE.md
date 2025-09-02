# GitHub PAT and Configuration Setup Guide
*Created: 2025-08-23*

## Step 1: Create a GitHub Personal Access Token (PAT)

### 1.1 Go to GitHub Settings
1. Log into GitHub.com
2. Click your profile picture (top right)
3. Select **Settings**
4. Scroll down to **Developer settings** (bottom of left sidebar)
5. Click **Personal access tokens**
6. Select **Tokens (classic)**

### 1.2 Generate New Token
1. Click **Generate new token** → **Generate new token (classic)**
2. Give it a descriptive name: `Unity-Claude-Automation`
3. Set expiration (90 days recommended for security)
4. Select the following scopes:
   - ✅ **repo** (Full control of private repositories)
     - This includes: repo:status, repo_deployment, public_repo, repo:invite
   - ✅ **workflow** (Update GitHub Action workflows)
   - ✅ **read:org** (Read org and team membership)
   - Optional: **notifications** (Access notifications)

5. Click **Generate token**
6. **IMPORTANT**: Copy the token immediately! You won't be able to see it again.

### 1.3 Token Format
Your token should look like: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

## Step 2: Configure PAT in Unity-Claude System

### 2.1 Set the PAT in PowerShell
```powershell
# Import the module
Import-Module ".\Modules\Unity-Claude-GitHub" -Force

# Set your PAT (it will be securely encrypted using Windows DPAPI)
Set-GitHubPAT

# When prompted, paste your token and press Enter
# The token will be hidden as you type for security
```

### 2.2 Verify PAT is Working
```powershell
# Test the PAT
Test-GitHubPAT

# Expected output:
# ✓ GitHub PAT is configured and valid
# User: YourGitHubUsername
# Rate Limit: 5000 requests/hour
```

## Step 3: Configure GitHub Repositories

### 3.1 Create Configuration File
Create a configuration for your repositories:

```powershell
# Create a configuration object
$config = @{
    defaultOwner = "YourGitHubUsername"  # Replace with your username
    defaultRepository = "YourMainRepo"    # Replace with your main repo
    repositories = @(
        @{
            owner = "YourGitHubUsername"
            name = "Unity-Claude-Automation"
            isDefault = $true
            priority = 10
            unityProjects = @(
                @{
                    name = "Sound-and-Shoal"
                    pathPattern = "*Sound-and-Shoal*"
                    category = "main"
                }
            )
            categories = @{
                graphics = @{
                    labels = @("graphics", "shader", "rendering")
                    priority = 2
                }
                networking = @{
                    labels = @("networking", "multiplayer")
                    priority = 2
                }
                physics = @{
                    labels = @("physics", "collision")
                    priority = 2
                }
            }
            labels = @("unity", "automation")
        }
        # Add more repositories as needed
        @{
            owner = "YourGitHubUsername"
            name = "AnotherUnityProject"
            isDefault = $false
            priority = 5
            unityProjects = @(
                @{
                    name = "SecondProject"
                    pathPattern = "*SecondProject*"
                }
            )
        }
    )
    enableAutoClose = $true
    autoCloseConfidenceThreshold = 0.8
    cacheEnabled = $true
    cacheMaxAge = 30  # minutes
}

# Save the configuration
Set-GitHubIntegrationConfig -Config $config
```

### 3.2 Alternative: Use Configuration Wizard
```powershell
# Run the configuration helper
$config = @{
    repositories = @(
        @{
            owner = Read-Host "Enter GitHub username/organization"
            name = Read-Host "Enter repository name"
            isDefault = $true
            unityProjects = @()
        }
    )
}

Set-GitHubIntegrationConfig -Config $config
```

### 3.3 Verify Configuration
```powershell
# Test configuration
Test-GitHubIntegrationConfig

# View current configuration
Get-GitHubIntegrationConfig | ConvertTo-Json -Depth 5

# Test repository access
Test-GitHubRepositoryAccess -Owner "YourUsername" -Repository "YourRepo"
```

## Step 4: Test Everything Works

### 4.1 Quick Validation
```powershell
# Run this test script to verify setup
function Test-GitHubSetup {
    Write-Host "`nTesting GitHub Setup..." -ForegroundColor Cyan
    
    # 1. Test PAT
    Write-Host "`n1. Testing PAT..." -ForegroundColor Yellow
    $patTest = Test-GitHubPAT
    if ($patTest) {
        Write-Host "   ✓ PAT is valid" -ForegroundColor Green
    } else {
        Write-Host "   ✗ PAT is not configured or invalid" -ForegroundColor Red
        return $false
    }
    
    # 2. Test configuration
    Write-Host "`n2. Testing configuration..." -ForegroundColor Yellow
    $config = Get-GitHubIntegrationConfig
    if ($config.repositories.Count -gt 0) {
        Write-Host "   ✓ Configuration found with $($config.repositories.Count) repositories" -ForegroundColor Green
    } else {
        Write-Host "   ✗ No repositories configured" -ForegroundColor Red
        return $false
    }
    
    # 3. Test repository access
    Write-Host "`n3. Testing repository access..." -ForegroundColor Yellow
    $repo = $config.repositories[0]
    $access = Test-GitHubRepositoryAccess -Owner $repo.owner -Repository $repo.name
    if ($access.Success) {
        Write-Host "   ✓ Can access $($repo.owner)/$($repo.name)" -ForegroundColor Green
        Write-Host "   Permissions: $($access.Permissions -join ', ')" -ForegroundColor Gray
    } else {
        Write-Host "   ✗ Cannot access repository: $($access.Error)" -ForegroundColor Red
        return $false
    }
    
    # 4. Test API rate limit
    Write-Host "`n4. Checking API rate limit..." -ForegroundColor Yellow
    $stats = Get-GitHubAPIUsageStats
    Write-Host "   Rate limit: $($stats.Core.Remaining)/$($stats.Core.Limit) remaining" -ForegroundColor Green
    if ($stats.Core.PercentUsed -gt 80) {
        Write-Host "   ⚠ Warning: Over 80% of rate limit used" -ForegroundColor Yellow
    }
    
    Write-Host "`n✓ GitHub setup is complete and working!" -ForegroundColor Green
    return $true
}

# Run the test
Test-GitHubSetup
```

### 4.2 Full Test Suite
```powershell
# Run the complete Week 9 test suite with API tests enabled
.\Test-Week9-AdvancedFeatures.ps1 -SaveResults

# Or test with specific repository
.\Test-Week9-AdvancedFeatures.ps1 -TestOwner "YourUsername" -TestRepository "YourRepo"
```

## Step 5: Common Use Cases

### 5.1 Create an Issue from Unity Error
```powershell
# Format Unity error as GitHub issue
$error = @{
    errorCode = "CS0246"
    message = "The type or namespace 'NetworkManager' could not be found"
    file = "Assets/Scripts/Player.cs"
    line = 42
}

$issue = Format-UnityErrorAsIssue -UnityError $error
New-GitHubIssue -Owner "YourUsername" -Repository "YourRepo" `
    -Title $issue.title -Body $issue.body -Labels $issue.labels
```

### 5.2 Check and Close Resolved Issues
```powershell
# Check if Unity error is resolved and close issue if it is
Close-GitHubIssueIfResolved -Owner "YourUsername" -Repository "YourRepo" `
    -IssueNumber 123 -ErrorSignature "CS0246" -MinConfidence 0.7
```

### 5.3 Search Across Multiple Repositories
```powershell
# Search for issues across all configured repositories
$repos = Get-GitHubRepositories
$results = Search-GitHubIssuesMultiRepo -Repositories $repos -Query "Unity error"
Write-Host "Found $($results.TotalCount) issues across repositories"
```

## Troubleshooting

### PAT Issues
```powershell
# If PAT is not working, clear and reset it
Clear-GitHubPAT
Set-GitHubPAT

# Check PAT expiration
$pat = Get-GitHubPAT
Write-Host "PAT Status: $($pat.Status)"
```

### Permission Errors
If you get 404 or 403 errors:
1. Verify your PAT has the `repo` scope
2. Check you have access to the repository
3. For private repos, ensure PAT has full `repo` scope
4. For organizations, check if SSO is required

### Rate Limiting
```powershell
# Check your current rate limit status
$stats = Get-GitHubAPIUsageStats
Write-Host "Remaining: $($stats.Core.Remaining)"
Write-Host "Reset at: $($stats.Core.ResetTime)"
```

## Security Best Practices

1. **Never commit your PAT** to version control
2. **Rotate PATs regularly** (every 90 days)
3. **Use minimum required scopes**
4. **Store PAT encrypted** (automatic with Set-GitHubPAT)
5. **Monitor PAT usage** with Get-GitHubAPIUsageStats

## Environment Variables (Optional)

You can also set PAT via environment variable:
```powershell
# Set in PowerShell session
$env:GITHUB_TOKEN = "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Or set permanently (Windows)
[System.Environment]::SetEnvironmentVariable("GITHUB_TOKEN", "ghp_xxx", "User")
```

## Next Steps

After setup is complete:
1. ✅ Create test issues to verify workflow
2. ✅ Test Unity error categorization
3. ✅ Set up automated issue creation for Unity errors
4. ✅ Configure issue auto-closing thresholds
5. ✅ Monitor API usage and optimize caching

## Quick Reference Commands

```powershell
# Essential commands
Set-GitHubPAT                    # Configure PAT
Test-GitHubPAT                   # Verify PAT works
Get-GitHubIntegrationConfig      # View configuration
Set-GitHubIntegrationConfig      # Update configuration
Test-GitHubIntegrationConfig     # Validate configuration
Get-GitHubRepositories           # List configured repos
Test-GitHubRepositoryAccess      # Test repo access
Get-GitHubAPIUsageStats          # Check API limits
```