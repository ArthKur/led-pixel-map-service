from flask import Flask, request, jsonify
from flask_cors import CORS
from PIL import Image, ImageDraw
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

def generate_pixel_map_optimized(width, height, pixel_pitch, led_panel_width, led_panel_height, canvas_scale=1.0, config=None):
    """Generate pixel map with memory optimization for ultra-large images - ENHANCED FOR 200M PIXELS"""
    try:
        # Log initial memory state
        initial_memory = get_memory_info()
        logger.info(f"🚀 ENHANCED: Starting generation: {width}×{height}px, Memory: {initial_memory['rss_mb']:.1f}MB")
        
        # Apply config defaults
        if config is None:
            config = {}
        show_grid = config.get('showGrid', True)
        show_panel_numbers = config.get('showPanelNumbers', True)
        
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
            led_name = config.get('ledName', 'Absen')
            return generate_chunked_pixel_map(canvas_width, canvas_height, pixel_pitch, led_panel_width, led_panel_height, mode, show_grid, show_panel_numbers, led_name)
        
        # Standard generation for smaller images (< 50M pixels)
        logger.info(f"📊 STANDARD: Using standard processing for {total_pixels:,} pixels")
        
        # For small images, use the full quality rendering with numbering
        led_name = config.get('ledName', 'Absen')
        return generate_full_quality_pixel_map(canvas_width, canvas_height, led_panel_width, led_panel_height, 
                                             show_grid, show_panel_numbers, led_name)
        
        return image
        
    except Exception as e:
        logger.error(f"Error in optimized generation: {str(e)}")
        logger.error(traceback.format_exc())
        raise

def generate_full_quality_pixel_map(width, height, led_panel_width, led_panel_height, show_grid=True, show_panel_numbers=True, led_name='Absen'):
    """Generate full quality pixel map with numbering and grid for smaller images"""
    try:
        # Calculate panel dimensions
        panels_width = int(width / led_panel_width)
        panels_height = int(height / led_panel_height)
        
        # Adjust actual image size to exact panel boundaries
        display_width = panels_width * led_panel_width
        display_height = panels_height * led_panel_height
        
        logger.info(f"📐 Full quality: {panels_width}×{panels_height} panels, {display_width}×{display_height}px")
        
        # Create high-fidelity RGB image for LED pixel mapping
        image = Image.new('RGB', (display_width, display_height), 'white')
        
        # Use high-quality drawing context for precise rendering
        draw = ImageDraw.Draw(image, 'RGB')
        
        # Memory check after image creation
        after_create_memory = get_memory_info()
        logger.info(f"After image creation: {after_create_memory['rss_mb']:.1f}MB")
        
        # Fill panels first (without borders)
        for row in range(panels_height):
            for col in range(panels_width):
                x = col * led_panel_width
                y = row * led_panel_height
                
                # Generate color for this panel based on LED type
                panel_color = generate_color(col, row, led_name)
                
                # Draw panel rectangle filled with color (no outline)
                draw.rectangle([x, y, x + led_panel_width - 1, y + led_panel_height - 1], 
                             fill=panel_color, outline=None)
        
        # Draw precise 1px white grid lines for LED panel boundaries
        if show_grid:
            # Horizontal grid lines (separating rows)
            for row in range(panels_height + 1):
                y_pos = row * led_panel_height
                if y_pos < display_height:
                    draw.line([(0, y_pos), (display_width - 1, y_pos)], fill=(255, 255, 255), width=1)
            
            # Vertical grid lines (separating columns)
            for col in range(panels_width + 1):
                x_pos = col * led_panel_width
                if x_pos < display_width:
                    draw.line([(x_pos, 0), (x_pos, display_height - 1)], fill=(255, 255, 255), width=1)
        
        # Draw panel numbers with VECTOR-BASED numbering (pixel-perfect quality)
        if show_panel_numbers:
            for row in range(panels_height):
                for col in range(panels_width):
                    x = col * led_panel_width
                    y = row * led_panel_height
                    
                    panel_number = f"{row + 1}.{col + 1}"
                    
                    # VECTOR NUMBERING: 20% of panel size for better visibility
                    number_size = int(min(led_panel_width, led_panel_height) * 0.15)
                    number_size = max(12, number_size)  # Minimum 12px for better quality
                    
                    # Position with 3% margin from edges (bit lower and to the right)
                    margin_percent = 0.03
                    margin_x = max(3, int(led_panel_width * margin_percent))
                    margin_y = max(3, int(led_panel_height * margin_percent))
                    text_x = x + margin_x
                    text_y = y + margin_y
                    
                    # Draw vector-based panel numbers (no font dependencies)
                    draw_vector_panel_number(
                        draw, panel_number, text_x, text_y, 
                        number_size, color=(255, 255, 255)  # WHITE numbers for better visibility
                    )
        
        # Final memory check
        final_memory = get_memory_info()
        logger.info(f"Generated full quality with numbering: {final_memory['rss_mb']:.1f}MB")
        
        return image
        
    except Exception as e:
        logger.error(f"Error in full quality generation: {str(e)}")
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

