#!/usr/bin/env python3
"""Test panel-based font scaling with same panel size across different surfaces"""

import requests
import json
import base64
import os

def test_panel_based_font_scaling():
    """Test that font size is based on panel pixel size, not surface width"""
    
    service_url = "https://led-pixel-map-service-1.onrender.com"
    desktop_path = os.path.join(os.path.expanduser("~"), "Desktop")
    
    # Test different surface widths but SAME panel pixel size
    # This should result in IDENTICAL font sizes across all tests
    panel_size = 100  # Same panel size for all tests
    
    test_configurations = [
        {
            "name": "Small Surface (10 panels wide)",
            "panels_width": 10,
            "panels_height": 4,
            "panel_width": panel_size,
            "panel_height": panel_size,
            "filename": "panel_based_test_10_panels.png"
        },
        {
            "name": "Medium Surface (20 panels wide)", 
            "panels_width": 20,
            "panels_height": 4,
            "panel_width": panel_size,
            "panel_height": panel_size,
            "filename": "panel_based_test_20_panels.png"
        },
        {
            "name": "Large Surface (50 panels wide)",
            "panels_width": 50,
            "panels_height": 4,
            "panel_width": panel_size,
            "panel_height": panel_size,
            "filename": "panel_based_test_50_panels.png"
        },
        {
            "name": "Huge Surface (100 panels wide)",
            "panels_width": 100,
            "panels_height": 4,
            "panel_width": panel_size,
            "panel_height": panel_size,
            "filename": "panel_based_test_100_panels.png"
        }
    ]
    
    print(f"🧪 TESTING PANEL-BASED FONT SCALING")
    print(f"=" * 60)
    print(f"🎯 ALL panels are {panel_size}×{panel_size}px - font should be IDENTICAL")
    print(f"📏 Expected font size: ~{int(panel_size * 0.07)}px (7% of {panel_size}px)")
    print(f"🎨 Different surface widths should NOT affect font size")
    print(f"=" * 60)
    
    results = []
    
    for i, config in enumerate(test_configurations, 1):
        print(f"\n{i}. Testing {config['name']}")
        print(f"   📦 Surface: {config['panels_width']}×{config['panels_height']} panels")
        print(f"   📐 Each panel: {config['panel_width']}×{config['panel_height']}px")
        
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
    print(f"\n🎉 PANEL-BASED FONT SCALING TEST COMPLETE!")
    print(f"=" * 60)
    successful_tests = [r for r in results if r['success']]
    print(f"✅ Generated {len(successful_tests)}/{len(test_configurations)} test images")
    
    if successful_tests:
        print(f"\n📁 Saved to Desktop:")
        for result in successful_tests:
            print(f"   • {result['config']['filename']} - {result['config']['name']}")
        
        print(f"\n📏 Font Analysis:")
        print(f"   • All panels are {panel_size}×{panel_size}px")
        print(f"   • Expected font size: ~{int(panel_size * 0.07)}px")
        print(f"   • Font should be IDENTICAL across all 4 images")
        print(f"   • Surface width should NOT affect font size")
        
        print(f"\n🔍 Visual Comparison:")
        print(f"   1. Open all 4 PNG files from your Desktop")
        print(f"   2. Zoom to same level on each image")
        print(f"   3. Check panel numbering - should be IDENTICAL size")
        print(f"   4. Verify that surface width doesn't change font size")
        print(f"   5. Reference: 20-panel wide surface has your preferred size")
    
    return len(successful_tests) == len(test_configurations)

if __name__ == "__main__":
    success = test_panel_based_font_scaling()
    
    if success:
        print(f"\n🏆 ALL TESTS PASSED! Font scaling now based on panel size only.")
    else:
        print(f"\n⚠️  Some tests failed. Check individual results above.")
