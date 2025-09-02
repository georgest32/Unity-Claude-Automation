# MCP Server Infrastructure Implementation

**Date**: 2025-08-23
**Time**: 11:00 AM
**Author**: Unity-Claude-Automation System
**Previous Context**: MULTI_AGENT_REPO_DOCS_ARP_2025_08_23.md plan created
**Topics**: MCP Server setup, Cursor IDE integration, ripgrep/git/filesystem servers

## Current State Analysis

### Completed Tasks (Hours 5-8: Development Tools Installation)
- **ripgrep**: Installed via Chocolatey at `C:\ProgramData\chocolatey\bin\rg.exe`
- **universal-ctags**: Installed via Chocolatey at `C:\ProgramData\chocolatey\bin\ctags.exe`
- **Git**: Installed at `C:\Program Files\Git\cmd\git.exe`
- **Python**: Version 3.13.5 installed
- **WSL2**: Ubuntu running in version 2
- **Directory Structure**: `agents/` directory created with subdirectories

### Existing Module Structure
- Unity-Claude-RepoAnalyst module created with proper structure
- Config, Logs, Private, Public directories established
- Module manifest (.psd1) and module (.psm1) files in place

### Cursor IDE MCP Support Status
- **Not Yet Configured**: Cursor IDE requires `.cursor/mcp.json` configuration
- **Research Complete**: MCP integration requires JSON configuration with server definitions
- **Transport Type**: Will use stdio for local development

## Implementation Plan for Day 3-4: MCP Server Infrastructure

### Hour 1: Create MCP Directory Structure and Base Configuration

#### Directory Structure to Create
```
Unity-Claude-Automation/
├── .ai/
│   ├── mcp/
│   │   ├── servers/           # MCP server implementations
│   │   ├── configs/           # Server configurations
│   │   └── logs/              # MCP server logs
│   ├── cache/                 # Code graphs, summaries
│   └── rules/                 # House rules for agents
└── .cursor/
    └── mcp.json               # Cursor IDE MCP configuration
```

### Hour 2-3: Implement Basic MCP Server for Ripgrep

#### Ripgrep MCP Server Configuration
```json
{
  "mcpServers": {
    "ripgrep": {
      "command": "npx",
      "args": ["-y", "mcp-ripgrep@latest"]
    }
  }
}
```

### Hour 4: Configure MCP Server for Git Operations

#### Git/GitHub MCP Server Configuration
```json
{
  "mcpServers": {
    "git": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git"],
      "env": {
        "GIT_PATH": "C:\\Program Files\\Git\\cmd\\git.exe"
      }
    }
  }
}
```

### Hour 5-6: Filesystem MCP Server with Windows Support

#### Filesystem Server Configuration
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "C:\\UnityProjects\\Sound-and-Shoal\\Unity-Claude-Automation"
      ]
    }
  }
}
```

### Hour 7-8: PowerShell-Python Bridge Implementation

#### Named Pipes IPC Setup
- Create PowerShell functions for pipe communication
- Implement JSON serialization layer
- Test bidirectional communication
- Create wrapper functions for MCP server interaction

## Research Findings Summary

### MCP Configuration in Cursor IDE (2025)
1. **Configuration Locations**:
   - Project-specific: `.cursor/mcp.json`
   - Global: `~/.cursor/mcp.json`

2. **Server Types Available**:
   - ripgrep: High-performance text search
   - filesystem: Token-efficient file access
   - git: Repository management
   - GitHub: Issue/PR management

3. **Windows-Specific Considerations**:
   - Path normalization required for Windows
   - Support for paths with spaces
   - Drive letter capitalization handling

### Implementation Dependencies
- Node.js/npm for npx commands
- MCP server packages from npm
- PowerShell 5.1/7.5 compatibility layer
- JSON serialization support

## Critical Learnings

### MCP Transport Types
- **stdio**: Simpler for local development (recommended)
- **SSE/HTTP**: Better for distributed teams
- **WebSocket**: Future support planned

### Security Considerations
- Environment variables for API keys
- OAuth support for external services
- File system access control via allowed directories

### Integration Points
- Cursor Composer Agent automatically uses available MCP tools
- Tools require user approval at each step
- Green indicator in Cursor shows successful connection

## Next Steps

### Immediate Actions (Hour 1)
1. Create .ai/mcp directory structure
2. Create .cursor directory with mcp.json
3. Install npm packages for MCP servers
4. Test basic ripgrep server connection

### Today's Deliverables (Hours 1-8)
1. Working ripgrep MCP server
2. Git operations MCP server
3. Filesystem MCP server with Windows support
4. PowerShell-Python IPC bridge prototype
5. Verified Cursor IDE integration

### Success Metrics
- Green indicator in Cursor MCP settings
- Successful ripgrep search from Cursor
- File read/write operations working
- Git status/diff commands functional

## Risk Mitigation
- Test each MCP server independently
- Maintain fallback to direct tool usage
- Document all configuration steps
- Create troubleshooting guide

## Conclusion

The development tools are installed and ready. The next phase involves creating the MCP server infrastructure to enable Cursor IDE integration with local tools. This will provide the foundation for the multi-agent repository analysis system.