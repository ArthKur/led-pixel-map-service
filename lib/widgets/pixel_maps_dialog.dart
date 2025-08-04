import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../models/surface_model.dart';
import '../services/pixel_map_service.dart';
import '../services/file_service.dart';

// Border colors as per style guide
const Color borderColorLight = Color(0xFFE7DCCC); // Lighter border #E7DCCC
const Color borderColorDark = Color(0xFFD4C7B7); // Darker border #D4C7B7

// Text colors as per style guide
const Color textColorPrimary = Color(
  0xFF383838,
); // Deep neutral gray for most text
const Color textColorSecondary = Color(
  0xFFA2A09A,
); // Light gray for secondary/disabled text

// Header/accent colors as per style guide
const Color headerBackgroundColor = Color(
  0xFFEADFC9,
); // Warm tan/sand/cream #EADFC9
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
          final imageBytes = await PixelMapService.createPixelMapImageSmart(
            surface,
            i,
            showGrid: true,
            showPanelNumbers: true,
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
        final imageBytes = await PixelMapService.createPixelMapImageSmart(
          surface,
          i,
          showGrid: true,
          showPanelNumbers: true,
        );
        final fileName = _generateFileName(surface, i);
        _downloadImage(imageBytes, fileName);
      }
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
