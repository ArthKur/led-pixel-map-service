#!/usr/bin/env python3

import requests
import base64
import json
import os

print("🧪 Testing Cloud Pixel Map Download")
print("====================================")

# Test data for large pixel map
test_data = {
    "surface": {
        "panelsWidth": 200,
        "fullPanelsHeight": 12,
        "panelPixelWidth": 200,
        "panelPixelHeight": 200,
        "ledName": "Absen PL2.5 Lite - ULTRA WIDE TEST"
    }
}

try:
    print("📡 Requesting 40000×2400px pixel map from cloud...")
    response = requests.post(
        "https://led-pixel-map-service-1.onrender.com/generate-pixel-map",
        headers={"Content-Type": "application/json"},
        json=test_data,
        timeout=30
    )
    
    if response.status_code == 200:
        data = response.json()
        
        if data.get('success'):
            print(f"✅ Success! Generated {data['dimensions']['width']}×{data['dimensions']['height']}px")
            print(f"📊 Format: {data['format']}")
            print(f"💾 File size: {data['file_size_mb']}MB")
            
            # Decode base64 SVG
            svg_content = base64.b64decode(data['image_base64']).decode('utf-8')
            
            # Save to desktop
            filename = f"Test_Cloud_Pixel_Map_40000x2400_{data['led_info']['name'].replace(' ', '_')}.svg"
            desktop_path = f"/Users/{os.environ.get('USER', 'user')}/Desktop/{filename}"
            
            with open(desktop_path, 'w') as f:
                f.write(svg_content)
            
            print(f"💾 File saved to: {desktop_path}")
            print(f"🎉 You can now open the SVG file to see the detailed pixel map!")
            print(f"📏 This would be IMPOSSIBLE to generate in browser due to Canvas API limits!")
            
        else:
            print(f"❌ Error: {data.get('error', 'Unknown error')}")
    else:
        print(f"❌ HTTP Error: {response.status_code}")
        print(response.text)

except Exception as e:
    print(f"❌ Failed: {e}")
