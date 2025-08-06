#!/usr/bin/env python3
"""
🔧 DEBUG BRIGHTEN FUNCTION
Test if the brighten_color function is working
"""

def test_brighten_local():
    """Test brighten_color function locally"""
    def brighten_color(color, factor=0.3):
        """Brighten a color by the given factor (0.0 to 1.0)"""
        r, g, b = color
        # Brighten each component
        r = min(255, int(r + (255 - r) * factor))
        g = min(255, int(g + (255 - g) * factor))
        b = min(255, int(b + (255 - b) * factor))
        return (r, g, b)
    
    print("🔧 TESTING BRIGHTEN_COLOR FUNCTION")
    print("=" * 50)
    
    # Test the exact colors from the panel test
    red_base = (255, 0, 0)
    grey_base = (128, 128, 128)
    
    red_bright = brighten_color(red_base, 0.4)
    grey_bright = brighten_color(grey_base, 0.4)
    
    print(f"RED base:   {red_base}")
    print(f"RED +40%:   {red_bright}")
    print(f"Expected:   (255, 102, 102)")
    print()
    print(f"GREY base:  {grey_base}")
    print(f"GREY +40%:  {grey_bright}")
    print(f"Expected:   (179, 179, 179)")
    print()
    
    # The border pixels should be these brightened colors!
    print("🎯 EXPECTED BORDER COLORS:")
    print(f"  Red panels should have borders: {red_bright}")
    print(f"  Grey panels should have borders: {grey_bright}")

if __name__ == "__main__":
    test_brighten_local()
