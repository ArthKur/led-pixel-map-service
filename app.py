from flask import Flask, request, jsonify
from flask_cors import CORS
import base64
import os
import io
from PIL import Image, ImageDraw, ImageFont

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
        'version': '6.0 - Pure PNG Generation',
        'message': 'Service generating actual PNG files using Pillow with simple fonts',
        'timestamp': '2025-08-04-00:25'
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
        
        # Generate actual PNG using Pillow
        display_width = int(total_width / scale_factor)
        display_height = int(total_height / scale_factor)
        panel_display_width = int(panel_pixel_width / scale_factor)
        panel_display_height = int(panel_pixel_height / scale_factor)
        
        # Add space for title and info
        title_height = 120
        image_height = display_height + title_height
        
        # Create PNG image
        image = Image.new('RGB', (display_width, image_height), color='black')
        draw = ImageDraw.Draw(image)
        
        # Use default font (no external font loading to avoid build issues)
        try:
            font_large = ImageFont.load_default()
            font_medium = ImageFont.load_default()
            font_small = ImageFont.load_default()
        except:
            font_large = None
            font_medium = None
            font_small = None
        
        # Draw title background and text
        draw.rectangle([10, 10, min(400, display_width-20), 60], 
                      fill='black', outline='gold', width=2)
        draw.text((20, 25), f"Screen {surface_index + 1}", 
                 fill='gold', font=font_large)
        
        # Draw LED info background and text
        draw.rectangle([10, 70, min(500, display_width-20), 110], 
                      fill='black', outline='gold', width=1)
        info_text = f"{led_name} | {panels_width}×{panels_height} panels | {total_width}×{total_height}px"
        draw.text((20, 82), info_text, fill='white', font=font_medium)
        
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
                    text_y = y + panel_display_height // 2
                    panel_number = f"{row + 1}.{col + 1}"
                    
                    # Draw text with simple centering
                    draw.text((text_x - 10, text_y - 6), panel_number, 
                             fill='black', font=font_small)
        
        # Convert to PNG bytes
        img_buffer = io.BytesIO()
        image.save(img_buffer, format='PNG')
        img_buffer.seek(0)
        
        png_base64 = base64.b64encode(img_buffer.getvalue()).decode()
        file_size_mb = len(img_buffer.getvalue()) / (1024 * 1024)
        
        format_type = 'PNG'
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
            'format': format_type,
            'panel_info': {
                'total_panels': panels_width * panels_height,
                'show_numbers': show_panel_numbers,
                'show_grid': show_grid
            },
            'note': f'Generated true {format_type} LED pixel map with colorful panels and numbers - Original: {total_width}×{total_height}px (scaled 1:{scale_factor:.1f} for display)'
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
