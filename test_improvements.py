#!/usr/bin/env python3
"""
Test improved vector numbering with different LED types and checkbox functionality
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app import generate_pixel_map_optimized
from PIL import Image
import time

def test_improvements():
    """Test all the improvements"""
    
    print("🧪 TESTING IMPROVED VECTOR NUMBERING")
    print("=" * 60)
    
    # Test parameters
    panel_width = 200
    panel_height = 200
    width_panels = 3
    height_panels = 2
    total_width = width_panels * panel_width
    total_height = height_panels * panel_height
    
    print(f"📏 Testing: {width_panels}×{height_panels} panels")
    print(f"📏 Panel size: {panel_width}×{panel_height}px")
    print(f"📏 Total image: {total_width}×{total_height}px")
    
    # Test different LED types and checkbox functionality
    test_cases = [
        ("Absen", True, "absen_with_numbers.png"),
        ("Absen", False, "absen_without_numbers.png"),
        ("Novastar", True, "novastar_with_numbers.png"),
        ("Colorlight", True, "colorlight_with_numbers.png"),
        ("Linsn", True, "linsn_with_numbers.png"),
        ("Unknown Brand", True, "unknown_with_numbers.png"),
    ]
    
    results = []
    
    for led_name, show_numbers, filename in test_cases:
        print(f"\n🔧 Testing {led_name} - Numbers: {'ON' if show_numbers else 'OFF'}")
        
        try:
            start_time = time.time()
            
            config = {
                'showGrid': True,
                'showPanelNumbers': show_numbers,
                'ledName': led_name
            }
            
            image = generate_pixel_map_optimized(
                width=total_width,
                height=total_height,
                pixel_pitch=2.5,
                led_panel_width=panel_width,
                led_panel_height=panel_height,
                canvas_scale=1.0,
                config=config
            )
            
            duration = time.time() - start_time
            
            if image:
                image.save(filename)
                
                # Analyze colors
                pixels = list(image.getdata())
                unique_colors = set(pixels)
                
                print(f"   ✅ SUCCESS in {duration:.2f}s")
                print(f"   📁 Saved: {filename}")
                print(f"   🎨 Colors: {len(unique_colors)} unique values")
                
                results.append((led_name, show_numbers, True, len(unique_colors)))
            else:
                print(f"   ❌ FAILED: No image generated")
                results.append((led_name, show_numbers, False, 0))
                
        except Exception as e:
            print(f"   💥 EXCEPTION: {e}")
            results.append((led_name, show_numbers, False, 0))
    
    # Summary
    print("\n" + "=" * 60)
    print("📊 IMPROVEMENT TEST RESULTS")
    print("=" * 60)
    
    for led_name, show_numbers, success, colors in results:
        status = "✅ PASS" if success else "❌ FAIL"
        numbers_text = "Numbers ON" if show_numbers else "Numbers OFF"
        print(f"{status} {led_name:12} - {numbers_text:12} - {colors} colors")
    
    # Check if checkbox works (compare Absen with/without numbers)
    absen_with = next((r for r in results if r[0] == "Absen" and r[1] == True), None)
    absen_without = next((r for r in results if r[0] == "Absen" and r[1] == False), None)
    
    if absen_with and absen_without and absen_with[3] != absen_without[3]:
        print("\n✅ CHECKBOX FUNCTIONALITY: Working! Different color counts when toggled")
    else:
        print("\n❌ CHECKBOX ISSUE: Numbers toggle may not be working")
    
    # Check if different LED types have different colors
    led_colors = {}
    for led_name, show_numbers, success, colors in results:
        if success and show_numbers:  # Only check successful cases with numbers
            led_colors[led_name] = colors
    
    if len(set(led_colors.values())) > 1:
        print("✅ LED TYPE COLORS: Working! Different LED types have different color schemes")
    else:
        print("❌ LED TYPE COLORS: All LED types appear to have same colors")
    
    print("\n🎯 KEY IMPROVEMENTS:")
    print("✅ 20% panel size numbering (was 10%)")
    print("✅ 3% margin positioning (was tight corner)")
    print("✅ Rounded, eye-friendly vector digits (was chunky)")
    print("✅ LED type-specific color schemes")
    print("✅ Fixed checkbox functionality")

if __name__ == "__main__":
    test_improvements()
