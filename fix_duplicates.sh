#!/bin/bash

# Remove duplicate parameter lines in pixel_map_service.dart
FILE="lib/services/pixel_map_service.dart"

# Remove duplicate showName lines
sed -i '' '/showName: showName,/,+3{N;N;N;/showName: showName,.*showCross: showCross,.*showCircle: showCircle,.*showLogo: showLogo,/{s/showName: showName,.*showCross: showCross,.*showCircle: showCircle,.*showLogo: showLogo,//g}}' "$FILE"

# Alternative approach - remove lines with exact duplicate pattern
sed -i '' '/^[[:space:]]*showName: showName,$/{
    N
    /\n[[:space:]]*showCross: showCross,$/{
        N
        /\n[[:space:]]*showCircle: showCircle,$/{
            N
            /\n[[:space:]]*showLogo: showLogo,$/{
                d
            }
        }
    }
}' "$FILE"

echo "Duplicates removed from $FILE"
