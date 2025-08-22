# GitHub Issue Management System Analysis
*Phase 4, Week 8, Days 3-4 Implementation Document*
*Created: 2025-08-22*
*Type: Implementation Analysis*

## Summary Information
- **Problem**: Implementing GitHub Issue Management System for Unity-Claude Automation
- **Date/Time**: 2025-08-22 16:30:00
- **Previous Context**: Phase 4 Week 8 Days 1-2 (Authentication & Security) completed
- **Topics**: GitHub API, Issue Creation, Issue Search, Deduplication, PowerShell Integration

## Home State Analysis
### Project Structure
- Unity-Claude-Automation system with modular PowerShell architecture
- Unity-Claude-GitHub module already initialized with authentication framework
- Secure PAT storage and rate limiting already implemented
- 6 public functions exist: Set/Get/Test/Clear-GitHubPAT, Get-GitHubRateLimit, Invoke-GitHubAPIWithRetry

### Current Module State
- **Module Version**: 1.0.0
- **Authentication**: DPAPI-encrypted PAT storage implemented
- **Rate Limiting**: Exponential backoff and retry logic in place
- **Configuration**: JSON-based config with module variables
- **Dependencies**: Optional PowerShellForGitHub module support

## Objectives and Implementation Plan
### Short-term Goals (Days 3-4)
1. **Hour 1-4**: Create GitHub issue creation automation
   - New-GitHubIssue function with Unity error context
   - Issue template generation from Unity errors
   - Label and milestone assignment
   - Error metadata preservation

2. **Hour 5-8**: Implement issue search and deduplication logic
   - Search-GitHubIssues function with filtering
   - Duplicate detection based on error signature
   - Issue update vs new issue decision logic
   - Comment addition for recurring errors

### Long-term Goals
- Full issue lifecycle management (Week 9)
- Multi-repository support
- Automated issue closing for resolved errors
- Performance optimization and caching

## Current Implementation Status
### Completed Components
- Authentication framework (Set/Get/Test/Clear-GitHubPAT)
- Rate limiting (Invoke-GitHubAPIWithRetry, Get-GitHubRateLimit)
- Secure credential storage (DPAPI encryption)
- Module configuration system

### Pending Implementation
- Issue creation functions
- Issue search and filtering
- Deduplication logic
- Template generation
- Error signature hashing
- Integration with Unity error export

## Research Requirements
1. GitHub Issues API v3 endpoints and parameters
2. Issue search syntax and operators
3. Label and milestone management via API
4. Comment threading and updates
5. Error signature generation strategies
6. Deduplication algorithms for similar errors
7. PowerShell HTTP request patterns
8. JSON payload construction for issues
9. Rate limit considerations for issue operations
10. Best practices for issue templates

## Preliminary Solution Design
### New Functions to Implement
1. **New-GitHubIssue**: Create issues from Unity errors
2. **Search-GitHubIssues**: Search existing issues
3. **Get-GitHubIssue**: Retrieve specific issue details
4. **Update-GitHubIssue**: Update existing issues
5. **Add-GitHubIssueComment**: Add comments to issues
6. **Get-UnityErrorSignature**: Generate unique error signatures
7. **Test-GitHubIssueDuplicate**: Check for duplicates
8. **Format-UnityErrorAsIssue**: Convert errors to issue format

### Integration Points
- Unity-Claude-Errors module for error data
- Unity-Claude-SystemStatus for monitoring
- Export-ErrorsForClaude for error formatting
- Submit-ErrorsToClaude for workflow integration

## Research Findings

