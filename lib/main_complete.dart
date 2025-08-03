import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'services/led_service.dart';
import 'models/led_model.dart';
import 'models/surface_model.dart';
import 'widgets/add_led_dialog_new.dart';
import 'widgets/led_list_dialog.dart';
import 'widgets/led_summary_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LEDService.init();
  runApp(const LEDCalculatorApp());
}

class LEDCalculatorApp extends StatelessWidget {
  const LEDCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LED Calculator 2.0',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[300],
      ),
      home: const FullScreenHomePage(),
    );
  }
}

class FullScreenHomePage extends StatefulWidget {
  const FullScreenHomePage({super.key});

  @override
  State<FullScreenHomePage> createState() => _FullScreenHomePageState();
}

class _FullScreenHomePageState extends State<FullScreenHomePage> {
  final _searchController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _nameController = TextEditingController();
  final _projectNameController = TextEditingController();
  final TransformationController _transformationController =
      TransformationController();

  List<LEDModel> _searchResults = [];
  bool _showSuggestions = false;
  LEDModel? _selectedLED;

  // Multi-surface support
  final List<Surface> _surfaces = [];
  int _activeSurfaceIndex = 0;

  // UI state
  bool _isStacked = false;
  bool _isRigged = false;

  @override
  void initState() {
    super.initState();
    _enableFullScreen();
    _projectNameController.text = 'Project Totals';

    // Initialize with first surface
    _addSurface();

    // Set up a periodic timer to check for LED updates
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _checkForLEDUpdates();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _nameController.dispose();
    _projectNameController.dispose();
    _transformationController.dispose();
    // Restore system UI when disposing
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _enableFullScreen() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _addSurface() {
    setState(() {
      final newSurface = Surface(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Surface ${_surfaces.length + 1}',
      );
      _surfaces.add(newSurface);
      _activeSurfaceIndex = _surfaces.length - 1;
      _updateControllersFromActiveSurface();
    });
  }

  void _checkForLEDUpdates() {
    // Implementation for checking LED updates
  }

  void _updateControllersFromActiveSurface() {
    if (_surfaces.isNotEmpty && _activeSurfaceIndex < _surfaces.length) {
      final surface = _surfaces[_activeSurfaceIndex];
      _nameController.text = surface.name;
      _widthController.text = surface.width?.toString() ?? '';
      _heightController.text = surface.height?.toString() ?? '';
      _selectedLED = surface.selectedLED;
      _isStacked = surface.isStacked;
      _isRigged = surface.isRigged;
    }
  }

  void _updateActiveSurfaceFromControllers() {
    if (_surfaces.isNotEmpty && _activeSurfaceIndex < _surfaces.length) {
      final surface = _surfaces[_activeSurfaceIndex];
      surface.name = _nameController.text;
      surface.width = double.tryParse(_widthController.text);
      surface.height = double.tryParse(_heightController.text);
      surface.selectedLED = _selectedLED;
      surface.isStacked = _isStacked;
      surface.isRigged = _isRigged;
      surface.updateCalculation();
    }
  }

  void _removeSurface(int index) {
    if (_surfaces.length <= 1) return;

    setState(() {
      _surfaces.removeAt(index);
      if (_activeSurfaceIndex >= _surfaces.length) {
        _activeSurfaceIndex = _surfaces.length - 1;
      }
      _updateControllersFromActiveSurface();
    });
  }

  Future<void> _refreshCalculations() async {
    for (final surface in _surfaces) {
      surface.updateCalculation();
    }
    setState(() {});
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _showSuggestions = true;
    });

