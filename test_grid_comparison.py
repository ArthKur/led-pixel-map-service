#!/usr/bin/env python3
"""
Test grid functionality - compare grid on vs off
"""
import requests
import json
import base64
from PIL import Image
import io

def test_grid_functionality():
    """Test grid on/off to verify functionality"""
    print("🔄 Testing Grid Functionality...")
    
    # Test data
    base_data = {
        "surface": {
            "panelsWidth": 3,
            "fullPanelsHeight": 2,
            "panelPixelWidth": 64,
            "panelPixelHeight": 64,
            "ledName": "Grid Test"
        },
        "config": {
            "surfaceIndex": 0,
            "showPanelNumbers": True,
            "showName": False,
            "showCross": False,
            "showCircle": False,
            "showLogo": False
        }
    }
    
    # Test 1: Grid OFF
    print("📴 Testing Grid OFF...")
    test_data_off = base_data.copy()
    test_data_off["config"]["showGrid"] = False
    
    try:
        response = requests.post(
            'https://led-pixel-map-service-1.onrender.com/generate-pixel-map',
            headers={'Content-Type': 'application/json'},
            json=test_data_off,
            timeout=60
        )
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                image_data = result.get('imageData', '').replace('data:image/png;base64,', '')
                if image_data:
                    image_bytes = base64.b64decode(image_data)
                    img = Image.open(io.BytesIO(image_bytes))
                    img.save('test_grid_OFF.png')
                    print("✅ Grid OFF test saved: test_grid_OFF.png")
        
    except Exception as e:
        print(f"❌ Grid OFF test failed: {e}")
    
    # Test 2: Grid ON
    print("📶 Testing Grid ON...")
    test_data_on = base_data.copy()
    test_data_on["config"]["showGrid"] = True
    
    try:
        response = requests.post(
            'https://led-pixel-map-service-1.onrender.com/generate-pixel-map',
            headers={'Content-Type': 'application/json'},
            json=test_data_on,
            timeout=60
        )
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                image_data = result.get('imageData', '').replace('data:image/png;base64,', '')
                if image_data:
                    image_bytes = base64.b64decode(image_data)
                    img = Image.open(io.BytesIO(image_bytes))
                    img.save('test_grid_ON.png')
                    print("✅ Grid ON test saved: test_grid_ON.png")
        
    except Exception as e:
        print(f"❌ Grid ON test failed: {e}")
    
    print("\n🔍 COMPARISON:")
    print("- Open test_grid_OFF.png - should show solid panel colors, no borders")
    print("- Open test_grid_ON.png - should show brighter colored borders around panels")
    print("- If both look the same with white borders, there's a deployment issue")

if __name__ == "__main__":
    test_grid_functionality()
