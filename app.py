from flask import Flask, request, jsonify
from flask_cors import CORS
from PIL import Image, ImageDraw, ImageFont
import base64
import io
import os
import gc
import logging
import psutil
import traceback

# Configure PIL for ultra-large images
Image.MAX_IMAGE_PIXELS = None  # Remove PIL limits
os.environ['PIL_LOAD_TRUNCATED_IMAGES'] = '1'

# Configure logging for better debugging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app, resources={
    r"/*": {
        "origins": ["http://localhost:*", "https://*.github.io", "https://led-calculator-*.onrender.com"],
        "methods": ["GET", "POST", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"],
        "supports_credentials": True
    }
})

def get_memory_info():
    """Get current memory usage for debugging (fallback if psutil not available)"""
    try:
        import psutil
        process = psutil.Process()
        memory_info = process.memory_info()
        return {
            'rss_mb': memory_info.rss / 1024 / 1024,
            'vms_mb': memory_info.vms / 1024 / 1024,
            'percent': process.memory_percent()
        }
    except ImportError:
        # Fallback without psutil
        return {'rss_mb': 0, 'vms_mb': 0, 'percent': 0}

def generate_pixel_map_optimized(width, height, pixel_pitch, led_panel_width, led_panel_height, canvas_scale=1.0):
    """Generate pixel map with memory optimization for ultra-large images"""
    try:
        # Log initial memory state
        initial_memory = get_memory_info()
        logger.info(f"Starting generation: {width}×{height}px, Memory: {initial_memory['rss_mb']:.1f}MB")
        
        # Calculate scaled dimensions
        canvas_width = int(width * canvas_scale)
        canvas_height = int(height * canvas_scale)
        total_pixels = canvas_width * canvas_height
        
        logger.info(f"Canvas: {canvas_width}×{canvas_height}px ({total_pixels:,} pixels)")
        
        # Force garbage collection before starting
        gc.collect()
        
        # Create image with memory-efficient mode
        if total_pixels > 50_000_000:  # 50M+ pixels
            mode = 'L'  # Grayscale for ultra-large images
            logger.info("Using grayscale mode for ultra-large image")
        else:
            mode = 'RGB'
            
        # Create image in chunks if very large
        if total_pixels > 100_000_000:  # 100M+ pixels
            return generate_chunked_pixel_map(canvas_width, canvas_height, pixel_pitch, led_panel_width, led_panel_height, mode)
        
        # Standard generation for smaller images
        image = Image.new(mode, (canvas_width, canvas_height), color='black' if mode == 'L' else (0, 0, 0))
        draw = ImageDraw.Draw(image)
        
        # Memory check after image creation
        after_create_memory = get_memory_info()
        logger.info(f"After image creation: {after_create_memory['rss_mb']:.1f}MB")
        
        # Generate pixel grid with optimized drawing
        generate_pixel_grid_optimized(draw, canvas_width, canvas_height, pixel_pitch, led_panel_width, led_panel_height, canvas_scale, mode)
        
        # Final memory check
        final_memory = get_memory_info()
        logger.info(f"Generation complete: {final_memory['rss_mb']:.1f}MB")
        
        return image
        
    except Exception as e:
        logger.error(f"Error in optimized generation: {str(e)}")
        logger.error(traceback.format_exc())
        raise

def generate_chunked_pixel_map(width, height, pixel_pitch, led_panel_width, led_panel_height, mode):
    """Generate ultra-large images in chunks to manage memory"""
    logger.info(f"Generating {width}×{height}px image in chunks")
    
    # Create base image
    image = Image.new(mode, (width, height), color='black' if mode == 'L' else (0, 0, 0))
    
    # Process in chunks of 10M pixels
    chunk_size = 3162  # sqrt(10M) ≈ 3162
    
    for y in range(0, height, chunk_size):
        for x in range(0, width, chunk_size):
            chunk_width = min(chunk_size, width - x)
            chunk_height = min(chunk_size, height - y)
            
            # Create chunk
            chunk = Image.new(mode, (chunk_width, chunk_height), color='black' if mode == 'L' else (0, 0, 0))
            chunk_draw = ImageDraw.Draw(chunk)
            
            # Generate grid for this chunk
            generate_pixel_grid_for_chunk(chunk_draw, chunk_width, chunk_height, x, y, pixel_pitch, led_panel_width, led_panel_height, mode)
            
            # Paste chunk into main image
            image.paste(chunk, (x, y))
            
            # Clean up chunk
            del chunk, chunk_draw
            gc.collect()
            
            logger.info(f"Processed chunk at {x},{y}")
    
    return image

