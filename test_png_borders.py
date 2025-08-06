#!/usr/bin/env python3
"""
🔧 FINAL GRID BORDER FIX TEST
Decode PNG and verify borders are actually drawn
"""

import requests
import json
import base64
from PIL import Image
from io import BytesIO

def test_png_borders():
    url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
    
    base_data = {
        "surface": {
            "panelsWidth": 3,
            "fullPanelsHeight": 2,
            "halfPanelsHeight": 0,
            "panelPixelWidth": 120,
            "panelPixelHeight": 120,
            "ledName": "Absen PL2.5 Lite"
        },
        "config": {
            "surfaceIndex": 0,
            "showPanelNumbers": False,  # Disable to focus on borders
            "showNames": False,
            "showCrosses": False,
            "showCircles": False,
            "showLetters": False
        }
    }
    
    print("🔧 FINAL GRID BORDER FIX TEST")
    print("=" * 60)
    
    # Test Grid OFF
    print("🧪 TEST 1: Grid OFF")
    data_off = base_data.copy()
    data_off["config"]["showGrid"] = False
    
    try:
        response = requests.post(url, json=data_off, timeout=20)
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                # Decode PNG
                image_data = result['imageData']
                if image_data.startswith('data:image/png;base64,'):
                    base64_data = image_data.split(',')[1]
                    img_bytes = base64.b64decode(base64_data)
                    img = Image.open(BytesIO(img_bytes))
                    img.save('test_grid_OFF.png')
                    
                    # Sample some border pixels to check colors
                    width, height = img.size
                    # Check corners and edges where borders would be
                    sample_pixels = [
                        img.getpixel((119, 0)),    # Top edge of first panel
                        img.getpixel((119, 119)),  # Bottom edge of first panel
                        img.getpixel((0, 119)),    # Left edge of first panel
                        img.getpixel((239, 0)),    # Between panels
                        img.getpixel((239, 119)),  # Between panels
                    ]
                    
                    print(f"✅ Grid OFF: Saved test_grid_OFF.png ({width}x{height})")
                    print(f"   Sample border pixels: {sample_pixels[:3]}")
                    
                else:
                    print("❌ Grid OFF: No PNG data found")
            else:
                print(f"❌ Grid OFF failed: {result.get('error')}")
        else:
            print(f"❌ Grid OFF HTTP error: {response.status_code}")
    except Exception as e:
        print(f"❌ Grid OFF exception: {e}")
    
    print()
    
    # Test Grid ON
    print("🧪 TEST 2: Grid ON")
    data_on = base_data.copy()
    data_on["config"]["showGrid"] = True
    
    try:
        response = requests.post(url, json=data_on, timeout=20)
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                # Decode PNG
                image_data = result['imageData']
                if image_data.startswith('data:image/png;base64,'):
                    base64_data = image_data.split(',')[1]
                    img_bytes = base64.b64decode(base64_data)
                    img = Image.open(BytesIO(img_bytes))
                    img.save('test_grid_ON.png')
                    
                    # Sample border pixels
                    width, height = img.size
                    sample_pixels = [
                        img.getpixel((119, 0)),    # Top edge of first panel
                        img.getpixel((119, 119)),  # Bottom edge of first panel
                        img.getpixel((0, 119)),    # Left edge of first panel
                        img.getpixel((239, 0)),    # Between panels
                        img.getpixel((239, 119)),  # Between panels
                    ]
                    
                    print(f"✅ Grid ON: Saved test_grid_ON.png ({width}x{height})")
                    print(f"   Sample border pixels: {sample_pixels[:3]}")
                    
                    # Check if borders are visible (different from main color)
                    center_pixel = img.getpixel((60, 60))  # Center of first panel
                    border_pixel = img.getpixel((119, 0))  # Border pixel
                    
                    print(f"   Center pixel: {center_pixel}")
                    print(f"   Border pixel: {border_pixel}")
                    
                    if center_pixel != border_pixel:
                        print("   ✅ BORDERS ARE VISIBLE! (different colors)")
                        
                        # Check if border is brighter
                        center_brightness = sum(center_pixel)
                        border_brightness = sum(border_pixel)
                        
                        if border_brightness > center_brightness:
                            print("   ✅ BORDERS ARE BRIGHTER! (working correctly)")
                        else:
                            print("   ⚠️  Borders same/darker than center")
                    else:
                        print("   ❌ NO BORDERS VISIBLE (same color)")
                    
                else:
                    print("❌ Grid ON: No PNG data found")
            else:
                print(f"❌ Grid ON failed: {result.get('error')}")
        else:
            print(f"❌ Grid ON HTTP error: {response.status_code}")
    except Exception as e:
        print(f"❌ Grid ON exception: {e}")
    
    print()
    print("🔍 ANALYSIS COMPLETE")
    print("=" * 60)
    print("📂 Check test_grid_OFF.png vs test_grid_ON.png")
    print("   The Grid ON image should have visible colored borders")
    print("   The Grid OFF image should have no borders")

if __name__ == "__main__":
    test_png_borders()
