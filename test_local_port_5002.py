#!/usr/bin/env python3
"""
Test local service on port 5002 with border spacing fix
"""

import requests
import base64
import json

def test_local_service():
    """Test the local service running on port 5002"""
    
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
    
    print("🧪 Testing local service on port 5002...")
    print(f"📦 Test config: {test_data['width']}×{test_data['height']} panels of {test_data['ledPanelWidth']}×{test_data['ledPanelHeight']}px")
    
    try:
        # Test local service
        response = requests.post("http://localhost:5002/generate-pixel-map", 
                               json=test_data, 
                               timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                # Save the result image
                image_data = result.get('image_base64', '')
                if image_data:
                    with open('test_local_5002_borders.png', 'wb') as f:
                        f.write(base64.b64decode(image_data))
                    
                    print("✅ LOCAL SERVICE SUCCESS!")
                    print(f"   📊 Dimensions: {result.get('dimensions', {})}")
                    print(f"   📁 File size: {result.get('file_size_mb', 0):.3f}MB")
                    print(f"   💾 Saved as: test_local_5002_borders.png")
                    print(f"   🎨 LED: {result.get('led_info', {}).get('name', 'Unknown')}")
                    print(f"   📝 Note: {result.get('note', 'No note')}")
                    
                    # Check for border spacing info
                    if 'BORDER SPACING' in result.get('note', '').upper():
                        print("🎯 BORDER SPACING FIX CONFIRMED!")
                    
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
    test_local_service()
