#!/usr/bin/env python3
"""
🔧 Quick Error Diagnosis for Professional Numbering
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    from app import draw_vector_digit, draw_vector_panel_number
    from PIL import Image, ImageDraw
    
    print("✅ Imports successful")
    
    # Test basic functionality
    image = Image.new('RGB', (100, 100), 'white')
    draw = ImageDraw.Draw(image)
    
    # Test digit drawing
    draw_vector_digit(draw, '1', 10, 10, 30, (0, 0, 0))
    print("✅ draw_vector_digit works")
    
    # Test panel number drawing
    draw_vector_panel_number(draw, "12", 50, 50, 20, (0, 0, 0))
    print("✅ draw_vector_panel_number works")
    
    image.save("quick_test.png")
    print("✅ Image saved successfully")
    print("🎉 All functions working locally")
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
