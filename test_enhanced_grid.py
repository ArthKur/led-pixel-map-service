#!/usr/bin/env python3
"""
Test the enhanced grid with thicker, brighter borders
"""

import requests
import json

def test_enhanced_grid():
    """Test the enhanced grid implementation"""
    
    print("🚀 TESTING ENHANCED GRID: Thicker + Brighter Borders")
    print("=" * 55)
    
    url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
    
    # Test with medium size for good visibility
    test_data = {
        "surface": {
            "panelsWidth": 4,
            "fullPanelsHeight": 3,
            "panelPixelWidth": 100,
            "panelPixelHeight": 100,
            "ledName": "Absen"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,  # ENHANCED GRID
            "showPanelNumbers": True
        }
    }
    
    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
    
    try:
        print("📤 Sending request for ENHANCED GRID test...")
        print("   Features: 50% brighter + 2-3px thick borders")
        print("   Size: 4x3 panels of 100x100px = 400x300px total")
        
        response = requests.post(url, json=test_data, headers=headers, timeout=30)
        
        if response.status_code == 200:
            response_data = response.json()
            if response_data.get('success'):
                print("✅ ENHANCED GRID SUCCESS!")
                
                if 'image_base64' in response_data:
                    import base64
                    image_data = base64.b64decode(response_data['image_base64'])
                    filename = 'enhanced_grid_test.png'
                    with open(filename, 'wb') as f:
                        f.write(image_data)
                    print(f"💾 Saved as: {filename}")
                    print("🎯 This should have MUCH MORE VISIBLE borders!")
                    print("   • 50% brighter colors (vs 30% before)")
                    print("   • 2-3 pixel thick borders (vs 1px before)")
                    print("   • Should be clearly visible even at high zoom levels")
                    return True
        
        print(f"❌ FAILED: {response.status_code}")
        return False
        
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return False

def test_enhanced_grid_large():
    """Test with larger panels like those in your app"""
    
    print("\n🚀 TESTING ENHANCED GRID: Large Panels (like your app)")
    print("=" * 55)
    
    url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
    
    # Test with larger panels similar to your app
    test_data = {
        "surface": {
            "panelsWidth": 8,
            "fullPanelsHeight": 4,
            "panelPixelWidth": 200,
            "panelPixelHeight": 200,
            "ledName": "Absen"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,  # ENHANCED GRID
            "showPanelNumbers": True
        }
    }
    
    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
    
    try:
        print("📤 Sending request for large panel test...")
        print("   Size: 8x4 panels of 200x200px = 1600x800px total")
        
        response = requests.post(url, json=test_data, headers=headers, timeout=30)
        
        if response.status_code == 200:
            response_data = response.json()
            if response_data.get('success'):
                print("✅ LARGE PANEL SUCCESS!")
                
                if 'image_base64' in response_data:
                    import base64
                    image_data = base64.b64decode(response_data['image_base64'])
                    filename = 'enhanced_grid_large_test.png'
                    with open(filename, 'wb') as f:
                        f.write(image_data)
                    print(f"💾 Saved as: {filename}")
                    print("🎯 Even at this larger size, borders should be clearly visible!")
                    return True
        
        print(f"❌ FAILED: {response.status_code}")
        return False
        
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return False

if __name__ == "__main__":
    success1 = test_enhanced_grid()
    success2 = test_enhanced_grid_large()
    
    if success1 and success2:
        print("\n🎉 ENHANCED GRID TESTS SUCCESSFUL!")
        print("📋 Check these images:")
        print("   • enhanced_grid_test.png (400x300px)")
        print("   • enhanced_grid_large_test.png (1600x800px)")
        print("\n🎯 The borders should now be MUCH MORE VISIBLE!")
        print("   • 50% brighter than panel colors")
        print("   • 2-3 pixels thick (adaptive based on panel size)")
        print("   • Should be clearly visible even when zoomed out")
        print("\n🚀 Try your Flutter app now - the grid should be much more obvious!")
    else:
        print("\n❌ Some tests failed")
