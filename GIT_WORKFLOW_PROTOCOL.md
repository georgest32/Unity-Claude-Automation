# Git Workflow Protocol

## Basic Git Commands

### 1. **Check Status**
Always start by checking what's changed:
```bash
git status
```

### 2. **Stage Changes**
Add files to staging area:
```bash
# Add specific files
git add filename.ps1

# Add all changes in current directory
git add .

# Add all changes everywhere
git add -A

# Interactive add (choose what to stage)
git add -p
```

### 3. **Commit Changes**
Create a commit with a descriptive message:
```bash
# Short message
git commit -m "fix: Corrected Mermaid graph syntax in documentation"

# Detailed message with description
git commit -m "fix: Corrected Mermaid graph syntax" -m "Changed 6 backticks to 3 for proper rendering"

# Amend last commit (if you forgot something)
git commit --amend

# Commit with sign-off
git commit -s -m "feat: Added safe operations handler"
```

### 4. **Push to GitHub**
Send commits to remote repository:
```bash
# Push to origin main
git push origin main

# Push and set upstream (first time)
git push -u origin main

# Force push (use with caution!)
git push --force-with-lease

# Push all branches
git push --all
```

## Common Workflows

### Standard Workflow
```bash
# 1. Check status
git status

# 2. Stage changes
git add .

# 3. Commit with descriptive message
git commit -m "feat: Added hybrid documentation generator"

# 4. Push to remote
git push origin main
```

### Fix Workflow (When You Get Errors)
```bash
# 1. Pull latest changes first
git pull origin main

# 2. If there are conflicts, resolve them
# Edit conflicted files, then:
git add .
git commit -m "merge: Resolved conflicts"

# 3. Push your changes
git push origin main
```

### Safe Workflow with Backup
```bash
# 1. Create backup branch
git branch backup-$(date +%Y%m%d)

# 2. Make your changes
git add .
git commit -m "your message"

# 3. Push to remote
git push origin main
```

## Commit Message Convention

Use conventional commits for clear history:

- **feat:** New feature
- **fix:** Bug fix
- **docs:** Documentation changes
- **style:** Code style changes (formatting, etc.)
- **refactor:** Code refactoring
- **test:** Test additions or changes
- **chore:** Maintenance tasks
- **perf:** Performance improvements

Examples:
```bash
git commit -m "feat: Added permission handler for Claude CLI"
git commit -m "fix: Corrected regex pattern in documentation generator"
git commit -m "docs: Updated Git workflow protocol"
git commit -m "refactor: Simplified safe operations logic"
```

## Troubleshooting Common Issues

### "Updates were rejected because the remote contains work"
```bash
# Pull first, then push
git pull origin main --rebase
git push origin main
```

### "Your branch is ahead of 'origin/main' by X commits"
```bash
# Just push your commits
git push origin main
```

### "Changes not staged for commit"
```bash
# Add the changes first
git add .
# Then commit
git commit -m "your message"
```

### "fatal: Not a git repository"
```bash
# Initialize git in the directory
git init
# Add remote
git remote add origin https://github.com/yourusername/repo.git
```

### GitHub Desktop Errors
If GitHub Desktop is giving errors:

1. **Try command line instead:**
```bash
# Open PowerShell in the repository folder
cd C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation

# Follow standard workflow
git status
git add .
git commit -m "your message"
git push origin main
```

2. **Check authentication:**
```bash
# Set your identity
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Check current remote
git remote -v

# If using HTTPS, you might need a token
# Create one at: https://github.com/settings/tokens
```

3. **Reset and try again:**
```bash
# Fetch latest
git fetch origin

# Reset to match remote (WARNING: loses local changes)
git reset --hard origin/main

# Or, create a new branch for your changes
git checkout -b my-changes
git add .
git commit -m "your message"
git push -u origin my-changes
```

## Best Practices

1. **Commit Often:** Small, focused commits are better than large ones
2. **Write Clear Messages:** Future you will thank present you
3. **Pull Before Push:** Always sync with remote before pushing
4. **Use Branches:** For major changes, create a feature branch
5. **Test Before Commit:** Make sure your code works
6. **Review Changes:** Use `git diff` before committing

## Quick Reference

| Command | Purpose |
|---------|---------|
| `git status` | Check what's changed |
| `git add .` | Stage all changes |
| `git commit -m "msg"` | Commit with message |
| `git push` | Push to remote |
| `git pull` | Pull from remote |
| `git log --oneline` | View commit history |
| `git diff` | See unstaged changes |
| `git branch` | List branches |
| `git checkout -b name` | Create new branch |
| `git stash` | Temporarily save changes |

## Automated Backup Script

Save this as `Quick-Commit.ps1`:
```powershell
param(
    [string]$Message = "Update: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
)

# Check git status
$status = git status --porcelain

if ($status) {
    Write-Host "📝 Staging changes..." -ForegroundColor Yellow
    git add .
    
    Write-Host "💾 Committing..." -ForegroundColor Cyan
    git commit -m $Message
    
    Write-Host "📤 Pushing to remote..." -ForegroundColor Green
    git push origin main
    
    Write-Host "✅ Done!" -ForegroundColor Green
} else {
    Write-Host "✨ No changes to commit" -ForegroundColor Gray
}
```

Usage:
```powershell
.\Quick-Commit.ps1 -Message "feat: Added new feature"
```

## Remember

- **Never commit secrets** (API keys, passwords, tokens)
- **Use .gitignore** for files that shouldn't be tracked
- **Make backups** before major operations
- **Ask for help** if unsure - better safe than sorry!

---

*For Unity-Claude-Automation specific workflows, see the Safe Operations Handler for automatic git checkpointing during implementation plans.*