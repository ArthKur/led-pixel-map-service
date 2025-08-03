#!/bin/bash

echo "🧪 Testing Cloud Pixel Map Integration"
echo "====================================="

# Wait for Flutter to start
echo "Waiting for Flutter app to start..."
sleep 10

# Test the cloud service directly
echo ""
echo "1. Testing cloud service health..."
curl -s https://led-pixel-map-service.onrender.com/ && echo "" || echo "Service not responding (might be starting up)"

echo ""
echo "2. Testing pixel map generation (this will wake up the service)..."
curl -s -X POST https://led-pixel-map-service.onrender.com/generate-pixel-map \
  -H "Content-Type: application/json" \
  -d '{
    "surface": {
      "panelsWidth": 3,
      "fullPanelsHeight": 2,
      "halfPanelsHeight": 0,
      "panelPixelWidth": 200,
      "panelPixelHeight": 200,
      "ledName": "Absen PL2.5 Lite (Cloud Test)"
    },
    "config": {
      "surfaceIndex": 0,
      "showGrid": true,
      "showPanelNumbers": true
    }
  }' | python3 -c "
import json
import sys
try:
    data = json.load(sys.stdin)
    if data.get('success'):
        print(f'✅ SUCCESS: Cloud generated {data[\"dimensions\"][\"width\"]}×{data[\"dimensions\"][\"height\"]}px image!')
        print(f'   File size: {data[\"file_size_mb\"]}MB')
        print(f'   LED: {data[\"led_info\"][\"name\"]}')
    else:
        print(f'❌ ERROR: {data.get(\"error\", \"Unknown error\")}')
except Exception as e:
    print(f'⚠️  Service might be starting up: {e}')
"

echo ""
echo "🎉 Integration test complete!"
echo "📱 Check your Flutter app - you should see the Cloud Service option!"
