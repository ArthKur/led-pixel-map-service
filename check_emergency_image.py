#!/usr/bin/env python3
"""
Check the emergency test image for grid colors
"""
import sys
try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("❌ PIL/Pillow not available. Install with: pip3 install Pillow numpy")
    sys.exit(1)

def analyze_image_grid(image_path):
    """Analyze the grid colors in the emergency test image"""
    try:
        img = Image.open(image_path)
        img_array = np.array(img)
        
        print(f"🔍 IMAGE ANALYSIS: {image_path}")
        print(f"📏 Size: {img.size}")
        print(f"🎨 Mode: {img.mode}")
        
        # Get some sample pixels from grid lines (edges of image where grid should be)
        height, width = img_array.shape[:2]
        
        # Sample top edge (should be grid line)
        top_edge_pixels = img_array[0, :width//4]  # First quarter of top edge
        
        # Sample left edge (should be grid line)
        left_edge_pixels = img_array[:height//4, 0]  # First quarter of left edge
        
        print(f"\n🔍 GRID LINE ANALYSIS:")
        print(f"Top edge sample pixels (first 10):")
        for i, pixel in enumerate(top_edge_pixels[:10]):
            if len(pixel) == 3:  # RGB
                print(f"  Pixel {i}: RGB({pixel[0]}, {pixel[1]}, {pixel[2]})")
            elif len(pixel) == 4:  # RGBA
                print(f"  Pixel {i}: RGBA({pixel[0]}, {pixel[1]}, {pixel[2]}, {pixel[3]})")
        
        print(f"\nLeft edge sample pixels (first 10):")
        for i, pixel in enumerate(left_edge_pixels[:10]):
            if len(pixel) == 3:  # RGB
                print(f"  Pixel {i}: RGB({pixel[0]}, {pixel[1]}, {pixel[2]})")
            elif len(pixel) == 4:  # RGBA
                print(f"  Pixel {i}: RGBA({pixel[0]}, {pixel[1]}, {pixel[2]}, {pixel[3]})")
        
        # Check if grid lines are white (255,255,255) or colored
        white_count = 0
        colored_count = 0
        
        for pixel in top_edge_pixels:
            if len(pixel) >= 3:
                if pixel[0] == 255 and pixel[1] == 255 and pixel[2] == 255:
                    white_count += 1
                else:
                    colored_count += 1
        
        print(f"\n📊 GRID COLOR ANALYSIS:")
        print(f"White pixels in top edge: {white_count}")
        print(f"Colored pixels in top edge: {colored_count}")
        
        if white_count > colored_count:
            print("❌ PROBLEM: Grid appears to be WHITE!")
            print("   This means the cloud service is NOT generating colored borders")
        else:
            print("✅ SUCCESS: Grid appears to be COLORED!")
            print("   This means the cloud service IS generating colored borders")
            print("   The issue must be in the Flutter app or browser caching")
            
    except Exception as e:
        print(f"❌ Error analyzing image: {e}")

if __name__ == "__main__":
    analyze_image_grid("emergency_test.png")
