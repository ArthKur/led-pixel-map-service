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
        
        # Generate PNG using SVG first (will convert to proper image later)
        # Create colorful grid pattern similar to your reference image
        colors = [
            '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7',
            '#DDA0DD', '#98D8C8', '#F7DC6F', '#BB8FCE', '#85C1E9',
            '#F8C471', '#82E0AA', '#F1948A', '#85C1E9', '#F4D03F'
        ]
        
        svg_content = f'''<svg width="{display_width}" height="{display_height}" xmlns="http://www.w3.org/2000/svg">
            <!-- Background -->
            <rect width="{display_width}" height="{display_height}" fill="#000000"/>
            
            <!-- Surface title -->
            <rect x="10" y="10" width="{min(400, display_width-20)}" height="50" fill="rgba(0,0,0,0.8)" stroke="#FFD700" stroke-width="2"/>
            <text x="20" y="35" fill="#FFD700" font-family="Arial, sans-serif" font-size="20" font-weight="bold">
                Screen {surface_index + 1}
            </text>
            
            <!-- LED Info -->
            <rect x="10" y="70" width="{min(500, display_width-20)}" height="40" fill="rgba(0,0,0,0.8)" stroke="#FFD700" stroke-width="1"/>
            <text x="20" y="90" fill="white" font-family="Arial, sans-serif" font-size="12">
                {led_name} | {panels_width}×{panels_height} panels | {total_width}×{total_height}px
            </text>
'''

        # Generate panels with colors and numbers
        for row in range(panels_height):
            for col in range(panels_width):
                x = col * panel_display_width
                y = 120 + row * panel_display_height  # Offset for title
                
                # Pick color based on position
                color_index = (row * panels_width + col) % len(colors)
                panel_color = colors[color_index]
                
                # Panel rectangle
                svg_content += f'''
                <rect x="{x}" y="{y}" width="{panel_display_width}" height="{panel_display_height}" 
                      fill="{panel_color}" stroke="#333333" stroke-width="1" opacity="0.8"/>
                '''
                
                # Panel number if enabled and panel is large enough
                if show_panel_numbers and panel_display_width > 30 and panel_display_height > 20:
                    text_x = x + panel_display_width // 2
                    text_y = y + panel_display_height // 2 + 4
                    panel_number = f"{row + 1}.{col + 1}"
                    font_size = min(12, panel_display_width // 8)
                    
                    svg_content += f'''
                    <text x="{text_x}" y="{text_y}" fill="#000000" font-family="Arial, sans-serif" 
                          font-size="{font_size}" font-weight="bold" text-anchor="middle">
                        {panel_number}
                    </text>
                    '''

        svg_content += '</svg>'
        
        # Convert SVG to base64 for now (in production, you'd convert to actual PNG)
        svg_base64 = base64.b64encode(svg_content.encode()).decode()
        
        # For the response, we'll return this as PNG-compatible data
        # The browser will render the SVG as an image
        file_size_mb = len(svg_content) / (1024 * 1024)
        
        return jsonify({
            'success': True,
            'image_base64': svg_base64,
            'imageData': f'data:image/svg+xml;base64,{svg_base64}',
            'dimensions': {
                'width': total_width,
                'height': total_height
            },
            'display_dimensions': {
                'width': display_width,
                'height': display_height + 120  # Include title area
            },
            'scale_factor': scale_factor,
            'file_size_mb': round(file_size_mb, 4),
            'led_info': {
                'name': led_name,
                'panels': f'{panels_width}×{panels_height}',
                'resolution': f'{total_width}×{total_height}px',
                'display_resolution': f'{display_width}×{display_height + 120}px'
            },
            'format': 'SVG',  # Will change to PNG when we implement proper PNG generation
            'panel_info': {
                'total_panels': panels_width * panels_height,
                'show_numbers': show_panel_numbers,
                'show_grid': show_grid
            },
            'note': f'Generated colorful LED pixel map with panel numbers - Original: {total_width}×{total_height}px (scaled 1:{scale_factor:.1f} for display)'
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
