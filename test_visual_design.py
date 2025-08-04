#!/usr/bin/env python3
"""Test script to showcase the new visual design"""

import requests
import json
import base64

def test_visual_design():
    # Test with a smaller map to better see the details
    test_data = {
        "surface": {
            "panelsWidth": 8,
            "fullPanelsHeight": 4,
            "halfPanelsHeight": 0,
            "panelPixelWidth": 200,
            "panelPixelHeight": 200,
            "ledName": "Absen PL2.5 Lite"
        },
        "config": {
            "surfaceIndex": 2,  # Screen 3
            "showGrid": True,
            "showPanelNumbers": True
        }
    }
    
    service_url = "https://led-pixel-map-service-1.onrender.com"
    
    print("🎨 Testing New Visual Design")
    print("=" * 50)
    print("✅ Removed black top area")
    print("✅ Panels only design")
    print("✅ Screen title centered on canvas")
    print("✅ Thin white panel borders (1px)")
    print("✅ Panel count + pixels in bottom left")
    print("✅ No product name shown")
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
                
                # Save the image
                if image_base64:
                    image_bytes = base64.b64decode(image_base64)
                    with open('visual_test_new_design.png', 'wb') as f:
                        f.write(image_bytes)
                    
                    print(f"🎯 Visual Test Results:")
                    print(f"   📐 Dimensions: {result.get('display_dimensions', {})}")
                    print(f"   📦 Panels: {test_data['surface']['panelsWidth']}×{test_data['surface']['fullPanelsHeight']} = {test_data['surface']['panelsWidth'] * test_data['surface']['fullPanelsHeight']} panels")
                    print(f"   📱 Pixels: {result.get('dimensions', {})}")
                    print(f"   💾 File size: {result.get('file_size_mb', 0)} MB")
                    print(f"   🖼️ Format: {result.get('format', 'PNG')}")
                    print("")
                    print("✅ Saved: visual_test_new_design.png")
                    print("👀 Open the file to see:")
                    print("   • Clean panels-only design")
                    print("   • 'Screen 3' centered on canvas")
                    print("   • Thin white borders between panels")
                    print("   • Panel numbers on each panel") 
                    print("   • '8×4 panels | 1600×800px' in bottom left")
                    
                    # Create comparison HTML
                    image_data = f'data:image/png;base64,{image_base64}'
                    with open('visual_comparison.html', 'w') as f:
                        f.write(f'''
<!DOCTYPE html>
<html>
<head>
    <title>Visual Design Showcase - LED Pixel Maps</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }}
        .container {{ max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }}
        .feature {{ margin: 10px 0; padding: 10px; background: #e8f5e8; border-left: 4px solid #4CAF50; }}
        .image-container {{ text-align: center; margin: 20px 0; border: 2px solid #ddd; padding: 10px; }}
        img {{ max-width: 100%; border: 1px solid #ccc; }}
        .specs {{ background: #f0f8ff; padding: 15px; margin: 10px 0; border-radius: 5px; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>🎨 LED Pixel Map - New Visual Design</h1>
        
        <h2>✨ Design Improvements</h2>
        <div class="feature">✅ <strong>Clean Design:</strong> Removed black top area - panels only</div>
        <div class="feature">✅ <strong>Centered Title:</strong> "Screen X" positioned in canvas center</div>
        <div class="feature">✅ <strong>Thin Borders:</strong> White 1px borders between panels (was thick gray)</div>
        <div class="feature">✅ <strong>Bottom Info:</strong> Panel count + pixel dimensions in bottom left</div>
        <div class="feature">✅ <strong>No Clutter:</strong> Removed product name for cleaner look</div>
        
        <div class="specs">
            <h3>📊 Technical Specs</h3>
            <p><strong>Panels:</strong> {test_data['surface']['panelsWidth']}×{test_data['surface']['fullPanelsHeight']} = {test_data['surface']['panelsWidth'] * test_data['surface']['fullPanelsHeight']} panels</p>
            <p><strong>Resolution:</strong> {result.get('dimensions', {}).get('width', 'N/A')}×{result.get('dimensions', {}).get('height', 'N/A')} pixels</p>
            <p><strong>Display Size:</strong> {result.get('display_dimensions', {}).get('width', 'N/A')}×{result.get('display_dimensions', {}).get('height', 'N/A')} pixels</p>
            <p><strong>File Size:</strong> {result.get('file_size_mb', 0)} MB</p>
            <p><strong>Format:</strong> True PNG (not SVG)</p>
        </div>
        
        <div class="image-container">
            <h3>🖼️ Generated Pixel Map</h3>
            <img src="{image_data}" alt="LED Pixel Map - New Design">
            <p><em>Notice: Colorful panels, thin white borders, centered title, bottom left info</em></p>
        </div>
        
        <div style="text-align: center; margin: 20px 0;">
            <a href="{image_data}" download="led_pixel_map_new_design.png" 
               style="background: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">
               📥 Download PNG
            </a>
        </div>
    </div>
</body>
</html>
                        ''')
                    
                    print("✅ Saved: visual_comparison.html")
                    print("🌐 Open in browser to see full visual comparison")
                
            else:
                print(f"❌ Service error: {result}")
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_visual_design()
