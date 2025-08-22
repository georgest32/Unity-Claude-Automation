# Phase 4: GitHub Integration - Week 8, Days 1-2 Analysis
## Authentication & Security Implementation
*Date: 2025-08-22*
*Time: 18:15*
*Topics: PowerShellForGitHub Integration, PAT Storage, Rate Limiting*

## Summary Information
- **Problem**: Implement GitHub integration foundation with secure authentication
- **Previous Context**: Phase 3 Windows Event Log Integration complete with 100% test pass rate
- **Current State**: No GitHub integration exists, starting from scratch
- **Objective**: Establish secure GitHub API foundation with authentication and rate limiting

## Home State Review

### Project Structure
```
Unity-Claude-Automation/
├── Modules/                    # PowerShell modules
│   ├── Unity-Claude-Core/
│   ├── Unity-Claude-EventLog/
│   └── [No GitHub module yet]
├── API-Integration/            # API integration scripts
├── ClaudeResponses/           # Response storage
└── Testing/                   # Test infrastructure
```

### Current Implementation Status
- Phase 1: Parallel Processing - Not yet implemented
- Phase 2: Email/Webhook Notifications - Complete (Week 6 Day 5)
- Phase 3: Windows Event Log Integration - Complete (Week 7 Day 5)
- Phase 4: GitHub Integration - Starting now

## Implementation Plan Status

### Week 8: GitHub API Foundation
**Days 1-2: Authentication & Security** (CURRENT)
- Hour 1-3: Implement PowerShellForGitHub module integration
- Hour 4-6: Create secure PAT storage and management
- Hour 7-8: Build rate limiting and retry logic framework

## Requirements Analysis

### Authentication Requirements
1. Support for GitHub Personal Access Tokens (PAT)
2. Secure credential storage (encrypted)
3. Token validation and expiration handling
4. Multiple repository support
5. Fallback authentication methods

### Security Requirements
1. Encrypted storage using Windows Data Protection API (DPAPI)
2. Secure string handling for PAT
3. Audit logging for all GitHub operations
4. Principle of least privilege for token scopes
5. Token rotation capabilities

### Rate Limiting Requirements
1. Respect GitHub API rate limits (5000 req/hr authenticated)
2. Implement exponential backoff
3. Queue management for bulk operations
4. Rate limit status monitoring
5. Graceful degradation when limits approached

## Research Findings (First 5 Queries)

### 1. PowerShellForGitHub Module
- **Installation**: `Install-Module -Name PowerShellForGitHub`
- **Authentication**: `Set-GitHubAuthentication` with PAT as SecureString
- **Session Management**: Support for persistent and session-only auth
- **Configuration**: Default owner/repo settings to reduce typing
- **Features**: Full GitHub API coverage with pipelining support

### 2. Secure Credential Storage (DPAPI)
- **DPAPI**: Windows Data Protection API encrypts for current user/machine
- **SecureString**: In-memory protection prevents plaintext exposure
- **Export-Clixml**: Stores PSCredential objects encrypted
- **Limitations**: User and machine bound - cannot decrypt elsewhere
- **Alternative**: AES encryption with keys for cross-machine use

### 3. GitHub API Rate Limiting
- **Authenticated**: 5000 requests/hour (15000 for Enterprise Cloud)
- **Headers**: X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset
- **Secondary Limits**: 80 requests/min, 500 requests/hour for content
- **Monitoring**: Check headers, use /rate_limit endpoint
- **Best Practice**: Exponential backoff with jitter

### 4. PAT vs OAuth/GitHub Apps
- **PAT Pros**: Simple, quick setup, personal use
- **PAT Cons**: User-bound, broad permissions, manual rotation
- **GitHub Apps Pros**: Fine-grained permissions, org-level, automated tokens
- **GitHub Apps Cons**: More complex setup, overhead for simple tasks
- **Recommendation**: PAT for Unity-Claude automation (simpler, sufficient)

### 5. PowerShell Implementation Patterns
- **Retry Logic**: Native exponential backoff coming to PowerShell
- **Current Method**: Custom retry with exponential backoff + jitter
- **Queue Management**: Prevent request spikes
- **Error Handling**: Respect Retry-After header for 429 responses

## Research Findings (Queries 6-10)

### 6. PowerShell Module Structure
- **Layout**: ModuleName.psd1 (manifest), ModuleName.psm1 (root), Public/, Private/, Tests/
- **Manifest**: Use New-ModuleManifest with RootModule, FunctionsToExport
- **Organization**: One function per file, dot-source in .psm1
- **Export**: Explicit function list in FunctionsToExport for auto-loading
- **Testing**: Test-ModuleManifest to validate structure

