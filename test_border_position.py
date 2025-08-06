#!/usr/bin/env python3
"""
🔧 TEST BORDER POSITIONING
Test exactly where borders should be drawn for 200x200 panels
"""

import requests
import json
import base64
from PIL import Image
from io import BytesIO

def test_border_positioning():
    url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
    
    # Simple test: 2x2 panels, 200x200 each = 400x400 total
    data = {
        "surface": {
            "panelsWidth": 2,
            "fullPanelsHeight": 2,
            "halfPanelsHeight": 0,
            "panelPixelWidth": 200,
            "panelPixelHeight": 200,
            "ledName": "Absen PL2.5 Lite"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,
            "showPanelNumbers": False,  # Disable to focus on borders
            "showNames": False,
            "showCrosses": False,
            "showCircles": False,
            "showLetters": False
        }
    }
    
    print("🔧 TESTING BORDER POSITIONING")
    print("=" * 50)
    print("Configuration:")
    print(f"  • Panels: 2x2 = 4 panels total")
    print(f"  • Panel size: 200x200 pixels each")
    print(f"  • Total image: 400x400 pixels")
    print(f"  • Expected borders on pixel 199 of each panel")
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
                    img.save('border_position_test.png')
                    
                    width, height = img.size
                    print(f"✅ Saved: border_position_test.png ({width}x{height})")
                    
                    # Test specific border pixels for 200x200 panels
                    print("\n🔍 BORDER PIXEL ANALYSIS:")
                    print("Expected panel layout:")
                    print("  Panel (0,0): x=0-199,   y=0-199   (RED)")
                    print("  Panel (1,0): x=200-399, y=0-199   (GREY)")  
                    print("  Panel (0,1): x=0-199,   y=200-399 (GREY)")
                    print("  Panel (1,1): x=200-399, y=200-399 (RED)")
                    print()
                    
                    # Sample key border positions
                    test_positions = [
                        # Panel (0,0) borders - should be brighter RED
                        ((199, 0), "Panel(0,0) top-right border"),
                        ((199, 199), "Panel(0,0) bottom-right border"),
                        ((0, 199), "Panel(0,0) bottom-left border"),
                        ((199, 100), "Panel(0,0) right edge"),
                        
                        # Panel (1,0) borders - should be brighter GREY  
                        ((399, 0), "Panel(1,0) top-right border"),
                        ((399, 199), "Panel(1,0) bottom-right border"),
                        ((200, 199), "Panel(1,0) bottom-left border"),
                        
                        # Interior pixels for comparison
                        ((100, 100), "Panel(0,0) center - base RED"),
                        ((300, 100), "Panel(1,0) center - base GREY"),
                    ]
                    
                    for (x, y), description in test_positions:
                        if x < width and y < height:
                            pixel = img.getpixel((x, y))
                            print(f"  {description:30} ({x:3},{y:3}): {pixel}")
                    
                    print()
                    print("✅ Check border_position_test.png to verify:")
                    print("  • Panel borders should be brighter versions of panel color")
                    print("  • Red panels should have brighter red borders")
                    print("  • Grey panels should have brighter grey borders")
                    print("  • Borders should be exactly on pixel 199 of each 200px panel")
                    
                else:
                    print("❌ No PNG data found")
            else:
                print(f"❌ Failed: {result.get('error')}")
        else:
            print(f"❌ HTTP error: {response.status_code}")
    except Exception as e:
        print(f"❌ Exception: {e}")

if __name__ == "__main__":
    test_border_positioning()
