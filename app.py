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
    # Use position to create varied but consistent colors
    hue = (panel_x * 17 + panel_y * 23) % 360
    saturation = 60 + (panel_x * panel_y) % 40  # 60-100%
    lightness = 45 + (panel_x + panel_y) % 30   # 45-75%
    
    # Convert HSL to RGB (simplified)
    h = hue / 360.0
    s = saturation / 100.0
    l = lightness / 100.0
    
    def hsl_to_rgb(h, s, l):
        if s == 0:
            r = g = b = l
        else:
            def hue_to_rgb(p, q, t):
                if t < 0: t += 1
                if t > 1: t -= 1
                if t < 1/6: return p + (q - p) * 6 * t
                if t < 1/2: return q
                if t < 2/3: return p + (q - p) * (2/3 - t) * 6
                return p
            
            q = l * (1 + s) if l < 0.5 else l + s - l * s
            p = 2 * l - q
            r = hue_to_rgb(p, q, h + 1/3)
            g = hue_to_rgb(p, q, h)
            b = hue_to_rgb(p, q, h - 1/3)
    
    r, g, b = hsl_to_rgb(h, s, l)
    return (int(r*255), int(g*255), int(b*255))

@app.route('/')
def health_check():
    return jsonify({
        'service': 'LED Pixel Map Cloud Renderer',
        'status': 'healthy',
        'version': '4.0 - PNG Edition',
        'message': 'Service is running with PIL for PNG generation',
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
        
        # Add space for title and info
        title_height = 120
        image_height = display_height + title_height
        
        # Create PNG image using PIL
        image = Image.new('RGB', (display_width, image_height), color='black')
        draw = ImageDraw.Draw(image)
        
        try:
            # Try to load a font, fallback to default if not available
            title_font = ImageFont.truetype("arial.ttf", 20)
            info_font = ImageFont.truetype("arial.ttf", 12)
            panel_font = ImageFont.truetype("arial.ttf", min(12, panel_display_width // 8))
        except:
            title_font = ImageFont.load_default()
            info_font = ImageFont.load_default()
            panel_font = ImageFont.load_default()
        
        # Draw title background and text
        draw.rectangle([10, 10, min(400, display_width-20), 60], 
                      fill='black', outline='gold', width=2)
        draw.text((20, 25), f"Screen {surface_index + 1}", 
                 fill='gold', font=title_font)
        
        # Draw LED info background and text
        draw.rectangle([10, 70, min(500, display_width-20), 110], 
                      fill='black', outline='gold', width=1)
        info_text = f"{led_name} | {panels_width}×{panels_height} panels | {total_width}×{total_height}px"
        draw.text((20, 82), info_text, fill='white', font=info_font)
        
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
                    
                    # Get text bounding box for centering
                    bbox = draw.textbbox((0, 0), panel_number, font=panel_font)
                    text_width = bbox[2] - bbox[0]
                    text_height = bbox[3] - bbox[1]
                    
                    draw.text((text_x - text_width//2, text_y - text_height//2), 
                             panel_number, fill='black', font=panel_font)
        
        # Convert to base64
        img_buffer = io.BytesIO()
        image.save(img_buffer, format='PNG', optimize=True)
        img_buffer.seek(0)
        
        png_base64 = base64.b64encode(img_buffer.getvalue()).decode()
        file_size_mb = len(img_buffer.getvalue()) / (1024 * 1024)
        
        return jsonify({
            'success': True,
            'image_base64': png_base64,
            'imageData': f'data:image/png;base64,{png_base64}',
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
            'note': f'Generated PNG LED pixel map with colorful panels and numbers - Original: {total_width}×{total_height}px (scaled 1:{scale_factor:.1f} for display)'
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
