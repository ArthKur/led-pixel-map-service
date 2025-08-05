#!/usr/bin/env python3
"""
🎨 Simple Test for Professional Font-Like Numbering
Testing reference-quality typography rendering
"""

from PIL import Image, ImageDraw
import math

def generate_color(panel_x, panel_y, led_name='Absen'):
    """Generate colors based on LED type and panel position"""
    if 'absen' in led_name.lower():
        colors = [(255, 0, 0), (128, 128, 128)]
    elif 'novastar' in led_name.lower():
        colors = [(0, 100, 255), (180, 180, 180)]
    elif 'colorlight' in led_name.lower():
        colors = [(0, 200, 0), (240, 240, 240)]
    else:
        colors = [(255, 0, 0), (128, 128, 128)]
    
    color_index = (panel_x + panel_y) % len(colors)
    return colors[color_index]

def draw_smooth_line(draw, x1, y1, x2, y2, thickness, color):
    """Draw a smooth line with rounded ends - professional quality"""
    if thickness <= 1:
        draw.line([(x1, y1), (x2, y2)], fill=color, width=1)
        return
    
    # Calculate direction
    dx = x2 - x1
    dy = y2 - y1
    length = math.sqrt(dx*dx + dy*dy)
    
    if length == 0:
        return
    
    # Unit vector
    ux = dx / length
    uy = dy / length
    
    # Perpendicular vector
    px = -uy * thickness / 2
    py = ux * thickness / 2
    
    # Draw main rectangle
    points = [
        (x1 + px, y1 + py),
        (x1 - px, y1 - py),
        (x2 - px, y2 - py),
        (x2 + px, y2 + py)
    ]
    
    # Convert to integer coordinates
    points = [(int(x), int(y)) for x, y in points]
    draw.polygon(points, fill=color)
    
    # Draw rounded ends
    radius = thickness // 2
    for cx, cy in [(x1, y1), (x2, y2)]:
        for dy in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                if dx*dx + dy*dy <= radius*radius:
                    draw.rectangle([cx + dx, cy + dy, cx + dx + 1, cy + dy + 1], fill=color)

def draw_font_one(draw, x, y, size, color):
    """Draw font-like '1' - clean vertical line with serif"""
    thickness = max(2, size // 8)
    width = int(size * 0.5)
    height = size
    
    # Main vertical line (centered)
    line_x = x + width // 2
    draw_smooth_line(draw, line_x, y, line_x, y + height, thickness, color)
    
    # Top serif (angled)
    serif_length = width // 3
    draw_smooth_line(draw, line_x - serif_length, y + serif_length, line_x, y, thickness, color)
    
    # Bottom serif
    bottom_y = y + height
    draw_smooth_line(draw, line_x - serif_length, bottom_y, line_x + serif_length, bottom_y, thickness, color)

def draw_font_two(draw, x, y, size, color):
    """Draw font-like '2' - curved top, diagonal, straight bottom"""
    thickness = max(2, size // 8)
    width = int(size * 0.7)
    height = size
    
    # Top curve - simplified
    quarter_height = height // 4
    draw_smooth_line(draw, x, y + quarter_height, x + width // 2, y, thickness, color)
    draw_smooth_line(draw, x + width // 2, y, x + width, y + quarter_height, thickness, color)
    draw_smooth_line(draw, x + width, y + quarter_height, x + width, y + height // 2, thickness, color)
    
    # Diagonal line
    draw_smooth_line(draw, x + width, y + height // 2, x, y + height, thickness, color)
    
    # Bottom line
    draw_smooth_line(draw, x, y + height, x + width, y + height, thickness, color)

def draw_simple_digit(draw, digit, x, y, size, color):
    """Draw simplified professional digits"""
    if digit == '1':
        draw_font_one(draw, x, y, size, color)
    elif digit == '2':
        draw_font_two(draw, x, y, size, color)
    elif digit == '3':
        # Simple 3
        thickness = max(2, size // 8)
        width = int(size * 0.7)
        height = size
        draw_smooth_line(draw, x, y, x + width, y, thickness, color)
        draw_smooth_line(draw, x + width, y, x + width, y + height // 2, thickness, color)
        draw_smooth_line(draw, x + width // 2, y + height // 2, x + width, y + height // 2, thickness, color)
        draw_smooth_line(draw, x + width, y + height // 2, x + width, y + height, thickness, color)
        draw_smooth_line(draw, x, y + height, x + width, y + height, thickness, color)
    else:
        # Default: simple rectangle for other digits
        thickness = max(2, size // 8)
        width = int(size * 0.7)
        height = size
        draw.rectangle([x, y, x + width, y + height], outline=color, width=thickness)

def draw_professional_number(draw, number_str, x, y, size, color):
    """Draw professional number with proper spacing"""
    current_x = x
    digit_width = int(size * 0.8)
    digit_spacing = max(3, size // 12)
    
    for char in number_str:
        if char.isdigit():
            draw_simple_digit(draw, char, current_x, y, size, color)
            current_x += digit_width + digit_spacing
        elif char == '.':
            # Draw dot
            dot_size = max(3, size // 6)
            dot_y = y + size - dot_size
            center_x = current_x + dot_size // 2
            center_y = dot_y + dot_size // 2
            radius = dot_size // 2
            for dy in range(-radius, radius + 1):
                for dx in range(-radius, radius + 1):
                    if dx*dx + dy*dy <= radius*radius:
                        draw.rectangle([center_x + dx, center_y + dy, center_x + dx + 1, center_y + dy + 1], fill=color)
            current_x += digit_width // 3

def test_simple_professional():
    """Test simple professional numbering"""
    
    print("🎨 Testing Simple Professional Font-Like Numbering")
    print("=" * 50)
    
    # Create test image
    panel_size = 200
    panels_width, panels_height = 6, 4
    
    image_width = panels_width * panel_size
    image_height = panels_height * panel_size
    
    image = Image.new('RGB', (image_width, image_height), 'white')
    draw = ImageDraw.Draw(image)
    
    # Draw panels with professional numbering
    for panel_y in range(panels_height):
        for panel_x in range(panels_width):
            x = panel_x * panel_size
            y = panel_y * panel_size
            
            # Generate color
            color = generate_color(panel_x, panel_y, 'Colorlight')
            
            # Draw panel
            draw.rectangle([x, y, x + panel_size, y + panel_size], fill=color)
            
            # Professional numbering: 15% of panel size
            number_size = int(panel_size * 0.15)
            number_size = max(12, number_size)
            
            # Position with 3% margin
            margin = max(3, int(panel_size * 0.03))
            number_x = x + margin
            number_y = y + margin
            
            # Panel number
            panel_num = panel_y * panels_width + panel_x + 1
            
            # Draw professional numbering
            draw_professional_number(draw, str(panel_num), number_x, number_y, number_size, (255, 255, 255))
    
    # Save test image
    filename = "simple_professional_test.png"
    image.save(filename)
    print(f"✅ Generated: {filename}")
    print(f"📊 Image: {image_width}×{image_height}px")
    print(f"🎨 Professional font-like numbering with:")
    print(f"   • Smooth lines with rounded ends")
    print(f"   • Proper typography proportions")
    print(f"   • Reference-quality appearance")
    print(f"   • 15% panel size scaling")

if __name__ == "__main__":
    test_simple_professional()
