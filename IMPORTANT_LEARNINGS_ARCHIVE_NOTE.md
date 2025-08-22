# IMPORTANT_LEARNINGS.md - Archive Notice

**Date**: 2025-08-19  
**Status**: REORGANIZED INTO TOPIC-SPECIFIC DOCUMENTS

## Notice
The original `IMPORTANT_LEARNINGS.md` file has been reorganized into topic-specific documents for better accessibility and maintenance. The content has been distributed across the following files:

## New Learning Document Structure

### 🚨 **[docs/LEARNINGS_CRITICAL_REQUIREMENTS.md](docs/LEARNINGS_CRITICAL_REQUIREMENTS.md)**
Essential information that must be known before starting any work
- Claude CLI limitations and PowerShell 5.1 compatibility
- Unity batch mode compilation and encoding requirements  
- Development environment setup and security guidelines

### 🔧 **[docs/LEARNINGS_POWERSHELL_COMPATIBILITY.md](docs/LEARNINGS_POWERSHELL_COMPATIBILITY.md)**
PowerShell 5.1 compatibility issues and syntax problems
- DateTime ETS properties, Unicode contamination, variable collisions
- String interpolation, escape sequences, parameter binding errors
- PowerShell version differences and workarounds

### 📋 **[docs/LEARNINGS_MODULE_SYSTEM.md](docs/LEARNINGS_MODULE_SYSTEM.md)**
PowerShell module architecture and best practices
- Module manifests, exports, nested module configurations
- State management, reloading limitations, path resolution
- Development workflow and debugging patterns

### 🤖 **[docs/LEARNINGS_CLAUDE_INTEGRATION.md](docs/LEARNINGS_CLAUDE_INTEGRATION.md)**
Claude CLI/API integration patterns and automation
- SendKeys automation, window focus management, response processing
- API key management, token usage, response classification
- Safety validation and command extraction

### 🔄 **[docs/LEARNINGS_UNITY_AUTOMATION.md](docs/LEARNINGS_UNITY_AUTOMATION.md)**
Unity-specific automation and compilation detection
- Domain reload survival, Roslyn conflicts, console log access
- Compilation detection, error patterns, build automation
- Unity Editor integration and performance monitoring

### 🧠 **[docs/LEARNINGS_AUTONOMOUS_AGENTS.md](docs/LEARNINGS_AUTONOMOUS_AGENTS.md)**
Phase 3 autonomous agent implementation and patterns
- State management, JSON persistence, human intervention thresholds
- Circuit breaker patterns, checkpoint systems, enhanced state machines
- Security considerations and audit trail implementation

### ⚡ **[docs/LEARNINGS_PERFORMANCE_SECURITY.md](docs/LEARNINGS_PERFORMANCE_SECURITY.md)**
Performance optimization and security patterns
- Runspace vs PSJob performance, parallel processing guidelines
- HTTP server implementation, common pitfalls, success patterns
- Input validation, credential management, secure logging

## Navigation
For the complete index and navigation guide, see:
**[IMPLEMENTATION_GUIDE.md - Learning Documentation Index](IMPLEMENTATION_GUIDE.md#-learning-documentation-index)**

## Benefits of Reorganization
- **Topic-focused**: Easier to find relevant information
- **Better maintenance**: Updates can be made to specific areas
- **Improved accessibility**: New team members can start with critical requirements
- **Cross-references**: Related concepts are properly linked
- **Code examples**: Each document includes relevant implementation patterns

---
*This reorganization was completed on 2025-08-19 as part of documentation improvement efforts.*