### 7. GitHub Issue Creation API
- **Endpoint**: POST to /repos/{owner}/{repo}/issues
- **Body Format**: JSON with title, body (markdown), labels[], assignees[]
- **PowerShellForGitHub**: Provides New-GitHubIssue cmdlet
- **Headers**: Authorization (Bearer token), Accept (vnd.github.v3+json)
- **Response**: Returns issue number, URL, and full issue object

### 8. Error Handling Patterns
- **Try-Catch**: Wrap all API calls, check $_.Exception.Response.StatusCode
- **401**: Authentication failure - check token
- **403/429**: Rate limiting - use exponential backoff
- **404**: Resource not found - don't retry
- **500-504**: Server errors - retry with backoff
- **Retry-After**: Always respect header value for 429 responses

### 9. Token Rotation Strategies
- **New Policies**: GitHub allows 1-366 day lifetime limits (Oct 2024)
- **Automation**: GitHub Actions workflows for rotation
- **Monitoring**: Track expiration dates, alert before expiry
- **Storage**: Azure Key Vault or secrets manager
- **Best Practice**: Always set expiration, never use indefinite tokens

### 10. Pester Testing Approaches
- **Structure**: Describe/Context/It blocks with Should assertions
- **Mocking**: Mock external API calls with Mock cmdlet
- **TestDrive**: Use for temporary file operations
- **Coverage**: Measure with Pester's code coverage tools
- **CI Integration**: Export results in JaCoCo format

## Granular Implementation Plan

### Week 8, Days 1-2: Authentication & Security

#### Day 1: Module Foundation and PAT Storage (Hours 1-8)

**Hour 1-2: Module Structure Setup**
1. Create Unity-Claude-GitHub module folder structure
2. Create module manifest with New-ModuleManifest
3. Set up Public/Private/Tests directories
4. Create root module script with dot-sourcing

**Hour 3-4: PowerShellForGitHub Integration**
1. Install PowerShellForGitHub module
2. Create wrapper functions for common operations
3. Implement configuration management
4. Set up default repository settings

**Hour 5-6: Secure Credential Storage**
1. Create New-GitHubCredential function using DPAPI
2. Implement Export-GitHubCredential with Export-Clixml
3. Create Import-GitHubCredential for retrieval
4. Add Test-GitHubCredential for validation

**Hour 7-8: PAT Management Functions**
1. Create Set-GitHubPAT with SecureString handling
2. Implement Get-GitHubPAT for secure retrieval
3. Add Clear-GitHubPAT for cleanup
4. Create Update-GitHubPAT for rotation

#### Day 2: Rate Limiting and Error Handling (Hours 1-8)

**Hour 1-2: Rate Limit Monitoring**
1. Create Get-GitHubRateLimit function
2. Implement header parsing for X-RateLimit-*
3. Add threshold warnings (80% of limit)
4. Create rate limit status display

**Hour 3-4: Exponential Backoff Implementation**
1. Create Invoke-GitHubAPIWithRetry function
2. Implement exponential delay calculation
3. Add jitter to prevent collision
4. Set maximum retry attempts (5)

**Hour 5-6: Error Handling Framework**
1. Create comprehensive error handler
2. Implement status code specific actions
3. Add logging for all API operations
4. Create error recovery strategies

**Hour 7-8: Integration and Testing**
1. Create Pester test suite structure
2. Mock GitHub API responses
3. Test authentication scenarios
4. Validate rate limiting behavior

## Critical Decisions

### Authentication Method
**Decision**: Use PAT instead of GitHub App
**Rationale**: Simpler implementation, sufficient for Unity-Claude automation, easier to manage for single-user scenario

### Storage Method
**Decision**: DPAPI with Export-Clixml
**Rationale**: Native Windows security, no additional dependencies, secure for single-machine use

### Retry Strategy
**Decision**: Exponential backoff with jitter, max 5 attempts
**Rationale**: Prevents API overload, handles transient failures, respects rate limits

## Success Criteria
1. Secure PAT storage with encryption
2. Automatic token validation on use
3. Rate limit monitoring with warnings
4. Exponential backoff for all API calls
5. Comprehensive error handling
6. 90%+ test coverage

## Risk Mitigation
1. **Token Exposure**: Use SecureString throughout, clear from memory
2. **Rate Limiting**: Implement conservative limits, monitor usage
3. **API Changes**: Version lock dependencies, monitor deprecations
4. **Token Expiry**: Implement expiration monitoring, rotation reminders