import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/surface_model.dart';
import '../services/pixel_map_service_browser_safe.dart';
import '../services/cloud_pixel_map_service.dart';

class EnhancedPixelMapsDialog extends StatefulWidget {
  final List<Surface> surfaces;

  const EnhancedPixelMapsDialog({super.key, required this.surfaces});

  @override
  State<EnhancedPixelMapsDialog> createState() =>
      _EnhancedPixelMapsDialogState();
}

class _EnhancedPixelMapsDialogState extends State<EnhancedPixelMapsDialog> {
  String _selectedQuality = 'high_quality';
  bool _showGrid = true;
  bool _showPanelNumbers = true;
  bool _useActualPanelPixels = true;
  bool _allowOverride = false;
  bool _useCloudService = false;
  bool _isGenerating = false;
  bool _isCloudHealthy = false;
  String? _cloudServiceInfo;

  @override
  void initState() {
    super.initState();
    _checkCloudService();
  }

  Future<void> _checkCloudService() async {
    final isHealthy = await CloudPixelMapService.isServiceHealthy();
    final serviceInfo = await CloudPixelMapService.getServiceInfo();

    setState(() {
      _isCloudHealthy = isHealthy;
      _cloudServiceInfo = serviceInfo != null
          ? '${serviceInfo['service']} v${serviceInfo['version']}'
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final validSurfaces = widget.surfaces
        .where((s) => s.calculation != null && s.selectedLED != null)
        .toList();

    if (validSurfaces.isEmpty) {
      return AlertDialog(
        title: const Text('No Valid Surfaces'),
        content: const Text(
          'No surfaces with LED calculations found. Please configure at least one surface with LED selection and calculations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Generate LED Pixel Maps'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Selection
            const Text(
              'Generation Method',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Cloud Service Option
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isCloudHealthy ? Colors.green : Colors.orange,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
                color: _isCloudHealthy
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: _useCloudService,
                        onChanged: _isCloudHealthy
                            ? (value) {
                                setState(() {
                                  _useCloudService = value ?? false;
                                });
                              }
                            : null,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Cloud Service',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isCloudHealthy
                                        ? Colors.green
                                        : Colors.orange,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _isCloudHealthy ? 'ONLINE' : 'CHECKING...',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '✅ Unlimited image sizes (no browser limits)\n'
                              '✅ Handles 100M+ pixels easily\n'
                              '✅ Fast Python PIL rendering',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                              ),
                            ),
                            if (_cloudServiceInfo != null)
                              Text(
                                _cloudServiceInfo!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Browser Service Option
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue.withOpacity(0.1),
              ),
              child: Row(
                children: [
                  Radio<bool>(
                    value: false,
                    groupValue: _useCloudService,
                    onChanged: (value) {
                      setState(() {
                        _useCloudService = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Browser Rendering',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '⚠️ Limited to 32K×32K pixels (65K with override)\n'
                          '⚠️ Memory constraints for large images\n'
                          '✅ No internet connection required',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quality Selection (only for browser rendering)
            if (!_useCloudService) ...[
              const Text(
                'Quality Preset',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedQuality,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: PixelMapServiceBrowserSafe.qualityPresets.keys.map((
                  key,
                ) {
                  final preset =
                      PixelMapServiceBrowserSafe.getRecommendedDimensions(key);
                  return DropdownMenuItem(
                    value: key,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(preset['description'] ?? key),
                        Text(
                          'Max: ${preset['maxWidth']}×${preset['maxHeight']}px',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedQuality = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            // Options
            const Text(
              'Options',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            CheckboxListTile(
              title: const Text('Use actual LED panel pixels'),
              subtitle: const Text(
                'Calculate exact pixel dimensions from LED specifications',
              ),
              value: _useActualPanelPixels,
              onChanged: (value) {
                setState(() {
                  _useActualPanelPixels = value ?? true;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),

            CheckboxListTile(
              title: const Text('Show grid lines'),
              value: _showGrid,
              onChanged: (value) {
                setState(() {
                  _showGrid = value ?? true;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),

            CheckboxListTile(
              title: const Text('Show panel numbers'),
              value: _showPanelNumbers,
              onChanged: (value) {
                setState(() {
                  _showPanelNumbers = value ?? true;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),

            // Override option (only for browser rendering)
            if (!_useCloudService)
              CheckboxListTile(
                title: const Text('Override browser limits'),
                subtitle: const Text(
                  'Force generation beyond safe limits (use with caution)',
                ),
                value: _allowOverride,
                onChanged: (value) {
                  setState(() {
                    _allowOverride = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),

            const SizedBox(height: 16),

            // Preview Info
            if (validSurfaces.isNotEmpty) ...[
              const Text(
                'Preview',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Surfaces to generate: ${validSurfaces.length}'),
                    const SizedBox(height: 4),
                    ...validSurfaces.take(3).map((surface) {
                      final calc = surface.calculation!;
                      final led = surface.selectedLED!;
                      final width = calc.panelsWidth * led.wPixel;
                      final height =
                          (calc.fullPanelsHeight + calc.halfPanelsHeight) *
                          led.hPixel;
                      final mp = (width * height / 1000000).toStringAsFixed(1);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• ${led.name}: $width×${height}px (${mp}MP)',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }),
                    if (validSurfaces.length > 3)
                      Text(
                        '... and ${validSurfaces.length - 3} more',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isGenerating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isGenerating ? null : _generatePixelMaps,
          child: _isGenerating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Generate'),
        ),
      ],
    );
  }

  Future<void> _generatePixelMaps() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final validSurfaces = widget.surfaces
          .where((s) => s.calculation != null && s.selectedLED != null)
          .toList();

      final results = <String>[];

      for (int i = 0; i < validSurfaces.length; i++) {
        final surface = validSurfaces[i];

        try {
          if (_useCloudService) {
            // Use cloud service
            final result = await CloudPixelMapService.generateCloudPixelMap(
              surface,
              i,
              showGrid: _showGrid,
              showPanelNumbers: _showPanelNumbers,
            );

            if (result.isSuccess) {
              final filename =
                  'surface_${i + 1}_${result.width}x${result.height}_cloud.png';
              await _downloadFile(result.imageBytes!, filename);
              results.add(
                '✅ Surface ${i + 1}: ${result.width}×${result.height}px (${result.fileSizeMB}MB) - Cloud generated',
              );
            } else {
              results.add('❌ Surface ${i + 1}: ${result.errorMessage}');
            }
          } else {
            // Use browser service
            final calc = surface.calculation!;
            final led = surface.selectedLED!;
            final targetWidth = calc.panelsWidth * led.wPixel;
            final targetHeight =
                (calc.fullPanelsHeight + calc.halfPanelsHeight) * led.hPixel;

            final result =
                await PixelMapServiceBrowserSafe.createBrowserSafePixelMap(
                  surface,
                  i,
                  targetWidth: targetWidth,
                  targetHeight: targetHeight,
                  qualityPreset: _selectedQuality,
                  autoAdjust: true,
                  allowOverride: _allowOverride,
                  showGrid: _showGrid,
                  showPanelNumbers: _showPanelNumbers,
                  useActualPanelPixels: _useActualPanelPixels,
                );

            if (result.isSuccess) {
              final filename =
                  'surface_${i + 1}_${result.actualWidth}x${result.actualHeight}_browser.png';
              await _downloadFile(result.imageBytes!, filename);
              results.add(
                '✅ Surface ${i + 1}: ${result.actualWidth}×${result.actualHeight}px - Browser generated',
              );
            } else {
              results.add('❌ Surface ${i + 1}: ${result.errorMessage}');
            }
          }
        } catch (e) {
          results.add('❌ Surface ${i + 1}: Error - ${e.toString()}');
        }
      }

      // Show results
      if (context.mounted) {
        Navigator.of(context).pop();
        _showResultsDialog(results);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _showErrorDialog('Generation failed: ${e.toString()}');
      }
    }

    setState(() {
      _isGenerating = false;
    });
  }

  Future<void> _downloadFile(Uint8List bytes, String filename) async {
    // This would trigger browser download
    // For now, we'll just copy to clipboard or show success
  }

  void _showResultsDialog(List<String> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generation Results'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...results.map(
                (result) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(result),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
