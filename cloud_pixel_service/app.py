from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import io
import base64
import json
from PIL import Image, ImageDraw, ImageFont
import os
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter web app

# Panel colors (matching your Flutter app)
PANEL_COLORS = [
    (45, 27, 105),    # Deep purple
    (27, 94, 32),     # Deep green
    (13, 71, 161),    # Deep blue
    (230, 81, 0),     # Deep orange
    (191, 54, 12),    # Deep red
    (74, 20, 140),    # Deep violet
]

@app.route('/')
def health_check():
    return jsonify({
        'status': 'healthy',
        'service': 'LED Pixel Map Cloud Renderer',
        'version': '1.0.0',
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/generate-pixel-map', methods=['POST'])
def generate_pixel_map():
    try:
        data = request.get_json()
        
        # Extract parameters
        surface_data = data.get('surface', {})
        config = data.get('config', {})
        
        # Required parameters
        panels_width = surface_data.get('panelsWidth', 5)
        full_panels_height = surface_data.get('fullPanelsHeight', 3)
        half_panels_height = surface_data.get('halfPanelsHeight', 0)
        panel_pixel_width = surface_data.get('panelPixelWidth', 200)
        panel_pixel_height = surface_data.get('panelPixelHeight', 200)
        
        # Optional parameters
        surface_index = config.get('surfaceIndex', 0)
        led_name = surface_data.get('ledName', 'Unknown LED')
        show_grid = config.get('showGrid', True)
        show_panel_numbers = config.get('showPanelNumbers', True)
        
        # Calculate total dimensions
        total_width = panels_width * panel_pixel_width
        total_height = (full_panels_height + half_panels_height) * panel_pixel_height
        
        logger.info(f"Generating pixel map: {total_width}×{total_height}px ({panels_width}×{full_panels_height + half_panels_height} panels)")
        logger.info(f"LED: {led_name}, Panel size: {panel_pixel_width}×{panel_pixel_height}px")
        
        # Create the image
        image = Image.new('RGB', (total_width, total_height), color='black')
        draw = ImageDraw.Draw(image)
        
        # Draw panels
        current_y = 0
        global_row = 0
        
        # Draw full panels
        for full_row in range(full_panels_height):
            _draw_panel_row(
                draw, panels_width, global_row, current_y,
                panel_pixel_width, panel_pixel_height,
                show_grid, show_panel_numbers
            )
            current_y += panel_pixel_height
            global_row += 1
        
        # Draw half panels (same pixel size as full panels)
        for half_row in range(half_panels_height):
            _draw_panel_row(
                draw, panels_width, global_row, current_y,
                panel_pixel_width, panel_pixel_height,
                show_grid, show_panel_numbers
            )
            current_y += panel_pixel_height
            global_row += 1
        
        # Draw info overlay
        if show_panel_numbers:
            _draw_info_overlay(
                draw, image, surface_index, led_name, 
                panels_width, full_panels_height + half_panels_height,
                panel_pixel_width, panel_pixel_height
            )
        
        # Convert to base64
        img_buffer = io.BytesIO()
        image.save(img_buffer, format='PNG', optimize=True)
        img_base64 = base64.b64encode(img_buffer.getvalue()).decode('utf-8')
        
        # Calculate file size
        file_size_mb = len(img_buffer.getvalue()) / (1024 * 1024)
        
        logger.info(f"Generated successfully: {total_width}×{total_height}px, {file_size_mb:.2f}MB")
        
        return jsonify({
            'success': True,
            'image_base64': img_base64,
            'dimensions': {
                'width': total_width,
                'height': total_height,
                'panels_width': panels_width,
                'panels_height': full_panels_height + half_panels_height
            },
            'file_size_mb': round(file_size_mb, 2),
            'led_info': {
                'name': led_name,
                'panel_pixels': f"{panel_pixel_width}×{panel_pixel_height}"
            }
        })
        
    except Exception as e:
        logger.error(f"Error generating pixel map: {str(e)}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

def _draw_panel_row(draw, panels_width, global_row, current_y, 
                   panel_width, panel_height, show_grid, show_panel_numbers):
    """Draw a row of panels"""
    for col in range(panels_width):
        # Calculate panel position
        x = col * panel_width
        y = current_y
        
        # Select panel color
        color_index = (global_row + col) % len(PANEL_COLORS)
        panel_color = PANEL_COLORS[color_index]
        
        # Draw panel background
        draw.rectangle(
            [x, y, x + panel_width - 1, y + panel_height - 1],
            fill=panel_color
        )
        
        # Draw grid if enabled
        if show_grid and panel_width > 4 and panel_height > 4:
            # White grid lines
            draw.rectangle(
                [x, y, x + panel_width - 1, y + panel_height - 1],
                outline=(255, 255, 255, 153),  # Semi-transparent white
                width=1
            )
        
        # Draw panel numbers if enabled and space allows
        if show_panel_numbers and panel_width > 40 and panel_height > 30:
            text = f"{global_row + 1}.{col + 1}"
            
            # Calculate font size based on panel size
            font_size = max(8, min(panel_width // 8, panel_height // 6))
            
            try:
                # Try to use a default font, fallback to basic if not available
                font = ImageFont.load_default()
            except:
                font = None
            
            # Calculate text position (top-left with padding)
            text_x = x + 4
            text_y = y + 4
            
            # Draw text with shadow for better visibility
            if font:
                # Shadow
                draw.text((text_x + 1, text_y + 1), text, fill=(0, 0, 0), font=font)
                # Main text
                draw.text((text_x, text_y), text, fill=(255, 255, 255, 204), font=font)
            else:
                # Fallback without font
                draw.text((text_x + 1, text_y + 1), text, fill=(0, 0, 0))
                draw.text((text_x, text_y), text, fill=(255, 255, 255))

def _draw_info_overlay(draw, image, surface_index, led_name, 
                      panels_width, panels_height, panel_pixel_width, panel_pixel_height):
    """Draw information overlay on the image"""
    width, height = image.size
    
    # Surface info
    surface_info = f"Surface {surface_index + 1} | {led_name} | {panels_width}×{panels_height} panels | {panel_pixel_width}×{panel_pixel_height}px per panel"
    pixel_info = f"{width}×{height}px"
    
    try:
        font = ImageFont.load_default()
    except:
        font = None
    
    # Draw surface info at top-left
    if len(surface_info) * 8 < width - 40:  # Rough character width check
        # Shadow
        draw.text((21, 21), surface_info, fill=(0, 0, 0), font=font)
        # Main text
        draw.text((20, 20), surface_info, fill=(255, 255, 255, 230), font=font)
    
    # Draw pixel info at bottom-right
    if font:
        # Get text size for positioning
        try:
            bbox = draw.textbbox((0, 0), pixel_info, font=font)
            text_width = bbox[2] - bbox[0]
            text_height = bbox[3] - bbox[1]
        except:
            # Fallback for older PIL versions
            text_width = len(pixel_info) * 8
            text_height = 12
    else:
        text_width = len(pixel_info) * 8
        text_height = 12
    
    text_x = width - text_width - 20
    text_y = height - text_height - 20
    
    if text_x > 0 and text_y > 0:
        # Shadow
        draw.text((text_x + 1, text_y + 1), pixel_info, fill=(0, 0, 0), font=font)
        # Main text
        draw.text((text_x, text_y), pixel_info, fill=(255, 255, 255, 204), font=font)

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
