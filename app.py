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
    """Generate pixel map with memory optimization for ultra-large images - ENHANCED FOR 200M PIXELS"""
    try:
        # Log initial memory state
        initial_memory = get_memory_info()
        logger.info(f"🚀 ENHANCED: Starting generation: {width}×{height}px, Memory: {initial_memory['rss_mb']:.1f}MB")
        
        # Calculate scaled dimensions
        canvas_width = int(width * canvas_scale)
        canvas_height = int(height * canvas_scale)
        total_pixels = canvas_width * canvas_height
        
        logger.info(f"Canvas: {canvas_width}×{canvas_height}px ({total_pixels:,} pixels)")
        
        # Force garbage collection before starting
        gc.collect()
        
        # Always use RGB for consistency and compatibility
        mode = 'RGB'
        
        # Enhanced chunking strategy for 200M pixels
        if total_pixels > 50_000_000:  # 50M+ pixels - use chunked processing
            logger.info(f"🔄 CHUNKED: Using enhanced chunked processing for {total_pixels:,} pixels")
            return generate_chunked_pixel_map(canvas_width, canvas_height, pixel_pitch, led_panel_width, led_panel_height, mode)
        
        # Standard generation for smaller images (< 50M pixels)
        logger.info(f"📊 STANDARD: Using standard processing for {total_pixels:,} pixels")
        image = Image.new(mode, (canvas_width, canvas_height), color=(0, 0, 0))
        draw = ImageDraw.Draw(image)
        
        # Memory check after image creation
        after_create_memory = get_memory_info()
        logger.info(f"After image creation: {after_create_memory['rss_mb']:.1f}MB")
        
        # Generate simple grid pattern for standard processing
        generate_simple_grid(draw, canvas_width, canvas_height, led_panel_width, led_panel_height, mode)
        
        # Final memory check
        final_memory = get_memory_info()
        logger.info(f"Generation complete: {final_memory['rss_mb']:.1f}MB")
        
        return image
        
    except Exception as e:
        logger.error(f"Error in optimized generation: {str(e)}")
        logger.error(traceback.format_exc())
        raise

def generate_simple_grid(draw, canvas_width, canvas_height, led_panel_width, led_panel_height, mode):
    """Generate a simple grid pattern for ultra-large images"""
    try:
        # Calculate number of panels
        panels_h = int(canvas_width / led_panel_width)
        panels_v = int(canvas_height / led_panel_height)
        
        # Use simple colors for large images
        colors = [(255, 0, 0), (128, 128, 128)]  # Red and Gray
        
        # Draw panels
        for row in range(panels_v):
            for col in range(panels_h):
                x = col * led_panel_width
                y = row * led_panel_height
                color = colors[(row + col) % 2]
                
                # Draw panel rectangle
                draw.rectangle([x, y, x + led_panel_width - 1, y + led_panel_height - 1], 
                             fill=color, outline=(255, 255, 255), width=1)
        
        logger.info(f"Generated simple grid: {panels_h}×{panels_v} panels")
        
    except Exception as e:
        logger.error(f"Error in simple grid generation: {str(e)}")
        raise

