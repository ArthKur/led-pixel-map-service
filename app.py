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
        'version': '9.0 - Clean Design: No Transparency, Smaller Panel Numbers, Perfect 1px Grid',
        'message': 'Clean pixel maps with smaller panel numbers, precise grid lines, no transparency',
        'timestamp': '2025-08-04-04:00'
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
        panel_font_size = max(8, int(min(panel_display_width, panel_display_height) * 0.1))  # 10% of panel size (50% smaller)
        
        # Load TrueType fonts for sharp quality - only need panel font now
        panel_font = None
        try:
            import platform
            system = platform.system()
            
            if system == "Darwin":  # macOS
                panel_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttf", panel_font_size)
            elif system == "Linux":  # Linux (Render.com)
                try:
                    panel_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", panel_font_size)
                except:
                    try:
                        panel_font = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf", panel_font_size)
                    except:
                        panel_font = ImageFont.truetype("/usr/share/fonts/TTF/arial.ttf", panel_font_size)
            else:  # Windows or other
                panel_font = ImageFont.truetype("arial.ttf", panel_font_size)
        except Exception as e:
            print(f"Font loading failed: {e}, using default font")
            panel_font = ImageFont.load_default()
        
        # Generate panels with precise 1px white grid lines
        for row in range(panels_height):
            for col in range(panels_width):
                x = col * panel_display_width
                y = row * panel_display_height
                
                # Generate color for this panel
                panel_color = generate_color(col, row)
                
                # Draw panel rectangle filled with color
                draw.rectangle([x, y, x + panel_display_width, y + panel_display_height], 
                             fill=panel_color)
                
                # Draw panel number - smaller size, top-left with margin
                if show_panel_numbers:
                    panel_number = f"{row + 1}.{col + 1}"
                    
                    # Position in top-left corner with small margin
                    margin = max(4, int(panel_display_width * 0.06))  # 6% margin from edges
                    text_x = x + margin
                    text_y = y + margin
                    
                    # Draw panel numbers with black color for maximum contrast
                    if panel_font:
                        draw.text((text_x, text_y), panel_number, fill='black', font=panel_font)
                    else:
                        draw.text((text_x, text_y), panel_number, fill='black')
        
        # Draw precise 1px white grid lines
        for row in range(panels_height + 1):
            y = row * panel_display_height
            if y < display_height:
                draw.line([(0, y), (display_width, y)], fill='white', width=1)
        
        for col in range(panels_width + 1):
            x = col * panel_display_width
            if x < display_width:
                draw.line([(x, 0), (x, display_height)], fill='white', width=1)
        
        # Convert image to high-quality PNG bytes
        img_buffer = io.BytesIO()
        # Use high quality PNG settings for sharp text
        image.save(img_buffer, format='PNG', optimize=False, compress_level=1)
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