def generate_chunked_pixel_map(width, height, pixel_pitch, led_panel_width, led_panel_height, mode, show_grid=True, show_panel_numbers=True, led_name='Absen'):
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
                led_panel_width, led_panel_height, mode, show_grid, show_panel_numbers, led_name
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

def generate_enhanced_grid_for_chunk(draw, chunk_width, chunk_height, offset_x, offset_y, led_panel_width, led_panel_height, mode, show_grid=True, show_panel_numbers=True, led_name='Absen'):
    """Enhanced grid generation optimized for 200M+ pixels"""
    try:
        # Calculate panel positions within this chunk
        start_panel_x = offset_x // led_panel_width
        start_panel_y = offset_y // led_panel_height
        
        # Calculate how many panels fit in this chunk
        panels_in_chunk_x = ((offset_x + chunk_width - 1) // led_panel_width) - start_panel_x + 1
        panels_in_chunk_y = ((offset_y + chunk_height - 1) // led_panel_height) - start_panel_y + 1
        
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
                    # Generate color based on LED type and panel position
                    color = generate_color(panel_global_x, panel_global_y, led_name)
                    
                    # Draw panel portion in chunk coordinates
                    if show_grid:
                        draw.rectangle([
                            chunk_left, chunk_top, 
                            chunk_right - 1, chunk_bottom - 1
                        ], fill=color, outline=(255, 255, 255), width=1)
                    else:
                        draw.rectangle([
                            chunk_left, chunk_top, 
                            chunk_right - 1, chunk_bottom - 1
                        ], fill=color, outline=None)
                    
                    # Add panel numbering if enabled and the panel starts in this chunk
                    if show_panel_numbers and panel_left >= offset_x and panel_top >= offset_y:
                        panel_number = f"{panel_global_y + 1}.{panel_global_x + 1}"
                        
                        # VECTOR NUMBERING: 20% of panel size for better visibility
                        number_size = int(min(led_panel_width, led_panel_height) * 0.15)
                        number_size = max(12, number_size)  # Minimum 12px for better quality
                        
                        # Position with 3% margin from edges (bit lower and to the right)
                        margin_percent = 0.03
                        margin_x = max(3, int(led_panel_width * margin_percent))
                        margin_y = max(3, int(led_panel_height * margin_percent))
                        
                        # Calculate position in chunk coordinates
                        text_x = chunk_left + margin_x
                        text_y = chunk_top + margin_y
                        
                        # Only draw if the number fits within the chunk
                        if text_x + number_size <= chunk_width and text_y + number_size <= chunk_height:
                            draw_vector_panel_number(
                                draw, panel_number, text_x, text_y, 
                                number_size, color=(255, 255, 255)  # WHITE numbers for better visibility
                            )
        
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

def draw_vector_digit(draw, digit, x, y, size, color=(0, 0, 0)):
    """Draw a single digit using high-quality smooth text-like style - ULTRA SMOOTH DESIGN"""
    
    # Enhanced 7-segment patterns for better visibility
    patterns = {
        '0': [1, 1, 1, 1, 1, 1, 0],  # All except middle
        '1': [0, 1, 1, 0, 0, 0, 0],  # Right side only
        '2': [1, 1, 0, 1, 1, 0, 1],  # Top + right-top + middle + left-bottom + bottom
        '3': [1, 1, 1, 1, 0, 0, 1],  # Top + right + middle + bottom
        '4': [0, 1, 1, 0, 0, 1, 1],  # Left-top, right side, middle
        '5': [1, 0, 1, 1, 0, 1, 1],  # Left S-shape
        '6': [1, 0, 1, 1, 1, 1, 1],  # Left + bottom
        '7': [1, 1, 1, 0, 0, 0, 0],  # Top + right
        '8': [1, 1, 1, 1, 1, 1, 1],  # All segments
        '9': [1, 1, 1, 1, 0, 1, 1],  # All except bottom-left
        '.': [0, 0, 0, 0, 0, 0, 0],  # Special case for dot
    }
    
    if digit not in patterns:
        return
    
    pattern = patterns[digit]
    
    # Ultra-smooth segment dimensions for text-like appearance
    seg_thickness = max(1, size // 10)  # Much thinner segments for smooth look
    seg_length = size - (seg_thickness * 2)
    corner_radius = max(1, seg_thickness // 2)  # Smaller radius for cleaner look
    
    # Advanced smooth segment drawing with sub-pixel precision
    def draw_smooth_segment(x1, y1, x2, y2, horizontal=True):
        """Draw ultra-smooth segment with anti-aliasing effect"""
        if horizontal:
            # Main segment body
            draw.rectangle([x1 + corner_radius, y1, x2 - corner_radius, y2], fill=color)
            
            # Smooth rounded ends with gradient effect
            for i in range(corner_radius):
                alpha_factor = (corner_radius - i) / corner_radius
                # Left rounded end
                end_y1 = y1 + int(i * alpha_factor)
                end_y2 = y2 - int(i * alpha_factor)
                if end_y1 < end_y2:
                    draw.rectangle([x1 + i, end_y1, x1 + i + 1, end_y2], fill=color)
                
                # Right rounded end  
                if end_y1 < end_y2:
                    draw.rectangle([x2 - i - 1, end_y1, x2 - i, end_y2], fill=color)
        else:
            # Main segment body
            draw.rectangle([x1, y1 + corner_radius, x2, y2 - corner_radius], fill=color)
            
            # Smooth rounded ends with gradient effect
            for i in range(corner_radius):
                alpha_factor = (corner_radius - i) / corner_radius
                # Top rounded end
                end_x1 = x1 + int(i * alpha_factor)
                end_x2 = x2 - int(i * alpha_factor)
                if end_x1 < end_x2:
                    draw.rectangle([end_x1, y1 + i, end_x2, y1 + i + 1], fill=color)
                
                # Bottom rounded end
                if end_x1 < end_x2:
                    draw.rectangle([end_x1, y2 - i - 1, end_x2, y2 - i], fill=color)
    
    # Enhanced segment positioning for better proportions
    mid_y = y + size // 2
    gap = max(1, seg_thickness // 2)  # Small gap between segments
    
    # Draw active segments with ultra-smooth rendering
    if pattern[0]:  # top
        draw_smooth_segment(x + seg_thickness, y, x + size - seg_thickness, y + seg_thickness, True)
    
    if pattern[1]:  # top-right
        draw_smooth_segment(x + size - seg_thickness, y + seg_thickness + gap, x + size, mid_y - gap, False)
    
    if pattern[2]:  # bottom-right
        draw_smooth_segment(x + size - seg_thickness, mid_y + gap, x + size, y + size - seg_thickness - gap, False)
    
    if pattern[3]:  # bottom
        draw_smooth_segment(x + seg_thickness, y + size - seg_thickness, x + size - seg_thickness, y + size, True)
    
    if pattern[4]:  # bottom-left
        draw_smooth_segment(x, mid_y + gap, x + seg_thickness, y + size - seg_thickness - gap, False)
    
    if pattern[5]:  # top-left
        draw_smooth_segment(x, y + seg_thickness + gap, x + seg_thickness, mid_y - gap, False)
    
    if pattern[6]:  # middle
        draw_smooth_segment(x + seg_thickness, mid_y - seg_thickness//2, x + size - seg_thickness, mid_y + seg_thickness//2, True)

def draw_vector_dot(draw, x, y, size, color=(0, 0, 0)):
    """Draw a smooth vector dot for decimal points"""
    dot_size = max(2, size // 8)  # Smaller, more proportional dot
    dot_y = y + size - dot_size - (size // 10)  # Better positioning
    
    # Draw smooth circular dot with multiple rectangles for roundness
    center_x = x + dot_size // 2
    center_y = dot_y + dot_size // 2
    radius = dot_size // 2
    
    # Draw circular dot using filled rectangles
    for dy in range(-radius, radius + 1):
        for dx in range(-radius, radius + 1):
            if dx * dx + dy * dy <= radius * radius:
                draw.rectangle([center_x + dx, center_y + dy, center_x + dx + 1, center_y + dy + 1], fill=color)

def draw_vector_panel_number(draw, panel_number, x, y, size, color=(0, 0, 0)):
    """Draw panel number using ultra-smooth vector digits - TEXT-LIKE QUALITY"""
    current_x = x
    digit_width = size
    digit_spacing = max(2, size // 8)  # Better proportional spacing between digits
    
    for char in panel_number:
        if char == '.':
            draw_vector_dot(draw, current_x, y, size, color)
            current_x += digit_width // 2  # Dots take less space
        elif char.isdigit():
            draw_vector_digit(draw, char, current_x, y, size, color)
            current_x += digit_width + digit_spacing
        else:
            # Skip non-digit, non-dot characters
            current_x += digit_width // 3

def generate_color(panel_x, panel_y, led_name='Absen'):
    """Generate colors based on LED type and panel position"""
    
    # Different color schemes for different LED manufacturers
    if 'absen' in led_name.lower():
        # Absen: Full red and medium grey
        colors = [
            (255, 0, 0),    # Full red (pure red)
            (128, 128, 128) # Medium grey
        ]
    elif 'novastar' in led_name.lower():
        # Novastar: Blue and light grey
        colors = [
            (0, 100, 255),  # Blue
            (180, 180, 180) # Light grey
        ]
    elif 'colorlight' in led_name.lower():
        # Colorlight: Green and white
        colors = [
            (0, 200, 0),    # Green
            (240, 240, 240) # Nearly white
        ]
    elif 'linsn' in led_name.lower():
        # Linsn: Purple and cream
        colors = [
            (150, 0, 150),  # Purple
            (250, 245, 220) # Cream
        ]
    else:
        # Default/Unknown: Standard red and grey
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
            config_dict = {
                'showGrid': show_grid,
                'showPanelNumbers': show_panel_numbers,
                'ledName': led_name
            }
            
            image = generate_pixel_map_optimized(
                total_width, total_height, 
                1,  # pixel_pitch set to 1 for precise grid
                panel_pixel_width, panel_pixel_height, 
                canvas_scale,  # Always 1.0
                config_dict  # Pass the config for numbering control
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
        
        # Calculate panel display dimensions (NO SCALING for pixel-perfect output)
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
        
        # Draw panel numbers with VECTOR-BASED numbering (pixel-perfect quality)
        for row in range(panels_height):
            for col in range(panels_width):
                if show_panel_numbers:
                    x = col * panel_display_width
                    y = row * panel_display_height
                    
                    panel_number = f"{row + 1}.{col + 1}"
                    
                    # VECTOR NUMBERING: 20% of panel size for better visibility
                    number_size = int(min(panel_display_width, panel_display_height) * 0.15)
                    number_size = max(12, number_size)  # Minimum 12px for better quality
                    
                    # Position with 3% margin from edges (bit lower and to the right)
                    margin_percent = 0.03
                    margin_x = max(3, int(panel_display_width * margin_percent))
                    margin_y = max(3, int(panel_display_height * margin_percent))
                    text_x = x + margin_x
                    text_y = y + margin_y
                    
                    # Draw vector-based panel numbers (no font dependencies)
                    draw_vector_panel_number(
                        draw, panel_number, text_x, text_y, 
                        number_size, color=(255, 255, 255)  # WHITE numbers for better visibility
                    )
        
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
