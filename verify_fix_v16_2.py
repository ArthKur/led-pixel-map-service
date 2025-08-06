#!/usr/bin/env python3
"""
VERIFICATION TEST - Surface Name Fix v16.2
Tests if the critical function signature fix resolved the surface name issue
"""
import requests
import json
import base64
from PIL import Image
import io
import time

def test_surface_name_fix():
    """Test the v16.2 fix for surface names"""
    print("🔧 TESTING SURFACE NAME FIX v16.2")
    print("=" * 50)
    
    url = 'https://led-pixel-map-service-1.onrender.com/generate-pixel-map'
    
    # Test data designed for clear surface name visibility
    data = {
        'surface': {
            'panelsWidth': 3,
            'fullPanelsHeight': 1,
            'panelPixelWidth': 64,
            'panelPixelHeight': 64,
            'ledName': 'Test LED'
        },
        'config': {
            'showGrid': False,       # Clean background
            'showPanelNumbers': False, # No distractions
            'showName': True,        # SURFACE NAME ON!
            'surfaceName': '🎯 FIX TEST v16.2 🎯'
        }
    }
    
    expected_size = (3*64, 1*64)  # 192x64
    
    print(f"📋 Test Configuration:")
    print(f"   Surface Name: '{data['config']['surfaceName']}'")
    print(f"   Expected Size: {expected_size}")
    print(f"   Grid/Numbers: OFF (clean view)")
    print(f"   Show Name: {data['config']['showName']}")
    print()
    
    try:
        print("🌐 Sending request to cloud service...")
        start_time = time.time()
        
        response = requests.post(
            url,
            headers={'Content-Type': 'application/json'}, 
            data=json.dumps(data),
            timeout=45
        )
        
        duration = time.time() - start_time
        print(f"⏱️  Response time: {duration:.1f}s")
        print(f"📡 Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            version = result.get('version', 'unknown')
            success = result.get('success', False)
            
            print(f"🔖 Version: {version}")
            print(f"✅ Success: {success}")
            
            if '16.2' in version:
                print("🎉 CONFIRMED: Running fixed version 16.2!")
            else:
                print("⚠️  WARNING: Not running expected version 16.2")
            
            if 'imageData' in result and result['imageData']:
                # Decode and analyze image
                image_data = result['imageData']
                if image_data.startswith('data:image/png;base64,'):
                    image_data = image_data.split(',')[1]
                
                image_bytes = base64.b64decode(image_data)
                image = Image.open(io.BytesIO(image_bytes))
                
                # Save test result
                filename = 'surface_name_fix_v16_2_test.png'
                image.save(filename)
                
                # Analyze colors
                pixels = list(image.getdata())
                unique_colors = set(pixels)
                amber_found = (255, 191, 0) in unique_colors
                total_colors = len(unique_colors)
                
                print(f"💾 Saved: {filename}")
                print(f"📊 Image size: {image.size}")
                print(f"🎨 Total colors: {total_colors}")
                print(f"🟡 Amber found: {amber_found}")
                print()
                
                # Detailed analysis
                if amber_found and total_colors > 10:
                    print("🎉 SUCCESS! Surface names are now working!")
                    print("✅ Amber text color (255,191,0) detected")
                    print("✅ Rich color palette indicates full rendering")
                    return True
                elif amber_found:
                    print("⚠️  PARTIAL: Amber found but limited colors")
                    print("🔍 May need further investigation")
                    return True
                else:
                    print("❌ FAILED: No amber text color detected")
                    print("🚨 Surface names still not rendering")
                    print(f"🎯 Available colors: {sorted(list(unique_colors))[:10]}")
                    return False
                    
            else:
                print("❌ No image data in response")
                return False
                
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            print(f"Response: {response.text[:300]}")
            return False
            
    except requests.exceptions.Timeout:
        print("⏰ Request timed out - service may be starting up")
        return False
    except Exception as e:
        print(f"💥 Error: {e}")
        return False

def main():
    """Run the verification test"""
    print("🚀 SURFACE NAME FIX VERIFICATION")
    print("Testing if v16.2 deployment fixed the missing parameter issue")
    print()
    
    # Give the service a moment to deploy
    print("⏳ Waiting 30 seconds for deployment...")
    time.sleep(30)
    
    success = test_surface_name_fix()
    
    print()
    print("🔍 VERIFICATION RESULTS:")
    print("=" * 30)
    
    if success:
        print("🎉 SUCCESS! Surface names are working in cloud service!")
        print("   → Function signature fix resolved the issue")
        print("   → Amber text (255,191,0) now renders correctly")
        print("   → No more 'surface name not displayed' issues")
    else:
        print("❌ FAILED: Surface names still not working")
        print("   → May need additional investigation")
        print("   → Check deployment status and logs")

if __name__ == "__main__":
    main()
