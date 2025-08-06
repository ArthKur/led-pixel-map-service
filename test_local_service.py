#!/usr/bin/env python3
"""
Test local pixel service to verify grid colors
"""
import requests
import time

def test_local_service():
    """Test local service to see grid colors"""
    
    url = "http://localhost:5001/generate-pixel-map"
    
    data = {
        "product": "P2.5",
        "width": 100,
        "height": 100,
        "showGrid": True  # Use boolean instead of string
    }
    
    headers = {
        "Content-Type": "application/json"
    }
    
    print(f"🧪 LOCAL SERVICE TEST")
    print(f"📡 URL: {url}")
    print(f"📋 Data: {data}")
    
    try:
        response = requests.post(url, json=data, headers=headers, timeout=30)
        print(f"✅ Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            if 'imageData' in result:
                # Decode base64 image
                import base64
                image_data = base64.b64decode(result['imageData'])
                
                filename = "local_test_grid.png"
                with open(filename, 'wb') as f:
                    f.write(image_data)
                    
                print(f"💾 Saved: {filename}")
                print(f"📏 Size: {len(image_data)} bytes")
                
                # Open it immediately
                import subprocess
                subprocess.run(["open", filename])
                
                print(f"\n🔍 LOCAL TEST RESULTS:")
                print(f"   File: {filename}")
                print(f"   This is from your ENHANCED cloud service code")
                print(f"   Check if grid lines are WHITE or BRIGHTER COLORED")
                print(f"   If COLORED: Your code works, cloud deployment issue")
                print(f"   If WHITE: Code issue in the service itself")
                
            else:
                print(f"❌ No imageData in response")
                print(f"Response: {result}")
        else:
            print(f"❌ Error: {response.status_code}")
            print(f"Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_local_service()
