#!/usr/bin/env python3
import re, sys

if len(sys.argv) < 2:
    print("Usage: python3 detect_dependency_errors.py <xcodebuild_log_path>")
    sys.exit(0)

log_path = sys.argv[1]

try:
    with open(log_path, 'r') as f:
        log_content = f.read()
except Exception as e:
    print(f"Could not read log file {log_path}: {e}")
    sys.exit(0)

# Common dependency graph error patterns
patterns = [
    r"cycle.*dependency",
    r"dependency graph",
    r"duplicate product", 
    r"multiple targets named",
    r"manifest.*error",
    r"swift-tools-version",
    r"could not resolve",
    r"ComputeTargetDependencyGraph",
    r"package resolution failed",
    r"unable to resolve build file"
]

print("=== Suspected dependency-graph hints ===")
found_issues = False

for i, line in enumerate(log_content.splitlines(), 1):
    for pattern in patterns:
        if re.search(pattern, line, re.IGNORECASE):
            print(f"Line {i}: {line.strip()}")
            found_issues = True
            break

if not found_issues:
    print("No dependency graph error patterns found in build log")
    
# Also look for specific TCA-related errors
tca_patterns = [
    r"ComposableArchitecture.*not found",
    r"swift-composable-architecture.*error", 
    r"macro.*not found",
    r"ReducerMacro.*could not be found"
]

print("\n=== TCA-specific issues ===")
for i, line in enumerate(log_content.splitlines(), 1):
    for pattern in tca_patterns:
        if re.search(pattern, line, re.IGNORECASE):
            print(f"Line {i}: {line.strip()}")