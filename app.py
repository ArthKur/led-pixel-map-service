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
    """Generate a consistent color for each panel based on position"""
    # Simple color generation using basic math
    colors = [
        (255, 107, 107), (78, 205, 196), (69, 183, 209), (150, 206, 180), (255, 234, 167),
        (221, 160, 221), (152, 216, 200), (247, 220, 111), (187, 143, 206), (133, 193, 233),
        (248, 196, 113), (130, 224, 170), (241, 148, 138), (133, 193, 233), (244, 208, 63)
    ]
    
    # Pick color based on position
    color_index = (panel_x * 3 + panel_y * 7) % len(colors)
    return colors[color_index]

@app.route('/')
def health_check():
    return jsonify({
        'service': 'LED Pixel Map Cloud Renderer',
        'status': 'healthy',
        'version': '9.1 - Ultra Quality: Perfect 1px Grid, Crystal Text, Anti-aliasing',
        'message': 'Ultra high quality with pixel-perfect grid lines and crystal clear text',
        'timestamp': '2025-08-04-04:15'
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
        # Scale down if too large to keep file size reasonable
        max_display_width = 4000
        max_display_height = 2400
        scale_factor = 1
        
        if total_width > max_display_width or total_height > max_display_height:
            scale_x = total_width / max_display_width
            scale_y = total_height / max_display_height
            scale_factor = max(scale_x, scale_y)
        
        display_width = int(total_width / scale_factor)
        display_height = int(total_height / scale_factor)
        panel_display_width = int(panel_pixel_width / scale_factor)
        panel_display_height = int(panel_pixel_height / scale_factor)
        
                # Create Image with white background
        image = Image.new('RGB', (display_width, display_height), 'white')
        draw = ImageDraw.Draw(image)
        
        # Calculate font sizes - smaller panel numbers, no transparency texts
        panel_font_size = max(12, int(min(panel_display_width, panel_display_height) * 0.08))  # 8% of panel size, minimum 12px
        
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
        
        # Create high-quality image with anti-aliasing
        image = Image.new('RGB', (display_width, display_height), 'white')
        draw = ImageDraw.Draw(image, 'RGBA')  # Enable anti-aliasing
        
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
        
        # Draw ultra-precise 1px white grid lines on top
        # Horizontal lines
        for row in range(panels_height + 1):
            y_pos = row * panel_display_height
            if y_pos < display_height:
                for x in range(display_width):
                    if y_pos < display_height:
                        draw.point((x, y_pos), fill='white')
        
        # Vertical lines  
        for col in range(panels_width + 1):
            x_pos = col * panel_display_width
            if x_pos < display_width:
                for y in range(display_height):
                    if x_pos < display_width:
                        draw.point((x_pos, y), fill='white')
        
        # Draw panel numbers with high quality
        for row in range(panels_height):
            for col in range(panels_width):
                if show_panel_numbers:
                    x = col * panel_display_width
                    y = row * panel_display_height
                    
                    panel_number = f"{row + 1}.{col + 1}"
                    
                    # Position in top-left corner with margin
                    margin = max(6, int(panel_display_width * 0.04))  # 4% margin
                    text_x = x + margin
                    text_y = y + margin
                    
                    # Draw with high contrast
                    if panel_font:
                        # Draw white outline for better visibility
                        for dx in [-1, 0, 1]:
                            for dy in [-1, 0, 1]:
                                if dx != 0 or dy != 0:
                                    draw.text((text_x + dx, text_y + dy), panel_number, fill='white', font=panel_font)
                        # Draw black text on top
                        draw.text((text_x, text_y), panel_number, fill='black', font=panel_font)
                    else:
                        draw.text((text_x, text_y), panel_number, fill='black')
        
        # Convert to RGB and save with maximum quality PNG
        if image.mode != 'RGB':
            image = image.convert('RGB')
            
        img_buffer = io.BytesIO()
        # Maximum quality PNG settings - no compression for sharpest text
        image.save(img_buffer, format='PNG', optimize=False, compress_level=0, pnginfo=None)
        img_buffer.seek(0)
        
        # Get PNG data
        png_bytes = img_buffer.getvalue()
        png_base64 = base64.b64encode(png_bytes).decode()
        file_size_mb = len(png_bytes) / (1024 * 1024)
        
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
            'panel_info': {
                'total_panels': panels_width * panels_height,
                'show_numbers': show_panel_numbers,
                'show_grid': show_grid
            },
            'note': f'Generated true PNG LED pixel map with colorful panels and numbers - Original: {total_width}×{total_height}px (scaled 1:{scale_factor:.1f} for display)'
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
