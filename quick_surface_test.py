#!/usr/bin/env python3
import requests
import json

def quick_test():
    """Quick test with minimal timeout"""
    print("🚀 Quick Surface Name Test")
    
    url = 'https://led-pixel-map-service-1.onrender.com/generate-pixel-map'
    
    # Minimal test data
    data = {
        'surface': {
            'panelsWidth': 2,
            'fullPanelsHeight': 1,
            'panelPixelWidth': 32,
            'panelPixelHeight': 32,
            'ledName': 'Test LED'
        },
        'config': {
            'showGrid': False,
            'showPanelNumbers': False,
            'showName': True,
            'surfaceName': 'TEST'
        }
    }
    
    print(f"📊 Expected canvas: {2*32}x{1*32} = 64x32 pixels")
    print(f"📝 Surface name: '{data['config']['surfaceName']}'")
    print(f"🎛️  Show name: {data['config']['showName']}")
    
    try:
        print("🌐 Sending request...")
        response = requests.post(
            url,
            headers={'Content-Type': 'application/json'}, 
            data=json.dumps(data),
            timeout=15  # 15 second timeout
        )
        
        print(f"📡 Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            success = result.get('success', False)
            has_image = 'imageData' in result
            print(f"✅ Success: {success}")
            print(f"🖼️  Has image: {has_image}")
            
            if has_image:
                image_data = result['imageData']
                data_size = len(image_data)
                print(f"📦 Image data size: {data_size} chars")
                
                if data_size > 1000:
                    print("🎉 SUCCESS! Image data received")
                    return True
                else:
                    print("⚠️  Image data too small")
            else:
                print("❌ No image data in response")
        else:
            print(f"❌ HTTP {response.status_code}")
            print(f"Response: {response.text[:200]}")
            
    except requests.exceptions.Timeout:
        print("⏰ Request timed out (15 seconds)")
    except Exception as e:
        print(f"💥 Error: {e}")
    
    return False

if __name__ == "__main__":
    success = quick_test()
    if success:
        print("\n✅ Quick test passed - service is working!")
    else:
        print("\n❌ Quick test failed - service issue detected")
