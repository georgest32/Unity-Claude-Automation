# Claude Code Best Practices for Autonomous Agent
*Date: 2025-08-18*
*Source: https://www.anthropic.com/engineering/claude-code-best-practices*
*Context: Guidelines for autonomous agent interactions with Claude Code CLI*

## Overview

The autonomous Unity-Claude agent must follow established Claude Code best practices when interacting with Claude Code CLI to ensure optimal performance and safety.

## Core Best Practices for Autonomous Agent

### 1. Customize Setup and Documentation
**CLAUDE.md Integration**: The agent should reference and maintain project documentation including:
- Bash commands and PowerShell scripts
- Code style guidelines (ASCII-only, no backticks)
- Testing instructions for each module
- Repository etiquette and commit practices
- Environment setup details (Unity 2021.1.14f1, PowerShell 5.1)

**Implementation**: Agent should read CLAUDE.md before generating prompts to understand project context.

### 2. Optimize Autonomous Workflow
**Specific Instructions**: Agent prompts should be highly specific:
- Mention exact files to work on
- Provide clear context about current errors
- Include relevant Unity version and project details
- Reference specific error codes (CS0246, etc.)

**Visual References**: When possible, include:
- Error screenshots or logs
- Unity console outputs
- Test result summaries

**Course Correction**: Agent should:
- Monitor Claude responses for confusion or clarification requests
- Adjust approach based on response feedback
- Use /clear when context becomes unfocused

### 3. Autonomous Workflow Patterns

**Explore, Plan, Code, Commit Pattern**:
1. **Explore**: Read relevant Unity scripts, error logs, test results
2. **Plan**: Generate detailed implementation plan with steps
3. **Code**: Implement solution following PowerShell 5.1 best practices
4. **Commit**: Create commits with clear messages (when explicitly requested)

**Test-Driven Development Pattern**:
1. **Write Tests**: Create validation tests for new functionality
2. **Confirm Failure**: Verify tests fail before implementation
3. **Implement Code**: Write code to pass tests
4. **Validate**: Confirm tests pass with new implementation

### 4. Advanced Features for Automation

**Headless Mode**: Agent should leverage headless mode for automation:
- File-based communication with Claude Code CLI
- Automated prompt submission and response monitoring
- FileSystemWatcher for response detection

**Context Management**: 
- Maintain conversation context across multiple interactions
- Use session state management for long autonomous conversations
- Implement context compression for long-running operations

### 5. Critical Safety Considerations

**⚠️ NEVER USE --dangerously-skip-permissions**: This mode could be catastrophic in autonomous operation
- Always respect Claude Code's permission system
- Use safe command execution with constrained runspace
- Implement comprehensive safety validation before execution

**Tool Permissions**: Agent should:
- Carefully validate all commands before execution
- Use minimal required permissions
- Implement safety checks for file operations
- Never bypass security measures

**Safe Automation Practices**:
- Test all operations in safe environment first
- Implement comprehensive error handling and rollback
- Use confidence thresholds for autonomous execution
- Maintain human oversight for critical operations

## Implementation Guidelines for Agent

### Prompt Generation Best Practices
**Clear Target Iteration**: Agent should provide Claude with:
- Visual mocks or examples when possible
- Specific test cases to validate against
- Clear success criteria and expected outputs
- Detailed error context and troubleshooting information

**Context Optimization**:
- Include relevant project history
- Reference previous successful solutions
- Provide Unity-specific terminology and patterns
- Maintain conversation continuity

### Command Execution Safety
**Pre-execution Validation**:
- Test all commands for safety using Test-CommandSafety
- Validate parameters using Test-ParameterSafety
- Ensure paths are within project boundaries using Test-PathSafety
- Use constrained runspace for execution isolation

**Response Monitoring**:
- Monitor Claude responses for errors or confusion
- Implement retry logic with exponential backoff
- Handle timeout scenarios gracefully
- Provide comprehensive feedback on execution results

## Integration with Existing Systems

### Module Integration
The autonomous agent's Claude Code interactions should integrate with:
- **ResponseParsing**: Parse Claude responses for actionable commands
- **Classification**: Categorize responses (Error, Instruction, Question, etc.)
- **SafeExecution**: Execute commands safely with validation
- **ConversationStateManager**: Maintain context across interactions
- **ContextOptimization**: Compress and optimize conversation context

### Quality Assurance
**Testing**: Every Claude Code interaction should:
- Include validation tests for expected outcomes
- Provide clear success/failure criteria
- Generate comprehensive logs for debugging
- Follow established PowerShell syntax patterns (ASCII-only, no backticks)

**Documentation**: Agent should:
- Update CLAUDE.md with new discoveries
- Document successful interaction patterns
- Record failed approaches for future avoidance
- Maintain comprehensive learning database

## Conclusion

Following these Claude Code best practices ensures the autonomous agent creates optimal interactions with Claude Code CLI while maintaining safety and effectiveness. The agent must never compromise on security (no --dangerously-skip-permissions) while leveraging all available features for autonomous operation.