#!/usr/bin/env python3
"""Test consistent font scaling across different surface widths"""

import requests
import json
import base64
import os

def test_font_scaling():
    """Test font scaling consistency across different surface widths"""
    
    service_url = "https://led-pixel-map-service-1.onrender.com"
    desktop_path = os.path.join(os.path.expanduser("~"), "Desktop")
    
    # Test different surface widths (simulating 10m, 40m, and 100m wide LED walls)
    test_configurations = [
        {
            "name": "10m Wide Surface (20 panels)",
            "panels_width": 20,
            "panels_height": 6,
            "panel_width": 100,
            "panel_height": 100,
            "filename": "font_test_10m_wide.png"
        },
        {
            "name": "40m Wide Surface (80 panels)",
            "panels_width": 80, 
            "panels_height": 6,
            "panel_width": 100,
            "panel_height": 100,
            "filename": "font_test_40m_wide.png"
        },
        {
            "name": "100m Wide Surface (200 panels)",
            "panels_width": 200,
            "panels_height": 6,
            "panel_width": 100,
            "panel_height": 100,
            "filename": "font_test_100m_wide.png"
        }
    ]
    
    print(f"🧪 TESTING CONSISTENT FONT SCALING")
    print(f"=" * 60)
    print(f"🎯 Fixed 7% font scale - should be consistent across all sizes")
    print(f"📏 Reference: 40m wide surface (user's preferred size)")
    print(f"=" * 60)
    
    results = []
    
    for i, config in enumerate(test_configurations, 1):
        print(f"\n{i}. Testing {config['name']}")
        print(f"   📦 Panels: {config['panels_width']}×{config['panels_height']}")
        print(f"   📐 Panel size: {config['panel_width']}×{config['panel_height']}px")
        
        # Configuration for test
        test_data = {
            "surface": {
                "panelsWidth": config['panels_width'],
                "fullPanelsHeight": config['panels_height'],
                "halfPanelsHeight": 0,
                "panelPixelWidth": config['panel_width'],
                "panelPixelHeight": config['panel_height'],
                "ledName": f"Test {config['name']}"
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
    print(f"\n🎉 FONT SCALING TEST COMPLETE!")
    print(f"=" * 60)
    successful_tests = [r for r in results if r['success']]
    print(f"✅ Generated {len(successful_tests)}/{len(test_configurations)} test images")
    
    if successful_tests:
        print(f"\n📁 Saved to Desktop:")
        for result in successful_tests:
            print(f"   • {result['config']['filename']} - {result['config']['name']}")
        
        print(f"\n📏 Font Analysis:")
        print(f"   • All images use FIXED 7% font scale")
        print(f"   • Panel numbers should appear the SAME SIZE across all surfaces")
        print(f"   • Compare the 3 images to verify consistent numbering")
        print(f"   • Reference: 40m wide surface has your preferred font size")
        
        print(f"\n🔍 Visual Comparison:")
        print(f"   1. Open all 3 PNG files from your Desktop")
        print(f"   2. Zoom to same level on each image")
        print(f"   3. Check panel numbering - should be identical size")
        print(f"   4. Verify readability across all surface widths")
    
    return len(successful_tests) == len(test_configurations)

if __name__ == "__main__":
    success = test_font_scaling()
    
    if success:
        print(f"\n🏆 ALL TESTS PASSED! Check Desktop for comparison images.")
    else:
        print(f"\n⚠️  Some tests failed. Check individual results above.")
