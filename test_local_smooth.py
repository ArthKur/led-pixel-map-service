#!/usr/bin/env python3
"""
🧪 Local Test for Ultra-Smooth Vector Numbering
Testing 15% size and improved quality directly
"""

from PIL import Image, ImageDraw
import json

def generate_color(panel_x, panel_y, led_name='Absen'):
    """Generate colors based on LED type and panel position"""
    
    # Different color schemes for different LED manufacturers
    if 'absen' in led_name.lower():
        # Absen: Full red and medium grey
        colors = [
            (255, 0, 0),    # Full red (pure red)
            (128, 128, 128) # Medium grey
        ]
    elif 'novastar' in led_name.lower():
        # Novastar: Blue and light grey
        colors = [
            (0, 100, 255),  # Blue
            (180, 180, 180) # Light grey
        ]
    elif 'colorlight' in led_name.lower():
        # Colorlight: Green and white
        colors = [
            (0, 200, 0),    # Green
            (240, 240, 240) # Nearly white
        ]
    elif 'linsn' in led_name.lower():
        # Linsn: Purple and cream
        colors = [
            (150, 0, 150),  # Purple
            (250, 245, 220) # Cream
        ]
    else:
        # Default/Unknown: Standard red and grey
        colors = [
            (255, 0, 0),    # Full red (pure red)
            (128, 128, 128) # Medium grey
        ]
    
    # Alternate colors in a checkerboard pattern
    color_index = (panel_x + panel_y) % len(colors)
    return colors[color_index]

