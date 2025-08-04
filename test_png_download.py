#!/usr/bin/env python3

import requests
import base64
import json
import os

print("🧪 Testing PNG Download from Cloud Service")
print("===========================================")

# Test with the exact same parameters as Flutter app
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
    print("📡 Requesting 40000×2400px PNG from cloud...")
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
            
            # Decode base64 PNG
            png_data = base64.b64decode(data['image_base64'])
            
            # Verify PNG signature
            if png_data[:8] == b'\x89PNG\r\n\x1a\n':
                print("✅ Valid PNG signature!")
            else:
                print("❌ Invalid PNG signature!")
                
            # Save to desktop
            filename = f"Cloud_Test_40000x2400.png"
            desktop_path = f"/Users/{os.environ.get('USER', 'user')}/Desktop/{filename}"
            
            with open(desktop_path, 'wb') as f:
                f.write(png_data)
            
            print(f"💾 PNG file saved to: {desktop_path}")
            print(f"🎉 Try opening the PNG file - it should open properly in Preview!")
            print(f"📏 40000×2400px generation bypassed Canvas API limits!")
            
        else:
            print(f"❌ Error: {data.get('error', 'Unknown error')}")
    else:
        print(f"❌ HTTP Error: {response.status_code}")
        print(response.text)

except Exception as e:
    print(f"❌ Failed: {e}")
