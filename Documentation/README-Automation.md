# Unity-Claude Automation Scripts

## Important: Claude Code CLI Limitations

Claude Code CLI v1.0.53 **does not support piped input or headless mode**. The CLI uses Ink (React for terminals) which requires an interactive terminal with raw mode support. This means:

- ❌ Cannot pipe input: `echo "text" | claude chat` will fail
- ❌ No headless/background mode available
- ✅ Must use SendKeys automation for unattended operation

## Recommended Solution

### Primary Script: `Submit-ErrorsToClaude-Final.ps1`

This is the recommended script for automating error submission to Claude Code:

```powershell
# Basic usage
.\Submit-ErrorsToClaude-Final.ps1

# Quick mode with auto-submit
.\Submit-ErrorsToClaude-Final.ps1 -QuickMode -AutoSubmit

# Custom error log
.\Submit-ErrorsToClaude-Final.ps1 -ErrorLogPath "path\to\errors.log"
```

**Features:**
- Automatically switches to Claude Code window (Alt+Tab)
- Types the error report line by line
- Optional auto-submit with Enter
- Fallback to clipboard if typing fails
- Progress indicator for long error logs

### Setup Instructions

1. **Open Claude Code** in a separate window:
   ```powershell
   claude chat
   ```

2. **Position Windows** so you can Alt+Tab between them:
   - PowerShell window (where you run scripts)
   - Claude Code chat window

3. **Run the Script**:
   ```powershell
   .\Submit-ErrorsToClaude-Final.ps1 -AutoSubmit
   ```

4. **Script will**:
   - Wait 3 seconds (giving you time to cancel)
   - Switch to Claude Code window
   - Clear any existing text
   - Type the error report
   - Optionally press Enter to submit

## Alternative Scripts

### For Testing
- `Test-SubmitToClaude.ps1` - Test different submission methods
- `Test-ClaudePiping.ps1` - Verify Claude CLI capabilities

### For Monitoring
- `Watch-AndReport.ps1` - Real-time error monitoring with manual submission

### Legacy/Experimental
- `Submit-ErrorsToClaude-NextWindow.ps1` - Earlier SendKeys version
- `Submit-ErrorsToClaude-SendKeys.ps1` - Opens new Claude window
- `Submit-ErrorsToClaude-Headless.ps1` - Attempted headless mode (doesn't work with v1.0.53)

## Modular System Components

### Core Modules
- `Unity-Claude-Core.psm1` - Unity compilation and automation
- `Unity-Claude-IPC.psm1` - Inter-process communication
- `Unity-Claude-Errors.psm1` - Error tracking and database

### Export Scripts
- `Export-ErrorsForClaude-Fixed.ps1` - Export errors to markdown format

## Limitations & Workarounds

### Why SendKeys?
Claude Code CLI requires an interactive terminal and cannot accept piped input. SendKeys simulates keyboard input, making it the only reliable automation method.

### Drawbacks
- Requires Claude Code window to be accessible via Alt+Tab
- Cannot run completely in background
- User cannot use computer while script is typing
- Sensitive to timing and window focus

### Best Practices
1. Run during breaks or dedicated automation time
2. Use `-QuickMode` for faster typing
3. Keep error logs concise when possible
4. Test with small error sets first
5. Have Claude Code already open and ready

## Troubleshooting

### Script doesn't switch windows
- Ensure Claude Code is the next window (Alt+Tab order)
- Try increasing the delay: `-DelayMs 50`

### Typing is garbled
- Increase delay between lines: `-DelayMs 100`
- Check for special characters in error messages

### Nothing happens in Claude
- Verify Claude Code is running: `claude chat`
- Check if cursor is in the input field
- Try manual Alt+Tab to confirm window order

## Future Improvements

When Claude Code CLI adds piped input support:
- True background operation will be possible
- No window switching needed
- Can run while using computer normally

Until then, SendKeys automation is the best available solution.