import requests
import json
import base64
from PIL import Image
import io

def test_surface_name_visibility():
    """
    Final test to verify surface name is actually visible in generated images
    """
    print("🔬 FINAL SURFACE NAME VISIBILITY TEST")
    print("=" * 50)
    
    url = 'https://led-pixel-map-service-1.onrender.com/generate-pixel-map'
    
    # Test with clean layout for maximum visibility
    data = {
        'surface': {
            'panelsWidth': 4,
            'fullPanelsHeight': 2,
            'panelPixelWidth': 64,
            'panelPixelHeight': 32,
            'ledName': 'Test LED'
        },
        'config': {
            'showGrid': False,  # No grid to see text clearly
            'showPanelNumbers': False,  # No numbers to see text clearly
            'showName': True,  # SURFACE NAME ENABLED
            'surfaceName': 'TEST SCREEN'  # Simple text first - no emoji
        }
    }
    
    print(f"📋 Test Configuration:")
    print(f"   Surface Name: '{data['config']['surfaceName']}'")
    print(f"   Show Name: {data['config']['showName']}")
    print(f"   Grid: {data['config']['showGrid']} (OFF for clarity)")
    print(f"   Numbers: {data['config']['showPanelNumbers']} (OFF for clarity)")
    print(f"   Expected canvas: 256x64 pixels")
    print()
    
    try:
        print("🌐 Sending request to cloud service...")
        response = requests.post(url, headers={'Content-Type': 'application/json'}, 
                               data=json.dumps(data), timeout=60)
        
        print(f"📡 Response Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Generation Success: {result.get('success')}")
            
            if 'imageData' in result and result['imageData']:
                # Extract and decode image
                image_data = result['imageData']
                if image_data.startswith('data:image/png;base64,'):
                    image_data = image_data.split(',')[1]
                
                # Decode and save
                image_bytes = base64.b64decode(image_data)
                image = Image.open(io.BytesIO(image_bytes))
                
                # Save with timestamp
                filename = 'FINAL_SURFACE_NAME_TEST.png'
                image.save(filename)
                
                print(f"📁 Image saved: {filename}")
                print(f"📊 Actual size: {image.size}")
                print(f"🎨 Image mode: {image.mode}")
                print()
                print("🔍 VERIFICATION INSTRUCTIONS:")
                print(f"   1. Open the file: {filename}")
                print("   2. Look for amber-colored text in the center")
                print("   3. Text should read: 'TEST SCREEN'")
                print("   4. Text should be roughly 30% of canvas height")
                print()
                
                if image.size == (256, 64):
                    print("✅ Canvas size is correct")
                else:
                    print(f"⚠️  Canvas size unexpected: got {image.size}, expected (256, 64)")
                    
                return True
                
            else:
                print("❌ No image data in response")
                return False
                
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            print(f"   Response: {response.text[:200]}")
            return False
            
    except Exception as e:
        print(f"❌ Request failed: {str(e)}")
        return False

if __name__ == "__main__":
    success = test_surface_name_visibility()
    if success:
        print("\n🎉 Test completed - check the generated image file!")
    else:
        print("\n💥 Test failed - surface name issue persists")
