#!/bin/zsh

# Run the Flutter app with the correct target file
cd "$(dirname "$0")"
flutter run -d chrome -t lib/main.dart "$@"
