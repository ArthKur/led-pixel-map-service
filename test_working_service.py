#!/usr/bin/env python3
"""
Test the working service with enhanced grid
"""
import requests
import json
import base64
import subprocess

def test_enhanced_grid():
    print("🚀 TESTING ENHANCED GRID v13.0")
    print("=" * 50)
    
    url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
    
    # Test with grid ON
    data_with_grid = {
        "surface": {
            "panelsWidth": 2,
            "fullPanelsHeight": 2,
            "panelPixelWidth": 100,
            "panelPixelHeight": 100,
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
            "panelsWidth": 2,
            "fullPanelsHeight": 2,
            "panelPixelWidth": 100,
            "panelPixelHeight": 100,
            "ledName": "P2.5"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": False,
            "showPanelNumbers": False
        }
    }
    
    print("🔧 Testing Grid ON...")
    try:
        response = requests.post(url, json=data_with_grid, timeout=30)
        if response.status_code == 200:
            result = response.json()
            if result.get('success') and 'image_base64' in result:
                img_data = base64.b64decode(result['image_base64'])
                with open('grid_on_test_v13.png', 'wb') as f:
                    f.write(img_data)
                print("✅ Grid ON image saved as grid_on_test_v13.png")
            else:
                print(f"❌ Grid ON failed: {result.get('error', 'Unknown error')}")
        else:
            print(f"❌ Grid ON HTTP Error: {response.status_code}")
    except Exception as e:
        print(f"❌ Grid ON Exception: {e}")
    
    print("\n🔧 Testing Grid OFF...")
    try:
        response = requests.post(url, json=data_without_grid, timeout=30)
        if response.status_code == 200:
            result = response.json()
            if result.get('success') and 'image_base64' in result:
                img_data = base64.b64decode(result['image_base64'])
                with open('grid_off_test_v13.png', 'wb') as f:
                    f.write(img_data)
                print("✅ Grid OFF image saved as grid_off_test_v13.png")
            else:
                print(f"❌ Grid OFF failed: {result.get('error', 'Unknown error')}")
        else:
            print(f"❌ Grid OFF HTTP Error: {response.status_code}")
    except Exception as e:
        print(f"❌ Grid OFF Exception: {e}")
    
    print("\n🔍 Opening images for comparison...")
    subprocess.run(["open", "grid_on_test_v13.png", "grid_off_test_v13.png"])
    
    print("\n🎯 VERIFICATION CHECKLIST:")
    print("✓ Check grid_on_test_v13.png - should have BRIGHT COLORED borders")
    print("✓ Check grid_off_test_v13.png - should have NO borders")
    print("✓ Compare the difference - grid should be clearly visible")
    print("\n🚨 If grid is visible and COLORED (not white), your service is WORKING!")

if __name__ == "__main__":
    test_enhanced_grid()
