import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;
import '../models/surface_model.dart';
import '../services/pixel_map_service.dart';
import '../services/file_service.dart';

// Border colors as per style guide
const Color borderColorLight = Color(0xFFE7DCCC); // Lighter border #E7DCCC
const Color borderColorDark = Color(0xFFD4C7B7); // Darker border #D4C7B7

// Text colors as per style guide
const Color textColorPrimary = Color(0xFF383838); // Deep neutral gray for most text
const Color textColorSecondary = Color(0xFFA2A09A); // Light gray for secondary/disabled text

// Header/accent colors as per style guide
const Color headerBackgroundColor = Color(0xFFEADFC9); // Warm tan/sand/cream #EADFC9
const Color headerTextColor = Color(0xFFC7B299); // Slightly deeper sand #C7B299

// Define the new button background color as per style guide
const Color buttonBackgroundColor = Color.fromRGBO(247, 238, 221, 1.0);

// Define the new button text color as per style guide (30% darker)
const Color buttonTextColor = Color.fromRGBO(125, 117, 103, 1.0);

class PixelMapsDialog extends StatefulWidget {
  final List<Surface> surfaces;
  final ProjectData? projectData;
  final bool isDarkMode;
  final String? logoBase64;

  const PixelMapsDialog({
    super.key,
    required this.surfaces,
    required this.projectData,
    required this.isDarkMode,
    this.logoBase64,
  });

  @override
  State<PixelMapsDialog> createState() => _PixelMapsDialogState();
}

class _PixelMapsDialogState extends State<PixelMapsDialog> {
  String _selectedOption = 'Selected Surfaces';
  final Map<int, bool> _selectedSurfaces =
      {}; // Track which surfaces are selected
  bool _includeLogo = true; // Simple checkbox for logo

