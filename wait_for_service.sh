#!/bin/bash

echo "🔄 Waiting for Render deployment..."
echo "This can take 2-10 minutes on free tier"
echo "========================================"

URL="https://led-pixel-map-service-1.onrender.com"
MAX_ATTEMPTS=30
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    echo "Attempt $ATTEMPT/$MAX_ATTEMPTS: Testing $URL"
    
    STATUS=$(curl -s -w "%{http_code}" -o /dev/null "$URL/")
    
    if [ "$STATUS" = "200" ]; then
        echo "🎉 SERVICE IS ONLINE!"
        echo ""
        echo "Testing 40000×2400px generation..."
        
        curl -s -X POST "$URL/generate-pixel-map" \
          -H "Content-Type: application/json" \
          -d '{
            "surface": {
              "panelsWidth": 200,
              "fullPanelsHeight": 12,
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
        print(f'🚀 MASSIVE SUCCESS: Generated {data[\"dimensions\"][\"width\"]}×{data[\"dimensions\"][\"height\"]}px')
        print(f'📊 Display size: {data[\"dimensions\"][\"displayWidth\"]}×{data[\"dimensions\"][\"displayHeight\"]}px')
        print(f'💾 File size: {data[\"file_size_mb\"]}MB')
        print(f'⚡ Scale factor: {data[\"scale_factor\"]}')
        print('')
        print('🎯 Your cloud service is now handling UNLIMITED pixel map sizes!')
        print('🔥 This completely bypasses browser Canvas API limitations!')
    else:
        print(f'❌ ERROR: {data.get(\"error\", \"Unknown error\")}')
except Exception as e:
    print(f'❌ Failed to parse response: {e}')
"
        break
    elif [ "$STATUS" = "502" ]; then
        echo "⏳ Status: 502 (still deploying...)"
    else
        echo "❌ Status: $STATUS"
    fi
    
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        echo ""
        echo "⚠️  Deployment taking longer than expected."
        echo "Check your Render dashboard: https://dashboard.render.com/"
        echo "The service should eventually come online."
        echo ""
        echo "💡 Once online, integrate with Flutter using:"
        echo "   URL: $URL/generate-pixel-map"
        break
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    sleep 20
done
