#!/bin/bash

# Script to ensure macros are built for the correct architecture
# This resolves "malformed response" errors from macro plugins

echo "🔧 Fixing Macro Architecture Issues"
echo "===================================="

# Clean everything first
echo "1️⃣ Cleaning all build artifacts..."
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf DerivedData
rm -rf build

# Get the host architecture
HOST_ARCH=$(uname -m)
echo "Host architecture: $HOST_ARCH"

# For CI environments, we need to build macros for the host architecture
if [[ "$HOST_ARCH" == "x86_64" ]]; then
    echo "Building for Intel Mac..."
    ARCH_FLAG="-arch x86_64"
elif [[ "$HOST_ARCH" == "arm64" ]]; then
    echo "Building for Apple Silicon..."
    ARCH_FLAG="-arch arm64"
else
    echo "Unknown architecture: $HOST_ARCH"
    exit 1
fi

# Resolve packages and build macros for host
echo "2️⃣ Resolving packages with clean cache..."
xcodebuild -resolvePackageDependencies \
    -project AgentDashboard.xcodeproj \
    -scheme AgentDashboard \
    -derivedDataPath ./DerivedData \
    -skipPackagePluginValidation \
    -skipMacroValidation \
    -clonedSourcePackagesDirPath ./SourcePackages

# Build for simulator with explicit architecture
echo "3️⃣ Building for simulator..."
xcodebuild build \
    -project AgentDashboard.xcodeproj \
    -scheme AgentDashboard \
    -sdk iphonesimulator \
    -configuration Debug \
    -derivedDataPath ./DerivedData \
    -destination "generic/platform=iOS Simulator" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    ONLY_ACTIVE_ARCH=NO \
    ARCHS="x86_64 arm64" \
    VALID_ARCHS="x86_64 arm64" \
    -UseModernBuildSystem=YES \
    OTHER_SWIFT_FLAGS="-Xfrontend -disable-availability-checking"

BUILD_RESULT=$?

if [ $BUILD_RESULT -eq 0 ]; then
    echo "✅ Build succeeded!"
else
    echo "❌ Build failed with code: $BUILD_RESULT"
    echo "Checking for macro issues..."
    
    # Debug macro locations
    echo "Macro locations:"
    find DerivedData -name "*Macro*" -type f 2>/dev/null | head -20
    
    # Check architecture of built macros
    echo "Checking macro architectures:"
    find DerivedData -name "*Macros" -type f -exec file {} \; 2>/dev/null | grep -i mach-o
fi

exit $BUILD_RESULT