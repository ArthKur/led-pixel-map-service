#!/usr/bin/env python3
"""
Debug the grid issue by testing step by step
"""

import requests
import json
import time

def debug_grid_issue():
    """Debug why grid is still showing white lines"""
    
    print("🔍 DEBUGGING GRID ISSUE")
    print("=" * 40)
    
    url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
    
    # Test 1: Simple format that we know works
    print("\n📝 TEST 1: Simple format (known working)")
    test_data_simple = {
        "width": 2,
        "height": 2, 
        "ledPanelWidth": 100,
        "ledPanelHeight": 100,
        "ledName": "Absen",
        "showPanelNumbers": True,
        "showGrid": True
    }
    
    test_request(url, test_data_simple, "simple_grid_debug.png")
    
    # Test 2: Flutter format that should work
    print("\n📝 TEST 2: Flutter format (what your app sends)")
    test_data_flutter = {
        "surface": {
            "panelsWidth": 2,
            "fullPanelsHeight": 2,
            "panelPixelWidth": 100,
            "panelPixelHeight": 100,
            "ledName": "Absen"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,
            "showPanelNumbers": True
        }
    }
    
    test_request(url, test_data_flutter, "flutter_grid_debug.png")
    
    # Test 3: Flutter format without grid
    print("\n📝 TEST 3: Flutter format without grid")
    test_data_flutter_no_grid = {
        "surface": {
            "panelsWidth": 2,
            "fullPanelsHeight": 2,
            "panelPixelWidth": 100,
            "panelPixelHeight": 100,
            "ledName": "Absen"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": False,
            "showPanelNumbers": True
        }
    }
    
    test_request(url, test_data_flutter_no_grid, "flutter_no_grid_debug.png")

def test_request(url, data, filename):
    """Test a single request"""
    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
    
    try:
        print(f"📤 Sending: {json.dumps(data, indent=2)}")
        
        response = requests.post(url, json=data, headers=headers, timeout=30)
        print(f"📥 Response: {response.status_code}")
        
        if response.status_code == 200:
            try:
                response_data = response.json()
                if response_data.get('success'):
                    print(f"✅ SUCCESS: {filename}")
                    if 'image_base64' in response_data:
                        import base64
                        image_data = base64.b64decode(response_data['image_base64'])
                        with open(filename, 'wb') as f:
                            f.write(image_data)
                        print(f"   💾 Saved as {filename}")
                    return True
                else:
                    print(f"❌ ERROR: {response_data.get('error', 'Unknown')}")
            except json.JSONDecodeError as e:
                print(f"❌ JSON DECODE ERROR: {str(e)}")
                print(f"   Raw response: {response.text[:200]}")
        else:
            print(f"❌ HTTP ERROR: {response.status_code}")
            print(f"   Response: {response.text[:200]}")
    except Exception as e:
        print(f"❌ EXCEPTION: {str(e)}")
    
    return False

if __name__ == "__main__":
    debug_grid_issue()
