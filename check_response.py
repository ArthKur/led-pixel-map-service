#!/usr/bin/env python3
"""
🔧 CHECK RESPONSE FORMAT
What is the service actually returning?
"""

import requests
import json

def check_response_format():
    url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
    
    data = {
        "surface": {
            "panelsWidth": 2,
            "fullPanelsHeight": 2,
            "halfPanelsHeight": 0,
            "panelPixelWidth": 100,
            "panelPixelHeight": 100,
            "ledName": "Absen PL2.5 Lite"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True,
            "showPanelNumbers": False,
            "showNames": False,
            "showCrosses": False,
            "showCircles": False,
            "showLetters": False
        }
    }
    
    print("🔧 CHECKING RESPONSE FORMAT")
    print("=" * 50)
    
    try:
        response = requests.post(url, json=data, timeout=15)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            
            print("Response keys:", list(result.keys()))
            
            if 'svgData' in result:
                svg_data = result['svgData']
                print(f"SVG data length: {len(svg_data)}")
                print(f"SVG starts with: {svg_data[:100]}...")
            
            if 'imageData' in result:
                image_data = result['imageData']
                print(f"Image data length: {len(image_data)}")
                print(f"Image starts with: {image_data[:50]}...")
            
            # Save the result to inspect
            with open('response_debug.json', 'w') as f:
                # Don't save the full data, just structure
                debug_result = {k: f"<{len(str(v))} chars>" if k in ['svgData', 'imageData'] else v 
                              for k, v in result.items()}
                json.dump(debug_result, f, indent=2)
            
            print("✅ Saved response structure to response_debug.json")
            
        else:
            print(f"Error: {response.text}")
            
    except Exception as e:
        print(f"Exception: {e}")

if __name__ == "__main__":
    check_response_format()
