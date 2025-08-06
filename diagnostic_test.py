#!/usr/bin/env python3
"""
Debug script to verify the cloud service is working correctly
"""

import requests
import json
import time

def test_exact_problem():
    """Test the exact same request your app generates"""
    
    print("🔍 DIAGNOSING WHITE LINES ISSUE")
    print("=" * 50)
    
    url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
    
    # Test exactly what your Flutter app sends (from the logs)
    test_data = {
        "surface": {
            "panelsWidth": 3,
            "fullPanelsHeight": 2,
            "panelPixelWidth": 200,
            "panelPixelHeight": 200,
            "ledName": "Absen PL2.5 Lite"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,    # GRID ENABLED
            "showPanelNumbers": True
        }
    }
    
    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache'
    }
    
    try:
        print("📤 Testing with Grid=True (should show BRIGHTER borders)...")
        
        response = requests.post(url, json=test_data, headers=headers, timeout=30)
        
        if response.status_code == 200:
            response_data = response.json()
            if response_data.get('success'):
                if 'image_base64' in response_data:
                    import base64
                    image_data = base64.b64decode(response_data['image_base64'])
                    
                    timestamp = int(time.time())
                    filename = f'diagnostic_grid_on_{timestamp}.png'
                    
                    with open(filename, 'wb') as f:
                        f.write(image_data)
                    
                    print(f"✅ SUCCESS: Saved as {filename}")
                    print("🔍 If this shows WHITE LINES instead of BRIGHTER BORDERS,")
                    print("   then the cloud service has a problem.")
                    print("🔍 If this shows BRIGHTER BORDERS, then your Flutter app")
                    print("   has a caching or state issue.")
                    
                    return filename
        
        print(f"❌ FAILED: {response.status_code}")
        return None
        
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return None

def test_grid_off():
    """Test with grid disabled for comparison"""
    
    print("\n📤 Testing with Grid=False (should show NO borders)...")
    
    url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
    
    test_data = {
        "surface": {
            "panelsWidth": 3,
            "fullPanelsHeight": 2,
            "panelPixelWidth": 200,
            "panelPixelHeight": 200,
            "ledName": "Absen PL2.5 Lite"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": False,   # GRID DISABLED
            "showPanelNumbers": True
        }
    }
    
    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
    
    try:
        response = requests.post(url, json=test_data, headers=headers, timeout=30)
        
        if response.status_code == 200:
            response_data = response.json()
            if response_data.get('success'):
                if 'image_base64' in response_data:
                    import base64
                    image_data = base64.b64decode(response_data['image_base64'])
                    
                    timestamp = int(time.time())
                    filename = f'diagnostic_grid_off_{timestamp}.png'
                    
                    with open(filename, 'wb') as f:
                        f.write(image_data)
                    
                    print(f"✅ SUCCESS: Saved as {filename}")
                    return filename
        
        print(f"❌ FAILED: {response.status_code}")
        return None
        
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return None

if __name__ == "__main__":
    grid_on_file = test_exact_problem()
    grid_off_file = test_grid_off()
    
    if grid_on_file and grid_off_file:
        print(f"\n🎯 DIAGNOSTIC COMPLETE!")
        print(f"📋 Compare these files:")
        print(f"   • {grid_on_file} (Grid ON)")
        print(f"   • {grid_off_file} (Grid OFF)")
        print("\n🔍 Analysis:")
        print("   If grid_on shows BRIGHTER BORDERS → Cloud service works, Flutter app issue")
        print("   If grid_on shows WHITE LINES → Cloud service issue")
        print("   If both look the same → Grid toggle not working")
    else:
        print("\n❌ Diagnostic failed")
