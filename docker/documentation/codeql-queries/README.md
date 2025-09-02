# CodeQL Custom Queries

This directory contains custom CodeQL queries for security analysis of:

- PowerShell scripts (.ps1, .psm1, .psd1)
- C# code (.cs files)
- Configuration files (.json, .yml)

## Query Categories

### PowerShell Security Queries
- Script injection vulnerabilities
- Credential exposure detection
- Path traversal vulnerabilities
- Command injection patterns
- Unsafe deserialization

### C# Security Queries  
- SQL injection vulnerabilities
- Cross-site scripting (XSS)
- Path injection vulnerabilities
- Unsafe reflection usage
- Insecure randomness

## Usage

These queries are automatically loaded by the CodeQL analysis service and run during scheduled security scans.

Results are generated in SARIF format and integrated into the Enhanced Documentation System security reports.