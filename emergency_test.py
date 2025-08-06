#!/usr/bin/env python3
"""
Emergency test to verify what the cloud service is actually generating
"""

import requests
import json
import base64

def emergency_test():
    print("🚨 EMERGENCY GRID TEST")
    print("=" * 30)
    
    url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
    
    # Very simple test
    data = {
        "surface": {
            "panelsWidth": 2,
            "fullPanelsHeight": 2,
            "panelPixelWidth": 100,
            "panelPixelHeight": 100,
            "ledName": "Test"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,
            "showPanelNumbers": False
        }
    }
    
    try:
        response = requests.post(url, json=data, timeout=30)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success') and 'image_base64' in result:
                img_data = base64.b64decode(result['image_base64'])
                with open('emergency_test.png', 'wb') as f:
                    f.write(img_data)
                print("✅ Image saved as emergency_test.png")
                print("🔍 Check this image - if it has WHITE LINES, the cloud service is broken")
                print("🔍 If it has BRIGHTER BORDERS, then your Flutter app has a different issue")
                return True
            else:
                print(f"❌ Error: {result.get('error', 'No image data')}")
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            print(response.text[:200])
        
        return False
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False

if __name__ == "__main__":
    emergency_test()
