#!/usr/bin/env python3
"""
🔧 DEBUG COLOR GENERATION
Check what colors are being generated and what borders should look like
"""

def test_brighten_color():
    """Test the brighten_color function locally"""
    def brighten_color(color, factor=0.3):
        """Brighten a color by the given factor (0.0 to 1.0)"""
        r, g, b = color
        # Brighten each component
        r = min(255, int(r + (255 - r) * factor))
        g = min(255, int(g + (255 - g) * factor))
        b = min(255, int(b + (255 - b) * factor))
        return (r, g, b)
    
    print("🔧 BRIGHTEN COLOR TEST")
    print("=" * 40)
    
    # Test with typical LED colors
    test_colors = [
        (255, 0, 0),      # Pure Red
        (128, 128, 128),  # Medium Grey
        (255, 255, 0),    # Yellow
        (0, 255, 0),      # Green
        (0, 0, 255),      # Blue
    ]
    
    for base_color in test_colors:
        bright_30 = brighten_color(base_color, 0.3)
        bright_40 = brighten_color(base_color, 0.4)
        
        print(f"Base:   {base_color}")
        print(f"30%:    {bright_30}")
        print(f"40%:    {bright_40}")
        print()

def test_color_alternating():
    """Test the alternating color pattern"""
    print("🔧 COLOR PATTERN TEST")
    print("=" * 40)
    
    # This mimics the pattern in generate_color function
    for row in range(3):
        for col in range(3):
            if (row + col) % 2 == 0:
                color = (255, 0, 0)  # Red
                pattern = "RED"
            else:
                color = (128, 128, 128)  # Grey
                pattern = "GREY"
            
            print(f"Panel ({col},{row}): {pattern} {color}")

if __name__ == "__main__":
    test_brighten_color()
    test_color_alternating()
