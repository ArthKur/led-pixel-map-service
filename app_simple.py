from flask import Flask, request, jsonify
from flask_cors import CORS
import base64
import io
from PIL import Image, ImageDraw, ImageFont
import os

app = Flask(__name__)
CORS(app)

@app.route('/')
def health_check():
    return jsonify({
        'service': 'LED Pixel Map Cloud Renderer',
        'status': 'healthy',
        'version': '2.0'
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
        panels_width = surface.get('panelsWidth', 10)
        panels_height = surface.get('fullPanelsHeight', 5)
        panel_pixel_width = surface.get('panelPixelWidth', 200)
        panel_pixel_height = surface.get('panelPixelHeight', 200)
        
        # Calculate total dimensions
        total_width = panels_width * panel_pixel_width
        total_height = panels_height * panel_pixel_height
        
        # Create image (scale down if too large for memory)
        max_dimension = 8000
        scale_factor = 1
        if total_width > max_dimension or total_height > max_dimension:
            scale_factor = max_dimension / max(total_width, total_height)
            display_width = int(total_width * scale_factor)
            display_height = int(total_height * scale_factor)
        else:
            display_width = total_width
            display_height = total_height
        
        # Create image
        img = Image.new('RGB', (display_width, display_height), (20, 20, 20))
        draw = ImageDraw.Draw(img)
        
        # Draw simple grid
        scaled_panel_width = int(panel_pixel_width * scale_factor)
        scaled_panel_height = int(panel_pixel_height * scale_factor)
        
        for x in range(0, display_width, scaled_panel_width):
            draw.line([(x, 0), (x, display_height)], fill=(60, 60, 60), width=1)
        
        for y in range(0, display_height, scaled_panel_height):
            draw.line([(0, y), (display_width, y)], fill=(60, 60, 60), width=1)
        
        # Convert to base64
        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        img_str = base64.b64encode(buffer.getvalue()).decode()
        
        # Calculate file size
        file_size_mb = len(buffer.getvalue()) / (1024 * 1024)
        
        return jsonify({
            'success': True,
            'imageData': f'data:image/png;base64,{img_str}',
            'dimensions': {
                'width': total_width,
                'height': total_height,
                'displayWidth': display_width,
                'displayHeight': display_height
            },
            'file_size_mb': round(file_size_mb, 2),
            'scale_factor': scale_factor
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
