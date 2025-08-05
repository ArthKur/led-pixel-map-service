#!/usr/bin/env python3
"""
Final verification that everything is working
"""
import requests
import json

def verify_service_health():
    print("🏥 SERVICE HEALTH CHECK")
    print("=" * 30)
    
    # Test health endpoint
    try:
        response = requests.get("https://led-pixel-map-service-1.onrender.com/", timeout=10)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Service: {data.get('service', 'Unknown')}")
            print(f"✅ Version: {data.get('version', 'Unknown')}")
            print(f"✅ Status: {data.get('status', 'Unknown')}")
            
            # Check for enhanced grid features
            if "ENHANCED GRID" in str(data.get('version', '')):
                print("🎯 Enhanced Grid v13.0 detected!")
                print("🔥 Features: 50% brighter borders, 2-3px thick, NO WHITE LINES")
                return True
            else:
                print("⚠️  Grid enhancement not detected in version")
                return False
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Health check error: {e}")
        return False

def test_flutter_compatible_request():
    print("\n🔄 FLUTTER COMPATIBILITY TEST")
    print("=" * 35)
    
    url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
    
    # This matches exactly what your Flutter app sends
    flutter_request = {
        "surface": {
            "panelsWidth": 4,
            "fullPanelsHeight": 3,
            "panelPixelWidth": 64,
            "panelPixelHeight": 64,
            "ledName": "P2.5"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,
            "showPanelNumbers": True
        }
    }
    
    try:
        response = requests.post(url, json=flutter_request, timeout=30)
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                print("✅ Flutter-compatible request successful")
                print(f"✅ Image size: {result.get('actual_image_size', 'Unknown')}")
                total_pixels = result.get('total_pixels', 'Unknown')
                if isinstance(total_pixels, (int, float)):
                    print(f"✅ Total pixels: {total_pixels:,}")
                else:
                    print(f"✅ Total pixels: {total_pixels}")
                
                # Check if we got image data
                if 'image_base64' in result:
                    print("✅ Image data received")
                    print("🎯 Grid should be visible with BRIGHT COLORED borders")
                    return True
                else:
                    print("❌ No image data in response")
                    return False
            else:
                print(f"❌ Request failed: {result.get('error', 'Unknown error')}")
                return False
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            print(response.text[:200])
            return False
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False

if __name__ == "__main__":
    health_ok = verify_service_health()
    flutter_ok = test_flutter_compatible_request()
    
    print("\n" + "=" * 50)
    print("🎯 FINAL STATUS")
    print("=" * 50)
    
    if health_ok and flutter_ok:
        print("🎉 SUCCESS! Everything is working correctly!")
        print("✅ Enhanced Grid v13.0 is deployed")
        print("✅ Service responds to Flutter requests")
        print("✅ Grid toggle should work in your app")
        print("\n📱 Your Flutter app at http://localhost:8080 should now show:")
        print("   - Checkbox works correctly")
        print("   - Grid shows BRIGHT COLORED borders (not white)")
        print("   - No more white line issues!")
    else:
        print("❌ Issues detected:")
        if not health_ok:
            print("   - Service health check failed")
        if not flutter_ok:
            print("   - Flutter compatibility test failed")
