import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/surface_model.dart';
import 'cloud_pixel_map_service.dart';

class PixelMapService {
  // ALWAYS USE CLOUD SERVICE - All pixel maps generated on Render.com
  static const int _canvasLimitThreshold =
      0; // Force all to cloud (was 16M pixels)

  /// All pixel map generation now happens on Render.com cloud service
  /// This ensures consistent quality, no Canvas API limits, and native PNG output
  static Future<Uint8List> createPixelMapImageSmart(
    Surface surface,
    int index, {
    bool showGrid = true,
    bool showPanelNumbers = true,
    bool showName = false,
    bool showCross = false,
    bool showCircle = false,
    bool showLogo = false,
  }) async {
    if (surface.calculation == null) {
      throw Exception('Surface calculation is null');
    }

    final calc = surface.calculation!;
    final totalPixels = calc.pixelsWidth * calc.pixelsHeight;

    debugPrint(
      'Cloud Pixel Map: ${calc.pixelsWidth}×${calc.pixelsHeight} = $totalPixels pixels (all generated on Render.com)',
    );

    // ALL images use cloud service for consistent quality and no local limits
    if (totalPixels > _canvasLimitThreshold) {
      // Always true since threshold = 0
      debugPrint(
        'Generating on Render.com cloud service ($totalPixels pixels)...',
      );

      try {
        final cloudResult = await CloudPixelMapService.generateCloudPixelMap(
          surface,
          index,
          showGrid: showGrid,
          showPanelNumbers: showPanelNumbers,
          showName: showName,
          showCross: showCross,
          showCircle: showCircle,
          showLogo: showLogo,
        );

        if (cloudResult.isSuccess && cloudResult.imageBytes != null) {
          debugPrint(
            'Cloud generation successful: ${cloudResult.width}×${cloudResult.height}px (${cloudResult.fileSizeMB}MB)',
          );
          return cloudResult.imageBytes!;
        } else {
          debugPrint('Cloud generation failed: ${cloudResult.errorMessage}');
          throw Exception(
            'Cloud generation failed: ${cloudResult.errorMessage}',
          );
        }
      } catch (e) {
        debugPrint('Cloud service error: $e');
        throw Exception(
          'Failed to generate large pixel map via cloud service: $e',
        );
      }
    } else {
      debugPrint('All images now use cloud generation for consistency...');
      try {
        final cloudResult = await CloudPixelMapService.generateCloudPixelMap(
          surface,
          index,
          showGrid: showGrid,
          showPanelNumbers: showPanelNumbers,
        );

        if (cloudResult.isSuccess && cloudResult.imageBytes != null) {
          debugPrint(
            'Cloud generation successful: ${cloudResult.width}×${cloudResult.height}px (${cloudResult.fileSizeMB}MB)',
          );
          return cloudResult.imageBytes!;
        } else {
          debugPrint('Cloud generation failed: ${cloudResult.errorMessage}');
          throw Exception(
            'Cloud generation failed: ${cloudResult.errorMessage}',
          );
        }
      } catch (e) {
        debugPrint('Cloud service error: $e');
        throw Exception('Failed to generate pixel map via cloud service: $e');
      }
    }
  }

