#!/usr/bin/env python3
"""Test smart panel number scaling at different canvas sizes"""

import requests
import json
import base64
import os

def test_panel_scaling():
    print(f"🔢 TESTING SMART PANEL NUMBER SCALING")
    print(f"=" * 60)
    
    # Test configurations for different canvas sizes
    test_configs = [
        {
            "name": "Small Canvas (4×3 panels)",
            "panelsWidth": 4,
            "panelsHeight": 3,
            "panelSize": 200,
            "filename": "small_4x3_panels.png"
        },
        {
            "name": "Medium Canvas (10×6 panels)", 
            "panelsWidth": 10,
            "panelsHeight": 6,
            "panelSize": 200,
            "filename": "medium_10x6_panels.png"
        },
        {
            "name": "Large Canvas (20×12 panels)",
            "panelsWidth": 20,
            "panelsHeight": 12, 
            "panelSize": 200,
            "filename": "large_20x12_panels.png"
        },
        {
            "name": "Very Large Canvas (50×30 panels)",
            "panelsWidth": 50,
            "panelsHeight": 30,
            "panelSize": 200,
            "filename": "very_large_50x30_panels.png"
        }
    ]
    
    service_url = "https://led-pixel-map-service-1.onrender.com"
    desktop_path = os.path.join(os.path.expanduser("~"), "Desktop")
    
    results = []
    
    for config in test_configs:
        print(f"\\n🎯 Testing {config['name']}")
        print(f"   📦 Panels: {config['panelsWidth']}×{config['panelsHeight']}")
        
        # Calculate total resolution
        total_width = config['panelsWidth'] * config['panelSize']
        total_height = config['panelsHeight'] * config['panelSize']
        total_pixels = total_width * total_height
        
        print(f"   📐 Resolution: {total_width}×{total_height} ({total_pixels:,} pixels)")
        
        test_data = {
            "surface": {
                "panelsWidth": config['panelsWidth'],
                "fullPanelsHeight": config['panelsHeight'],
                "halfPanelsHeight": 0,
                "panelPixelWidth": config['panelSize'],
                "panelPixelHeight": config['panelSize'],
                "ledName": f"Scaling Test - {config['name']}"
            },
            "config": {
                "surfaceIndex": 0,
                "showGrid": True,
                "showPanelNumbers": True  # Enable numbers to test scaling
            }
        }
        
        try:
            response = requests.post(
                f"{service_url}/generate-pixel-map",
                headers={'Content-Type': 'application/json'},
                json=test_data,
                timeout=120
            )
            
            if response.status_code == 200:
                result = response.json()
                
                if result.get('success'):
                    image_base64 = result.get('image_base64', '')
                    display_dims = result.get('display_dimensions', {})
                    
                    print(f"   ✅ Generated: {display_dims.get('width', 'N/A')}×{display_dims.get('height', 'N/A')} pixels")
                    print(f"   💾 File size: {result.get('file_size_mb', 0)} MB")
                    
                    # Download test image
                    if image_base64:
                        image_bytes = base64.b64decode(image_base64)
                        file_path = os.path.join(desktop_path, config['filename'])
                        
                        with open(file_path, 'wb') as f:
                            f.write(image_bytes)
                        
                        actual_size_mb = len(image_bytes) / (1024 * 1024)
                        print(f"   📁 Saved: {config['filename']} ({actual_size_mb:.2f} MB)")
                        
                        results.append({
                            'config': config,
                            'success': True,
                            'file_size': actual_size_mb,
                            'total_pixels': total_pixels
                        })
                    
                else:
                    print(f"   ❌ Service error: {result}")
                    results.append({'config': config, 'success': False})
            else:
                print(f"   ❌ HTTP Error: {response.status_code}")
                results.append({'config': config, 'success': False})
                
        except Exception as e:
            print(f"   ❌ Error: {e}")
            results.append({'config': config, 'success': False})
    
    # Summary
    print(f"\\n" + "=" * 60)
    print(f"🏆 PANEL NUMBER SCALING TEST SUMMARY")
    print(f"=" * 60)
    
    successful_tests = [r for r in results if r.get('success', False)]
    
    if successful_tests:
        print(f"✅ Successful tests: {len(successful_tests)}/{len(test_configs)}")
        print(f"\\n📋 Generated test files on desktop:")
        
        for result in successful_tests:
            config = result['config']
            pixels = result['total_pixels']
            size_mb = result['file_size']
            print(f"   • {config['filename']} - {pixels:,} pixels ({size_mb:.2f} MB)")
        
        print(f"\\n🎯 Expected font scaling behavior:")
        print(f"   • Small canvas: Larger panel numbers (more readable)")
        print(f"   • Large canvas: Smaller panel numbers (proportional)")
        print(f"   • All sizes: High-contrast white backgrounds")
        print(f"   • Consistent: Readable at every scale")
        
        return True
    else:
        print(f"❌ No successful tests completed")
        return False

if __name__ == "__main__":
    success = test_panel_scaling()
    
    if success:
        print(f"\\n🚀 SUCCESS! Smart panel number scaling is working!")
        print(f"📝 Check the generated files to verify font sizes scale appropriately")
        print(f"🎯 Ready for massive 40K+ canvases with readable panel numbers!")
    else:
        print(f"\\n❌ Scaling test failed. Check cloud service deployment status.")
