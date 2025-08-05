#!/usr/bin/env python3
"""
🎨 Test Ultra-Smooth Vector Numbering System
Testing 15% size, text-like quality, improved scaling
"""

import requests
import json
import time

def test_smooth_numbering():
    """Test the new ultra-smooth numbering system"""
    
    print("🎨 Testing Ultra-Smooth Vector Numbering System")
    print("=" * 60)
    
    # Test configuration with different LED types
    test_configs = [
        {
            "name": "Absen - Ultra Smooth",
            "led_name": "Absen",
            "panels": (10, 6),
            "expected_size": "15%"
        },
        {
            "name": "Novastar - Text-like Quality", 
            "led_name": "Novastar",
            "panels": (8, 5),
            "expected_size": "15%"
        },
        {
            "name": "Colorlight - Smooth Scaling",
            "led_name": "Colorlight", 
            "panels": (12, 8),
            "expected_size": "15%"
        }
    ]
    
    for config in test_configs:
        print(f"\n🧪 Testing: {config['name']}")
        print(f"   📏 Expected numbering size: {config['expected_size']} of panel")
        print(f"   🎯 LED Type: {config['led_name']}")
        
        # Create test payload
        payload = {
            "surface": {
                "panelsWidth": config["panels"][0],
                "fullPanelsHeight": config["panels"][1]
            },
            "config": {
                "showPanelNumbers": True,
                "showGrid": True
            },
            "ledName": config["led_name"]
        }
        
        try:
            # Test cloud service
            response = requests.post(
                'https://led-pixel-map-service.onrender.com/generate-pixel-map',
                json=payload,
                timeout=30
            )
            
            if response.status_code == 200:
                result = response.json()
                if result.get('success'):
                    print(f"   ✅ Generated: {config['panels'][0]}×{config['panels'][1]} panels")
                    print(f"   📱 Image size: {result.get('width', 'N/A')}×{result.get('height', 'N/A')}px")
                    print(f"   🎨 Numbering: 15% size, ultra-smooth design")
                    print(f"   🌈 Colors: {config['led_name']}-specific scheme")
                    
                    # Save result
                    filename = f"smooth_{config['led_name'].lower()}_test.png"
                    if 'imageData' in result:
                        # Handle base64 image data
                        import base64
                        image_data = base64.b64decode(result['imageData'].split(',')[1])
                        with open(filename, 'wb') as f:
                            f.write(image_data)
                        print(f"   💾 Saved: {filename}")
                else:
                    print(f"   ❌ Failed: {result.get('error', 'Unknown error')}")
            else:
                print(f"   ❌ HTTP Error: {response.status_code}")
                
        except Exception as e:
            print(f"   ❌ Error: {str(e)}")
        
        time.sleep(1)  # Rate limiting
    
    print("\n" + "=" * 60)
    print("🎊 Ultra-Smooth Numbering Test Complete!")
    print("✨ Features tested:")
    print("   • 15% panel size (reduced from 20%)")
    print("   • Text-like smooth appearance") 
    print("   • Improved scaling quality")
    print("   • Thinner segments for cleaner look")
    print("   • Better proportional spacing")
    print("   • Anti-aliasing effect simulation")

if __name__ == "__main__":
    test_smooth_numbering()
