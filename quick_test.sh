#!/bin/bash

echo "🔄 Monitoring deployment progress..."
echo "==================================="

URL="https://led-pixel-map-service-1.onrender.com"
MAX_ATTEMPTS=20
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    echo "Attempt $ATTEMPT/$MAX_ATTEMPTS: Testing $URL"
    
    RESPONSE=$(curl -s "$URL/" 2>/dev/null)
    STATUS=$(curl -s -w "%{http_code}" -o /dev/null "$URL/" 2>/dev/null)
    
    if [ "$STATUS" = "200" ]; then
        echo "🎉 SERVICE IS ONLINE!"
        echo "Response: $RESPONSE"
        echo ""
        echo "✅ Your cloud pixel map service is now working!"
        echo "🌐 URL: $URL"
        echo ""
        echo "🧪 Testing a basic pixel map generation..."
        
        RESULT=$(curl -s -X POST "$URL/generate-pixel-map" \
          -H "Content-Type: application/json" \
          -d '{
            "surface": {
              "panelsWidth": 10,
              "fullPanelsHeight": 5,
              "panelPixelWidth": 200,
              "panelPixelHeight": 200
            }
          }' 2>/dev/null)
        
        echo "Generation result: $RESULT"
        break
    else
        echo "❌ Status: $STATUS"
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    sleep 15
done

if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
    echo "⚠️ Service still not responding after maximum attempts"
    echo "Check Render dashboard for more details"
fi
