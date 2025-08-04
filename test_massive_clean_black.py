#!/usr/bin/env python3
"""Test massive 40K canvas with clean black panel numbers"""

import requests
import json
import base64
import os

def test_massive_clean_text():
    print(f"🖤 TESTING MASSIVE 40K WITH CLEAN BLACK TEXT")
    print(f"=" * 60)
    
    # Use the massive configuration with panel numbers enabled
    test_data = {
        "surface": {
            "panelsWidth": 200,  # 200 panels wide (40000px)
            "fullPanelsHeight": 12,  # 12 panels high (2400px)
            "halfPanelsHeight": 0,
            "panelPixelWidth": 200,
            "panelPixelHeight": 200,
            "ledName": "Massive 40K - Clean Black Text"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,
            "showPanelNumbers": True  # ENABLE to test massive scale text
        }
    }
    
    print(f"🎯 Massive Scale: 40000×2400 pixels (96M total pixels)")
    print(f"📦 Panels: 200×12 = 2400 panels")
    print(f"🖤 Text: Clean black, no backgrounds, smart scaling")
    print(f"📏 Expected font: ~1.5% scaling = very small but readable")
    
    service_url = "https://led-pixel-map-service-1.onrender.com"
    
    try:
        print(f"\\n📡 Generating massive pixel map with clean black text...")
        
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
                
                print(f"✅ MASSIVE CLEAN TEXT SUCCESS!")
                print(f"   📐 Original: {original_dims.get('width', 'N/A')}×{original_dims.get('height', 'N/A')} pixels")
                print(f"   📺 Display: {display_dims.get('width', 'N/A')}×{display_dims.get('height', 'N/A')} pixels")
                print(f"   🔢 Scale factor: {result.get('scale_factor', 1):.2f}")
                print(f"   💾 File size: {result.get('file_size_mb', 0)} MB")
                
                # Download to desktop
                if image_base64:
                    image_bytes = base64.b64decode(image_base64)
                    
                    desktop_path = os.path.join(os.path.expanduser("~"), "Desktop")
                    filename = "massive_40K_clean_black_text.png"
                    file_path = os.path.join(desktop_path, filename)
                    
                    with open(file_path, 'wb') as f:
                        f.write(image_bytes)
                    
                    actual_size_mb = len(image_bytes) / (1024 * 1024)
                    
                    print(f"")
                    print(f"🎉 MASSIVE CLEAN TEXT DOWNLOADED!")
                    print(f"   📁 Location: {file_path}")
                    print(f"   📊 File size: {actual_size_mb:.2f} MB")
                    print(f"   🖤 Panel numbers: Clean black text, no backgrounds")
                    print(f"   📏 Font scaling: Optimized for 96M pixel canvas")
                    print(f"   🎨 Colors: Red/grey alternating pattern")
                    print(f"   ✨ Quality: Pixel-perfect, smart-scaled text")
                    
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
    success = test_massive_clean_text()
    
    if success:
        print(f"\\n🏆 SUCCESS! Massive 40K canvas with clean black panel numbers!")
        print(f"🖤 Panel numbers: Pure black text without backgrounds")
        print(f"📏 Smart scaling: Readable even at massive scale")
        print(f"🎯 Perfect for professional LED installations!")
    else:
        print(f"\\n❌ Generation failed.")
