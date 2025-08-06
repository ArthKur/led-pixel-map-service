#!/bin/bash

# Fix CloudPixelMapService calls to include new parameters
sed -i '' \
  -e 's/showPanelNumbers: showPanelNumbers,$/showPanelNumbers: showPanelNumbers,/g' \
  -e '/showPanelNumbers: showPanelNumbers,$/a\
          showName: showName,\
          showCross: showCross,\
          showCircle: showCircle,\
          showLogo: showLogo,' \
  /Users/arturkurowski/Desktop/PROJECT\ /led_calculator_2_0/lib/services/pixel_map_service.dart