  /// Smart ultra-high-quality pixel-perfect generation
  static Future<Uint8List> createUltraPixelPerfectImageSmart(
    Surface surface,
    int index, {
    required int imageWidth,
    required int imageHeight,
    bool showPanelNumbers = true,
    bool showGrid = true,
    bool showName = false,
    bool showCross = false,
    bool showCircle = false,
    bool showLogo = false,
  }) async {
    final totalPixels = imageWidth * imageHeight;

    debugPrint(
      'Smart Ultra Pixel Perfect: $imageWidth×$imageHeight = $totalPixels pixels',
    );

    // For large images, use cloud service
    if (totalPixels > _canvasLimitThreshold) {
      debugPrint(
        'Large ultra image detected ($totalPixels pixels), using cloud service...',
      );

      try {
        final cloudResult = await CloudPixelMapService.generateCloudPixelMap(
          surface,
          index,
          showGrid: showGrid,
          showPanelNumbers: showPanelNumbers,
          showName: showName,
          showCross: showCross,
          showCircle: showCircle,
          showLogo: showLogo,
        );

        if (cloudResult.isSuccess && cloudResult.imageBytes != null) {
          debugPrint(
            'Cloud ultra generation successful: ${cloudResult.width}×${cloudResult.height}px (${cloudResult.fileSizeMB}MB)',
          );
          return cloudResult.imageBytes!;
        } else {
          debugPrint(
            'Cloud ultra generation failed: ${cloudResult.errorMessage}',
          );
          throw Exception(
            'Cloud ultra generation failed: ${cloudResult.errorMessage}',
          );
        }
      } catch (e) {
        debugPrint('Cloud ultra service error: $e');
        throw Exception(
          'Failed to generate ultra large pixel map via cloud service: $e',
        );
      }
    } else {
      debugPrint('All images now use cloud generation for consistency...');
      try {
        final cloudResult = await CloudPixelMapService.generateCloudPixelMap(
          surface,
          index,
          showGrid: showGrid,
          showPanelNumbers: showPanelNumbers,
          showName: showName,
          showCross: showCross,
          showCircle: showCircle,
          showLogo: showLogo,
        );

        if (cloudResult.isSuccess && cloudResult.imageBytes != null) {
          debugPrint(
            'Cloud generation successful: ${cloudResult.width}×${cloudResult.height}px (${cloudResult.fileSizeMB}MB)',
          );
          return cloudResult.imageBytes!;
        } else {
          debugPrint('Cloud generation failed: ${cloudResult.errorMessage}');
          throw Exception(
            'Cloud generation failed: ${cloudResult.errorMessage}',
          );
        }
      } catch (e) {
        debugPrint('Cloud service error: $e');
        throw Exception('Failed to generate pixel map via cloud service: $e');
      }
    }
  }

