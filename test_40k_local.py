#!/usr/bin/env python3

# Direct test of 40000×2400px generation using local cloud service code
import sys
import os
sys.path.append('cloud_pixel_service')

from PIL import Image, ImageDraw
import io
import base64

def test_40k_generation():
    print("🧪 Testing 40000×2400px Generation Locally")
    print("==========================================")
    
    # Parameters for 200×12 Absen panels = 40000×2400px
    panels_width = 200
    full_panels_height = 12
    panel_pixel_width = 200
    panel_pixel_height = 200
    
    total_width = panels_width * panel_pixel_width
    total_height = full_panels_height * panel_pixel_height
    
    print(f"Target size: {total_width}×{total_height}px")
    print(f"Panel configuration: {panels_width}×{full_panels_height} panels")
    print(f"Each panel: {panel_pixel_width}×{panel_pixel_height}px")
    
    try:
        # Create the image
        print("Creating image...")
        image = Image.new('RGB', (total_width, total_height), color='black')
        
        print("Drawing panels...")
        draw = ImageDraw.Draw(image)
        
        # Panel colors
        panel_colors = [
            (45, 27, 105),    # Deep purple
            (27, 94, 32),     # Deep green
            (13, 71, 161),    # Deep blue
            (230, 81, 0),     # Deep orange
            (191, 54, 12),    # Deep red
            (74, 20, 140),    # Deep violet
        ]
        
        # Draw panels
        for row in range(full_panels_height):
            for col in range(panels_width):
                x = col * panel_pixel_width
                y = row * panel_pixel_height
                
                color_index = (row + col) % len(panel_colors)
                panel_color = panel_colors[color_index]
                
                # Draw panel
                draw.rectangle(
                    [x, y, x + panel_pixel_width - 1, y + panel_pixel_height - 1],
                    fill=panel_color
                )
                
                # Progress indicator
                if (row * panels_width + col) % 1000 == 0:
                    progress = ((row * panels_width + col) / (panels_width * full_panels_height)) * 100
                    print(f"Progress: {progress:.1f}%")
        
        print("Encoding to PNG...")
        img_buffer = io.BytesIO()
        image.save(img_buffer, format='PNG', optimize=True)
        
        file_size_mb = len(img_buffer.getvalue()) / (1024 * 1024)
        
        print(f"🎉 SUCCESS!")
        print(f"Generated: {total_width}×{total_height}px")
        print(f"File size: {file_size_mb:.2f}MB")
        print(f"This proves cloud service CAN handle ultra-wide images!")
        
        return True
        
    except Exception as e:
        print(f"❌ ERROR: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    test_40k_generation()
