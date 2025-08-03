import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:math' as math;
import '../models/surface_model.dart';

// Define the new button background color as per style guide
const Color buttonBackgroundColor = Color.fromRGBO(247, 238, 221, 1.0);

// Define the new button text color as per style guide
const Color buttonTextColor = Color.fromRGBO(178, 167, 147, 1.0);

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
  final List<String> _exportOptions = ['Selected Surfaces', 'All Surfaces'];
  String _selectedOption = 'Selected Surfaces';
  final Map<int, bool> _selectedSurfaces = {}; // Track which surfaces are selected
  String? _customLogoBase64;
  String? _customLogoFileName;
  bool _useDefaultLogo = true;

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
            color: widget.isDarkMode ? Colors.white : Colors.amber,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(13),
                  topRight: Radius.circular(13),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.grid_view, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'Generate Pixel Maps',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
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
                    // Export Options
                    _buildSectionHeader('Export Options'),
                    const SizedBox(height: 10),
                    _buildExportOptions(),
                    
                    const SizedBox(height: 20),

                    // Logo Options
                    _buildSectionHeader('Logo Options'),
                    const SizedBox(height: 10),
                    _buildLogoOptions(),
                    
                    const SizedBox(height: 20),

                    // Preview Section
                    _buildSectionHeader('Surface Preview'),
                    const SizedBox(height: 10),
                    _buildSurfacePreview(),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
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
        ),
                    child: const Text(
                      'Generate Pixel Maps',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
        color: Colors.amber[100],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.amber[800]!),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.amber[800],
        ),
      ),
    );
  }

  Widget _buildExportOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Export Option:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ..._exportOptions.map((option) => RadioListTile<String>(
                title: Text(option),
                subtitle: Text(option == 'Selected Surfaces' 
                    ? 'Generate JPGs for selected surfaces only'
                    : 'Generate JPGs for all surfaces as individual files'),
                value: option,
                groupValue: _selectedOption,
                onChanged: (value) {
                  setState(() {
                    _selectedOption = value!;
                  });
                },
                activeColor: Colors.amber,
              )),
        ],
      ),
    );
  }

  Widget _buildLogoOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Logo Settings:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          
          // Use default logo option
          CheckboxListTile(
            title: const Text('Use Project Logo'),
            subtitle: Text(widget.logoBase64 != null 
                ? 'Current project logo will be used'
                : 'No project logo available'),
            value: _useDefaultLogo,
            onChanged: widget.logoBase64 != null ? (value) {
              setState(() {
                _useDefaultLogo = value!;
              });
            } : null,
            activeColor: Colors.amber,
          ),
          
          // Import custom logo option
          if (!_useDefaultLogo) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _importCustomLogo,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Import Custom Logo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: buttonTextColor,
                  ),
                ),
                if (_customLogoFileName != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Selected: $_customLogoFileName',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSurfacePreview() {
    if (widget.surfaces.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
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
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          // Header
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
                const Text('Select', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 40),
                const Text('Surface Name', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                const Text('Resolution', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 80),
                const Text('Panels', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          // Surface list with checkboxes
          ...widget.surfaces.asMap().entries.map((entry) {
            int index = entry.key;
            Surface surface = entry.value;
            
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: index > 0 ? Border(top: BorderSide(color: Colors.grey[300]!)) : null,
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
                    activeColor: Colors.amber,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      surface.name.isEmpty ? 'Surface ${index + 1}' : surface.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(
                      surface.calculation != null 
                          ? '${surface.calculation!.pixelsWidth} × ${surface.calculation!.pixelsHeight}'
                          : 'Not calculated',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      surface.calculation != null 
                          ? '${surface.calculation!.panelsWidth} × ${surface.calculation!.panelsHeight}'
                          : '-',
                      textAlign: TextAlign.center,
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

  void _importCustomLogo() async {
    try {
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((e) {
        final files = uploadInput.files;
        if (files!.isEmpty) return;

        final reader = html.FileReader();
        reader.readAsDataUrl(files[0]);
        reader.onLoadEnd.listen((e) {
          setState(() {
            _customLogoBase64 = reader.result as String;
            _customLogoFileName = files[0].name;
          });
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error importing logo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generatePixelMaps() async {
    try {
      if (_selectedOption == 'Selected Surfaces') {
        await _generateSelectedMaps();
      } else {
        await _generateAllMaps();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pixel maps generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating pixel maps: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateSelectedMaps() async {
    for (int i = 0; i < widget.surfaces.length; i++) {
      if (_selectedSurfaces[i] == true) {
        final surface = widget.surfaces[i];
        if (surface.calculation != null) {
          final imageBytes = await _createPixelMapImage(surface, i);
          final fileName = _generateFileName(surface, i, false);
          _downloadImage(imageBytes, fileName);
        }
      }
    }
  }

  Future<void> _generateAllMaps() async {
    for (int i = 0; i < widget.surfaces.length; i++) {
      final surface = widget.surfaces[i];
      if (surface.calculation != null) {
        final imageBytes = await _createPixelMapImage(surface, i);
        final fileName = _generateFileName(surface, i, false);
        _downloadImage(imageBytes, fileName);
      }
    }
  }

  Future<Uint8List> _createPixelMapImage(Surface surface, int index) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();
    
    // Canvas dimensions
    const double canvasWidth = 1920;
    const double canvasHeight = 1080;
    
    // Background
    paint.color = const Color(0xFF2D2D2D); // Dark gray background
    canvas.drawRect(Rect.fromLTWH(0, 0, canvasWidth, canvasHeight), paint);
    
    // Calculate grid dimensions and positioning
    final panelsWidth = surface.calculation!.panelsWidth;
    final panelsHeight = surface.calculation!.panelsHeight;
    
    // Grid area (leave space for title and margins)
    const double gridMargin = 100;
    const double titleHeight = 150; // Increased for title + resolution
    final double availableWidth = canvasWidth - (gridMargin * 2);
    final double availableHeight = canvasHeight - titleHeight - (gridMargin * 2);
    
    // Calculate cell size to fit the grid
    final double cellWidth = availableWidth / panelsWidth;
    final double cellHeight = availableHeight / panelsHeight;
    final double cellSize = math.min(cellWidth, cellHeight);
    
    // Center the grid
    final double gridWidth = panelsWidth * cellSize;
    final double gridHeight = panelsHeight * cellSize;
    final double gridStartX = (canvasWidth - gridWidth) / 2;
    final double gridStartY = titleHeight + (availableHeight - gridHeight) / 2;
    
    // Draw title with "Screen One" style - MOVED TO CENTER
    final surfaceName = surface.name.isEmpty ? 'Screen ${index + 1}' : surface.name;
    final textPainter = TextPainter(
      text: TextSpan(
        text: surfaceName,
        style: const TextStyle(
          color: Color(0xFFFFD700), // Golden color like in reference
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    // Center the title horizontally and vertically in the grid area
    final titleX = gridStartX + (gridWidth - textPainter.width) / 2;
    final titleY = gridStartY + (gridHeight - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(titleX, titleY));
    
    // Add pixel size info to BOTTOM LEFT corner of surface
    final pixelSizeText = '${surface.calculation!.pixelsWidth} × ${surface.calculation!.pixelsHeight}';
    final pixelSizePainter = TextPainter(
      text: TextSpan(
        text: pixelSizeText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    pixelSizePainter.layout();
    pixelSizePainter.paint(
      canvas,
      Offset(
        gridStartX + 10, // 10px from left edge
        gridStartY + gridHeight - pixelSizePainter.height - 10, // 10px from bottom
      ),
    );
    
    // Draw grid
    _drawPixelGrid(
      canvas, 
      gridStartX, 
      gridStartY, 
      cellSize, 
      panelsWidth, 
      panelsHeight
    );
    
    // Draw logo if available
    await _drawLogo(canvas, canvasWidth, canvasHeight);
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(canvasWidth.toInt(), canvasHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _drawLogo(Canvas canvas, double canvasWidth, double canvasHeight) async {

  void drawSurfaceInArea(Canvas canvas, Surface surface, double x, double y, double width, double height, int index) {
    // Draw surface title with "Screen" prefix
    final surfaceName = surface.name.isEmpty ? 'Screen ${index + 1}' : surface.name;
    final textPainter = TextPainter(
      text: TextSpan(
        text: surfaceName,
        style: const TextStyle(
          color: Color(0xFFFFD700), // Golden color
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x + (width - textPainter.width) / 2, y + 20),
    );
    
    // Add resolution info
    final resolutionText = '${surface.calculation!.pixelsWidth} × ${surface.calculation!.pixelsHeight}';
    final resolutionPainter = TextPainter(
      text: TextSpan(
        text: resolutionText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    resolutionPainter.layout();
    resolutionPainter.paint(
      canvas,
      Offset(x + (width - resolutionPainter.width) / 2, y + 50),
    );
    
    // Calculate grid area
    const double margin = 40;
    final double titleHeight = 60;
    final double gridX = x + margin;
    final double gridY = y + titleHeight + margin;
    final double gridWidth = width - (margin * 2);
    final double gridHeight = height - titleHeight - (margin * 2);
    
    final panelsWidth = surface.calculation!.panelsWidth;
    final panelsHeight = surface.calculation!.panelsHeight;
    
    final double cellWidth = gridWidth / panelsWidth;
    final double cellHeight = gridHeight / panelsHeight;
    final double cellSize = math.min(cellWidth, cellHeight);
    
    // Center the grid in the available area
    final double actualGridWidth = panelsWidth * cellSize;
    final double actualGridHeight = panelsHeight * cellSize;
    final double centeredGridX = gridX + (gridWidth - actualGridWidth) / 2;
    final double centeredGridY = gridY + (gridHeight - actualGridHeight) / 2;
    
    drawPixelGrid(canvas, centeredGridX, centeredGridY, cellSize, panelsWidth, panelsHeight);
  }

  void drawPixelGrid(Canvas canvas, double startX, double startY, double cellSize, int panelsWidth, int panelsHeight) {
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
        
        // Draw panel number in TOP LEFT corner of each panel
        // Corrected numbering: horizontal first (1,1 then 1,2 etc), then vertical (2,1 etc)
        final panelLabel = '${row + 1},${col + 1}';
        final panelTextPainter = TextPainter(
          text: TextSpan(
            text: panelLabel,
            style: TextStyle(
              color: Colors.white,
              fontSize: math.max(8, cellSize / 8),
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
        
        // Add 5 circles and cross in center of each panel (if panel is large enough)
        if (cellSize > 40) {
          drawPanelMarkers(canvas, x, y, cellSize);
        }
      }
    }
    
    // Draw grid lines
    paint.color = const Color(0xFF666666); // Gray grid lines
    paint.strokeWidth = 2;
    
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

  void drawPanelMarkers(Canvas canvas, double panelX, double panelY, double cellSize) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final centerX = panelX + cellSize / 2;
    final centerY = panelY + cellSize / 2;
    final circleRadius = cellSize / 20; // Small circles
    final markerSpacing = cellSize / 8;
    
    // Draw 5 circles in a cross pattern
    final circlePositions = [
      Offset(centerX, centerY), // Center
      Offset(centerX - markerSpacing, centerY), // Left
      Offset(centerX + markerSpacing, centerY), // Right
      Offset(centerX, centerY - markerSpacing), // Top
      Offset(centerX, centerY + markerSpacing), // Bottom
    ];
    
    for (final position in circlePositions) {
      canvas.drawCircle(position, circleRadius, paint);
    }
    
    // Draw cross in the center
    final crossSize = cellSize / 12;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    
    // Horizontal line of cross
    canvas.drawLine(
      Offset(centerX - crossSize, centerY),
      Offset(centerX + crossSize, centerY),
      paint,
    );
    
    // Vertical line of cross
    canvas.drawLine(
      Offset(centerX, centerY - crossSize),
      Offset(centerX, centerY + crossSize),
      paint,
    );
  }

  Future<void> drawLogo(Canvas canvas, double canvasWidth, double canvasHeight) async {
    String? logoBase64;
    
    if (_useDefaultLogo && widget.logoBase64 != null) {
      logoBase64 = widget.logoBase64;
    } else if (!_useDefaultLogo && _customLogoBase64 != null) {
      logoBase64 = _customLogoBase64;
    }
    
    if (logoBase64 != null) {
      try {
        // Extract base64 data
        final base64Data = logoBase64.split(',').last;
        final bytes = html.window.atob(base64Data);
        final uint8List = Uint8List.fromList(bytes.codeUnits);
        
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

  String generateFileName(Surface? surface, int index, bool isCombined) {
    String fileName = 'PixelMap';
    
    if (widget.projectData != null && widget.projectData!.projectNumber.isNotEmpty) {
      fileName += '_${widget.projectData!.projectNumber}';
    }
    
    if (isCombined) {
      fileName += '_AllSurfaces';
    } else if (surface != null) {
      final surfaceName = surface.name.isEmpty ? 'Surface${index + 1}' : surface.name;
      final cleanName = surfaceName.replaceAll(RegExp(r'[^\w\-_]'), '_');
      fileName += '_$cleanName';
    }
    
    fileName += '_${DateTime.now().millisecondsSinceEpoch}';
    return fileName;
  }

  void downloadImage(Uint8List bytes, String fileName) {
    final blob = html.Blob([bytes], 'image/jpeg');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement()
      ..href = url
      ..style.display = 'none'
      ..download = '$fileName.jpg';
    
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}