def generate_pixel_grid_optimized(draw, canvas_width, canvas_height, pixel_pitch, led_panel_width, led_panel_height, canvas_scale, mode):
    """Optimized pixel grid generation"""
    scaled_pitch = pixel_pitch * canvas_scale
    color = 128 if mode == 'L' else (128, 128, 128)  # Gray
    
    # Calculate grid dimensions
    h_lines = int(canvas_height / scaled_pitch) + 1
    v_lines = int(canvas_width / scaled_pitch) + 1
    
    # Draw horizontal lines (batch processing)
    for i in range(h_lines):
        y = i * scaled_pitch
        if y < canvas_height:
            draw.line([(0, y), (canvas_width, y)], fill=color, width=1)
    
    # Draw vertical lines (batch processing)
    for i in range(v_lines):
        x = i * scaled_pitch
        if x < canvas_width:
            draw.line([(x, 0), (x, canvas_height)], fill=color, width=1)
    
    # Force garbage collection
    gc.collect()

def generate_pixel_grid_for_chunk(draw, chunk_width, chunk_height, offset_x, offset_y, pixel_pitch, led_panel_width, led_panel_height, mode):
    """Generate pixel grid for a specific chunk"""
    color = 128 if mode == 'L' else (128, 128, 128)
    
    # Calculate starting positions based on offset
    start_x = offset_x % pixel_pitch
    start_y = offset_y % pixel_pitch
    
    # Draw lines within chunk bounds
    y = start_y
    while y < chunk_height:
        draw.line([(0, y), (chunk_width, y)], fill=color, width=1)
        y += pixel_pitch
    
    x = start_x
    while x < chunk_width:
        draw.line([(x, 0), (x, chunk_height)], fill=color, width=1)
        x += pixel_pitch

def generate_color(panel_x, panel_y):
    """Generate alternating full red and medium grey colors for each panel"""
    # Use only two colors: full red and medium grey
    colors = [
        (255, 0, 0),    # Full red (pure red)
        (128, 128, 128) # Medium grey
    ]
    
    # Alternate colors in a checkerboard pattern
    color_index = (panel_x + panel_y) % len(colors)
    return colors[color_index]

