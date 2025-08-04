#!/usr/bin/env python3
"""Test script to verify PNG generation"""

import requests
import json
import base64
import os
from PIL import Image
import io

def test_png_generation():
    # Test data for a medium-sized pixel map
    test_data = {
        "surface": {
            "panelsWidth": 50,
            "fullPanelsHeight": 3,
            "halfPanelsHeight": 0,
            "panelPixelWidth": 200,
            "panelPixelHeight": 200,
            "ledName": "Absen PL2.5 Lite"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,
            "showPanelNumbers": True
        }
    }
    
    service_url = "https://led-pixel-map-service-1.onrender.com"
    
    print(f"Testing PNG generation at: {service_url}")
    print(f"Test data: {json.dumps(test_data, indent=2)}")
    
    try:
        # Make request to cloud service
        response = requests.post(
            f"{service_url}/generate-pixel-map",
            headers={
                'Content-Type': 'application/json',
                'Accept': 'application/json',
            },
            json=test_data,
            timeout=300  # 5 minutes
        )
        
        print(f"Response status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"Success: {result.get('success', False)}")
            print(f"Format: {result.get('format', 'unknown')}")
            
            if result.get('success'):
                # Get image data
                image_base64 = result.get('image_base64', '')
                image_data = result.get('imageData', '')
                
                print(f"Image base64 length: {len(image_base64)}")
                print(f"Image data URL length: {len(image_data)}")
                print(f"File size: {result.get('file_size_mb', 0)} MB")
                print(f"Dimensions: {result.get('dimensions', {})}")
                print(f"Display dimensions: {result.get('display_dimensions', {})}")
                
                # Test if it's actually PNG
                if image_base64:
                    try:
                        # Decode the base64 data
                        image_bytes = base64.b64decode(image_base64)
                        
                        # Check PNG signature
                        png_signature = image_bytes[:8]
                        expected_png_signature = b'\x89PNG\r\n\x1a\n'
                        
                        if png_signature == expected_png_signature:
                            print("✅ CONFIRMED: File has valid PNG signature!")
                            
                            # Try to open with PIL to double-check
                            image = Image.open(io.BytesIO(image_bytes))
                            print(f"✅ PIL confirms: Format={image.format}, Size={image.size}, Mode={image.mode}")
                            
                            # Save as PNG file
                            with open('test_output.png', 'wb') as f:
                                f.write(image_bytes)
                            print("✅ Saved test_output.png - this is a real PNG file!")
                            
                            # Also save data URL as HTML for browser test
                            with open('test_png_download.html', 'w') as f:
                                f.write(f'''
<!DOCTYPE html>
<html>
<head>
    <title>PNG Test - LED Pixel Map</title>
</head>
<body>
    <h1>Generated PNG Pixel Map</h1>
    <p>Format: {result.get('format', 'PNG')}</p>
    <p>Dimensions: {result.get('dimensions', {})}</p>
    <p>File size: {result.get('file_size_mb', 0)} MB</p>
    <img src="{image_data}" alt="Pixel Map" style="max-width: 100%; border: 1px solid #ccc;">
    
    <br><br>
    <a href="{image_data}" download="pixel_map_test.png">Download PNG</a>
    
    <h2>Technical Details:</h2>
    <p>PNG Signature: ✅ Valid</p>
    <p>PIL Verification: ✅ Confirmed PNG format</p>
    <p>Generation Method: Pillow-based cloud service</p>
</body>
</html>
                                ''')
                            print("✅ Saved test_png_download.html")
                        else:
                            print(f"❌ INVALID PNG: Got signature {png_signature}, expected {expected_png_signature}")
                            print("This might still be SVG content!")
                            
                            # Try to decode as text to see if it's SVG
                            try:
                                text_content = image_bytes.decode('utf-8')
                                if '<svg' in text_content:
                                    print("❌ CONFIRMED: This is SVG content, not PNG!")
                                else:
                                    print("❌ Unknown binary format")
                            except:
                                print("❌ Not text/SVG, but also not valid PNG")
                        
                    except Exception as e:
                        print(f"❌ Error processing image data: {e}")
                
            else:
                print(f"❌ Service returned success=false: {result}")
                
        else:
            print(f"❌ HTTP Error {response.status_code}: {response.text}")
            
    except Exception as e:
        print(f"❌ Error testing service: {e}")

if __name__ == "__main__":
    test_png_generation()
