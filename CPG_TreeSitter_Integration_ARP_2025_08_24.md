# CPG Tree-sitter Integration Implementation Document
## Date: 2025-08-24
## Time: Current
## Previous Context: Enhanced Documentation System ARP, Phase 1 CPG implementation complete
## Topics: Tree-sitter integration, universal parsing, cross-language support

## Summary Information
- **Problem**: Need universal parsing capability for multiple languages using tree-sitter
- **Date and Time**: 2025-08-24
- **Previous Context**: CPG module implemented with 100% test coverage for PowerShell
- **Current Phase**: Phase 1, Day 3-4: Tree-sitter Integration & Universal Parsing
- **Topics Involved**: Tree-sitter, CST parsing, multi-language support, unified graph format

## Home State Analysis
The Unity-Claude-CPG module has been successfully implemented with:
- Complete PowerShell AST to CPG conversion
- Node and edge type definitions  
- Graph operations with thread safety
- 100% test coverage (34/34 tests passing)
- Deferred call resolution for forward references
- Data flow and control flow analysis

### Current Module Structure
- **Unity-Claude-CPG.psm1**: Main module with graph operations
- **Unity-Claude-CPG-ASTConverter.psm1**: AST to CPG conversion
- **Unity-Claude-CPG-Enums.ps1**: Enum definitions for node/edge types
- **Unity-Claude-CPG.Tests.ps1**: Comprehensive test suite
- **Unity-Claude-CPG.psd1**: Module manifest

## Project Code State
- CPG foundation is complete for PowerShell
- AST parsing works correctly with relationship mapping
- Need to add tree-sitter for universal language support

## Objectives
### Short-term (Today)
1. Install and configure tree-sitter CLI
2. Create wrapper functions for tree-sitter parsing
3. Support Python, JavaScript, TypeScript, C# parsing
4. Convert CST to unified graph format
5. Benchmark for 36x performance improvement

### Long-term (This Week)
1. Complete cross-language relationship mapping
2. Implement unified relationship model
3. Create cross-reference resolver
4. Generate language-agnostic dependency maps

## Current Implementation Plan (from ARP)
We are at **Phase 1, Day 3-4: Tree-sitter Integration & Universal Parsing**

**Hours 1-4**: Tree-sitter Setup
- Install tree-sitter CLI and language parsers
- Create `Invoke-TreeSitterParse` wrapper function
- Support Python, JavaScript, TypeScript, C# parsing
- Convert CST to unified graph format
- Benchmark: Target 36x performance improvement

**Hours 5-8**: Cross-Language Relationship Mapping
- Build unified relationship model across languages
- Implement `Merge-LanguageGraphs` for multi-language projects
- Create cross-reference resolver for mixed codebases
- Add import/export tracking between modules
- Generate language-agnostic dependency maps

## Benchmarks
- Tree-sitter parsing: 36x speedup over traditional parsers
- Processing speed: 100+ files/second target
- Incremental updates: Millisecond response times

## Blockers
None identified yet.

## Errors/Flow of Logic
No errors - starting fresh implementation.

## Preliminary Solutions
Use tree-sitter CLI with PowerShell wrappers for maximum compatibility.

## Research Findings (from Previous ARP + New Research)
- Tree-sitter produces Concrete Syntax Trees (CST) vs Abstract Syntax Trees (AST)
- CST preserves all syntax details including whitespace and comments
- 36x speedup over traditional parsers confirmed in benchmarks
- Incremental parsing capability for efficient updates
- Universal interface for multiple languages
- Foundation for modern language servers and IDE features

### Installation Options for Windows (Research Pass 1-5)
1. **Chocolatey**: `choco install tree-sitter` (v0.25.8 as of 2025)
2. **NPM**: `npm install -g tree-sitter-cli` 
3. **Cargo**: `cargo install tree-sitter-cli --locked`
4. **Pre-built binaries**: Available from GitHub releases

### Language Parser Installation via NPM
```bash
npm install tree-sitter tree-sitter-javascript tree-sitter-typescript tree-sitter-python tree-sitter-c-sharp
```

### Tree-sitter Parse Output Formats
- Default: S-expression format
- XML: `tree-sitter parse -x` or `--xml`
- CST: `tree-sitter parse --cst`
- DOT: `tree-sitter parse --dot` 
- No native JSON output - requires post-processing

### Windows Requirements
- Node.js on PATH for parser generation
- C/C++ compiler (MSVC cl.exe) for running parsers
- Architecture must match (x64 vs x86)

### PowerShell XML Parsing Approach (Research Pass 6-10)
- No built-in ConvertFrom-XML cmdlet in PowerShell
- Use `[xml]` type accelerator to load XML
- Navigate with dot notation or XPath queries
- Custom ConvertFrom-XML implementations available on GitHub

### Node.js Integration Examples
```javascript
const Parser = require('tree-sitter');
const JavaScript = require('tree-sitter-javascript');
const parser = new Parser();
parser.setLanguage(JavaScript);
const tree = parser.parse(sourceCode);
```

### Implementation Decision
Based on research, will use Node.js script with tree-sitter bindings called from PowerShell for best performance and compatibility.