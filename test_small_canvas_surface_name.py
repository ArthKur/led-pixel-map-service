import requests
import json

url = "http://localhost:5000/api/generate-pixel-map"

data = {
    "width": 2000,
    "height": 1000,
    "ledPanels": [{
        "width": 64,
        "height": 32,
        "panelSizeWidth": 320,
        "panelSizeHeight": 160
    }],
    "surfaceName": "TEST SURFACE SMALL",
    "showBorders": True,
    "showName": True
}

print("Sending small canvas surface name test request...")
response = requests.post(url, headers={'Content-Type': 'application/json'}, data=json.dumps(data))

print(f"Status: {response.status_code}")
if response.status_code == 200:
    result = response.json()
    print(f"Success: {result.get('success')}")
    if 'pngFileName' in result:
        print(f"✅ Small canvas surface name test image saved")
        print(f"Dimensions: {{'height': {data['height']}, 'width': {data['width']}}}")
        print(f"File size: {result.get('fileSize', 'Unknown')} MB")
        print(f"Panel info: {result.get('panelInfo')}")
    else:
        print(f"❌ Error: {result.get('error')}")
else:
    print(f"❌ HTTP Error: {response.text}")
