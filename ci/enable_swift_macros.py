#!/usr/bin/env python3
import re, sys, uuid, pathlib

def genid():
    # Xcode IDs are 24 hex chars
    return uuid.uuid4().hex.upper()[:24]

pbx_path = pathlib.Path("iOS-App/AgentDashboard/AgentDashboard.xcodeproj/project.pbxproj")

if not pbx_path.exists():
    print("❌ Missing project.pbxproj")
    sys.exit(1)

try:
    s = pbx_path.read_text(encoding="utf-8", errors="ignore")
except Exception as e:
    print(f"❌ Failed to read project.pbxproj: {e}")
    sys.exit(1)

# Quick guards
if "/* Begin PBXNativeTarget section */" not in s:
    print("❌ pbxproj missing PBXNativeTarget section. Aborting.")
    sys.exit(1)

# Locate AgentDashboard native target block
tgt_m = re.search(r"(?P<id>[A-F0-9]{24}) /\* AgentDashboard \*/ = \{", s)
if not tgt_m:
    print("❌ Could not find AgentDashboard target in pbxproj.")
    sys.exit(1)

tgt_id = tgt_m.group("id")
tgt_start = tgt_m.start()
tgt_end = s.find("};", tgt_start)
target_block = s[tgt_start:tgt_end+2]

# Ensure Macro Expansion phase section exists
if "/* Begin PBXSwiftMacroExpansionBuildPhase section */" not in s:
    # Insert the section after Frameworks section
    insert_after = "/* End PBXFrameworksBuildPhase section */"
    ins_idx = s.find(insert_after)
    if ins_idx == -1:
        print("❌ Could not find insertion point for MacroExpansion section.")
        sys.exit(1)
    
    ins_idx += len(insert_after)
    macro_phase_id = genid()
    macro_section = f"""

/* Begin PBXSwiftMacroExpansionBuildPhase section */
\t\t{macro_phase_id} /* Swift Macro Expansion */ = {{
\t\t\tisa = PBXSwiftMacroExpansionBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSwiftMacroExpansionBuildPhase section */"""
    
    s = s[:ins_idx] + macro_section + s[ins_idx:]
else:
    # Find existing macro phase id
    m = re.search(r"([A-F0-9]{24}) /\* Swift Macro Expansion \*/ = \{\s*isa = PBXSwiftMacroExpansionBuildPhase;", s)
    macro_phase_id = m.group(1) if m else genid()

# Add macro phase to target buildPhases if not present
def ensure_phase_in_list(block, phase_id, comment):
    if f"{phase_id} /* {comment} */" not in block:
        # Find buildPhases array
        phases_m = re.search(r"buildPhases = \((.*?)\);", block, re.S)
        if phases_m:
            phases_content = phases_m.group(1)
            new_phases = phases_content + f"\n\t\t\t\t{phase_id} /* {comment} */,"
            block = block.replace(phases_m.group(0), f"buildPhases = ({new_phases}\n\t\t\t);")
    return block

target_block = ensure_phase_in_list(target_block, macro_phase_id, "Swift Macro Expansion")

# Update master string with modified target
s = s[:tgt_start] + target_block + s[tgt_end+2:]

# Find package reference for swift-composable-architecture
pkg_m = re.search(r"([A-F0-9]{24}) /\* XCRemoteSwiftPackageReference \"swift-composable-architecture\" \*/ = \{", s)
if not pkg_m:
    print("❌ Could not find swift-composable-architecture package reference")
    sys.exit(1)

pkg_ref_id = pkg_m.group(1)

# Define macro products we need
macro_products = [
    "ComposableArchitectureMacros",
    "CasePathsMacros", 
    "DependenciesMacrosPlugin",
    "PerceptionMacros"
]

# Ensure XCSwiftPackageProductDependency section has our macro products
for prod in macro_products:
    if f"productName = {prod};" not in s:
        # Add new product dependency
        prod_id = genid()
        prod_def = f"\t\t{prod_id} /* {prod} */ = {{\n\t\t\tisa = XCSwiftPackageProductDependency;\n\t\t\tpackage = {pkg_ref_id} /* XCRemoteSwiftPackageReference \"swift-composable-architecture\" */;\n\t\t\tproductName = {prod};\n\t\t}};\n"
        
        # Insert before end of section
        s = re.sub(
            r"(/\* End XCSwiftPackageProductDependency section \*/)",
            prod_def + r"\1",
            s,
            count=1
        )
        
        # Add to target packageProductDependencies
        target_start = s.find(f"{tgt_id} /* AgentDashboard */ = {{")
        target_end = s.find("};", target_start)
        current_target = s[target_start:target_end+2]
        
        # Add to packageProductDependencies array
        pkg_deps_m = re.search(r"packageProductDependencies = \((.*?)\);", current_target, re.S)
        if pkg_deps_m:
            current_deps = pkg_deps_m.group(1)
            new_deps = current_deps + f"\n\t\t\t\t{prod_id} /* {prod} */,"
            new_target = current_target.replace(pkg_deps_m.group(0), f"packageProductDependencies = ({new_deps}\n\t\t\t);")
            s = s[:target_start] + new_target + s[target_end+2:]

# Write the updated project file
try:
    pbx_path.write_text(s, encoding="utf-8")
    print("✅ Swift macro configuration added successfully")
except Exception as e:
    print(f"❌ Failed to write project.pbxproj: {e}")
    sys.exit(1)

# Verify the changes
for prod in macro_products:
    if f"productName = {prod};" in s:
        print(f"✅ {prod} configured")
    else:
        print(f"❌ {prod} missing")