  // Original canvas-based method for display/preview
  static Future<Uint8List> createPixelMapImage(
    Surface surface,
    int index,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Canvas dimensions - Higher resolution for better quality
    const double canvasWidth = 2560; // Increased resolution
    const double canvasHeight = 1440; // Increased resolution

    // Transparent background (no background fill)
    // canvas.drawRect(Rect.fromLTWH(0, 0, canvasWidth, canvasHeight), paint);

    // Calculate grid dimensions and positioning
    final panelsWidth = surface.calculation!.panelsWidth;
    final fullPanelsHeight = surface.calculation!.fullPanelsHeight;
    final halfPanelsHeight = surface.calculation!.halfPanelsHeight;

    // Grid area (leave space for margins but focus on LED area)
    const double gridMargin = 50; // Reduced margin for tighter focus
    final double availableWidth = canvasWidth - (gridMargin * 2);
    final double availableHeight = canvasHeight - (gridMargin * 2);

    // Calculate cell size based on actual panel proportions
    // For InfiLED: full panels are 1000mm, half panels are 500mm
    // We need to calculate the proportional heights
    final double fullPanelRatio = 1.0; // Full panels are the reference
    final double halfPanelRatio =
        0.5; // Half panels are 50% height of full panels

    // Calculate total height units (full panels count as 1.0, half panels as 0.5)
    final double totalHeightUnits =
        (fullPanelsHeight * fullPanelRatio) +
        (halfPanelsHeight * halfPanelRatio);

    // Calculate cell sizes
    final double cellWidth = availableWidth / panelsWidth;
    final double fullPanelCellHeight = availableHeight / totalHeightUnits;

    // Use the width-constrained size to maintain proper proportions
    final double cellSize = math.min(cellWidth, fullPanelCellHeight);
    final double adjustedFullPanelHeight = cellSize;
    final double adjustedHalfPanelHeight = cellSize * halfPanelRatio;

    // Calculate actual grid dimensions
    final double gridWidth = panelsWidth * cellSize;
    final double gridHeight =
        (fullPanelsHeight * adjustedFullPanelHeight) +
        (halfPanelsHeight * adjustedHalfPanelHeight);
    final double gridStartX = (canvasWidth - gridWidth) / 2;
    final double gridStartY = (canvasHeight - gridHeight) / 2;

    // Draw LED grid with enhanced quality
    _drawPixelGridWithMixedHeights(
      canvas,
      gridStartX,
      gridStartY,
      cellSize,
      panelsWidth,
      fullPanelsHeight,
      halfPanelsHeight,
      adjustedFullPanelHeight,
      adjustedHalfPanelHeight,
    );

    // Enhanced diagonal lines with anti-aliasing and gradients
    final diagonalPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFC7B299).withOpacity(0.6),
              const Color(0xFFC7B299).withOpacity(0.3),
            ],
          ).createShader(
            Rect.fromLTWH(gridStartX, gridStartY, gridWidth, gridHeight),
          )
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Top-left LED corner to bottom-right LED corner
    canvas.drawLine(
      Offset(gridStartX, gridStartY),
      Offset(gridStartX + gridWidth, gridStartY + gridHeight),
      diagonalPaint,
    );

    // Top-right LED corner to bottom-left LED corner
    canvas.drawLine(
      Offset(gridStartX + gridWidth, gridStartY),
      Offset(gridStartX, gridStartY + gridHeight),
      diagonalPaint,
    );

    // Enhanced surface name with better typography and effects
    final surfaceName = surface.name.isEmpty
        ? 'Screen ${index + 1}'
        : surface.name;
    final maxTextWidth = canvasWidth * 0.75;

    // Calculate enhanced font size with better scaling
    double fontSize = 150; // Increased base font size for higher resolution
    TextPainter textPainter;

    do {
      textPainter = TextPainter(
        text: TextSpan(
          text: surfaceName,
          style: TextStyle(
            color: const Color(0x90FFD700), // Slightly more opaque golden color
            fontSize: fontSize,
            fontWeight: FontWeight.w800, // Heavier font weight
            letterSpacing: 2.0, // Better letter spacing
            shadows: [
              Shadow(
                offset: const Offset(2, 2),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();

      if (textPainter.width <= maxTextWidth) break;
      fontSize -= 5;
    } while (fontSize > 30); // Increased minimum font size

    // Ensure symmetrical height (height should match width proportion)
    final symmetricalHeight =
        textPainter.width * 0.3; // Adjust ratio for symmetry
    if (textPainter.height > symmetricalHeight) {
      // Recalculate with height constraint
      fontSize = fontSize * (symmetricalHeight / textPainter.height);
      textPainter = TextPainter(
        text: TextSpan(
          text: surfaceName,
          style: TextStyle(
            color: const Color(0x80FFD700),
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
    }

    // Position title in center of canvas
    final titleX = (canvasWidth - textPainter.width) / 2;
    final titleY = (canvasHeight - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(titleX, titleY));

    // Add pixel size info ON TOP of the pixel map grid in left bottom corner of LED area
    final pixelSizeText =
        '${surface.calculation!.pixelsWidth}x${surface.calculation!.pixelsHeight}';
    final pixelSizePainter = TextPainter(
      text: TextSpan(
        text: pixelSizeText,
        style: const TextStyle(
          color: Colors
              .white, // White color for better visibility on colored panels
          fontSize: 32, // Larger font for better visibility
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    pixelSizePainter.layout();

    // Position in left bottom corner of the LED grid area (ON TOP of the pixel map)
    const double gridBottomMargin = 15.0;
    const double gridLeftMargin = 15.0;
    final pixelSizeX = gridStartX + gridLeftMargin;
    final pixelSizeY =
        gridStartY + gridHeight - pixelSizePainter.height - gridBottomMargin;
    pixelSizePainter.paint(canvas, Offset(pixelSizeX, pixelSizeY));

    // Render canvas to image with transparency support
    final picture = recorder.endRecording();
    final img = await picture.toImage(
      canvasWidth.toInt(),
      canvasHeight.toInt(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Creates ultra-high-quality pixel-perfect image with exact 1:1 pixel mapping
  /// Each LED panel pixel corresponds to exactly one image pixel for perfect video mapping
  static Future<Uint8List> createUltraPixelPerfectImage(
    Surface surface,
    int index, {
    required int imageWidth, // Exact pixel width (e.g., 1920)
    required int imageHeight, // Exact pixel height (e.g., 1080)
    bool showPanelNumbers = true,
    bool showGrid = true,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Use exact pixel dimensions - no scaling, no interpolation
    final double canvasWidth = imageWidth.toDouble();
    final double canvasHeight = imageHeight.toDouble();

    // Create high-quality paint with anti-aliasing disabled for pixel-perfect edges
    final backgroundPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill
      ..isAntiAlias = false; // Disable anti-aliasing for crisp pixel boundaries

    // Fill background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
      backgroundPaint,
    );

    // Get panel configuration
    final panelsWidth = surface.calculation!.panelsWidth;
    final fullPanelsHeight = surface.calculation!.fullPanelsHeight;
    final halfPanelsHeight = surface.calculation!.halfPanelsHeight;

    // Calculate exact pixels per panel (integer division for perfect alignment)
    final double pixelsPerPanelWidth = imageWidth / panelsWidth;
    final double totalPanelHeight = fullPanelsHeight + (halfPanelsHeight * 0.5);
    final double fullPanelPixelHeight = imageHeight / totalPanelHeight;
    final double halfPanelPixelHeight = fullPanelPixelHeight * 0.5;

    // Ultra-crisp panel colors for maximum visibility
    final panelColors = [
      const Color(0xFF2D1B69), // Deep purple
      const Color(0xFF1B5E20), // Deep green
      const Color(0xFF0D47A1), // Deep blue
      const Color(0xFFE65100), // Deep orange
      const Color(0xFFBF360C), // Deep red
      const Color(0xFF4A148C), // Deep violet
    ];

    double currentY = 0;
    int globalRow = 0;

    // Draw full-height panels with pixel-perfect positioning
    for (int fullRow = 0; fullRow < fullPanelsHeight; fullRow++) {
      for (int col = 0; col < panelsWidth; col++) {
        final double exactX = col * pixelsPerPanelWidth;
        final double exactY = currentY;

        // Round to exact pixel boundaries for perfect alignment
        final int pixelX = exactX.floor();
        final int pixelY = exactY.floor();
        final int pixelWidth =
            ((col + 1) * pixelsPerPanelWidth).floor() - pixelX;
        final int pixelHeight =
            (exactY + fullPanelPixelHeight).floor() - pixelY;

        // Select high-contrast color
        final colorIndex = (globalRow + col) % panelColors.length;
        final panelColor = panelColors[colorIndex];

        // Draw panel with pixel-perfect boundaries
        final panelPaint = Paint()
          ..color = panelColor
          ..style = PaintingStyle.fill
          ..isAntiAlias = false; // Critical: no anti-aliasing for sharp edges

        canvas.drawRect(
          Rect.fromLTWH(
            pixelX.toDouble(),
            pixelY.toDouble(),
            pixelWidth.toDouble(),
            pixelHeight.toDouble(),
          ),
          panelPaint,
        );

        // Draw ultra-crisp grid lines
        if (showGrid) {
          final gridPaint = Paint()
            ..color = Colors.white.withOpacity(0.6)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke
            ..isAntiAlias = false; // No anti-aliasing for crisp lines

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

        // Draw ultra-crisp panel numbers
        if (showPanelNumbers) {
          final panelText = '${globalRow + 1}.${col + 1}';
          final fontSize = math
              .max(math.min(pixelWidth * 0.2, pixelHeight * 0.4), 12)
              .toDouble();

          if (fontSize >= 12 && pixelWidth > 50 && pixelHeight > 30) {
            final textPainter = TextPainter(
              text: TextSpan(
                text: panelText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace', // Use monospace for crisp text
                ),
              ),
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();

            // Position in top-left with small margin
            final textX = pixelX + 3.0;
            final textY = pixelY + 3.0;

            if (textX + textPainter.width < pixelX + pixelWidth - 3 &&
                textY + textPainter.height < pixelY + pixelHeight - 3) {
              textPainter.paint(canvas, Offset(textX, textY));
            }
          }
        }
      }
      currentY += fullPanelPixelHeight;
      globalRow++;
    }

    // Draw half-height panels with pixel-perfect positioning
    for (int halfRow = 0; halfRow < halfPanelsHeight; halfRow++) {
      for (int col = 0; col < panelsWidth; col++) {
        final double exactX = col * pixelsPerPanelWidth;
        final double exactY = currentY;

        // Round to exact pixel boundaries
        final int pixelX = exactX.floor();
        final int pixelY = exactY.floor();
        final int pixelWidth =
            ((col + 1) * pixelsPerPanelWidth).floor() - pixelX;
        final int pixelHeight =
            (exactY + halfPanelPixelHeight).floor() - pixelY;

        // Select high-contrast color
        final colorIndex = (globalRow + col) % panelColors.length;
        final panelColor = panelColors[colorIndex];

        // Draw half panel with pixel-perfect boundaries
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

        // Draw ultra-crisp grid lines for half panels
        if (showGrid) {
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

        // Draw panel numbers for half panels
        if (showPanelNumbers) {
          final panelText = '${globalRow + 1}.${col + 1}';
          final fontSize = math.max(
            math.min(pixelWidth * 0.25, pixelHeight * 0.6),
            10,
          );

          if (fontSize >= 10 && pixelWidth > 40 && pixelHeight > 20) {
            final textPainter = TextPainter(
              text: TextSpan(
                text: panelText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize.toDouble(),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();

            final textX = pixelX + 2.0;
            final textY = pixelY + 2.0;

            if (textX + textPainter.width < pixelX + pixelWidth - 2 &&
                textY + textPainter.height < pixelY + pixelHeight - 2) {
              textPainter.paint(canvas, Offset(textX, textY));
            }
          }
        }
      }
      currentY += halfPanelPixelHeight;
      globalRow++;
    }

    // Add pixel dimension overlay in bottom-right corner
    if (showPanelNumbers) {
      final pixelInfoText = '$imageWidth×${imageHeight}px';
      final overlaySize = math.max(imageWidth * 0.025, 16);

      final textPainter = TextPainter(
        text: TextSpan(
          text: pixelInfoText,
          style: TextStyle(
            color: Colors.yellow,
            fontSize: overlaySize.toDouble(),
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            shadows: [
              Shadow(
                offset: const Offset(2, 2),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.8),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final textX = canvasWidth - textPainter.width - 15;
      final textY = canvasHeight - textPainter.height - 15;
      textPainter.paint(canvas, Offset(textX, textY));
    }

    // Render to exact pixel dimensions with no scaling or filtering
    final picture = recorder.endRecording();
    final img = await picture.toImage(imageWidth, imageHeight);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Creates a pixel-perfect image where each LED panel maps to exact pixels
  /// If you specify 4000x2000, you get exactly 4000x2000 pixels with perfect panel-to-pixel mapping
  static Future<Uint8List> createPixelPerfectImage(
    Surface surface,
    int index, {
    required int imageWidth, // Exact pixel width (e.g., 4000)
    required int imageHeight, // Exact pixel height (e.g., 2000)
    bool showPanelNumbers = true,
    bool showGrid = true,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Use exact pixel dimensions
    final double canvasWidth = imageWidth.toDouble();
    final double canvasHeight = imageHeight.toDouble();

    // Fill with black background for LED display simulation
    final backgroundPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
      backgroundPaint,
    );

    // Calculate exact panel dimensions
    final panelsWidth = surface.calculation!.panelsWidth;
    final fullPanelsHeight = surface.calculation!.fullPanelsHeight;
    final halfPanelsHeight = surface.calculation!.halfPanelsHeight;

    // Calculate pixels per panel (exact division)
    final double pixelsPerPanelWidth = canvasWidth / panelsWidth;
    final double fullPanelPixelHeight =
        canvasHeight / (fullPanelsHeight + (halfPanelsHeight * 0.5));
    final double halfPanelPixelHeight = fullPanelPixelHeight * 0.5;

    // Draw pixel-perfect LED panels
    await _drawPixelPerfectGrid(
      canvas,
      panelsWidth,
      fullPanelsHeight,
      halfPanelsHeight,
      pixelsPerPanelWidth,
      fullPanelPixelHeight,
      halfPanelPixelHeight,
      showPanelNumbers: showPanelNumbers,
      showGrid: showGrid,
    );

    // Add pixel dimensions overlay if requested
    if (showPanelNumbers) {
      final pixelInfoText = '${imageWidth}x$imageHeight pixels';
      final textPainter = TextPainter(
        text: TextSpan(
          text: pixelInfoText,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: math.max(
              imageWidth * 0.02,
              12,
            ), // Scale font with image size
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
      textPainter.layout();

      // Position in bottom-right corner
      final textX = canvasWidth - textPainter.width - 20;
      final textY = canvasHeight - textPainter.height - 20;
      textPainter.paint(canvas, Offset(textX, textY));
    }

    // Render to exact pixel dimensions
    final picture = recorder.endRecording();
    final img = await picture.toImage(imageWidth, imageHeight);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Draws pixel-perfect grid where each panel corresponds to exact pixels
  static Future<void> _drawPixelPerfectGrid(
    Canvas canvas,
    int panelsWidth,
    int fullPanelsHeight,
    int halfPanelsHeight,
    double pixelsPerPanelWidth,
    double fullPanelPixelHeight,
    double halfPanelPixelHeight, {
    required bool showPanelNumbers,
    required bool showGrid,
  }) async {
    // Enhanced LED panel colors for realistic appearance
    final panelColors = [
      const Color(0xFF1E1E2E), // Dark purple
      const Color(0xFF1E2E2E), // Dark teal
      const Color(0xFF2E2E1E), // Dark olive
      const Color(0xFF1E1E2E), // Dark navy
      const Color(0xFF1E2E1E), // Dark green
      const Color(0xFF2E1E1E), // Dark maroon
    ];

    double currentY = 0;
    int globalRow = 0;

    // Draw full-height panels with pixel precision
    for (int fullRow = 0; fullRow < fullPanelsHeight; fullRow++) {
      for (int col = 0; col < panelsWidth; col++) {
        final double panelX = col * pixelsPerPanelWidth;
        final double panelY = currentY;

        // Calculate exact pixel boundaries (rounded to ensure sharp edges)
        final int pixelX = panelX.round();
        final int pixelY = panelY.round();
        final int pixelWidth = (panelX + pixelsPerPanelWidth).round() - pixelX;
        final int pixelHeight =
            (panelY + fullPanelPixelHeight).round() - pixelY;

        // Select panel color based on position
        final colorIndex = (globalRow + col) % panelColors.length;
        final panelColor = panelColors[colorIndex];

        // Draw panel with exact pixel boundaries
        final panelPaint = Paint()
          ..color = panelColor
          ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromLTWH(
            pixelX.toDouble(),
            pixelY.toDouble(),
            pixelWidth.toDouble(),
            pixelHeight.toDouble(),
          ),
          panelPaint,
        );

        // Draw grid lines if requested
        if (showGrid) {
          final gridPaint = Paint()
            ..color = Colors.grey.withOpacity(0.3)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;

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

        // Draw panel numbers if requested
        if (showPanelNumbers) {
          final panelText = '${globalRow + 1}.${col + 1}';
          final fontSize = math.min(pixelWidth * 0.15, pixelHeight * 0.3);

          if (fontSize > 8) {
            // Only draw if text will be readable
            final textPainter = TextPainter(
              text: TextSpan(
                text: panelText,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();

            // Position in top-left corner of panel
            final textX = pixelX + 4.0;
            final textY = pixelY + 4.0;

            // Only draw if text fits within panel
            if (textX + textPainter.width < pixelX + pixelWidth &&
                textY + textPainter.height < pixelY + pixelHeight) {
              textPainter.paint(canvas, Offset(textX, textY));
            }
          }
        }
      }
      currentY += fullPanelPixelHeight;
      globalRow++;
    }

    // Draw half-height panels with pixel precision
    for (int halfRow = 0; halfRow < halfPanelsHeight; halfRow++) {
      for (int col = 0; col < panelsWidth; col++) {
        final double panelX = col * pixelsPerPanelWidth;
        final double panelY = currentY;

        // Calculate exact pixel boundaries for half panels
        final int pixelX = panelX.round();
        final int pixelY = panelY.round();
        final int pixelWidth = (panelX + pixelsPerPanelWidth).round() - pixelX;
        final int pixelHeight =
            (panelY + halfPanelPixelHeight).round() - pixelY;

        // Select panel color based on position
        final colorIndex = (globalRow + col) % panelColors.length;
        final panelColor = panelColors[colorIndex];

        // Draw half panel with exact pixel boundaries
        final panelPaint = Paint()
          ..color = panelColor
          ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromLTWH(
            pixelX.toDouble(),
            pixelY.toDouble(),
            pixelWidth.toDouble(),
            pixelHeight.toDouble(),
          ),
          panelPaint,
        );

        // Draw grid lines if requested
        if (showGrid) {
          final gridPaint = Paint()
            ..color = Colors.grey.withOpacity(0.3)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;

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

        // Draw panel numbers if requested
        if (showPanelNumbers) {
          final panelText = '${globalRow + 1}.${col + 1}';
          final fontSize = math.min(pixelWidth * 0.15, pixelHeight * 0.4);

          if (fontSize > 6) {
            // Smaller threshold for half panels
            final textPainter = TextPainter(
              text: TextSpan(
                text: panelText,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();

            // Position in top-left corner of half panel
            final textX = pixelX + 2.0;
            final textY = pixelY + 2.0;

            // Only draw if text fits within panel
            if (textX + textPainter.width < pixelX + pixelWidth &&
                textY + textPainter.height < pixelY + pixelHeight) {
              textPainter.paint(canvas, Offset(textX, textY));
            }
          }
        }
      }
      currentY += halfPanelPixelHeight;
      globalRow++;
    }
  }

  static void _drawPixelGridWithMixedHeights(
    Canvas canvas,
    double startX,
    double startY,
    double cellWidth,
    int panelsWidth,
    int fullPanelsHeight,
    int halfPanelsHeight,
    double fullPanelHeight,
    double halfPanelHeight,
  ) {
    // Enhanced professional color palette with gradients
    final baseColors = [
      const Color(0xFF8B4C8B), // Purple
      const Color(0xFF2E7D7D), // Teal
      const Color(0xFF8B8B4C), // Olive
      const Color(0xFF4C4C8B), // Navy
      const Color(0xFF4C8B4C), // Green
      const Color(0xFF8B4C4C), // Maroon
    ];

    // Enhanced border paint with anti-aliasing
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    // Enhanced shadow paint for depth
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0)
      ..isAntiAlias = true;

    double currentY = startY;
    int globalRow = 0;

    // Draw full panel rows first
    for (int fullRow = 0; fullRow < fullPanelsHeight; fullRow++) {
      for (int col = 0; col < panelsWidth; col++) {
        final left = startX + col * cellWidth;
        final top = currentY;
        final rect = Rect.fromLTWH(left, top, cellWidth, fullPanelHeight);

        // Select enhanced color with gradient based on position
        final colorIndex = (globalRow + col) % baseColors.length;
        final baseColor = baseColors[colorIndex];

        // Create gradient paint for this panel
        final gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.withOpacity(1.0),
            baseColor.withOpacity(0.8),
            baseColor.withOpacity(0.9),
          ],
          stops: const [0.0, 0.5, 1.0],
        );

        final panelPaint = Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.fill
          ..shader = gradient.createShader(rect);

        // Draw shadow first for depth
        final shadowRect = Rect.fromLTWH(
          left + 1.5,
          top + 1.5,
          cellWidth,
          fullPanelHeight,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(shadowRect, const Radius.circular(4)),
          shadowPaint,
        );

        // Draw enhanced panel with rounded corners
        final panelRect = RRect.fromRectAndRadius(
          rect,
          const Radius.circular(4),
        );
        canvas.drawRRect(panelRect, panelPaint);

        // Draw enhanced border
        canvas.drawRRect(panelRect, borderPaint);

        // Draw enhanced panel number with better typography
        final panelText = '${globalRow + 1},${col + 1}';
        final textPainter = TextPainter(
          text: TextSpan(
            text: panelText,
            style: TextStyle(
              color: Colors.white,
              fontSize:
                  cellWidth * 0.1, // Slightly larger for better visibility
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                  color: Colors.black.withOpacity(0.5),
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // Center text better within panel
        final textX = left + (cellWidth - textPainter.width) / 2;
        final textY = top + (fullPanelHeight - textPainter.height) / 2;
        textPainter.paint(canvas, Offset(textX, textY));
      }
      currentY += fullPanelHeight;
      globalRow++;
    }

    // Draw half panel rows with enhanced styling
    for (int halfRow = 0; halfRow < halfPanelsHeight; halfRow++) {
      for (int col = 0; col < panelsWidth; col++) {
        final left = startX + col * cellWidth;
        final top = currentY;
        final rect = Rect.fromLTWH(left, top, cellWidth, halfPanelHeight);

        // Select enhanced color with gradient based on position
        final colorIndex = (globalRow + col) % baseColors.length;
        final baseColor = baseColors[colorIndex];

        // Create gradient paint for this panel
        final gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.withOpacity(1.0),
            baseColor.withOpacity(0.8),
            baseColor.withOpacity(0.9),
          ],
          stops: const [0.0, 0.5, 1.0],
        );

        final panelPaint = Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.fill
          ..shader = gradient.createShader(rect);

        // Draw shadow first for depth
        final shadowRect = Rect.fromLTWH(
          left + 1.5,
          top + 1.5,
          cellWidth,
          halfPanelHeight,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(shadowRect, const Radius.circular(4)),
          shadowPaint,
        );

        // Draw enhanced panel with rounded corners
        final panelRect = RRect.fromRectAndRadius(
          rect,
          const Radius.circular(4),
        );
        canvas.drawRRect(panelRect, panelPaint);

        // Draw enhanced border
        canvas.drawRRect(panelRect, borderPaint);

        // Draw enhanced panel number with better typography
        final panelText = '${globalRow + 1},${col + 1}';
        final textPainter = TextPainter(
          text: TextSpan(
            text: panelText,
            style: TextStyle(
              color: Colors.white,
              fontSize:
                  cellWidth * 0.1, // Slightly larger for better visibility
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                  color: Colors.black.withOpacity(0.5),
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // Center text better within panel
        final textX = left + (cellWidth - textPainter.width) / 2;
        final textY = top + (halfPanelHeight - textPainter.height) / 2;
        textPainter.paint(canvas, Offset(textX, textY));
      }
      currentY += halfPanelHeight;
      globalRow++;
    }
  }

  // Create a preview widget version for dialogs
  static Widget createPixelMapPreview(
    Surface surface,
    int index, {
    double width = 250,
    double height = 180,
  }) {
    return FutureBuilder<Uint8List>(
      future: createPixelMapImageSmart(surface, index),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: Text(
                'Error loading preview',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        return SizedBox(
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(snapshot.data!, fit: BoxFit.contain),
          ),
        );
      },
    );
  }
}
