#!/usr/bin/env python3
"""
Test the brighter border grid locally to debug
"""

import sys
sys.path.append('.')

from PIL import Image, ImageDraw

def brighten_color(color, factor=0.3):
    """Brighten a color by the given factor (0.0 to 1.0)"""
    r, g, b = color
    # Brighten each component
    r = min(255, int(r + (255 - r) * factor))
    g = min(255, int(g + (255 - g) * factor))
    b = min(255, int(b + (255 - b) * factor))
    return (r, g, b)

def generate_color(panel_x, panel_y, led_name='Absen'):
    """Generate colors based on LED type and panel position"""
    
    # Different color schemes for different LED manufacturers
    if 'absen' in led_name.lower():
        # Absen: Full red and medium grey
        colors = [
            (255, 0, 0),    # Full red (pure red)
            (128, 128, 128) # Medium grey
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

def test_local_grid():
    """Test the grid implementation locally"""
    
    print("🧪 Testing Grid Implementation Locally")
    print("=" * 40)
    
    # Create test image
    panel_width = 100
    panel_height = 100
    panels_h = 3
    panels_v = 2
    
    img_width = panels_h * panel_width
    img_height = panels_v * panel_height
    
    # Test with grid
    img_grid = Image.new('RGB', (img_width, img_height), color=(0, 0, 0))
    draw_grid = ImageDraw.Draw(img_grid)
    
    # Fill panels with colors and add brighter grid borders
    for row in range(panels_v):
        for col in range(panels_h):
            x = col * panel_width
            y = row * panel_height
            
            # Generate color for this panel
            panel_color = generate_color(col, row, 'Absen')
            
            # Draw panel rectangle filled with color
            draw_grid.rectangle([x, y, x + panel_width - 1, y + panel_height - 1], 
                         fill=panel_color, outline=None)
            
            # Add brighter border
            border_color = brighten_color(panel_color, 0.3)
            print(f"Panel ({col},{row}): Base color {panel_color} → Border color {border_color}")
            
            # Draw 1-pixel brighter border around panel
            # Top border
            draw_grid.line([(x, y), (x + panel_width - 1, y)], fill=border_color, width=1)
            # Bottom border  
            draw_grid.line([(x, y + panel_height - 1), (x + panel_width - 1, y + panel_height - 1)], fill=border_color, width=1)
            # Left border
            draw_grid.line([(x, y), (x, y + panel_height - 1)], fill=border_color, width=1)
            # Right border
            draw_grid.line([(x + panel_width - 1, y), (x + panel_width - 1, y + panel_height - 1)], fill=border_color, width=1)
    
    img_grid.save('local_grid_test.png')
    
    # Test without grid
    img_no_grid = Image.new('RGB', (img_width, img_height), color=(0, 0, 0))
    draw_no_grid = ImageDraw.Draw(img_no_grid)
    
    for row in range(panels_v):
        for col in range(panels_h):
            x = col * panel_width
            y = row * panel_height
            
            # Generate color for this panel
            panel_color = generate_color(col, row, 'Absen')
            
            # Draw panel rectangle filled with color (no border)
            draw_no_grid.rectangle([x, y, x + panel_width - 1, y + panel_height - 1], 
                         fill=panel_color, outline=None)
    
    img_no_grid.save('local_no_grid_test.png')
    
    print(f"✅ Local test completed:")
    print(f"   • Grid version: local_grid_test.png")
    print(f"   • No grid version: local_no_grid_test.png")
    print(f"   • Check if brighter borders are visible")

if __name__ == "__main__":
    test_local_grid()
