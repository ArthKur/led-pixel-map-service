from flask import Flask, request, jsonify
from flask_cors import CORS
from PIL import Image, ImageDraw, ImageFont
import base64
import io
import os
import struct

app = Flask(__name__)
CORS(app)

def generate_color(panel_x, panel_y):
    """Generate alternating full red and medium grey colors for each panel"""
    # Use only two colors: full red and medium grey
    colors = [
        (255, 0, 0),    # Full red (pure red)
        (128, 128, 128) # Medium grey
    ]
    
    # Alternate colors in a checkerboard pattern
    color_index = (panel_x + panel_y) % len(colors)
    return colors[color_index]

@app.route('/')
def health_check():
    return jsonify({
        'service': 'LED Pixel Map Cloud Renderer',
        'status': 'healthy',
        'version': '10.10 - Balanced Quality: 6000×6000 max for stable sharp images',
        'message': 'Red/Grey alternating pattern with surface-size-based font scaling and improved image quality',
        'features': 'Surface-width based font scaling, no backgrounds, pure black text',
        'colors': 'Full Red (255,0,0) alternating with Medium Grey (128,128,128)',
        'timestamp': '2025-08-04-09:00'
    })

@app.route('/test')
def test():
    return jsonify({'message': 'Test endpoint working!'})

