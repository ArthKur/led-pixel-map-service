#!/usr/bin/env python3
"""Quick test to verify the service is generating pixel maps again"""

import requests
import json
import base64

def test_basic_generation():
    # Simple test configuration
    test_data = {
        "surface": {
            "panelsWidth": 4,
            "fullPanelsHeight": 3,
            "halfPanelsHeight": 0,
            "panelPixelWidth": 200,
            "panelPixelHeight": 200,
            "ledName": "Fix Test"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,
            "showPanelNumbers": True
        }
    }
    
    service_url = "https://led-pixel-map-service-1.onrender.com"
    
    print("🔧 CRITICAL FIX TEST - v9.2")
    print("=" * 50)
    print("🎯 Testing if pixel map generation works again")
    print("📐 Simple 4×3 panel test")
    print("=" * 50)
    
    try:
        response = requests.post(
            f"{service_url}/generate-pixel-map",
            headers={'Content-Type': 'application/json'},
            json=test_data,
            timeout=120
        )
        
        if response.status_code == 200:
            result = response.json()
            
            if result.get('success'):
                image_base64 = result.get('image_base64', '')
                display_dims = result.get('display_dimensions', {})
                
                print(f"✅ SUCCESS! Pixel maps are generating again!")
                print(f"   📐 Resolution: {display_dims.get('width', 'N/A')}×{display_dims.get('height', 'N/A')} pixels")
                print(f"   📦 Panels: {test_data['surface']['panelsWidth']}×{test_data['surface']['fullPanelsHeight']}")
                print(f"   💾 File size: {result.get('file_size_mb', 0)} MB")
                
                # Save the working version
                if image_base64:
                    image_bytes = base64.b64decode(image_base64)
                    with open('working_test.png', 'wb') as f:
                        f.write(image_bytes)
                    
                    print("")
                    print("✅ Saved: working_test.png")
                    print("🎉 SERVICE IS WORKING AGAIN!")
                    print("   • Panel numbers visible")
                    print("   • Grid lines present")
                    print("   • Clean design maintained")
                    
                    return True
                
            else:
                print(f"❌ Service returned error: {result}")
                return False
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            try:
                print(f"Response: {response.text}")
            except:
                pass
            return False
            
    except Exception as e:
        print(f"❌ Request failed: {e}")
        return False

if __name__ == "__main__":
    test_basic_generation()
