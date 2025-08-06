#!/usr/bin/env python3
"""
Test script to debug surface name rendering
"""

from PIL import Image, ImageDraw, ImageFont
import sys
import os

def test_surface_name_rendering():
    """Test surface name text rendering with exact same logic as the app"""
    
    # Test configuration - larger pixel map
    panels_width = 15
    panels_height = 8
    led_panel_width = 64
    led_panel_height = 32
    
    # Calculate full dimensions
    display_width = panels_width * led_panel_width  # 960px
    display_height = panels_height * led_panel_height  # 256px
    
    print(f"🖼️  Testing pixel map: {display_width}x{display_height}px")
    
    # Create image
    image = Image.new('RGB', (display_width, display_height), 'black')
    draw = ImageDraw.Draw(image)
    
    # Surface name settings
    surface_name = "BIG TEST NAME"
    show_name = True
    
    if show_name and surface_name:
        # Calculate font size so that TEXT WIDTH is 30% of canvas width (FIXED)
        target_text_width = int(display_width * 0.3)  # Target: 30% of canvas width
        
        print(f"📏 Text size calculation (FIXED):")
        print(f"   - Target text width: {target_text_width}px (30% of {display_width}px)")
        
        # Amber color
        amber_color = (255, 191, 0)
        
        # Start with an estimated font size and adjust to fit target width
        font_size = max(20, int(target_text_width / len(surface_name) * 1.2))  # Rough estimate
        font_size = min(font_size, 200)  # Cap at reasonable size
        
        print(f"   - Initial font size estimate: {font_size}px")
        
        # Try to load font
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", font_size)
            print(f"✅ Loaded Arial font at {font_size}px")
        except:
            try:
                font = ImageFont.load_default()
                print(f"⚠️  Using default font (size may be wrong)")
            except:
                font = None
                print(f"❌ No font available")
        
        if font:
            # Adjust font size to achieve target text width
            for attempt in range(10):  # Max 10 iterations
                bbox = draw.textbbox((0, 0), surface_name, font=font)
                actual_width = bbox[2] - bbox[0]
                
                print(f"   - Attempt {attempt + 1}: font_size={font_size}px → text_width={actual_width}px")
                
                if abs(actual_width - target_text_width) < target_text_width * 0.1:  # Within 10%
                    print(f"   ✅ Converged! Final text width: {actual_width}px (target: {target_text_width}px)")
                    break
                    
                # Adjust font size
                if actual_width > target_text_width:
                    font_size = int(font_size * 0.9)
                else:
                    font_size = int(font_size * 1.1)
                
                font_size = max(12, min(font_size, 300))  # Keep within bounds
                
                try:
                    font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", font_size)
                except:
                    font = ImageFont.load_default()
                    
            # Get final text size
            bbox = draw.textbbox((0, 0), surface_name, font=font)
            text_width = bbox[2] - bbox[0]
            text_height = bbox[3] - bbox[1]
            
            # Center the text
            center_x = display_width // 2
            center_y = display_height // 2
            text_x = center_x - text_width // 2
            text_y = center_y - text_height // 2
            
            print(f"📝 Final text placement:")
            print(f"   - Text: '{surface_name}'")
            print(f"   - Final size: {text_width}x{text_height}px")
            print(f"   - Position: ({text_x}, {text_y})")
            print(f"   - Color: {amber_color} (amber)")
            print(f"   - Font size: {font_size}px")
            
            # Draw the text
            draw.text((text_x, text_y), surface_name, fill=amber_color, font=font)
            
            # Save the test image
            output_file = "test_surface_name_debug_FIXED.png"
            image.save(output_file)
            print(f"💾 Saved test image: {output_file}")
            print(f"🔍 Text should now be visible and properly sized!")
            
            return True
        else:
            print("❌ Could not render text - no font available")
            return False
    else:
        print("❌ Surface name rendering disabled")
        return False

if __name__ == "__main__":
    test_surface_name_rendering()
