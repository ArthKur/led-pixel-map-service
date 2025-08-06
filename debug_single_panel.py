#!/usr/bin/env python3
"""
🔧 DEBUG BORDER COORDINATES
Test exact coordinates where borders should be drawn
"""

import requests
import json
import base64
from PIL import Image
from io import BytesIO

def debug_border_coordinates():
    url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
    
    # Simple test: 1x1 panel to isolate the issue
    data = {
        "surface": {
            "panelsWidth": 1,
            "fullPanelsHeight": 1, 
            "halfPanelsHeight": 0,
            "panelPixelWidth": 200,
            "panelPixelHeight": 200,
            "ledName": "Absen PL2.5 Lite"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,
            "showPanelNumbers": False,
            "showNames": False,
            "showCrosses": False,
            "showCircles": False,
            "showLetters": False
        }
    }
    
    print("🔧 DEBUG BORDER COORDINATES")
    print("=" * 50)
    print("Single 200x200 panel test")
    print("Expected:")
    print("  • Panel area: (0,0) to (199,199)")
    print("  • Bottom border: y=199, x=0 to x=199")
    print("  • Right border: x=199, y=0 to y=199")
    print("  • Base color: RED (255,0,0)")
    print("  • Border color: Bright RED (255,102,102)")
    print()
    
    try:
        response = requests.post(url, json=data, timeout=20)
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                # Decode PNG
                image_data = result['imageData']
                if image_data.startswith('data:image/png;base64,'):
                    base64_data = image_data.split(',')[1]
                    img_bytes = base64.b64decode(base64_data)
                    img = Image.open(BytesIO(img_bytes))
                    img.save('single_panel_debug.png')
                    
                    width, height = img.size
                    print(f"✅ Saved: single_panel_debug.png ({width}x{height})")
                    
                    # Test specific border coordinates
                    test_coords = [
                        # Expected border positions
                        ((199, 199), "Bottom-right corner (should be border)"),
                        ((199, 100), "Right edge middle (should be border)"),
                        ((100, 199), "Bottom edge middle (should be border)"),
                        ((199, 0), "Top-right corner (should be border)"),
                        ((0, 199), "Bottom-left corner (should be border)"),
                        
                        # Non-border positions
                        ((100, 100), "Center (should be base color)"),
                        ((0, 0), "Top-left (should be base color)"),
                        ((198, 198), "Near corner (should be base color)"),
                    ]
                    
                    print("\n🔍 PIXEL ANALYSIS:")
                    base_color = None
                    border_color = None
                    
                    for (x, y), description in test_coords:
                        if x < width and y < height:
                            pixel = img.getpixel((x, y))
                            print(f"  {description:35} ({x:3},{y:3}): {pixel}")
                            
                            if "Center" in description:
                                base_color = pixel
                            elif "should be border" in description and border_color is None:
                                border_color = pixel
                    
                    print(f"\n🎯 ANALYSIS:")
                    print(f"  Base color:   {base_color}")
                    print(f"  Border color: {border_color}")
                    print(f"  Expected border: (255, 102, 102)")
                    
                    if base_color and border_color:
                        if base_color == border_color:
                            print("  ❌ PROBLEM: Border and base colors are identical!")
                            print("     This means borders are not being drawn.")
                        else:
                            print("  ✅ SUCCESS: Border and base colors are different!")
                    
                else:
                    print("❌ No PNG data found")
            else:
                print(f"❌ Failed: {result.get('error')}")
        else:
            print(f"❌ HTTP error: {response.status_code}")
    except Exception as e:
        print(f"❌ Exception: {e}")

if __name__ == "__main__":
    debug_border_coordinates()
