#!/usr/bin/env python3
"""Generate massive 40000x2400 pixel LED map and download to desktop"""

import requests
import json
import base64
import os

def generate_massive_pixel_map():
    # Calculate panel configuration for 40000x2400 resolution
    # Using 200x200 pixel panels for good detail
    panel_width = 200
    panel_height = 200
    
    panels_horizontal = 40000 // panel_width  # 200 panels wide
    panels_vertical = 2400 // panel_height    # 12 panels high
    
    print(f"🚀 MASSIVE PIXEL MAP GENERATION - CLEAN GRID")
    print(f"=" * 60)
    print(f"🎯 Target Resolution: 40000×2400 pixels")
    print(f"📦 Panel Configuration: {panels_horizontal}×{panels_vertical} panels")
    print(f"📐 Panel Size: {panel_width}×{panel_height}px each")
    print(f"🔢 Total Panels: {panels_horizontal * panels_vertical} panels")
    print(f"🎨 Style: Clean grid - no panel numbering")
    print(f"� Features: Smart panel number scaling (if enabled)")
    print(f"📏 Font scaling: Optimized for massive canvas sizes")
    print(f"�💾 Expected Size: Very Large (uncompressed PNG)")
    print(f"=" * 60)
    
    # Configuration for massive pixel map
    test_data = {
        "surface": {
            "panelsWidth": panels_horizontal,
            "fullPanelsHeight": panels_vertical,
            "halfPanelsHeight": 0,
            "panelPixelWidth": panel_width,
            "panelPixelHeight": panel_height,
            "ledName": "Massive 40K LED Wall"
        },
        "config": {
            "surfaceIndex": 0,  # Screen 1
            "showGrid": True,
            "showPanelNumbers": False  # Set to True for clean black panel numbers
        }
    }
    
    service_url = "https://led-pixel-map-service-1.onrender.com"
    
    print(f"📡 Sending request to cloud service...")
    print(f"⏱️  This may take several minutes for such a large image...")
    
    try:
        # Extended timeout for massive image generation
        response = requests.post(
            f"{service_url}/generate-pixel-map",
            headers={'Content-Type': 'application/json'},
            json=test_data,
            timeout=600  # 10 minutes timeout for massive images
        )
        
        if response.status_code == 200:
            result = response.json()
            
            if result.get('success'):
                image_base64 = result.get('image_base64', '')
                display_dims = result.get('display_dimensions', {})
                original_dims = result.get('dimensions', {})
                
                print(f"✅ MASSIVE PIXEL MAP GENERATED!")
                print(f"   📐 Original: {original_dims.get('width', 'N/A')}×{original_dims.get('height', 'N/A')} pixels")
                print(f"   📺 Display: {display_dims.get('width', 'N/A')}×{display_dims.get('height', 'N/A')} pixels")
                print(f"   📦 Panels: {panels_horizontal}×{panels_vertical} = {panels_horizontal * panels_vertical} total")
                print(f"   🔢 Scale factor: {result.get('scale_factor', 1):.2f}")
                print(f"   💾 File size: {result.get('file_size_mb', 0)} MB")
                
                # Download to desktop
                if image_base64:
                    image_bytes = base64.b64decode(image_base64)
                    
                    # Get desktop path
                    desktop_path = os.path.join(os.path.expanduser("~"), "Desktop")
                    filename = "massive_led_pixel_map_40000x2400_clean_grid.png"
                    file_path = os.path.join(desktop_path, filename)
                    
                    # Save to desktop
                    with open(file_path, 'wb') as f:
                        f.write(image_bytes)
                    
                    actual_size_mb = len(image_bytes) / (1024 * 1024)
                    
                    print(f"")
                    print(f"🎉 DOWNLOAD COMPLETE!")
                    print(f"   📁 Location: {file_path}")
                    print(f"   📊 File size: {actual_size_mb:.2f} MB")
                    print(f"   🎯 Resolution: {display_dims.get('width', 'N/A')}×{display_dims.get('height', 'N/A')} pixels")
                    print(f"   🎨 Style: Clean grid - no panel numbers")
                    print(f"   📱 Flutter ready: Direct PNG usage")
                    print(f"   🏗️  LED Installation: Professional quality mapping")
                    
                    # Verify file exists
                    if os.path.exists(file_path):
                        file_size_bytes = os.path.getsize(file_path)
                        file_size_mb_verify = file_size_bytes / (1024 * 1024)
                        print(f"   ✅ Verified: {file_size_mb_verify:.2f} MB saved to desktop")
                        
                        # Create summary info
                        info_filename = "massive_led_pixel_map_clean_grid_INFO.txt"
                        info_path = os.path.join(desktop_path, info_filename)
                        
                        with open(info_path, 'w') as f:
                            f.write(f"MASSIVE LED PIXEL MAP - 40000×2400 CLEAN GRID VERSION\\n")
                            f.write(f"=" * 60 + "\\n")
                            f.write(f"Generated: {test_data}\\n")
                            f.write(f"Service: Native PNG generation on Render.com\\n")
                            f.write(f"Original Resolution: {original_dims.get('width', 'N/A')}×{original_dims.get('height', 'N/A')} pixels\\n")
                            f.write(f"Display Resolution: {display_dims.get('width', 'N/A')}×{display_dims.get('height', 'N/A')} pixels\\n")
                            f.write(f"Panel Configuration: {panels_horizontal}×{panels_vertical} panels\\n")
                            f.write(f"Panel Size: {panel_width}×{panel_height}px each\\n")
                            f.write(f"Total Panels: {panels_horizontal * panels_vertical}\\n")
                            f.write(f"Scale Factor: {result.get('scale_factor', 1):.2f}\\n")
                            f.write(f"File Size: {actual_size_mb:.2f} MB\\n")
                            f.write(f"Format: PNG (uncompressed, pixel-perfect)\\n")
                            f.write(f"Quality: Native generation - no SVG conversion\\n")
                            f.write(f"Usage: Ready for Flutter direct display\\n")
                            f.write(f"Grid: 1px white lines between panels\\n")
                            f.write(f"Panel Numbers: DISABLED - Clean grid only\\n")
                            f.write(f"Design: Minimalist - just colorful panels with grid\\n")
                            f.write(f"Generated: 2025-08-04 via Render.com cloud service\\n")
                        
                        print(f"   📄 Info file: {info_path}")
                        
                        return True
                    else:
                        print(f"   ❌ Error: File not found after save")
                        return False
                
            else:
                print(f"❌ Service error: {result}")
                return False
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            try:
                print(f"Response: {response.text}")
            except:
                pass
            return False
            
    except requests.exceptions.Timeout:
        print(f"⏱️  Request timed out - image may be too large for current server limits")
        print(f"💡 Try smaller dimensions or contact service for optimization")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    print(f"🎯 Starting massive 40000×2400 pixel LED map generation...")
    success = generate_massive_pixel_map()
    
    if success:
        print(f"\\n🏆 SUCCESS! Massive pixel map downloaded to desktop!")
    else:
        print(f"\\n❌ Generation failed. Check service status or try smaller dimensions.")
