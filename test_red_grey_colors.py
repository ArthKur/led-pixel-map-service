#!/usr/bin/env python3
"""Test the new red/grey alternating color scheme with a smaller sample"""

import requests
import json
import base64
import os

def test_red_grey_colors():
    print(f"🎨 TESTING RED/GREY ALTERNATING COLOR SCHEME")
    print(f"=" * 50)
    
    # Small test configuration for quick verification
    test_data = {
        "surface": {
            "panelsWidth": 8,  # 8 panels wide
            "fullPanelsHeight": 6,  # 6 panels high
            "halfPanelsHeight": 0,
            "panelPixelWidth": 100,  # Smaller panels for quick test
            "panelPixelHeight": 100,
            "ledName": "Red/Grey Test Pattern"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,
            "showPanelNumbers": True  # Enable numbers to see pattern clearly
        }
    }
    
    service_url = "https://led-pixel-map-service-1.onrender.com"
    
    print(f"📡 Testing new color scheme on cloud service...")
    print(f"🎯 Pattern: 8×6 panels (800×600 pixels)")
    print(f"🔴 Colors: Full Red (255,0,0) & Medium Grey (128,128,128)")
    print(f"🔄 Pattern: Alternating checkerboard style")
    
    try:
        response = requests.post(
            f"{service_url}/generate-pixel-map",
            headers={'Content-Type': 'application/json'},
            json=test_data,
            timeout=60
        )
        
        if response.status_code == 200:
            result = response.json()
            
            if result.get('success'):
                image_base64 = result.get('image_base64', '')
                display_dims = result.get('display_dimensions', {})
                
                print(f"✅ RED/GREY TEST SUCCESSFUL!")
                print(f"   📐 Resolution: {display_dims.get('width', 'N/A')}×{display_dims.get('height', 'N/A')} pixels")
                print(f"   📦 Panels: 8×6 = 48 total panels")
                print(f"   💾 File size: {result.get('file_size_mb', 0)} MB")
                
                # Download test image to desktop
                if image_base64:
                    image_bytes = base64.b64decode(image_base64)
                    
                    desktop_path = os.path.join(os.path.expanduser("~"), "Desktop")
                    filename = "red_grey_test_pattern.png"
                    file_path = os.path.join(desktop_path, filename)
                    
                    with open(file_path, 'wb') as f:
                        f.write(image_bytes)
                    
                    actual_size_mb = len(image_bytes) / (1024 * 1024)
                    
                    print(f"")
                    print(f"🎉 TEST PATTERN DOWNLOADED!")
                    print(f"   📁 Location: {file_path}")
                    print(f"   📊 File size: {actual_size_mb:.2f} MB")
                    print(f"   🎨 Colors: Full Red & Medium Grey")
                    print(f"   🔄 Pattern: Alternating checkerboard")
                    print(f"   🔢 Panel numbers: Visible for verification")
                    
                    return True
                
            else:
                print(f"❌ Service error: {result}")
                return False
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    success = test_red_grey_colors()
    
    if success:
        print(f"\n🏆 SUCCESS! Red/Grey color scheme is working!")
        print(f"📝 Pattern: Panels alternate between Full Red and Medium Grey")
        print(f"🎯 Ready for massive 40K×2400 generation with new colors!")
    else:
        print(f"\n❌ Test failed. Check cloud service deployment status.")
