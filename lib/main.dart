import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'services/led_service.dart';
import 'models/led_model.dart';
import 'models/surface_model.dart';
import 'widgets/add_led_dialog_new.dart';
import 'widgets/led_list_dialog.dart';

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

  List<LEDModel> _searchResults = [];
  bool _showSuggestions = false;

  // Multi-surface support
  List<Surface> _surfaces = [];
  int _activeSurfaceIndex = 0;

  // UI state for checkboxes
  bool _isStacked = false;
  bool _isRigged = false;

  // Helper getter for active surface LED
  LEDModel? get _activeLED =>
      _surfaces.isNotEmpty && _activeSurfaceIndex < _surfaces.length
      ? _surfaces[_activeSurfaceIndex].selectedLED
      : null;

  @override
  void initState() {
    super.initState();
    _enableFullScreen();

    // Add Absen LED products
    LEDService.addAbsenProducts();

    // Initialize with first surface
    _addSurface();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _nameController.dispose();
    // Restore system UI when disposing
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _addSurface() {
    setState(() {
      final newSurface = Surface(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'NAME',
      );
      _surfaces.add(newSurface);
      _activeSurfaceIndex = _surfaces.length - 1;
      _updateControllersFromActiveSurface();
    });
  }

  void _updateControllersFromActiveSurface() {
    if (_surfaces.isNotEmpty && _activeSurfaceIndex < _surfaces.length) {
      final surface = _surfaces[_activeSurfaceIndex];
      _nameController.text = surface.name;
      _widthController.text = surface.width?.toString() ?? '';
      _heightController.text = surface.height?.toString() ?? '';
      _searchController.text = surface.selectedLED?.name ?? '';
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
            width: double.infinity,
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
            child: Stack(
              children: [
                // Top left search and dimension inputs
                Positioned(
                  top: 20,
                  left: 20, // moved back to top left corner
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Surface tabs (only show if more than 1 surface)
                      if (_surfaces.length > 1)
                        Container(
                          height: 40,
                          width: 300,
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
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        width: 40,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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
                                        borderRadius: BorderRadius.circular(6),
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
                                              padding: const EdgeInsets.only(
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

                      // Search window
                      Container(
                        width: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) async {
                            if (value.isNotEmpty) {
                              final results = await LEDService.searchLEDs(
                                value,
                              );
                              setState(() {
                                _searchResults = results
                                    .take(5)
                                    .toList(); // Limit to 5 suggestions
                                _showSuggestions = results.isNotEmpty;
                              });
                            } else {
                              setState(() {
                                _searchResults = [];
                                _showSuggestions = false;
                              });
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search for LED product...',
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                      ),
                      // Search suggestions dropdown
                      if (_showSuggestions)
                        Container(
                          width: 300,
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[400]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
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
                              return InkWell(
                                onTap: () {
                                  _searchController.text = led.name;
                                  setState(() {
                                    _showSuggestions = false;
                                    _surfaces[_activeSurfaceIndex].selectedLED =
                                        led;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: index < _searchResults.length - 1
                                            ? Colors.grey[200]!
                                            : Colors.transparent,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        led.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '${led.manufacturer} - ${led.model}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (led.pitch > 0)
                                        Text(
                                          'Pitch: ${led.pitch}mm',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 11,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 15),
                      // Width and Height inputs
                      Row(
                        children: [
                          Container(
                            width: 145,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[400]!),
                            ),
                            child: TextField(
                              controller: _widthController,
                              onChanged: (value) {
                                _updateActiveSurfaceFromControllers();
                                setState(() {});
                              },
                              decoration: const InputDecoration(
                                hintText: 'Width (m)',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(12),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 145,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[400]!),
                            ),
                            child: TextField(
                              controller: _heightController,
                              onChanged: (value) {
                                _updateActiveSurfaceFromControllers();
                                setState(() {});
                              },
                              decoration: const InputDecoration(
                                hintText: 'Height (m)',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(12),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // LED Specifications Display - wider and all columns in one row
                      if (_activeLED != null)
                        Container(
                          width: 800,
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[400]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with LED name
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _activeLED!.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _surfaces[_activeSurfaceIndex]
                                                .selectedLED =
                                            null;
                                        _searchController.clear();
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.grey,
                                      size: 16,
                                    ),
                                    tooltip: 'Clear selection',
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // All specifications in a single row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Optical Column
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSectionHeader('Optical'),
                                        _buildSpecRow(
                                          'Pixel Pitch:',
                                          _activeLED!.pitch > 0
                                              ? '${_activeLED!.pitch}mm'
                                              : '',
                                        ),
                                        _buildSpecRow(
                                          'Resolution:',
                                          _activeLED!.hPixel > 0 &&
                                                  _activeLED!.wPixel > 0
                                              ? '${_activeLED!.hPixel}x${_activeLED!.wPixel}'
                                              : '',
                                        ),
                                        _buildSpecRow(
                                          'Config:',
                                          _activeLED!.ledConfiguration,
                                        ),
                                        _buildSpecRow(
                                          'Brightness:',
                                          _activeLED!.brightness > 0
                                              ? '${_activeLED!.brightness}nit'
                                              : '',
                                        ),
                                        _buildSpecRow(
                                          'View Angle:',
                                          _activeLED!.viewingAngle,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Physical Column
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSectionHeader('Physical'),
                                        _buildSpecRow(
                                          'Height:',
                                          _activeLED!.fullHeight > 0
                                              ? '${_activeLED!.fullHeight.toInt()}mm'
                                              : '',
                                        ),
                                        _buildSpecRow(
                                          'Width:',
                                          _activeLED!.width > 0
                                              ? '${_activeLED!.width.toInt()}mm'
                                              : '',
                                        ),
                                        _buildSpecRow(
                                          'Depth:',
                                          _activeLED!.depth > 0
                                              ? '${_activeLED!.depth.toInt()}mm'
                                              : '',
                                        ),
                                        _buildSpecRow(
                                          'Weight:',
                                          _activeLED!.fullPanelWeight > 0
                                              ? '${_activeLED!.fullPanelWeight}Kg'
                                              : '',
                                        ),
                                        _buildSpecRow(
                                          'Frame:',
                                          _activeLED!.touringFrame,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Environmental Column
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSectionHeader('Environmental'),
                                        _buildSpecRow(
                                          'IP Rating:',
                                          _activeLED!.ipRating,
                                        ),
                                        _buildSpecRow(
                                          'Voltage:',
                                          _activeLED!.operatingVoltage,
                                        ),
                                        _buildSpecRow(
                                          'Temp:',
                                          _activeLED!.operatingTemp,
                                        ),
                                        _buildSpecRow(
                                          'Max Power:',
                                          _activeLED!.fullPanelMaxW > 0
                                              ? '${_activeLED!.fullPanelMaxW.toInt()}W'
                                              : '',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Technical Column
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSectionHeader('Technical'),
                                        _buildSpecRow(
                                          'Power Conn:',
                                          _activeLED!.powerConnection,
                                        ),
                                        _buildSpecRow(
                                          'Data Conn:',
                                          _activeLED!.dataConnection,
                                        ),
                                        _buildSpecRow(
                                          'Processing:',
                                          _activeLED!.processing,
                                        ),
                                        _buildSpecRow(
                                          'Supplier:',
                                          _activeLED!.supplier,
                                        ),
                                      ],
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
                // Second surface box - name input for all surfaces
                Positioned(
                  top: 20,
                  left:
                      340, // 20 (left margin) + 300 (width of first box) + 20 (spacing)
                  child: Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: TextField(
                      controller: _nameController,
                      onChanged: (value) {
                        _updateActiveSurfaceFromControllers();
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                        hintText: 'Surface name...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ),
                // Stacked and Rigged checkboxes - positioned under name input
                Positioned(
                  top: 88, // 20 (top) + 48 (TextField height) + 20 (spacing)
                  left: 340, // Same left position as name input box
                  child: Container(
                    width: 300, // Same width as second surface box
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center, // Center the checkboxes
                      children: [
                        // Stacked checkbox
                        Row(
                          children: [
                            Transform.scale(
                              scale: 0.7, // 30% smaller
                              child: Checkbox(
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
                            ),
                            const Text(
                              'Stacked',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Rigged checkbox
                        Row(
                          children: [
                            Transform.scale(
                              scale: 0.7, // 30% smaller
                              child: Checkbox(
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
                            ),
                            const Text(
                              'Rigged',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Add Surface button - moved outside to the right
                Positioned(
                  top: 20,
                  left: 660, // 20 + 300 + 20 + 300 + 20 (positioning to the right of second box)
                  child: ElevatedButton.icon(
                    onPressed: _addSurface,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Surface'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
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
                // Bottom right buttons (now side by side in amber)
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
    );
  }
}
