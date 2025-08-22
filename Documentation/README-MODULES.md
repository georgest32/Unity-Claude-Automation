# Unity-Claude Automation - Modular System

## 🚀 Quick Start

### From PowerShell:
```powershell
# Option 1: Interactive menu (EASIEST)
.\START-HERE.ps1

# Option 2: Direct testing
.\Run-ModuleTests.ps1

# Option 3: Direct automation
.\Unity-Claude-Automation.ps1 -RunOnce
```

## 📁 File Structure

```
C:\UnityProjects\Sound-and-Shoal\
├── START-HERE.ps1                  # 🎯 Start here! Interactive menu
├── Unity-Claude-Automation.ps1     # Main orchestrator (uses modules)
├── unity_claude_automation.ps1     # Original monolithic script (backup)
├── Test-UnityClaudeModules.ps1    # Comprehensive test suite
├── Run-ModuleTests.ps1            # Quick test runner
│
└── Modules\                       # Modular components
    ├── Unity-Claude-Core\         # Core orchestration
    ├── Unity-Claude-IPC\          # Claude communication  
    └── Unity-Claude-Errors\       # Error tracking

```

## ⚡ Running the System

### First Time Setup (Test Everything)
```powershell
# From PowerShell in project directory:
cd C:\UnityProjects\Sound-and-Shoal
.\START-HERE.ps1
# Choose option 1 to test modules first
```

### Normal Operation
```powershell
# Single test (recommended first):
.\Unity-Claude-Automation.ps1 -RunOnce

# Continuous monitoring:
.\Unity-Claude-Automation.ps1 -Loop

# With all features:
.\Unity-Claude-Automation.ps1 -Loop -EnableDatabase -GenerateReport
```

## 🎯 Command Line Options

### Basic Modes
- `-RunOnce` - Test compilation once and exit
- `-Loop` - Continuously monitor and fix errors
- `-TestModules` - Run module test suite

### Features
- `-EnableDatabase` - Track error patterns in SQLite
- `-EnableLearning` - Learn from successful fixes
- `-GenerateReport` - Create HTML report at end

### Claude Settings
- `-Model 'sonnet-3.5'` - Claude model to use
- `-ClaudeExe 'claude'` - Path to Claude CLI
- `-ClaudeTimeout 3600` - Timeout in seconds

### Unity Settings
- `-ProjectPath 'C:\UnityProjects\Sound-and-Shoal'`
- `-UnityExe 'C:\Program Files\Unity\Hub\Editor\2021.1.14f1\Editor\Unity.exe'`
- `-UnityTimeout 300` - Compilation timeout

## 🧪 Testing

### Quick Test
```powershell
.\Run-ModuleTests.ps1
```

### Detailed Testing
```powershell
# Full test with HTML report:
.\Test-UnityClaudeModules.ps1 -GenerateReport

# Skip Claude tests if CLI not installed:
.\Test-UnityClaudeModules.ps1 -SkipClaudeTests
```

## 📊 Expected Output

### Successful Module Test:
```
=== MODULE LOADING TESTS ===
[Unity-Claude-Core module exists]
  ✓ PASSED
[Unity-Claude-IPC module exists]
  ✓ PASSED
[Unity-Claude-Errors module exists]
  ✓ PASSED
```

### Successful Compilation:
```
[Cycle 1] 14:32:15
  Testing Unity compilation...
  ✓ Compilation successful!
```

### Error Detection and Fix:
```
[Cycle 2] 14:35:22
  Testing Unity compilation...
  ✗ Compilation failed: CompilationError
  Exporting Unity console...
  Analyzing errors...
  Sending to Claude for analysis...
    Model: sonnet-3.5 | Type: Continue
  ✓ Claude provided solution
```

## 🔧 Troubleshooting

### "Module not found"
```powershell
# Ensure modules are in path:
$env:PSModulePath = "$PWD\Modules;$env:PSModulePath"
Get-Module -ListAvailable Unity-Claude*
```

### "Claude CLI not found"
- Install Claude CLI or use `-SkipClaudeTests` for testing
- The system will still work but without Claude integration

### "Access denied"
```powershell
# Run PowerShell as Administrator, or:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Unity doesn't compile
- Check Unity path is correct
- Ensure project path is valid
- Verify AutoRecompile.cs gets installed to Assets\Editor\Automation\

## 🆚 Modular vs Original

| Feature | Original (unity_claude_automation.ps1) | Modular (Unity-Claude-Automation.ps1) |
|---------|----------------------------------------|---------------------------------------|
| Lines of code | 635 (monolithic) | ~400 per module (separated) |
| Error database | ❌ No | ✅ SQLite tracking |
| Pattern learning | ❌ No | ✅ Success/failure tracking |
| HTML reports | ❌ No | ✅ Statistical analysis |
| Testing | ❌ Manual only | ✅ 24+ automated tests |
| Extensibility | ❌ Hard to modify | ✅ Plugin-ready |
| Named pipes | ❌ No | ✅ Bidirectional IPC |

## 💡 Tips

1. **Always test modules first** on a new system
2. **Use -RunOnce** for initial testing before -Loop
3. **Enable database** for long-running sessions to track patterns
4. **Check HTML reports** for error trends and success rates
5. **Original script** is still available as fallback

## 📈 Next Steps

After successful testing:
1. Run with `-EnableDatabase` to start building error history
2. Use `-GenerateReport` to analyze patterns
3. Consider adding custom error patterns to the database
4. Extend with plugins in the future

---
*Unity-Claude Automation v2.0 - Modular Architecture*