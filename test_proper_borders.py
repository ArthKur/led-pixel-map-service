#!/usr/bin/env python3
"""
Test the proper border fix - borders within panel boundaries
"""

import requests
import base64
import json

def test_proper_borders():
    """Test the proper border fix on port 5003"""
    
    # Test with small Absen panels for border visibility
    test_data = {
        "width": 4,
        "height": 3,
        "ledPanelWidth": 64,
        "ledPanelHeight": 64,
        "ledName": "Absen",
        "showGrid": True,
        "showPanelNumbers": True
    }
    
    print("🔧 Testing PROPER BORDER FIX on port 5003...")
    print(f"📦 Test config: {test_data['width']}×{test_data['height']} panels of {test_data['ledPanelWidth']}×{test_data['ledPanelHeight']}px")
    print("🎯 Expected: 1px borders WITHIN panel boundaries, no white lines")
    
    try:
        # Test local service with proper border fix
        response = requests.post("http://localhost:5003/generate-pixel-map", 
                               json=test_data, 
                               timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                # Save the result image
                image_data = result.get('image_base64', '')
                if image_data:
                    with open('test_proper_borders_v15.png', 'wb') as f:
                        f.write(base64.b64decode(image_data))
                    
                    print("✅ PROPER BORDER FIX SUCCESS!")
                    print(f"   📊 Dimensions: {result.get('dimensions', {})}")
                    print(f"   📁 File size: {result.get('file_size_mb', 0):.3f}MB")
                    print(f"   💾 Saved as: test_proper_borders_v15.png")
                    print(f"   🎨 LED: {result.get('led_info', {}).get('name', 'Unknown')}")
                    print(f"   📝 Note: {result.get('note', 'No note')}")
                    
                    return True
                else:
                    print("❌ No image data in response")
                    return False
            else:
                print(f"❌ Service error: {result.get('error', 'Unknown error')}")
                return False
        else:
            print(f"❌ HTTP error: {response.status_code}")
            print(f"   Response: {response.text[:200]}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Connection error: {e}")
        return False

if __name__ == "__main__":
    test_proper_borders()
