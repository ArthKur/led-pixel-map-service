import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/led_service.dart';
import 'services/led_calculation_service.dart';
import 'models/led_model.dart';
import 'models/surface_model.dart';
import 'widgets/add_led_dialog_new.dart';
import 'widgets/led_list_dialog.dart';
import 'widgets/led_summary_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LEDService.init();

  // Add Absen LED products
  await LEDService.addAbsenProducts();

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
  final _projectTotalsController = TextEditingController();
  final _projectNameController = TextEditingController();
  
  // Project information fields
  final _easyJobNumberController = TextEditingController();
  final _projectNameInfoController = TextEditingController();
  final _projectManagerController = TextEditingController();
  final _projectEngineerController = TextEditingController();

  // Zoom functionality
  final TransformationController _transformationController =
      TransformationController();
  double _currentZoom = 1.0;

  List<LEDModel> _searchResults = [];
  bool _showSuggestions = false;
  LEDModel? _selectedLED;
  LEDCalculationResult? _calculationResult;

  // Multi-surface management
  final List<Surface> _surfaces = [];
  int _activeSurfaceIndex = 0;

  // Stacked and Rigged selection state
  bool _isStacked = true; // Default to Stacked selected
  bool _isRigged = false;

  @override
  void initState() {
    super.initState();
    _enableFullScreen();
    _projectNameController.text = 'Project Totals'; // Set default project name
    
    // Initialize project information fields with default values
    _easyJobNumberController.text = 'CT25-0000';
    _projectNameInfoController.text = '2 Cents GCC Tour 2025';
    _projectManagerController.text = 'Dan Hughes';
    _projectEngineerController.text = 'Carlos Aguilar';

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
    _projectTotalsController.dispose();
    _projectNameController.dispose();
    _easyJobNumberController.dispose();
    _projectNameInfoController.dispose();
    _projectManagerController.dispose();
    _projectEngineerController.dispose();
    _transformationController.dispose();
    // Restore system UI when disposing
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // Zoom functionality methods
  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom * 1.2).clamp(0.5, 3.0);
      _transformationController.value = Matrix4.identity()..scale(_currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom / 1.2).clamp(0.5, 3.0);
      _transformationController.value = Matrix4.identity()..scale(_currentZoom);
    });
  }

  void _resetZoom() {
    setState(() {
      _currentZoom = 1.0;
      _transformationController.value = Matrix4.identity();
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

  String _generateNextName(String currentName) {
    // Check if the name already ends with a number
    RegExp regex = RegExp(r'^(.+?)(\s*)(\d+)$');
    Match? match = regex.firstMatch(currentName);

    if (match != null) {
      // Name already has a number, increment it
      String baseName = match.group(1)!;
      String spacing = match.group(2)!;
      int currentNumber = int.parse(match.group(3)!);
      return '$baseName$spacing${currentNumber + 1}';
    } else {
      // Name doesn't have a number, add " 2"
      return '$currentName 2';
    }
  }

  void _addSurface() {
    if (_selectedLED != null &&
        _widthController.text.isNotEmpty &&
        _heightController.text.isNotEmpty &&
        _nameController.text.isNotEmpty &&
        (_isStacked || _isRigged)) {
      // Require one checkbox to be selected
      final double? width = double.tryParse(_widthController.text);
      final double? height = double.tryParse(_heightController.text);

      if (width != null && height != null && width > 0 && height > 0) {
        final surface = Surface(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text,
          selectedLED: _selectedLED,
          width: width,
          height: height,
          isStacked: _isStacked,
          isRigged: _isRigged,
        );
        surface.updateCalculation();

        setState(() {
          _surfaces.add(surface);
          // Stay on the current calculation tab instead of switching to new surface
          // _activeSurfaceIndex = _surfaces.length - 1; // Remove this auto-switch

          // Keep all inputs but auto-increment the name
          String currentName = _nameController.text;
          String newName = _generateNextName(currentName);
          _nameController.text = newName;

          // Keep width, height, LED selection, and checkbox states
          // Keep _selectedLED, _widthController.text, _heightController.text
          // Keep _isStacked and _isRigged states
          // Keep _searchController.text for easy reuse
          _showSuggestions = false;
          // Keep _calculationResult so Current tab stays visible
        });
      }
    } else {
      String message;
      if (!(_isStacked || _isRigged)) {
        message = 'Please select either Stacked or Rigged option';
      } else {
        message = 'Please fill in all fields (LED, Width, Height, Name)';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void _removeSurface(int index) {
    setState(() {
      _surfaces.removeAt(index);
      if (_activeSurfaceIndex >= _surfaces.length && _surfaces.isNotEmpty) {
        _activeSurfaceIndex = _surfaces.length - 1;
      } else if (_surfaces.isEmpty) {
        _activeSurfaceIndex = 0;
      }
    });
  }

  LEDCalculationResult? _getActiveCalculation() {
    if (_activeSurfaceIndex == -1) {
      return _calculationResult; // Current calculation
    } else if (_activeSurfaceIndex >= 0 &&
        _activeSurfaceIndex < _surfaces.length) {
      return _surfaces[_activeSurfaceIndex].calculation; // Surface calculation
    }
    return null;
  }

  // Update checkbox states when switching tabs
  void _updateCheckboxStates() {
    if (_activeSurfaceIndex >= 0 && _activeSurfaceIndex < _surfaces.length) {
      // Surface tab is active - use surface's stored states
      final surface = _surfaces[_activeSurfaceIndex];
      _isStacked = surface.isStacked;
      _isRigged = surface.isRigged;
    } else {
      // Current calculation tab is active - keep current states
      // (they are already set from the checkboxes)
    }
  }

  void _calculateLEDSummary() {
    if (_selectedLED != null &&
        _widthController.text.isNotEmpty &&
        _heightController.text.isNotEmpty) {
      final double? width = double.tryParse(_widthController.text);
      final double? height = double.tryParse(_heightController.text);

      if (width != null && height != null && width > 0 && height > 0) {
        setState(() {
          _calculationResult = LEDCalculationService.calculateLEDInstallation(
            _selectedLED!,
            width,
            height,
          );
          // Only switch to current tab if we're not already on a surface tab
          // This prevents automatic tab switching when typing in inputs
          if (_activeSurfaceIndex >= 0) {
            // User is on a surface tab, don't force switch to current
          } else {
            // User is on current tab or no tab, keep current tab active
            _activeSurfaceIndex = -1;
          }
        });
      }
    } else {
      setState(() {
        _calculationResult = null;
      });
    }
  }

  // Auto-update calculations when LED data changes
  Future<void> _refreshCalculations() async {
    if (_selectedLED != null) {
      // Reload the selected LED from database to get latest data
      final updatedLED = await LEDService.getLEDByName(_selectedLED!.name);
      if (updatedLED != null) {
        setState(() {
          _selectedLED = updatedLED;
        });
        _calculateLEDSummary();
      }
    }

    // Update all surfaces with their latest LED data
    for (int i = 0; i < _surfaces.length; i++) {
      final surface = _surfaces[i];
      if (surface.selectedLED != null) {
        final updatedLED = await LEDService.getLEDByName(
          surface.selectedLED!.name,
        );
        if (updatedLED != null) {
          setState(() {
            surface.selectedLED = updatedLED;
            surface.updateCalculation();
          });
        }
      }
    }
  }

  // Check for LED updates periodically
  Future<void> _checkForLEDUpdates() async {
    // This method can be enhanced with more sophisticated change detection
    // For now, it's called periodically to refresh calculations
    if (_selectedLED != null || _surfaces.isNotEmpty) {
      await _refreshCalculations();
    }
  }

  Widget _buildSpecRow(String label, String value) {
    return Container(
      height: 14, // Fixed height for each row
      margin: const EdgeInsets.only(bottom: 1),
      child: Row(
        children: [
          // Fixed width label container
          SizedBox(
            width: 140, // Increased width for longer labels (was 120)
            child: Text(
              '$label :',
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
            ),
          ),
          // Fixed width value container, right-aligned
          Expanded(
            child: Container(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
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
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // Dismiss suggestions when tapping outside
          if (_showSuggestions) {
            setState(() {
              _showSuggestions = false;
            });
          }
          // Only dismiss keyboard when tapping on the background, not on input fields
          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            FocusScope.of(context).unfocus();
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[300],
          child: SafeArea(
            child: InteractiveViewer(
              transformationController: _transformationController,
              panEnabled: true,
              scaleEnabled: true,
              minScale: 0.5,
              maxScale: 3.0,
              child: Stack(
                children: [
                  // Project Information Fields in top-right corner
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      width: 250,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProjectInfoField('Easy Job number', _easyJobNumberController, Colors.grey.shade600),
                          const SizedBox(height: 8),
                          _buildProjectInfoField('Project Name', _projectNameInfoController, Colors.black),
                          const SizedBox(height: 8),
                          _buildProjectInfoField('Project Manager', _projectManagerController, Colors.black),
                          const SizedBox(height: 8),
                          _buildProjectInfoField('Project Engineer', _projectEngineerController, Colors.black),
                        ],
                      ),
                    ),
                  ),
                  // Refresh and Zoom Controls moved down vertically
                  Positioned(
                    top: 160,
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
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.transparent),
                              ),
                              child: const Icon(
                                Icons.refresh,
                                size: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Zoom controls
                        Row(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _zoomIn,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.transparent),
                                  ),
                                  child: const Icon(
                                    Icons.zoom_in,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _zoomOut,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.transparent),
                                  ),
                                  child: const Icon(
                                    Icons.zoom_out,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _resetZoom,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.transparent),
                                      ),
                                      child: const Icon(
                                        Icons.center_focus_strong,
                                        size: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Top left search and dimension inputs
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search window with Add Surface button - aligned horizontally
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Search box
                                GestureDetector(
                                  onTap: () {
                                    // Prevent parent gesture detector from interfering
                                  },
                                  child: Container(
                                    width:
                                        320, // Adjusted width since button is closer
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[400]!,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: (value) async {
                                        if (value.isNotEmpty) {
                                          final results =
                                              await LEDService.searchLEDs(
                                                value,
                                              );
                                          setState(() {
                                            _searchResults = results
                                                .take(5)
                                                .toList(); // Limit to 5 suggestions
                                            _showSuggestions =
                                                results.isNotEmpty;
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
                                ),
                                const SizedBox(height: 8),
                                // Width and Height inputs under search box
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        // Prevent parent gesture detector from interfering
                                      },
                                      child: Container(
                                        width:
                                            155, // Half of 320px minus spacing
                                        height: 48, // Match other input heights
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey[400]!,
                                          ),
                                        ),
                                        child: TextField(
                                          controller: _widthController,
                                          onChanged: (value) =>
                                              _calculateLEDSummary(),
                                          decoration: const InputDecoration(
                                            hintText: 'Width (m)',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.all(12),
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: () {
                                        // Prevent parent gesture detector from interfering
                                      },
                                      child: Container(
                                        width:
                                            155, // Half of 320px minus spacing
                                        height: 48, // Match other input heights
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey[400]!,
                                          ),
                                        ),
                                        child: TextField(
                                          controller: _heightController,
                                          onChanged: (value) =>
                                              _calculateLEDSummary(),
                                          decoration: const InputDecoration(
                                            hintText: 'Height (m)',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.all(12),
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(
                              width: 20,
                            ), // Reduced spacing to move Add Surface button closer
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 120, // Match NAME input width
                                  height: 48, // Match search box height
                                  child: ElevatedButton(
                                    onPressed: _addSurface,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Add Surface',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Row with NAME input and checkboxes
                                Row(
                                  children: [
                                    // NAME input
                                    GestureDetector(
                                      onTap: () {
                                        // Prevent the parent GestureDetector from stealing focus
                                      },
                                      child: Container(
                                        width: 120,
                                        height:
                                            48, // Match button height for consistency
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey[400]!,
                                          ),
                                        ),
                                        child: TextField(
                                          controller: _nameController,
                                          decoration: const InputDecoration(
                                            hintText: 'NAME',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.all(12),
                                          ),
                                          style: const TextStyle(fontSize: 12),
                                          onSubmitted: (_) =>
                                              _addSurface(), // Add Enter key functionality
                                          // Ensure the field can receive focus easily
                                          autofocus: false,
                                          enableInteractiveSelection: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Stacked and Rigged checkboxes
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Stacked checkbox
                                        SizedBox(
                                          height: 22,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Transform.scale(
                                                scale: 0.8,
                                                child: Checkbox(
                                                  value: _isStacked,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      if (value == true) {
                                                        _isStacked = true;
                                                        _isRigged =
                                                            false; // Uncheck rigged when stacked is selected
                                                      } else {
                                                        _isStacked = false;
                                                      }
                                                    });
                                                  },
                                                  activeColor: Colors.orange,
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                              ),
                                              const Text(
                                                'Stacked',
                                                style: TextStyle(fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Rigged checkbox
                                        SizedBox(
                                          height: 22,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Transform.scale(
                                                scale: 0.8,
                                                child: Checkbox(
                                                  value: _isRigged,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      if (value == true) {
                                                        _isRigged = true;
                                                        _isStacked =
                                                            false; // Uncheck stacked when rigged is selected
                                                      } else {
                                                        _isRigged = false;
                                                      }
                                                    });
                                                  },
                                                  activeColor: Colors.orange,
                                                  materialTapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                              ),
                                              const Text(
                                                'Rigged',
                                                style: TextStyle(fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // LED Specifications Display - progressive expansion: 460px → 575px → 720px → 800px → 900px for maximum data density
                        if (_selectedLED != null)
                          Container(
                            width:
                                900, // Extended by additional 100px for optimal information presentation
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
                                // Header with LED name only
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedLED!.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedLED = null;
                                          _searchController.clear();
                                          _calculationResult = null;
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
                                const SizedBox(height: 4),
                                // Specifications in expanded 4-column layout with 900px width optimization and column-wise selectability
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Optical Performance Column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Selectable header and content with aligned answers
                                          SelectableText.rich(
                                            TextSpan(
                                              children: [
                                                const TextSpan(
                                                  text: 'Optical',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Orange underline
                                          Container(
                                            height: 2,
                                            width: double.infinity,
                                            color: Colors.orange,
                                            margin: const EdgeInsets.only(
                                              top: 2,
                                              bottom: 6,
                                            ),
                                          ),
                                          // Specification data with aligned answers using structured layout
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildSpecRow(
                                                'Pixel Pitch',
                                                _selectedLED!.pitch > 0
                                                    ? '${_selectedLED!.pitch}'
                                                    : '-',
                                              ),
                                              _buildSpecRow(
                                                'Panel Resolution',
                                                _selectedLED!.hPixel > 0 &&
                                                        _selectedLED!.wPixel > 0
                                                    ? '${_selectedLED!.hPixel} x ${_selectedLED!.wPixel}'
                                                    : '-',
                                              ),
                                              _buildSpecRow(
                                                'LED Configuration',
                                                _selectedLED!
                                                        .ledConfiguration
                                                        .isNotEmpty
                                                    ? _selectedLED!
                                                          .ledConfiguration
                                                    : '-',
                                              ),
                                              _buildSpecRow(
                                                'Brightness',
                                                _selectedLED!.brightness > 0
                                                    ? '${_selectedLED!.brightness} nit'
                                                    : '-',
                                              ),
                                              _buildSpecRow(
                                                'Viewing Angle',
                                                _selectedLED!
                                                        .viewingAngle
                                                        .isNotEmpty
                                                    ? _selectedLED!.viewingAngle
                                                    : '-',
                                              ),
                                              _buildSpecRow(
                                                'Refresh Rate',
                                                _selectedLED!.refreshRate > 0
                                                    ? '≤${_selectedLED!.refreshRate}Hz'
                                                    : '-',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    // Physical Dimensions & Build Column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Selectable header and content with aligned answers
                                          SelectableText.rich(
                                            TextSpan(
                                              children: [
                                                const TextSpan(
                                                  text: 'Physical',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Orange underline
                                          Container(
                                            height: 2,
                                            width: double.infinity,
                                            color: Colors.orange,
                                            margin: const EdgeInsets.only(
                                              top: 2,
                                              bottom: 6,
                                            ),
                                          ),
                                          // Specification data with aligned answers using structured layout
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildSpecRow(
                                                'Panel Height',
                                                _selectedLED!.fullHeight > 0
                                                    ? '${_selectedLED!.fullHeight.toInt()}mm'
                                                    : '-',
                                              ),
                                              _buildSpecRow(
                                                'Panel Width',
                                                _selectedLED!.width > 0
                                                    ? '${_selectedLED!.width.toInt()}mm'
                                                    : '-',
                                              ),
                                              _buildSpecRow(
                                                'Panel Depth',
                                                _selectedLED!.depth > 0
                                                    ? '${_selectedLED!.depth.toInt()}mm'
                                                    : '-',
                                              ),
                                              _buildSpecRow(
                                                'Panel Weight',
                                                _selectedLED!.fullPanelWeight >
                                                        0
                                                    ? '${_selectedLED!.fullPanelWeight}kg'
                                                    : '-',
                                              ),
                                              _buildSpecRow(
                                                'Touring Frame',
                                                _selectedLED!
                                                        .touringFrame
                                                        .isNotEmpty
                                                    ? _selectedLED!.touringFrame
                                                    : '',
                                              ),
                                              _buildSpecRow(
                                                'Curve Capability',
                                                _selectedLED!
                                                        .curveCapability
                                                        .isNotEmpty
                                                    ? _selectedLED!
                                                          .curveCapability
                                                    : '',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    // Power & Environmental Column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Selectable header and content with aligned answers
                                          SelectableText.rich(
                                            TextSpan(
                                              children: [
                                                const TextSpan(
                                                  text: 'Environmental',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Orange underline
                                          Container(
                                            height: 2,
                                            width: double.infinity,
                                            color: Colors.orange,
                                            margin: const EdgeInsets.only(
                                              top: 2,
                                              bottom: 6,
                                            ),
                                          ),
                                          // Specification data with aligned answers using structured layout
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildSpecRow(
                                                'IP Rating',
                                                _selectedLED!
                                                        .ipRating
                                                        .isNotEmpty
                                                    ? _selectedLED!.ipRating
                                                    : '',
                                              ),
                                              _buildSpecRow(
                                                'Operating Voltage',
                                                _selectedLED!
                                                        .operatingVoltage
                                                        .isNotEmpty
                                                    ? _selectedLED!
                                                          .operatingVoltage
                                                    : '',
                                              ),
                                              _buildSpecRow(
                                                'Operating Temperature',
                                                _selectedLED!
                                                        .operatingTemp
                                                        .isNotEmpty
                                                    ? _selectedLED!
                                                          .operatingTemp
                                                    : '',
                                              ),
                                              _buildSpecRow(
                                                'Max Power Consumption',
                                                _selectedLED!.fullPanelMaxW > 0
                                                    ? '${_selectedLED!.fullPanelMaxW.toInt()}'
                                                    : '',
                                              ),
                                              _buildSpecRow(
                                                'Avg Power Consumption',
                                                _selectedLED!.fullPanelAvgW > 0
                                                    ? '${_selectedLED!.fullPanelAvgW.toInt()}'
                                                    : '',
                                              ),
                                              _buildSpecRow(
                                                'Verification',
                                                _selectedLED!
                                                        .verification
                                                        .isNotEmpty
                                                    ? _selectedLED!.verification
                                                    : '',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    // Connectivity & Support Column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Selectable header and content with aligned answers
                                          SelectableText.rich(
                                            TextSpan(
                                              children: [
                                                const TextSpan(
                                                  text: 'Technical',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Orange underline
                                          Container(
                                            height: 2,
                                            width: double.infinity,
                                            color: Colors.orange,
                                            margin: const EdgeInsets.only(
                                              top: 2,
                                              bottom: 6,
                                            ),
                                          ),
                                          // Specification data with aligned answers using structured layout
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildSpecRow(
                                                'Power Connection',
                                                _selectedLED!
                                                        .powerConnection
                                                        .isNotEmpty
                                                    ? _selectedLED!
                                                          .powerConnection
                                                    : '',
                                              ),
                                              _buildSpecRow(
                                                'Data Connection',
                                                _selectedLED!
                                                        .dataConnection
                                                        .isNotEmpty
                                                    ? _selectedLED!
                                                          .dataConnection
                                                    : '',
                                              ),
                                              _buildSpecRow(
                                                'Processing',
                                                _selectedLED!
                                                        .processing
                                                        .isNotEmpty
                                                    ? _selectedLED!.processing
                                                    : '',
                                              ),
                                              _buildSpecRow(
                                                'Panels per Port',
                                                _selectedLED!.panelsPerPort > 0
                                                    ? '${_selectedLED!.panelsPerPort}'
                                                    : '',
                                              ),
                                              _buildSpecRow(
                                                'Panels per 16A (230V)',
                                                _selectedLED!.panelsPer16A > 0
                                                    ? '${_selectedLED!.panelsPer16A}'
                                                    : '',
                                              ),
                                              _buildSpecRow('', ''),
                                            ],
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
                  // Search suggestions dropdown overlay - positioned absolutely to not affect layout
                  if (_showSuggestions)
                    Positioned(
                      top: 68, // Position just below the search box (20 + 48)
                      left: 20,
                      child: Container(
                        width: 320, // Match the search box width
                        constraints: const BoxConstraints(maxHeight: 150),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[400]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
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
                                });
                                _calculateLEDSummary();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: index < _searchResults.length - 1
                                          ? Colors.grey[200]!
                                          : Colors.transparent,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  led.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  // LED Calculations horizontal section with tabs - positioned under LED details and above bottom buttons
                  if (_calculationResult != null || _surfaces.isNotEmpty)
                    Positioned(
                      bottom: 70, // Extended by 10px (was 80)
                      left: 20,
                      width: 900, // Match LED data window width
                      top: 330, // Restored to original position
                      child: Container(
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
                          children: [
                            // Tab headers if there are surfaces
                            if (_surfaces.isNotEmpty)
                              Container(
                                height: 45, // Restored to original height
                                decoration: BoxDecoration(
                                  color: Colors
                                      .grey[200], // Light grey background to match Project Totals
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Current calculation tab (if exists) - non-interactive
                                    if (_calculationResult != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _activeSurfaceIndex == -1
                                              ? Colors.white
                                              : Colors.transparent,
                                          borderRadius:
                                              const BorderRadius.only(
                                                topLeft: Radius.circular(8),
                                                topRight: Radius.circular(8),
                                              ),
                                          border: _activeSurfaceIndex == -1
                                              ? Border.all(
                                                  color: Colors.grey[400]!,
                                                )
                                              : null,
                                        ),
                                        // Empty container - no text, no interaction
                                      ),
                                    // Surface tabs
                                    Expanded(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: _surfaces.asMap().entries.map((
                                            entry,
                                          ) {
                                            int index = entry.key;
                                            Surface surface = entry.value;
                                            bool isActive =
                                                index == _activeSurfaceIndex;

                                            return GestureDetector(
                                              onTap: () {
                                                if (_activeSurfaceIndex !=
                                                    index) {
                                                  setState(() {
                                                    _activeSurfaceIndex = index;
                                                    _updateCheckboxStates();
                                                  });
                                                }
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isActive
                                                      ? Colors.white
                                                      : Colors.transparent,
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(8),
                                                        topRight:
                                                            Radius.circular(8),
                                                      ),
                                                  border: isActive
                                                      ? Border.all(
                                                          color:
                                                              Colors.grey[400]!,
                                                        )
                                                      : null,
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    GestureDetector(
                                                      onDoubleTap: () {
                                                        // Enable comprehensive surface editing on double tap
                                                        final nameController =
                                                            TextEditingController(
                                                              text:
                                                                  surface.name,
                                                            );
                                                        final widthController =
                                                            TextEditingController(
                                                              text: surface
                                                                  .width
                                                                  .toString(),
                                                            );
                                                        final heightController =
                                                            TextEditingController(
                                                              text: surface
                                                                  .height
                                                                  .toString(),
                                                            );
                                                        LEDModel? selectedLED =
                                                            surface.selectedLED;
                                                        List<LEDModel>
                                                        searchResults = [];
                                                        bool showSuggestions =
                                                            false;
                                                        bool isStacked =
                                                            surface.isStacked;
                                                        bool isRigged =
                                                            surface.isRigged;
                                                        final searchController =
                                                            TextEditingController(
                                                              text:
                                                                  surface
                                                                      .selectedLED
                                                                      ?.name ??
                                                                  '',
                                                            );

                                                        showDialog(
                                                          context: context,
                                                          builder: (context) => StatefulBuilder(
                                                            builder:
                                                                (
                                                                  context,
                                                                  setDialogState,
                                                                ) => AlertDialog(
                                                                  title: const Text(
                                                                    'Edit Surface',
                                                                  ),
                                                                  content: SizedBox(
                                                                    width: 400,
                                                                    child: Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        // Surface Name
                                                                        TextFormField(
                                                                          controller:
                                                                              nameController,
                                                                          decoration: const InputDecoration(
                                                                            labelText:
                                                                                'Surface Name',
                                                                            border:
                                                                                OutlineInputBorder(),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                          height:
                                                                              16,
                                                                        ),
                                                                        // LED Product Search
                                                                        Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            TextFormField(
                                                                              controller: searchController,
                                                                              decoration: const InputDecoration(
                                                                                labelText: 'LED Product',
                                                                                border: OutlineInputBorder(),
                                                                                prefixIcon: Icon(
                                                                                  Icons.search,
                                                                                ),
                                                                              ),
                                                                              onChanged:
                                                                                  (
                                                                                    value,
                                                                                  ) async {
                                                                                    if (value.isNotEmpty) {
                                                                                      final results = await LEDService.searchLEDs(
                                                                                        value,
                                                                                      );
                                                                                      setDialogState(
                                                                                        () {
                                                                                          searchResults = results
                                                                                              .take(
                                                                                                5,
                                                                                              )
                                                                                              .toList();
                                                                                          showSuggestions = results.isNotEmpty;
                                                                                        },
                                                                                      );
                                                                                    } else {
                                                                                      setDialogState(
                                                                                        () {
                                                                                          searchResults = [];
                                                                                          showSuggestions = false;
                                                                                        },
                                                                                      );
                                                                                    }
                                                                                  },
                                                                            ),
                                                                            // LED suggestions dropdown
                                                                            if (showSuggestions)
                                                                              Container(
                                                                                margin: const EdgeInsets.only(
                                                                                  top: 4,
                                                                                ),
                                                                                constraints: const BoxConstraints(
                                                                                  maxHeight: 150,
                                                                                ),
                                                                                decoration: BoxDecoration(
                                                                                  border: Border.all(
                                                                                    color: Colors.grey[400]!,
                                                                                  ),
                                                                                  borderRadius: BorderRadius.circular(
                                                                                    4,
                                                                                  ),
                                                                                ),
                                                                                child: ListView.builder(
                                                                                  shrinkWrap: true,
                                                                                  itemCount: searchResults.length,
                                                                                  itemBuilder:
                                                                                      (
                                                                                        context,
                                                                                        index,
                                                                                      ) {
                                                                                        final led = searchResults[index];
                                                                                        return ListTile(
                                                                                          dense: true,
                                                                                          title: Text(
                                                                                            led.name,
                                                                                            style: const TextStyle(
                                                                                              fontSize: 12,
                                                                                            ),
                                                                                          ),
                                                                                          onTap: () {
                                                                                            setDialogState(
                                                                                              () {
                                                                                                selectedLED = led;
                                                                                                searchController.text = led.name;
                                                                                                showSuggestions = false;
                                                                                              },
                                                                                            );
                                                                                          },
                                                                                        );
                                                                                      },
                                                                                ),
                                                                              ),
                                                                          ],
                                                                        ),
                                                                        const SizedBox(
                                                                          height:
                                                                              16,
                                                                        ),
                                                                        // Width and Height
                                                                        Row(
                                                                          children: [
                                                                            Expanded(
                                                                              child: TextFormField(
                                                                                controller: widthController,
                                                                                decoration: const InputDecoration(
                                                                                  labelText: 'Width (m)',
                                                                                  border: OutlineInputBorder(),
                                                                                ),
                                                                                keyboardType: TextInputType.number,
                                                                              ),
                                                                            ),
                                                                            const SizedBox(
                                                                              width: 16,
                                                                            ),
                                                                            Expanded(
                                                                              child: TextFormField(
                                                                                controller: heightController,
                                                                                decoration: const InputDecoration(
                                                                                  labelText: 'Height (m)',
                                                                                  border: OutlineInputBorder(),
                                                                                ),
                                                                                keyboardType: TextInputType.number,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        const SizedBox(
                                                                          height:
                                                                              16,
                                                                        ),
                                                                        // Stacked and Rigged checkboxes
                                                                        Row(
                                                                          children: [
                                                                            Expanded(
                                                                              child: CheckboxListTile(
                                                                                title: const Text(
                                                                                  'Stacked',
                                                                                  style: TextStyle(
                                                                                    fontSize: 14,
                                                                                  ),
                                                                                ),
                                                                                value: isStacked,
                                                                                onChanged:
                                                                                    (
                                                                                      value,
                                                                                    ) {
                                                                                      setDialogState(
                                                                                        () {
                                                                                          if (value ==
                                                                                              true) {
                                                                                            isStacked = true;
                                                                                            isRigged = false; // Uncheck rigged when stacked is selected
                                                                                          } else {
                                                                                            isStacked = false;
                                                                                          }
                                                                                        },
                                                                                      );
                                                                                    },
                                                                                activeColor: Colors.orange,
                                                                                controlAffinity: ListTileControlAffinity.leading,
                                                                                contentPadding: EdgeInsets.zero,
                                                                              ),
                                                                            ),
                                                                            Expanded(
                                                                              child: CheckboxListTile(
                                                                                title: const Text(
                                                                                  'Rigged',
                                                                                  style: TextStyle(
                                                                                    fontSize: 14,
                                                                                  ),
                                                                                ),
                                                                                value: isRigged,
                                                                                onChanged:
                                                                                    (
                                                                                      value,
                                                                                    ) {
                                                                                      setDialogState(
                                                                                        () {
                                                                                          if (value ==
                                                                                              true) {
                                                                                            isRigged = true;
                                                                                            isStacked = false; // Uncheck stacked when rigged is selected
                                                                                          } else {
                                                                                            isRigged = false;
                                                                                          }
                                                                                        },
                                                                                      );
                                                                                    },
                                                                                activeColor: Colors.orange,
                                                                                controlAffinity: ListTileControlAffinity.leading,
                                                                                contentPadding: EdgeInsets.zero,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed: () =>
                                                                          Navigator.pop(
                                                                            context,
                                                                          ),
                                                                      child: const Text(
                                                                        'Cancel',
                                                                      ),
                                                                    ),
                                                                    TextButton(
                                                                      onPressed: () {
                                                                        final double?
                                                                        width = double.tryParse(
                                                                          widthController
                                                                              .text,
                                                                        );
                                                                        final double?
                                                                        height = double.tryParse(
                                                                          heightController
                                                                              .text,
                                                                        );

                                                                        if (nameController.text.isNotEmpty &&
                                                                            selectedLED !=
                                                                                null &&
                                                                            width !=
                                                                                null &&
                                                                            height !=
                                                                                null &&
                                                                            width >
                                                                                0 &&
                                                                            height >
                                                                                0 &&
                                                                            (isStacked ||
                                                                                isRigged)) {
                                                                          // Require one checkbox to be selected
                                                                          setState(() {
                                                                            surface.name =
                                                                                nameController.text;
                                                                            surface.selectedLED =
                                                                                selectedLED;
                                                                            surface.width =
                                                                                width;
                                                                            surface.height =
                                                                                height;
                                                                            surface.isStacked =
                                                                                isStacked;
                                                                            surface.isRigged =
                                                                                isRigged;
                                                                            surface.updateCalculation();
                                                                            // Update checkbox states if this is the active surface
                                                                            _updateCheckboxStates();
                                                                          });
                                                                          Navigator.pop(
                                                                            context,
                                                                          );
                                                                        } else {
                                                                          String
                                                                          message;
                                                                          if (!(isStacked ||
                                                                              isRigged)) {
                                                                            message =
                                                                                'Please select either Stacked or Rigged option';
                                                                          } else {
                                                                            message =
                                                                                'Please fill in all fields with valid values';
                                                                          }
                                                                          ScaffoldMessenger.of(
                                                                            context,
                                                                          ).showSnackBar(
                                                                            SnackBar(
                                                                              content: Text(
                                                                                message,
                                                                              ),
                                                                              backgroundColor: Colors.red,
                                                                            ),
                                                                          );
                                                                        }
                                                                      },
                                                                      child: const Text(
                                                                        'Save',
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                      child: Text(
                                                        surface.name,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: isActive
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                    .normal,
                                                          color: isActive
                                                              ? Colors.black
                                                              : Colors
                                                                    .grey[600],
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    GestureDetector(
                                                      onTap: () =>
                                                          _removeSurface(index),
                                                      child: const Icon(
                                                        Icons.close,
                                                        size: 14,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Tab content
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: _getActiveCalculation() != null
                                    ? LEDSummaryWidget(
                                        calculation: _getActiveCalculation()!,
                                        isStacked: _isStacked,
                                        isRigged: _isRigged,
                                      )
                                    : const Center(
                                        child: Text(
                                          'No calculation available',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Project Totals window - positioned to the right of calculation window
                  if (_calculationResult != null || _surfaces.isNotEmpty)
                    Positioned(
                      bottom: 70, // Extended by 10px (was 80)
                      left:
                          940, // Position to the right of calculation window (920 + 20px gap)
                      width: 900, // Same width as calculation window
                      top: 330, // Restored to original position
                      child: Container(
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
                          children: [
                            // Header with editable project name
                            Container(
                              height: 45, // Restored to original height
                              decoration: BoxDecoration(
                                color:
                                    Colors.grey[200], // Light grey background
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 200,
                                  child: TextField(
                                    controller: _projectNameController,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Editable text area in the center
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: TextField(
                                  controller: _projectTotalsController,
                                  maxLines: null,
                                  expands: true,
                                  textAlignVertical: TextAlignVertical.top,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Enter project totals information...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.orange,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                                  'Generate Pixel Maps functionality coming soon!',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Generate Pixel Maps',
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
                                  'Generate OBJ functionality coming soon!',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Generate OBJ',
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
                                  'Generate Calculations functionality coming soon!',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Generate Calculations',
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
                          onPressed: () async {
                            final result = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return const LEDListDialog();
                              },
                            );
                            // Refresh calculations after dialog closes
                            if (result != null || mounted) {
                              await _refreshCalculations();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
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
                          onPressed: () async {
                            final result = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return const AddLEDDialog();
                              },
                            );
                            // Refresh calculations after dialog closes
                            if (result != null || mounted) {
                              await _refreshCalculations();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
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

  // Helper method to build project information fields
  Widget _buildProjectInfoField(String label, TextEditingController controller, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 24,
          child: TextField(
            controller: controller,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Colors.blue, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
