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
        'version': '8.3 - Fixed: Thin Lines, Always Show Panel Numbers, 20% Transparency',
        'message': 'Service with guaranteed panel numbers, thin 1px grid lines, and 20% text transparency',
        'timestamp': '2025-08-04-03:30'
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
        
        # Calculate proper font sizes based on screen dimensions (not panel size)
        title_font_size = max(20, int(display_height * 0.20))    # 20% of screen height
        info_font_size = max(12, int(display_height * 0.05))     # 5% of screen height  
        panel_font_size = max(8, min(20, int(panel_display_width * 0.15)))  # 15% of panel width
        
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
                             fill=panel_color, outline='white', width=0)  # No border, we'll draw thin lines
                
                # Draw thin white grid lines manually for better control
                if x > 0:  # Vertical line (left edge)
                    draw.line([(x, y), (x, y + panel_display_height)], fill='white', width=1)
                if y > 0:  # Horizontal line (top edge)
                    draw.line([(x, y), (x + panel_display_width, y)], fill='white', width=1)
                
                # Draw panel number - ALWAYS show for ALL panels (remove size restrictions)
                if show_panel_numbers:
                    panel_number = f"{row + 1}.{col + 1}"
                    
                    # Position in top-left corner with small margin
                    margin = max(3, int(panel_display_width * 0.08))  # 8% margin from edges
                    text_x = x + margin
                    text_y = y + margin
                    
                    # Always draw panel numbers with white color for visibility
                    if panel_font:
                        draw.text((text_x, text_y), panel_number, fill='white', font=panel_font)
                    else:
                        draw.text((text_x, text_y), panel_number, fill='white')
        
        # Draw right and bottom borders to complete the grid
        draw.line([(display_width-1, 0), (display_width-1, display_height)], fill='white', width=1)  # Right edge
        draw.line([(0, display_height-1), (display_width, display_height-1)], fill='white', width=1)  # Bottom edge
        
        # Create semi-transparent overlay for text (20% transparency)
        # We'll create a separate layer for transparency effects
        text_overlay = Image.new('RGBA', (display_width, display_height), (0, 0, 0, 0))
        text_draw = ImageDraw.Draw(text_overlay)
        
        # Draw "Screen X" title in CENTER with 20% transparency (text only, no background)
        title_text = f"Screen {surface_index + 1}"
        if title_font:
            try:
                bbox = text_draw.textbbox((0, 0), title_text, font=title_font)
                text_width = bbox[2] - bbox[0]
                text_height = bbox[3] - bbox[1]
                title_x = (display_width - text_width) // 2
                title_y = (display_height - text_height) // 2
            except:
                title_x = display_width // 2 - (title_font_size * 3)
                title_y = display_height // 2 - (title_font_size // 2)
            
            # Draw semi-transparent gold text (20% opacity = 80% visible)
            text_draw.text((title_x, title_y), title_text, fill=(255, 215, 0, 204), font=title_font)
        else:
            # Simple center positioning with transparency
            title_x = display_width // 2 - 40
            title_y = display_height // 2 - 10
            text_draw.text((title_x, title_y), title_text, fill=(255, 215, 0, 204))
        
        # Draw info in BOTTOM LEFT corner with 20% transparency (text only, no background)
        info_text = f"{panels_width}×{panels_height} panels | {total_width}×{total_height}px"
        info_x = int(display_width * 0.02)  # 2% margin from left
        info_y = display_height - int(display_height * 0.08)  # 8% margin from bottom
        
        if info_font:
            # Draw semi-transparent white text (20% opacity = 80% visible)
            text_draw.text((info_x, info_y), info_text, fill=(255, 255, 255, 204), font=info_font)
        else:
            # Simple positioning with transparency
            text_draw.text((info_x, info_y), info_text, fill=(255, 255, 255, 204))
        
        # Composite the text overlay onto the main image
        image = Image.alpha_composite(image.convert('RGBA'), text_overlay).convert('RGB')
        
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
