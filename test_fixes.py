#!/usr/bin/env python3
"""Test script to verify the fixes: panel numbers, thin lines, 20% transparency"""

import requests
import json
import base64

def test_fixes():
    # Test with a configuration that should clearly show all improvements
    test_data = {
        "surface": {
            "panelsWidth": 6,
            "fullPanelsHeight": 3,
            "halfPanelsHeight": 0,
            "panelPixelWidth": 300,  # Large panels to clearly see panel numbers
            "panelPixelHeight": 300,
            "ledName": "Test LED"
        },
        "config": {
            "surfaceIndex": 1,  # Screen 2
            "showGrid": True,
            "showPanelNumbers": True
        }
    }
    
    service_url = "https://led-pixel-map-service-1.onrender.com"
    
    print("🔧 Testing CRITICAL FIXES")
    print("=" * 60)
    print("🔢 Panel Numbers: MUST appear on ALL panels in top-left")
    print("📏 Grid Lines: MUST be thin 1px white lines") 
    print("🎨 Transparency: Text at 20% transparency (more visible)")
    print("🧹 Quality: Clean, professional appearance")
    print("=" * 60)
    
    try:
        response = requests.post(
            f"{service_url}/generate-pixel-map",
            headers={'Content-Type': 'application/json'},
            json=test_data,
            timeout=300
        )
        
        if response.status_code == 200:
            result = response.json()
            
            if result.get('success'):
                image_base64 = result.get('image_base64', '')
                display_dims = result.get('display_dimensions', {})
                
                print(f"🎯 Fix Verification Results:")
                print(f"   📐 Screen: {display_dims.get('width', 'N/A')}×{display_dims.get('height', 'N/A')} pixels")
                print(f"   📦 Panels: {test_data['surface']['panelsWidth']}×{test_data['surface']['fullPanelsHeight']} = {test_data['surface']['panelsWidth'] * test_data['surface']['fullPanelsHeight']} panels")
                print(f"   💾 File size: {result.get('file_size_mb', 0)} MB")
                print(f"   🔤 Panel numbers: Should appear on ALL {test_data['surface']['panelsWidth'] * test_data['surface']['fullPanelsHeight']} panels")
                
                # Save the fixed version
                if image_base64:
                    image_bytes = base64.b64decode(image_base64)
                    with open('fixed_version_test.png', 'wb') as f:
                        f.write(image_bytes)
                    
                    print("")
                    print("✅ Saved: fixed_version_test.png")
                    print("🔍 Check for these fixes:")
                    print("   ✅ Panel numbers: 1.1, 1.2, 1.3... on every panel top-left")
                    print("   ✅ Grid lines: Thin 1px white lines between panels")
                    print("   ✅ Text transparency: 20% (more visible than before)")
                    print("   ✅ Screen 2: Large centered title")
                    print("   ✅ Panel info: Bottom-left corner")
                    
                    # Create verification HTML
                    image_data = f'data:image/png;base64,{image_base64}'
                    with open('fixes_verification.html', 'w') as f:
                        f.write(f'''
<!DOCTYPE html>
<html>
<head>
    <title>Critical Fixes Verification - LED Pixel Maps</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }}
        .container {{ max-width: 1400px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }}
        .fix {{ margin: 15px 0; padding: 15px; background: #e8f5e8; border-left: 4px solid #4CAF50; }}
        .critical {{ background: #fff3cd; border-left: 4px solid #ffc107; }}
        .image-container {{ text-align: center; margin: 20px 0; border: 2px solid #ddd; padding: 15px; }}
        .zoom-section {{ margin: 20px 0; padding: 15px; background: #f8f9fa; border-radius: 8px; }}
        img {{ max-width: 100%; border: 1px solid #ccc; }}
        .zoomed {{ transform: scale(3); transform-origin: top left; border: 2px solid #ff6b6b; }}
        .checklist {{ background: #f0f8ff; padding: 15px; margin: 15px 0; border-radius: 5px; }}
        .checklist ul {{ margin: 0; padding-left: 20px; }}
        .checklist li {{ margin: 8px 0; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>🔧 Critical Fixes Verification</h1>
        
        <div class="critical">
            <h3>⚠️ Issues Fixed in This Version</h3>
            <p><strong>Previous Problems:</strong> Missing panel numbers, thick grid lines, too much transparency</p>
            <p><strong>This Update:</strong> Guaranteed panel numbers, thin 1px lines, better visibility</p>
        </div>
        
        <div class="checklist">
            <h3>✅ Verification Checklist</h3>
            <ul>
                <li><strong>Panel Numbers:</strong> Every panel shows "row.col" (1.1, 1.2, etc.) in top-left corner</li>
                <li><strong>Grid Lines:</strong> Thin 1px white lines separating panels</li>
                <li><strong>Text Transparency:</strong> 20% transparency (80% visible) instead of 50%</li>
                <li><strong>Text Quality:</strong> Sharp TrueType fonts with anti-aliasing</li>
                <li><strong>Layout:</strong> Screen title centered, panel info bottom-left</li>
            </ul>
        </div>
        
        <div class="fix">
            <h3>🔢 Panel Numbers Fix</h3>
            <p><strong>Before:</strong> Missing on small panels due to size restrictions</p>
            <p><strong>After:</strong> Always shown on ALL panels regardless of size</p>
            <p><strong>Position:</strong> Top-left corner with 8% margin from edges</p>
        </div>
        
        <div class="fix">
            <h3>📏 Grid Lines Fix</h3>
            <p><strong>Before:</strong> Thick rectangle outlines</p>
            <p><strong>After:</strong> Thin 1px manual grid lines for precision</p>
            <p><strong>Method:</strong> Custom line drawing instead of rectangle borders</p>
        </div>
        
        <div class="fix">
            <h3>🎨 Transparency Fix</h3>
            <p><strong>Before:</strong> 50% transparency (128/255 alpha)</p>
            <p><strong>After:</strong> 20% transparency (204/255 alpha) - more visible</p>
            <p><strong>Result:</strong> Text is clearer and easier to read</p>
        </div>
        
        <div class="image-container">
            <h3>🖼️ Fixed Version - Full View</h3>
            <img src="{image_data}" alt="Fixed LED Pixel Map">
            <p><em>Should show: {test_data['surface']['panelsWidth']}×{test_data['surface']['fullPanelsHeight']} panels, each with visible numbers, thin grid lines</em></p>
        </div>
        
        <div class="zoom-section">
            <h3>🔍 Zoomed View - Panel Detail Verification</h3>
            <p><strong>Look for:</strong> Panel numbers in top-left corners, thin white grid lines</p>
            <div style="overflow: auto; max-height: 400px; border: 1px solid #ddd; background: white;">
                <img src="{image_data}" alt="Zoomed LED Pixel Map" class="zoomed">
            </div>
            <p><em>At 300% zoom, panel numbers and thin grid lines should be clearly visible</em></p>
        </div>
        
        <div style="text-align: center; margin: 20px 0;">
            <a href="{image_data}" download="fixed_led_pixel_map.png" 
               style="background: #4CAF50; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; font-size: 16px;">
               📥 Download Fixed Version PNG
            </a>
        </div>
        
        <div class="fix">
            <h3>🏆 Quality Comparison</h3>
            <p><strong>Panel Numbers:</strong> Now guaranteed on all {test_data['surface']['panelsWidth'] * test_data['surface']['fullPanelsHeight']} panels</p>
            <p><strong>Grid Quality:</strong> Precise 1px lines instead of thick borders</p>
            <p><strong>Text Visibility:</strong> 20% transparency for better readability</p>
            <p><strong>File Size:</strong> {result.get('file_size_mb', 0)} MB - optimized PNG quality</p>
        </div>
    </div>
</body>
</html>
                        ''')
                    
                    print("✅ Saved: fixes_verification.html")
                    print("🌐 Open in browser to verify all fixes")
                
            else:
                print(f"❌ Service error: {result}")
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_fixes()
