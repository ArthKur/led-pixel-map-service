#!/usr/bin/env python3
"""
Test with more obvious borders for debugging
"""

import requests
import json

def test_obvious_borders():
    """Test with smaller panels and more obvious borders"""
    
    print("🔍 TESTING WITH MORE OBVIOUS BORDERS")
    print("=" * 45)
    
    url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
    
    # Use smaller panels so borders are more visible
    test_data = {
        "surface": {
            "panelsWidth": 3,
            "fullPanelsHeight": 3,
            "panelPixelWidth": 80,  # Smaller panels
            "panelPixelHeight": 80,
            "ledName": "Absen"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,  # GRID ON
            "showPanelNumbers": True
        }
    }
    
    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
    
    try:
        print("📤 Sending request for obvious borders test...")
        print(f"   Panels: 3x3 of 80x80px each = 240x240px total")
        
        response = requests.post(url, json=test_data, headers=headers, timeout=30)
        
        if response.status_code == 200:
            response_data = response.json()
            if response_data.get('success'):
                print("✅ SUCCESS!")
                
                if 'image_base64' in response_data:
                    import base64
                    image_data = base64.b64decode(response_data['image_base64'])
                    filename = 'obvious_borders_test.png'
                    with open(filename, 'wb') as f:
                        f.write(image_data)
                    print(f"💾 Saved as: {filename}")
                    print("🔍 At this small size, brighter borders should be VERY obvious")
                    print("   Red panels should have clearly brighter red edges")
                    print("   Grey panels should have clearly brighter grey edges")
                    return True
        
        print(f"❌ FAILED: {response.status_code}")
        return False
        
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return False

def test_no_grid():
    """Test without grid for comparison"""
    
    print("\n🔍 TESTING WITHOUT GRID (for comparison)")
    print("=" * 45)
    
    url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
    
    test_data = {
        "surface": {
            "panelsWidth": 3,
            "fullPanelsHeight": 3,
            "panelPixelWidth": 80,
            "panelPixelHeight": 80,
            "ledName": "Absen"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": False,  # GRID OFF
            "showPanelNumbers": True
        }
    }
    
    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
    
    try:
        response = requests.post(url, json=test_data, headers=headers, timeout=30)
        
        if response.status_code == 200:
            response_data = response.json()
            if response_data.get('success'):
                print("✅ SUCCESS!")
                
                if 'image_base64' in response_data:
                    import base64
                    image_data = base64.b64decode(response_data['image_base64'])
                    filename = 'no_borders_test.png'
                    with open(filename, 'wb') as f:
                        f.write(image_data)
                    print(f"💾 Saved as: {filename}")
                    return True
        
        print(f"❌ FAILED: {response.status_code}")
        return False
        
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return False

if __name__ == "__main__":
    success1 = test_obvious_borders()
    success2 = test_no_grid()
    
    if success1 and success2:
        print("\n🎯 COMPARISON READY!")
        print("📋 Compare these two small images:")
        print("   • obvious_borders_test.png (WITH brighter borders)")
        print("   • no_borders_test.png (WITHOUT borders)")
        print("\n🔍 The difference should be VERY clear at this small size!")
        print("   If you still see white lines in 'obvious_borders_test.png',")
        print("   then there's a fundamental issue with the implementation.")
    else:
        print("\n❌ Tests failed")
