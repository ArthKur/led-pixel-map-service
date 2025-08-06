#!/usr/bin/env python3
"""
Test the FIXED local service with proper border spacing
"""
import requests
import json
import base64
import subprocess

def test_fixed_grid():
    print("🔧 TESTING FIXED GRID SPACING")
    print("=" * 40)
    
    url = "http://localhost:5001/generate-pixel-map"
    
    # Test with grid ON - should now show borders properly
    data_with_grid = {
        "surface": {
            "panelsWidth": 4,
            "fullPanelsHeight": 3,
            "panelPixelWidth": 64,
            "panelPixelHeight": 64,
            "ledName": "P2.5"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,
            "showPanelNumbers": False
        }
    }
    
    # Test with grid OFF
    data_without_grid = {
        "surface": {
            "panelsWidth": 4,
            "fullPanelsHeight": 3,
            "panelPixelWidth": 64,
            "panelPixelHeight": 64,
            "ledName": "P2.5"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": False,
            "showPanelNumbers": False
        }
    }
    
    print("🔧 Testing FIXED Grid ON...")
    try:
        response = requests.post(url, json=data_with_grid, timeout=30)
        if response.status_code == 200:
            result = response.json()
            if result.get('success') and 'image_base64' in result:
                img_data = base64.b64decode(result['image_base64'])
                with open('fixed_grid_on.png', 'wb') as f:
                    f.write(img_data)
                print("✅ FIXED Grid ON saved as fixed_grid_on.png")
            else:
                print(f"❌ Grid ON failed: {result.get('error', 'Unknown error')}")
                return False
        else:
            print(f"❌ Grid ON HTTP Error: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Grid ON Exception: {e}")
        return False
    
    print("\n🔧 Testing FIXED Grid OFF...")
    try:
        response = requests.post(url, json=data_without_grid, timeout=30)
        if response.status_code == 200:
            result = response.json()
            if result.get('success') and 'image_base64' in result:
                img_data = base64.b64decode(result['image_base64'])
                with open('fixed_grid_off.png', 'wb') as f:
                    f.write(img_data)
                print("✅ FIXED Grid OFF saved as fixed_grid_off.png")
            else:
                print(f"❌ Grid OFF failed: {result.get('error', 'Unknown error')}")
                return False
        else:
            print(f"❌ Grid OFF HTTP Error: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Grid OFF Exception: {e}")
        return False
    
    print("\n🔍 Opening FIXED images...")
    subprocess.run(["open", "fixed_grid_on.png", "fixed_grid_off.png"])
    
    print("\n🎯 THE FIX:")
    print("✓ Panels now drawn SMALLER (with border space reserved)")
    print("✓ Grid borders drawn in BRIGHT RED (not white)")  
    print("✓ Border width 2-3px thick")
    print("✓ Panels can't overwrite border space anymore!")
    print("\n🚨 Check fixed_grid_on.png - should show BRIGHT RED borders!")
    
    return True

if __name__ == "__main__":
    test_fixed_grid()
