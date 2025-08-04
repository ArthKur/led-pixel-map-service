#!/bin/bash

echo "🧪 Testing Cloud Pixel Map Service"
echo "=================================="

# Test health endpoint
echo "1. Testing health endpoint..."
curl -s http://localhost:8080/ | python3 -m json.tool
echo ""

# Test pixel map generation
echo "2. Testing pixel map generation (5×3 Absen panels = 1000×600px)..."
curl -s -X POST http://localhost:8080/generate-pixel-map \
  -H "Content-Type: application/json" \
  -d '{
    "surface": {
      "panelsWidth": 5,
      "fullPanelsHeight": 3,
      "halfPanelsHeight": 0,
      "panelPixelWidth": 200,
      "panelPixelHeight": 200,
      "ledName": "Absen PL2.5 Lite"
    },
    "config": {
      "surfaceIndex": 0,
      "showGrid": true,
      "showPanelNumbers": true
    }
  }' | python3 -c "
import json
import sys
data = json.load(sys.stdin)
if data.get('success'):
    print(f'✅ SUCCESS: Generated {data[\"dimensions\"][\"width\"]}×{data[\"dimensions\"][\"height\"]}px image ({data[\"file_size_mb\"]}MB)')
    print(f'   LED: {data[\"led_info\"][\"name\"]} ({data[\"led_info\"][\"panel_pixels\"]} per panel)')
    print(f'   Image data: {len(data[\"image_base64\"])} characters (base64)')
else:
    print(f'❌ ERROR: {data.get(\"error\", \"Unknown error\")}')
"

echo ""
echo "3. Testing large image (100×50 panels = 20000×10000px = 200MP)..."
curl -s -X POST http://localhost:8080/generate-pixel-map \
  -H "Content-Type: application/json" \
  -d '{
    "surface": {
      "panelsWidth": 100,
      "fullPanelsHeight": 50,
      "halfPanelsHeight": 0,
      "panelPixelWidth": 200,
      "panelPixelHeight": 200,
      "ledName": "Absen PL2.5 Lite (Cloud Test)"
    },
    "config": {
      "surfaceIndex": 0,
      "showGrid": false,
      "showPanelNumbers": false
    }
  }' | python3 -c "
import json
import sys
data = json.load(sys.stdin)
if data.get('success'):
    print(f'✅ SUCCESS: Generated HUGE image {data[\"dimensions\"][\"width\"]}×{data[\"dimensions\"][\"height\"]}px ({data[\"file_size_mb\"]}MB)')
    print(f'   This would NEVER work in browser! Cloud service FTW! 🚀')
else:
    print(f'❌ ERROR: {data.get(\"error\", \"Unknown error\")}')
"

echo ""
echo "🎉 Cloud service testing complete!"
