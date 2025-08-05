#!/usr/bin/env python3
"""
🎨 FINAL VERIFICATION: Ultra-Smooth Numbering Comparison
Comparing old chunky vs new smooth numbering side-by-side
"""

from PIL import Image, ImageDraw
import json

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

def draw_old_chunky_digit(draw, digit, x, y, size, color=(0, 0, 0)):
    """Old chunky style - 20% size, thick segments"""
    patterns = {
        '0': [1, 1, 1, 1, 1, 1, 0], '1': [0, 1, 1, 0, 0, 0, 0],
        '2': [1, 1, 0, 1, 1, 0, 1], '3': [1, 1, 1, 1, 0, 0, 1],
        '4': [0, 1, 1, 0, 0, 1, 1], '5': [1, 0, 1, 1, 0, 1, 1],
        '6': [1, 0, 1, 1, 1, 1, 1], '7': [1, 1, 1, 0, 0, 0, 0],
        '8': [1, 1, 1, 1, 1, 1, 1], '9': [1, 1, 1, 1, 0, 1, 1],
    }
    
    if digit not in patterns:
        return
    
    pattern = patterns[digit]
    seg_thickness = max(2, size // 6)  # OLD: Thick segments
    mid_y = y + size // 2
    
    # Draw thick, chunky segments
    if pattern[0]:  # top
        draw.rectangle([x + seg_thickness, y, x + size - seg_thickness, y + seg_thickness], fill=color)
    if pattern[1]:  # top-right
        draw.rectangle([x + size - seg_thickness, y + seg_thickness, x + size, mid_y - seg_thickness//2], fill=color)
    if pattern[2]:  # bottom-right
        draw.rectangle([x + size - seg_thickness, mid_y + seg_thickness//2, x + size, y + size - seg_thickness], fill=color)
    if pattern[3]:  # bottom
        draw.rectangle([x + seg_thickness, y + size - seg_thickness, x + size - seg_thickness, y + size], fill=color)
    if pattern[4]:  # bottom-left
        draw.rectangle([x, mid_y + seg_thickness//2, x + seg_thickness, y + size - seg_thickness], fill=color)
    if pattern[5]:  # top-left
        draw.rectangle([x, y + seg_thickness, x + seg_thickness, mid_y - seg_thickness//2], fill=color)
    if pattern[6]:  # middle
        draw.rectangle([x + seg_thickness, mid_y - seg_thickness//2, x + size - seg_thickness, mid_y + seg_thickness//2], fill=color)

def draw_new_smooth_digit(draw, digit, x, y, size, color=(0, 0, 0)):
    """NEW ultra-smooth style - 15% size, thin segments, anti-aliasing"""
    patterns = {
        '0': [1, 1, 1, 1, 1, 1, 0], '1': [0, 1, 1, 0, 0, 0, 0],
        '2': [1, 1, 0, 1, 1, 0, 1], '3': [1, 1, 1, 1, 0, 0, 1],
        '4': [0, 1, 1, 0, 0, 1, 1], '5': [1, 0, 1, 1, 0, 1, 1],
        '6': [1, 0, 1, 1, 1, 1, 1], '7': [1, 1, 1, 0, 0, 0, 0],
        '8': [1, 1, 1, 1, 1, 1, 1], '9': [1, 1, 1, 1, 0, 1, 1],
    }
    
    if digit not in patterns:
        return
    
    pattern = patterns[digit]
    seg_thickness = max(1, size // 10)  # NEW: Much thinner segments
    corner_radius = max(1, seg_thickness // 2)
    mid_y = y + size // 2
    gap = max(1, seg_thickness // 2)
    
    def draw_smooth_segment(x1, y1, x2, y2, horizontal=True):
        """Ultra-smooth with anti-aliasing effect"""
        if horizontal:
            draw.rectangle([x1 + corner_radius, y1, x2 - corner_radius, y2], fill=color)
            for i in range(corner_radius):
                alpha_factor = (corner_radius - i) / corner_radius
                end_y1 = y1 + int(i * alpha_factor)
                end_y2 = y2 - int(i * alpha_factor)
                if end_y1 < end_y2:
                    draw.rectangle([x1 + i, end_y1, x1 + i + 1, end_y2], fill=color)
                    draw.rectangle([x2 - i - 1, end_y1, x2 - i, end_y2], fill=color)
        else:
            draw.rectangle([x1, y1 + corner_radius, x2, y2 - corner_radius], fill=color)
            for i in range(corner_radius):
                alpha_factor = (corner_radius - i) / corner_radius
                end_x1 = x1 + int(i * alpha_factor)
                end_x2 = x2 - int(i * alpha_factor)
                if end_x1 < end_x2:
                    draw.rectangle([end_x1, y1 + i, end_x2, y1 + i + 1], fill=color)
                    draw.rectangle([end_x1, y2 - i - 1, end_x2, y2 - i], fill=color)
    
    # Draw smooth segments with gaps
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

def create_comparison():
    """Create side-by-side comparison of old vs new numbering"""
    
    print("🎨 Creating Old vs New Numbering Comparison")
    print("=" * 60)
    
    # Panel configuration
    panels_width, panels_height = 8, 6
    panel_size = 150
    
    # Create comparison image - double width for side-by-side
    image_width = panels_width * panel_size * 2  # Double width
    image_height = panels_height * panel_size
    
    image = Image.new('RGB', (image_width, image_height), 'white')
    draw = ImageDraw.Draw(image)
    
    # Draw comparison panels
    for panel_y in range(panels_height):
        for panel_x in range(panels_width):
            panel_num = panel_y * panels_width + panel_x + 1
            
            # LEFT SIDE: Old chunky style (20% size)
            x_old = panel_x * panel_size
            y_old = panel_y * panel_size
            color_old = generate_color(panel_x, panel_y, 'Absen')
            
            # Draw old panel
            draw.rectangle([x_old, y_old, x_old + panel_size, y_old + panel_size], fill=color_old)
            
            # Old numbering: 20% size, thick segments
            old_number_size = int(panel_size * 0.2)  # 20%
            old_margin = max(3, int(panel_size * 0.03))
            draw_old_chunky_digit(draw, str(panel_num)[0], x_old + old_margin, y_old + old_margin, old_number_size, (255, 255, 255))
            if len(str(panel_num)) > 1:
                draw_old_chunky_digit(draw, str(panel_num)[1], x_old + old_margin + old_number_size + 5, y_old + old_margin, old_number_size, (255, 255, 255))
            
            # RIGHT SIDE: New smooth style (15% size)
            x_new = (panel_x + panels_width) * panel_size
            y_new = panel_y * panel_size
            color_new = generate_color(panel_x, panel_y, 'Colorlight')
            
            # Draw new panel
            draw.rectangle([x_new, y_new, x_new + panel_size, y_new + panel_size], fill=color_new)
            
            # New numbering: 15% size, thin segments
            new_number_size = int(panel_size * 0.15)  # 15%
            new_margin = max(3, int(panel_size * 0.03))
            draw_new_smooth_digit(draw, str(panel_num)[0], x_new + new_margin, y_new + new_margin, new_number_size, (255, 255, 255))
            if len(str(panel_num)) > 1:
                new_spacing = max(2, new_number_size // 8)
                draw_new_smooth_digit(draw, str(panel_num)[1], x_new + new_margin + new_number_size + new_spacing, y_new + new_margin, new_number_size, (255, 255, 255))
    
    # Add labels
    from PIL import ImageFont
    try:
        font = ImageFont.load_default()
    except:
        font = None
    
    # Label old side
    if font:
        draw.text((50, 20), "OLD: 20% Size, Chunky Segments", fill=(0, 0, 0), font=font)
        draw.text((panels_width * panel_size + 50, 20), "NEW: 15% Size, Ultra-Smooth", fill=(0, 0, 0), font=font)
    
    # Save comparison
    filename = "numbering_comparison_old_vs_new.png"
    image.save(filename)
    
    print(f"✅ Comparison saved: {filename}")
    print(f"📊 Image size: {image_width}×{image_height}px")
    print(f"📏 Old numbering: {int(panel_size * 0.2)}px (20% of {panel_size}px)")
    print(f"🎨 New numbering: {int(panel_size * 0.15)}px (15% of {panel_size}px)")
    print("\n🔍 Visual differences:")
    print("   LEFT (Old): Thick, chunky segments at 20% size")
    print("   RIGHT (New): Thin, smooth segments at 15% size")
    print("   • Much cleaner and more text-like appearance")
    print("   • Better proportions")
    print("   • Reduced visual clutter")
    print("   • Professional typography feel")
    
    return filename

if __name__ == "__main__":
    create_comparison()
