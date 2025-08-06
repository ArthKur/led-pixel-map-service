import requests
import base64

# Test with proper Flutter app API structure
response = requests.post('https://led-pixel-map-service-1.onrender.com/generate-pixel-map', json={
    'surface': {
        'panelsWidth': 10,
        'fullPanelsHeight': 5,
        'halfPanelsHeight': 0,
        'panelPixelWidth': 200,
        'panelPixelHeight': 200,
        'ledName': 'Absen PL0.6 (3840x2160)',
    },
    'config': {
        'surfaceIndex': 0,
        'showGrid': True,
        'showPanelNumbers': True,
        'showName': True,  # Enable surface name display
        'showCross': False,
        'showCircle': False,
        'showLogo': False,
        'surfaceName': 'Screen One',  # Surface name as sent by Flutter
    },
})

print('Status:', response.status_code)
print('Headers:', response.headers.get('Content-Type'))

if response.status_code == 200:
    data = response.json()
    print('Success:', data.get('success'))
    print('Panel info:', data.get('panel_info'))
    print('Technical specs:', data.get('technical_specs'))
    
    # Save the image to test surface name
    if 'image_base64' in data:
        with open('/Users/arturkurowski/Desktop/PROJECT /led_calculator_2_0/flutter_surface_name_test.png', 'wb') as f:
            f.write(base64.b64decode(data['image_base64']))
        print('✅ Flutter-style surface name test image saved')
        print('Dimensions:', data.get('dimensions'))
    else:
        print('❌ No image data in response')
        print('Available keys:', list(data.keys()))
else:
    print('❌ Request failed')
    print('Response:', response.text)
