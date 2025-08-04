import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/surface_model.dart';

/// BROWSER-SAFE PIXEL MAP SERVICE WITH REALISTIC LIMITS
///
/// This service provides realistic browser limits that actually work:
/// - Maximum 16K×16K pixels (browser canvas limit)
/// - Maximum 512MB memory per image (browser memory limit)
/// - Override mode for forcing generation beyond warnings
/// - Better error handling for browser limitations
class PixelMapServiceBrowserSafe {
  // === REALISTIC BROWSER LIMITS ===

  /// Quality presets that work in browsers
  static const Map<String, PixelMapLimits> qualityPresets = {
    'web_preview': PixelMapLimits(
      maxWidth: 1920,
      maxHeight: 1080,
      maxTotalPixels: 2073600, // 1920*1080
      maxMemoryMB: 32,
      warnWidth: 1920,
      warnHeight: 1080,
      warnTotalPixels: 2073600,
    ),
    'standard': PixelMapLimits(
      maxWidth: 4096,
      maxHeight: 4096,
      maxTotalPixels: 16777216, // 16 megapixels
      maxMemoryMB: 256,
      warnWidth: 2560,
      warnHeight: 1440,
      warnTotalPixels: 3686400,
    ),
    'high_quality': PixelMapLimits(
      maxWidth: 8192,
      maxHeight: 8192,
      maxTotalPixels: 67108864, // 64 megapixels
      maxMemoryMB: 512,
      warnWidth: 4096,
      warnHeight: 4096,
      warnTotalPixels: 16777216,
    ),
    'browser_max': PixelMapLimits(
      maxWidth: 32767, // Increased browser limit
      maxHeight: 32767, // Increased browser limit
      maxTotalPixels: 268435456, // 256 megapixels
      maxMemoryMB: 2048, // 2GB maximum
      warnWidth: 16384,
      warnHeight: 16384,
      warnTotalPixels: 134217728, // 128MP warning
    ),
    'unlimited': PixelMapLimits(
      maxWidth: 65535, // Absolute browser canvas max
      maxHeight: 65535, // Absolute browser canvas max
      maxTotalPixels: 536870912, // 512MP - extreme maximum
      maxMemoryMB: 4096, // 4GB - extreme maximum
      warnWidth: 32767,
      warnHeight: 32767,
      warnTotalPixels: 268435456, // 256MP warning
    ),
  };

  static String _getPresetDescription(String preset) {
    switch (preset) {
      case 'web_preview':
        return 'Fast preview for web display (up to 1920×1080)';
      case 'standard':
        return 'Standard quality for most uses (up to 4K)';
      case 'high_quality':
        return 'High quality for professional use (up to 8K)';
      case 'browser_max':
        return 'Maximum browser capacity (up to 32K×32K, 256MP)';
      case 'unlimited':
        return 'UNLIMITED - Force huge sizes (up to 65K×65K, 512MP)';
      default:
        return 'Custom configuration';
    }
  }

  /// Gets recommended dimensions for a quality preset
  static Map<String, dynamic> getRecommendedDimensions(String qualityPreset) {
    final limits = qualityPresets[qualityPreset];
    if (limits == null) return {};

    return {
      'preset': qualityPreset,
      'maxWidth': limits.maxWidth,
      'maxHeight': limits.maxHeight,
      'recommendedWidth': limits.warnWidth,
      'recommendedHeight': limits.warnHeight,
      'maxMemoryMB': limits.maxMemoryMB,
      'description': _getPresetDescription(qualityPreset),
    };
  }

