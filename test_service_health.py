#!/usr/bin/env python3
"""
Quick test to verify our cloud service is working and accessible
"""

import requests
import json

def test_service_health():
    """Test if the cloud service is healthy"""
    url = "https://led-pixel-map-service-1.onrender.com/"
    
    try:
        response = requests.get(url, timeout=10)
        print(f"📡 Service URL: {url}")
        print(f"📊 Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Service: {data.get('service', 'Unknown')}")
            print(f"🔧 Version: {data.get('version', 'Unknown')}")
            print(f"💚 Status: {data.get('status', 'Unknown')}")
            print(f"🎯 Features: {data.get('features', 'None listed')}")
            return True
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Connection Error: {e}")
        return False

if __name__ == "__main__":
    print("🔍 CLOUD SERVICE HEALTH CHECK")
    print("=" * 50)
    
    if test_service_health():
        print("\n✅ Cloud service is healthy and ready!")
        print("🎯 Flutter app should be able to connect successfully")
    else:
        print("\n❌ Cloud service is not accessible")
        print("🔧 Check internet connection or service status")
