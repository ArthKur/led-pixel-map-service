#!/usr/bin/env python3
"""
Test the cloud service using Flutter app's request format
"""

import requests
import json
import time

def test_flutter_format():
    """Test using the exact format that Flutter app sends"""
    
    print("📱 Testing Cloud Service with Flutter App Format")
    print("=" * 50)
    
    url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
    
    # EXACT format that Flutter app uses (from cloud_pixel_map_service.dart)
    test_data = {
        "surface": {
            "panelsWidth": 3,
            "fullPanelsHeight": 2,
            "panelPixelWidth": 100,
            "panelPixelHeight": 100,
            "ledName": "Absen"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,  # ENABLE GRID
            "showPanelNumbers": True
        }
    }
    
    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
    
    try:
        print("📤 Sending request with Flutter format (grid=True)...")
        print(f"Request data: {json.dumps(test_data, indent=2)}")
        
        response = requests.post(url, json=test_data, headers=headers, timeout=60)
        
        print(f"📥 Response status: {response.status_code}")
        
        if response.status_code == 200:
            response_data = response.json()
            
            if response_data.get('success'):
                print("✅ SUCCESS: Flutter format works!")
                print(f"   Dimensions: {response_data.get('dimensions', {})}")
                print(f"   File size: {response_data.get('file_size_mb', 'Unknown')}MB")
                print(f"   LED info: {response_data.get('led_info', {})}")
                
                # Save the image if we have image data
                if 'image_base64' in response_data:
                    import base64
                    image_data = base64.b64decode(response_data['image_base64'])
                    with open('flutter_format_grid_test.png', 'wb') as f:
                        f.write(image_data)
                    print("   💾 Image saved as 'flutter_format_grid_test.png'")
                    print("   🔍 Check if brighter borders are visible!")
                    return True
                else:
                    print("   ⚠️ No image data in response")
                    return False
            else:
                print(f"❌ FAILED: {response_data.get('error', 'Unknown error')}")
                return False
        else:
            print(f"❌ FAILED: HTTP {response.status_code}")
            try:
                print(f"Response: {response.text}")
            except:
                print("Could not read response text")
            return False
            
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return False

def test_flutter_format_no_grid():
    """Test without grid for comparison"""
    
    print("\n📱 Testing Flutter Format WITHOUT Grid")
    print("=" * 50)
    
    url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
    
    # Same format but with grid disabled
    test_data = {
        "surface": {
            "panelsWidth": 3,
            "fullPanelsHeight": 2,
            "panelPixelWidth": 100,
            "panelPixelHeight": 100,
            "ledName": "Absen"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": False,  # DISABLE GRID
            "showPanelNumbers": True
        }
    }
    
    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
    
    try:
        print("📤 Sending request with Flutter format (grid=False)...")
        
        response = requests.post(url, json=test_data, headers=headers, timeout=60)
        
        print(f"📥 Response status: {response.status_code}")
        
        if response.status_code == 200:
            response_data = response.json()
            
            if response_data.get('success'):
                print("✅ SUCCESS: Flutter format without grid works!")
                
                # Save the image if we have image data
                if 'image_base64' in response_data:
                    import base64
                    image_data = base64.b64decode(response_data['image_base64'])
                    with open('flutter_format_no_grid_test.png', 'wb') as f:
                        f.write(image_data)
                    print("   💾 Image saved as 'flutter_format_no_grid_test.png'")
                    return True
                else:
                    print("   ⚠️ No image data in response")
                    return False
            else:
                print(f"❌ FAILED: {response_data.get('error', 'Unknown error')}")
                return False
        else:
            print(f"❌ FAILED: HTTP {response.status_code}")
            try:
                print(f"Response: {response.text}")
            except:
                print("Could not read response text")
            return False
            
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return False

if __name__ == "__main__":
    success1 = test_flutter_format()
    success2 = test_flutter_format_no_grid()
    
    if success1 and success2:
        print("\n🎉 FLUTTER FORMAT TESTS SUCCESSFUL!")
        print("📋 Compare the two images:")
        print("   • flutter_format_grid_test.png (WITH brighter borders)")
        print("   • flutter_format_no_grid_test.png (WITHOUT borders)")
        print("   • The grid image should show 30% brighter borders around each panel")
        print("\n🔧 Your Flutter app should now work with the brighter grid!")
    else:
        print("\n⚠️  Some tests failed - check the output above")