    try {
      final results = await LEDService.searchLEDs(query);
      setState(() {
        _searchResults = results.take(10).toList();
      });
    } catch (e) {
      setState(() {
        _searchResults.clear();
      });
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          Container(
            height: 1,
            width: 40,
            color: Colors.orange,
            margin: const EdgeInsets.only(top: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: TextStyle(
                fontSize: 10,
                color: value.isNotEmpty ? Colors.black : Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          // Dismiss suggestions when tapping outside
          if (_showSuggestions) {
            setState(() {
              _showSuggestions = false;
            });
          }
          // Dismiss keyboard
          FocusScope.of(context).unfocus();
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[300],
          child: SafeArea(
            child: InteractiveViewer(
              transformationController: _transformationController,
              boundaryMargin: const EdgeInsets.all(50),
              minScale: 0.5,
              maxScale: 3.0,
              child: Stack(
                children: [
                  // Zoom Controls in top-right
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Column(
                      children: [
                        // Refresh calculations button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              await _refreshCalculations();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Calculations refreshed!'),
                                    duration: Duration(seconds: 1),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.refresh,
                                color: Colors.black,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Zoom in button
                        Material(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                          child: InkWell(
                            onTap: () {
                              final currentScale = _transformationController
                                  .value
                                  .getMaxScaleOnAxis();
                              final newScale = (currentScale * 1.2).clamp(
                                0.5,
                                3.0,
                              );
                              _transformationController.value =
                                  Matrix4.identity()..scale(newScale);
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: const Icon(Icons.zoom_in, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Zoom out button
                        Material(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                          child: InkWell(
                            onTap: () {
                              final currentScale = _transformationController
                                  .value
                                  .getMaxScaleOnAxis();
                              final newScale = (currentScale * 0.8).clamp(
                                0.5,
                                3.0,
                              );
                              _transformationController.value =
                                  Matrix4.identity()..scale(newScale);
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: const Icon(Icons.zoom_out, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Top left search and dimension inputs
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Container(
                      width: 340,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Surface tabs (only show if more than 1 surface)
                          if (_surfaces.length > 1)
                            Container(
                              height: 40,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount:
                                    _surfaces.length + 1, // +1 for add button
                                itemBuilder: (context, index) {
                                  if (index == _surfaces.length) {
                                    // Add surface button
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _addSurface,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Container(
                                            width: 40,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: Colors.green,
                                                width: 1,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.add,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  final surface = _surfaces[index];
                                  final isActive = index == _activeSurfaceIndex;

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _activeSurfaceIndex = index;
                                            _updateControllersFromActiveSurface();
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? Colors.blue
                                                : Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                surface.name,
                                                style: TextStyle(
                                                  color: isActive
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (_surfaces.length > 1)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 8,
                                                      ),
                                                  child: InkWell(
                                                    onTap: () =>
                                                        _removeSurface(index),
                                                    child: Icon(
                                                      Icons.close,
                                                      size: 16,
                                                      color: isActive
                                                          ? Colors.white
                                                          : Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          // Search field
                          TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search for LED products...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchResults.clear();
                                          _showSuggestions = false;
                                        });
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Surface name input
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Surface Name',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _nameController,
                                onChanged: (value) {
                                  _updateActiveSurfaceFromControllers();
                                  setState(() {});
                                },
                                decoration: InputDecoration(
                                  hintText: 'Enter surface name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Width and height inputs
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Width (m)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: _widthController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      onChanged: (value) {
                                        _updateActiveSurfaceFromControllers();
                                        setState(() {});
                                      },
                                      decoration: InputDecoration(
                                        hintText: '0.0',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Height (m)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: _heightController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      onChanged: (value) {
                                        _updateActiveSurfaceFromControllers();
                                        setState(() {});
                                      },
                                      decoration: InputDecoration(
                                        hintText: '0.0',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Stacked and Rigged checkboxes
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _isStacked,
                                      onChanged: (value) {
                                        setState(() {
                                          _isStacked = value ?? false;
                                          _updateActiveSurfaceFromControllers();
                                        });
                                      },
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    const Text(
                                      'Stacked',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _isRigged,
                                      onChanged: (value) {
                                        setState(() {
                                          _isRigged = value ?? false;
                                          _updateActiveSurfaceFromControllers();
                                        });
                                      },
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    const Text(
                                      'Rigged',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // LED Specifications (if LED is selected)
                  if (_selectedLED != null)
                    Positioned(
                      top: 20,
                      left: 380,
                      child: Container(
                        width: 320,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedLED!.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _selectedLED = null;
                                      _updateActiveSurfaceFromControllers();
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Show LED specifications using proper property names from LEDModel
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionHeader('Optical'),
                                      _buildSpecRow(
                                        'Pixel Pitch:',
                                        _selectedLED!.pitch > 0
                                            ? '${_selectedLED!.pitch}mm'
                                            : '',
                                      ),
                                      _buildSpecRow(
                                        'Resolution:',
                                        _selectedLED!.hPixel > 0 &&
                                                _selectedLED!.wPixel > 0
                                            ? '${_selectedLED!.hPixel}x${_selectedLED!.wPixel}'
                                            : '',
                                      ),
                                      _buildSpecRow(
                                        'Config:',
                                        _selectedLED!.ledConfiguration,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionHeader('Physical'),
                                      _buildSpecRow(
                                        'Height:',
                                        _selectedLED!.fullHeight > 0
                                            ? '${_selectedLED!.fullHeight.toInt()}mm'
                                            : '',
                                      ),
                                      _buildSpecRow(
                                        'Width:',
                                        _selectedLED!.width > 0
                                            ? '${_selectedLED!.width.toInt()}mm'
                                            : '',
                                      ),
                                      _buildSpecRow(
                                        'Weight:',
                                        _selectedLED!.fullPanelWeight > 0
                                            ? '${_selectedLED!.fullPanelWeight}kg'
                                            : '',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  // LED Summary Widget (bottom left) - show when calculations are available
                  if (_surfaces.isNotEmpty &&
                      _surfaces.any(
                        (s) => s.isComplete && s.calculation != null,
                      ))
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: LEDSummaryWidget(
                          calculation: _surfaces
                              .firstWhere(
                                (s) => s.isComplete && s.calculation != null,
                              )
                              .calculation!,
                          isStacked: _isStacked,
                          isRigged: _isRigged,
                        ),
                      ),
                    ),
                  // Search suggestions dropdown overlay
                  if (_showSuggestions)
                    Positioned(
                      top: 95,
                      left: 36,
                      child: Container(
                        width: 308,
                        constraints: const BoxConstraints(maxHeight: 150),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final led = _searchResults[index];
                            return ListTile(
                              title: Text(
                                led.name,
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                '${led.manufacturer} - ${led.model}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedLED = led;
                                  _showSuggestions = false;
                                  _searchController.text = led.name;
                                  _updateActiveSurfaceFromControllers();
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  // Bottom left buttons
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Generate PixelMaps functionality coming soon!',
                                ),
                                backgroundColor: Colors.amber,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Generate PixelMaps',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Generate Obj functionality coming soon!',
                                ),
                                backgroundColor: Colors.amber,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Generate Obj',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Generate Paperwork functionality coming soon!',
                                ),
                                backgroundColor: Colors.amber,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Generate Paperwork',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bottom right buttons
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return const LEDListDialog();
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'LED EDIT',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return const AddLEDDialog();
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'ADD NEW LED',
                            style: TextStyle(
                              fontSize: 14,
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
          ),
        ),
      ),
    );
  }
}