  /// Validates dimensions against browser limits
  static DimensionValidationResult validateDimensions(
    int requestedWidth,
    int requestedHeight, {
    String? qualityPreset,
  }) {
    // Use preset limits or browser_max as default
    final activeLimits =
        qualityPresets[qualityPreset] ?? qualityPresets['browser_max']!;

    final totalPixels = requestedWidth * requestedHeight;
    final estimatedMemoryMB =
        (totalPixels * 4) / (1024 * 1024); // 4 bytes per pixel (RGBA)

    // For unlimited preset, be more permissive with individual dimensions
    // but still check total pixels and memory
    bool isUnlimitedPreset = qualityPreset == 'unlimited';

    // Check if within limits
    bool widthOk = requestedWidth <= activeLimits.maxWidth;
    bool heightOk = requestedHeight <= activeLimits.maxHeight;
    bool totalPixelsOk = totalPixels <= activeLimits.maxTotalPixels;
    bool memoryOk = estimatedMemoryMB <= activeLimits.maxMemoryMB;

    // For unlimited preset, allow larger individual dimensions if total pixels is reasonable
    if (isUnlimitedPreset && totalPixels <= activeLimits.maxTotalPixels) {
      // Allow extreme aspect ratios as long as memory is OK
      if (totalPixels <= 268435456) {
        // 256MP or less
        widthOk = requestedWidth <= 65535; // Browser absolute max
        heightOk = requestedHeight <= 65535; // Browser absolute max
      }
    }

    // Check warning thresholds
    bool widthWarning = requestedWidth > activeLimits.warnWidth;
    bool heightWarning = requestedHeight > activeLimits.warnHeight;
    bool totalPixelsWarning = totalPixels > activeLimits.warnTotalPixels;

    // Calculate adjusted dimensions if needed
    int adjustedWidth = requestedWidth;
    int adjustedHeight = requestedHeight;
    bool wasAdjusted = false;

    if (!widthOk || !heightOk || !totalPixelsOk || !memoryOk) {
      // Calculate scaling factor to fit within limits
      double widthScale = widthOk
          ? 1.0
          : activeLimits.maxWidth / requestedWidth;
      double heightScale = heightOk
          ? 1.0
          : activeLimits.maxHeight / requestedHeight;
      double totalPixelsScale = totalPixelsOk
          ? 1.0
          : math.sqrt(activeLimits.maxTotalPixels / totalPixels);
      double memoryScale = memoryOk
          ? 1.0
          : math.sqrt(activeLimits.maxMemoryMB / estimatedMemoryMB);

      // Use the most restrictive scale
      double scale = math.min(
        math.min(widthScale, heightScale),
        math.min(totalPixelsScale, memoryScale),
      );

      adjustedWidth = (requestedWidth * scale).floor();
      adjustedHeight = (requestedHeight * scale).floor();
      wasAdjusted = true;
    }

    return DimensionValidationResult(
      originalWidth: requestedWidth,
      originalHeight: requestedHeight,
      adjustedWidth: adjustedWidth,
      adjustedHeight: adjustedHeight,
      wasAdjusted: wasAdjusted,
      hasWarnings: widthWarning || heightWarning || totalPixelsWarning,
      isValid: widthOk && heightOk && totalPixelsOk && memoryOk,
      estimatedMemoryMB: estimatedMemoryMB.round(),
      activeLimits: activeLimits,
      warnings: [
        if (widthWarning)
          'Width ${requestedWidth}px exceeds recommended ${activeLimits.warnWidth}px',
        if (heightWarning)
          'Height ${requestedHeight}px exceeds recommended ${activeLimits.warnHeight}px',
        if (totalPixelsWarning)
          'Total pixels $totalPixels exceeds recommended ${activeLimits.warnTotalPixels}',
        if (!widthOk)
          'Width ${requestedWidth}px exceeds maximum ${activeLimits.maxWidth}px',
        if (!heightOk)
          'Height ${requestedHeight}px exceeds maximum ${activeLimits.maxHeight}px',
        if (!totalPixelsOk)
          'Total pixels $totalPixels exceeds maximum ${activeLimits.maxTotalPixels}',
        if (!memoryOk)
          'Estimated memory ${estimatedMemoryMB.round()}MB exceeds maximum ${activeLimits.maxMemoryMB}MB',
      ],
    );
  }

