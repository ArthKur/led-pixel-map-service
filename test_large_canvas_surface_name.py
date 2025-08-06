import requests
import base64

# Test normal font with larger canvas to verify 30% sizing
response = requests.post('https://led-pixel-map-service-1.onrender.com/generate-pixel-map', json={
    'surface': {
        'panelsWidth': 20,  # Larger canvas
        'fullPanelsHeight': 10,
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
        'surfaceName': 'Large Screen',  # Surface name to display
    },
})

print('Status:', response.status_code)

if response.status_code == 200:
    data = response.json()
    print('Success:', data.get('success'))
    
    # Save the image to test normal font surface name on larger canvas
    if 'image_base64' in data:
        with open('/Users/arturkurowski/Desktop/PROJECT /led_calculator_2_0/large_canvas_surface_name_test.png', 'wb') as f:
            f.write(base64.b64decode(data['image_base64']))
        print('✅ Large canvas surface name test image saved')
        print('Dimensions:', data.get('dimensions'))
        print('File size:', data.get('file_size_mb'), 'MB')
        print('Panel info:', data.get('panel_info'))
    else:
        print('❌ No image data in response')
        print('Available keys:', list(data.keys()))
else:
    print('❌ Request failed')
    print('Response:', response.text)
