#!/usr/bin/env python3
"""
Test with timestamp to avoid any caching issues
"""

import requests
import json
import time

def test_no_cache():
    """Test with cache-busting timestamp"""
    
    timestamp = int(time.time())
    
    print(f"🕐 TIMESTAMP TEST: {timestamp}")
    print("=" * 40)
    
    url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
    
    # Add timestamp to avoid any caching
    test_data = {
        "surface": {
            "panelsWidth": 2,
            "fullPanelsHeight": 2,
            "panelPixelWidth": 50,
            "panelPixelHeight": 50,
            "ledName": f"Absen_Test_{timestamp}"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,
            "showPanelNumbers": True
        }
    }
    
    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache'
    }
    
    try:
        print("📤 Sending cache-busting request...")
        
        response = requests.post(url, json=test_data, headers=headers, timeout=30)
        
        if response.status_code == 200:
            response_data = response.json()
            if response_data.get('success'):
                print("✅ SUCCESS: Grid should be working")
                
                if 'image_base64' in response_data:
                    import base64
                    image_data = base64.b64decode(response_data['image_base64'])
                    filename = f'cache_test_{timestamp}.png'
                    with open(filename, 'wb') as f:
                        f.write(image_data)
                    print(f"💾 Fresh image saved as: {filename}")
                    print("🔍 This image should have BRIGHTER BORDERS, not white lines")
                    return True
        
        print(f"❌ FAILED: {response.status_code}")
        return False
        
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return False

if __name__ == "__main__":
    test_no_cache()
