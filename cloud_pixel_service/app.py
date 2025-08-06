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
        show_name = config.get('showName', False)
        show_cross = config.get('showCross', False)
        show_circle = config.get('showCircle', False)
        show_logo = config.get('showLogo', False)
        
        # Get surface name for overlays
        surface_name = config.get('surfaceName', 'Screen One')
        
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
            return generate_chunked_pixel_map(canvas_width, canvas_height, pixel_pitch, led_panel_width, led_panel_height, mode, show_grid, show_panel_numbers, led_name, show_name, show_cross, show_circle, show_logo, surface_name)
        
        # Standard generation for smaller images (< 50M pixels)
        logger.info(f"📊 STANDARD: Using standard processing for {total_pixels:,} pixels")
        
        # For small images, use the full quality rendering with numbering
        led_name = config.get('ledName', 'Absen')
        return generate_full_quality_pixel_map(canvas_width, canvas_height, led_panel_width, led_panel_height, 
                                             show_grid, show_panel_numbers, led_name, show_name, show_cross, show_circle, show_logo, surface_name)
        
        return image
        
    except Exception as e:
        logger.error(f"Error in optimized generation: {str(e)}")
        logger.error(traceback.format_exc())
        raise

def generate_full_quality_pixel_map(width, height, led_panel_width, led_panel_height, show_grid=True, show_panel_numbers=True, led_name='Absen', show_name=False, show_cross=False, show_circle=False, show_logo=False, surface_name='Screen One'):
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
        
        # Fill panels with colors and optionally add brighter grid borders
        for row in range(panels_height):
            for col in range(panels_width):
                x = col * led_panel_width
                y = row * led_panel_height
                
                # Generate color for this panel based on LED type
                panel_color = generate_color(col, row, led_name)
                
                # Draw panel rectangle filled with color (no outline)
                draw.rectangle([x, y, x + led_panel_width - 1, y + led_panel_height - 1], 
                             fill=panel_color, outline=None)
                
                # Add brighter border if grid is enabled
                if show_grid:
                    # Create brighter border color (30% brighter)
                    border_color = brighten_color(panel_color, 0.3)
                    
                    # Draw 1-pixel brighter border around panel
                    # Top border
                    draw.line([(x, y), (x + led_panel_width - 1, y)], fill=border_color, width=1)
                    # Bottom border  
                    draw.line([(x, y + led_panel_height - 1), (x + led_panel_width - 1, y + led_panel_height - 1)], fill=border_color, width=1)
                    # Left border
                    draw.line([(x, y), (x, y + led_panel_height - 1)], fill=border_color, width=1)
                    # Right border
                    draw.line([(x + led_panel_width - 1, y), (x + led_panel_width - 1, y + led_panel_height - 1)], fill=border_color, width=1)
        
        # Draw panel numbers with VECTOR-BASED numbering (pixel-perfect quality)
        if show_panel_numbers:
            for row in range(panels_height):
                for col in range(panels_width):
                    x = col * led_panel_width
                    y = row * led_panel_height
                    
                    panel_number = f"{row + 1}.{col + 1}"
                    
                    # ENHANCED VECTOR NUMBERING: 15% of panel size for optimal visibility
                    number_size = int(min(led_panel_width, led_panel_height) * 0.15)  # Increased to 15%
                    number_size = max(12, number_size)  # Minimum 12px for enhanced visibility
                    
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

        # Add new visual elements based on config
        add_visual_overlays(draw, display_width, display_height, surface_name, show_name, show_cross, show_circle, show_logo)
        
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

