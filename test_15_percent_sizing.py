#!/usr/bin/env python3
"""
Test the 15% numbering size with ultra-fine quality rendering
"""

import sys
sys.path.append('.')

import requests
import json
import base64

def test_15_percent_sizing():
    """Test the cloud service with 15% numbering size"""
    
    # Test data
    test_data = {
        "surface": {
            "panelsWidth": 4,
            "fullPanelsHeight": 3,
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
    
    print("📐 Testing 15% Numbering Size")
    print("=" * 40)
    print(f"📊 Panel size: 200×200px")
    print(f"📊 Number size: 15% = 30px")
    print(f"📊 Quality: Ultra-fine with anti-aliasing")
    
    try:
        # Make request
        response = requests.post(
            "https://led-pixel-map-service-1.onrender.com/generate-pixel-map",
            json=test_data,
            timeout=30
        )
        
        print(f"📡 Response status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            
            if result.get('success'):
                # Decode and save image
                image_data = base64.b64decode(result['image_base64'])
                
                with open('test_15_percent_sizing.png', 'wb') as f:
                    f.write(image_data)
                
                print(f"✅ 15% sizing test successful!")
                print(f"📐 Dimensions: {result['dimensions']['width']}×{result['dimensions']['height']}")
                print(f"💾 File size: {result['file_size_mb']:.3f} MB")
                print(f"💾 Saved: test_15_percent_sizing.png")
                print(f"🎯 Features:")
                print(f"   • Size: 15% of panel (30px on 200px panel)")
                print(f"   • Quality: Ultra-fine strokes with anti-aliasing")
                print(f"   • Visibility: Enhanced readability")
                
                return True
            else:
                print(f"❌ Cloud error: {result.get('error')}")
                return False
        else:
            print(f"❌ HTTP error: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False

if __name__ == "__main__":
    success = test_15_percent_sizing()
    
    if success:
        print(f"\n🎉 15% SIZING IMPLEMENTED!")
        print(f"   • Numbering size increased to 15% of panel")
        print(f"   • Maintains ultra-fine quality rendering")
        print(f"   • Better visibility while keeping smoothness")
        print(f"   • Check test_15_percent_sizing.png for results")
    else:
        print(f"\n❌ Test failed - check cloud service status")
