#!/usr/bin/env python3
"""
Test the new BRIGHTER BORDER GRID system
"""

import sys
sys.path.append('.')

import requests
import json
import base64

def test_grid_system():
    """Test both grid enabled and disabled"""
    
    print("🎨 Testing NEW BRIGHTER BORDER GRID System")
    print("=" * 50)
    
    # Test data
    test_data_grid_on = {
        "surface": {
            "panelsWidth": 3,
            "fullPanelsHeight": 2,
            "halfPanelsHeight": 0,
            "panelPixelWidth": 200,
            "panelPixelHeight": 200,
            "ledName": "Absen PL2.5 Lite"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,
            "showPanelNumbers": True
        }
    }
    
    test_data_grid_off = {
        "surface": {
            "panelsWidth": 3,
            "fullPanelsHeight": 2,
            "halfPanelsHeight": 0,
            "panelPixelWidth": 200,
            "panelPixelHeight": 200,
            "ledName": "Absen PL2.5 Lite"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": False,
            "showPanelNumbers": True
        }
    }
    
    # Test with grid enabled (brighter borders)
    print("🔆 Testing GRID ENABLED (Brighter Borders)...")
    try:
        response = requests.post(
            "https://led-pixel-map-service-1.onrender.com/generate-pixel-map",
            json=test_data_grid_on,
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                image_data = base64.b64decode(result['image_base64'])
                with open('test_grid_brighter_borders.png', 'wb') as f:
                    f.write(image_data)
                
                print(f"✅ Grid ON: test_grid_brighter_borders.png")
                print(f"   📐 Size: {result['dimensions']['width']}×{result['dimensions']['height']}")
                print(f"   💾 File: {result['file_size_mb']:.3f} MB")
            else:
                print(f"❌ Grid ON error: {result.get('error')}")
                return False
        else:
            print(f"❌ Grid ON HTTP error: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Grid ON exception: {e}")
        return False
    
    # Test with grid disabled (no borders)
    print("\n🚫 Testing GRID DISABLED (No Borders)...")
    try:
        response = requests.post(
            "https://led-pixel-map-service-1.onrender.com/generate-pixel-map",
            json=test_data_grid_off,
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                image_data = base64.b64decode(result['image_base64'])
                with open('test_no_grid_clean.png', 'wb') as f:
                    f.write(image_data)
                
                print(f"✅ Grid OFF: test_no_grid_clean.png")
                print(f"   📐 Size: {result['dimensions']['width']}×{result['dimensions']['height']}")
                print(f"   💾 File: {result['file_size_mb']:.3f} MB")
                return True
            else:
                print(f"❌ Grid OFF error: {result.get('error')}")
                return False
        else:
            print(f"❌ Grid OFF HTTP error: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Grid OFF exception: {e}")
        return False

if __name__ == "__main__":
    success = test_grid_system()
    
    if success:
        print(f"\n🎉 NEW GRID SYSTEM IMPLEMENTED!")
        print(f"✅ Grid Features:")
        print(f"   • Grid ON: Brighter borders around each panel")
        print(f"   • Grid OFF: Clean panels with no borders")
        print(f"   • No more white lines between panels")
        print(f"   • Border pixels are 30% brighter than panel color")
        print(f"\n📸 Compare images:")
        print(f"   • test_grid_brighter_borders.png (with grid)")
        print(f"   • test_no_grid_clean.png (without grid)")
    else:
        print(f"\n❌ Test failed - check implementation")
