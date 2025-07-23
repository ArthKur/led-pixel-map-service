#!/bin/bash
# Temporarily disable code signing for Flutter development

cd /Users/arturkurowski/Desktop/led_calculator_2_0

# Build the app with specific Xcode settings to disable code signing
/opt/homebrew/bin/flutter build macos --debug --dart-define=FLUTTER_WEB_USE_SKIA=true

# If build succeeds, try to run the app directly
if [ $? -eq 0 ]; then
    echo "Build successful! Attempting to run the app..."
    open ./build/macos/Build/Products/Debug/led_calculator_2_0.app
else
    echo "Build failed due to code signing. Trying alternative approach..."
    # Try running with relaxed security
    export FLUTTER_XCODE_CODESIGN_IDENTITY=""
    export FLUTTER_XCODE_DEVELOPMENT_TEAM=""
    /opt/homebrew/bin/flutter run -d macos
fi
