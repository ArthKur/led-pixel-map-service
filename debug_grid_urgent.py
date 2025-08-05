#!/usr/bin/env python3
"""
🔧 URGENT GRID DEBUG TEST
Test if grid parameter is actually working in cloud service
"""

import requests
import json

def test_grid_states():
    url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
    
    # Test data - simple case
    base_data = {
        "surface": {
            "panelsWidth": 2,
            "fullPanelsHeight": 2,
            "halfPanelsHeight": 0,
            "panelPixelWidth": 100,
            "panelPixelHeight": 100,
            "ledName": "Absen PL2.5 Lite"
        },
        "config": {
            "surfaceIndex": 0,
            "showPanelNumbers": False,
            "showNames": False,
            "showCrosses": False,
            "showCircles": False,
            "showLetters": False
        }
    }
    
    print("🔧 URGENT GRID DEBUG TEST")
    print("=" * 50)
    
    # Test 1: Grid OFF
    print("🧪 TEST 1: Grid OFF")
    data_off = base_data.copy()
    data_off["config"]["showGrid"] = False
    
    try:
        response = requests.post(url, json=data_off, timeout=15)
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                svg_data = result.get('svgData', '')
                with open('debug_grid_OFF.svg', 'w') as f:
                    f.write(svg_data)
                print("✅ Grid OFF: Saved debug_grid_OFF.svg")
                
                # Check for stroke attributes in SVG (borders)
                stroke_count = svg_data.count('stroke=')
                print(f"   • Stroke attributes found: {stroke_count}")
            else:
                print(f"❌ Grid OFF failed: {result.get('error')}")
        else:
            print(f"❌ Grid OFF HTTP error: {response.status_code}")
    except Exception as e:
        print(f"❌ Grid OFF exception: {e}")
    
    print()
    
    # Test 2: Grid ON
    print("🧪 TEST 2: Grid ON")
    data_on = base_data.copy()
    data_on["config"]["showGrid"] = True
    
    try:
        response = requests.post(url, json=data_on, timeout=15)
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                svg_data = result.get('svgData', '')
                with open('debug_grid_ON.svg', 'w') as f:
                    f.write(svg_data)
                print("✅ Grid ON: Saved debug_grid_ON.svg")
                
                # Check for stroke attributes in SVG (borders)
                stroke_count = svg_data.count('stroke=')
                print(f"   • Stroke attributes found: {stroke_count}")
                
                # Look for specific border patterns
                if 'stroke=' in svg_data:
                    # Extract some stroke examples
                    lines = svg_data.split('\n')
                    stroke_lines = [line.strip() for line in lines if 'stroke=' in line][:3]
                    print("   • Border examples:")
                    for line in stroke_lines:
                        print(f"     {line}")
                
            else:
                print(f"❌ Grid ON failed: {result.get('error')}")
        else:
            print(f"❌ Grid ON HTTP error: {response.status_code}")
    except Exception as e:
        print(f"❌ Grid ON exception: {e}")
    
    print()
    print("🔍 Check debug_grid_OFF.svg vs debug_grid_ON.svg")
    print("   If they look the same, the grid toggle isn't working!")

if __name__ == "__main__":
    test_grid_states()
