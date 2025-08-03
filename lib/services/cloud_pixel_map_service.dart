import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/surface_model.dart';

/// CLOUD PIXEL MAP SERVICE
///
/// Offloads pixel map generation to Python cloud service on Render.com
/// Removes all browser Canvas API limitations for unlimited image sizes
class CloudPixelMapService {
  // Cloud service URL - UPDATE THIS AFTER DEPLOYMENT
  static const String _baseUrl = 'https://led-pixel-map-service.onrender.com';
  
  // Local development URL
  static const String _localUrl = 'http://localhost:8080';
  
  // Use local for development, cloud for production
  static String get serviceUrl => _localUrl; // Temporarily force local service

  /// Generates pixel map using cloud service
  static Future<CloudPixelMapResult> generateCloudPixelMap(
    Surface surface,
    int index, {
    bool showGrid = true,
    bool showPanelNumbers = true,
  }) async {
    try {
      // Validate surface
      if (surface.calculation == null || surface.selectedLED == null) {
        return CloudPixelMapResult.error("Invalid surface data - missing calculation or LED selection");
      }

      final calc = surface.calculation!;
      final led = surface.selectedLED!;

      // Prepare request data
      final requestData = {
        'surface': {
          'panelsWidth': calc.panelsWidth,
          'fullPanelsHeight': calc.fullPanelsHeight,
          'halfPanelsHeight': calc.halfPanelsHeight,
          'panelPixelWidth': led.wPixel,
          'panelPixelHeight': led.hPixel,
          'ledName': led.name,
        },
        'config': {
          'surfaceIndex': index,
          'showGrid': showGrid,
          'showPanelNumbers': showPanelNumbers,
        },
      };

      debugPrint('Cloud Service: Sending request to $serviceUrl');
      debugPrint('Request data: ${jsonEncode(requestData)}');

      // Make HTTP request to cloud service
      final response = await http.post(
        Uri.parse('$serviceUrl/generate-pixel-map'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestData),
      ).timeout(
        const Duration(minutes: 5), // Allow 5 minutes for large images
      );

      debugPrint('Cloud Service: Response status ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          // Decode base64 image
          final imageBase64 = responseData['image_base64'] as String;
          final imageBytes = base64Decode(imageBase64);
          
          final dimensions = responseData['dimensions'];
          final fileSizeMB = responseData['file_size_mb'];
          final ledInfo = responseData['led_info'];
          
          debugPrint('Cloud Service: Success! Generated ${dimensions['width']}×${dimensions['height']}px (${fileSizeMB}MB)');
          
          return CloudPixelMapResult.success(
            imageBytes: imageBytes,
            width: dimensions['width'],
            height: dimensions['height'],
            fileSizeMB: fileSizeMB.toDouble(),
            ledInfo: ledInfo,
            serviceUrl: serviceUrl,
          );
        } else {
          final error = responseData['error'] ?? 'Unknown cloud service error';
          return CloudPixelMapResult.error(error);
        }
      } else {
        debugPrint('Cloud Service: Error response body: ${response.body}');
        return CloudPixelMapResult.error(
          'Cloud service error (${response.statusCode}): ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      debugPrint('Cloud Service: Exception: $e');
      
      // Provide helpful error messages
      String errorMessage = e.toString();
      if (errorMessage.contains('TimeoutException') || errorMessage.contains('timeout')) {
        errorMessage = 'Cloud service timeout - the image may be too large or service is busy. Try again in a moment.';
      } else if (errorMessage.contains('SocketException') || errorMessage.contains('connection')) {
        errorMessage = 'Cannot connect to cloud service. Check internet connection.';
      } else if (errorMessage.contains('FormatException')) {
        errorMessage = 'Invalid response from cloud service - service may be down.';
      }
      
      return CloudPixelMapResult.error(errorMessage);
    }
  }

  /// Health check for cloud service
  static Future<bool> isServiceHealthy() async {
    try {
      final response = await http.get(
        Uri.parse('$serviceUrl/'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      debugPrint('Cloud Service health check failed: $e');
      return false;
    }
  }

  /// Get service information
  static Future<Map<String, dynamic>?> getServiceInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$serviceUrl/'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Cloud Service info request failed: $e');
      return null;
    }
  }
}

/// Result class for cloud pixel map generation
class CloudPixelMapResult {
  final bool isSuccess;
  final Uint8List? imageBytes;
  final int? width;
  final int? height;
  final double? fileSizeMB;
  final Map<String, dynamic>? ledInfo;
  final String? serviceUrl;
  final String? errorMessage;

  const CloudPixelMapResult._({
    required this.isSuccess,
    this.imageBytes,
    this.width,
    this.height,
    this.fileSizeMB,
    this.ledInfo,
    this.serviceUrl,
    this.errorMessage,
  });

  factory CloudPixelMapResult.success({
    required Uint8List imageBytes,
    required int width,
    required int height,
    required double fileSizeMB,
    required Map<String, dynamic> ledInfo,
    required String serviceUrl,
  }) {
    return CloudPixelMapResult._(
      isSuccess: true,
      imageBytes: imageBytes,
      width: width,
      height: height,
      fileSizeMB: fileSizeMB,
      ledInfo: ledInfo,
      serviceUrl: serviceUrl,
    );
  }

  factory CloudPixelMapResult.error(String message) {
    return CloudPixelMapResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}
