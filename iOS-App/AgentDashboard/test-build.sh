#!/bin/bash

echo "🔧 iOS Build Test Script"
echo "========================"

PROJECT_PATH="AgentDashboard.xcodeproj"
SCHEME="AgentDashboard"
BUILD_DIR="./test-build-output"

# Clean everything
echo "1️⃣ Cleaning DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf "$BUILD_DIR"

# Resolve packages
echo "2️⃣ Resolving package dependencies..."
xcodebuild -resolvePackageDependencies \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  -skipPackagePluginValidation \
  -skipMacroValidation

# Build for simulator
echo "3️⃣ Building for iOS Simulator..."
xcodebuild build \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  -UseModernBuildSystem=YES

BUILD_RESULT=$?

if [ $BUILD_RESULT -eq 0 ]; then
    echo "✅ Build succeeded!"
else
    echo "❌ Build failed with code: $BUILD_RESULT"
    echo "Check the logs above for details"
fi

exit $BUILD_RESULT