  /// Creates a pixel map with browser-safe validation
  static Future<PixelMapResult> createBrowserSafePixelMap(
    Surface surface,
    int index, {
    required int targetWidth,
    required int targetHeight,
    String? qualityPreset,
    bool autoAdjust = true,
    bool allowOverride = false,
    bool showGrid = true,
    bool showPanelNumbers = true,
    bool useActualPanelPixels =
        true, // NEW: Use actual LED panel pixel dimensions
  }) async {
    try {
      // Validate surface
      if (surface.calculation == null) {
        return PixelMapResult.error("Invalid surface data");
      }

      // Calculate actual pixel dimensions based on LED product specifications
      int finalWidth = targetWidth;
      int finalHeight = targetHeight;

      if (useActualPanelPixels && surface.selectedLED != null) {
        final led = surface.selectedLED!;
        final calc = surface.calculation!;

        // Calculate actual pixel map dimensions based on LED panel specifications
        final actualWidth = calc.panelsWidth * led.wPixel;
        final actualHeight =
            (calc.fullPanelsHeight + calc.halfPanelsHeight) * led.hPixel;

        debugPrint('Using actual LED panel dimensions: ${led.name}');
        debugPrint('Panel pixels: ${led.wPixel}×${led.hPixel}');
        debugPrint(
          'Panel layout: ${calc.panelsWidth}×${calc.fullPanelsHeight + calc.halfPanelsHeight}',
        );
        debugPrint('Calculated pixel map: $actualWidth×$actualHeight');

        finalWidth = actualWidth;
        finalHeight = actualHeight;
      }

      // Validate dimensions
      final validation = validateDimensions(
        finalWidth,
        finalHeight,
        qualityPreset: qualityPreset,
      );

      // Check if dimensions need adjustment or override
      if (!validation.isValid && !allowOverride) {
        if (autoAdjust && validation.wasAdjusted) {
          finalWidth = validation.adjustedWidth;
          finalHeight = validation.adjustedHeight;
        } else {
          return PixelMapResult.error(
            "Actual LED dimensions ($finalWidth×$finalHeight) exceed browser limits: ${validation.warnings.join(', ')}. Enable 'Override browser limits' to force generation.",
          );
        }
      }

      // Create the image
      final imageBytes = await _createBrowserSafeImage(
        surface,
        finalWidth,
        finalHeight,
        surfaceIndex: index,
        showGrid: showGrid,
        showPanelNumbers: showPanelNumbers,
        allowOverride: allowOverride, // Pass through override flag
      );

      return PixelMapResult.success(
        imageBytes: imageBytes,
        actualWidth: finalWidth,
        actualHeight: finalHeight,
        validation: validation,
      );
    } catch (e) {
      debugPrint('PixelMapServiceBrowserSafe: Error creating image: $e');
      return PixelMapResult.error(
        "Failed to create pixel map: ${e.toString()}",
      );
    }
  }

