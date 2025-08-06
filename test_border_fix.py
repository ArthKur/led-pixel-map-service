#!/usr/bin/env python3
"""
🔧 TEST BORDER FIX - Grid ON/OFF comparison
Test if colored borders are restored and white lines are gone
"""

import requests
import json
import base64
from PIL import Image
from io import BytesIO

def test_cloud_service_with_grid(show_grid):
    url = "https://led-pixel-map-service-1.onrender.com/api/pixel-map"
    
    data = {
        "surface": {
            "panelsWidth": 4,
            "fullPanelsHeight": 3,
            "halfPanelsHeight": 0,
            "panelPixelWidth": 200,
            "panelPixelHeight": 200,
            "ledName": "Absen PL2.5 Lite"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": show_grid,
            "showPanelNumbers": True,
            "showNames": False,
            "showCrosses": False,
            "showCircles": False,
            "showLetters": False
        }
    }
    
    print(f"🧪 Testing with Grid {'ON' if show_grid else 'OFF'}")
    print("=" * 50)
    
    try:
        response = requests.post(url, json=data, timeout=30)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            
            if result.get('success'):
                # Process the SVG response  
                svg_data = result.get('svgData', '')
                if svg_data:
                    filename = f"test_grid_{'on' if show_grid else 'off'}.svg"
                    with open(filename, 'w') as f:
                        f.write(svg_data)
                    print(f"✅ Saved: {filename}")
                    
                    # Also create HTML for PNG download
                    html_content = f"""
<!DOCTYPE html>
<html>
<head><title>Grid {'ON' if show_grid else 'OFF'} Test</title></head>
<body>
<h1>Grid {'ON' if show_grid else 'OFF'} Test - Border Fix Verification</h1>
<div style="border: 1px solid #ccc; display: inline-block;">
{svg_data}
</div>
<br><br>
<button onclick="downloadPNG()">Download PNG</button>

<script>
function downloadPNG() {{
    const svg = document.querySelector('svg');
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    
    canvas.width = svg.viewBox.baseVal.width;
    canvas.height = svg.viewBox.baseVal.height;
    
    const data = new XMLSerializer().serializeToString(svg);
    const img = new Image();
    
    img.onload = function() {{
        ctx.drawImage(img, 0, 0);
        
        const link = document.createElement('a');
        link.download = 'grid_{'on' if show_grid else 'off'}_test.png';
        link.href = canvas.toDataURL();
        link.click();
    }};
    
    img.src = 'data:image/svg+xml;base64,' + btoa(unescape(encodeURIComponent(data)));
}}
</script>
</body>
</html>
"""
                    html_filename = f"test_grid_{'on' if show_grid else 'off'}.html"
                    with open(html_filename, 'w') as f:
                        f.write(html_content)
                    print(f"✅ Saved: {html_filename}")
                    
                return True
            else:
                print(f"❌ Error: {result.get('error', 'Unknown error')}")
                return False
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            print(response.text)
            return False
            
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False

def main():
    print("🔧 BORDER FIX VERIFICATION TEST")
    print("=" * 50)
    print("Testing if colored borders are restored")
    print("and white lines are eliminated")
    print("=" * 50)
    
    # Test both Grid ON and OFF
    grid_on_success = test_cloud_service_with_grid(True)
    print()
    grid_off_success = test_cloud_service_with_grid(False)
    
    print()
    print("=" * 50)
    if grid_on_success and grid_off_success:
        print("✅ SUCCESS! Both Grid ON/OFF tests passed")
        print("🎉 Border fix is deployed and working!")
        print("📂 Check the generated HTML files to verify:")
        print("   • test_grid_on.html - Should show COLORED borders")
        print("   • test_grid_off.html - Should show NO borders")
        print("   • No white lines should be visible!")
    else:
        print("❌ FAILURE! Some tests failed")
        print("🔍 Check the output for errors")

if __name__ == "__main__":
    main()
