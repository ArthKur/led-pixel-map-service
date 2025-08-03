from flask import Flask, request, jsonify
from flask_cors import CORS
import base64
import os

app = Flask(__name__)
CORS(app)

@app.route('/')
def health_check():
    return jsonify({
        'service': 'LED Pixel Map Cloud Renderer',
        'status': 'healthy',
        'version': '3.0',
        'message': 'Service is running without PIL dependency',
        'timestamp': '2025-08-03-23:45'
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
        
        # Generate a simple SVG instead of PIL image
        svg_content = f'''<svg width="{total_width}" height="{total_height}" xmlns="http://www.w3.org/2000/svg">
            <rect width="{total_width}" height="{total_height}" fill="#141414"/>
            <defs>
                <pattern id="grid" width="{panel_pixel_width}" height="{panel_pixel_height}" patternUnits="userSpaceOnUse">
                    <rect width="{panel_pixel_width}" height="{panel_pixel_height}" fill="none" stroke="#3c3c3c" stroke-width="1"/>
                </pattern>
            </defs>
            <rect width="{total_width}" height="{total_height}" fill="url(#grid)"/>
            <text x="50" y="50" fill="white" font-family="Arial" font-size="24">
                LED Panel Grid: {panels_width}×{panels_height} panels
            </text>
            <text x="50" y="80" fill="white" font-family="Arial" font-size="16">
                Total Resolution: {total_width}×{total_height} pixels
            </text>
        </svg>'''
        
        # Convert SVG to base64
        svg_base64 = base64.b64encode(svg_content.encode()).decode()
        
        # Estimate file size
        file_size_mb = len(svg_content) / (1024 * 1024)
        
        return jsonify({
            'success': True,
            'image_base64': svg_base64,  # Changed from 'imageData' to 'image_base64'
            'imageData': f'data:image/svg+xml;base64,{svg_base64}',  # Keep both for compatibility
            'dimensions': {
                'width': total_width,
                'height': total_height
            },
            'file_size_mb': round(file_size_mb, 3),
            'led_info': {
                'name': surface.get('ledName', 'Unknown LED'),
                'panels': f'{panels_width}×{panels_height}',
                'resolution': f'{total_width}×{total_height}px'
            },
            'format': 'SVG',
            'note': 'Generated without PIL dependency - using SVG format'
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