def generate_chunked_pixel_map(width, height, pixel_pitch, led_panel_width, led_panel_height, mode):
    """Generate ultra-large images in chunks to manage memory - ENHANCED FOR 200M PIXELS"""
    logger.info(f"🚀 ENHANCED: Generating {width}×{height}px image in optimized chunks")
    
    # Create base image
    image = Image.new(mode, (width, height), color=(0, 0, 0))
    
    # Enhanced chunking strategy for 200M+ pixels
    total_pixels = width * height
    
    if total_pixels > 150_000_000:  # 150M+ pixels
        chunk_size = 2000  # Smaller chunks for massive images
        logger.info(f"Ultra-massive image detected ({total_pixels:,} pixels) - using 2K chunks")
    elif total_pixels > 100_000_000:  # 100-150M pixels  
        chunk_size = 3000  # Medium chunks
        logger.info(f"Very large image detected ({total_pixels:,} pixels) - using 3K chunks")
    else:  # <100M pixels
        chunk_size = 4000  # Larger chunks for smaller images
        logger.info(f"Large image detected ({total_pixels:,} pixels) - using 4K chunks")
    
    chunks_processed = 0
    total_chunks = ((width + chunk_size - 1) // chunk_size) * ((height + chunk_size - 1) // chunk_size)
    
    # Process in optimized chunks with memory management
    for y in range(0, height, chunk_size):
        for x in range(0, width, chunk_size):
            chunk_width = min(chunk_size, width - x)
            chunk_height = min(chunk_size, height - y)
            
            # Create chunk with minimal memory footprint
            chunk = Image.new(mode, (chunk_width, chunk_height), color=(0, 0, 0))
            chunk_draw = ImageDraw.Draw(chunk)
            
            # Generate optimized grid for this chunk
            generate_enhanced_grid_for_chunk(
                chunk_draw, chunk_width, chunk_height, x, y, 
                led_panel_width, led_panel_height, mode
            )
            
            # Paste chunk into main image
            image.paste(chunk, (x, y))
            
            # Aggressive cleanup for memory management
            del chunk, chunk_draw
            chunks_processed += 1
            
            # Force garbage collection every 10 chunks
            if chunks_processed % 10 == 0:
                gc.collect()
                memory_info = get_memory_info()
                progress = (chunks_processed / total_chunks) * 100
                logger.info(f"Progress: {progress:.1f}% ({chunks_processed}/{total_chunks} chunks) - Memory: {memory_info['rss_mb']:.1f}MB")
    
    logger.info(f"✅ Completed chunked generation: {chunks_processed} chunks processed")
    return image

def generate_enhanced_grid_for_chunk(draw, chunk_width, chunk_height, offset_x, offset_y, led_panel_width, led_panel_height, mode):
    """Enhanced grid generation optimized for 200M+ pixels"""
    try:
        # Calculate panel positions within this chunk
        start_panel_x = offset_x // led_panel_width
        start_panel_y = offset_y // led_panel_height
        
        # Calculate how many panels fit in this chunk
        panels_in_chunk_x = ((offset_x + chunk_width - 1) // led_panel_width) - start_panel_x + 1
        panels_in_chunk_y = ((offset_y + chunk_height - 1) // led_panel_height) - start_panel_y + 1
        
        # Enhanced colors for better visibility
        colors = [(255, 0, 0), (128, 128, 128)]  # Full red, medium grey
        
        # Draw panels that intersect with this chunk
        for row in range(panels_in_chunk_y):
            for col in range(panels_in_chunk_x):
                panel_global_x = start_panel_x + col
                panel_global_y = start_panel_y + row
                
                # Calculate panel boundaries in global coordinates
                panel_left = panel_global_x * led_panel_width
                panel_top = panel_global_y * led_panel_height
                panel_right = panel_left + led_panel_width
                panel_bottom = panel_top + led_panel_height
                
                # Calculate intersection with current chunk
                chunk_left = max(0, panel_left - offset_x)
                chunk_top = max(0, panel_top - offset_y)
                chunk_right = min(chunk_width, panel_right - offset_x)
                chunk_bottom = min(chunk_height, panel_bottom - offset_y)
                
                # Only draw if there's a valid intersection
                if chunk_right > chunk_left and chunk_bottom > chunk_top:
                    # Select color based on panel position
                    color = colors[(panel_global_y + panel_global_x) % 2]
                    
                    # Draw panel portion in chunk coordinates
                    draw.rectangle([
                        chunk_left, chunk_top, 
                        chunk_right - 1, chunk_bottom - 1
                    ], fill=color, outline=(255, 255, 255), width=1)
        
    except Exception as e:
        logger.error(f"Error in enhanced chunk grid generation: {str(e)}")
        # Fallback to simple fill
        draw.rectangle([0, 0, chunk_width-1, chunk_height-1], fill=(128, 128, 128))

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
        'service': 'LED Pixel Map Cloud Renderer - ENHANCED 200M',
        'status': 'healthy',
        'version': '12.0 - ENHANCED: Up to 200M pixels with advanced chunked processing',
        'message': 'No scaling, pixel-perfect generation for massive LED installations up to 200M pixels',
        'features': 'Enhanced chunked processing, adaptive compression, 200M pixel support',
        'colors': 'Full Red (255,0,0) alternating with Medium Grey (128,128,128)',
        'pixel_limits': {
            'maximum': '200M pixels',
            'chunked_processing': '>50M pixels',
            'standard_processing': '<50M pixels',
            'memory_optimization': 'Adaptive chunk sizes based on image size'
        },
        'timestamp': '2025-08-05-200M-ENHANCED'
    })

@app.route('/test')
def test():
    return jsonify({'message': 'Test endpoint working!'})

@app.route('/generate-pixel-map', methods=['POST'])
def generate_pixel_map():
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({
                'success': False,
                'error': 'No data provided'
            }), 400
        
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
        
        # ENHANCED FOR 200M PIXELS: Use optimized generation for large images
        if total_pixels > 5_000_000:
            logger.info(f"🎯 ENHANCED 200M: Using optimized generation for {total_pixels:,} pixels - NO SCALING")
            
            # NO SCALING - Generate at exact requested dimensions for ANY size up to 200M
            canvas_scale = 1.0  # Always 1.0 for pixel-perfect output
            
            # Enhanced memory management for 200M pixels
            if total_pixels > 200_000_000:
                logger.warning(f"⚠️ EXTREME SIZE: {total_pixels:,} pixels exceeds 200M limit - may fail")
                # Still attempt generation but warn user
            elif total_pixels > 150_000_000:
                logger.info(f"🔥 MASSIVE: {total_pixels:,} pixels - using maximum optimization")
            elif total_pixels > 100_000_000:
                logger.info(f"📈 VERY LARGE: {total_pixels:,} pixels - using enhanced processing")
            
            # Generate using enhanced optimized function at EXACT requested size
            image = generate_pixel_map_optimized(
                total_width, total_height, 
                1,  # pixel_pitch set to 1 for precise grid
                panel_pixel_width, panel_pixel_height, 
                canvas_scale  # Always 1.0
            )
            
            # Verify image is exactly the requested size
            if image.width != total_width or image.height != total_height:
                logger.error(f"Size mismatch! Requested: {total_width}×{total_height}, Got: {image.width}×{image.height}")
                # Force resize to exact requested dimensions if needed
                image = image.resize((total_width, total_height), Image.NEAREST)
                logger.info(f"Resized to exact requested dimensions: {total_width}×{total_height}")
            
            # Enhanced PNG compression for large files
            buffer = io.BytesIO()
            if image.mode == 'L':
                # Convert grayscale back to RGB for compatibility
                image = image.convert('RGB')
            
            # Adaptive compression based on image size
            if total_pixels > 100_000_000:
                # High compression for massive images to reduce file size
                image.save(buffer, format='PNG', optimize=True, compress_level=6)
                logger.info("Using high compression for massive image")
            else:
                # Standard compression
                image.save(buffer, format='PNG', optimize=True)
            
            buffer.seek(0)
            image_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')
            
            # Get actual file size
            file_size_mb = len(buffer.getvalue()) / (1024 * 1024)
            
            return jsonify({
                'success': True,
                'image_base64': image_base64,  # Use consistent field name
                'dimensions': {
                    'width': total_width,  # Return REQUESTED dimensions, not scaled
                    'height': total_height
                },
                'file_size_mb': round(file_size_mb, 4),
                'led_info': {
                    'name': led_name,
                    'panels': f'{panels_width}×{panels_height}',
                    'resolution': f'{total_width}×{total_height}px'  # EXACT requested resolution
                },
                'optimized': True,
                'total_pixels': total_pixels,
                'note': f'ENHANCED 200M: {total_width}×{total_height}px (no scaling, adaptive compression)',
                'actual_image_size': {
                    'width': image.width,
                    'height': image.height
                },
                'processing_info': {
                    'pixel_limit': '200M pixels maximum',
                    'memory_optimization': 'Enhanced chunked processing',
                    'compression': 'Adaptive based on size'
                }
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
        logger.error(f"Error in generate_pixel_map: {str(e)}")
        logger.error(traceback.format_exc())
        return jsonify({
            'success': False,
            'error': f'Server error: {str(e)}',
            'error_type': type(e).__name__
        }), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
