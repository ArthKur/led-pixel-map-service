import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/led_service.dart';
import 'models/led_model.dart';
import 'models/surface_model.dart'; // Added Surface model import
import 'widgets/add_led_dialog_new.dart';
import 'widgets/led_list_dialog.dart';

// Add extension to Surface class to provide additional properties
extension SurfaceExtension on Surface {
  double? get area => width != null && height != null ? width! * height! : null;

  String? get resolution => selectedLED != null && calculation != null
      ? "${calculation!.pixelsWidth} × ${calculation!.pixelsHeight}"
      : null;

  int? get totalPanels => calculation != null
      ? calculation!.totalFullPanels + calculation!.totalHalfPanels
      : null;

  int? get fullPanels =>
      calculation?.totalFullPanels;

  int? get halfPanels =>
      calculation?.totalHalfPanels;

  double? get totalPowerAvg =>
      calculation?.avgPower;

  double? get totalPowerMax =>
      calculation?.maxPower;

  double? get totalWeight =>
      calculation?.totalWeight;
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
  LEDModel? _selectedLED;

  // Multi-surface support
  final List<Surface> _surfaces = [];
  int _activeSurfaceIndex = 0;

  // UI state for checkboxes
  bool _isStacked = false;
  bool _isRigged = false;

  @override
  void initState() {
    super.initState();
    _enableFullScreen();
    LEDService.addAbsenProducts(); // Ensure we have some sample products
    _addSurface(); // Add an initial surface
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

  // Surface management methods
  void _addSurface() {
    setState(() {
      final newSurface = Surface(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'New Surface',
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

  // Helper method for creating info rows in the Calculation Box
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  // Calculation helper methods
  String _calculatePanelsWide() {
    if (_surfaces.isEmpty ||
        _activeSurfaceIndex >= _surfaces.length ||
        _surfaces[_activeSurfaceIndex].width == null ||
        _surfaces[_activeSurfaceIndex].selectedLED == null) {
      return "N/A";
    }

    final width = _surfaces[_activeSurfaceIndex].width!;
    final ledWidth =
        _surfaces[_activeSurfaceIndex].selectedLED!.width /
        1000; // Convert to meters
    return (width / ledWidth).ceil().toString();
  }

  String _calculatePanelsHigh() {
    if (_surfaces.isEmpty ||
        _activeSurfaceIndex >= _surfaces.length ||
        _surfaces[_activeSurfaceIndex].height == null ||
        _surfaces[_activeSurfaceIndex].selectedLED == null) {
      return "N/A";
    }

    final height = _surfaces[_activeSurfaceIndex].height!;
    final ledHeight =
        _surfaces[_activeSurfaceIndex].selectedLED!.fullHeight /
        1000; // Convert to meters
    return (height / ledHeight).ceil().toString();
  }

  String _calculateTotalPanels() {
    if (_surfaces.isEmpty ||
        _activeSurfaceIndex >= _surfaces.length ||
        _surfaces[_activeSurfaceIndex].width == null ||
        _surfaces[_activeSurfaceIndex].height == null ||
        _surfaces[_activeSurfaceIndex].selectedLED == null) {
      return "N/A";
    }

    final panelsWide = int.tryParse(_calculatePanelsWide()) ?? 0;
    final panelsHigh = int.tryParse(_calculatePanelsHigh()) ?? 0;
    return (panelsWide * panelsHigh).toString();
  }

  String _calculatePowerAvg() {
    if (_surfaces.isEmpty ||
        _activeSurfaceIndex >= _surfaces.length ||
        _surfaces[_activeSurfaceIndex].selectedLED == null) {
      return "N/A";
    }

    final totalPanels = int.tryParse(_calculateTotalPanels()) ?? 0;
    final avgPower = _surfaces[_activeSurfaceIndex].selectedLED!.fullPanelAvgW;
    return (totalPanels * avgPower).toString();
  }

  String _calculatePowerMax() {
    if (_surfaces.isEmpty ||
        _activeSurfaceIndex >= _surfaces.length ||
        _surfaces[_activeSurfaceIndex].selectedLED == null) {
      return "N/A";
    }

    final totalPanels = int.tryParse(_calculateTotalPanels()) ?? 0;
    final maxPower = _surfaces[_activeSurfaceIndex].selectedLED!.fullPanelMaxW;
    return (totalPanels * maxPower).toString();
  }

  String _calculateWeight() {
    if (_surfaces.isEmpty ||
        _activeSurfaceIndex >= _surfaces.length ||
        _surfaces[_activeSurfaceIndex].selectedLED == null) {
      return "N/A";
    }

    final totalPanels = int.tryParse(_calculateTotalPanels()) ?? 0;
    final panelWeight =
        _surfaces[_activeSurfaceIndex].selectedLED!.fullPanelWeight;
    return (totalPanels * panelWeight).toString();
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
            child: Stack(
              children: [
                // Top left search and dimension inputs
                Positioned(
                  top: 20,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                    _selectedLED = led;
                                    if (_surfaces.isNotEmpty &&
                                        _activeSurfaceIndex <
                                            _surfaces.length) {
                                      _surfaces[_activeSurfaceIndex]
                                              .selectedLED =
                                          led;
                                      _updateActiveSurfaceFromControllers();
                                    }
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
                              decoration: const InputDecoration(
                                hintText: 'Width (m)',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(12),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _updateActiveSurfaceFromControllers();
                              },
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
                              decoration: const InputDecoration(
                                hintText: 'Height (m)',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(12),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _updateActiveSurfaceFromControllers();
                              },
                            ),
                          ),
                        ],
                      ),

                      // Surface name input and checkboxes
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[400]!),
                            ),
                            child: TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                hintText: 'Surface Name',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(12),
                              ),
                              onChanged: (value) {
                                _updateActiveSurfaceFromControllers();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Row(
                            children: [
                              Checkbox(
                                value: _isStacked,
                                onChanged: (value) {
                                  setState(() {
                                    _isStacked = value ?? false;
                                    _updateActiveSurfaceFromControllers();
                                  });
                                },
                              ),
                              const Text('Stacked'),
                              const SizedBox(width: 10),
                              Checkbox(
                                value: _isRigged,
                                onChanged: (value) {
                                  setState(() {
                                    _isRigged = value ?? false;
                                    _updateActiveSurfaceFromControllers();
                                  });
                                },
                              ),
                              const Text('Rigged'),
                            ],
                          ),
                        ],
                      ),
                      // LED Specifications Display - smaller and positioned under width/height boxes
                      if (_selectedLED != null)
                        Container(
                          width: 300,
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
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedLED!.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${_selectedLED!.manufacturer} - ${_selectedLED!.model}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedLED = null;
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
                              // Specifications in compact grid layout
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
                                        _buildSpecRow(
                                          'Brightness:',
                                          _selectedLED!.brightness > 0
                                              ? '${_selectedLED!.brightness}nit'
                                              : '',
                                        ),
                                        _buildSpecRow(
                                          'View Angle:',
                                          _selectedLED!.viewingAngle,
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
                                          'Depth:',
                                          _selectedLED!.depth > 0
                                              ? '${_selectedLED!.depth.toInt()}mm'
                                              : '',
                                        ),
                                        _buildSpecRow(
                                          'Weight:',
                                          _selectedLED!.fullPanelWeight > 0
                                              ? '${_selectedLED!.fullPanelWeight}Kg'
                                              : '',
                                        ),
                                        _buildSpecRow(
                                          'Frame:',
                                          _selectedLED!.touringFrame,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Second row - Environmental and Technical
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Environmental Column
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSectionHeader('Environmental'),
                                        _buildSpecRow(
                                          'IP Rating:',
                                          _selectedLED!.ipRating,
                                        ),
                                        _buildSpecRow(
                                          'Voltage:',
                                          _selectedLED!.operatingVoltage,
                                        ),
                                        _buildSpecRow(
                                          'Temp:',
                                          _selectedLED!.operatingTemp,
                                        ),
                                        _buildSpecRow(
                                          'Max Power:',
                                          _selectedLED!.fullPanelMaxW > 0
                                              ? '${_selectedLED!.fullPanelMaxW.toInt()}W'
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
                                          _selectedLED!.powerConnection,
                                        ),
                                        _buildSpecRow(
                                          'Data Conn:',
                                          _selectedLED!.dataConnection,
                                        ),
                                        _buildSpecRow(
                                          'Processing:',
                                          _selectedLED!.processing,
                                        ),
                                        _buildSpecRow(
                                          'Supplier:',
                                          _selectedLED!.supplier,
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
                // Surface Calculation Box
                Positioned(
                  bottom: 440,
                  left: 20,
                  child: Container(
                    width: 750,
                    height: 400,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.amber, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Surface Calculation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left column - Panel info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    calcInfoRow(
                                      'Dimensions',
                                      '${_widthController.text} m × ${_heightController.text} m',
                                    ),
                                    calcInfoRow(
                                      'Area',
                                      '${_surfaces.isNotEmpty ? (_surfaces[_activeSurfaceIndex].area?.toStringAsFixed(2) ?? "0.00") : "0.00"} m²',
                                    ),
                                    calcInfoRow(
                                      'Panels Wide × High',
                                      '${_surfaces.isNotEmpty && _surfaces[_activeSurfaceIndex].calculation != null ? _surfaces[_activeSurfaceIndex].calculation!.panelsWidth : 0} × ${_surfaces.isNotEmpty && _surfaces[_activeSurfaceIndex].calculation != null ? _surfaces[_activeSurfaceIndex].calculation!.panelsHeight : 0}',
                                    ),
                                    calcInfoRow(
                                      'Total Panels',
                                      '${_surfaces.isNotEmpty ? (_surfaces[_activeSurfaceIndex].totalPanels ?? 0) : 0}',
                                    ),
                                    calcInfoRow(
                                      'Panel Resolution',
                                      '${_selectedLED?.wPixel ?? 0} × ${_selectedLED?.hPixel ?? 0} px',
                                    ),
                                    calcInfoRow(
                                      'Total Resolution',
                                      '${_surfaces.isNotEmpty && _surfaces[_activeSurfaceIndex].calculation != null ? _surfaces[_activeSurfaceIndex].calculation!.pixelsWidth : 0} × ${_surfaces.isNotEmpty && _surfaces[_activeSurfaceIndex].calculation != null ? _surfaces[_activeSurfaceIndex].calculation!.pixelsHeight : 0} px',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              // Right column - Power and weight
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    calcInfoRow(
                                      'Max Power',
                                      '${_surfaces.isNotEmpty ? (_surfaces[_activeSurfaceIndex].totalPowerMax?.toStringAsFixed(2) ?? "0.00") : "0.00"} kW',
                                    ),
                                    calcInfoRow(
                                      'Avg Power',
                                      '${_surfaces.isNotEmpty ? (_surfaces[_activeSurfaceIndex].totalPowerAvg?.toStringAsFixed(2) ?? "0.00") : "0.00"} kW',
                                    ),
                                    calcInfoRow(
                                      'Panel Weight',
                                      '${_selectedLED?.fullPanelWeight ?? 0} kg',
                                    ),
                                    calcInfoRow(
                                      'Total Weight',
                                      '${_surfaces.isNotEmpty ? (_surfaces[_activeSurfaceIndex].totalWeight?.toStringAsFixed(1) ?? "0.0") : "0.0"} kg',
                                    ),
                                    calcInfoRow(
                                      'Pixel Pitch',
                                      '${_selectedLED?.pitch ?? 0} mm',
                                    ),
                                    calcInfoRow(
                                      'Total Pixels',
                                      '${_surfaces.isNotEmpty && _surfaces[_activeSurfaceIndex].calculation != null ? _surfaces[_activeSurfaceIndex].calculation!.totalPx : 0}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget for calculation box info rows
  Widget calcInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
