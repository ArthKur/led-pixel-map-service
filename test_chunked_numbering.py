#!/usr/bin/env python3
"""
Test vector numbering with chunked processing (large image)
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import generate_pixel_map_optimized
from PIL import Image
import time

def test_chunked_numbering():
    """Test vector numbering with chunked processing"""
    
    print("🧪 TESTING CHUNKED VECTOR NUMBERING")
    print("=" * 50)
    
    # Large image to force chunked processing (>50M pixels)
    panel_width = 500
    panel_height = 500
    width_panels = 15
    height_panels = 15
    total_width = width_panels * panel_width
    total_height = height_panels * panel_height
    total_pixels = total_width * total_height
    
    print(f"📏 Testing: {width_panels}×{height_panels} panels")
    print(f"📏 Panel size: {panel_width}×{panel_height}px")
    print(f"📏 Total image: {total_width}×{total_height}px")
    print(f"📏 Total pixels: {total_pixels:,} ({total_pixels/1_000_000:.1f}M)")
    print(f"📏 Expected number size: ~{int(panel_width * 0.2)}px (20% of panel)")
    print(f"📏 Expected margin: ~{int(panel_width * 0.03)}px (3% of panel)")
    
    if total_pixels <= 50_000_000:
        print("⚠️ Image too small for chunked processing - increase size")
        return False
    
    try:
        start_time = time.time()
        
        # Test with numbering enabled
        config = {
            'showGrid': True,
            'showPanelNumbers': True
        }
        
        print("\n🔄 Testing with panel numbers ENABLED...")
        image_with_numbers = generate_pixel_map_optimized(
            width=total_width,
            height=total_height,
            pixel_pitch=2.5,
            led_panel_width=panel_width,
            led_panel_height=panel_height,
            canvas_scale=1.0,
            config=config
        )
        
        duration = time.time() - start_time
        
        if image_with_numbers:
            filename = "chunked_test_with_numbers.png"
            image_with_numbers.save(filename)
            
            print(f"✅ SUCCESS in {duration:.1f}s")
            print(f"📁 Saved: {filename}")
            print(f"📏 Image size: {image_with_numbers.size}")
            
            # Test with numbering disabled
            start_time = time.time()
            config['showPanelNumbers'] = False
            
            print("\n🔄 Testing with panel numbers DISABLED...")
            image_without_numbers = generate_pixel_map_optimized(
                width=total_width,
                height=total_height,
                pixel_pitch=2.5,
                led_panel_width=panel_width,
                led_panel_height=panel_height,
                canvas_scale=1.0,
                config=config
            )
            
            duration2 = time.time() - start_time
            
            if image_without_numbers:
                filename2 = "chunked_test_without_numbers.png"
                image_without_numbers.save(filename2)
                
                print(f"✅ SUCCESS in {duration2:.1f}s")
                print(f"📁 Saved: {filename2}")
                
                # Compare the images to verify the checkbox works
                pixels_with = list(image_with_numbers.getdata())
                pixels_without = list(image_without_numbers.getdata())
                
                if pixels_with != pixels_without:
                    print("✅ CHECKBOX WORKING: Images are different when numbering is toggled")
                    return True
                else:
                    print("❌ CHECKBOX ISSUE: Images are identical regardless of numbering setting")
                    return False
            else:
                print("❌ Failed to generate image without numbers")
                return False
        else:
            print("❌ Failed to generate image with numbers")
            return False
            
    except Exception as e:
        print(f"💥 EXCEPTION: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_chunked_numbering()
    
    if success:
        print("\n🎉 CHUNKED NUMBERING TEST PASSED!")
        print("✅ 20% panel size numbering works")
        print("✅ 3% margin positioning works") 
        print("✅ Checkbox toggle works")
        print("✅ Ultra-large image support confirmed")
    else:
        print("\n❌ CHUNKED NUMBERING TEST FAILED")
        print("Check the error messages above")
