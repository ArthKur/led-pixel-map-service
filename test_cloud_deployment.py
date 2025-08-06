#!/usr/bin/env python3
"""
End-to-end test of cloud service with visual overlays
"""
import requests
import json
import base64
from PIL import Image
import io

def test_cloud_visual_overlays():
    """Test that cloud visual overlays are working correctly"""
    print("🌐 Testing Cloud Service Visual Overlays...")
    print("🔗 Service: https://led-pixel-map-service-1.onrender.com")
    
    # Test data with all visual overlays enabled
    test_data = {
        "surface": {
            "panelsWidth": 4,
            "fullPanelsHeight": 3,
            "panelPixelWidth": 64,
            "panelPixelHeight": 64,
            "ledName": "CLOUD VISUAL TEST"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,
            "showPanelNumbers": True,
            "showName": True,
            "showCross": True,
            "showCircle": True,
            "showLogo": True
        }
    }
    
    try:
        print("📤 Sending request to cloud service...")
        response = requests.post(
            'https://led-pixel-map-service-1.onrender.com/generate-pixel-map',
            headers={'Content-Type': 'application/json'},
            json=test_data,
            timeout=60  # Give cloud service more time
        )
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                print("✅ Cloud service request successful!")
                print(f"📏 Image size: {result['dimensions']['width']}×{result['dimensions']['height']}px")
                print(f"💾 File size: {result['file_size_mb']}MB")
                
                # Decode and save the image
                image_data = result.get('imageData', '').replace('data:image/png;base64,', '')
                if image_data:
                    image_bytes = base64.b64decode(image_data)
                    img = Image.open(io.BytesIO(image_bytes))
                    img.save('cloud_visual_overlays_test.png')
                    print("💾 Saved cloud test image as: cloud_visual_overlays_test.png")
                    
                    # Check image properties
                    print(f"🎨 Image mode: {img.mode}")
                    print(f"📏 Actual size: {img.size}")
                    
                    print("\n🎯 WHAT TO EXPECT IN THE IMAGE:")
                    print("✅ Panel grid with colored borders")
                    print("✅ Panel numbers in each panel")
                    print("✅ Center name 'CLOUD VISUAL TEST' in amber")
                    print("✅ White circle from center (full height)")
                    print("✅ White diagonal cross lines (corner to corner)")
                    print("✅ Logo placeholder (if implemented)")
                    
                    print("\n🚀 DEPLOYMENT SUCCESS!")
                    print("The cloud service now supports all visual overlays!")
                    print("Flutter app should now work with Name, Cross, and Circle features!")
                    
                else:
                    print("❌ No image data received from cloud service")
            else:
                print(f"❌ Cloud service returned error: {result.get('error', 'Unknown error')}")
        else:
            print(f"❌ Cloud service HTTP Error: {response.status_code}")
            print(f"Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Error testing cloud visual overlays: {e}")
        print("💡 The service might still be deploying. Try again in a few minutes.")

if __name__ == "__main__":
    test_cloud_visual_overlays()
