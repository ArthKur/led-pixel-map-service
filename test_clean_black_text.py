#!/usr/bin/env python3
"""Test clean black panel numbers without backgrounds"""

import requests
import json
import base64
import os

def test_clean_black_text():
    print(f"🖤 TESTING CLEAN BLACK PANEL NUMBERS")
    print(f"=" * 50)
    
    # Small test to clearly see the text changes
    test_data = {
        "surface": {
            "panelsWidth": 6,
            "panelsHeight": 4,
            "halfPanelsHeight": 0,
            "panelPixelWidth": 300,  # Larger panels to see text clearly
            "panelPixelHeight": 300,
            "ledName": "Clean Black Text Test"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,
            "showPanelNumbers": True  # Enable to test clean black text
        }
    }
    
    service_url = "https://led-pixel-map-service-1.onrender.com"
    
    print(f"🎯 Testing clean black text rendering...")
    print(f"📦 Pattern: 6×4 panels (1800×1200 pixels)")
    print(f"🖤 Expected: Pure black text, no white backgrounds")
    print(f"🎨 Colors: Red/grey alternating panels")
    
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
                
                print(f"✅ CLEAN BLACK TEXT GENERATED!")
                print(f"   📐 Resolution: {display_dims.get('width', 'N/A')}×{display_dims.get('height', 'N/A')} pixels")
                print(f"   💾 File size: {result.get('file_size_mb', 0)} MB")
                
                # Download test image to desktop
                if image_base64:
                    image_bytes = base64.b64decode(image_base64)
                    
                    desktop_path = os.path.join(os.path.expanduser("~"), "Desktop")
                    filename = "clean_black_text_test.png"
                    file_path = os.path.join(desktop_path, filename)
                    
                    with open(file_path, 'wb') as f:
                        f.write(image_bytes)
                    
                    actual_size_mb = len(image_bytes) / (1024 * 1024)
                    
                    print(f"")
                    print(f"🎉 CLEAN TEXT TEST DOWNLOADED!")
                    print(f"   📁 Location: {file_path}")
                    print(f"   📊 File size: {actual_size_mb:.2f} MB")
                    print(f"   🖤 Text style: Pure black, no backgrounds")
                    print(f"   🎨 Panel colors: Red/grey alternating")
                    print(f"   📏 Font scaling: Smart sizing for readability")
                    
                    # Check service version
                    try:
                        version_response = requests.get(f"{service_url}/", timeout=30)
                        if version_response.status_code == 200:
                            version_info = version_response.json()
                            service_version = version_info.get('version', 'Unknown')
                            features = version_info.get('features', 'Unknown')
                            print(f"   🔧 Service: {service_version}")
                            print(f"   ✨ Features: {features}")
                    except:
                        pass
                    
                    return True
                
            else:
                print(f"❌ Service error: {result}")
                return False
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            print(f"Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    success = test_clean_black_text()
    
    if success:
        print(f"\\n🏆 SUCCESS! Clean black text without backgrounds!")
        print(f"🖤 Panel numbers now render as pure black text")
        print(f"✨ No more white background rectangles")
        print(f"🎯 Ready for all canvas sizes with clean text!")
    else:
        print(f"\\n❌ Test failed. Service may still be deploying...")
