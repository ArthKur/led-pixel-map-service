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
        'version': '3.1',
        'message': 'Service is running without PIL dependency - Cleaned deployment',
        'timestamp': '2025-08-04-00:15'
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
        
        # Generate SVG with proper pixel map grid
        svg_content = f'''<svg width="{total_width}" height="{total_height}" xmlns="http://www.w3.org/2000/svg">
            <!-- Dark background -->
            <rect width="{total_width}" height="{total_height}" fill="#141414"/>
            
            <!-- Panel grid lines -->
            <defs>
                <pattern id="panelGrid" width="{panel_pixel_width}" height="{panel_pixel_height}" patternUnits="userSpaceOnUse">
                    <rect width="{panel_pixel_width}" height="{panel_pixel_height}" fill="none" stroke="#FFD700" stroke-width="2"/>
                </pattern>
                <pattern id="pixelGrid" width="10" height="10" patternUnits="userSpaceOnUse">
                    <rect width="10" height="10" fill="none" stroke="#3c3c3c" stroke-width="0.5"/>
                </pattern>
            </defs>
            
            <!-- Pixel grid -->
            <rect width="{total_width}" height="{total_height}" fill="url(#pixelGrid)"/>
            
            <!-- Panel boundaries -->
            <rect width="{total_width}" height="{total_height}" fill="url(#panelGrid)"/>
            
            <!-- Info text -->
            <text x="20" y="40" fill="white" font-family="Arial, sans-serif" font-size="24" font-weight="bold">
                LED Panel Grid: {panels_width}×{panels_height} panels
            </text>
            <text x="20" y="70" fill="white" font-family="Arial, sans-serif" font-size="18">
                Resolution: {total_width}×{total_height} pixels
            </text>
            <text x="20" y="95" fill="white" font-family="Arial, sans-serif" font-size="16">
                LED: {surface.get('ledName', 'Unknown LED')}
            </text>
            <text x="20" y="115" fill="white" font-family="Arial, sans-serif" font-size="14">
                Panel Size: {panel_pixel_width}×{panel_pixel_height}px each
            </text>
        </svg>'''
        
        # Convert SVG to base64
        svg_base64 = base64.b64encode(svg_content.encode()).decode()
        
        # Estimate file size
        file_size_mb = len(svg_content) / (1024 * 1024)
        
        return jsonify({
            'success': True,
            'image_base64': svg_base64,  # SVG base64 for now
            'imageData': f'data:image/svg+xml;base64,{svg_base64}',  # SVG format
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
            'note': 'Generated without PIL dependency - using SVG format with proper grid'
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
