import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:html' as html;
import '../models/surface_model.dart';
import '../services/pixel_map_service.dart';

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
  final Map<int, bool> _selectedSurfaces =
      {}; // Track which surfaces are selected
  String? _customLogoBase64;
  String? _customLogoFileName;
  bool _useDefaultLogo = true;

  // Pixel-perfect options
  bool _usePixelPerfect = false;
  final TextEditingController _widthController = TextEditingController(
    text: '4000',
  );
  final TextEditingController _heightController = TextEditingController(
    text: '2000',
  );
  bool _showPanelNumbers = true;
  bool _showGrid = true;

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Export options
                    _buildExportOptions(),
                    const SizedBox(height: 20),

                    // Pixel-perfect options
                    _buildPixelPerfectOptions(),
                    const SizedBox(height: 20),

                    // Surface selection
                    Expanded(child: _buildSurfaceSelection()),
                    const SizedBox(height: 20),

                    // Custom logo section
                    _buildCustomLogoSection(),
                    const SizedBox(height: 20),

                    // Generate button
                    _buildGenerateButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptions() {
    return Card(
      color: widget.isDarkMode ? Colors.grey[700] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
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
                                : Colors.black,
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
          ],
        ),
      ),
    );
  }

  Widget _buildPixelPerfectOptions() {
    return Card(
      color: widget.isDarkMode ? Colors.grey[700] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _usePixelPerfect,
                  onChanged: (value) {
                    setState(() {
                      _usePixelPerfect = value ?? false;
                    });
                  },
                ),
                Text(
                  'Pixel-Perfect Mode',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            if (_usePixelPerfect) ...[
              const SizedBox(height: 10),
              Text(
                'Generate exact pixel dimensions for precise video mapping',
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDarkMode
                      ? Colors.grey[300]
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _widthController,
                      decoration: InputDecoration(
                        labelText: 'Width (px)',
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(
                          color: widget.isDarkMode
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      decoration: InputDecoration(
                        labelText: 'Height (px)',
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(
                          color: widget.isDarkMode
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: Text(
                        'Show Panel Numbers',
                        style: TextStyle(
                          color: widget.isDarkMode
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      value: _showPanelNumbers,
                      onChanged: (value) {
                        setState(() {
                          _showPanelNumbers = value ?? true;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      title: Text(
                        'Show Grid',
                        style: TextStyle(
                          color: widget.isDarkMode
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                      value: _showGrid,
                      onChanged: (value) {
                        setState(() {
                          _showGrid = value ?? true;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSurfaceSelection() {
    return Card(
      color: widget.isDarkMode ? Colors.grey[700] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Surface Selection',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
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
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '${surface.width} x ${surface.height} panels',
                      style: TextStyle(
                        color: widget.isDarkMode
                            ? Colors.grey[300]
                            : Colors.grey[600],
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
      ),
    );
  }

  Widget _buildCustomLogoSection() {
    return Card(
      color: widget.isDarkMode ? Colors.grey[700] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Logo Options',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: _useDefaultLogo,
                  onChanged: (value) {
                    setState(() {
                      _useDefaultLogo = value!;
                    });
                  },
                ),
                Text(
                  'Use Default Logo',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(width: 20),
                Radio<bool>(
                  value: false,
                  groupValue: _useDefaultLogo,
                  onChanged: (value) {
                    setState(() {
                      _useDefaultLogo = value!;
                    });
                  },
                ),
                Text(
                  'Custom Logo',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            if (!_useDefaultLogo) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _importCustomLogo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonBackgroundColor,
                      foregroundColor: buttonTextColor,
                    ),
                    child: const Text('Import Logo'),
                  ),
                  const SizedBox(width: 10),
                  if (_customLogoFileName != null)
                    Text(
                      _customLogoFileName!,
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _generatePixelMaps,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Generate Pixel Maps',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _generatePixelMaps() async {
    List<Surface> surfacesToExport = [];

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

        final image = await _createPixelMapImage(surface, originalIndex);
        final fileName = _generateFileName(surface, originalIndex);

        await _downloadImage(image, fileName);
      }

      _showMessage('Pixel maps generated successfully!');
    } catch (e) {
      _showMessage('Error generating pixel maps: $e');
    }
  }

  Future<ui.Image> _createPixelMapImage(Surface surface, int index) async {
    if (_usePixelPerfect) {
      // Use the smart pixel-perfect service with cloud support
      final width = int.tryParse(_widthController.text) ?? 4000;
      final height = int.tryParse(_heightController.text) ?? 2000;

      // Get bytes from smart service and convert to Image
      final imageBytes =
          await PixelMapService.createUltraPixelPerfectImageSmart(
            surface,
            index,
            imageWidth: width,
            imageHeight: height,
            showPanelNumbers: _showPanelNumbers,
            showGrid: _showGrid,
          );

      // Convert bytes to ui.Image
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } else {
      // Use the smart standard service with cloud support
      final imageBytes = await PixelMapService.createPixelMapImageSmart(
        surface,
        index,
        showGrid: _showGrid,
        showPanelNumbers: _showPanelNumbers,
      );

      // Convert bytes to ui.Image
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    }
  }

  Future<void> _importCustomLogo() async {
    try {
      // Implementation would go here for web file picker
      // For now, show a message
      _showMessage('Custom logo import feature coming soon!');
    } catch (e) {
      _showMessage('Error importing logo: $e');
    }
  }

  String _generateFileName(Surface surface, int index) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final prefix = _usePixelPerfect ? 'pixelperfect' : 'pixelmap';
    return '${prefix}_${surface.name.replaceAll(' ', '_')}_${index + 1}_$timestamp.png';
  }

  Future<void> _downloadImage(ui.Image image, String fileName) async {
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final blob = html.Blob([byteData.buffer.asUint8List()]);
        final url = html.Url.createObjectUrlFromBlob(blob);

        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();

        html.Url.revokeObjectUrl(url);
      }
    } catch (e) {
      throw Exception('Failed to download image: $e');
    }
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pixel Maps'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
