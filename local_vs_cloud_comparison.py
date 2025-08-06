#!/usr/bin/env python3
"""
Local vs Cloud Surface Name Comparison Test
Tests the exact same request against both local and cloud services
"""
import requests
import json
import base64
from PIL import Image
import io
import time

def test_request_data():
    """The exact same request data for both local and cloud"""
    return {
        'surface': {
            'panelsWidth': 2,
            'fullPanelsHeight': 1,
            'panelPixelWidth': 64,
            'panelPixelHeight': 32,
            'ledName': 'Test LED'
        },
        'config': {
            'showGrid': False,
            'showPanelNumbers': False,
            'showName': True,
            'surfaceName': 'COMPARISON TEST'
        }
    }

def test_cloud_service():
    """Test cloud service"""
    print("🌐 TESTING CLOUD SERVICE")
    print("=" * 40)
    
    url = 'https://led-pixel-map-service-1.onrender.com/generate-pixel-map'
    data = test_request_data()
    
    print(f"📋 Request: {data['config']['surfaceName']}")
    print(f"🎯 Expected size: 128x32 pixels")
    
    try:
        print("⏰ Sending request (60s timeout)...")
        start_time = time.time()
        
        response = requests.post(
            url,
            headers={'Content-Type': 'application/json'}, 
            data=json.dumps(data),
            timeout=60
        )
        
        duration = time.time() - start_time
        print(f"⏱️  Response time: {duration:.1f}s")
        print(f"📡 Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            version = result.get('version', 'unknown')
            print(f"🔖 Version: {version}")
            
            if 'imageData' in result and result['imageData']:
                # Decode image
                image_data = result['imageData']
                if image_data.startswith('data:image/png;base64,'):
                    image_data = image_data.split(',')[1]
                
                image_bytes = base64.b64decode(image_data)
                image = Image.open(io.BytesIO(image_bytes))
                
                # Save cloud result
                cloud_file = 'comparison_CLOUD.png'
                image.save(cloud_file)
                
                # Analyze colors
                pixels = list(image.getdata())
                unique_colors = set(pixels)
                amber_found = (255, 191, 0) in unique_colors
                
                print(f"💾 Saved: {cloud_file}")
                print(f"📊 Size: {image.size}")
                print(f"🎨 Colors: {len(unique_colors)}")
                print(f"🟡 Amber found: {amber_found}")
                
                return amber_found, cloud_file
            else:
                print("❌ No image data returned")
                return False, None
        else:
            print(f"❌ HTTP {response.status_code}")
            print(f"Response: {response.text[:200]}")
            return False, None
            
    except requests.exceptions.Timeout:
        print("⏰ Request timed out")
        return False, None
    except Exception as e:
        print(f"💥 Error: {e}")
        return False, None

def test_local_service():
    """Test local service by importing and calling directly"""
    print("🏠 TESTING LOCAL SERVICE")
    print("=" * 40)
    
    try:
        import sys
        sys.path.append('.')
        from app import generate_pixel_map_surface
        
        data = test_request_data()
        surface = data['surface']
        config = data['config']
        
        print(f"📋 Request: {config['surfaceName']}")
        print(f"🎯 Expected size: 128x32 pixels")
        
        # Call local function directly
        result = generate_pixel_map_surface(
            panels_width=surface['panelsWidth'],
            panels_height=surface['fullPanelsHeight'],
            panel_pixel_width=surface['panelPixelWidth'],
            panel_pixel_height=surface['panelPixelHeight'],
            led_name=surface['ledName'],
            surface_name=config['surfaceName'],
            show_grid=config['showGrid'],
            show_panel_numbers=config['showPanelNumbers'],
            show_name=config['showName'],
            show_cross=False,
            show_circle=False,
            show_logo=False
        )
        
        if result:
            # Save local result
            local_file = 'comparison_LOCAL.png'
            result.save(local_file)
            
            # Analyze colors
            pixels = list(result.getdata())
            unique_colors = set(pixels)
            amber_found = (255, 191, 0) in unique_colors
            
            print(f"💾 Saved: {local_file}")
            print(f"📊 Size: {result.size}")
            print(f"🎨 Colors: {len(unique_colors)}")
            print(f"🟡 Amber found: {amber_found}")
            
            return amber_found, local_file
        else:
            print("❌ Local generation failed")
            return False, None
            
    except Exception as e:
        print(f"💥 Error: {e}")
        return False, None

def main():
    """Run comparison test"""
    print("🔬 LOCAL vs CLOUD SURFACE NAME COMPARISON")
    print("=" * 50)
    print()
    
    # Test local first (faster)
    local_amber, local_file = test_local_service()
    print()
    
    # Test cloud service (slower)
    cloud_amber, cloud_file = test_cloud_service()
    print()
    
    # Compare results
    print("🔍 COMPARISON RESULTS")
    print("=" * 30)
    print(f"🏠 Local amber text:  {'✅ YES' if local_amber else '❌ NO'}")
    print(f"🌐 Cloud amber text:  {'✅ YES' if cloud_amber else '❌ NO'}")
    print()
    
    if local_amber and cloud_amber:
        print("🎉 SUCCESS! Both local and cloud show surface names!")
    elif local_amber and not cloud_amber:
        print("🚨 ISSUE CONFIRMED: Local works, cloud doesn't show surface names")
        print("   → Cloud service deployment or environment issue")
    elif not local_amber and cloud_amber:
        print("🤔 UNEXPECTED: Cloud works but local doesn't")
    else:
        print("💥 BOTH FAILED: Surface name rendering broken everywhere")
    
    if local_file and cloud_file:
        print(f"📁 Compare these files:")
        print(f"   Local:  {local_file}")
        print(f"   Cloud:  {cloud_file}")

if __name__ == "__main__":
    main()