  @override
  void initState() {
    super.initState();
    // Initialize all surfaces as selected by default
    for (int i = 0; i < widget.surfaces.length; i++) {
      _selectedSurfaces[i] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 1200,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: widget.isDarkMode ? Colors.grey[800] : const Color(0xFFF7F6F3),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: widget.isDarkMode ? Colors.white : headerTextColor,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: headerBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(13),
                  topRight: Radius.circular(13),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.grid_view, color: headerTextColor, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Generate Pixel Maps',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: headerTextColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: headerTextColor),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Surface Selection with Export Options next to it
                    Row(
                      children: [
                        _buildSectionHeader('Surface Selection'),
                        const SizedBox(width: 20),
                        // Export options next to Surface Selection
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: headerBackgroundColor,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: headerTextColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: 'Selected Surfaces',
                                groupValue: _selectedOption,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedOption = value!;
                                  });
                                },
                                activeColor: headerTextColor,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Text(
                                'Selected',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 10),
                              Radio<String>(
                                value: 'All Surfaces',
                                groupValue: _selectedOption,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedOption = value!;
                                    // When 'All' is selected, select all surfaces
                                    if (_selectedOption == 'All Surfaces') {
                                      for (
                                        int i = 0;
                                        i < widget.surfaces.length;
                                        i++
                                      ) {
                                        _selectedSurfaces[i] = true;
                                      }
                                    }
                                  });
                                },
                                activeColor: headerTextColor,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Text('All', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildSurfacePreviewWithOptions(),
                  ],
                ),
              ),
            ),

            // Action Buttons with logo checkbox
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Logo checkbox in bottom right corner
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Checkbox(
                        value: _includeLogo,
                        onChanged: (bool? value) {
                          setState(() {
                            _includeLogo = value ?? false;
                          });
                        },
                        activeColor: headerTextColor,
                      ),
                      const Text('Include Logo'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: buttonTextColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: _generatePixelMaps,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonBackgroundColor,
                          foregroundColor: buttonTextColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Generate Pixel Maps',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: headerBackgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: headerTextColor),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: headerTextColor,
        ),
      ),
    );
  }

  Widget _buildSurfacePreviewWithOptions() {
    if (widget.surfaces.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: borderColorLight),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'No surfaces available for pixel map generation',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColorLight),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          // Header with column titles
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 40), // Checkbox + spacing width
                const SizedBox(
                  width: 30,
                  child: Text(
                    'No.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 30),
                const SizedBox(
                  width: 150,
                  child: Text(
                    'Surface Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 20),
                const SizedBox(
                  width: 120,
                  child: Text(
                    'Resolution',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 20),
                const SizedBox(
                  width: 80,
                  child: Text(
                    'Panels',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Surface list with checkboxes and new columns
          ...widget.surfaces.asMap().entries.map((entry) {
            int index = entry.key;
            Surface surface = entry.value;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: index > 0
                    ? Border(top: BorderSide(color: Colors.grey[300]!))
                    : null,
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _selectedSurfaces[index] ?? false,
                    onChanged: (bool? value) {
                      setState(() {
                        _selectedSurfaces[index] = value ?? false;
                      });
                    },
                    activeColor: headerTextColor,
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 30),
                  SizedBox(
                    width: 150,
                    child: Text(
                      surface.name.isEmpty
                          ? 'Surface ${index + 1}'
                          : surface.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 120,
                    child: Text(
                      surface.calculation != null
                          ? '${surface.calculation!.pixelsWidth} × ${surface.calculation!.pixelsHeight}'
                          : 'Not calculated',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 80,
                    child: Text(
                      surface.calculation != null
                          ? '${surface.calculation!.panelsWidth} × ${surface.calculation!.panelsHeight}'
                          : '-',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _drawLogo(
    Canvas canvas,
    double canvasWidth,
    double canvasHeight,
  ) async {
    // Only draw logo if checkbox is checked and logo is available
    if (_includeLogo && widget.logoBase64 != null) {
      try {
        // Extract base64 data and convert to bytes
        final base64Data = widget.logoBase64!.split(',').last;
        final uint8List = FileService.base64ToBytes(base64Data);

        // Create image from bytes
        final codec = await ui.instantiateImageCodec(uint8List);
        final frame = await codec.getNextFrame();
        final image = frame.image;

        // Position logo in bottom right corner
        const double logoSize = 150;
        final double logoX = canvasWidth - logoSize - 50;
        final double logoY = canvasHeight - logoSize - 50;

        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromLTWH(logoX, logoY, logoSize, logoSize),
          Paint(),
        );
      } catch (e) {
        print('Error drawing logo: $e');
      }
    }
  }

  Future<void> _generatePixelMaps() async {
    try {
      if (_selectedOption == 'Selected Surfaces') {
        await _generateSelectedMaps();
      } else {
        await _generateAllMaps();
      }

      // Removed success notification - keep only error notifications
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating pixel maps: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom:
                MediaQuery.of(context).size.height * 0.5, // Bottom half height
            left: 16,
            right: 16,
          ),
          duration: const Duration(
            milliseconds: 2000,
          ), // Half time (2 seconds instead of 4)
        ),
      );
    }
  }

  Future<void> _generateSelectedMaps() async {
    for (int i = 0; i < widget.surfaces.length; i++) {
      if (_selectedSurfaces[i] == true) {
        final surface = widget.surfaces[i];
        if (surface.calculation != null) {
          final imageBytes = await PixelMapService.createPixelMapImage(
            surface,
            i,
          );
          final fileName = _generateFileName(surface, i);
          _downloadImage(imageBytes, fileName);
        }
      }
    }
  }

  Future<void> _generateAllMaps() async {
    for (int i = 0; i < widget.surfaces.length; i++) {
      final surface = widget.surfaces[i];
      if (surface.calculation != null) {
        final imageBytes = await PixelMapService.createPixelMapImage(
          surface,
          i,
        );
        final fileName = _generateFileName(surface, i);
        _downloadImage(imageBytes, fileName);
      }
    }
  }

  void _drawPixelGrid(
    Canvas canvas,
    double startX,
    double startY,
    double cellSize,
    int panelsWidth,
    int panelsHeight,
  ) {
    final paint = Paint();

    // Color pattern similar to the reference image
    final colors = [
      const Color(0xFF8B4C8B), // Purple
      const Color(0xFF2E7D7D), // Teal
      const Color(0xFF8B8B4C), // Olive
      const Color(0xFF4C4C8B), // Navy
      const Color(0xFF4C8B4C), // Green
      const Color(0xFF8B4C4C), // Maroon
    ];

    // Draw grid cells with corrected numbering
    for (int row = 0; row < panelsHeight; row++) {
      for (int col = 0; col < panelsWidth; col++) {
        final x = startX + (col * cellSize);
        final y = startY + (row * cellSize);

        // Select color based on position for pattern variety
        final colorIndex = (row + col) % colors.length;
        paint.color = colors[colorIndex];

        // Draw cell
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize - 2, cellSize - 2), // -2 for border
          paint,
        );

        // Draw panel number in TOP LEFT corner of each panel (increased font size by 1)
        // Corrected numbering: horizontal first (1,1 then 1,2 etc), then vertical (2,1 etc)
        final panelLabel = '${row + 1},${col + 1}';
        final panelTextPainter = TextPainter(
          text: TextSpan(
            text: panelLabel,
            style: TextStyle(
              color: Colors.white,
              fontSize: math.max(9, cellSize / 8 + 1), // Increased by 1
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        panelTextPainter.layout();

        // Position in top-left corner of panel
        panelTextPainter.paint(
          canvas,
          Offset(x + 4, y + 4), // 4px padding from edges
        );

        // Removed the panel markers (5 circles and cross)
      }
    }

    // Draw grid lines (changed to white with 0.5px thickness)
    paint.color = Colors.white; // Changed from gray to white
    paint.strokeWidth = 0.5; // Changed from 2 to 0.5px

    // Vertical lines
    for (int i = 0; i <= panelsWidth; i++) {
      final x = startX + (i * cellSize);
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, startY + (panelsHeight * cellSize)),
        paint,
      );
    }

    // Horizontal lines
    for (int i = 0; i <= panelsHeight; i++) {
      final y = startY + (i * cellSize);
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + (panelsWidth * cellSize), y),
        paint,
      );
    }
  }

  String _generateFileName(Surface surface, int index) {
    String fileName = '';

    // Start with project number if available
    if (widget.projectData != null &&
        widget.projectData!.projectNumber.isNotEmpty) {
      fileName += widget.projectData!.projectNumber;
    }

    // Add PixelMap
    fileName += fileName.isEmpty ? 'PixelMap' : '_PixelMap';

    // Add surface name
    final surfaceName = surface.name.isEmpty
        ? 'Surface${index + 1}'
        : surface.name;
    final cleanName = surfaceName.replaceAll(RegExp(r'[^\w\-_]'), '_');
    fileName += '_$cleanName';

    return fileName;
  }

  void _downloadImage(Uint8List bytes, String fileName) async {
    try {
      await FileService.downloadFile(bytes, '$fileName.jpg', 'image/jpeg');
    } catch (e) {
      print('Error downloading image: $e');
    }
  }
}
