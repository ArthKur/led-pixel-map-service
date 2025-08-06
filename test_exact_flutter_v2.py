#!/usr/bin/env python3
"""
Test the EXACT format your Flutter app uses to verify enhanced grid is working
"""

import requests
import json

def test_flutter_exact_format():
    """Test using the exact request that shows white lines in your app"""
    
    print("🔍 TESTING EXACT FLUTTER FORMAT - Should show BRIGHTER BORDERS")
    print("=" * 65)
    
    url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
    
    # EXACT format from your Flutter app logs
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
            "showGrid": True,
            "showPanelNumbers": True
        }
    }
    
    headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
    }
    
    try:
        print("📤 Sending EXACT Flutter request format...")
        print(f"Request: {json.dumps(test_data, indent=2)}")
        
        response = requests.post(url, json=test_data, headers=headers, timeout=30)
        
        print(f"📥 Response: {response.status_code}")
        
        if response.status_code == 200:
            response_data = response.json()
            if response_data.get('success'):
                print("✅ SUCCESS!")
                print(f"   Dimensions: {response_data.get('dimensions', {})}")
                
                if 'image_base64' in response_data:
                    import base64
                    image_data = base64.b64decode(response_data['image_base64'])
                    filename = 'flutter_exact_test_v2.png'
                    with open(filename, 'wb') as f:
                        f.write(image_data)
                    print(f"💾 Saved as: {filename}")
                    print("🎯 This should now show BRIGHTER BORDERS, not white lines!")
                    print("   • Red panels should have brighter red borders")
                    print("   • Grey panels should have brighter grey borders")
                    print("   • Borders should be 2-3 pixels thick")
                    print("   • NO WHITE LINES anywhere!")
                    return True
            else:
                print(f"❌ ERROR: {response_data.get('error', 'Unknown')}")
        else:
            print(f"❌ HTTP ERROR: {response.status_code}")
            print(f"Response: {response.text[:200]}")
        
        return False
        
    except Exception as e:
        print(f"❌ EXCEPTION: {str(e)}")
        return False

if __name__ == "__main__":
    success = test_flutter_exact_format()
    
    if success:
        print("\n🎉 TEST SUCCESSFUL!")
        print("📋 Check 'flutter_exact_test_v2.png'")
        print("🚀 If this shows brighter borders, your Flutter app should too!")
        print("   Try generating a new pixel map in your app now.")
    else:
        print("\n❌ Test failed - there may still be deployment issues")