def generate_chunked_pixel_map(width, height, pixel_pitch, led_panel_width, led_panel_height, mode, show_grid=True, show_panel_numbers=True, led_name='Absen', show_name=False, show_cross=False, show_circle=False, show_logo=False, surface_name='Screen One'):
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
    
    # Add visual overlays after chunked generation is complete
    draw = ImageDraw.Draw(image)
    add_visual_overlays(draw, width, height, surface_name, show_name, show_cross, show_circle, show_logo)
    
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
                    draw.rectangle([
                        chunk_left, chunk_top, 
                        chunk_right - 1, chunk_bottom - 1
                    ], fill=color, outline=None)
                    
                    # Add brighter border if grid is enabled
                    if show_grid:
                        border_color = brighten_color(color, 0.3)
                        # Draw brighter border around the panel portion in this chunk
                        # Only draw borders that are within the chunk boundaries
                        
                        # Top border (if panel top is in this chunk)
                        if panel_top >= offset_y and chunk_top == panel_top - offset_y:
                            draw.line([(chunk_left, chunk_top), (chunk_right - 1, chunk_top)], fill=border_color, width=1)
                        
                        # Bottom border (if panel bottom is in this chunk)
                        if panel_bottom <= offset_y + chunk_height and chunk_bottom == panel_bottom - offset_y:
                            draw.line([(chunk_left, chunk_bottom - 1), (chunk_right - 1, chunk_bottom - 1)], fill=border_color, width=1)
                        
                        # Left border (if panel left is in this chunk)
                        if panel_left >= offset_x and chunk_left == panel_left - offset_x:
                            draw.line([(chunk_left, chunk_top), (chunk_left, chunk_bottom - 1)], fill=border_color, width=1)
                        
                        # Right border (if panel right is in this chunk)
                        if panel_right <= offset_x + chunk_width and chunk_right == panel_right - offset_x:
                            draw.line([(chunk_right - 1, chunk_top), (chunk_right - 1, chunk_bottom - 1)], fill=border_color, width=1)
                    
                    # Add panel numbering if enabled and the panel starts in this chunk
                    if show_panel_numbers and panel_left >= offset_x and panel_top >= offset_y:
                        panel_number = f"{panel_global_y + 1}.{panel_global_x + 1}"
                        
                        # ENHANCED VECTOR NUMBERING: 15% of panel size for optimal visibility
                        number_size = int(min(led_panel_width, led_panel_height) * 0.15)  # Increased to 15%
                        number_size = max(12, number_size)  # Minimum 12px for enhanced visibility
                        
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
    """Draw a single digit using ULTRA HIGH QUALITY rendering with fine-pixel precision"""
    
    # ULTRA QUALITY settings - reduced pixel size for smoother text
    # Reduce the effective "pixel" size while maintaining readability
    base_thickness = max(2, size // 8)  # Thinner base strokes for finer detail
    thickness = base_thickness + 1  # Add slight thickness for visibility
    width = int(size * 0.75)  # Slightly narrower for better proportions
    height = size
    
    # Helper function for ultra-smooth thick lines with anti-aliasing effect
    def draw_ultra_smooth_line(x1, y1, x2, y2, thickness):
        # Draw core line
        draw.line([(x1, y1), (x2, y2)], fill=color, width=thickness)
        
        # Add sub-pixel smoothing with smaller rounded ends
        r = max(1, thickness // 3)  # Much smaller radius for finer detail
        
        # Multiple small circles for smoother appearance
        for i in range(3):
            offset = i * 0.3
            radius = r - i * 0.2
            if radius > 0:
                draw.ellipse([x1-radius+offset, y1-radius+offset, 
                            x1+radius+offset, y1+radius+offset], fill=color)
                draw.ellipse([x2-radius+offset, y2-radius+offset, 
                            x2+radius+offset, y2+radius+offset], fill=color)
    
    if digit == '0':
        # Ultra-smooth oval outline with fine detail
        margin = thickness // 2
        # Draw main oval
        draw.ellipse([x + margin, y + margin, x + width - margin, y + height - margin], 
                    outline=color, width=thickness)
        # Add inner smoothing
        inner_margin = margin + 1
        if width > 20 and height > 20:  # Only for larger sizes
            draw.ellipse([x + inner_margin, y + inner_margin, x + width - inner_margin, y + height - inner_margin], 
                        outline=color, width=1)
        
    elif digit == '1':
        # Ultra-smooth vertical line with refined serifs
        center_x = x + width // 2
        # Main vertical with ultra-smooth rendering
        draw_ultra_smooth_line(center_x, y + thickness, center_x, y + height - thickness, thickness)
        # Refined top serif
        serif_len = width // 4  # Smaller serif for finer look
        draw_ultra_smooth_line(center_x - serif_len, y + serif_len + thickness, center_x, y + thickness, thickness)
        # Refined bottom serif
        draw_ultra_smooth_line(center_x - serif_len, y + height - thickness, 
                       center_x + serif_len, y + height - thickness, thickness)
        
    elif digit == '2':
        # Ultra-smooth curves and lines
        mid_y = y + height // 2
        
        # Top horizontal
        draw_ultra_smooth_line(x + thickness, y + thickness, x + width - thickness, y + thickness, thickness)
        # Right vertical (top section)
        draw_ultra_smooth_line(x + width - thickness, y + thickness, x + width - thickness, mid_y, thickness)
        # Diagonal with anti-aliasing
        draw_ultra_smooth_line(x + width - thickness, mid_y, x + thickness, y + height - thickness, thickness)
        # Bottom horizontal
        draw_ultra_smooth_line(x + thickness, y + height - thickness, 
                       x + width - thickness, y + height - thickness, thickness)
        
    elif digit == '3':
        # Ultra-smooth three horizontal lines with right curves
        mid_y = y + height // 2
        # Top horizontal
        draw_ultra_smooth_line(x + thickness, y + thickness, x + width - thickness, y + thickness, thickness)
        # Middle horizontal
        draw_ultra_smooth_line(x + width//2, mid_y, x + width - thickness, mid_y, thickness)
        # Bottom horizontal
        draw_ultra_smooth_line(x + thickness, y + height - thickness, 
                       x + width - thickness, y + height - thickness, thickness)
        # Right verticals
        draw_ultra_smooth_line(x + width - thickness, y + thickness, x + width - thickness, mid_y, thickness)
        draw_ultra_smooth_line(x + width - thickness, mid_y, x + width - thickness, y + height - thickness, thickness)
        
    elif digit == '4':
        # Ultra-smooth left angle, right vertical, horizontal cross
        cross_y = y + 2 * height // 3
        # Left vertical (top part)
        draw_ultra_smooth_line(x + width//4, y + thickness, x + width//4, cross_y, thickness)
        # Horizontal cross
        draw_ultra_smooth_line(x + thickness, cross_y, x + width - thickness, cross_y, thickness)
        # Right vertical (full)
        draw_ultra_smooth_line(x + 3*width//4, y + thickness, x + 3*width//4, y + height - thickness, thickness)
        
    elif digit == '5':
        # Ultra-smooth top, left vertical, middle, bottom curve
        mid_y = y + height // 2
        # Top horizontal
        draw_ultra_smooth_line(x + thickness, y + thickness, x + width - thickness, y + thickness, thickness)
        # Left vertical (top half)
        draw_ultra_smooth_line(x + thickness, y + thickness, x + thickness, mid_y, thickness)
        # Middle horizontal
        draw_ultra_smooth_line(x + thickness, mid_y, x + width - thickness, mid_y, thickness)
        # Right vertical (bottom half)
        draw_ultra_smooth_line(x + width - thickness, mid_y, x + width - thickness, y + height - thickness, thickness)
        # Bottom horizontal
        draw_ultra_smooth_line(x + thickness, y + height - thickness, 
                       x + width - thickness, y + height - thickness, thickness)
        
    elif digit == '6':
        # Ultra-smooth left vertical, top curve, bottom rectangle
        mid_y = y + height // 2
        # Left vertical (full)
        draw_ultra_smooth_line(x + thickness, y + thickness, x + thickness, y + height - thickness, thickness)
        # Top horizontal
        draw_ultra_smooth_line(x + thickness, y + thickness, x + width//2, y + thickness, thickness)
        # Middle horizontal
        draw_ultra_smooth_line(x + thickness, mid_y, x + width - thickness, mid_y, thickness)
        # Bottom horizontal
        draw_ultra_smooth_line(x + thickness, y + height - thickness, 
                       x + width - thickness, y + height - thickness, thickness)
        # Right vertical (bottom half)
        draw_ultra_smooth_line(x + width - thickness, mid_y, x + width - thickness, y + height - thickness, thickness)
        
    elif digit == '7':
        # Ultra-smooth top horizontal and diagonal
        # Top line
        draw_ultra_smooth_line(x + thickness, y + thickness, x + width - thickness, y + thickness, thickness)
        # Diagonal
        draw_ultra_smooth_line(x + width - thickness, y + thickness, x + width//3, y + height - thickness, thickness)
        
    elif digit == '8':
        # Ultra-smooth two rectangles stacked with fine detail
        mid_y = y + height // 2
        # Top rectangle with enhanced smoothing
        draw.rectangle([x + thickness, y + thickness, x + width - thickness, mid_y], 
                      outline=color, width=thickness)
        # Bottom rectangle with enhanced smoothing
        draw.rectangle([x + thickness, mid_y, x + width - thickness, y + height - thickness], 
                      outline=color, width=thickness)
        # Add fine detail lines for ultra-smooth appearance
        if thickness > 2:
            draw.rectangle([x + thickness + 1, y + thickness + 1, x + width - thickness - 1, mid_y - 1], 
                          outline=color, width=1)
            draw.rectangle([x + thickness + 1, mid_y + 1, x + width - thickness - 1, y + height - thickness - 1], 
                          outline=color, width=1)
        
    elif digit == '9':
        # Ultra-smooth top rectangle with right tail
        mid_y = y + height // 2
        # Top rectangle
        draw.rectangle([x + thickness, y + thickness, x + width - thickness, mid_y], 
                      outline=color, width=thickness)
        # Right vertical tail
        draw_ultra_smooth_line(x + width - thickness, mid_y, x + width - thickness, y + height - thickness, thickness)
        # Bottom horizontal
        draw_ultra_smooth_line(x + width//2, y + height - thickness, 
                       x + width - thickness, y + height - thickness, thickness)
                       
    elif digit == '.':
        # Large dot
        dot_size = thickness * 2
        dot_y = y + height - dot_size - thickness
        draw.ellipse([x, dot_y, x + dot_size, dot_y + dot_size], fill=color)

def draw_vector_dot(draw, x, y, size, color=(0, 0, 0)):
    """Draw a simple circular dot for decimal points"""
    dot_size = max(3, size // 6)
    dot_y = y + size - dot_size - (size // 8)
    
    # Draw simple circle
    draw.ellipse([x, dot_y, x + dot_size, dot_y + dot_size], fill=color)

def draw_vector_panel_number(draw, panel_number, x, y, size, color=(0, 0, 0)):
    """Draw panel number using PROFESSIONAL FONT-LIKE digits - REFERENCE QUALITY"""
    current_x = x
    digit_width = int(size * 0.8)  # Tighter character width for better typography
    digit_spacing = max(3, size // 12)  # Professional letter spacing
    
    for char in panel_number:
        if char == '.':
            draw_vector_dot(draw, current_x, y, size, color)
            current_x += digit_width // 3  # Dots take minimal space
        elif char.isdigit():
            draw_vector_digit(draw, char, current_x, y, size, color)
            current_x += digit_width + digit_spacing
        elif char == ',':
            # Handle comma like dot but positioned lower
            draw_vector_dot(draw, current_x, y + size // 6, size, color)
            current_x += digit_width // 3
        else:
            # Skip other characters but leave small space
            current_x += digit_width // 4

def add_visual_overlays(draw, width, height, surface_name, show_name=False, show_cross=False, show_circle=False, show_logo=False):
    """Add visual overlays like name, cross, circle and logo to the pixel map"""
    
    logger.info(f"🎨 add_visual_overlays called: w={width}, h={height}, name='{surface_name}'")
    logger.info(f"🎨 Overlay flags: name={show_name}, cross={show_cross}, circle={show_circle}, logo={show_logo}")
    
    center_x = width // 2
    center_y = height // 2
    
    # 1. Add CENTER NAME (30% of canvas dimensions, amber color)
    if show_name and surface_name:
        # Calculate font size so that TEXT WIDTH is 30% of canvas width
        target_text_width = int(width * 0.3)  # Target: 30% of canvas width
        
        # Amber color as requested
        amber_color = (255, 191, 0)  # Pure amber
        
        try:
            # Try to load a default system font
            from PIL import ImageFont
            
            # Start with an estimated font size and adjust to fit target width
            font_size = max(20, int(target_text_width / len(surface_name) * 1.2))  # Rough estimate
            font_size = min(font_size, 200)  # Cap at reasonable size
            
            try:
                # Linux-compatible font paths for cloud deployment
                font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
            except:
                try:
                    # Alternative Linux font
                    font = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf", font_size)
                except:
                    try:
                        # Basic Linux font
                        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", font_size)
                    except:
                        try:
                            # Fallback to default font with fixed size
                            font = ImageFont.load_default()
                            # For default font, use simpler approach
                            text_width = len(surface_name) * 6  # Rough estimate for default font
                            text_height = 11  # Default font height
                            text_x = center_x - text_width // 2
                            text_y = center_y - text_height // 2
                            draw.text((text_x, text_y), surface_name, font=font, fill=amber_color)
                            logger.info(f"✅ Added center name with default font: '{surface_name}' at {text_x},{text_y}")
                            return  # Exit early - don't continue with complex font sizing
                        except Exception as fallback_error:
                            logger.error(f"❌ All font methods failed: {fallback_error}")
                            # Last resort: use vector text
                            font_size_vector = max(12, int(width * 0.05))
                            text_x = center_x - len(surface_name) * font_size_vector // 4
                            text_y = center_y - font_size_vector // 2
                            draw_vector_text(draw, surface_name, text_x, text_y, font_size_vector, amber_color)
                            logger.info(f"✅ Added center name with vector text: '{surface_name}'")
                            return
            
            # Simplified font sizing - avoid complex loops that can hang
            try:
                bbox = draw.textbbox((0, 0), surface_name, font=font)
                actual_width = bbox[2] - bbox[0]
                text_height = bbox[3] - bbox[1]
                
                # If text is too wide, scale down font
                if actual_width > target_text_width:
                    scale_factor = target_text_width / actual_width
                    font_size = int(font_size * scale_factor)
                    font_size = max(8, font_size)  # Minimum readable size
                    
                    # Reload font with new size
                    try:
                        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
                    except:
                        font = ImageFont.load_default()
                
                # Get final text dimensions
                bbox = draw.textbbox((0, 0), surface_name, font=font)
                text_width = bbox[2] - bbox[0]
                text_height = bbox[3] - bbox[1]
                
            except Exception as bbox_error:
                logger.error(f"❌ textbbox failed: {bbox_error}, using estimates")
                # Use estimates if textbbox fails
                text_width = len(surface_name) * font_size * 0.6
                text_height = font_size
            
            # Center the text precisely
            text_x = center_x - text_width // 2
            text_y = center_y - text_height // 2
            
            # Draw the surface name with normal font
            draw.text((text_x, text_y), surface_name, font=font, fill=amber_color)
            
            logger.info(f"✅ Added center name: '{surface_name}' at {text_x},{text_y} font_size={font_size} text_width={text_width} (target: {target_text_width})")
            
        except Exception as e:
            logger.error(f"❌ Font loading failed: {e}, falling back to vector text")
            # Fallback to vector text if font loading fails
            font_size = max(20, int(target_text_width / len(surface_name) * 1.2))
            text_width_estimate = len(surface_name) * font_size * 0.6
            text_x = center_x - int(text_width_estimate // 2)
            text_y = center_y - font_size // 2
            draw_vector_text(draw, surface_name, text_x, text_y, font_size, amber_color)
    
    # 2. Add CIRCLE (white line 1px thick, center to full height)
    if show_circle:
        circle_color = (255, 255, 255)  # White
        # Circle from center, filling top to bottom (radius = half height)
        radius = height // 2
        
        # Draw circle outline with 1px thickness
        bbox = [center_x - radius, center_y - radius, center_x + radius, center_y + radius]
        try:
            # PIL doesn't have a direct circle outline, so we'll use ellipse
            draw.ellipse(bbox, outline=circle_color, width=1)
            logger.info(f"✅ Added circle: center=({center_x},{center_y}) radius={radius}")
        except:
            # Fallback: draw as arc if ellipse fails
            draw.arc(bbox, 0, 360, fill=circle_color, width=1)
    
    # 3. Add CROSS LINES (diagonal from opposite corners)
    if show_cross:
        cross_color = (255, 255, 255)  # White
        
        # Draw diagonal lines from corners
        # Top-left to bottom-right
        draw.line([(0, 0), (width-1, height-1)], fill=cross_color, width=1)
        # Top-right to bottom-left  
        draw.line([(width-1, 0), (0, height-1)], fill=cross_color, width=1)
        
        logger.info(f"✅ Added cross lines: diagonal from corners")
    
    # 4. Add LOGO (placeholder for future implementation)
    if show_logo:
        # For now, just log that logo was requested
        logger.info(f"✅ Logo requested (not yet implemented)")

def draw_vector_text(draw, text, x, y, size, color):
    """Draw text using vector digits and basic characters"""
    current_x = x
    char_width = int(size * 0.8)
    char_spacing = max(2, size // 10)
    
    for char in text.upper():
        if char.isdigit():
            draw_vector_digit(draw, char, current_x, y, size, color)
        elif char.isalpha():
            # For letters, draw a simple representation using lines
            draw_vector_letter(draw, char, current_x, y, size, color)
        elif char == ' ':
            # Space character
            current_x += char_width // 2
            continue
        else:
            # Skip unknown characters
            pass
            
        current_x += char_width + char_spacing

def draw_vector_letter(draw, letter, x, y, size, color):
    """Draw basic vector letters using simple line patterns"""
    line_width = max(1, size // 20)
    
    # Simple letter patterns using lines
    if letter == 'A':
        # Draw letter A
        draw.line([(x, y + size), (x + size//2, y), (x + size, y + size)], fill=color, width=line_width)
        draw.line([(x + size//4, y + size//2), (x + 3*size//4, y + size//2)], fill=color, width=line_width)
    elif letter == 'B':
        # Draw letter B - simplified
        draw.line([(x, y), (x, y + size)], fill=color, width=line_width)
        draw.line([(x, y), (x + size//2, y)], fill=color, width=line_width)
        draw.line([(x, y + size//2), (x + size//2, y + size//2)], fill=color, width=line_width)
        draw.line([(x, y + size), (x + size//2, y + size)], fill=color, width=line_width)
    elif letter == 'C':
        # Draw letter C
        draw.line([(x + size, y), (x, y), (x, y + size), (x + size, y + size)], fill=color, width=line_width)
    elif letter == 'E':
        # Draw letter E
        draw.line([(x, y), (x, y + size)], fill=color, width=line_width)
        draw.line([(x, y), (x + size, y)], fill=color, width=line_width)
        draw.line([(x, y + size//2), (x + size//2, y + size//2)], fill=color, width=line_width)
        draw.line([(x, y + size), (x + size, y + size)], fill=color, width=line_width)
    elif letter == 'N':
        # Draw letter N
        draw.line([(x, y), (x, y + size)], fill=color, width=line_width)
        draw.line([(x, y), (x + size, y + size)], fill=color, width=line_width)
        draw.line([(x + size, y), (x + size, y + size)], fill=color, width=line_width)
    elif letter == 'O':
        # Draw letter O as rectangle outline
        draw.rectangle([x, y, x + size, y + size], outline=color, width=line_width)
    elif letter == 'R':
        # Draw letter R
        draw.line([(x, y), (x, y + size)], fill=color, width=line_width)
        draw.line([(x, y), (x + size, y)], fill=color, width=line_width)
        draw.line([(x, y + size//2), (x + size, y + size//2)], fill=color, width=line_width)
        draw.line([(x + size//2, y + size//2), (x + size, y + size)], fill=color, width=line_width)
    elif letter == 'S':
        # Draw letter S - simplified
        draw.line([(x + size, y), (x, y), (x, y + size//2), (x + size, y + size//2), (x + size, y + size), (x, y + size)], fill=color, width=line_width)
    elif letter == 'T':
        # Draw letter T
        draw.line([(x, y), (x + size, y)], fill=color, width=line_width)
        draw.line([(x + size//2, y), (x + size//2, y + size)], fill=color, width=line_width)
    else:
        # For other letters, draw a simple rectangle as placeholder
        draw.rectangle([x, y, x + size//2, y + size], outline=color, width=line_width)

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

def brighten_color(color, factor=0.3):
    """Brighten a color by the given factor (0.0 to 1.0)"""
    r, g, b = color
    # Brighten each component
    r = min(255, int(r + (255 - r) * factor))
    g = min(255, int(g + (255 - g) * factor))
    b = min(255, int(b + (255 - b) * factor))
    return (r, g, b)

@app.route('/')
def health_check():
    # FORCE REBUILD: v17.0 - Surface name parameter fixes MUST be deployed
    return jsonify({
        'service': 'LED Pixel Map Cloud Renderer - ENHANCED 200M',
        'status': 'healthy',
        'version': '17.1 - LINUX FONTS ACTIVE: DejaVu/Liberation fonts, simplified sizing, surface names should work',
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
        show_name = config.get('showName', False)
        show_cross = config.get('showCross', False)
        show_circle = config.get('showCircle', False)
        show_logo = config.get('showLogo', False)
        surface_index = config.get('surfaceIndex', 0)
        
        # Get surface name for center text overlay (default to "Screen One")
        surface_name = config.get('surfaceName', 'Screen One')
        
        # Add debug logging for visual overlays and grid controls
        logger.info(f"🎨 Visual Overlays: Name={show_name}, Cross={show_cross}, Circle={show_circle}, Logo={show_logo}")
        logger.info(f"🔧 Grid Controls: Grid={show_grid}, Panel Numbers={show_panel_numbers}")
        logger.info(f"📛 Surface Name: '{surface_name}' (show_name={show_name})")
        logger.info(f"🏷️ LED Name: '{led_name}'")
        
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
                'showName': show_name,
                'showCross': show_cross,
                'showCircle': show_circle,
                'showLogo': show_logo,
                'ledName': led_name,
                'surfaceName': surface_name
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
                    
                    # ENHANCED VECTOR NUMBERING: 15% of panel size for optimal visibility
                    number_size = int(min(panel_display_width, panel_display_height) * 0.15)  # Increased to 15%
                    number_size = max(12, number_size)  # Minimum 12px for enhanced visibility
                    
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