### 1. GitHub API v3 Authentication (Query 1)
- Personal Access Token (PAT) with basic auth is standard approach
- Token must be base64-encoded for basic authentication
- Headers require: Authorization, Content-Type (application/json), Accept (application/vnd.github+json)
- TLS 1.2 must be enforced: [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

### 2. GitHub Issues API Endpoints (Query 2)
- Create issue: POST /repos/{owner}/{repo}/issues
- Update issue: PATCH /repos/{owner}/{repo}/issues/{issue_number}
- List issues: GET /repos/{owner}/{repo}/issues
- Search issues: GET /search/issues?q={query}
- Add comment: POST /repos/{owner}/{repo}/issues/{issue_number}/comments
- 404 errors indicate auth issues for private repos (not 403)

### 3. Search Query Syntax (Query 3)
- Advanced search supports AND/OR/NOT operators with parentheses
- Example: is:issue state:open (type:Bug OR type:Epic)
- Comma syntax for OR on labels: label:"bug","wip"
- Known pagination bug causes duplicates over 100 results
- Five operator limit per query
- Space between terms defaults to AND

### 4. Error Signature Generation (Query 4)
- Unity Burst compiler uses hash for method references
- Hash-based identification for duplicate detection
- Common issues: hash generation failures with static properties
- Solutions: version updates, deterministic compilation toggle
- Fixed-size buffer reuse improves performance by 1.25x

### 5. PowerShell Best Practices (Query 5)
- Try-catch with $_.Exception.Response for error details
- PowerShell 7+ has -MaximumRetryCount and -RetryIntervalSec
- Exponential backoff for rate limiting (429 status)
- Splatting for cleaner parameter management
- ConvertTo-Json for body preparation
- Custom retry wrapper functions for reusability

## Critical Learnings

### 1. GitHub API Authentication
- Personal Access Token must be base64-encoded for basic auth
- TLS 1.2 enforcement is critical: [Net.ServicePointManager]::SecurityProtocol
- 404 errors often indicate auth issues, not missing resources

### 2. Issue Deduplication Strategy
- Error signatures should normalize variable parts (names, numbers)
- Line numbers should be rounded for fuzzy matching
- Exact signature matching via metadata comments is most reliable
- GitHub Search API has pagination issues beyond 100 results

### 3. PowerShell Integration Patterns
- Use splatting for cleaner API parameter management
- Always implement try-catch with detailed error logging
- Module functions should write to central log file
- Test-Path before file operations to avoid exceptions

### 4. Unity Error Processing
- Standard format: File(line,col): error CODE: message
- Error codes follow patterns: CS (C#), BCE (Boo), US (UnityScript)
- File paths should be normalized to Assets-relative paths
- Include Unity version in issues for version-specific bugs

### 5. Module Architecture
- Separate Public/Private function directories
- Use module-scoped variables for configuration
- Export only public functions in manifest
- Version bumps for significant feature additions

## Granular Implementation Plan

### Week 8, Day 3: Issue Creation Foundation
#### Hour 1: Core Issue Creation Function
- Create New-GitHubIssue.ps1 in Public folder
- Implement basic POST to /repos/{owner}/{repo}/issues
- Parameter validation and error handling
- Integration with Invoke-GitHubAPIWithRetry

#### Hour 2: Unity Error to Issue Conversion
- Create Format-UnityErrorAsIssue.ps1
- Extract error details from Unity log format
- Generate issue title from error type
- Format body with code blocks and context

#### Hour 3: Issue Template System
- Create issue templates in module config
- Support for different error types
- Metadata preservation in issue body
- Links to Unity documentation

#### Hour 4: Label and Milestone Management
- Auto-label based on error type
- Unity version milestone assignment
- Priority labeling from error severity
- Component tagging from script names

### Week 8, Day 4: Search and Deduplication
#### Hour 5: Issue Search Implementation
- Create Search-GitHubIssues.ps1
- Implement GET to /search/issues
- Query builder for complex searches
- Result parsing and filtering

#### Hour 6: Error Signature Generation
- Create Get-UnityErrorSignature.ps1
- Hash generation from error components
- Fuzzy matching for similar errors
- Signature storage and comparison

#### Hour 7: Duplicate Detection Logic
- Create Test-GitHubIssueDuplicate.ps1
- Search by error signature
- Similarity threshold configuration
- Decision tree for update vs create

#### Hour 8: Issue Update and Comments
- Create Update-GitHubIssue.ps1
- Create Add-GitHubIssueComment.ps1
- Occurrence counting for duplicates
- Context aggregation in comments

## Testing Strategy
- Mock API responses for unit tests
- Integration tests with test repository
- Error simulation for deduplication testing
- Rate limit testing with bulk operations
- End-to-end workflow validation

## Closing Summary
The Issue Management System will provide automated GitHub issue creation and management for Unity compilation errors. With authentication already in place, the focus is on implementing robust issue operations with intelligent deduplication to prevent issue spam while maintaining comprehensive error tracking.