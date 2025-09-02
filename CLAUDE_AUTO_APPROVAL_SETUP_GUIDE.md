# Claude Code Auto-Approval Configuration Guide

## Summary of Research Findings

After conducting extensive research through multiple queries, here are the key findings about Claude Code's auto-approval system:

### 1. Configuration File Format
- **Location**: `.claude/settings.json` (project-specific)
- **Key**: Use `allowedTools` array at the root level, NOT `permissions.allow`
- **Format**: JSON array of tool patterns

### 2. Working Configuration
The following configuration successfully auto-approves all read and non-destructive operations:

```json
{
  "allowedTools": [
    "Bash(*)",
    "Read",
    "Read(*)",
    "Glob",
    "Glob(*)",
    "Grep",
    "Grep(*)",
    "Edit",
    "Edit(*)",
    "MultiEdit",
    "MultiEdit(*)",
    "Write",
    "Write(*)",
    "NotebookEdit",
    "NotebookEdit(*)",
    "Task",
    "Task(*)",
    "BashOutput",
    "BashOutput(*)",
    "TodoWrite",
    "TodoWrite(*)",
    "WebSearch",
    "WebSearch(*)",
    "WebFetch",
    "WebFetch(*)",
    "ExitPlanMode",
    "ExitPlanMode(*)"
  ]
}
```

### 3. Key Research Findings

#### Configuration Hierarchy
- User settings: `~/.claude/settings.json` (applies globally)
- Project settings: `.claude/settings.json` (project-specific, shared)
- Local settings: `.claude/settings.local.json` (personal, not in git)

#### Permission Syntax
- `ToolName` - Permit every action for that tool
- `ToolName(*)` - Permit any argument for that tool
- `ToolName(pattern*)` - Permit matching patterns only
- Examples: `Bash(git *)`, `Read(src/*)`, `Write(*.js)`

#### Important Notes
1. **`Bash(*)` is powerful but risky** - It allows ALL bash commands. Research shows this is the most comprehensive way to avoid approval prompts but should be used cautiously.

2. **Alternative approaches**:
   - Shift+Tab toggles auto-accept mode in the UI
   - `--dangerously-skip-permissions` flag bypasses all checks (not recommended)
   - `/permissions` command for interactive configuration

3. **Security considerations**:
   - Never include destructive commands in allowedTools
   - Use specific patterns when possible
   - Consider using deny rules (though the format differs)

### 4. Common Issues Encountered

#### Issue 1: Invalid Settings File
- **Problem**: Using `permissions.allow` instead of `allowedTools`
- **Solution**: Use `allowedTools` array at root level

#### Issue 2: Windows Commands Not Auto-Approved
- **Problem**: Commands like `dir`, `cmd /c dir` weren't auto-approved
- **Solution**: `Bash(*)` covers most commands when running through Git Bash/WSL

#### Issue 3: Pattern Matching
- **Finding**: Some specific patterns like `Bash(dir*)` don't work as expected
- **Solution**: `Bash(*)` is more reliable for comprehensive coverage

### 5. Best Practices

1. **Start Restrictive**: Begin with minimal permissions and add as needed
2. **Use Specific Patterns**: When possible, use patterns like `Bash(npm test*)` instead of `Bash(*)`
3. **Regular Review**: Periodically review your allowedTools list
4. **Team Sharing**: Use `.claude/settings.json` for team-wide settings
5. **Personal Overrides**: Use `.claude/settings.local.json` for personal preferences

### 6. What Gets Auto-Approved with Our Configuration

✅ **Auto-Approved**:
- All bash/shell commands (via `Bash(*)`)
- File reading operations
- File writing and editing
- Web searches and fetches
- Task management operations
- Pattern matching and searching

❌ **Still Requires Approval**:
- Any operations not explicitly listed
- Operations blocked by enterprise policies
- Commands matching deny patterns (if configured separately)

### 7. Testing Results

With the current configuration:
- ✅ `echo`, `ls`, `pwd`, `git status` - All auto-approved
- ✅ `Read`, `Write`, `Edit` tools - All auto-approved
- ✅ `WebSearch`, `WebFetch` - Auto-approved
- ✅ Most Unix-style commands through Git Bash

### 8. Recommendations

For maximum productivity with reasonable safety:
1. Use the configuration provided above
2. Keep `Bash(*)` for convenience but be aware of risks
3. Consider adding specific deny rules if needed
4. Use auto-accept mode (Shift+Tab) for temporary sessions
5. Never use `--dangerously-skip-permissions` in production

### 9. Alternative for More Granular Control

If you want more specific control instead of `Bash(*)`:

```json
{
  "allowedTools": [
    "Bash(ls*)",
    "Bash(pwd*)",
    "Bash(cd*)",
    "Bash(git status*)",
    "Bash(git diff*)",
    "Bash(git log*)",
    "Bash(npm test*)",
    "Bash(npm run*)",
    "Read(*)",
    "Write(src/*)",
    "Edit(src/*)"
  ]
}
```

## Conclusion

The research revealed that Claude Code's permission system uses `allowedTools` in settings.json files. The most effective approach for auto-approving all safe operations is using `Bash(*)` combined with all Claude tool patterns. While this is broad, it provides the smoothest workflow for development tasks. For production or sensitive environments, more restrictive patterns should be used.