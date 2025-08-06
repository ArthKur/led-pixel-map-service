#!/usr/bin/env python3
"""
Test script to verify visual overlays are working
"""
import requests
import json
import base64
from PIL import Image
import io

def test_visual_overlays():
    """Test that visual overlays are working correctly"""
    print("🧪 Testing Visual Overlays...")
    
    # Test data - small image for quick testing
    test_data = {
        "surface": {
            "panelsWidth": 4,
            "fullPanelsHeight": 3,
            "panelPixelWidth": 64,
            "panelPixelHeight": 64,
            "ledName": "Test Visual Overlays"
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
        # Make request to local service
        response = requests.post(
            'http://localhost:5001/generate-pixel-map',
            headers={'Content-Type': 'application/json'},
            json=test_data,
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                print("✅ Request successful!")
                print(f"📏 Image size: {result['dimensions']['width']}×{result['dimensions']['height']}px")
                print(f"💾 File size: {result['file_size_mb']}MB")
                
                # Decode and save the image
                image_data = result.get('imageData', '').replace('data:image/png;base64,', '')
                if image_data:
                    image_bytes = base64.b64decode(image_data)
                    img = Image.open(io.BytesIO(image_bytes))
                    img.save('test_visual_overlays_output.png')
                    print("💾 Saved test image as: test_visual_overlays_output.png")
                    print("🎨 Open the image to verify visual overlays are present!")
                else:
                    print("❌ No image data received")
            else:
                print(f"❌ Request failed: {result.get('error', 'Unknown error')}")
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            print(f"Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Error testing visual overlays: {e}")

if __name__ == "__main__":
    test_visual_overlays()
