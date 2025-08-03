import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/led_service.dart';
import 'services/led_calculation_service.dart';
import 'models/led_model.dart';
import 'models/surface_model.dart';

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

  final List<LEDModel> _searchResults = [];
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
