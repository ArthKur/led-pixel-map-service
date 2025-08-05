#!/usr/bin/env python3
"""Test script to demonstrate the panel numbers checkbox functionality"""

import requests
import json

def test_panel_numbering_options():
    """Test both options: with and without panel numbers"""
    
    service_url = "https://led-pixel-map-service-1.onrender.com"
    
    # Test configuration
    test_data_base = {
        "surface": {
            "panelsWidth": 10,
            "fullPanelsHeight": 6,
            "halfPanelsHeight": 0,
            "panelPixelWidth": 128,
            "panelPixelHeight": 128,
            "ledName": "Test LED Panel"
        },
        "config": {
            "surfaceIndex": 0,
            "showGrid": True
        }
    }
    
    print("🧪 TESTING PANEL NUMBERS CHECKBOX FUNCTIONALITY")
    print("=" * 60)
    
    # Test 1: WITH panel numbers
    print("🔢 Test 1: Generating pixel map WITH panel numbers...")
    test_data_with_numbers = test_data_base.copy()
    test_data_with_numbers["config"]["showPanelNumbers"] = True
    
    try:
        response = requests.post(
            f"{service_url}/generate-pixel-map",
            headers={'Content-Type': 'application/json'},
            json=test_data_with_numbers,
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                print(f"✅ SUCCESS: {result.get('dimensions', {}).get('width', 'N/A')}×{result.get('dimensions', {}).get('height', 'N/A')}px")
                print(f"   📊 File size: {result.get('file_size_mb', 0)} MB")
                print(f"   🔢 Panel numbers: ENABLED")
            else:
                print(f"❌ FAILED: {result}")
        else:
            print(f"❌ HTTP Error: {response.status_code}")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    print()
    
    # Test 2: WITHOUT panel numbers
    print("🚫 Test 2: Generating pixel map WITHOUT panel numbers...")
    test_data_without_numbers = test_data_base.copy()
    test_data_without_numbers["config"]["showPanelNumbers"] = False
    
    try:
        response = requests.post(
            f"{service_url}/generate-pixel-map",
            headers={'Content-Type': 'application/json'},
            json=test_data_without_numbers,
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                print(f"✅ SUCCESS: {result.get('dimensions', {}).get('width', 'N/A')}×{result.get('dimensions', {}).get('height', 'N/A')}px")
                print(f"   📊 File size: {result.get('file_size_mb', 0)} MB")
                print(f"   🚫 Panel numbers: DISABLED (clean grid)")
            else:
                print(f"❌ FAILED: {result}")
        else:
            print(f"❌ HTTP Error: {response.status_code}")
    except Exception as e:
        print(f"❌ Error: {e}")
    
    print()
    print("=" * 60)
    print("🎯 CHECKBOX FUNCTIONALITY TEST COMPLETE")
    print("")
    print("📋 How to use in Flutter app:")
    print("   1. Open Generate Pixel Maps dialog")
    print("   2. Look for 'Show Panel Numbers' checkbox in Export Options")
    print("   3. Check/uncheck to control panel numbering")
    print("   4. Generate pixel maps with your preferred setting")
    print("")
    print("✨ The checkbox allows you to:")
    print("   ✅ Generate maps WITH panel coordinates (for installation)")
    print("   🚫 Generate clean maps WITHOUT numbers (for content creation)")

if __name__ == "__main__":
    test_panel_numbering_options()
