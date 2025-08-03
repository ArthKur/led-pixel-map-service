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
        'version': '8.1 - Sharp Text Rendering with TrueType Fonts',
        'message': 'Service generating PNG files with crisp text, proper font sizing, and anti-aliasing',
        'timestamp': '2025-08-04-02:30'
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
        
        # Create clean image with ONLY panels (no black top area)
        image = Image.new('RGB', (display_width, display_height), color='black')
        draw = ImageDraw.Draw(image)
        
        # Calculate proper font sizes based on display dimensions for sharp text
        title_font_size = max(16, min(48, display_width // 50))  # Scale font with image size
        info_font_size = max(10, min(24, display_width // 80))   # Smaller font for info
        panel_font_size = max(8, min(16, panel_display_width // 15))  # Panel number font
        
        # Try to load fonts with calculated sizes - use truetype for sharp rendering
        try:
            # Try to load system fonts for better quality
            import platform
            system = platform.system()
            
            if system == "Darwin":  # macOS
                title_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", title_font_size)
                info_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", info_font_size)
                panel_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", panel_font_size)
            elif system == "Linux":  # Linux/Render.com
                # Try common Linux font paths
                try:
                    title_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", title_font_size)
                    info_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", info_font_size)
                    panel_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", panel_font_size)
                except:
                    # Fallback to other common paths
                    title_font = ImageFont.truetype("/usr/share/fonts/TTF/arial.ttf", title_font_size)
                    info_font = ImageFont.truetype("/usr/share/fonts/TTF/arial.ttf", info_font_size)
                    panel_font = ImageFont.truetype("/usr/share/fonts/TTF/arial.ttf", panel_font_size)
            else:  # Windows or other
                title_font = ImageFont.truetype("arial.ttf", title_font_size)
                info_font = ImageFont.truetype("arial.ttf", info_font_size)
                panel_font = ImageFont.truetype("arial.ttf", panel_font_size)
        except Exception as e:
            print(f"Font loading failed: {e}, using default fonts")
            # Fallback to default fonts but with size hints
            title_font = ImageFont.load_default()
            info_font = ImageFont.load_default()
            panel_font = ImageFont.load_default()
        
        # Generate panels with thin white borders and colorful fills
        for row in range(panels_height):
            for col in range(panels_width):
                x = col * panel_display_width
                y = row * panel_display_height
                
                # Generate color for this panel
                panel_color = generate_color(col, row)
                
                # Draw panel rectangle with thin white border (0.5px effect)
                draw.rectangle([x, y, x + panel_display_width, y + panel_display_height], 
                             fill=panel_color, outline='white', width=1)
                
                # Draw panel number if enabled and panel is large enough
                if show_panel_numbers and panel_display_width > 30 and panel_display_height > 20:
                    text_x = x + panel_display_width // 2
                    text_y = y + panel_display_height // 2 - 6
                    panel_number = f"{row + 1}.{col + 1}"
                    
                    # Calculate text position for centering with sharp font
                    if panel_font:
                        # Get text dimensions for better centering
                        try:
                            bbox = draw.textbbox((0, 0), panel_number, font=panel_font)
                            text_width = bbox[2] - bbox[0]
                            text_height = bbox[3] - bbox[1]
                            text_x = x + (panel_display_width - text_width) // 2
                            text_y = y + (panel_display_height - text_height) // 2
                        except:
                            # Fallback to simple centering
                            text_x = x + panel_display_width // 2 - 10
                            text_y = y + panel_display_height // 2 - 6
                        
                        draw.text((text_x, text_y), panel_number, fill='black', font=panel_font)
                    else:
                        # Basic positioning without font
                        text_x = x + panel_display_width // 2 - 10
                        text_y = y + panel_display_height // 2 - 6
                        draw.text((text_x, text_y), panel_number, fill='black')
        
        # Draw "Screen X" title in CENTER of canvas with sharp font
        title_text = f"Screen {surface_index + 1}"
        if title_font:
            try:
                bbox = draw.textbbox((0, 0), title_text, font=title_font)
                text_width = bbox[2] - bbox[0]
                text_height = bbox[3] - bbox[1]
                title_x = (display_width - text_width) // 2
                title_y = (display_height - text_height) // 2
            except:
                title_x = display_width // 2 - 40
                title_y = display_height // 2 - 10
            
            # Draw title with dark background for visibility
            draw.rectangle([title_x - 10, title_y - 5, title_x + text_width + 10, title_y + text_height + 5], 
                          fill=(30, 30, 30))  # Dark gray background
            draw.text((title_x, title_y), title_text, fill='gold', font=title_font)
        else:
            # Simple center positioning
            title_x = display_width // 2 - 40
            title_y = display_height // 2 - 10
            draw.rectangle([title_x - 10, title_y - 5, title_x + 80, title_y + 20], 
                          fill=(30, 30, 30))
            draw.text((title_x, title_y), title_text, fill='gold')
        
        # Draw info in BOTTOM LEFT corner with sharp font
        info_text = f"{panels_width}×{panels_height} panels | {total_width}×{total_height}px"
        info_x = 10
        info_y = display_height - 25
        
        if info_font:
            try:
                bbox = draw.textbbox((0, 0), info_text, font=info_font)
                text_width = bbox[2] - bbox[0]
                text_height = bbox[3] - bbox[1]
            except:
                text_width = len(info_text) * 6
                text_height = 15
            
            # Draw info with dark background
            draw.rectangle([info_x - 5, info_y - 5, info_x + text_width + 5, info_y + text_height + 5], 
                          fill=(30, 30, 30))  # Dark gray background
            draw.text((info_x, info_y), info_text, fill='white', font=info_font)
        else:
            # Simple positioning
            draw.rectangle([info_x - 5, info_y - 5, info_x + 200, info_y + 15], 
                          fill=(30, 30, 30))
            draw.text((info_x, info_y), info_text, fill='white')
        
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