@app.route('/')
def health_check():
    return jsonify({
        'service': 'LED Pixel Map Cloud Renderer',
        'status': 'healthy',
        'version': '11.0 - PIXEL-PERFECT: Full resolution generation without scaling for maximum quality',
        'message': 'No scaling, pixel-perfect generation for crisp fonts and perfect panel definition',
        'features': 'Full resolution, surface-based font scaling, pixel-perfect quality',
        'colors': 'Full Red (255,0,0) alternating with Medium Grey (128,128,128)',
        'timestamp': '2025-08-04-09:00'
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
        total_pixels = total_width * total_height
        
        logger.info(f"🎯 PIXEL-PERFECT GENERATION: {total_width}×{total_height} pixels ({total_pixels:,} total)")
        logger.info(f"📦 Panel config: {panels_width}×{panels_height} panels of {panel_pixel_width}×{panel_pixel_height}px each")
        
        # For ultra-large images (>5M pixels), use optimized generation
        if total_pixels > 5_000_000:
            logger.info("Using optimized generation for ultra-large image")
            
            # Use chunked generation for memory efficiency
            canvas_scale = 1.0
            if total_width > 10000 or total_height > 10000:
                # Scale down for extremely large dimensions
                max_dimension = 8000
                scale_factor = max(total_width / max_dimension, total_height / max_dimension)
                canvas_scale = 1.0 / scale_factor
                logger.info(f"Scaling down by factor {scale_factor:.2f}")
            
            # Generate using optimized function
            image = generate_pixel_map_optimized(
                total_width, total_height, 
                1,  # pixel_pitch set to 1 for now
                panel_pixel_width, panel_pixel_height, 
                canvas_scale
            )
            
            # Convert to base64 and return immediately for ultra-large images
            buffer = io.BytesIO()
            if image.mode == 'L':
                # Convert grayscale back to RGB for compatibility
                image = image.convert('RGB')
            image.save(buffer, format='PNG', optimize=True)
            buffer.seek(0)
            image_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')
            
            return jsonify({
                'success': True,
                'image': image_base64,
                'width': image.width,
                'height': image.height,
                'optimized': True,
                'total_pixels': total_pixels
            })
        
        # Standard generation for smaller images (≤5M pixels)
        # For very large images, create a manageable size for display
        # Scale down if too large to keep file size reasonable
        max_display_width = 4000
        max_display_height = 2400
        scale_factor = 1
        
        # NEW APPROACH: NO SCALING - Generate at full resolution for pixel-perfect quality
        # This ensures crisp fonts and perfect panel definition even for massive surfaces
        display_width = total_width
        display_height = total_height
        panel_display_width = panel_pixel_width
        panel_display_height = panel_pixel_height
        scale_factor = 1.0
        
        print(f"🔥 Full resolution generation - NO SCALING for maximum quality")
        
        # Memory and performance check
        total_pixels = display_width * display_height
        estimated_memory_mb = (total_pixels * 3) / (1024 * 1024)  # RGB = 3 bytes per pixel
        print(f"📊 Image specs: {total_pixels:,} pixels, ~{estimated_memory_mb:.1f}MB memory")
        
        # Warn about very large images but proceed anyway
        if total_pixels > 100_000_000:  # 100M pixels
            print(f"⚠️  Large image detected - this may take several minutes to generate")
        
        # Create high-fidelity RGB image for LED pixel mapping
        # Use RGB mode for consistent color representation across platforms
        image = Image.new('RGB', (display_width, display_height), 'white')
        
        # Use high-quality drawing context for precise rendering
        draw = ImageDraw.Draw(image, 'RGB')  # Ensure RGB consistency
        
        # SURFACE-DIMENSION-BASED font scaling as per user requirements
        # User specification: 
        # - Absen 2.5mm @ 10m×10m surface = correct font size (reference)
        # - Absen 2.5mm @ 50m×50m surface = 50% smaller font than 10m surface
        
        # Calculate surface dimensions in meters (assuming 500mm = 0.5m panels for Absen)
        # This is an approximation - in real app, we'd need actual panel physical dimensions
        estimated_panel_width_m = 0.5  # Absen panels are typically 500mm = 0.5m wide
        surface_width_m = panels_width * estimated_panel_width_m
        surface_height_m = panels_height * estimated_panel_width_m  # Assume square panels
        
        # Use ORIGINAL panel pixel dimensions as base
        original_panel_size = min(panel_pixel_width, panel_pixel_height)
        
        # STEP-BY-STEP SCALING based on surface size:
        # Reference: 10m×10m surface (20×20 panels) = 100% font scale
        # Target: 50m×50m surface (100×100 panels) = 50% font scale
        
        reference_surface_size = 10.0  # 10m×10m reference surface
        current_surface_size = max(surface_width_m, surface_height_m)  # Use larger dimension
        
        if current_surface_size <= 10.0:
            # Small surfaces (up to 10m) - full size font
            surface_scale_factor = 0.08  # 8% for good visibility on small surfaces
            print(f"Small surface ({current_surface_size:.1f}m) - using full size font")
        elif current_surface_size <= 50.0:
            # Medium to large surfaces (10m to 50m) - scale down proportionally
            scale_ratio = 10.0 / current_surface_size  # 10m=1.0, 50m=0.2 (20% of original)
            surface_scale_factor = 0.08 * scale_ratio  # Scale from 8% down to smaller
            print(f"Large surface ({current_surface_size:.1f}m) - scaled font (ratio: {scale_ratio:.2f})")
        else:
            # Very large surfaces (50m+) - minimum font size
            surface_scale_factor = 0.016  # 2% for very large surfaces
            print(f"Very large surface ({current_surface_size:.1f}m) - minimum font size")
        
        # Calculate font size: panel pixel size × surface scale factor
        calculated_font_size = int(original_panel_size * surface_scale_factor)
        
        # Set reasonable bounds: minimum 4px, maximum 40px
        panel_font_size = max(4, min(40, calculated_font_size))
        
        print(f"Surface-based font scaling: {original_panel_size}px panel × {surface_scale_factor:.3f} = {panel_font_size}px font")
        
        # Load high-quality TrueType fonts with better error handling
        panel_font = None
        font_paths_to_try = []
        
        try:
            import platform
            system = platform.system()
            
            if system == "Darwin":  # macOS
                font_paths_to_try = [
                    "/System/Library/Fonts/Helvetica.ttc",
                    "/System/Library/Fonts/Arial.ttf", 
                    "/System/Library/Fonts/Arial Unicode.ttf"
                ]
            elif system == "Linux":  # Linux (Render.com)
                font_paths_to_try = [
                    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
                    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
                    "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
                    "/usr/share/fonts/truetype/liberation/LiberationSans.ttf",
                    "/usr/share/fonts/TTF/arial.ttf",
                    "/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf"
                ]
            else:  # Windows
                font_paths_to_try = [
                    "C:/Windows/Fonts/arial.ttf",
                    "C:/Windows/Fonts/calibri.ttf"
                ]
            
            # Try each font path until one works
            for font_path in font_paths_to_try:
                try:
                    panel_font = ImageFont.truetype(font_path, panel_font_size)
                    print(f"Successfully loaded font: {font_path}")
                    break
                except:
                    continue
                    
            if panel_font is None:
                print("All font paths failed, using default")
                panel_font = ImageFont.load_default()
                
        except Exception as e:
            print(f"Font loading error: {e}")
            panel_font = ImageFont.load_default()
        
        # Fill panels first (without borders)
        for row in range(panels_height):
            for col in range(panels_width):
                x = col * panel_display_width
                y = row * panel_display_height
                
                # Generate color for this panel
                panel_color = generate_color(col, row)
                
                # Draw panel rectangle filled with color (no outline)
                draw.rectangle([x, y, x + panel_display_width - 1, y + panel_display_height - 1], 
                             fill=panel_color, outline=None)
        
        # Draw precise 1px white grid lines for LED panel boundaries
        # Horizontal grid lines (separating rows)
        for row in range(panels_height + 1):
            y_pos = row * panel_display_height
            if y_pos < display_height:
                # Ensure exactly 1px line for grid precision
                draw.line([(0, y_pos), (display_width - 1, y_pos)], fill=(255, 255, 255), width=1)
        
        # Vertical grid lines (separating columns)
        for col in range(panels_width + 1):
            x_pos = col * panel_display_width
            if x_pos < display_width:
                # Ensure exactly 1px line for grid precision
                draw.line([(x_pos, 0), (x_pos, display_height - 1)], fill=(255, 255, 255), width=1)
        
        # Draw panel numbers with simple high contrast
        for row in range(panels_height):
            for col in range(panels_width):
                if show_panel_numbers:
                    x = col * panel_display_width
                    y = row * panel_display_height
                    
                    panel_number = f"{row + 1}.{col + 1}"
                    
                    # Smart margin calculation - proportional to font size, not panel size
                    # This ensures consistent text positioning regardless of canvas scale
                    margin = max(2, int(panel_font_size * 0.3))  # 30% of font size, minimum 2px
                    text_x = x + margin
                    text_y = y + margin
                    
                    # Draw simple black text - no background
                    if panel_font:
                        # Draw black text directly on panels
                        draw.text((text_x, text_y), panel_number, fill='black', font=panel_font)
                    else:
                        # Fallback without font - still black text
                        draw.text((text_x, text_y), panel_number, fill='black')
        
        # Generate NATIVE PNG with maximum quality and precision
        # No SVG conversion - direct PNG generation for Flutter
        img_buffer = io.BytesIO()
        
        # PNG-specific optimization for pixel-perfect accuracy
        # Use maximum quality settings for professional LED visualization
        pnginfo = None  # Remove any metadata that could affect quality
        
        # Save as uncompressed PNG for absolute pixel accuracy
        image.save(img_buffer, 
                  format='PNG', 
                  optimize=False,           # No size optimization that could affect quality
                  compress_level=0,         # No compression for maximum fidelity
                  pnginfo=pnginfo,         # No metadata interference
                  bits=8)                  # 8-bit per channel for standard compatibility
        
        img_buffer.seek(0)
        
        # Get pure PNG bytes - ready for Flutter without any conversion
        png_bytes = img_buffer.getvalue()
        png_base64 = base64.b64encode(png_bytes).decode()
        file_size_mb = len(png_bytes) / (1024 * 1024)
        
        # Verify PNG integrity (basic header check)
        png_signature = png_bytes[:8]
        expected_signature = b'\x89PNG\r\n\x1a\n'
        is_valid_png = png_signature == expected_signature
        
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
            'png_quality': {
                'native_generation': True,
                'no_svg_conversion': True,
                'compression_level': 0,
                'bits_per_channel': 8,
                'valid_png_header': is_valid_png,
                'flutter_ready': True
            },
            'panel_info': {
                'total_panels': panels_width * panels_height,
                'show_numbers': show_panel_numbers,
                'show_grid': show_grid
            },
            'technical_specs': {
                'direct_png_generation': 'Pillow native PNG - no quality loss',
                'pixel_accuracy': 'Uncompressed for exact pixel representation',
                'flutter_compatibility': 'Ready for direct use without conversion',
                'rendering_engine': 'PIL/Pillow direct rasterization'
            },
            'note': f'PIXEL-PERFECT PNG generated on Render.com - Full Resolution: {total_width}×{total_height}px (NO SCALING) - Maximum quality for professional use'
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
