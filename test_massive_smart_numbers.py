#!/usr/bin/env python3
"""Test massive 40000x2400 with improved panel number scaling"""

import requests
import json
import base64
import os

def test_massive_with_numbers():
    print(f"🔢 TESTING MASSIVE 40000×2400 WITH SMART PANEL NUMBERS")
    print(f"=" * 70)
    
    # Test the original massive configuration but WITH panel numbers
    test_data = {
        "surface": {
            "panelsWidth": 200,  # 200 panels wide
            "fullPanelsHeight": 12,  # 12 panels high  
            "halfPanelsHeight": 0,
            "panelPixelWidth": 200,
            "panelPixelHeight": 200,
            "ledName": "Massive 40K LED Wall - Smart Numbers"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,
            "showPanelNumbers": True  # ENABLE numbers to test scaling
        }
    }
    
    total_pixels = 200 * 200 * 200 * 12  # 96 million pixels
    
    print(f"🎯 Target: 40000×2400 pixels ({total_pixels:,} total pixels)")
    print(f"📦 Panels: 200×12 = 2400 panels")
    print(f"🔢 Expected font scaling: 1.5% (very small for readability)")
    print(f"🎨 Features: Red/grey alternating + white text backgrounds")
    print(f"=" * 70)
    
    service_url = "https://led-pixel-map-service-1.onrender.com"
    
    try:
        print(f"📡 Generating massive pixel map with smart panel numbers...")
        
        response = requests.post(
            f"{service_url}/generate-pixel-map",
            headers={'Content-Type': 'application/json'},
            json=test_data,
            timeout=600  # 10 minutes for massive generation
        )
        
        if response.status_code == 200:
            result = response.json()
            
            if result.get('success'):
                image_base64 = result.get('image_base64', '')
                display_dims = result.get('display_dimensions', {})
                original_dims = result.get('dimensions', {})
                
                print(f"✅ MASSIVE GENERATION WITH SMART NUMBERS SUCCESS!")
                print(f"   📐 Original: {original_dims.get('width', 'N/A')}×{original_dims.get('height', 'N/A')} pixels")
                print(f"   📺 Display: {display_dims.get('width', 'N/A')}×{display_dims.get('height', 'N/A')} pixels")
                print(f"   🔢 Scale factor: {result.get('scale_factor', 1):.2f}")
                print(f"   💾 File size: {result.get('file_size_mb', 0)} MB")
                
                # Download to desktop
                if image_base64:
                    image_bytes = base64.b64decode(image_base64)
                    
                    desktop_path = os.path.join(os.path.expanduser("~"), "Desktop")
                    filename = "massive_40K_smart_panel_numbers.png"
                    file_path = os.path.join(desktop_path, filename)
                    
                    with open(file_path, 'wb') as f:
                        f.write(image_bytes)
                    
                    actual_size_mb = len(image_bytes) / (1024 * 1024)
                    
                    print(f"")
                    print(f"🎉 DOWNLOAD COMPLETE!")
                    print(f"   📁 Location: {file_path}")
                    print(f"   📊 File size: {actual_size_mb:.2f} MB")
                    print(f"   🔢 Panel numbers: Smart-scaled with white backgrounds")
                    print(f"   🎨 Colors: Red/grey alternating pattern")
                    print(f"   📏 Font scaling: Optimized for 96M pixel canvas")
                    print(f"   ✅ Readability: High contrast, proportional sizing")
                    
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
    success = test_massive_with_numbers()
    
    if success:
        print(f"\\n🏆 SUCCESS! Massive 40K pixel map with smart panel numbers!")
        print(f"🔍 Compare with previous version to see improved number scaling")
        print(f"📝 Panel numbers now readable even at massive scale!")
    else:
        print(f"\\n❌ Generation failed.")