def draw_vector_digit(draw, digit, x, y, size, color=(0, 0, 0)):
    """Draw a single digit using high-quality smooth text-like style - ULTRA SMOOTH DESIGN"""
    
    # Enhanced 7-segment patterns for better visibility
    patterns = {
        '0': [1, 1, 1, 1, 1, 1, 0],  # All except middle
        '1': [0, 1, 1, 0, 0, 0, 0],  # Right side only
        '2': [1, 1, 0, 1, 1, 0, 1],  # Top + right-top + middle + left-bottom + bottom
        '3': [1, 1, 1, 1, 0, 0, 1],  # Top + right + middle + bottom
        '4': [0, 1, 1, 0, 0, 1, 1],  # Left-top, right side, middle
        '5': [1, 0, 1, 1, 0, 1, 1],  # Left S-shape
        '6': [1, 0, 1, 1, 1, 1, 1],  # Left + bottom
        '7': [1, 1, 1, 0, 0, 0, 0],  # Top + right
        '8': [1, 1, 1, 1, 1, 1, 1],  # All segments
        '9': [1, 1, 1, 1, 0, 1, 1],  # All except bottom-left
        '.': [0, 0, 0, 0, 0, 0, 0],  # Special case for dot
    }
    
    if digit not in patterns:
        return
    
    pattern = patterns[digit]
    
    # Ultra-smooth segment dimensions for text-like appearance
    seg_thickness = max(1, size // 10)  # Much thinner segments for smooth look
    seg_length = size - (seg_thickness * 2)
    corner_radius = max(1, seg_thickness // 2)  # Smaller radius for cleaner look
    
    # Advanced smooth segment drawing with sub-pixel precision
    def draw_smooth_segment(x1, y1, x2, y2, horizontal=True):
        """Draw ultra-smooth segment with anti-aliasing effect"""
        if horizontal:
            # Main segment body
            draw.rectangle([x1 + corner_radius, y1, x2 - corner_radius, y2], fill=color)
            
            # Smooth rounded ends with gradient effect
            for i in range(corner_radius):
                alpha_factor = (corner_radius - i) / corner_radius
                # Left rounded end
                end_y1 = y1 + int(i * alpha_factor)
                end_y2 = y2 - int(i * alpha_factor)
                if end_y1 < end_y2:
                    draw.rectangle([x1 + i, end_y1, x1 + i + 1, end_y2], fill=color)
                
                # Right rounded end  
                if end_y1 < end_y2:
                    draw.rectangle([x2 - i - 1, end_y1, x2 - i, end_y2], fill=color)
        else:
            # Main segment body
            draw.rectangle([x1, y1 + corner_radius, x2, y2 - corner_radius], fill=color)
            
            # Smooth rounded ends with gradient effect
            for i in range(corner_radius):
                alpha_factor = (corner_radius - i) / corner_radius
                # Top rounded end
                end_x1 = x1 + int(i * alpha_factor)
                end_x2 = x2 - int(i * alpha_factor)
                if end_x1 < end_x2:
                    draw.rectangle([end_x1, y1 + i, end_x2, y1 + i + 1], fill=color)
                
                # Bottom rounded end
                if end_x1 < end_x2:
                    draw.rectangle([end_x1, y2 - i - 1, end_x2, y2 - i], fill=color)
    
    # Enhanced segment positioning for better proportions
    mid_y = y + size // 2
    gap = max(1, seg_thickness // 2)  # Small gap between segments
    
    # Draw active segments with ultra-smooth rendering
    if pattern[0]:  # top
        draw_smooth_segment(x + seg_thickness, y, x + size - seg_thickness, y + seg_thickness, True)
    
    if pattern[1]:  # top-right
        draw_smooth_segment(x + size - seg_thickness, y + seg_thickness + gap, x + size, mid_y - gap, False)
    
    if pattern[2]:  # bottom-right
        draw_smooth_segment(x + size - seg_thickness, mid_y + gap, x + size, y + size - seg_thickness - gap, False)
    
    if pattern[3]:  # bottom
        draw_smooth_segment(x + seg_thickness, y + size - seg_thickness, x + size - seg_thickness, y + size, True)
    
    if pattern[4]:  # bottom-left
        draw_smooth_segment(x, mid_y + gap, x + seg_thickness, y + size - seg_thickness - gap, False)
    
    if pattern[5]:  # top-left
        draw_smooth_segment(x, y + seg_thickness + gap, x + seg_thickness, mid_y - gap, False)
    
    if pattern[6]:  # middle
        draw_smooth_segment(x + seg_thickness, mid_y - seg_thickness//2, x + size - seg_thickness, mid_y + seg_thickness//2, True)

def draw_vector_dot(draw, x, y, size, color=(0, 0, 0)):
    """Draw a smooth vector dot for decimal points"""
    dot_size = max(2, size // 8)  # Smaller, more proportional dot
    dot_y = y + size - dot_size - (size // 10)  # Better positioning
    
    # Draw smooth circular dot with multiple rectangles for roundness
    center_x = x + dot_size // 2
    center_y = dot_y + dot_size // 2
    radius = dot_size // 2
    
    # Draw circular dot using filled rectangles
    for dy in range(-radius, radius + 1):
        for dx in range(-radius, radius + 1):
            if dx * dx + dy * dy <= radius * radius:
                draw.rectangle([center_x + dx, center_y + dy, center_x + dx + 1, center_y + dy + 1], fill=color)

def draw_vector_panel_number(draw, panel_number, x, y, size, color=(0, 0, 0)):
    """Draw panel number using ultra-smooth vector digits - TEXT-LIKE QUALITY"""
    current_x = x
    digit_width = size
    digit_spacing = max(2, size // 8)  # Better proportional spacing between digits
    
    for char in panel_number:
        if char == '.':
            draw_vector_dot(draw, current_x, y, size, color)
            current_x += digit_width // 2  # Dots take less space
        elif char.isdigit():
            draw_vector_digit(draw, char, current_x, y, size, color)
            current_x += digit_width + digit_spacing
        else:
            # Skip non-digit, non-dot characters
            current_x += digit_width // 3

def test_local_smooth_numbering():
    """Test the improved numbering system locally"""
    
    print("🧪 Local Ultra-Smooth Numbering Test")
    print("=" * 50)
    
    # Test different sizes and LED types
    test_cases = [
        {
            "name": "Small Panels - Absen",
            "panels": (6, 4),
            "led_name": "Absen",
            "panel_size": 100
        },
        {
            "name": "Medium Panels - Novastar", 
            "panels": (10, 6),
            "led_name": "Novastar",
            "panel_size": 150
        },
        {
            "name": "Large Panels - Colorlight",
            "panels": (8, 8),
            "led_name": "Colorlight", 
            "panel_size": 200
        }
    ]
    
    for test in test_cases:
        print(f"\n🎨 Testing: {test['name']}")
        print(f"   📐 Panels: {test['panels'][0]}×{test['panels'][1]}")
        print(f"   📏 Panel size: {test['panel_size']}px")
        
        # Calculate expected numbering size (15% of panel)
        expected_number_size = int(test['panel_size'] * 0.15)
        print(f"   🔢 Expected number size: {expected_number_size}px (15% of {test['panel_size']}px)")
        
        # Create test image
        panels_width, panels_height = test['panels']
        image_width = panels_width * test['panel_size']
        image_height = panels_height * test['panel_size']
        
        image = Image.new('RGB', (image_width, image_height), 'white')
        draw = ImageDraw.Draw(image)
        
        # Draw panels with smooth numbering
        for panel_y in range(panels_height):
            for panel_x in range(panels_width):
                x = panel_x * test['panel_size']
                y = panel_y * test['panel_size']
                
                # Generate LED-specific color
                color = generate_color(panel_x, panel_y, test['led_name'])
                
                # Draw panel
                draw.rectangle([x, y, x + test['panel_size'], y + test['panel_size']], fill=color)
                
                # Calculate actual numbering size (15% of panel)
                number_size = int(min(test['panel_size'], test['panel_size']) * 0.15)
                number_size = max(12, number_size)  # Minimum 12px
                
                # Position with 3% margin
                margin_x = max(3, int(test['panel_size'] * 0.03))
                margin_y = max(3, int(test['panel_size'] * 0.03))
                number_x = x + margin_x
                number_y = y + margin_y
                
                # Panel number
                panel_num = panel_y * panels_width + panel_x + 1
                
                # Draw ultra-smooth numbering
                draw_vector_panel_number(draw, str(panel_num), number_x, number_y, number_size, (255, 255, 255))
        
        # Save test image
        filename = f"local_smooth_{test['led_name'].lower()}_test.png"
        image.save(filename)
        print(f"   ✅ Generated: {filename}")
        print(f"   📊 Image: {image_width}×{image_height}px")
        print(f"   🎨 Actual number size: {number_size}px")
        print(f"   🌈 LED colors: {test['led_name']}-specific scheme")
        
        # Verify size calculation
        actual_percentage = (number_size / test['panel_size']) * 100
        print(f"   ✨ Size verification: {actual_percentage:.1f}% (target: 15%)")
    
    print("\n" + "=" * 50) 
    print("🎊 Local Ultra-Smooth Test Complete!")
    print("🔍 Check generated images to see:")
    print("   • 15% numbering size (reduced from 20%)")
    print("   • Much smoother, text-like appearance")
    print("   • Thinner segments for cleaner look")
    print("   • Better proportional spacing")
    print("   • Anti-aliasing effect")

if __name__ == "__main__":
    test_local_smooth_numbering()
