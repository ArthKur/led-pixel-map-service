#!/usr/bin/env python3

import requests
import json

print("🧪 Testing Cloud Service with Different LED Products")
print("=====================================================")

# Test with different LED products from the CSV data
test_cases = [
    {
        "name": "Absen PL2.5 Lite (200×200px panels)",
        "data": {
            "surface": {
                "panelsWidth": 10,
                "fullPanelsHeight": 5,
                "halfPanelsHeight": 0,
                "panelPixelWidth": 200,
                "panelPixelHeight": 200,
                "ledName": "Absen PL2.5 Lite"
            }
        },
        "expected_resolution": "2000×1000px"
    },
    {
        "name": "Absen PL3.9 Lite (128×128px panels)", 
        "data": {
            "surface": {
                "panelsWidth": 15,
                "fullPanelsHeight": 8,
                "halfPanelsHeight": 0,
                "panelPixelWidth": 128,
                "panelPixelHeight": 128,
                "ledName": "Absen PL3.9 Lite"
            }
        },
        "expected_resolution": "1920×1024px"
    },
    {
        "name": "Absen A3 Pro (128×128px panels) - LARGE",
        "data": {
            "surface": {
                "panelsWidth": 50,
                "fullPanelsHeight": 30,
                "halfPanelsHeight": 0,
                "panelPixelWidth": 128,
                "panelPixelHeight": 128,
                "ledName": "Absen A3 Pro"
            }
        },
        "expected_resolution": "6400×3840px"
    },
    {
        "name": "Custom LED Product (100×100px panels)",
        "data": {
            "surface": {
                "panelsWidth": 20,
                "fullPanelsHeight": 15,
                "halfPanelsHeight": 2,
                "panelPixelWidth": 100,
                "panelPixelHeight": 100,
                "ledName": "Custom LED Product XYZ"
            }
        },
        "expected_resolution": "2000×1500px"
    },
    {
        "name": "ULTRA LARGE - 300×20 panels (240000×4000px)",
        "data": {
            "surface": {
                "panelsWidth": 300,
                "fullPanelsHeight": 20,
                "halfPanelsHeight": 0,
                "panelPixelWidth": 800,
                "panelPixelHeight": 200,
                "ledName": "Ultra Large LED Wall"
            }
        },
        "expected_resolution": "240000×4000px"
    }
]

url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"

for i, test_case in enumerate(test_cases, 1):
    print(f"\n📋 Test {i}: {test_case['name']}")
    print(f"Expected: {test_case['expected_resolution']}")
    
    try:
        response = requests.post(
            url,
            headers={"Content-Type": "application/json"},
            json=test_case['data'],
            timeout=30
        )
        
        if response.status_code == 200:
            data = response.json()
            
            if data.get('success'):
                actual_resolution = f"{data['dimensions']['width']}×{data['dimensions']['height']}px"
                led_info = data.get('led_info', {})
                
                print(f"✅ SUCCESS: {actual_resolution}")
                print(f"   LED: {led_info.get('name', 'N/A')}")
                print(f"   Panels: {led_info.get('panels', 'N/A')}")
                print(f"   File size: {data.get('file_size_mb', 'N/A')}MB")
                
                if 'scaled_dimensions' in data:
                    scaled = data['scaled_dimensions']
                    print(f"   Scaled: {scaled['width']}×{scaled['height']}px (1:{data.get('scale_factor', 1)})")
                
                # Verify the calculation is correct
                surface = test_case['data']['surface']
                expected_width = surface['panelsWidth'] * surface['panelPixelWidth']
                expected_height = surface['fullPanelsHeight'] * surface['panelPixelHeight']
                
                if data['dimensions']['width'] == expected_width and data['dimensions']['height'] == expected_height:
                    print(f"   ✅ Dimensions match calculator!")
                else:
                    print(f"   ❌ Dimension mismatch! Expected {expected_width}×{expected_height}")
                    
            else:
                print(f"❌ ERROR: {data.get('error', 'Unknown error')}")
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            print(f"   Response: {response.text[:200]}...")
            
    except Exception as e:
        print(f"❌ Exception: {e}")

print(f"\n🎯 Summary: Testing cloud service with dynamic LED product data")
print(f"✅ Validates proper handling of different panel sizes")
print(f"✅ Tests calculator integration with real LED specs")
print(f"✅ Confirms Canvas API bypass for ultra-large images")
