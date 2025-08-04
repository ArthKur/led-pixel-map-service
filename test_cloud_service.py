#!/usr/bin/env python3
"""Test script for the cloud pixel map service"""

import requests
import json
import base64
import os

def test_cloud_service():
    # Test data for a large pixel map
    test_data = {
        "surface": {
            "panelsWidth": 100,
            "fullPanelsHeight": 6,
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
    
    print(f"Testing cloud service at: {service_url}")
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
            
            if result.get('success'):
                # Get image data
                image_base64 = result.get('image_base64', '')
                image_data = result.get('imageData', '')
                
                print(f"Image base64 length: {len(image_base64)}")
                print(f"Image data URL length: {len(image_data)}")
                print(f"File size: {result.get('file_size_mb', 0)} MB")
                print(f"Dimensions: {result.get('dimensions', {})}")
                print(f"Display dimensions: {result.get('display_dimensions', {})}")
                
                # Save the image data to a file for testing
                if image_base64:
                    try:
                        # Decode and save as SVG
                        image_bytes = base64.b64decode(image_base64)
                        with open('test_output.svg', 'wb') as f:
                            f.write(image_bytes)
                        print("✅ Saved test_output.svg")
                        
                        # Also save the data URL for browser testing
                        with open('test_output.html', 'w') as f:
                            f.write(f'''
<!DOCTYPE html>
<html>
<head>
    <title>Test Pixel Map</title>
</head>
<body>
    <h1>Generated Pixel Map</h1>
    <p>Dimensions: {result.get('dimensions', {})}</p>
    <p>File size: {result.get('file_size_mb', 0)} MB</p>
    <img src="{image_data}" alt="Pixel Map" style="max-width: 100%; border: 1px solid #ccc;">
    
    <br><br>
    <a href="{image_data}" download="pixel_map.png">Download as PNG</a>
</body>
</html>
                            ''')
                        print("✅ Saved test_output.html - open this in browser to test PNG download")
                        
                    except Exception as e:
                        print(f"❌ Error saving image: {e}")
                
            else:
                print(f"❌ Service returned success=false: {result}")
                
        else:
            print(f"❌ HTTP Error {response.status_code}: {response.text}")
            
    except Exception as e:
        print(f"❌ Error testing service: {e}")

if __name__ == "__main__":
    test_cloud_service()