@app.route('/generate-pixel-map', methods=['POST'])
def generate_pixel_map():
    try:
        data = request.get_json()
        
        # Extract dimensions
        surface = data.get('surface', {})
        config = data.get('config', {})
        panels_width = surface.get('panelsWidth', 10)
        panels_height = surface.get('fullPanelsHeight', 5)
        panel_pixel_width = surface.get('panelPixelWidth', 200)
        panel_pixel_height = surface.get('panelPixelHeight', 200)
        led_name = surface.get('ledName', 'Unknown LED')
        
        show_grid = config.get('showGrid', True)
        show_panel_numbers = config.get('showPanelNumbers', True)
        surface_index = config.get('surfaceIndex', 0)
        
        # Calculate total dimensions
        total_width = panels_width * panel_pixel_width
        total_height = panels_height * panel_pixel_height
        
        # For very large images, create a manageable size for display
        # BALANCED limits for good quality without overwhelming the server
        # 50m×50m = 20,000×20,000px original → target ~6000px output for good balance
        max_display_width = 6000   # Balanced limit for server stability
        max_display_height = 6000  # Balanced limit for server stability
        scale_factor = 1
        
        if total_width > max_display_width or total_height > max_display_height:
            scale_x = total_width / max_display_width
            scale_y = total_height / max_display_height
            scale_factor = max(scale_x, scale_y)
        
        display_width = int(total_width / scale_factor)
        display_height = int(total_height / scale_factor)
        panel_display_width = int(panel_pixel_width / scale_factor)
        panel_display_height = int(panel_pixel_height / scale_factor)
        
        print(f"Image scaling: {total_width}×{total_height} → {display_width}×{display_height} (scale: {scale_factor:.2f})")
        
        # Create high-fidelity RGB image for LED pixel mapping
        # Use RGB mode for consistent color representation across platforms
        image = Image.new('RGB', (display_width, display_height), 'white')
        
        # Use high-quality drawing context for precise rendering
        draw = ImageDraw.Draw(image, 'RGB')  # Ensure RGB consistency
        
        # SURFACE-DIMENSION-BASED font scaling as per user requirements
        # User specification: 
        # - Absen 2.5mm @ 10m×10m surface = correct font size (reference)
        # - Absen 2.5mm @ 50m×50m surface = 50% smaller font than 10m surface
        
        # Calculate surface dimensions in meters (assuming 500mm = 0.5m panels for Absen)
        # This is an approximation - in real app, we'd need actual panel physical dimensions
        estimated_panel_width_m = 0.5  # Absen panels are typically 500mm = 0.5m wide
        surface_width_m = panels_width * estimated_panel_width_m
        surface_height_m = panels_height * estimated_panel_width_m  # Assume square panels
        
        # Use ORIGINAL panel pixel dimensions as base
        original_panel_size = min(panel_pixel_width, panel_pixel_height)
        
        # STEP-BY-STEP SCALING based on surface size:
        # Reference: 10m×10m surface (20×20 panels) = 100% font scale
        # Target: 50m×50m surface (100×100 panels) = 50% font scale
        
        reference_surface_size = 10.0  # 10m×10m reference surface
        current_surface_size = max(surface_width_m, surface_height_m)  # Use larger dimension
        
        if current_surface_size <= 10.0:
            # Small surfaces (up to 10m) - full size font
            surface_scale_factor = 0.08  # 8% for good visibility on small surfaces
            print(f"Small surface ({current_surface_size:.1f}m) - using full size font")
        elif current_surface_size <= 50.0:
            # Medium to large surfaces (10m to 50m) - scale down proportionally
            scale_ratio = 10.0 / current_surface_size  # 10m=1.0, 50m=0.2 (20% of original)
            surface_scale_factor = 0.08 * scale_ratio  # Scale from 8% down to smaller
            print(f"Large surface ({current_surface_size:.1f}m) - scaled font (ratio: {scale_ratio:.2f})")
        else:
            # Very large surfaces (50m+) - minimum font size
            surface_scale_factor = 0.016  # 2% for very large surfaces
            print(f"Very large surface ({current_surface_size:.1f}m) - minimum font size")
        
        # Calculate font size: panel pixel size × surface scale factor
        calculated_font_size = int(original_panel_size * surface_scale_factor)
        
        # Set reasonable bounds: minimum 4px, maximum 40px
        panel_font_size = max(4, min(40, calculated_font_size))
        
        print(f"Surface-based font scaling: {original_panel_size}px panel × {surface_scale_factor:.3f} = {panel_font_size}px font")
        
        # Load high-quality TrueType fonts with better error handling
        panel_font = None
        font_paths_to_try = []
        
        try:
            import platform
            system = platform.system()
            
            if system == "Darwin":  # macOS
                font_paths_to_try = [
                    "/System/Library/Fonts/Helvetica.ttc",
                    "/System/Library/Fonts/Arial.ttf", 
                    "/System/Library/Fonts/Arial Unicode.ttf"
                ]
            elif system == "Linux":  # Linux (Render.com)
                font_paths_to_try = [
                    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
                    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
                    "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
                    "/usr/share/fonts/truetype/liberation/LiberationSans.ttf",
                    "/usr/share/fonts/TTF/arial.ttf",
                    "/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf"
                ]
            else:  # Windows
                font_paths_to_try = [
                    "C:/Windows/Fonts/arial.ttf",
                    "C:/Windows/Fonts/calibri.ttf"
                ]
            
            # Try each font path until one works
            for font_path in font_paths_to_try:
                try:
                    panel_font = ImageFont.truetype(font_path, panel_font_size)
                    print(f"Successfully loaded font: {font_path}")
                    break
                except:
                    continue
                    
            if panel_font is None:
                print("All font paths failed, using default")
                panel_font = ImageFont.load_default()
                
        except Exception as e:
            print(f"Font loading error: {e}")
            panel_font = ImageFont.load_default()
        
        # Fill panels first (without borders)
        for row in range(panels_height):
            for col in range(panels_width):
                x = col * panel_display_width
                y = row * panel_display_height
                
                # Generate color for this panel
                panel_color = generate_color(col, row)
                
                # Draw panel rectangle filled with color (no outline)
                draw.rectangle([x, y, x + panel_display_width - 1, y + panel_display_height - 1], 
                             fill=panel_color, outline=None)
        
        # Draw precise 1px white grid lines for LED panel boundaries
        # Horizontal grid lines (separating rows)
        for row in range(panels_height + 1):
            y_pos = row * panel_display_height
            if y_pos < display_height:
                # Ensure exactly 1px line for grid precision
                draw.line([(0, y_pos), (display_width - 1, y_pos)], fill=(255, 255, 255), width=1)
        
        # Vertical grid lines (separating columns)
        for col in range(panels_width + 1):
            x_pos = col * panel_display_width
            if x_pos < display_width:
                # Ensure exactly 1px line for grid precision
                draw.line([(x_pos, 0), (x_pos, display_height - 1)], fill=(255, 255, 255), width=1)
        
        # Draw panel numbers with simple high contrast
        for row in range(panels_height):
            for col in range(panels_width):
                if show_panel_numbers:
                    x = col * panel_display_width
                    y = row * panel_display_height
                    
                    panel_number = f"{row + 1}.{col + 1}"
                    
                    # Smart margin calculation - proportional to font size, not panel size
                    # This ensures consistent text positioning regardless of canvas scale
                    margin = max(2, int(panel_font_size * 0.3))  # 30% of font size, minimum 2px
                    text_x = x + margin
                    text_y = y + margin
                    
                    # Draw simple black text - no background
                    if panel_font:
                        # Draw black text directly on panels
                        draw.text((text_x, text_y), panel_number, fill='black', font=panel_font)
                    else:
                        # Fallback without font - still black text
                        draw.text((text_x, text_y), panel_number, fill='black')
        
        # Generate NATIVE PNG with maximum quality and precision
        # No SVG conversion - direct PNG generation for Flutter
        img_buffer = io.BytesIO()
        
        # PNG-specific optimization for pixel-perfect accuracy
        # Use maximum quality settings for professional LED visualization
        pnginfo = None  # Remove any metadata that could affect quality
        
        # Save as uncompressed PNG for absolute pixel accuracy
        image.save(img_buffer, 
                  format='PNG', 
                  optimize=False,           # No size optimization that could affect quality
                  compress_level=0,         # No compression for maximum fidelity
                  pnginfo=pnginfo,         # No metadata interference
                  bits=8)                  # 8-bit per channel for standard compatibility
        
        img_buffer.seek(0)
        
        # Get pure PNG bytes - ready for Flutter without any conversion
        png_bytes = img_buffer.getvalue()
        png_base64 = base64.b64encode(png_bytes).decode()
        file_size_mb = len(png_bytes) / (1024 * 1024)
        
        # Verify PNG integrity (basic header check)
        png_signature = png_bytes[:8]
        expected_signature = b'\x89PNG\r\n\x1a\n'
        is_valid_png = png_signature == expected_signature
        
        # Create data URL for PNG
        image_data = f'data:image/png;base64,{png_base64}'
        
        return jsonify({
            'success': True,
            'image_base64': png_base64,
            'imageData': image_data,
            'dimensions': {
                'width': total_width,
                'height': total_height
            },
            'display_dimensions': {
                'width': display_width,
                'height': display_height
            },
            'scale_factor': scale_factor,
            'file_size_mb': round(file_size_mb, 4),
            'led_info': {
                'name': led_name,
                'panels': f'{panels_width}×{panels_height}',
                'resolution': f'{total_width}×{total_height}px',
                'display_resolution': f'{display_width}×{display_height}px'
            },
            'format': 'PNG',
            'png_quality': {
                'native_generation': True,
                'no_svg_conversion': True,
                'compression_level': 0,
                'bits_per_channel': 8,
                'valid_png_header': is_valid_png,
                'flutter_ready': True
            },
            'panel_info': {
                'total_panels': panels_width * panels_height,
                'show_numbers': show_panel_numbers,
                'show_grid': show_grid
            },
            'technical_specs': {
                'direct_png_generation': 'Pillow native PNG - no quality loss',
                'pixel_accuracy': 'Uncompressed for exact pixel representation',
                'flutter_compatibility': 'Ready for direct use without conversion',
                'rendering_engine': 'PIL/Pillow direct rasterization'
            },
            'note': f'Native PNG generated on Render.com - Original: {total_width}×{total_height}px (scaled 1:{scale_factor:.1f} for display) - Flutter ready without conversion'
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
