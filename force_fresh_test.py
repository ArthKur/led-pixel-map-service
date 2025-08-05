#!/usr/bin/env python3
"""
Force a completely fresh test bypassing all caches
"""
import requests
import time

def force_fresh_test():
    """Test with cache-busting parameters"""
    
    # Use timestamp to bust any caches
    timestamp = int(time.time())
    
    url = "https://led-pixel-service.onrender.com/generate-pixel-map"
    
    params = {
        "product": "P2.5",
        "width": 100,
        "height": 100,
        "showGrid": "true",
        "cache_bust": timestamp,  # Force fresh request
        "debug": "true"
    }
    
    headers = {
        "Cache-Control": "no-cache, no-store, must-revalidate",
        "Pragma": "no-cache",
        "Expires": "0",
        "Content-Type": "application/json"
    }
    
    print(f"🚀 FRESH TEST - Cache Bust: {timestamp}")
    print(f"📡 URL: {url}")
    print(f"📋 Params: {params}")
    
    try:
        response = requests.post(url, json=params, headers=headers, timeout=30)
        print(f"✅ Status: {response.status_code}")
        
        if response.status_code == 200:
            filename = f"fresh_test_{timestamp}.png"
            with open(filename, 'wb') as f:
                f.write(response.content)
            print(f"💾 Saved: {filename}")
            print(f"📏 Size: {len(response.content)} bytes")
            
            # Open it immediately
            import subprocess
            subprocess.run(["open", filename])
            
            print(f"\n🔍 FRESH TEST RESULTS:")
            print(f"   File: {filename}")
            print(f"   Check if grid lines are WHITE or COLORED")
            print(f"   This bypasses ALL caches and Flutter app issues")
            
        else:
            print(f"❌ Error: {response.status_code}")
            print(f"Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    force_fresh_test()
