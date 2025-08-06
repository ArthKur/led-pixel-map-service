#!/usr/bin/env python3
"""
Test the cloud grid implementation
"""

import requests
import json
import time

def test_cloud_grid():
    """Test the grid implementation on cloud service"""
    
    print("🌐 Testing Cloud Grid Implementation")
    print("=" * 40)
    
    url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
    
    # Test data
    test_data = {
        "width": 3,
        "height": 2, 
        "ledPanelWidth": 100,
        "ledPanelHeight": 100,
        "ledName": "Absen",
        "showPanelNumbers": True,
        "showGrid": True  # ENABLE GRID
    }
    
    headers = {
        'Content-Type': 'application/json'
    }
    
    try:
        print("📤 Sending request with grid=True...")
        print(f"Request data: {json.dumps(test_data, indent=2)}")
        
        response = requests.post(url, json=test_data, headers=headers, timeout=60)
        
        print(f"📥 Response status: {response.status_code}")
        
        if response.status_code == 200:
            # Save the image
            with open('cloud_grid_test.png', 'wb') as f:
                f.write(response.content)
            print("✅ SUCCESS: Grid test image saved as 'cloud_grid_test.png'")
            print("   Check if the image shows brighter borders around panels")
            return True
        else:
            print(f"❌ FAILED: HTTP {response.status_code}")
            try:
                print(f"Response: {response.text}")
            except:
                print("Could not read response text")
            return False
            
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return False

def test_cloud_no_grid():
    """Test without grid for comparison"""
    
    print("\n🌐 Testing Cloud NO Grid (for comparison)")
    print("=" * 40)
    
    url = "https://led-pixel-map-service-1.onrender.com/generate-pixel-map"
    
    # Test data without grid
    test_data = {
        "width": 3,
        "height": 2, 
        "ledPanelWidth": 100,
        "ledPanelHeight": 100,
        "ledName": "Absen",
        "showPanelNumbers": True,
        "showGrid": False  # DISABLE GRID
    }
    
    headers = {
        'Content-Type': 'application/json'
    }
    
    try:
        print("📤 Sending request with grid=False...")
        
        response = requests.post(url, json=test_data, headers=headers, timeout=60)
        
        print(f"📥 Response status: {response.status_code}")
        
        if response.status_code == 200:
            # Save the image
            with open('cloud_no_grid_test.png', 'wb') as f:
                f.write(response.content)
            print("✅ SUCCESS: No-grid test image saved as 'cloud_no_grid_test.png'")
            return True
        else:
            print(f"❌ FAILED: HTTP {response.status_code}")
            try:
                print(f"Response: {response.text}")
            except:
                print("Could not read response text")
            return False
            
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return False

if __name__ == "__main__":
    success1 = test_cloud_grid()
    success2 = test_cloud_no_grid()
    
    if success1 and success2:
        print("\n🎉 BOTH TESTS SUCCESSFUL!")
        print("📋 Compare the two images:")
        print("   • cloud_grid_test.png (WITH brighter borders)")
        print("   • cloud_no_grid_test.png (WITHOUT borders)")
        print("   • The difference should show 30% brighter borders around each panel")
    else:
        print("\n⚠️  Some tests failed - check the output above")
