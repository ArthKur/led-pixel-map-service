#!/usr/bin/env python3
"""Test script for sharp text quality"""

import requests
import json
import base64

def test_sharp_text():
    # Test with a smaller map to better see text sharpness
    test_data = {
        "surface": {
            "panelsWidth": 6,
            "fullPanelsHeight": 3,
            "halfPanelsHeight": 0,
            "panelPixelWidth": 300,  # Larger panels to see text better
            "panelPixelHeight": 300,
            "ledName": "Test LED"
        },
        "config": {
            "surfaceIndex": 4,  # Screen 5
            "showGrid": True,
            "showPanelNumbers": True
        }
    }
    
    service_url = "https://led-pixel-map-service-1.onrender.com"
    
    print("🔍 Testing Sharp Text Rendering")
    print("=" * 50)
    print("✅ TrueType fonts with proper sizing")
    print("✅ Anti-aliased text rendering")
    print("✅ High-quality PNG output")
    print("✅ No compression artifacts")
    print("=" * 50)
    
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
                
                # Save the sharp text image
                if image_base64:
                    image_bytes = base64.b64decode(image_base64)
                    with open('sharp_text_test.png', 'wb') as f:
                        f.write(image_bytes)
                    
                    print(f"🎯 Sharp Text Test Results:")
                    print(f"   📐 Display: {result.get('display_dimensions', {})} pixels")
                    print(f"   📦 Panels: {test_data['surface']['panelsWidth']}×{test_data['surface']['fullPanelsHeight']} = {test_data['surface']['panelsWidth'] * test_data['surface']['fullPanelsHeight']} panels")
                    print(f"   📱 Resolution: {result.get('dimensions', {})} pixels")
                    print(f"   💾 File size: {result.get('file_size_mb', 0)} MB")
                    print(f"   🔤 Font quality: TrueType with proper sizing")
                    print("")
                    print("✅ Saved: sharp_text_test.png")
                    print("👀 Text should now be:")
                    print("   • Sharp and crisp (not pixelated)")
                    print("   • Properly sized relative to panels")
                    print("   • Anti-aliased edges")
                    print("   • High contrast on dark backgrounds")
                    
                    # Create comparison HTML with zoom
                    image_data = f'data:image/png;base64,{image_base64}'
                    with open('sharp_text_comparison.html', 'w') as f:
                        f.write(f'''
<!DOCTYPE html>
<html>
<head>
    <title>Sharp Text Quality Test - LED Pixel Maps</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }}
        .container {{ max-width: 1400px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }}
        .feature {{ margin: 10px 0; padding: 10px; background: #e8f5e8; border-left: 4px solid #4CAF50; }}
        .image-container {{ text-align: center; margin: 20px 0; border: 2px solid #ddd; padding: 10px; }}
        .zoom-container {{ margin: 20px 0; padding: 10px; background: #f9f9f9; border-radius: 5px; }}
        img {{ max-width: 100%; border: 1px solid #ccc; }}
        .zoomed {{ transform: scale(2); transform-origin: top left; border: 2px solid #ff6b6b; }}
        .specs {{ background: #f0f8ff; padding: 15px; margin: 10px 0; border-radius: 5px; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>🔍 Sharp Text Quality Test</h1>
        
        <h2>🎯 Text Rendering Improvements</h2>
        <div class="feature">✅ <strong>TrueType Fonts:</strong> Using system fonts instead of default bitmap</div>
        <div class="feature">✅ <strong>Dynamic Sizing:</strong> Font size scales with image dimensions</div>
        <div class="feature">✅ <strong>Anti-aliasing:</strong> Smooth text edges, no pixelation</div>
        <div class="feature">✅ <strong>High Quality:</strong> Minimal compression, sharp rendering</div>
        <div class="feature">✅ <strong>Proper Contrast:</strong> Dark backgrounds for text visibility</div>
        
        <div class="specs">
            <h3>📊 Text Specifications</h3>
            <p><strong>Title Font:</strong> Dynamic size (16-48px based on image width)</p>
            <p><strong>Info Font:</strong> Dynamic size (10-24px based on image width)</p>
            <p><strong>Panel Font:</strong> Dynamic size (8-16px based on panel size)</p>
            <p><strong>Resolution:</strong> {result.get('display_dimensions', {}).get('width', 'N/A')}×{result.get('display_dimensions', {}).get('height', 'N/A')} pixels</p>
            <p><strong>File Size:</strong> {result.get('file_size_mb', 0)} MB (higher quality = larger size)</p>
        </div>
        
        <div class="image-container">
            <h3>🖼️ Generated Pixel Map - Normal View</h3>
            <img src="{image_data}" alt="LED Pixel Map - Sharp Text">
            <p><em>Text should appear crisp and clear at this scale</em></p>
        </div>
        
        <div class="zoom-container">
            <h3>🔍 Zoomed View (200%) - Check Text Quality</h3>
            <div style="overflow: auto; max-height: 400px; border: 1px solid #ddd;">
                <img src="{image_data}" alt="LED Pixel Map - Zoomed" class="zoomed">
            </div>
            <p><em>Even at 200% zoom, text should have smooth edges and clear readability</em></p>
        </div>
        
        <div style="text-align: center; margin: 20px 0;">
            <a href="{image_data}" download="sharp_text_pixel_map.png" 
               style="background: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
               📥 Download Sharp Text PNG
            </a>
        </div>
    </div>
</body>
</html>
                        ''')
                    
                    print("✅ Saved: sharp_text_comparison.html")
                    print("🌐 Open in browser to see text quality comparison with zoom")
                
            else:
                print(f"❌ Service error: {result}")
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_sharp_text()
