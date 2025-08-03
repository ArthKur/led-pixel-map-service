#!/bin/bash

echo "🧪 Testing 40000×2400px Generation"
echo "================================="

# Test with a few common Render URL patterns
URLS=(
    "https://led-pixel-map-service.onrender.com"
    "https://led-pixel-map-service-1.onrender.com"
    "https://led-pixel-map-service-2.onrender.com"
    "https://led-pixel-map-service-3.onrender.com"
    "https://arthkur-led-pixel-map-service.onrender.com"
    "https://led-pixel-map-service-arthkur.onrender.com"
    "https://led-pixel-map-service-latest.onrender.com"
    "https://pixel-map-service.onrender.com"
)

for url in "${URLS[@]}"; do
    echo ""
    echo "Testing: $url"
    
    # Health check
    status=$(curl -s -w "%{http_code}" -o /dev/null "$url/")
    if [ "$status" = "200" ]; then
        echo "✅ Service is online!"
        
        # Test large image generation (200×12 Absen panels = 40000×2400px)
        echo "Testing 40000×2400px generation..."
        curl -s -X POST "$url/generate-pixel-map" \
          -H "Content-Type: application/json" \
          -d '{
            "surface": {
              "panelsWidth": 200,
              "fullPanelsHeight": 12,
              "halfPanelsHeight": 0,
              "panelPixelWidth": 200,
              "panelPixelHeight": 200,
              "ledName": "Absen PL2.5 Lite - ULTRA WIDE TEST"
            },
            "config": {
              "surfaceIndex": 0,
              "showGrid": false,
              "showPanelNumbers": false
            }
          }' | python3 -c "
import json
import sys
try:
    data = json.load(sys.stdin)
    if data.get('success'):
        print(f'🎉 SUCCESS: Generated {data[\"dimensions\"][\"width\"]}×{data[\"dimensions\"][\"height\"]}px ({data[\"file_size_mb\"]}MB)')
        print(f'This would be IMPOSSIBLE in browser! Cloud service rocks!')
    else:
        print(f'❌ ERROR: {data.get(\"error\", \"Unknown error\")}')
except Exception as e:
    print(f'❌ Failed: {e}')
"
        break
    else
        echo "❌ Status: $status (not responding)"
    fi
done

echo ""
echo "💡 If none work, check your Render.com dashboard for the correct URL!"
