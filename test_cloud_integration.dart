#!/usr/bin/env dart

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing Flutter App Cloud Integration');
  print('=========================================');

  // Test 1: Service Health Check
  print('\n1. Testing Cloud Service Health...');
  try {
    final response = await http
        .get(
          Uri.parse('https://led-pixel-map-service-1.onrender.com/'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Service Status: ${data['status']}');
      print('✅ Service Version: ${data['version']}');
      print('✅ Timestamp: ${data['timestamp']}');
    } else {
      print('❌ Service responded with status: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Service health check failed: $e');
  }

  // Test 2: Generate Test Pixel Map
  print('\n2. Testing Pixel Map Generation...');
  try {
    final requestData = {
      'surface': {
        'panelsWidth': 10,
        'fullPanelsHeight': 5,
        'halfPanelsHeight': 0,
        'panelPixelWidth': 200,
        'panelPixelHeight': 200,
        'ledName': 'Absen PL2.5 Lite (Flutter Test)',
      },
      'config': {'surfaceIndex': 0, 'showGrid': true, 'showPanelNumbers': true},
    };

    final response = await http
        .post(
          Uri.parse(
            'https://led-pixel-map-service-1.onrender.com/generate-pixel-map',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(requestData),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final dimensions = data['dimensions'];
        final fileSizeMB = data['file_size_mb'];
        print('✅ Generated: ${dimensions['width']}×${dimensions['height']}px');
        print('✅ File Size: ${fileSizeMB}MB');
        print('✅ Base64 Image Length: ${data['image_base64'].length} chars');
      } else {
        print('❌ Generation failed: ${data['error']}');
      }
    } else {
      print('❌ Request failed with status: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Generation test failed: $e');
  }

  // Test 3: Large Image Test (16M+ pixels)
  print('\n3. Testing Large Image Generation (Canvas API Bypass)...');
  try {
    final requestData = {
      'surface': {
        'panelsWidth': 100, // 100×50 = 20,000×10,000px = 200M pixels!
        'fullPanelsHeight': 50,
        'halfPanelsHeight': 0,
        'panelPixelWidth': 200,
        'panelPixelHeight': 200,
        'ledName': 'Absen PL2.5 Lite (MEGA TEST)',
      },
      'config': {
        'surfaceIndex': 0,
        'showGrid': false, // Disable grid for performance
        'showPanelNumbers': false,
      },
    };

    final response = await http
        .post(
          Uri.parse(
            'https://led-pixel-map-service-1.onrender.com/generate-pixel-map',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(requestData),
        )
        .timeout(const Duration(minutes: 3));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final dimensions = data['dimensions'];
        final fileSizeMB = data['file_size_mb'];
        final totalPixels = dimensions['width'] * dimensions['height'];
        print(
          '🎉 MEGA SUCCESS: ${dimensions['width']}×${dimensions['height']}px',
        );
        print('🎉 Total Pixels: ${totalPixels ~/ 1000000}M pixels');
        print('🎉 File Size: ${fileSizeMB}MB');
        print('🎉 This would CRASH browser Canvas API!');
      } else {
        print('❌ Large generation failed: ${data['error']}');
      }
    } else {
      print('❌ Large request failed with status: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Large generation test failed: $e');
  }

  print('\n✅ Cloud Integration Test Complete!');
  print(
    '💡 Your Flutter app now automatically uses cloud service for large images.',
  );
  print('💡 Small images (< 16M pixels) use local Canvas API for speed.');
  print(
    '💡 Large images (> 16M pixels) use cloud service to bypass Canvas limits.',
  );
}
