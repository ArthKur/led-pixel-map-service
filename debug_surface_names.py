#!/usr/bin/env python3
"""
Complete debug test for surface name issue
"""
import requests
import json
import time

def test_cloud_service_surface_name():
    """Test the cloud service with detailed debugging"""
    
    print("🔍 DEBUGGING SURFACE NAME ISSUE")
    print("=" * 50)
    
    # Test data
    test_data = {
        "surface": {
            "panelsWidth": 8,
            "fullPanelsHeight": 4,
            "panelPixelWidth": 64,
            "panelPixelHeight": 32
        },
        "config": {
            "showName": True,
            "surfaceName": "DEBUG TEST"
        }
    }
    
    print(f"📤 Sending request:")
    print(json.dumps(test_data, indent=2))
    print()
    
    try:
        # Make request to cloud service
        url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
        
        print(f"🌐 Calling: {url}")
        response = requests.post(url, json=test_data, timeout=60)
        
        print(f"📡 Response status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Success: {result.get('success', False)}")
            
            if 'imageUrl' in result:
                image_url = result['imageUrl']
                print(f"🖼️  Image URL: {image_url}")
                
                # Download and save the image for inspection
                img_response = requests.get(image_url)
                if img_response.status_code == 200:
                    with open("cloud_debug_test.png", "wb") as f:
                        f.write(img_response.content)
                    print(f"💾 Downloaded image: cloud_debug_test.png")
                    print(f"🔍 Check this image to see if surface name appears!")
                else:
                    print(f"❌ Failed to download image: {img_response.status_code}")
            else:
                print(f"❌ No image URL in response: {result}")
                
            # Print any logs or debug info
            if 'logs' in result:
                print(f"📝 Service logs:")
                for log in result['logs']:
                    print(f"   {log}")
                    
        else:
            print(f"❌ Error response: {response.status_code}")
            print(f"Response text: {response.text}")
            
    except Exception as e:
        print(f"❌ Request failed: {e}")

def test_local_service():
    """Test local service to compare"""
    print("\n" + "=" * 50)
    print("🏠 TESTING LOCAL SERVICE")
    
    try:
        import sys
        import os
        
        # Add current directory to path
        sys.path.insert(0, '/Users/arturkurowski/Desktop/PROJECT /led_calculator_2_0')
        
        from app import generate_pixel_map_optimized
        
        # Test with same parameters
        width = 8 * 64  # 512px
        height = 4 * 32  # 128px
        config = {
            'showName': True,
            'surfaceName': 'LOCAL DEBUG TEST'
        }
        
        print(f"📏 Canvas size: {width}x{height}px")
        print(f"🏷️  Surface name: '{config['surfaceName']}'")
        
        # Generate pixel map
        result = generate_pixel_map_optimized(
            width=width, 
            height=height, 
            pixel_pitch=1.0, 
            led_panel_width=64, 
            led_panel_height=32,
            canvas_scale=1.0,
            config=config
        )
        
        if result and 'filename' in result:
            print(f"✅ Local generation successful: {result['filename']}")
            print(f"🔍 Check local file to compare with cloud service!")
        else:
            print(f"❌ Local generation failed: {result}")
            
    except Exception as e:
        print(f"❌ Local test failed: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_cloud_service_surface_name()
    test_local_service()
