import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../models/surface_model.dart';
import '../services/cloud_pixel_map_service.dart';
import 'dart:io' show Platform, File, Directory;
import 'package:flutter/foundation.dart' show kIsWeb;

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
  final List<String> _exportOptions = ['Selected Surfaces', 'All Surfaces'];
  String _selectedOption = 'Selected Surfaces';
  final Map<int, bool> _selectedSurfaces =
      {}; // Track which surfaces are selected
  bool _showPanelNumbers = true; // Control panel numbering display

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
      backgroundColor: widget.isDarkMode
          ? const Color(0xFF23272F) // Gunmetal/slate gray panel background
          : const Color(0xFFF7F6F3), // Very light warm gray
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.grid_view,
                  color: widget.isDarkMode ? Colors.white : Colors.blue[600],
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'Generate Ultra Pixel-Perfect Maps',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : textColorPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: widget.isDarkMode ? Colors.white : buttonTextColor,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: headerBackgroundColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: borderColorLight.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: widget.isDarkMode
                              ? Colors.white
                              : textColorPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Generates ultra-high-quality pixel-perfect images with exact 1:1 LED pixel mapping. Anti-aliasing disabled for maximum sharpness.',
                            style: TextStyle(
                              fontSize: 13,
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : textColorPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Export options
                  _buildExportOptions(),
                  const SizedBox(height: 20),

                  // Surface selection
                  Expanded(child: _buildSurfaceSelection()),
                  const SizedBox(height: 20),

                  // Generate button
                  _buildGenerateButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: headerBackgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColorLight.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                size: 16,
                color: widget.isDarkMode ? Colors.white : textColorPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                'Export Options',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : textColorPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: _exportOptions
                .map(
                  (option) => Expanded(
                    child: RadioListTile<String>(
                      title: Text(
                        option,
                        style: TextStyle(
                          color: widget.isDarkMode
                              ? Colors.white
                              : textColorPrimary,
                        ),
                      ),
                      value: option,
                      groupValue: _selectedOption,
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value!;
                        });
                      },
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 15),
          // Panel numbering checkbox
          CheckboxListTile(
            title: Text(
              'Show Panel Numbers',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : textColorPrimary,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              'Display panel coordinates on the pixel map',
              style: TextStyle(
                color: widget.isDarkMode
                    ? Colors.grey[300]
                    : textColorSecondary,
                fontSize: 12,
              ),
            ),
            value: _showPanelNumbers,
            onChanged: (value) {
              setState(() {
                _showPanelNumbers = value ?? true;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSurfaceSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: headerBackgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColorLight.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.layers,
                size: 16,
                color: widget.isDarkMode ? Colors.white : textColorPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                'Surface Selection',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : textColorPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: widget.surfaces.length,
              itemBuilder: (context, index) {
                final surface = widget.surfaces[index];
                return CheckboxListTile(
                  title: Text(
                    surface.name,
                    style: TextStyle(
                      color: widget.isDarkMode
                          ? Colors.white
                          : textColorPrimary,
                    ),
                  ),
                  subtitle: Text(
                    surface.calculation != null
                        ? '${surface.calculation!.pixelsWidth} x ${surface.calculation!.pixelsHeight} pixels'
                        : 'No calculation available',
                    style: TextStyle(
                      color: widget.isDarkMode
                          ? Colors.grey[300]
                          : textColorSecondary,
                    ),
                  ),
                  value: _selectedSurfaces[index] ?? false,
                  onChanged: _selectedOption == 'Selected Surfaces'
                      ? (value) {
                          setState(() {
                            _selectedSurfaces[index] = value ?? false;
                          });
                        }
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _generatePixelMaps,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonBackgroundColor,
          foregroundColor: buttonTextColor,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download, size: 18, color: buttonTextColor),
            const SizedBox(width: 8),
            const Text(
              'Generate Pixel-Perfect Maps',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePixelMaps() async {
    final List<Surface> surfacesToExport;

    if (_selectedOption == 'All Surfaces') {
      surfacesToExport = widget.surfaces;
    } else {
      surfacesToExport = widget.surfaces
          .asMap()
          .entries
          .where((entry) => _selectedSurfaces[entry.key] == true)
          .map((entry) => entry.value)
          .toList();
    }

    if (surfacesToExport.isEmpty) {
      _showMessage('Please select at least one surface to export.');
      return;
    }

    try {
      for (int i = 0; i < surfacesToExport.length; i++) {
        final surface = surfacesToExport[i];
        final originalIndex = widget.surfaces.indexOf(surface);

        print('🔄 Starting generation for surface: ${surface.name}');
        final imageBytes = await _createPixelMapImage(surface, originalIndex);
        print('✅ Image generated: ${imageBytes.length} bytes');
        
        final fileName = _generateFileName(surface, originalIndex);
        print('💾 Attempting to download: $fileName');

        await _downloadImageBytes(imageBytes, fileName);
        print('✅ Download completed for: $fileName');
      }

      _showMessage('✅ All pixel maps generated and saved successfully!');
    } catch (e) {
      print('❌ Error in _generatePixelMaps: $e');
      _showMessage('❌ Error generating pixel maps: $e');
    }
  }

  Future<Uint8List> _createPixelMapImage(Surface surface, int index) async {
    // Use cloud service directly for better error handling
    if (surface.calculation == null) {
      throw Exception('Surface ${surface.name} has no calculation data');
    }

    print('🔄 Generating pixel map for ${surface.name} via cloud service...');
    
    // Import the cloud service
    final cloudResult = await CloudPixelMapService.generateCloudPixelMap(
      surface,
      index,
      showGrid: true,
      showPanelNumbers: _showPanelNumbers,
    );

    if (cloudResult.isSuccess && cloudResult.imageBytes != null) {
      print('✅ Cloud generation successful: ${cloudResult.width}×${cloudResult.height}px (${cloudResult.fileSizeMB}MB)');
      return cloudResult.imageBytes!;
    } else {
      print('❌ Cloud generation failed: ${cloudResult.errorMessage}');
      throw Exception('Cloud generation failed: ${cloudResult.errorMessage}');
    }
  }

  String _generateFileName(Surface surface, int index) {
    // Get pixel resolution
    final pixelResolution = surface.calculation != null
        ? '${surface.calculation!.pixelsWidth}x${surface.calculation!.pixelsHeight}'
        : 'unknown_resolution';

    // Get project information
    final projectNumber =
        widget.projectData?.projectNumber != null &&
            widget.projectData!.projectNumber.isNotEmpty
        ? widget.projectData!.projectNumber
        : 'no_project_number';

    final projectName =
        widget.projectData?.projectName != null &&
            widget.projectData!.projectName.isNotEmpty
        ? widget.projectData!.projectName.replaceAll(' ', '_')
        : 'no_project_name';

    // Clean surface name
    final surfaceName = surface.name.replaceAll(' ', '_');

    // Format: Pixel_Map_[resolution]_[project_number]_[project_name]_[surface_name]_[surface_index].png
    return 'Pixel_Map_${pixelResolution}_${projectNumber}_${projectName}_${surfaceName}_${index + 1}.png';
  }

  Future<void> _downloadImageBytes(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      if (kIsWeb) {
        // Web platform - show message that download is not available
        _showMessage('Download not available on this platform. Try web version or save from cloud service.');
      } else {
        // Desktop platforms - save to file system
        try {
          // Get the user's home directory
          final homeDir = Platform.environment['HOME'] ?? '/Users/${Platform.environment['USER']}';
          
          // Try Desktop first
          final desktopPath = '$homeDir/Desktop';
          final desktopDir = Directory(desktopPath);
          
          if (await desktopDir.exists()) {
            final file = File('$desktopPath/$fileName');
            await file.writeAsBytes(imageBytes);
            _showMessage('✅ File saved to Desktop: $fileName');
            print('File saved to: ${file.path}');
          } else {
            // Fallback: try Downloads folder
            final downloadsPath = '$homeDir/Downloads';
            final downloadsDir = Directory(downloadsPath);
            
            if (await downloadsDir.exists()) {
              final file = File('$downloadsPath/$fileName');
              await file.writeAsBytes(imageBytes);
              _showMessage('✅ File saved to Downloads: $fileName');
              print('File saved to: ${file.path}');
            } else {
              // Last fallback: save to Documents
              final documentsPath = '$homeDir/Documents';
              final file = File('$documentsPath/$fileName');
              await file.writeAsBytes(imageBytes);
              _showMessage('✅ File saved to Documents: $fileName');
              print('File saved to: ${file.path}');
            }
          }
        } catch (e) {
          print('Download error: $e');
          _showMessage('❌ Failed to save file: $e');
        }
      }
    } catch (e) {
      print('Download exception: $e');
      throw Exception('Failed to download image: $e');
    }
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode
            ? const Color(0xFF23272F) // Gunmetal/slate gray panel background
            : const Color(0xFFF7F6F3), // Very light warm gray
        title: Row(
          children: [
            Icon(
              Icons.grid_view,
              color: widget.isDarkMode ? Colors.white : Colors.blue[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Pixel Maps',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : textColorPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : textColorPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: widget.isDarkMode
                  ? Colors.white
                  : buttonTextColor,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
