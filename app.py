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
        'version': '7.0 - True PNG Generation with Pillow',
        'message': 'Service generating actual PNG files using Pillow library',
        'timestamp': '2025-08-04-01:00'
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
        
        # Add space for title and info
        title_height = 120
        image_height = display_height + title_height
        
        # Create actual PNG image using Pillow
        image = Image.new('RGB', (display_width, image_height), color='black')
        draw = ImageDraw.Draw(image)
        
        # Try to load a default font, fallback to basic if not available
        try:
            # Use default font - this should work on most systems
            font_large = ImageFont.load_default()
            font_medium = ImageFont.load_default()
            font_small = ImageFont.load_default()
        except Exception:
            # If all else fails, use None (will use basic font)
            font_large = None
            font_medium = None
            font_small = None
        
        # Draw title background (gold border)
        title_box_width = min(400, display_width - 20)
        draw.rectangle([10, 10, 10 + title_box_width, 60], 
                      fill='black', outline='gold', width=2)
        
        # Draw title text
        title_text = f"Screen {surface_index + 1}"
        if font_large:
            draw.text((20, 25), title_text, fill='gold', font=font_large)
        else:
            draw.text((20, 25), title_text, fill='gold')
        
        # Draw LED info background
        info_box_width = min(500, display_width - 20)
        draw.rectangle([10, 70, 10 + info_box_width, 110], 
                      fill='black', outline='gold', width=1)
        
        # Draw LED info text
        info_text = f"{led_name} | {panels_width}×{panels_height} panels | {total_width}×{total_height}px"
        if font_medium:
            draw.text((20, 82), info_text, fill='white', font=font_medium)
        else:
            draw.text((20, 82), info_text, fill='white')
        
        # Generate panels with colors and numbers
        for row in range(panels_height):
            for col in range(panels_width):
                x = col * panel_display_width
                y = title_height + row * panel_display_height
                
                # Generate color for this panel
                panel_color = generate_color(col, row)
                
                # Draw panel rectangle
                draw.rectangle([x, y, x + panel_display_width, y + panel_display_height], 
                             fill=panel_color, outline='#333333', width=1)
                
                # Draw panel number if enabled and panel is large enough
                if show_panel_numbers and panel_display_width > 30 and panel_display_height > 20:
                    text_x = x + panel_display_width // 2
                    text_y = y + panel_display_height // 2 - 6
                    panel_number = f"{row + 1}.{col + 1}"
                    
                    # Calculate text position for centering
                    if font_small:
                        # Get text dimensions for better centering
                        try:
                            bbox = draw.textbbox((0, 0), panel_number, font=font_small)
                            text_width = bbox[2] - bbox[0]
                            text_height = bbox[3] - bbox[1]
                            text_x = x + (panel_display_width - text_width) // 2
                            text_y = y + (panel_display_height - text_height) // 2
                        except:
                            # Fallback to simple centering
                            text_x = x + panel_display_width // 2 - 10
                            text_y = y + panel_display_height // 2 - 6
                        
                        draw.text((text_x, text_y), panel_number, fill='black', font=font_small)
                    else:
                        # Basic positioning without font
                        text_x = x + panel_display_width // 2 - 10
                        text_y = y + panel_display_height // 2 - 6
                        draw.text((text_x, text_y), panel_number, fill='black')
        
        # Convert image to PNG bytes
        img_buffer = io.BytesIO()
        image.save(img_buffer, format='PNG', optimize=True)
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
                'height': image_height
            },
            'scale_factor': scale_factor,
            'file_size_mb': round(file_size_mb, 4),
            'led_info': {
                'name': led_name,
                'panels': f'{panels_width}×{panels_height}',
                'resolution': f'{total_width}×{total_height}px',
                'display_resolution': f'{display_width}×{image_height}px'
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
