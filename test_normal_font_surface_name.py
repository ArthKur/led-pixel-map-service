import requests
import base64

# Test normal font surface name functionality
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
        'surfaceName': 'Screen One',  # Surface name to display
    },
})

print('Status:', response.status_code)

if response.status_code == 200:
    data = response.json()
    print('Success:', data.get('success'))
    
    # Save the image to test normal font surface name
    if 'image_base64' in data:
        with open('/Users/arturkurowski/Desktop/PROJECT /led_calculator_2_0/normal_font_surface_name_test.png', 'wb') as f:
            f.write(base64.b64decode(data['image_base64']))
        print('✅ Normal font surface name test image saved')
        print('Dimensions:', data.get('dimensions'))
        print('File size:', data.get('file_size_mb'), 'MB')
    else:
        print('❌ No image data in response')
        print('Available keys:', list(data.keys()))
else:
    print('❌ Request failed')
    print('Response:', response.text)
