#!/usr/bin/env python3
"""
Test with grid OFF to verify no white lines
"""

import requests
import base64
import json

def test_no_grid():
    """Test with grid disabled to check for white lines"""
    
    # Test with grid OFF
    test_data = {
        "width": 4,
        "height": 3,
        "ledPanelWidth": 64,
        "ledPanelHeight": 64,
        "ledName": "Absen",
        "showGrid": False,  # Grid OFF
        "showPanelNumbers": True
    }
    
    print("🚫 Testing with GRID OFF to check for white lines...")
    print(f"📦 Test config: {test_data['width']}×{test_data['height']} panels of {test_data['ledPanelWidth']}×{test_data['ledPanelHeight']}px")
    print("🎯 Expected: NO white lines, solid panel colors only")
    
    try:
        response = requests.post("http://localhost:5003/generate-pixel-map", 
                               json=test_data, 
                               timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                image_data = result.get('image_base64', '')
                if image_data:
                    with open('test_no_grid_v15.png', 'wb') as f:
                        f.write(base64.b64decode(image_data))
                    
                    print("✅ NO GRID TEST SUCCESS!")
                    print(f"   📊 Dimensions: {result.get('dimensions', {})}")
                    print(f"   💾 Saved as: test_no_grid_v15.png")
                    print("   🔍 Check image: Should have NO white lines between panels")
                    
                    return True
                else:
                    print("❌ No image data in response")
                    return False
            else:
                print(f"❌ Service error: {result.get('error', 'Unknown error')}")
                return False
        else:
            print(f"❌ HTTP error: {response.status_code}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Connection error: {e}")
        return False

if __name__ == "__main__":
    test_no_grid()
