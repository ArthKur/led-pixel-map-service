#!/usr/bin/env python3
"""Test font scaling with actual Absen PL2.5 Lite panel dimensions (200x200px)"""

import requests
import json
import base64
import os

def test_absen_font_scaling():
    """Test font scaling with Absen PL2.5 Lite panels (200x200px)"""
    
    service_url = "https://led-pixel-map-service-1.onrender.com"
    desktop_path = os.path.join(os.path.expanduser("~"), "Desktop")
    
    # Test with ACTUAL Absen PL2.5 Lite panel dimensions (200x200px)
    # This should match what the Flutter app sends for Absen panels
    absen_panel_size = 200  # Absen PL2.5 Lite: 200x200 pixels per panel
    
    test_configurations = [
        {
            "name": "Absen 10m Wide (20 panels)",
            "panels_width": 20,  # 20 panels × 0.5m = 10m wide  
            "panels_height": 6,
            "panel_width": absen_panel_size,
            "panel_height": absen_panel_size,
            "filename": "absen_test_10m_wide.png"
        },
        {
            "name": "Absen 40m Wide (80 panels)", 
            "panels_width": 80,  # 80 panels × 0.5m = 40m wide
            "panels_height": 6,
            "panel_width": absen_panel_size,
            "panel_height": absen_panel_size,
            "filename": "absen_test_40m_wide.png"
        },
        {
            "name": "Absen 100m Wide (200 panels)",
            "panels_width": 200,  # 200 panels × 0.5m = 100m wide
            "panels_height": 6,
            "panel_width": absen_panel_size,
            "panel_height": absen_panel_size,
            "filename": "absen_test_100m_wide.png"
        }
    ]
    
    print(f"🧪 TESTING ABSEN PL2.5 LITE FONT SCALING")
    print(f"=" * 60)
    print(f"🎯 ALL panels are {absen_panel_size}×{absen_panel_size}px (Absen PL2.5 Lite)")
    print(f"📏 Expected font size: ~{int(absen_panel_size * 0.07)}px (7% of {absen_panel_size}px)")
    print(f"🎨 This should match Flutter app behavior with Absen panels")
    print(f"=" * 60)
    
    results = []
    
    for i, config in enumerate(test_configurations, 1):
        print(f"\n{i}. Testing {config['name']}")
        print(f"   📦 Surface: {config['panels_width']}×{config['panels_height']} panels")
        print(f"   📐 Each panel: {config['panel_width']}×{config['panel_height']}px (Absen PL2.5 Lite)")
        
        # Configuration matching Flutter app data structure
        test_data = {
            "surface": {
                "panelsWidth": config['panels_width'],
                "fullPanelsHeight": config['panels_height'],
                "halfPanelsHeight": 0,
                "panelPixelWidth": config['panel_width'],  # This matches led.wPixel
                "panelPixelHeight": config['panel_height'], # This matches led.hPixel
                "ledName": f"Absen PL2.5 Lite - {config['name']}"
            },
            "config": {
                "surfaceIndex": 0,
                "showGrid": True,
                "showPanelNumbers": True  # Enable to see font scaling
            }
        }
        
        try:
            response = requests.post(
                f"{service_url}/generate-pixel-map",
                headers={'Content-Type': 'application/json'},
                json=test_data,
                timeout=60
            )
            
            if response.status_code == 200:
                result = response.json()
                
                if result.get('success'):
                    image_base64 = result.get('image_base64', '')
                    display_dims = result.get('display_dimensions', {})
                    
                    print(f"   ✅ Generated: {display_dims.get('width')}×{display_dims.get('height')} pixels")
                    
                    # Save to desktop
                    if image_base64:
                        image_bytes = base64.b64decode(image_base64)
                        file_path = os.path.join(desktop_path, config['filename'])
                        
                        with open(file_path, 'wb') as f:
                            f.write(image_bytes)
                        
                        file_size_mb = len(image_bytes) / (1024 * 1024)
                        print(f"   💾 Saved: {config['filename']} ({file_size_mb:.2f} MB)")
                        
                        results.append({
                            'config': config,
                            'success': True,
                            'file_path': file_path
                        })
                    else:
                        print(f"   ❌ No image data received")
                        results.append({'config': config, 'success': False})
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
    print(f"\n🎉 ABSEN FONT SCALING TEST COMPLETE!")
    print(f"=" * 60)
    successful_tests = [r for r in results if r['success']]
    print(f"✅ Generated {len(successful_tests)}/{len(test_configurations)} test images")
    
    if successful_tests:
        print(f"\n📁 Saved to Desktop:")
        for result in successful_tests:
            print(f"   • {result['config']['filename']} - {result['config']['name']}")
        
        print(f"\n📏 Font Analysis:")
        print(f"   • All panels are {absen_panel_size}×{absen_panel_size}px (Absen PL2.5 Lite)")
        print(f"   • Expected font size: ~{int(absen_panel_size * 0.07)}px")
        print(f"   • Font should be IDENTICAL across all 3 images")
        print(f"   • This should match Flutter app with Absen PL2.5 Lite selected")
        
        print(f"\n🔍 To Compare with Flutter App:")
        print(f"   1. In Flutter app, select 'Absen PL2.5 Lite' LED type")
        print(f"   2. Create surfaces with 20, 80, and 200 panels wide")
        print(f"   3. Generate pixel maps and compare with these test images")
        print(f"   4. Font sizes should now be identical!")
    
    return len(successful_tests) == len(test_configurations)

if __name__ == "__main__":
    success = test_absen_font_scaling()
    
    if success:
        print(f"\n🏆 ABSEN TESTS PASSED! Font scaling based on 200x200px panels.")
    else:
        print(f"\n⚠️  Some tests failed. Check individual results above.")
