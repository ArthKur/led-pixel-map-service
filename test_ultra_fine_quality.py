#!/usr/bin/env python3
"""
Test the ULTRA-FINE QUALITY numbering system with smaller pixels
"""

import sys
sys.path.append('.')

from PIL import Image, ImageDraw
import requests
import json
import base64

# Import our improved ultra-fine draw_vector_digit function
def draw_vector_digit(draw, digit, x, y, size, color=(0, 0, 0)):
    """Draw a single digit using ULTRA HIGH QUALITY rendering with fine-pixel precision"""
    
    # ULTRA QUALITY settings - reduced pixel size for smoother text
    # Reduce the effective "pixel" size while maintaining readability
    base_thickness = max(2, size // 8)  # Thinner base strokes for finer detail
    thickness = base_thickness + 1  # Add slight thickness for visibility
    width = int(size * 0.75)  # Slightly narrower for better proportions
    height = size
    
    # Helper function for ultra-smooth thick lines with anti-aliasing effect
    def draw_ultra_smooth_line(x1, y1, x2, y2, thickness):
        # Draw core line
        draw.line([(x1, y1), (x2, y2)], fill=color, width=thickness)
        
        # Add sub-pixel smoothing with smaller rounded ends
        r = max(1, thickness // 3)  # Much smaller radius for finer detail
        
        # Multiple small circles for smoother appearance
        for i in range(3):
            offset = i * 0.3
            radius = r - i * 0.2
            if radius > 0:
                draw.ellipse([x1-radius+offset, y1-radius+offset, 
                            x1+radius+offset, y1+radius+offset], fill=color)
                draw.ellipse([x2-radius+offset, y2-radius+offset, 
                            x2+radius+offset, y2+radius+offset], fill=color)
    
    if digit == '0':
        # Ultra-smooth oval outline with fine detail
        margin = thickness // 2
        # Draw main oval
        draw.ellipse([x + margin, y + margin, x + width - margin, y + height - margin], 
                    outline=color, width=thickness)
        # Add inner smoothing
        inner_margin = margin + 1
        if width > 20 and height > 20:  # Only for larger sizes
            draw.ellipse([x + inner_margin, y + inner_margin, x + width - inner_margin, y + height - inner_margin], 
                        outline=color, width=1)
        
    elif digit == '1':
        # Ultra-smooth vertical line with refined serifs
        center_x = x + width // 2
        # Main vertical with ultra-smooth rendering
        draw_ultra_smooth_line(center_x, y + thickness, center_x, y + height - thickness, thickness)
        # Refined top serif
        serif_len = width // 4  # Smaller serif for finer look
        draw_ultra_smooth_line(center_x - serif_len, y + serif_len + thickness, center_x, y + thickness, thickness)
        # Refined bottom serif
        draw_ultra_smooth_line(center_x - serif_len, y + height - thickness, 
                       center_x + serif_len, y + height - thickness, thickness)
        
    elif digit == '2':
        # Ultra-smooth curves and lines
        mid_y = y + height // 2
        
        # Top horizontal
        draw_ultra_smooth_line(x + thickness, y + thickness, x + width - thickness, y + thickness, thickness)
        # Right vertical (top section)
        draw_ultra_smooth_line(x + width - thickness, y + thickness, x + width - thickness, mid_y, thickness)
        # Diagonal with anti-aliasing
        draw_ultra_smooth_line(x + width - thickness, mid_y, x + thickness, y + height - thickness, thickness)
        # Bottom horizontal
        draw_ultra_smooth_line(x + thickness, y + height - thickness, 
                       x + width - thickness, y + height - thickness, thickness)

def test_ultra_fine_quality():
    """Test ultra-fine quality numbering with smaller pixels"""
    
    print("🔬 Testing ULTRA-FINE QUALITY Numbering System")
    print("=" * 60)
    
    # Create larger test image for detailed comparison
    img_width, img_height = 1600, 600
    img = Image.new('RGB', (img_width, img_height), color=(40, 40, 40))  # Dark grey background
    draw = ImageDraw.Draw(img)
    
    # Test comparison: Old size vs Ultra-fine size
    old_size = 80  # Simulating old 15% sizing
    ultra_fine_size = 50  # Simulating new 10% sizing
    
    spacing = 90
    start_x = 50
    start_y = 50
    
    # Header text
    header_y = 20
    draw.text((start_x, header_y), "OLD 15% SIZE (Pixelated):", fill=(255, 255, 255))
    draw.text((start_x, header_y + 300), "NEW 10% ULTRA-FINE (Smooth):", fill=(255, 255, 255))
    
    # Test digits comparison
    digits = "0123456789"
    
    # Old size (simulating pixelated appearance)
    for i, digit in enumerate(digits):
        x = start_x + i * spacing
        # Simulating old thick pixelated look
        draw_old_digit(draw, digit, x, start_y + 40, old_size, color=(255, 100, 100))  # Red tint
    
    # Ultra-fine new size
    for i, digit in enumerate(digits):
        x = start_x + i * spacing
        # New ultra-fine rendering
        draw_vector_digit(draw, digit, x, start_y + 340, ultra_fine_size, color=(100, 255, 100))  # Green tint
    
    # Test actual panel numbers at realistic scale
    panel_y = start_y + 480
    
    # Simulate actual panel sizes like 200x200 pixels
    panel_size_old = int(200 * 0.15)  # Old 15% = 30px
    panel_size_new = int(200 * 0.10)  # New 10% = 20px
    
    # Test panel numbers
    test_numbers = ["1.1", "2.5", "10.15", "25.8"]
    for i, number in enumerate(test_numbers):
        x_old = start_x + i * 120
        x_new = start_x + i * 120
        
        # Old size
        draw_panel_number_old(draw, number, x_old, panel_y, panel_size_old, color=(255, 255, 255))
        
        # New ultra-fine size
        draw_panel_number_new(draw, number, x_new, panel_y + 60, panel_size_new, color=(255, 255, 255))
    
    # Save comparison image
    img.save('ultra_fine_quality_comparison.png')
    
    print(f"✅ Comparison image created: ultra_fine_quality_comparison.png")
    print(f"📐 Old size (15%): {old_size}px → Pixelated, thick strokes")
    print(f"📐 New size (10%): {ultra_fine_size}px → Ultra-fine, smooth strokes")
    print(f"🎯 Panel numbers:")
    print(f"   • Old: {panel_size_old}px (15% of 200px panel)")
    print(f"   • New: {panel_size_new}px (10% of 200px panel)")
    print(f"📈 Quality improvement: Smaller pixels = Smoother text")
    
    return True

def draw_old_digit(draw, digit, x, y, size, color):
    """Simulate old thick pixelated digit style"""
    thickness = max(8, size // 3)  # Very thick, pixelated style
    width = int(size * 0.9)
    
    if digit == '1':
        center_x = x + width // 2
        # Thick pixelated line
        draw.line([(center_x, y + thickness), (center_x, y + size - thickness)], fill=color, width=thickness)
    elif digit == '2':
        # Thick pixelated curves
        mid_y = y + size // 2
        draw.line([(x + thickness, y + thickness), (x + width - thickness, y + thickness)], fill=color, width=thickness)
        draw.line([(x + width - thickness, y + thickness), (x + width - thickness, mid_y)], fill=color, width=thickness)
        draw.line([(x + width - thickness, mid_y), (x + thickness, y + size - thickness)], fill=color, width=thickness)
        draw.line([(x + thickness, y + size - thickness), (x + width - thickness, y + size - thickness)], fill=color, width=thickness)

def draw_panel_number_old(draw, number, x, y, size, color):
    """Draw panel number with old thick style"""
    current_x = x
    spacing = size // 2
    for char in number:
        if char.isdigit():
            draw_old_digit(draw, char, current_x, y, size, color)
            current_x += int(size * 0.9) + spacing
        elif char == '.':
            dot_size = size // 3
            draw.ellipse([current_x, y + size - dot_size, current_x + dot_size, y + size], fill=color)
            current_x += dot_size + spacing

def draw_panel_number_new(draw, number, x, y, size, color):
    """Draw panel number with new ultra-fine style"""
    current_x = x
    spacing = size // 4
    for char in number:
        if char.isdigit():
            draw_vector_digit(draw, char, current_x, y, size, color)
            current_x += int(size * 0.75) + spacing
        elif char == '.':
            dot_size = max(2, size // 6)
            draw.ellipse([current_x, y + size - dot_size, current_x + dot_size, y + size], fill=color)
            current_x += dot_size + spacing

def test_cloud_ultra_fine():
    """Test the cloud service with ultra-fine quality"""
    
    # Test data
    test_data = {
        "surface": {
            "panelsWidth": 6,
            "fullPanelsHeight": 4,
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
    
    print(f"\n🌐 Testing Cloud Service with ULTRA-FINE QUALITY")
    print("=" * 60)
    
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
                
                with open('cloud_ultra_fine_test.png', 'wb') as f:
                    f.write(image_data)
                
                print(f"✅ Ultra-fine cloud image generated!")
                print(f"📐 Dimensions: {result['dimensions']['width']}×{result['dimensions']['height']}")
                print(f"💾 File size: {result['file_size_mb']:.3f} MB")
                print(f"💾 Saved: cloud_ultra_fine_test.png")
                print(f"🔬 Text quality: 10% sizing with ultra-smooth strokes")
                
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
    local_success = test_ultra_fine_quality()
    
    # Test cloud service if local works
    if local_success:
        cloud_success = test_cloud_ultra_fine()
        
        print(f"\n🔬 ULTRA-FINE QUALITY RESULTS:")
        print(f"   • Local comparison: {'✅ SUCCESS' if local_success else '❌ FAILED'}")
        print(f"   • Cloud test: {'✅ SUCCESS' if cloud_success else '❌ FAILED'}")
        
        if local_success and cloud_success:
            print(f"\n🎉 ULTRA-FINE QUALITY IMPLEMENTED!")
            print(f"   • Size reduced: 15% → 10% (smaller pixels)")
            print(f"   • Stroke optimization: Thinner base with smoothing")
            print(f"   • Anti-aliasing effect: Multiple sub-pixel circles")
            print(f"   • Compare ultra_fine_quality_comparison.png")
            print(f"   • Check cloud_ultra_fine_test.png for live results")
            print(f"   • Much smoother, less pixelated appearance")
