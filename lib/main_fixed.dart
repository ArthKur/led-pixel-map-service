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

  void _checkForLEDUpdates() async {
    if (_selectedLED != null) {
      try {
        final updatedLED = await LEDService.getLEDById(_selectedLED!.id);
        if (updatedLED != null && mounted) {
          setState(() {
            _selectedLED = updatedLED;
            _performCalculation();
          });
        }
      } catch (e) {
        // Handle error silently - LED might have been deleted
      }
    }
  }

  void _performCalculation() async {
    if (_selectedLED != null &&
        _widthController.text.isNotEmpty &&
        _heightController.text.isNotEmpty) {
      try {
        final width = double.parse(_widthController.text);
        final height = double.parse(_heightController.text);
        final result = LEDCalculationService.calculateLEDRequirements(
          _selectedLED!,
          width,
          height,
        );
        setState(() {
          _calculationResult = result;
        });
      } catch (e) {
        // Handle invalid input
        setState(() {
          _calculationResult = null;
        });
      }
    }
  }

  void _addSurface() {
    if (_selectedLED == null || _calculationResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an LED and enter dimensions first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if one of the required checkboxes is selected
    if (!_isStacked && !_isRigged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select either Stacked or Rigged option'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get the surface name, either from input or generated
    String surfaceName = _nameController.text.isEmpty
        ? 'Surface ${_surfaces.length + 1}'
        : _nameController.text;

    final surface = Surface(
      name: surfaceName,
      led: _selectedLED!,
      calculationResult: _calculationResult!,
      isStacked: _isStacked,
      isRigged: _isRigged,
    );

    setState(() {
      _surfaces.add(surface);
      _activeSurfaceIndex = _surfaces.length - 1;

      // Keep the current form data but auto-increment the name for next surface
      if (_nameController.text.isNotEmpty) {
        _nameController.text = _generateNextName(_nameController.text);
      }
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added surface: ${surface.name}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );

    // Recalculate totals
    _calculateLEDSummary();
  }

  void _removeSurface(int index) {
    setState(() {
      _surfaces.removeAt(index);
      if (_activeSurfaceIndex >= _surfaces.length) {
        _activeSurfaceIndex = _surfaces.length - 1;
      }
      if (_activeSurfaceIndex < 0) {
        _activeSurfaceIndex = 0;
      }
    });
    _calculateLEDSummary();
  }

  LEDCalculationResult? _getActiveCalculation() {
    if (_surfaces.isEmpty || _activeSurfaceIndex >= _surfaces.length) {
      return _calculationResult;
    }
    return _surfaces[_activeSurfaceIndex].calculationResult;
  }

  void _updateCheckboxStates() {
    // Ensure mutual exclusivity - when one is selected, the other is deselected
    // But at least one must remain selected
    if (!_isStacked && !_isRigged) {
      // If both are unchecked, revert to the previously selected one
      setState(() {
        _isStacked = true; // Default back to stacked
      });
    }
  }

  void _calculateLEDSummary() {
    if (_surfaces.isEmpty) return;

    // Avoid switching to "Current" tab when recalculating
    // Keep the current active tab unchanged
  }

  Future<void> _refreshCalculations() async {
    for (int i = 0; i < _surfaces.length; i++) {
      if (_surfaces[i].led != null) {
        try {
          final updatedLED = await LEDService.getLEDById(_surfaces[i].led.id);
          if (updatedLED != null) {
            final result = LEDCalculationService.calculateLEDRequirements(
              updatedLED,
              _surfaces[i].calculationResult.surfaceWidth,
              _surfaces[i].calculationResult.surfaceHeight,
            );

            setState(() {
              _surfaces[i] = Surface(
                name: _surfaces[i].name,
                led: updatedLED,
                calculationResult: result,
                isStacked: _surfaces[i].isStacked,
                isRigged: _surfaces[i].isRigged,
              );
            });
          }
        } catch (e) {
          // Handle error silently
        }
      }
    }

    // Also refresh current calculation if available
    if (_selectedLED != null) {
      try {
        final updatedLED = await LEDService.getLEDById(_selectedLED!.id);
        if (updatedLED != null && mounted) {
          setState(() {
            _selectedLED = updatedLED;
            _performCalculation();
          });
        }
      } catch (e) {
        // Handle error silently
      }
    }

    _calculateLEDSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
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
                          _buildProjectInfoField(
                            'Easy Job number',
                            _easyJobNumberController,
                            Colors.grey.shade600,
                          ),
                          const SizedBox(height: 8),
                          _buildProjectInfoField(
                            'Project Name',
                            _projectNameInfoController,
                            Colors.black,
                          ),
                          const SizedBox(height: 8),
                          _buildProjectInfoField(
                            'Project Manager',
                            _projectManagerController,
                            Colors.black,
                          ),
                          const SizedBox(height: 8),
                          _buildProjectInfoField(
                            'Project Engineer',
                            _projectEngineerController,
                            Colors.black,
                          ),
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
                                    border: Border.all(
                                      color: Colors.transparent,
                                    ),
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
                                    border: Border.all(
                                      color: Colors.transparent,
                                    ),
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
                                    border: Border.all(
                                      color: Colors.transparent,
                                    ),
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
                                                .toList();
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
                                const SizedBox(height: 12),
                                // Dimensions input row
                                Row(
                                  children: [
                                    // Width input
                                    GestureDetector(
                                      onTap: () {
                                        // Prevent parent gesture detector from interfering
                                      },
                                      child: Container(
                                        width: 100,
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
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          onChanged: (value) =>
                                              _performCalculation(),
                                          decoration: const InputDecoration(
                                            labelText: 'Width (m)',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.all(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Height input
                                    GestureDetector(
                                      onTap: () {
                                        // Prevent parent gesture detector from interfering
                                      },
                                      child: Container(
                                        width: 100,
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
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          onChanged: (value) =>
                                              _performCalculation(),
                                          decoration: const InputDecoration(
                                            labelText: 'Height (m)',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.all(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Name input
                                    GestureDetector(
                                      onTap: () {
                                        // Prevent parent gesture detector from interfering
                                      },
                                      child: Container(
                                        width: 96,
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
                                            labelText: 'Name',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.all(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Stacked and Rigged checkboxes row
                                Row(
                                  children: [
                                    // Stacked checkbox
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _isStacked,
                                          onChanged: (value) {
                                            setState(() {
                                              _isStacked = value ?? false;
                                              if (_isStacked) {
                                                _isRigged =
                                                    false; // Mutual exclusivity
                                              } else if (!_isRigged) {
                                                _isStacked =
                                                    true; // Ensure at least one is selected
                                              }
                                            });
                                          },
                                          activeColor: Colors.blue,
                                        ),
                                        const Text('Stacked'),
                                      ],
                                    ),
                                    const SizedBox(width: 20),
                                    // Rigged checkbox
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _isRigged,
                                          onChanged: (value) {
                                            setState(() {
                                              _isRigged = value ?? false;
                                              if (_isRigged) {
                                                _isStacked =
                                                    false; // Mutual exclusivity
                                              } else if (!_isStacked) {
                                                _isRigged =
                                                    true; // Ensure at least one is selected
                                              }
                                            });
                                          },
                                          activeColor: Colors.blue,
                                        ),
                                        const Text('Rigged'),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // Add Surface button moved closer
                            Column(
                              children: [
                                const SizedBox(
                                  height: 0,
                                ), // Align with search box
                                ElevatedButton(
                                  onPressed: _addSurface,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'ADD SURFACE',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
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
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) =>
                              Divider(height: 1, color: Colors.grey[300]),
                          itemBuilder: (context, index) {
                            final led = _searchResults[index];
                            return ListTile(
                              dense: true,
                              title: Text(
                                led.name,
                                style: const TextStyle(fontSize: 14),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedLED = led;
                                  _searchController.text = led.name;
                                  _showSuggestions = false;
                                });
                                _performCalculation();
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  // LED Summary in bottom left
                  if (_surfaces.isNotEmpty)
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: LEDSummaryWidget(
                        surfaces: _surfaces,
                        activeSurfaceIndex: _activeSurfaceIndex,
                        onSurfaceSelected: (index) {
                          // Made non-interactive - current tab cannot be clicked
                          if (index < _surfaces.length) {
                            setState(() {
                              _activeSurfaceIndex = index;
                            });
                          }
                        },
                        calculationResult: _getActiveCalculation(),
                        projectTotalsController: _projectTotalsController,
                        projectNameController: _projectNameController,
                        isStacked: _isStacked,
                        isRigged: _isRigged,
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
  Widget _buildProjectInfoField(
    String label,
    TextEditingController controller,
    Color labelColor,
  ) {
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
            style: const TextStyle(fontSize: 12, color: Colors.black),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 4,
              ),
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
