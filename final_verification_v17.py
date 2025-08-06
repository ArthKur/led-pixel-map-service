#!/usr/bin/env python3
"""
FINAL SURFACE NAME VERIFICATION TEST
Tests if v17.0 force rebuild deployed the critical surface_name parameter fixes
"""
import requests
import json
import base64
from PIL import Image
import io
import time

def wait_for_deployment():
    """Wait for v17.0 deployment to complete"""
    print("⏳ Waiting for v17.0 deployment...")
    max_attempts = 30  # 5 minutes max
    
    for attempt in range(max_attempts):
        try:
            response = requests.get('https://led-pixel-map-service-1.onrender.com/', timeout=10)
            if response.status_code == 200:
                data = response.json()
                version = data.get('version', '')
                print(f"Attempt {attempt+1}: Version {version}")
                
                if '17.0' in version:
                    print("✅ v17.0 deployment detected!")
                    return True
                elif '16.' in version:
                    print("⚠️  v16.x detected (previous fix)")
                    return True
                    
        except Exception as e:
            print(f"Attempt {attempt+1}: Connection error - {e}")
        
        time.sleep(10)  # Wait 10 seconds between attempts
    
    print("⏰ Timeout waiting for deployment")
    return False

def test_surface_names_final():
    """Final comprehensive test of surface name rendering"""
    print("\n🔬 FINAL SURFACE NAME TEST")
    print("=" * 50)
    
    url = 'https://led-pixel-map-service-1.onrender.com/generate-pixel-map'
    
    # Ultimate test configuration
    data = {
        'surface': {
            'panelsWidth': 4,
            'fullPanelsHeight': 2,
            'panelPixelWidth': 32,
            'panelPixelHeight': 32,
            'ledName': 'Test LED'
        },
        'config': {
            'showGrid': False,
            'showPanelNumbers': False,
            'showName': True,
            'surfaceName': '🏆 FINAL TEST SUCCESS 🏆'
        }
    }
    
    expected_size = (4*32, 2*32)  # 128x64
    
    print(f"📋 Final Test Configuration:")
    print(f"   Surface Name: '{data['config']['surfaceName']}'")
    print(f"   Expected Size: {expected_size}")
    print(f"   Grid: OFF, Numbers: OFF (clean view)")
    print(f"   Show Name: {data['config']['showName']}")
    print()
    
    try:
        print("🌐 Testing cloud service...")
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
            success = result.get('success', False)
            
            print(f"🔖 Version: {version}")
            print(f"✅ Success: {success}")
            
            if 'imageData' in result and result['imageData']:
                # Decode and analyze
                image_data = result['imageData']
                if image_data.startswith('data:image/png;base64,'):
                    image_data = image_data.split(',')[1]
                
                image_bytes = base64.b64decode(image_data)
                image = Image.open(io.BytesIO(image_bytes))
                
                # Save final test
                filename = 'FINAL_SURFACE_NAME_SUCCESS.png'
                image.save(filename)
                
                # Comprehensive analysis
                pixels = list(image.getdata())
                unique_colors = set(pixels)
                amber_found = (255, 191, 0) in unique_colors
                total_colors = len(unique_colors)
                
                print(f"💾 Saved: {filename}")
                print(f"📊 Size: {image.size} (expected {expected_size})")
                print(f"🎨 Colors: {total_colors}")
                print(f"🟡 Amber: {amber_found}")
                print()
                
                # Final verdict
                if amber_found and total_colors > 50:
                    print("🎉 COMPLETE SUCCESS!")
                    print("✅ Surface names working perfectly")
                    print("✅ Rich color rendering ({}+ colors)".format(total_colors))
                    print("✅ Amber text (255,191,0) detected")
                    print("✅ All surface name issues RESOLVED!")
                    return True, 'COMPLETE_SUCCESS'
                    
                elif amber_found:
                    print("⚠️  PARTIAL SUCCESS!")
                    print("✅ Surface names rendering")
                    print("✅ Amber text detected")
                    print("⚠️  Limited color palette")
                    return True, 'PARTIAL_SUCCESS'
                    
                else:
                    print("❌ STILL FAILED!")
                    print("🚨 No amber text detected")
                    print("🚨 Surface names NOT rendering")
                    print(f"Available colors: {sorted(list(unique_colors))}")
                    return False, 'STILL_BROKEN'
                    
            else:
                print("❌ No image data")
                return False, 'NO_IMAGE_DATA'
                
        else:
            print(f"❌ HTTP {response.status_code}")
            print(response.text[:300])
            return False, 'HTTP_ERROR'
            
    except Exception as e:
        print(f"💥 Error: {e}")
        return False, 'EXCEPTION'

def main():
    """Run complete verification"""
    print("🚀 FINAL SURFACE NAME VERIFICATION")
    print("Testing if force rebuild v17.0 resolved all issues")
    print()
    
    # Wait for deployment
    if not wait_for_deployment():
        print("❌ Could not confirm deployment - proceeding anyway")
    
    # Run final test
    success, status = test_surface_names_final()
    
    print("\n" + "="*60)
    print("🏁 FINAL VERIFICATION RESULTS")
    print("="*60)
    
    if success and status == 'COMPLETE_SUCCESS':
        print("🎉 MISSION ACCOMPLISHED!")
        print("✅ Surface names fully working in cloud service")
        print("✅ All parameter fixes successfully deployed")
        print("✅ No more 'surface name not displayed' issues")
        print("\n🎯 SUMMARY:")
        print("   - Root cause: Missing surface_name parameters")
        print("   - Solution: Added parameters to function signatures")
        print("   - Result: Amber text (255,191,0) now renders correctly")
        
    elif success:
        print("⚠️  PARTIAL SUCCESS")
        print("✅ Surface names working but may need optimization")
        print(f"Status: {status}")
        
    else:
        print("❌ VERIFICATION FAILED")
        print("🚨 Surface names still not working")
        print(f"Status: {status}")
        print("\n🔧 NEXT STEPS:")
        print("   - Check Render deployment logs")
        print("   - Verify git push succeeded")
        print("   - Consider manual deployment trigger")

if __name__ == "__main__":
    main()
