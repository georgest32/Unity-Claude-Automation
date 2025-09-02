# Critical Requirements - Unity-Claude Automation
*Essential knowledge that must be understood before starting any work*
*Last Updated: 2025-08-19*

## 🚨 CRITICAL: Must Know Before Starting

### 1. Claude CLI Limitations (⚠️ CRITICAL)
**Issue**: Claude Code CLI v1.0.53 does NOT support piped input or headless mode
**Discovery**: Extensive testing confirmed CLI uses Ink (React for terminals) requiring interactive terminal
**Evidence**: 
- `echo "test" | claude chat` fails with "raw mode" error
- `claude chat < input.txt` hangs indefinitely
- No --headless or --batch flags available
**Resolution**: SendKeys automation is the ONLY reliable method for CLI automation
**Critical Learning**: Do not waste time trying to pipe input to Claude CLI - it fundamentally cannot work with current version

### 2. PowerShell Version Compatibility (⚠️ CRITICAL)
**Issue**: Script must maintain PowerShell 5.1 compatibility
**Discovery**: Many organizations still on PS5.1; PS7 features break compatibility
**Evidence**:
- No `??` null coalescing operator in PS5.1
- No `ForEach-Object -Parallel` in PS5.1
- Different module loading behavior
**Resolution**: Avoid PS7-only syntax; use ThreadJob module for parallelization
**Critical Learning**: Always test on PS5.1 before deployment

### 3. Unity Batch Mode Compilation (✅ RESOLVED)
**Issue**: EditorApplication.isCompiling always returns true in batch mode
**Discovery**: Unity's compilation detection APIs don't work properly in batch mode
**Evidence**: CompilationPipeline.compilationFinished is reliable; EditorApplication.isCompiling is not
**Resolution**: Use CompilationPipeline events and SessionState for domain reload survival
**Critical Learning**: Don't trust EditorApplication properties in batch mode

### 4. PowerShell Script Encoding Requirements (⚠️ CRITICAL)
**Issue**: UTF-8 BOM Requirement for Windows PowerShell 5.1
**Discovery**: Scripts created with UTF-8 without BOM cause "unexpected token" errors
**Evidence**: Start-UnityClaudeAutomation.ps1 failed with multiple syntax errors
**Resolution**: Convert files to UTF-8 with BOM using Fix-ScriptEncoding.ps1
**Critical Learning**: Always save PowerShell scripts as UTF-8 with BOM for compatibility
**Error Pattern**:
- Unexpected token '}' errors
- String missing terminator errors
- Missing closing brace errors at wrong lines

### 5. PowerShell Error Location Reporting (⚠️ CRITICAL)
**Issue**: Syntax errors reported at different lines than actual problem
**Discovery**: Missing braces and syntax errors often detected later in code
**Evidence**: Errors at lines 82, 84, 91, 149 but actual issue was encoding
**Resolution**: Check lines before reported errors and verify file encoding
**Critical Learning**: Always expand analysis range beyond reported error lines

### 6. Development Environment Setup Requirements
**Required Software**:
- **PowerShell**: 5.1+ (PS5.1 compatibility required)
- **Unity**: 2021.1.14f1 (.NET Standard 2.0)
- **Claude CLI**: v1.0.53+ or API key
- **Memory**: 4GB minimum
- **Storage**: 1GB for logs/database

**Required Modules**:
```powershell
# For advanced features (optional)
Install-Module PSSQLite -Scope CurrentUser
Install-Module ThreadJob -Scope CurrentUser  # For PS5.1 parallelization
```

**Environment Variables**:
```powershell
$env:ANTHROPIC_API_KEY = "sk-ant-..."  # For API mode
$env:PSModulePath = "$PWD\Modules;$env:PSModulePath"
```

### 7. File and Directory Structure Requirements
**Critical Paths**:
- **Unity Editor.log location**: `C:\Users\georg\AppData\Local\Unity\Editor\Editor.log`
- **Centralized Logging**: All logs must write to `unity_claude_automation.log` at project root
- **Module Directory**: `.\Modules\` with proper PowerShell module structure
- **Session Data**: `.\SessionData\` for state persistence and checkpoints

### 8. Security and Safety Requirements (⚠️ CRITICAL)
**Never Use in Autonomous Operation**:
- `--dangerously-skip-permissions` flag in Claude Code CLI
- Direct code execution without validation
- Automated file modifications without backup
- Network operations without timeout/retry limits

**Always Required**:
- Constrained runspace for command execution
- Parameter validation and sanitization
- Path safety validation within project boundaries
- Comprehensive logging for all operations

---
*This document contains only the most critical information needed before starting development.*
*For detailed implementation specifics, see the other LEARNINGS_*.md documents.*