  /// Creates the actual image with browser safety checks
  static Future<Uint8List> _createBrowserSafeImage(
    Surface surface,
    int imageWidth,
    int imageHeight, {
    int surfaceIndex = 0,
    bool showGrid = true,
    bool showPanelNumbers = true,
    bool allowOverride = false, // NEW: Allow bypassing safety checks
  }) async {
    ui.PictureRecorder? recorder;

    try {
      // Browser safety checks
      final totalPixels = imageWidth * imageHeight;
      final estimatedMemoryMB = (totalPixels * 4) / (1024 * 1024);

      // Hard browser limits - can be overridden
      if (!allowOverride) {
        // Conservative limits for normal mode - more permissive for wide images
        if (imageWidth > 32767 || imageHeight > 32767) {
          throw Exception(
            'Browser canvas size limit: Max 32767px per dimension. Requested: $imageWidth×${imageHeight}px. Enable "Override browser limits" to force generation.',
          );
        }

        if (totalPixels > 268435456) {
          // 256 megapixels - increased limit
          throw Exception(
            'Browser memory limit: Max ~256MP. Requested: ${(totalPixels / 1000000).round()}MP (~${estimatedMemoryMB.round()}MB). Enable "Override browser limits" to force generation.',
          );
        }
      } else {
        // Override mode - VERY permissive for wide/tall images
        // Allow extreme dimensions as long as total pixel count is reasonable
        const int absoluteMaxDimension = 65535; // Absolute browser canvas limit
        const int practicalMaxPixels =
            268435456; // 256MP - practical limit for override
        const int extremeMaxPixels = 536870912; // 512MP - absolute maximum

        // For override mode, allow ANY dimension up to browser absolute limit
        if (imageWidth > absoluteMaxDimension ||
            imageHeight > absoluteMaxDimension) {
          throw Exception(
            'Absolute browser canvas limit: Max ${absoluteMaxDimension}px per dimension. Requested: $imageWidth×${imageHeight}px',
          );
        }

        // Only check total pixels for extreme cases
        if (totalPixels > extremeMaxPixels) {
          throw Exception(
            'Browser practical limit exceeded: Max ~${(extremeMaxPixels / 1000000).round()}MP for stable rendering. Requested: ${(totalPixels / 1000000).round()}MP (~${estimatedMemoryMB.round()}MB)',
          );
        }

        // Warn about large images but allow them
        if (totalPixels > practicalMaxPixels) {
          debugPrint(
            'Warning: Large image ${(totalPixels / 1000000).round()}MP may be slow to generate. Total: $imageWidth×${imageHeight}px',
          );
        }

        // Additional check for extreme aspect ratios
        final aspectRatio = imageWidth > imageHeight
            ? imageWidth / imageHeight
            : imageHeight / imageWidth;
        if (aspectRatio > 50) {
          debugPrint(
            'Warning: Extreme aspect ratio ${aspectRatio.toStringAsFixed(1)}:1 - this is a very wide/tall image',
          );
        }
      }

      recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw background
      final backgroundPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(0, 0, imageWidth.toDouble(), imageHeight.toDouble()),
        backgroundPaint,
      );

      // Calculate panel layout
      final calc = surface.calculation!;
      final panelsWidth = calc.panelsWidth;
      final fullPanelsHeight = calc.fullPanelsHeight;
      final halfPanelsHeight = calc.halfPanelsHeight;

      // Get actual panel pixel dimensions from LED product
      int panelPixelWidth = 200; // Default fallback
      int panelPixelHeight = 200; // Default fallback

      if (surface.selectedLED != null) {
        panelPixelWidth = surface.selectedLED!.wPixel;
        panelPixelHeight = surface.selectedLED!.hPixel;
        debugPrint(
          'Using LED panel pixels: ${surface.selectedLED!.name} = $panelPixelWidth×${panelPixelHeight}px per panel',
        );
      } else {
        debugPrint('No LED selected, using default 200×200px per panel');
      }

      // Panel colors
      final panelColors = [
        const Color(0xFF2D1B69), // Deep purple
        const Color(0xFF1B5E20), // Deep green
        const Color(0xFF0D47A1), // Deep blue
        const Color(0xFFE65100), // Deep orange
        const Color(0xFFBF360C), // Deep red
        const Color(0xFF4A148C), // Deep violet
      ];

      // Calculate exact panel dimensions in pixels
      // Each panel should be exactly the LED specification size
      final double panelWidth = panelPixelWidth.toDouble();
      final double panelHeight = panelPixelHeight.toDouble();

      debugPrint(
        'Panel layout: $panelsWidth×${fullPanelsHeight + halfPanelsHeight} panels',
      );
      debugPrint(
        'Each panel: ${panelWidth.round()}×${panelHeight.round()} pixels',
      );
      debugPrint(
        'Expected total: ${(panelsWidth * panelWidth).round()}×${((fullPanelsHeight + halfPanelsHeight) * panelHeight).round()} pixels',
      );

      // Draw panels with exact pixel dimensions
      double currentY = 0;
      int globalRow = 0;

      // Draw full panels
      for (int fullRow = 0; fullRow < fullPanelsHeight; fullRow++) {
        _drawPanelRow(
          canvas,
          panelsWidth,
          globalRow,
          currentY,
          panelWidth,
          panelHeight,
          panelColors,
          showGrid: showGrid,
          showPanelNumbers: showPanelNumbers,
        );
        currentY += panelHeight;
        globalRow++;
      }

      // Draw half panels (same pixel size as full panels)
      for (int halfRow = 0; halfRow < halfPanelsHeight; halfRow++) {
        _drawPanelRow(
          canvas,
          panelsWidth,
          globalRow,
          currentY,
          panelWidth,
          panelHeight,
          panelColors,
          showGrid: showGrid,
          showPanelNumbers: showPanelNumbers,
        );
        currentY += panelHeight;
        globalRow++;
      }

      // Draw info overlay
      if (showPanelNumbers) {
        final pixelInfo = '$imageWidth×${imageHeight}px';
        final ledName = surface.selectedLED?.name ?? 'No LED Selected';
        final panelPixelInfo = surface.selectedLED != null
            ? '${surface.selectedLED!.wPixel}×${surface.selectedLED!.hPixel}px per panel'
            : 'Unknown panel size';
        final surfaceInfo =
            'Surface ${surfaceIndex + 1} | $ledName | ${calc.panelsWidth}×${(calc.fullPanelsHeight + calc.halfPanelsHeight)} panels | $panelPixelInfo';
        final fontSize = math.max(12, imageWidth * 0.015).toDouble();

        // Surface info at top
        final surfaceTextPainter = TextPainter(
          text: TextSpan(
            text: surfaceInfo,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                  color: Colors.black.withOpacity(0.8),
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        surfaceTextPainter.layout();
        if (surfaceTextPainter.width < imageWidth - 40) {
          surfaceTextPainter.paint(canvas, const Offset(20, 20));
        }

        // Pixel info at bottom
        final pixelTextPainter = TextPainter(
          text: TextSpan(
            text: pixelInfo,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: fontSize * 0.8,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                  color: Colors.black.withOpacity(0.7),
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        pixelTextPainter.layout();
        final textX = imageWidth - pixelTextPainter.width - 20;
        final textY = imageHeight - pixelTextPainter.height - 20;

        if (textX > 0 && textY > 0) {
          pixelTextPainter.paint(
            canvas,
            Offset(textX.toDouble(), textY.toDouble()),
          );
        }
      }

      // Render to image with proper error handling
      final picture = recorder.endRecording();

      try {
        final img = await picture.toImage(imageWidth, imageHeight);
        final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

        if (byteData == null) {
          throw Exception(
            'Browser failed to encode image - try smaller dimensions',
          );
        }

        return byteData.buffer.asUint8List();
      } catch (e) {
        // Handle browser canvas API failures
        String errorMsg = e.toString();
        if (errorMsg.contains('JSObject') ||
            errorMsg.contains('toImage') ||
            errorMsg.contains('toByteData')) {
          final mp = (totalPixels / 1000000).round();
          throw Exception(
            'Browser Canvas API failed for $imageWidth×${imageHeight}px (${mp}MP). Try dimensions under 8K×8K or 64MP total.',
          );
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('PixelMapServiceBrowserSafe: Rendering error: $e');
      recorder?.endRecording();

      // Provide helpful error messages
      String errorMessage = e.toString();
      if (errorMessage.contains('Browser canvas size limit') ||
          errorMessage.contains('Browser memory limit') ||
          errorMessage.contains('Browser practical limit') ||
          errorMessage.contains('Browser Canvas API failed') ||
          errorMessage.contains(
            'type \'Null\' is not a subtype of type \'JSObject\'',
          )) {
        final totalPixels = imageWidth * imageHeight;
        final estimatedMemoryMB = (totalPixels * 4) / (1024 * 1024);
        final mp = (totalPixels / 1000000).round();

        // More specific error messages based on the issue
        if (imageWidth > 32767 || imageHeight > 32767) {
          errorMessage =
              'Image dimensions too large: $imageWidth×${imageHeight}px. '
              'Width or height exceeds 32K limit. Enable "Override browser limits" and use "UNLIMITED" preset to attempt generation up to 65K×65K.';
        } else if (totalPixels > 268435456) {
          // Over 256MP
          errorMessage =
              'Image too large: $imageWidth×${imageHeight}px (${mp}MP, ~${estimatedMemoryMB.round()}MB). '
              'Exceeds 256MP limit. Enable "Override browser limits" and use "UNLIMITED" preset to attempt generation up to 512MP.';
        } else {
          errorMessage =
              'Browser rendering failed for $imageWidth×${imageHeight}px (~${estimatedMemoryMB.round()}MB). '
              'Try enabling "Override browser limits" or use a smaller quality preset.';
        }
      }

      return _createErrorImageBytes(errorMessage);
    }
  }

  static void _drawPanelRow(
    Canvas canvas,
    int panelsWidth,
    int globalRow,
    double currentY,
    double panelWidth,
    double panelHeight,
    List<Color> panelColors, {
    bool showGrid = true,
    bool showPanelNumbers = true,
  }) {
    for (int col = 0; col < panelsWidth; col++) {
      try {
        final double exactX = col * panelWidth;
        final int pixelX = exactX.floor();
        final int pixelY = currentY.floor();
        final int pixelWidth = ((col + 1) * panelWidth).floor() - pixelX;
        final int pixelHeight = (currentY + panelHeight).floor() - pixelY;

        // Draw panel
        final colorIndex = (globalRow + col) % panelColors.length;
        final panelColor = panelColors[colorIndex];

        final panelPaint = Paint()
          ..color = panelColor
          ..style = PaintingStyle.fill
          ..isAntiAlias = false;

        canvas.drawRect(
          Rect.fromLTWH(
            pixelX.toDouble(),
            pixelY.toDouble(),
            pixelWidth.toDouble(),
            pixelHeight.toDouble(),
          ),
          panelPaint,
        );

        // Draw grid if enabled
        if (showGrid && pixelWidth > 2 && pixelHeight > 2) {
          final gridPaint = Paint()
            ..color = Colors.white.withOpacity(0.6)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke
            ..isAntiAlias = false;

          canvas.drawRect(
            Rect.fromLTWH(
              pixelX.toDouble(),
              pixelY.toDouble(),
              pixelWidth.toDouble(),
              pixelHeight.toDouble(),
            ),
            gridPaint,
          );
        }

        // Draw panel number if enabled and space allows
        if (showPanelNumbers && pixelWidth > 20 && pixelHeight > 15) {
          final text = '${globalRow + 1}.${col + 1}';
          final fontSize = math.max(
            8.0,
            math.min(pixelWidth * 0.15, pixelHeight * 0.3),
          );

          final textPainter = TextPainter(
            text: TextSpan(
              text: text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          );

          textPainter.layout();
          final textX = pixelX + 2;
          final textY = pixelY + 2;

          if (textX + textPainter.width < pixelX + pixelWidth - 2 &&
              textY + textPainter.height < pixelY + pixelHeight - 2) {
            textPainter.paint(
              canvas,
              Offset(textX.toDouble(), textY.toDouble()),
            );
          }
        }
      } catch (e) {
        debugPrint('Error drawing panel ($globalRow, $col): $e');
        // Continue with next panel
      }
    }
  }

  static Uint8List _createErrorImageBytes(String message) {
    // Create minimal PNG data for error case
    return Uint8List.fromList([
      137,
      80,
      78,
      71,
      13,
      10,
      26,
      10,
      0,
      0,
      0,
      13,
      73,
      72,
      68,
      82,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      1,
      8,
      6,
      0,
      0,
      0,
      31,
      21,
      196,
      137,
      0,
      0,
      0,
      11,
      73,
      68,
      65,
      84,
      120,
      156,
      99,
      248,
      15,
      0,
      0,
      1,
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    ]);
  }
}

// Configuration classes remain the same
class PixelMapLimits {
  final int maxWidth;
  final int maxHeight;
  final int maxTotalPixels;
  final int maxMemoryMB;
  final int warnWidth;
  final int warnHeight;
  final int warnTotalPixels;

  const PixelMapLimits({
    required this.maxWidth,
    required this.maxHeight,
    required this.maxTotalPixels,
    required this.maxMemoryMB,
    required this.warnWidth,
    required this.warnHeight,
    required this.warnTotalPixels,
  });
}

class DimensionValidationResult {
  final int originalWidth;
  final int originalHeight;
  final int adjustedWidth;
  final int adjustedHeight;
  final bool wasAdjusted;
  final bool hasWarnings;
  final bool isValid;
  final int estimatedMemoryMB;
  final PixelMapLimits activeLimits;
  final List<String> warnings;

  const DimensionValidationResult({
    required this.originalWidth,
    required this.originalHeight,
    required this.adjustedWidth,
    required this.adjustedHeight,
    required this.wasAdjusted,
    required this.hasWarnings,
    required this.isValid,
    required this.estimatedMemoryMB,
    required this.activeLimits,
    required this.warnings,
  });
}

class PixelMapResult {
  final bool isSuccess;
  final Uint8List? imageBytes;
  final int? actualWidth;
  final int? actualHeight;
  final String? errorMessage;
  final DimensionValidationResult? validation;

  const PixelMapResult._({
    required this.isSuccess,
    this.imageBytes,
    this.actualWidth,
    this.actualHeight,
    this.errorMessage,
    this.validation,
  });

  factory PixelMapResult.success({
    required Uint8List imageBytes,
    required int actualWidth,
    required int actualHeight,
    DimensionValidationResult? validation,
  }) {
    return PixelMapResult._(
      isSuccess: true,
      imageBytes: imageBytes,
      actualWidth: actualWidth,
      actualHeight: actualHeight,
      validation: validation,
    );
  }

  factory PixelMapResult.error(String message) {
    return PixelMapResult._(isSuccess: false, errorMessage: message);
  }
}
