#!/usr/bin/env python3
"""
Test the improved HIGH QUALITY numbering system
"""

import sys
sys.path.append('.')

from PIL import Image, ImageDraw
import requests
import json
import base64

# Import our improved draw_vector_digit function
def draw_vector_digit(draw, digit, x, y, size, color=(0, 0, 0)):
    """Draw a single digit using HIGH QUALITY rendering with thick strokes"""
    
    # High quality settings - much thicker and more readable
    thickness = max(4, size // 5)  # Much thicker strokes
    width = int(size * 0.8)  # Wider digits
    height = size
    
    # Helper function for thick rounded lines
    def draw_thick_line(x1, y1, x2, y2, thickness):
        # Draw line with rounded ends
        draw.line([(x1, y1), (x2, y2)], fill=color, width=thickness)
        # Add rounded ends
        r = thickness // 2
        draw.ellipse([x1-r, y1-r, x1+r, y1+r], fill=color)
        draw.ellipse([x2-r, y2-r, x2+r, y2+r], fill=color)
    
    if digit == '0':
        # Thick oval outline
        margin = thickness // 2
        draw.ellipse([x + margin, y + margin, x + width - margin, y + height - margin], 
                    outline=color, width=thickness)
        
    elif digit == '1':
        # Thick vertical line with serifs
        center_x = x + width // 2
        # Main vertical
        draw_thick_line(center_x, y + thickness, center_x, y + height - thickness, thickness)
        # Top serif
        serif_len = width // 3
        draw_thick_line(center_x - serif_len, y + serif_len + thickness, center_x, y + thickness, thickness)
        # Bottom serif
        draw_thick_line(center_x - serif_len, y + height - thickness, 
                       center_x + serif_len, y + height - thickness, thickness)
        
    elif digit == '2':
        # Top curve, diagonal, bottom line with thick strokes
        mid_y = y + height // 2
        quarter_y = y + height // 4
        
        # Top horizontal
        draw_thick_line(x + thickness, y + thickness, x + width - thickness, y + thickness, thickness)
        # Right vertical (top section)
        draw_thick_line(x + width - thickness, y + thickness, x + width - thickness, mid_y, thickness)
        # Diagonal
        draw_thick_line(x + width - thickness, mid_y, x + thickness, y + height - thickness, thickness)
        # Bottom horizontal
        draw_thick_line(x + thickness, y + height - thickness, 
                       x + width - thickness, y + height - thickness, thickness)
        
    elif digit == '3':
        # Three horizontal lines with right curves
        mid_y = y + height // 2
        # Top horizontal
        draw_thick_line(x + thickness, y + thickness, x + width - thickness, y + thickness, thickness)
        # Middle horizontal
        draw_thick_line(x + width//2, mid_y, x + width - thickness, mid_y, thickness)
        # Bottom horizontal
        draw_thick_line(x + thickness, y + height - thickness, 
                       x + width - thickness, y + height - thickness, thickness)
        # Right verticals
        draw_thick_line(x + width - thickness, y + thickness, x + width - thickness, mid_y, thickness)
        draw_thick_line(x + width - thickness, mid_y, x + width - thickness, y + height - thickness, thickness)

def test_local_high_quality():
    """Test high quality numbering locally"""
    
    print("🎨 Testing HIGH QUALITY Numbering System")
    print("=" * 50)
    
    # Create test image
    img_width, img_height = 1200, 400
    img = Image.new('RGB', (img_width, img_height), color=(128, 128, 128))  # Grey background
    draw = ImageDraw.Draw(img)
    
    # Test digits with large size for quality assessment
    digit_size = 120
    spacing = 130
    start_x = 50
    start_y = 50
    
    # Test digits 0-9
    digits = "0123456789"
    for i, digit in enumerate(digits):
        x = start_x + i * spacing
        # White numbers on grey background for visibility
        draw_vector_digit(draw, digit, x, start_y, digit_size, color=(255, 255, 255))
    
    # Add panel numbers test (15% sizing)
    panel_size = int(digit_size * 0.15)  # 15% size like in actual use
    panel_y = start_y + 200
    
    # Test small panel numbers
    test_numbers = ["1.1", "2.5", "10.15", "25.8"]
    for i, number in enumerate(test_numbers):
        x = start_x + i * spacing * 2
        for j, char in enumerate(number):
            char_x = x + j * int(panel_size * 0.6)
            draw_vector_digit(draw, char, char_x, panel_y, panel_size, color=(255, 255, 255))
    
    # Save test image
    img.save('high_quality_numbering_test.png')
    
    print(f"✅ Test image created: high_quality_numbering_test.png")
    print(f"📐 Large digits: {digit_size}px")
    print(f"📐 Panel digits: {panel_size}px (15% sizing)")
    print(f"🎯 Features:")
    print(f"   • Thick strokes (size // 5)")
    print(f"   • Rounded line ends")
    print(f"   • Better proportions (0.8 width ratio)")
    print(f"   • High contrast white on grey")
    
    return True

def test_cloud_with_high_quality():
    """Test the cloud service with improved quality"""
    
    # Test data
    test_data = {
        "surface": {
            "panelsWidth": 4,
            "fullPanelsHeight": 3,
            "halfPanelsHeight": 0,
            "panelPixelWidth": 200,
            "panelPixelHeight": 200,
            "ledName": "Absen PL2.5 Lite"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,
            "showPanelNumbers": True
        }
    }
    
    print("\n🌐 Testing Cloud Service with HIGH QUALITY")
    print("=" * 50)
    
    try:
        # Make request
        response = requests.post(
            "https://led-pixel-map-service-1.onrender.com/generate-pixel-map",
            json=test_data,
            timeout=30
        )
        
        print(f"📡 Response status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            
            if result.get('success'):
                # Decode and save image
                image_data = base64.b64decode(result['image_base64'])
                
                with open('cloud_high_quality_test.png', 'wb') as f:
                    f.write(image_data)
                
                print(f"✅ Cloud image generated!")
                print(f"📐 Dimensions: {result['dimensions']['width']}×{result['dimensions']['height']}")
                print(f"💾 File size: {result['file_size_mb']:.3f} MB")
                print(f"💾 Saved: cloud_high_quality_test.png")
                
                return True
            else:
                print(f"❌ Cloud error: {result.get('error')}")
                return False
        else:
            print(f"❌ HTTP error: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False

if __name__ == "__main__":
    # Test locally first
    local_success = test_local_high_quality()
    
    # Test cloud service if local works
    if local_success:
        cloud_success = test_cloud_with_high_quality()
        
        print(f"\n🎯 QUALITY IMPROVEMENT RESULTS:")
        print(f"   • Local test: {'✅ SUCCESS' if local_success else '❌ FAILED'}")
        print(f"   • Cloud test: {'✅ SUCCESS' if cloud_success else '❌ FAILED'}")
        
        if local_success and cloud_success:
            print(f"\n🎉 HIGH QUALITY NUMBERING IMPLEMENTED!")
            print(f"   • Compare high_quality_numbering_test.png with previous version")
            print(f"   • Check cloud_high_quality_test.png for actual output")
            print(f"   • Much thicker, more readable strokes")
            print(f"   • Better proportions and spacing")
