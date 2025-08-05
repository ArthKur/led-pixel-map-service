import requests
import base64

# Test surface name functionality
response = requests.post('https://led-pixel-map-service-1.onrender.com/generate-pixel-map', json={
    'wallWidthM': 0.1,
    'wallHeightM': 0.1,
    'selectedLed': 'Absen PL0.6 (3840x2160)',
    'showGrid': True,
    'showPanelNumbers': True,
    'showName': True,  # Enable surface name display
    'surfaceName': 'Test Screen',  # Custom surface name
    'format': 'png'
})

print('Status:', response.status_code)
data = response.json()
print('Success:', data.get('success'))
print('Panel info:', data.get('panel_info'))

# Save the image to test surface name
if 'image_base64' in data:
    with open('/Users/arturkurowski/Desktop/PROJECT /led_calculator_2_0/surface_name_test.png', 'wb') as f:
        f.write(base64.b64decode(data['image_base64']))
    print('✅ Surface name test image saved')
else:
    print('❌ No image data in response')
    print('Response:', data)
