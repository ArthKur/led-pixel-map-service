#!/usr/bin/env python3
"""
Quick test to verify the Linux font fix
"""
import requests
import json
import time

def quick_version_check():
    """Check if the Linux font fix deployed"""
    try:
        response = requests.get('https://led-pixel-map-service-1.onrender.com/', timeout=10)
        if response.status_code == 200:
            data = response.json()
            version = data.get('version', 'unknown')
            print(f'🔖 Current version: {version}')
            
            if '17.1' in version:
                print('✅ Linux font fix deployed!')
                return True
            else:
                print('⏳ Still waiting for v17.1 deployment...')
                return False
        else:
            print(f'❌ HTTP {response.status_code}')
            return False
    except Exception as e:
        print(f'❌ Error: {e}')
        return False

def test_simple_surface_name():
    """Test with simple surface name (no emoji)"""
    data = {
        'surface': {
            'panelsWidth': 2,
            'fullPanelsHeight': 1,
            'panelPixelWidth': 64,
            'panelPixelHeight': 32,
            'ledName': 'Test'
        },
        'config': {
            'showGrid': False,
            'showPanelNumbers': False,
            'showName': True,
            'surfaceName': 'TEST SCREEN'  # Simple text, no emoji
        }
    }
    
    try:
        print('🧪 Testing simple surface name...')
        response = requests.post(
            'https://led-pixel-map-service-1.onrender.com/generate-pixel-map',
            headers={'Content-Type': 'application/json'}, 
            data=json.dumps(data),
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            if 'imageData' in result and result['imageData']:
                print('✅ Image generated successfully')
                return True
            else:
                print('❌ No image data')
                return False
        else:
            print(f'❌ HTTP {response.status_code}')
            return False
            
    except Exception as e:
        print(f'❌ Error: {e}')
        return False

if __name__ == "__main__":
    print("🔧 LINUX FONT FIX VERIFICATION")
    print("=" * 40)
    
    # Check version first
    print("1. Checking deployment status...")
    if quick_version_check():
        print("\n2. Testing surface name rendering...")
        if test_simple_surface_name():
            print("\n🎉 SUCCESS! Surface names should now work!")
            print("Try your test again with simple text first, then emoji.")
        else:
            print("\n❌ Still issues - may need further debugging")
    else:
        print("\n⏳ Waiting for deployment... try again in a few minutes")
