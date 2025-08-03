import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'services/led_service.dart';
import 'services/led_calculation_service.dart';
import 'services/file_service.dart';
import 'models/led_model.dart';
import 'models/surface_model.dart';
import 'widgets/add_led_dialog_new.dart';
import 'widgets/led_list_dialog.dart';
import 'widgets/led_summary_dialog.dart';
import 'widgets/pixel_maps_dialog_fixed.dart';
import 'widgets/led_study_dialog.dart';
import 'widgets/power_diagram_dialog_enhanced.dart';

// Define the new button background color as per style guide
const Color buttonBackgroundColor = Color.fromRGBO(247, 238, 221, 1.0);

// Define the new button text color as per style guide (30% darker)
const Color buttonTextColor = Color.fromRGBO(125, 117, 103, 1.0);

// Define the new border colors as per style guide - muted taupe/light sand
const Color borderColorLight = Color(0xFFE7DCCC); // Lighter border #E7DCCC
const Color borderColorDark = Color(0xFFD4C7B7); // Darker border #D4C7B7

// Define the new text colors as per style guide
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

// Add extension to Surface class to provide additional properties
extension SurfaceExtension on Surface {
  double? get area => width != null && height != null ? width! * height! : null;

  String? get resolution => selectedLED != null && calculation != null
      ? "${calculation!.pixelsWidth} × ${calculation!.pixelsHeight}"
      : null;

  int? get totalPanels => calculation != null
      ? calculation!.totalFullPanels + calculation!.totalHalfPanels
      : null;

  int? get fullPanels => calculation?.totalFullPanels;

  int? get halfPanels => calculation?.totalHalfPanels;

  double? get totalPowerAvg => calculation?.avgPower;

  double? get totalPowerMax => calculation?.maxPower;

  double? get totalWeight => calculation?.totalWeight;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LEDService.init();
  runApp(const LEDCalculatorApp());
}

class LEDCalculatorApp extends StatelessWidget {
  const LEDCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'LED Calculator 2.0',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(
              0xFFF7F6F3,
            ), // Very light warm gray
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(
              0xFF181A20,
            ), // Deep blue-black/charcoal background
          ),
          themeMode: ThemeMode.system,
          home: const FullScreenHomePage(),
        );
      },
    );
  }
}

class FullScreenHomePage extends StatefulWidget {
  const FullScreenHomePage({super.key});

  @override
  State<FullScreenHomePage> createState() => _FullScreenHomePageState();
}

class _FullScreenHomePageState extends State<FullScreenHomePage> {
  // Controllers
  final _searchController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _nameController = TextEditingController();

  // Scroll controllers for the main scrollable area
  final _verticalScrollController = ScrollController();
  final _horizontalScrollController = ScrollController();

  // Project data controllers

  // Chat messages list
  List<Map<String, String>> messages = [];

  // Dark mode toggle
  bool _isDarkMode = false;

  // Logo import
  String? _logoBase64;
  String? _logoFileName;

  // Search functionality
  List<LEDModel> _searchResults = [];
  bool _showSuggestions = false;

  void _searchLEDs(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSuggestions = false;
        // Don't clear LED selection - keep form state independent
      });
      print("Empty query, hiding suggestions");
      return;
    }

    // Fetch results from service
    final results = await LEDService.searchLEDs(query.toLowerCase());

    setState(() {
      _searchResults = results;
      _showSuggestions = results.isNotEmpty;
      print(
        "Set _showSuggestions to ${results.isNotEmpty} with ${results.length} results",
      );
    });

    // Debug: Print current state to console
    print("Search results: ${_searchResults.length}");
    print("Show suggestions: $_showSuggestions");
  }

  void _selectLED(LEDModel led) {
    setState(() {
      _searchController.text = led.name;
      _showSuggestions = false;

      // Only update form fields for new surface creation
      // Don't modify existing surfaces - they can only be edited via the edit dialog
    });
  }

  void clearMessages() {
    setState(() {
      messages.clear();
    });
  }

  // Multi-surface support
  final List<Surface> _surfaces = [];
  int _activeSurfaceIndex = 0;

  // Project data support
  ProjectData _projectData = ProjectData();

  // UI state for checkboxes
  bool _isStacked = false;
  bool _isRigged = false;

  // Helper getter for active surface LED
  LEDModel? get _activeLED =>
      _surfaces.isNotEmpty && _activeSurfaceIndex < _surfaces.length
      ? _surfaces[_activeSurfaceIndex].selectedLED
      : null;

  // Helper getter for active surface calculation
  LEDCalculationResult? get _activeCalculation =>
      _surfaces.isNotEmpty && _activeSurfaceIndex < _surfaces.length
      ? _surfaces[_activeSurfaceIndex].calculation
      : null;

  @override
  void initState() {
    super.initState();
    _enableFullScreen();
    LEDService.addAbsenProducts();
    LEDService.addNewLEDProducts(); // Add new LED products from specifications
    // Don't create initial surface - user will add when needed

    // Check if device is in dark mode
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _isDarkMode = brightness == Brightness.dark;
  }

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  // Password protection for LED management functions
  Future<bool> _showPasswordDialog() async {
    String enteredPassword = '';
    const String correctPassword = 'abc123';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Password Required',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter password to access LED management:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                onChanged: (value) {
                  enteredPassword = value;
                },
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                onSubmitted: (value) {
                  enteredPassword = value;
                  if (enteredPassword == correctPassword) {
                    Navigator.of(context).pop(true);
                  } else {
                    Navigator.of(context).pop(false);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: buttonTextColor),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (enteredPassword == correctPassword) {
                  Navigator.of(context).pop(true);
                } else {
                  Navigator.of(context).pop(false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonBackgroundColor,
                foregroundColor: buttonTextColor,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (result == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect password!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }

    return result ?? false;
  }

  // Password-protected import function
  Future<void> _importLEDDataWithPassword() async {
    // Check password before allowing access
    final hasAccess = await _showPasswordDialog();
    if (hasAccess) {
      await _importLEDData();
    }
  }

  Future<void> _importLEDData() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Importing LED data from CSV...'),
              ],
            ),
          );
        },
      );

      final csvContent = await FileService.pickCsvFile();

      // Close loading dialog
      Navigator.of(context).pop();

      if (csvContent != null) {
        // Import LED data from CSV content
        await LEDService.importLEDDataFromCSVContent(csvContent);

        // Refresh search results to show new LEDs
        if (_searchController.text.isNotEmpty) {
          _searchLEDs(_searchController.text);
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error importing LED data: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Save project as JSON file
  void _saveProjectAsJson() {
    // Create project data structure
    Map<String, dynamic> projectData = {
      'projectInfo': {
        'projectNumber': _projectData.projectNumber,
        'projectName': _projectData.projectName,
        'projectManager': _projectData.projectManager,
        'projectEngineer': _projectData.projectEngineer,
        'clientName': _projectData.clientName,
        'location': _projectData.location,
        'description': _projectData.description,
        'logoBase64': _logoBase64, // Save logo data
        'logoFileName': _logoFileName, // Save logo filename
      },
      'surfaces': _surfaces
          .map(
            (surface) => {
              'id': surface.id,
              'name': surface.name,
              'width': surface.width,
              'height': surface.height,
              'isStacked': surface.isStacked,
              'isRigged': surface.isRigged,
              'notes': surface.notes,
              'powerLines': surface.powerLines, // Add power lines data
              'selectedLED': surface.selectedLED != null
                  ? {
                      'name': surface.selectedLED!.name,
                      'manufacturer': surface.selectedLED!.manufacturer,
                      'model': surface.selectedLED!.model,
                      'pitch': surface.selectedLED!.pitch,
                      'fullHeight': surface.selectedLED!.fullHeight,
                      'halfHeight': surface.selectedLED!.halfHeight,
                      'width': surface.selectedLED!.width,
                      'depth': surface.selectedLED!.depth,
                      'fullPanelWeight': surface.selectedLED!.fullPanelWeight,
                      'halfPanelWeight': surface.selectedLED!.halfPanelWeight,
                      'hPixel': surface.selectedLED!.hPixel,
                      'wPixel': surface.selectedLED!.wPixel,
                      'halfHPixel': surface.selectedLED!.halfHPixel,
                      'halfWPixel': surface.selectedLED!.halfWPixel,
                      'halfWidth': surface.selectedLED!.halfWidth,
                      'fullPanelMaxW': surface.selectedLED!.fullPanelMaxW,
                      'halfPanelMaxW': surface.selectedLED!.halfPanelMaxW,
                      'fullPanelAvgW': surface.selectedLED!.fullPanelAvgW,
                      'halfPanelAvgW': surface.selectedLED!.halfPanelAvgW,
                      'processing': surface.selectedLED!.processing,
                      'brightness': surface.selectedLED!.brightness,
                      'viewingAngle': surface.selectedLED!.viewingAngle,
                      'refreshRate': surface.selectedLED!.refreshRate,
                      'ledConfiguration': surface.selectedLED!.ledConfiguration,
                      'ipRating': surface.selectedLED!.ipRating,
                      'curveCapability': surface.selectedLED!.curveCapability,
                      'verification': surface.selectedLED!.verification,
                      'dataConnection': surface.selectedLED!.dataConnection,
                      'powerConnection': surface.selectedLED!.powerConnection,
                      'touringFrame': surface.selectedLED!.touringFrame,
                      'supplier': surface.selectedLED!.supplier,
                      'operatingVoltage': surface.selectedLED!.operatingVoltage,
                      'operatingTemp': surface.selectedLED!.operatingTemp,
                      'dateAdded': surface.selectedLED!.dateAdded.toString(),
                      'panelsPerPort': surface.selectedLED!.panelsPerPort,
                      'panelsPer16A': surface.selectedLED!.panelsPer16A,
                    }
                  : null,
            },
          )
          .toList(),
      'metadata': {
        'version': '2.0',
        'createdDate': DateTime.now().toIso8601String(),
        'appVersion': 'LED Calculator 2.0',
      },
    };

    // Convert to JSON string
    String jsonString = jsonEncode(projectData);

    // Create filename from project number and name
    String fileName = 'LED_Calculator';
    if (_projectData.projectNumber.isNotEmpty) {
      fileName += '_${_projectData.projectNumber}';
    }
    if (_projectData.projectName.isNotEmpty) {
      fileName += '_${_projectData.projectName}';
    }

    // If no project data, add timestamp
    if (_projectData.projectNumber.isEmpty &&
        _projectData.projectName.isEmpty) {
      fileName += '_${DateTime.now().millisecondsSinceEpoch}';
    }

    // Show save dialog with filename input and save options
    _showSaveDialog(jsonString, fileName);
  }

  void _showSaveDialog(String jsonContent, String defaultFileName) {
    TextEditingController fileNameController = TextEditingController(
      text: defaultFileName,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _isDarkMode
              ? const Color(0xFF23272F) // Gunmetal/slate gray panel background
              : const Color(0xFFF7F6F3), // Very light warm gray
          title: Row(
            children: [
              Icon(
                Icons.save,
                color: _isDarkMode ? Colors.white : Colors.blue[600],
              ),
              const SizedBox(width: 10),
              Text(
                'Save Project',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : textColorPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose how to save your project:',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white70 : textColorPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'File name:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _isDarkMode ? Colors.white : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: fileNameController,
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : textColorPrimary,
                ),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter file name',
                  hintStyle: TextStyle(
                    color: _isDarkMode ? Colors.grey[400] : textColorSecondary,
                  ),
                  suffix: Text(
                    '.json',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white70 : textColorSecondary,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _isDarkMode ? Colors.grey[600]! : borderColorLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: _isDarkMode ? Colors.grey[400] : textColorSecondary,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _downloadJsonFile(jsonContent, fileNameController.text.trim());
              },
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save Project'),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonBackgroundColor,
                foregroundColor: buttonTextColor,
              ),
            ),
          ],
        );
      },
    );
  }

  void _downloadJsonFile(String jsonContent, String fileName) async {
    try {
      // Clean filename
      String cleanFileName = fileName.replaceAll(RegExp(r'[^\w\-_\.]'), '_');
      if (cleanFileName.isEmpty) {
        cleanFileName = 'LED_Project_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Create bytes from JSON content
      final bytes = Uint8List.fromList(utf8.encode(jsonContent));

      // Use cross-platform file service
      await FileService.downloadFile(
        bytes,
        '$cleanFileName.json',
        'application/json',
      );

      // No success message - silent save
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving file: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Open project from JSON file
  void _openProject() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Open Project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select a JSON project file to open.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _selectJsonFile();
                },
                icon: const Icon(Icons.file_upload),
                label: const Text('Choose File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBackgroundColor,
                  foregroundColor: buttonTextColor,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: buttonTextColor),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _selectJsonFile() async {
    try {
      final jsonContent = await FileService.pickJsonFile();
      if (jsonContent != null) {
        _loadProjectFromJson(jsonContent);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reading file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _loadProjectFromJson(String jsonContent) {
    try {
      final Map<String, dynamic> projectData = jsonDecode(jsonContent);

      // Load project info
      final projectInfo = projectData['projectInfo'] as Map<String, dynamic>?;
      if (projectInfo != null) {
        _projectData.projectNumber = projectInfo['projectNumber'] ?? '';
        _projectData.projectName = projectInfo['projectName'] ?? '';
        _projectData.projectManager = projectInfo['projectManager'] ?? '';
        _projectData.projectEngineer = projectInfo['projectEngineer'] ?? '';
        _projectData.clientName = projectInfo['clientName'] ?? '';
        _projectData.location = projectInfo['location'] ?? '';
        _projectData.description = projectInfo['description'] ?? '';

        // Load logo data
        setState(() {
          _logoBase64 = projectInfo['logoBase64'];
          _logoFileName = projectInfo['logoFileName'];
        });
      }

      // Load surfaces
      final surfacesData = projectData['surfaces'] as List<dynamic>?;
      if (surfacesData != null) {
        setState(() {
          _surfaces.clear();
          _activeSurfaceIndex = 0;

          for (final surfaceData in surfacesData) {
            final surface = Surface(
              id:
                  surfaceData['id'] ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              name: surfaceData['name'] ?? '',
            );

            surface.width = surfaceData['width']?.toDouble();
            surface.height = surfaceData['height']?.toDouble();
            surface.isStacked = surfaceData['isStacked'] ?? false;
            surface.isRigged = surfaceData['isRigged'] ?? false;
            surface.notes = surfaceData['notes'] ?? '';

            // Load power lines data if available
            final powerLinesData = surfaceData['powerLines'] as List<dynamic>?;
            if (powerLinesData != null) {
              surface.powerLines = powerLinesData
                  .map((powerLine) => Map<String, dynamic>.from(powerLine))
                  .toList();
            }

            // Load LED data if available
            final ledData = surfaceData['selectedLED'] as Map<String, dynamic>?;
            if (ledData != null) {
              surface.selectedLED = LEDModel(
                name: ledData['name'] ?? '',
                manufacturer: ledData['manufacturer'] ?? '',
                model: ledData['model'] ?? '',
                pitch: ledData['pitch']?.toDouble() ?? 0.0,
                fullHeight: ledData['fullHeight']?.toDouble() ?? 0.0,
                halfHeight: ledData['halfHeight']?.toDouble() ?? 0.0,
                width: ledData['width']?.toDouble() ?? 0.0,
                depth: ledData['depth']?.toDouble() ?? 0.0,
                fullPanelWeight: ledData['fullPanelWeight']?.toDouble() ?? 0.0,
                halfPanelWeight: ledData['halfPanelWeight']?.toDouble() ?? 0.0,
                hPixel: ledData['hPixel'] ?? 0,
                wPixel: ledData['wPixel'] ?? 0,
                halfHPixel: ledData['halfHPixel'] ?? 0,
                halfWPixel: ledData['halfWPixel'] ?? 0,
                halfWidth: ledData['halfWidth']?.toDouble() ?? 0.0,
                fullPanelMaxW: ledData['fullPanelMaxW']?.toDouble() ?? 0.0,
                halfPanelMaxW: ledData['halfPanelMaxW']?.toDouble() ?? 0.0,
                fullPanelAvgW: ledData['fullPanelAvgW']?.toDouble() ?? 0.0,
                halfPanelAvgW: ledData['halfPanelAvgW']?.toDouble() ?? 0.0,
                processing: ledData['processing'] ?? '',
                brightness: ledData['brightness'] ?? 0,
                viewingAngle: ledData['viewingAngle'] ?? '',
                refreshRate: ledData['refreshRate'] ?? 0,
                ledConfiguration: ledData['ledConfiguration'] ?? '',
                ipRating: ledData['ipRating'] ?? '',
                curveCapability: ledData['curveCapability'] ?? '',
                verification: ledData['verification'] ?? '',
                dataConnection: ledData['dataConnection'] ?? '',
                powerConnection: ledData['powerConnection'] ?? '',
                touringFrame: ledData['touringFrame'] ?? '',
                supplier: ledData['supplier'] ?? '',
                operatingVoltage: ledData['operatingVoltage'] ?? '',
                operatingTemp: ledData['operatingTemp'] ?? '',
                dateAdded:
                    DateTime.tryParse(ledData['dateAdded'] ?? '') ??
                    DateTime.now(),
                panelsPerPort: ledData['panelsPerPort'] ?? 0,
                panelsPer16A: ledData['panelsPer16A'] ?? 0,
              );
            }

            // Update calculation
            surface.updateCalculation();
            _surfaces.add(surface);
          }
        });
      }

      // Success message removed - no more banner popup for project loading
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading project: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _nameController.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _addSurface() {
    // Validate that all required fields are filled
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a surface name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check for duplicate names and modify if necessary
    String proposedName = _nameController.text.trim();
    String finalName = _getUniqueName(proposedName);

    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an LED product'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_widthController.text.trim().isEmpty ||
        double.tryParse(_widthController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid width'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_heightController.text.trim().isEmpty ||
        double.tryParse(_heightController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid height'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isStacked && !_isRigged) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select either Stacked or Rigged'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      // Create new surface with current form data
      final newSurface = Surface(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: finalName,
      );

      // Set the surface properties from current form
      newSurface.width = double.tryParse(_widthController.text);
      newSurface.height = double.tryParse(_heightController.text);
      newSurface.isStacked = _isStacked;
      newSurface.isRigged = _isRigged;

      // Find the currently selected LED from search
      if (_searchResults.isNotEmpty) {
        final selectedLED = _searchResults.firstWhere(
          (led) => led.name == _searchController.text,
          orElse: () => _searchResults.first,
        );
        newSurface.selectedLED = selectedLED;
      }

      // Update calculation for the new surface
      newSurface.updateCalculation();

      // Add to surfaces list and set as active
      _surfaces.add(newSurface);
      _activeSurfaceIndex = _surfaces.length - 1;

      // Keep all current form data - don't clear anything
      // This allows quick creation of similar surfaces
    });
  } // Helper method to ensure unique surface names

  String _getUniqueName(String proposedName) {
    // Check if the name already exists
    bool nameExists = _surfaces.any((surface) => surface.name == proposedName);

    if (!nameExists) {
      return proposedName;
    }

    // Find the highest number suffix
    int highestNumber = 0;
    RegExp regex = RegExp(r'^' + RegExp.escape(proposedName) + r'(\d+)$');

    for (Surface surface in _surfaces) {
      if (surface.name == proposedName) {
        highestNumber = math.max(highestNumber, 1);
      } else {
        Match? match = regex.firstMatch(surface.name);
        if (match != null) {
          int number = int.parse(match.group(1)!);
          highestNumber = math.max(highestNumber, number);
        }
      }
    }

    return '$proposedName${highestNumber + 1}';
  }

  // Helper method to ensure unique surface names when editing (excludes current surface)
  String _getUniqueNameExcluding(String proposedName, int excludeIndex) {
    // Check if the name already exists (excluding the current surface being edited)
    bool nameExists = false;
    for (int i = 0; i < _surfaces.length; i++) {
      if (i != excludeIndex && _surfaces[i].name == proposedName) {
        nameExists = true;
        break;
      }
    }

    if (!nameExists) {
      return proposedName;
    }

    // Find the highest number suffix (excluding the current surface)
    int highestNumber = 0;
    RegExp regex = RegExp(r'^' + RegExp.escape(proposedName) + r'(\d+)$');

    for (int i = 0; i < _surfaces.length; i++) {
      if (i == excludeIndex) continue; // Skip the current surface being edited

      Surface surface = _surfaces[i];
      if (surface.name == proposedName) {
        highestNumber = math.max(highestNumber, 1);
      } else {
        Match? match = regex.firstMatch(surface.name);
        if (match != null) {
          int number = int.parse(match.group(1)!);
          highestNumber = math.max(highestNumber, number);
        }
      }
    }

    return '$proposedName${highestNumber + 1}';
  }

  void _updateControllersFromActiveSurface() {
    // Don't update form controllers when switching tabs
    // Form is only for creating new surfaces, not for editing existing ones
    // Existing surfaces can only be edited via the edit dialog
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

  // Dialog for editing surface properties
  void _showEditSurfaceDialog(int surfaceIndex) {
    final surface = _surfaces[surfaceIndex];
    final nameController = TextEditingController(text: surface.name);
    final widthController = TextEditingController(
      text: surface.width?.toString() ?? '',
    );
    final heightController = TextEditingController(
      text: surface.height?.toString() ?? '',
    );
    final searchController = TextEditingController(
      text: surface.selectedLED?.name ?? '',
    );
    bool tempStacked = surface.isStacked;
    bool tempRigged = surface.isRigged;
    LEDModel? tempSelectedLED = surface.selectedLED;
    List<LEDModel> tempSearchResults = [];
    bool tempShowSuggestions = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _isDarkMode
                  ? const Color(
                      0xFF23272F,
                    ) // Gunmetal/slate gray panel background
                  : const Color(0xFFF7F6F3), // Very light warm gray
              title: Text(
                'Edit Surface',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : textColorPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Surface Name
                    TextField(
                      controller: nameController,
                      style: TextStyle(
                        color: _isDarkMode ? Colors.white : textColorPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Surface Name',
                        labelStyle: TextStyle(
                          color: _isDarkMode
                              ? Colors.grey[400]
                              : textColorSecondary,
                        ),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _isDarkMode
                                ? Colors.grey[600]!
                                : borderColorLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // LED Product Search
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: searchController,
                          style: TextStyle(
                            color: _isDarkMode
                                ? Colors.white
                                : textColorPrimary,
                          ),
                          onChanged: (value) async {
                            if (value.isEmpty) {
                              setDialogState(() {
                                tempSearchResults = [];
                                tempShowSuggestions = false;
                                tempSelectedLED = null;
                              });
                              return;
                            }

                            final results = await LEDService.searchLEDs(
                              value.toLowerCase(),
                            );
                            setDialogState(() {
                              tempSearchResults = results;
                              tempShowSuggestions = results.isNotEmpty;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'LED Product',
                            labelStyle: TextStyle(
                              color: _isDarkMode
                                  ? Colors.grey[400]
                                  : textColorSecondary,
                            ),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: _isDarkMode
                                    ? Colors.grey[600]!
                                    : borderColorLight,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: _isDarkMode
                                  ? Colors.grey[400]
                                  : textColorSecondary,
                            ),
                          ),
                        ),

                        // LED Search Suggestions - Fixed positioning and styling like main search
                        if (tempShowSuggestions)
                          Material(
                            elevation: 8,
                            color: Colors.transparent,
                            child: Container(
                              margin: const EdgeInsets.only(top: 4),
                              constraints: const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                color: _isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: buttonBackgroundColor,
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                elevation: 0,
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: tempSearchResults.length,
                                  itemBuilder: (context, index) {
                                    final led = tempSearchResults[index];
                                    return InkWell(
                                      onTap: () {
                                        setDialogState(() {
                                          tempSelectedLED = led;
                                          searchController.text = led.name;
                                          tempShowSuggestions = false;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                          horizontal: 16.0,
                                        ),
                                        child: Text(
                                          led.name,
                                          style: TextStyle(
                                            color: _isDarkMode
                                                ? Colors.white
                                                : textColorPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Width and Height
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: widthController,
                            style: TextStyle(
                              color: _isDarkMode
                                  ? Colors.white
                                  : textColorPrimary,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Width (m)',
                              labelStyle: TextStyle(
                                color: _isDarkMode
                                    ? Colors.grey[400]
                                    : textColorSecondary,
                              ),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: _isDarkMode
                                      ? Colors.grey[600]!
                                      : borderColorLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: heightController,
                            style: TextStyle(
                              color: _isDarkMode
                                  ? Colors.white
                                  : textColorPrimary,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Height (m)',
                              labelStyle: TextStyle(
                                color: _isDarkMode
                                    ? Colors.grey[400]
                                    : textColorSecondary,
                              ),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: _isDarkMode
                                      ? Colors.grey[600]!
                                      : borderColorLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stacked and Rigged checkboxes
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: Text(
                              'Stacked',
                              style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.white
                                    : textColorPrimary,
                              ),
                            ),
                            value: tempStacked,
                            onChanged: (value) {
                              setDialogState(() {
                                tempStacked = value ?? false;
                                // Make checkboxes mutually exclusive
                                if (tempStacked) {
                                  tempRigged = false;
                                }
                              });
                            },
                            checkColor: Colors.white,
                            fillColor: WidgetStateProperty.resolveWith<Color>((
                              states,
                            ) {
                              return _isDarkMode
                                  ? Colors.white
                                  : headerTextColor;
                            }),
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            title: Text(
                              'Rigged',
                              style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.white
                                    : textColorPrimary,
                              ),
                            ),
                            value: tempRigged,
                            onChanged: (value) {
                              setDialogState(() {
                                tempRigged = value ?? false;
                                // Make checkboxes mutually exclusive
                                if (tempRigged) {
                                  tempStacked = false;
                                }
                              });
                            },
                            checkColor: Colors.white,
                            fillColor: WidgetStateProperty.resolveWith<Color>((
                              states,
                            ) {
                              return _isDarkMode
                                  ? Colors.white
                                  : headerTextColor;
                            }),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: _isDarkMode
                          ? Colors.grey[400]
                          : textColorSecondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Validate name and get unique name if needed
                    String proposedName = nameController.text.trim();
                    if (proposedName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter a surface name'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Get unique name, excluding the current surface being edited
                    String finalName = _getUniqueNameExcluding(
                      proposedName,
                      surfaceIndex,
                    );

                    // Update surface with new values
                    setState(() {
                      surface.name = finalName;
                      surface.width = double.tryParse(widthController.text);
                      surface.height = double.tryParse(heightController.text);
                      surface.selectedLED = tempSelectedLED;
                      surface.isStacked = tempStacked;
                      surface.isRigged = tempRigged;
                      surface.updateCalculation();

                      // Update UI controllers if this is the active surface
                      if (surfaceIndex == _activeSurfaceIndex) {
                        _updateControllersFromActiveSurface();
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDarkMode
                        ? const Color(
                            0xFF23272F,
                          ) // Gunmetal/slate gray panel background
                        : buttonBackgroundColor,
                    foregroundColor: _isDarkMode
                        ? Colors.white
                        : buttonTextColor,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper methods for the calculation box
  Widget _columnHeader(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            text,
            style: TextStyle(
              fontSize: 11, // Increased from 10 to 11
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : headerTextColor,
            ),
          ),
          Container(
            height: 1,
            width: double.infinity,
            color: _isDarkMode ? Colors.white : headerTextColor,
          ),
        ],
      ),
    );
  }

  // Helper method for mobile summary rows
  Widget _mobileSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: _isDarkMode ? Colors.white70 : textColorPrimary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: _isDarkMode ? Colors.white : textColorPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for calculation info rows
  Widget _calcInfoRow(String label, String value, {bool greyedOut = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100, // Reduced from 120 to 100 to save space
            child: SelectableText(
              label,
              style: TextStyle(
                fontSize: 9, // Increased from 8 to 9
                fontWeight: FontWeight.bold,
                color: greyedOut
                    ? (_isDarkMode
                          ? Colors.white70.withOpacity(0.4)
                          : textColorPrimary.withOpacity(0.4))
                    : (_isDarkMode ? Colors.white70 : textColorPrimary),
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              greyedOut ? '0' : value, // Show 0 when greyed out
              textAlign: TextAlign.right, // Align answers to the right
              style: TextStyle(
                fontSize: 9, // Increased from 8 to 9
                color: greyedOut
                    ? (_isDarkMode
                          ? Colors.white.withOpacity(0.4)
                          : textColorPrimary.withOpacity(0.4))
                    : (_isDarkMode ? Colors.white : textColorPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for summary rows (left-aligned text for summary column)
  Widget _summaryRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: SelectableText(
        text,
        style: TextStyle(
          fontSize: 9,
          color: _isDarkMode ? Colors.white : textColorPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size information for responsive behavior
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;
    final isTablet = screenWidth > 600 && screenWidth <= 1024;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main content with scrolling
            Directionality(
              textDirection: TextDirection.rtl,
              child: Scrollbar(
                controller: _verticalScrollController,
                thumbVisibility: false, // Auto-hide when not scrolling
                trackVisibility: false, // Hide track completely
                thickness: 8, // Thinner scrollbar
                radius: const Radius.circular(4),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      scrollbars: false, // Hide the default scrollbar
                    ),
                    child: SingleChildScrollView(
                      controller: _verticalScrollController,
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        controller: _horizontalScrollController,
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          width: screenWidth, // Use full browser width
                          height:
                              1500, // Ensure minimum height for vertical scrolling
                          color: _isDarkMode
                              ? Colors.grey[900]
                              : const Color(0xFFF7F6F3), // Very light warm gray
                          child: Stack(
                            children: [
                              // Top left buttons (moved from bottom left)
                              Positioned(
                                top:
                                    5, // Position at the very top, above search box
                                left: 20,
                                child: Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _showProjectDataDialog(),
                                      icon: const Icon(
                                        Icons.info_outline,
                                        size: 18,
                                      ),
                                      label: const Text('Project Data'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isDarkMode
                                            ? const Color(
                                                0xFF23272F,
                                              ) // Gunmetal/slate gray panel background
                                            : buttonBackgroundColor,
                                        foregroundColor: _isDarkMode
                                            ? Colors.white
                                            : buttonTextColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      onPressed: () => _saveProjectAsJson(),
                                      icon: const Icon(Icons.save, size: 18),
                                      label: const Text('Save'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isDarkMode
                                            ? const Color(
                                                0xFF23272F,
                                              ) // Gunmetal/slate gray panel background
                                            : buttonBackgroundColor,
                                        foregroundColor: _isDarkMode
                                            ? Colors.white
                                            : buttonTextColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      onPressed: () => _saveProjectAsJson(),
                                      icon: const Icon(Icons.save, size: 18),
                                      label: const Text('Save'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isDarkMode
                                            ? const Color(
                                                0xFF23272F,
                                              ) // Gunmetal/slate gray panel background
                                            : buttonBackgroundColor,
                                        foregroundColor: _isDarkMode
                                            ? Colors.white
                                            : buttonTextColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      onPressed: () => _openProject(),
                                      icon: const Icon(
                                        Icons.folder_open,
                                        size: 18,
                                      ),
                                      label: const Text('Open Project'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isDarkMode
                                            ? const Color(
                                                0xFF23272F,
                                              ) // Gunmetal/slate gray panel background
                                            : buttonBackgroundColor,
                                        foregroundColor: _isDarkMode
                                            ? Colors.white
                                            : buttonTextColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => PixelMapsDialog(
                                            surfaces: _surfaces,
                                            projectData: _projectData,
                                            isDarkMode: _isDarkMode,
                                            logoBase64: _logoBase64,
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isDarkMode
                                            ? const Color(
                                                0xFF23272F,
                                              ) // Gunmetal/slate gray panel background
                                            : buttonBackgroundColor,
                                        foregroundColor: _isDarkMode
                                            ? Colors.white
                                            : buttonTextColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Generate PixelMaps',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Generate Obj functionality coming soon!',
                                            ),
                                            backgroundColor:
                                                headerBackgroundColor,
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isDarkMode
                                            ? const Color(
                                                0xFF23272F,
                                              ) // Gunmetal/slate gray panel background
                                            : buttonBackgroundColor,
                                        foregroundColor: _isDarkMode
                                            ? Colors.white
                                            : buttonTextColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Generate Obj',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _isDarkMode
                                              ? Colors.white
                                              : buttonTextColor,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return LEDSummaryDialog(
                                              surfaces: _surfaces,
                                              isDarkMode: _isDarkMode,
                                              projectData: _projectData,
                                              logoBase64: _logoBase64,
                                              logoFileName: _logoFileName,
                                              onProjectDataChanged:
                                                  (updatedData) {
                                                    setState(() {
                                                      _projectData =
                                                          updatedData;
                                                    });
                                                  },
                                            );
                                          },
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isDarkMode
                                            ? const Color(
                                                0xFF23272F,
                                              ) // Gunmetal/slate gray panel background
                                            : buttonBackgroundColor,
                                        foregroundColor: _isDarkMode
                                            ? Colors.white
                                            : buttonTextColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Generate LED Summary',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _isDarkMode
                                              ? Colors.white
                                              : buttonTextColor,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return LEDStudyDialog(
                                              surfaces: _surfaces,
                                              isDarkMode: _isDarkMode,
                                              projectData: _projectData,
                                              logoBase64: _logoBase64,
                                              logoFileName: _logoFileName,
                                              onProjectDataChanged:
                                                  (updatedData) {
                                                    setState(() {
                                                      _projectData =
                                                          updatedData;
                                                    });
                                                  },
                                            );
                                          },
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isDarkMode
                                            ? const Color(
                                                0xFF23272F,
                                              ) // Gunmetal/slate gray panel background
                                            : buttonBackgroundColor,
                                        foregroundColor: _isDarkMode
                                            ? Colors.white
                                            : buttonTextColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Generate Project Details',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _isDarkMode
                                              ? Colors.white
                                              : buttonTextColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (_surfaces.isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Please add at least one surface before generating power diagram.',
                                              ),
                                              backgroundColor:
                                                  headerBackgroundColor,
                                            ),
                                          );
                                          return;
                                        }
                                        
                                        showDialog(
                                          context: context,
                                          builder: (context) => PowerDiagramDialog(
                                            surfaces: _surfaces,
                                            isDarkMode: _isDarkMode,
                                            onPowerLinesUpdated: (updatedSurfaces) {
                                              // Power lines are already updated in the surface objects
                                              // Just trigger a UI refresh and save project
                                              setState(() {
                                                // Force UI refresh
                                              });
                                              // Save project data
                                              _saveProjectAsJson();
                                            },
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isDarkMode
                                            ? const Color(
                                                0xFF23272F,
                                              ) // Gunmetal/slate gray panel background
                                            : buttonBackgroundColor,
                                        foregroundColor: _isDarkMode
                                            ? Colors.white
                                            : buttonTextColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Generate Power Diagram',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _isDarkMode
                                              ? Colors.white
                                              : buttonTextColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Generate Signal Diagram functionality coming soon!',
                                            ),
                                            backgroundColor:
                                                headerBackgroundColor,
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isDarkMode
                                            ? const Color(
                                                0xFF23272F,
                                              ) // Gunmetal/slate gray panel background
                                            : buttonBackgroundColor,
                                        foregroundColor: _isDarkMode
                                            ? Colors.white
                                            : buttonTextColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Generate Signal Diagram',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _isDarkMode
                                              ? Colors.white
                                              : buttonTextColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Combined Surface Input Box - Square layout in top left corner
                              Positioned(
                                top: 60, // Position below the top buttons
                                left: 20,
                                child: Material(
                                  elevation: 10,
                                  color: Colors.transparent,
                                  child: Container(
                                    width: isMobile
                                        ? 90.w
                                        : 340, // Increased from 320 to 340 (20px wider)
                                    height: isMobile
                                        ? 300
                                        : 300, // Reduced by 10px from 310px to 300px
                                    decoration: BoxDecoration(
                                      color: _isDarkMode
                                          ? Colors.grey[800]
                                          : const Color(
                                              0xFFF7F6F3,
                                            ), // Very light warm gray
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _isDarkMode
                                            ? Colors.grey[700]!
                                            : borderColorLight,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          spreadRadius: 2,
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(
                                      12,
                                    ), // Reduced padding
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // LED Search (removed title header)
                                          Container(
                                            decoration: BoxDecoration(
                                              color: _isDarkMode
                                                  ? Colors.grey[700]
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: _isDarkMode
                                                    ? Colors.grey[600]!
                                                    : borderColorLight,
                                              ),
                                            ),
                                            child: TextField(
                                              controller: _searchController,
                                              textAlign: TextAlign
                                                  .left, // Align text to the left to be next to search icon
                                              style: TextStyle(
                                                color: _isDarkMode
                                                    ? Colors.white
                                                    : textColorPrimary,
                                                fontSize: 14,
                                              ),
                                              onChanged: (value) {
                                                _searchLEDs(value);
                                              },
                                              decoration: InputDecoration(
                                                hintText: 'Search LED Product',
                                                hintStyle: TextStyle(
                                                  color: _isDarkMode
                                                      ? Colors.grey[400]
                                                      : textColorSecondary,
                                                  fontSize: 14,
                                                ),
                                                border: InputBorder.none,
                                                contentPadding:
                                                    const EdgeInsets.fromLTRB(
                                                      0, 10, 10, 10,
                                                    ), // Remove left padding to position text next to search icon
                                                prefixIcon: Icon(
                                                  Icons.search,
                                                  color: _isDarkMode
                                                      ? Colors.grey[400]
                                                      : textColorSecondary,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ), // Reduced spacing
                                          // Surface Name
                                          Container(
                                            decoration: BoxDecoration(
                                              color: _isDarkMode
                                                  ? Colors.grey[700]
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: _isDarkMode
                                                    ? Colors.grey[600]!
                                                    : borderColorLight,
                                              ),
                                            ),
                                            child: TextField(
                                              controller: _nameController,
                                              style: TextStyle(
                                                color: _isDarkMode
                                                    ? Colors.white
                                                    : textColorPrimary,
                                                fontSize: 14,
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  // Don't update existing surfaces from form changes
                                                });
                                              },
                                              decoration: InputDecoration(
                                                hintText: 'Surface name',
                                                hintStyle: TextStyle(
                                                  color: _isDarkMode
                                                      ? Colors.grey[400]
                                                      : textColorSecondary,
                                                  fontSize: 14,
                                                ),
                                                border: InputBorder.none,
                                                contentPadding:
                                                    const EdgeInsets.all(
                                                      10,
                                                    ), // Reduced padding
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ), // Reduced spacing
                                          // Width and Height row
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: _isDarkMode
                                                        ? Colors.grey[700]
                                                        : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: _isDarkMode
                                                          ? Colors.grey[600]!
                                                          : borderColorLight,
                                                    ),
                                                  ),
                                                  child: TextField(
                                                    controller:
                                                        _widthController,
                                                    style: TextStyle(
                                                      color: _isDarkMode
                                                          ? Colors.white
                                                          : textColorPrimary,
                                                      fontSize: 14,
                                                    ),
                                                    keyboardType:
                                                        const TextInputType.numberWithOptions(
                                                          decimal: true,
                                                        ),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        // Don't update existing surfaces from form changes
                                                      });
                                                    },
                                                    decoration: InputDecoration(
                                                      hintText: 'Width (m)',
                                                      hintStyle: TextStyle(
                                                        color: _isDarkMode
                                                            ? Colors.grey[400]
                                                            : textColorSecondary,
                                                        fontSize: 14,
                                                      ),
                                                      border: InputBorder.none,
                                                      contentPadding:
                                                          const EdgeInsets.all(
                                                            10,
                                                          ), // Reduced padding
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: _isDarkMode
                                                        ? Colors.grey[700]
                                                        : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: _isDarkMode
                                                          ? Colors.grey[600]!
                                                          : borderColorLight,
                                                    ),
                                                  ),
                                                  child: TextField(
                                                    controller:
                                                        _heightController,
                                                    style: TextStyle(
                                                      color: _isDarkMode
                                                          ? Colors.white
                                                          : textColorPrimary,
                                                      fontSize: 14,
                                                    ),
                                                    keyboardType:
                                                        const TextInputType.numberWithOptions(
                                                          decimal: true,
                                                        ),
                                                    onChanged: (value) {
                                                      setState(() {
                                                        // Don't update existing surfaces from form changes
                                                      });
                                                    },
                                                    decoration: InputDecoration(
                                                      hintText: 'Height (m)',
                                                      hintStyle: TextStyle(
                                                        color: _isDarkMode
                                                            ? Colors.grey[400]
                                                            : textColorSecondary,
                                                        fontSize: 14,
                                                      ),
                                                      border: InputBorder.none,
                                                      contentPadding:
                                                          const EdgeInsets.all(
                                                            10,
                                                          ), // Reduced padding
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ), // Reduced spacing
                                          // Stacked and Rigged checkboxes
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Transform.scale(
                                                      scale: 0.8,
                                                      child: Checkbox(
                                                        value: _isStacked,
                                                        fillColor:
                                                            WidgetStateProperty.resolveWith<
                                                              Color
                                                            >((
                                                              Set<WidgetState>
                                                              states,
                                                            ) {
                                                              if (_isDarkMode) {
                                                                return Colors
                                                                    .grey[600]!;
                                                              }
                                                              return buttonBackgroundColor;
                                                            }),
                                                        checkColor: _isDarkMode
                                                            ? Colors.white
                                                            : buttonTextColor,
                                                        onChanged: (value) {
                                                          setState(() {
                                                            _isStacked =
                                                                value ?? false;
                                                            if (_isStacked) {
                                                              _isRigged = false;
                                                            }
                                                          });
                                                        },
                                                        materialTapTargetSize:
                                                            MaterialTapTargetSize
                                                                .shrinkWrap,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Stacked',
                                                      style: TextStyle(
                                                        fontSize:
                                                            13, // Reduced font size
                                                        color: _isDarkMode
                                                            ? Colors.white
                                                            : buttonTextColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Transform.scale(
                                                      scale: 0.8,
                                                      child: Checkbox(
                                                        value: _isRigged,
                                                        fillColor:
                                                            WidgetStateProperty.resolveWith<
                                                              Color
                                                            >((
                                                              Set<WidgetState>
                                                              states,
                                                            ) {
                                                              if (_isDarkMode) {
                                                                return Colors
                                                                    .grey[600]!;
                                                              }
                                                              return buttonBackgroundColor;
                                                            }),
                                                        checkColor: _isDarkMode
                                                            ? Colors.white
                                                            : buttonTextColor,
                                                        onChanged: (value) {
                                                          setState(() {
                                                            _isRigged =
                                                                value ?? false;
                                                            if (_isRigged) {
                                                              _isStacked =
                                                                  false;
                                                            }
                                                          });
                                                        },
                                                        materialTapTargetSize:
                                                            MaterialTapTargetSize
                                                                .shrinkWrap,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Rigged',
                                                      style: TextStyle(
                                                        fontSize:
                                                            13, // Reduced font size
                                                        color: _isDarkMode
                                                            ? Colors.white
                                                            : buttonTextColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ), // Reduced spacing
                                          // Add Surface button (moved to left side)
                                          Row(
                                            children: [
                                              SizedBox(
                                                width:
                                                    150, // Half the width of the container
                                                height: 32, // Smaller height
                                                child: ElevatedButton.icon(
                                                  onPressed: _addSurface,
                                                  icon: Icon(
                                                    Icons.add,
                                                    size: 14, // Smaller icon
                                                    color: Colors.white,
                                                  ),
                                                  label: Text(
                                                    'Add Surface',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize:
                                                          12, // Smaller font
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: _isDarkMode
                                                        ? const Color(
                                                            0xFF23272F,
                                                          )
                                                        : Colors.green,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal:
                                                          12, // Reduced padding
                                                      vertical:
                                                          8, // Reduced padding
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const Spacer(), // Pushes button to the left
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Surface Calculation Box - positioned next to the Surface Setup box
                              // LED Data Box (4 columns) - moved to right side
                              if (!isMobile)
                                Positioned(
                                  top:
                                      60, // Position below the top buttons, same as Surface Setup box
                                  left:
                                      380, // Moved another 5px right from 375 to 380
                                  child: Container(
                                    width: isTablet
                                        ? screenWidth * 0.8
                                        : (screenWidth > 1600
                                              ? 1200
                                              : screenWidth *
                                                    0.75), // Increased width to align with buttons
                                    height:
                                        300, // Reduced by 10px from 310px to 300px to match Surface Setup box
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color:
                                          (_isDarkMode
                                                  ? const Color(0xFF23272F)
                                                  : Colors
                                                        .white) // Gunmetal/slate gray panel background
                                              .withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: _isDarkMode
                                            ? const Color(
                                                0x18FFFFFF,
                                              ) // Translucent white border
                                            : borderColorDark, // New muted taupe border
                                        width: 2,
                                      ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SelectableText(
                                          _activeLED?.name ?? 'No LED Selected',
                                          style: TextStyle(
                                            fontSize:
                                                15, // Increased from 14 to 15
                                            fontWeight: FontWeight.bold,
                                            color: _isDarkMode
                                                ? Colors.white
                                                : textColorPrimary, // New deep neutral gray
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Expanded(
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Column 1 - Optical
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    _columnHeader('Optical'),
                                                    _calcInfoRow(
                                                      'Pixel Pitch :',
                                                      _activeLED != null
                                                          ? '${_activeLED!.pitch} mm'
                                                          : '0 mm',
                                                    ),
                                                    _calcInfoRow(
                                                      'Panel Resolution :',
                                                      _activeLED != null
                                                          ? '${_activeLED!.wPixel} x ${_activeLED!.hPixel}'
                                                          : '0 x 0',
                                                    ),
                                                    _calcInfoRow(
                                                      'LED Configuration :',
                                                      _activeLED
                                                              ?.ledConfiguration ??
                                                          '0',
                                                    ),
                                                    _calcInfoRow(
                                                      'Brightness :',
                                                      _activeLED != null
                                                          ? '${_activeLED!.brightness} nit'
                                                          : '0 nit',
                                                    ),
                                                    _calcInfoRow(
                                                      'Viewing Angle :',
                                                      _activeLED
                                                              ?.viewingAngle ??
                                                          '0° / 0°',
                                                    ),
                                                    _calcInfoRow(
                                                      'Refresh Rate :',
                                                      _activeLED != null
                                                          ? '${_activeLED!.refreshRate}Hz'
                                                          : '0Hz',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ), // Reduced from 10 to 5
                                              // Column 2 - Physical
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    _columnHeader('Physical'),
                                                    _calcInfoRow(
                                                      'Panel Height :',
                                                      _activeLED != null
                                                          ? '${_activeLED!.fullHeight}mm'
                                                          : '0mm',
                                                    ),
                                                    _calcInfoRow(
                                                      'Panel Width :',
                                                      _activeLED != null
                                                          ? '${_activeLED!.width}mm'
                                                          : '0mm',
                                                    ),
                                                    _calcInfoRow(
                                                      'Panel Depth :',
                                                      _activeLED != null
                                                          ? '${_activeLED!.depth}mm'
                                                          : '0mm',
                                                    ),
                                                    _calcInfoRow(
                                                      'Panel Weight :',
                                                      _activeLED != null
                                                          ? '${_activeLED!.fullPanelWeight}kg'
                                                          : '0kg',
                                                    ),
                                                    _calcInfoRow(
                                                      'Touring Frame :',
                                                      _activeLED
                                                              ?.touringFrame ??
                                                          '0',
                                                    ),
                                                    _calcInfoRow(
                                                      'Curve Capability :',
                                                      _activeLED
                                                              ?.curveCapability ??
                                                          '0',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ), // Reduced from 10 to 5
                                              // Column 3 - Environmental
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    _columnHeader(
                                                      'Environmental',
                                                    ),
                                                    _calcInfoRow(
                                                      'IP Rating :',
                                                      _activeLED?.ipRating ??
                                                          '0',
                                                    ),
                                                    _calcInfoRow(
                                                      'Operating Voltage :',
                                                      _activeLED
                                                              ?.operatingVoltage ??
                                                          '0V',
                                                    ),
                                                    _calcInfoRow(
                                                      'Operating Temp :',
                                                      _activeLED
                                                              ?.operatingTemp ??
                                                          '0°C',
                                                    ),
                                                    _calcInfoRow(
                                                      'Max Power Cons :',
                                                      _activeLED != null
                                                          ? '${_activeLED!.fullPanelMaxW}W'
                                                          : '0W',
                                                    ),
                                                    _calcInfoRow(
                                                      'Avg Power Cons :',
                                                      _activeLED != null
                                                          ? '${_activeLED!.fullPanelAvgW}W'
                                                          : '0W',
                                                    ),
                                                    _calcInfoRow(
                                                      'Verification :',
                                                      _activeLED
                                                              ?.verification ??
                                                          '0',
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 5,
                                              ), // Reduced from 10 to 5
                                              // Column 4 - Technical
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    _columnHeader('Technical'),
                                                    _calcInfoRow(
                                                      'Power Connection :',
                                                      _activeLED
                                                              ?.powerConnection ??
                                                          '0',
                                                    ),
                                                    _calcInfoRow(
                                                      'Data Connection :',
                                                      _activeLED
                                                              ?.dataConnection ??
                                                          '0',
                                                    ),
                                                    _calcInfoRow(
                                                      'Processing :',
                                                      _activeLED?.processing ??
                                                          '0',
                                                    ),
                                                    _calcInfoRow(
                                                      'Panels per port :',
                                                      _activeLED != null
                                                          ? '${_activeLED!.panelsPerPort}'
                                                          : '0',
                                                    ),
                                                    _calcInfoRow(
                                                      'Panels per 16A (230V) :',
                                                      _activeLED != null
                                                          ? '${_activeLED!.panelsPer16A}'
                                                          : '0',
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

                              // Summary Box - positioned under the Calculation box
                              Positioned(
                                top: isMobile
                                    ? 850 // Moved down 15px more from 835 to 850
                                    : 910, // Moved down 15px more from 895 to 910
                                left:
                                    20, // Same left alignment as calculation box
                                child: Container(
                                  width: isMobile
                                      ? screenWidth - 40
                                      : (screenWidth > 1600
                                            ? 1560 // 380 + 1200 - 20 = 1560 to align with LED Data Box right edge
                                            : 380 +
                                                  (screenWidth * 0.75) -
                                                  20), // Calculate to align with LED Data Box right edge
                                  height: isMobile
                                      ? 300
                                      : (isTablet
                                            ? 500
                                            : 500), // Extended from 400 to 500 (100px taller)
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color:
                                        (_isDarkMode
                                                ? const Color(0xFF23272F)
                                                : Colors
                                                      .white) // Gunmetal/slate gray panel background
                                            .withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: _isDarkMode
                                          ? const Color(
                                              0x18FFFFFF,
                                            ) // Translucent white border
                                          : borderColorDark, // New muted taupe border
                                      width: 2,
                                    ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header with totals
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'LED Summary',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: _isDarkMode
                                                  ? Colors.white
                                                  : textColorPrimary, // New deep neutral gray
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Total counts - Responsive layout
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: headerBackgroundColor,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  'Surfaces: ${_surfaces.length}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: _isDarkMode
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF635955,
                                                          ), // 50% darker than headerTextColor
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: headerBackgroundColor,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  'SQM: ${_surfaces.fold<double>(0.0, (sum, surface) => sum + (surface.area ?? 0.0)).toStringAsFixed(1)}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: _isDarkMode
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF635955,
                                                          ), // 50% darker than headerTextColor
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: headerBackgroundColor,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  'Power: ${(_surfaces.fold<double>(0.0, (sum, surface) => sum + ((surface.calculation?.maxPower ?? 0.0) / 1000))).toStringAsFixed(1)}kW',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: _isDarkMode
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF635955,
                                                          ), // 50% darker than headerTextColor
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: headerBackgroundColor,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  'Pixels: ${_surfaces.fold<int>(0, (sum, surface) => sum + ((surface.calculation?.pixelsWidth ?? 0) * (surface.calculation?.pixelsHeight ?? 0)))}',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: _isDarkMode
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF635955,
                                                          ), // 50% darker than headerTextColor
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: headerBackgroundColor,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  'Panels: ${_surfaces.fold<int>(0, (sum, surface) => sum + (surface.calculation?.totalFullPanels ?? 0))} full | ${_surfaces.fold<int>(0, (sum, surface) => sum + (surface.calculation?.totalHalfPanels ?? 0))} half',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: _isDarkMode
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF635955,
                                                          ), // 50% darker than headerTextColor
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // Scrollable data table
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: _isDarkMode
                                                  ? Colors.grey[600]!
                                                  : borderColorLight, // New muted taupe border
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Scrollbar(
                                              child: SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: SingleChildScrollView(
                                                  scrollDirection:
                                                      Axis.vertical,
                                                  child: DataTable(
                                                    columnSpacing: 8,
                                                    headingRowHeight: 35,
                                                    dataRowHeight: 30,
                                                    headingTextStyle: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: _isDarkMode
                                                          ? Colors.white
                                                          : textColorPrimary, // New deep neutral gray
                                                    ),
                                                    dataTextStyle: TextStyle(
                                                      fontSize: 9,
                                                      color: _isDarkMode
                                                          ? Colors.white
                                                          : textColorPrimary, // New deep neutral gray
                                                    ),
                                                    headingRowColor:
                                                        WidgetStateProperty.all(
                                                          buttonBackgroundColor, // Use the consistent beige color
                                                        ),
                                                    columns: const [
                                                      DataColumn(
                                                        label: SizedBox(
                                                          width: 40,
                                                          child: Text(
                                                            'Scr No',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: SizedBox(
                                                          width: 80,
                                                          child: Text(
                                                            'Screen Name',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: SizedBox(
                                                          width: 100,
                                                          child: Text(
                                                            'LED Product',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: SizedBox(
                                                          width: 50,
                                                          child: Text(
                                                            'H Res (px)',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: SizedBox(
                                                          width: 50,
                                                          child: Text(
                                                            'V Res (px)',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: SizedBox(
                                                          width: 50,
                                                          child: Text(
                                                            'Width (m)',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: SizedBox(
                                                          width: 50,
                                                          child: Text(
                                                            'Height (m)',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: SizedBox(
                                                          width: 50,
                                                          child: Text(
                                                            'SQM (m²)',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: SizedBox(
                                                          width: 60,
                                                          child: Text(
                                                            'Proc Main',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: SizedBox(
                                                          width: 60,
                                                          child: Text(
                                                            'Proc B-Up',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: SizedBox(
                                                          width: 50,
                                                          child: Text(
                                                            'Full Panel',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: SizedBox(
                                                          width: 50,
                                                          child: Text(
                                                            'Half Panel',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: SizedBox(
                                                          width: 60,
                                                          child: Text(
                                                            'Power (kW)',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: SizedBox(
                                                          width: 60,
                                                          child: Text(
                                                            'Power 3P',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: SizedBox(
                                                          width: 50,
                                                          child: Text(
                                                            'Header',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: SizedBox(
                                                          width: 40,
                                                          child: Text(
                                                            'GAC',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: SizedBox(
                                                          width: 50,
                                                          child: Text(
                                                            'Shackle',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: SizedBox(
                                                          width: 60,
                                                          child: Text(
                                                            'Weight (kg)',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: SizedBox(
                                                          width: 60,
                                                          child: Text(
                                                            'Volume (m³)',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: SizedBox(
                                                          width: 70,
                                                          child: Text(
                                                            'Dolly/Cages',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      DataColumn(
                                                        label: SizedBox(
                                                          width: 100,
                                                          child: Text(
                                                            'Notes',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                    rows: [
                                                      // Surface data rows
                                                      if (_surfaces.isNotEmpty)
                                                        ..._surfaces.asMap().entries.map((
                                                          entry,
                                                        ) {
                                                          int index = entry.key;
                                                          Surface surface =
                                                              entry.value;
                                                          return DataRow(
                                                            cells: [
                                                              DataCell(
                                                                SizedBox(
                                                                  width: 40,
                                                                  child: Text(
                                                                    '${index + 1}',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                SizedBox(
                                                                  width: 80,
                                                                  child: Text(
                                                                    surface
                                                                            .name
                                                                            .isEmpty
                                                                        ? 'Surface ${index + 1}'
                                                                        : surface
                                                                              .name,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                SizedBox(
                                                                  width: 100,
                                                                  child: Text(
                                                                    surface
                                                                            .selectedLED
                                                                            ?.name ??
                                                                        '',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                SizedBox(
                                                                  width: 50,
                                                                  child: Text(
                                                                    '${surface.calculation?.pixelsWidth ?? 0}',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                SizedBox(
                                                                  width: 50,
                                                                  child: Text(
                                                                    '${surface.calculation?.pixelsHeight ?? 0}',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                SizedBox(
                                                                  width: 50,
                                                                  child: Text(
                                                                    surface.width
                                                                            ?.toString() ??
                                                                        '0',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                SizedBox(
                                                                  width: 50,
                                                                  child: Text(
                                                                    surface.height
                                                                            ?.toString() ??
                                                                        '0',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                SizedBox(
                                                                  width: 50,
                                                                  child: Text(
                                                                    surface.area
                                                                            ?.toStringAsFixed(
                                                                              1,
                                                                            ) ??
                                                                        '0',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                SizedBox(
                                                                  width: 60,
                                                                  child: Text(
                                                                    '${surface.calculation?.novastarMain ?? 0}',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                SizedBox(
                                                                  width: 60,
                                                                  child: Text(
                                                                    '${surface.calculation?.novastarBU ?? 0}',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                SizedBox(
                                                                  width: 50,
                                                                  child: Text(
                                                                    '${surface.calculation?.totalFullPanels ?? 0}',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                SizedBox(
                                                                  width: 50,
                                                                  child: Text(
                                                                    '${surface.calculation?.totalHalfPanels ?? 0}',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                SizedBox(
                                                                  width: 60,
                                                                  child: Text(
                                                                    surface.calculation !=
                                                                            null
                                                                        ? (surface.calculation!.maxPower /
                                                                                  1000)
                                                                              .toStringAsFixed(2)
                                                                        : '0.00',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                SizedBox(
                                                                  width: 60,
                                                                  child: Text(
                                                                    surface.calculation !=
                                                                            null
                                                                        ? ((surface.calculation!.maxPower /
                                                                                      1000) *
                                                                                  1.732)
                                                                              .toStringAsFixed(2)
                                                                        : '0.00',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                SizedBox(
                                                                  width: 50,
                                                                  child: Text(
                                                                    '${surface.calculation?.singleHeader ?? 0}',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                SizedBox(
                                                                  width: 40,
                                                                  child: Text(
                                                                    '${surface.calculation?.gacSpanset4m ?? 0}',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                SizedBox(
                                                                  width: 50,
                                                                  child: Text(
                                                                    '${surface.calculation?.shackle25t ?? 0}',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                SizedBox(
                                                                  width: 60,
                                                                  child: Text(
                                                                    surface.totalWeight
                                                                            ?.toStringAsFixed(
                                                                              0,
                                                                            ) ??
                                                                        '0',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                SizedBox(
                                                                  width: 60,
                                                                  child: Text(
                                                                    surface
                                                                            .calculation
                                                                            ?.shippingVolume
                                                                            .toStringAsFixed(
                                                                              2,
                                                                            ) ??
                                                                        '0.00',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                SizedBox(
                                                                  width: 70,
                                                                  child: Text(
                                                                    '${surface.calculation?.dollysPerCase ?? 0}',
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ),
                                                              DataCell(
                                                                Container(
                                                                  width: 100,
                                                                  padding:
                                                                      const EdgeInsets.all(
                                                                        2,
                                                                      ),
                                                                  child: TextFormField(
                                                                    initialValue:
                                                                        surface
                                                                            .notes,
                                                                    style: const TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                    ),
                                                                    decoration: const InputDecoration(
                                                                      border: InputBorder
                                                                          .none,
                                                                      hintText:
                                                                          'Add notes...',
                                                                      contentPadding: EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            4,
                                                                        vertical:
                                                                            2,
                                                                      ),
                                                                    ),
                                                                    maxLines: 1,
                                                                    onChanged: (value) {
                                                                      surface.notes =
                                                                          value;
                                                                    },
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        })
                                                      else
                                                        // Show placeholder row when no surfaces
                                                        DataRow(
                                                          cells: List.generate(
                                                            21,
                                                            (index) =>
                                                                const DataCell(
                                                                  Text('-'),
                                                                ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Surface Summary Box with integrated tabs - repositioned below the top boxes
                              // ⚠️ UPDATED POSITION - Surface Summary Box (9 columns with tabs) ⚠️
                              Positioned(
                                top: isMobile
                                    ? 425
                                    : 385, // Moved down another 5px from 420/380 to 425/385
                                left:
                                    20, // Back to left side since we have space now
                                child: Container(
                                  width: isMobile
                                      ? screenWidth - 40
                                      : (screenWidth > 1600
                                            ? 1560 // 380 + 1200 - 20 = 1560 to align with LED Data Box right edge
                                            : 380 +
                                                  (screenWidth * 0.75) -
                                                  20), // Calculate to align with LED Data Box right edge
                                  height: isTablet ? 400 : 500,
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color:
                                        (_isDarkMode
                                                ? const Color(0xFF23272F)
                                                : Colors
                                                      .white) // Gunmetal/slate gray panel background
                                            .withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: _isDarkMode
                                          ? Colors.white
                                          : borderColorDark, // New muted taupe border
                                      width: 2,
                                    ),
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
                                    children: [
                                      // Scrollable Tabs at the top of the calculation box
                                      if (_surfaces.isNotEmpty)
                                        SizedBox(
                                          height: 40,
                                          width: double.infinity,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              children: [
                                                for (
                                                  int i = 0;
                                                  i < _surfaces.length;
                                                  i++
                                                )
                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        _activeSurfaceIndex = i;
                                                        _updateControllersFromActiveSurface();
                                                      });
                                                    },
                                                    onDoubleTap: () {
                                                      _showEditSurfaceDialog(i);
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 6,
                                                          ),
                                                      margin:
                                                          const EdgeInsets.only(
                                                            right: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            _activeSurfaceIndex ==
                                                                i
                                                            ? (_isDarkMode
                                                                  ? Colors
                                                                        .grey[800]
                                                                  : Colors
                                                                        .white)
                                                            : (_isDarkMode
                                                                  ? Colors
                                                                        .grey[700]
                                                                  : Colors
                                                                        .grey[200]),
                                                        borderRadius:
                                                            const BorderRadius.only(
                                                              topLeft:
                                                                  Radius.circular(
                                                                    8,
                                                                  ),
                                                              topRight:
                                                                  Radius.circular(
                                                                    8,
                                                                  ),
                                                            ),
                                                        border: Border.all(
                                                          color:
                                                              _activeSurfaceIndex ==
                                                                  i
                                                              ? Colors.white
                                                              : Colors
                                                                    .grey[500]!,
                                                          width:
                                                              _activeSurfaceIndex ==
                                                                  i
                                                              ? 2
                                                              : 1,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            _surfaces[i]
                                                                    .name
                                                                    .isEmpty
                                                                ? 'Surface ${i + 1}'
                                                                : _surfaces[i]
                                                                      .name,
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  _activeSurfaceIndex ==
                                                                      i
                                                                  ? FontWeight
                                                                        .bold
                                                                  : FontWeight
                                                                        .normal,
                                                              color: _isDarkMode
                                                                  ? Colors.white
                                                                  : textColorPrimary,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          GestureDetector(
                                                            onTap: () {
                                                              setState(() {
                                                                _surfaces
                                                                    .removeAt(
                                                                      i,
                                                                    );
                                                                // Adjust active surface index
                                                                if (_surfaces
                                                                    .isEmpty) {
                                                                  _activeSurfaceIndex =
                                                                      0;
                                                                  // Clear all form fields when no surfaces exist
                                                                  _nameController
                                                                      .clear();
                                                                  _searchController
                                                                      .clear();
                                                                  _widthController
                                                                      .clear();
                                                                  _heightController
                                                                      .clear();
                                                                  _isStacked =
                                                                      false;
                                                                  _isRigged =
                                                                      false;
                                                                } else {
                                                                  // Ensure active index is valid
                                                                  if (_activeSurfaceIndex >=
                                                                      _surfaces
                                                                          .length) {
                                                                    _activeSurfaceIndex =
                                                                        _surfaces
                                                                            .length -
                                                                        1;
                                                                  }
                                                                  _updateControllersFromActiveSurface();
                                                                }
                                                              });
                                                            },
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    2,
                                                                  ),
                                                              child: Icon(
                                                                Icons.close,
                                                                size: 12,
                                                                color:
                                                                    _isDarkMode
                                                                    ? Colors
                                                                          .white
                                                                    : textColorPrimary,
                                                              ),
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

                                      // Divider line
                                      if (_surfaces.isNotEmpty)
                                        Container(
                                          height: 1,
                                          width: double.infinity,
                                          color: _isDarkMode
                                              ? Colors.white
                                              : Colors.grey[800],
                                          margin: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                        ),

                                      // Content area
                                      Expanded(
                                        child: _surfaces.isEmpty
                                            ? Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.add_circle_outline,
                                                      size: 64,
                                                      color: _isDarkMode
                                                          ? Colors.grey[400]
                                                          : textColorSecondary,
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'No surfaces created yet',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: _isDarkMode
                                                            ? Colors.grey[400]
                                                            : textColorSecondary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Click "Add Surface" to get started',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: _isDarkMode
                                                            ? Colors.grey[500]
                                                            : Colors.grey[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Column(
                                                children: [
                                                  // Top row - 3 columns
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        // Summary Column
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              _columnHeader(
                                                                'Summary',
                                                              ),
                                                              _summaryRow(
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '> ${_activeCalculation!.ledName}'
                                                                    : '> No LED Selected',
                                                              ),
                                                              _summaryRow(
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '> Screen Size: ${_activeCalculation!.metersWidth}mW x ${_activeCalculation!.metersHeight}mH | ${_activeCalculation!.sqm.toInt()} SQM Total'
                                                                    : '> Screen Size: 0mW x 0mH | 0 SQM Total',
                                                              ),
                                                              _summaryRow(
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '> Panels: ${_activeCalculation!.panelsWidth}W x ${_activeCalculation!.panelsHeight}H | ${_activeCalculation!.totalFullPanels} full | ${_activeCalculation!.totalHalfPanels} half'
                                                                    : '> Panels: 0W x 0H | 0 full | 0 half',
                                                              ),
                                                              _summaryRow(
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '> Pixelspace: ${_activeCalculation!.pixelsWidth}pxW x ${_activeCalculation!.pixelsHeight}pxH'
                                                                    : '> Pixelspace: 0pxW x 0pxH',
                                                              ),
                                                              _summaryRow(
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '> Aspect Ratio: ${_activeCalculation!.aspectRatio}'
                                                                    : '> Aspect Ratio: 0:0',
                                                              ),
                                                              _summaryRow(
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '> Max Power: ${_activeCalculation!.maxAmps3Phase}A 3ø | Avg Power: ${_activeCalculation!.avgAmps3Phase}A 3ø'
                                                                    : '> Max Power: 0A 3ø | Avg Power: 0A 3ø',
                                                              ),
                                                              _summaryRow(
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '> Approx. Weight: ${_activeCalculation!.totalWeight.toInt()} Kg'
                                                                    : '> Approx. Weight: 0 Kg',
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),

                                                        // Totals Column
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              _columnHeader(
                                                                'Totals',
                                                              ),
                                                              _calcInfoRow(
                                                                'SQM - m²',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.sqm.toInt()}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Weight - Kg',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.totalWeight.toInt()}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Total Full Panels',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.totalFullPanels}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Total Half Panels',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.totalHalfPanels}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Total px',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? _activeCalculation!
                                                                          .totalPx
                                                                          .toString()
                                                                          .replaceAllMapped(
                                                                            RegExp(
                                                                              r'(\d{1,3})(?=(\d{3})+(?!\d))',
                                                                            ),
                                                                            (
                                                                              Match
                                                                              m,
                                                                            ) =>
                                                                                '${m[1]},',
                                                                          )
                                                                    : '0',
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),

                                                        // Shipping Column
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              _columnHeader(
                                                                'Shipping',
                                                              ),
                                                              _calcInfoRow(
                                                                'Dollys / Case',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.dollysPerCase}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Shipping Weight - Kg',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.shippingWeight.toInt()}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Shipping Volume - m³',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.shippingVolume.toInt()}'
                                                                    : '0',
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),

                                                  // Middle row - 3 columns
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        // Physical Column
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              _columnHeader(
                                                                'Physical',
                                                              ),
                                                              _calcInfoRow(
                                                                'Meters (W)',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.metersWidth}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Meters (H)',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.metersHeight}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Panels (W)',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.panelsWidth}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Panels (H)',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.panelsHeight}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Pixels (W)',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.pixelsWidth}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Pixels (H)',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.pixelsHeight}'
                                                                    : '0',
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),

                                                        // Electrical Column
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              _columnHeader(
                                                                'Electrical',
                                                              ),
                                                              _calcInfoRow(
                                                                'Max Amps 1ø',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.maxAmps1Phase}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Max Amps 3ø',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.maxAmps3Phase}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Avg Amps 1ø',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.avgAmps1Phase}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Avg Amps 3ø',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.avgAmps3Phase}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Total kW',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? _activeCalculation!
                                                                          .totalKW
                                                                          .toStringAsFixed(
                                                                            2,
                                                                          )
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'kW/hr',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? _activeCalculation!
                                                                          .kWPerHour
                                                                          .toStringAsFixed(
                                                                            1,
                                                                          )
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Distro',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? _activeCalculation!
                                                                          .distro
                                                                    : '0',
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),

                                                        // Stacked Rigging Column
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              _columnHeader(
                                                                'Stacked Rigging',
                                                              ),
                                                              _calcInfoRow(
                                                                'Truss Upright',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.trussUpright}'
                                                                    : '0',
                                                                greyedOut:
                                                                    _surfaces
                                                                        .isNotEmpty &&
                                                                    _activeSurfaceIndex <
                                                                        _surfaces
                                                                            .length &&
                                                                    _surfaces[_activeSurfaceIndex]
                                                                        .isRigged,
                                                              ),
                                                              _calcInfoRow(
                                                                'Truss Baseplate',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.trussBaseplate}'
                                                                    : '0',
                                                                greyedOut:
                                                                    _surfaces
                                                                        .isNotEmpty &&
                                                                    _activeSurfaceIndex <
                                                                        _surfaces
                                                                            .length &&
                                                                    _surfaces[_activeSurfaceIndex]
                                                                        .isRigged,
                                                              ),
                                                              _calcInfoRow(
                                                                'Horizontal Pipe',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.horizontalPipe}'
                                                                    : '0',
                                                                greyedOut:
                                                                    _surfaces
                                                                        .isNotEmpty &&
                                                                    _activeSurfaceIndex <
                                                                        _surfaces
                                                                            .length &&
                                                                    _surfaces[_activeSurfaceIndex]
                                                                        .isRigged,
                                                              ),
                                                              _calcInfoRow(
                                                                'Half Couplers',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.halfCouplers}'
                                                                    : '0',
                                                                greyedOut:
                                                                    _surfaces
                                                                        .isNotEmpty &&
                                                                    _activeSurfaceIndex <
                                                                        _surfaces
                                                                            .length &&
                                                                    _surfaces[_activeSurfaceIndex]
                                                                        .isRigged,
                                                              ),
                                                              _calcInfoRow(
                                                                'Bracing Arms',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.bracingArms}'
                                                                    : '0',
                                                                greyedOut:
                                                                    _surfaces
                                                                        .isNotEmpty &&
                                                                    _activeSurfaceIndex <
                                                                        _surfaces
                                                                            .length &&
                                                                    _surfaces[_activeSurfaceIndex]
                                                                        .isRigged,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),

                                                  // Bottom row - 3 columns
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        // Cables & Processing Column
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              _columnHeader(
                                                                'Cables & Processing',
                                                              ),
                                                              _calcInfoRow(
                                                                'First Data (inc backup)',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.firstData}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'First Power',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.firstPower}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Socapex',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.socapex}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Novastar MCTRL 4K Main',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.novastarMain}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Novastar MCTRL 4K BU',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.novastarBU}'
                                                                    : '0',
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),

                                                        // Weights Column
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              _columnHeader(
                                                                'Weights',
                                                              ),
                                                              _calcInfoRow(
                                                                'Screen Weight',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.screenWeight.toInt()}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Cable Weight (10%)',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.cableWeight.toInt()}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Rigging Allowance (20%)',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.riggingAllowance.toInt()}'
                                                                    : '0',
                                                              ),
                                                              _calcInfoRow(
                                                                'Total',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.totalCalculatedWeight.toInt()}'
                                                                    : '0',
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),

                                                        // Flown Rigging Column
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              _columnHeader(
                                                                'Flown Rigging',
                                                              ),
                                                              _calcInfoRow(
                                                                'Single Header',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.singleHeader}'
                                                                    : '0',
                                                                greyedOut:
                                                                    _surfaces
                                                                        .isNotEmpty &&
                                                                    _activeSurfaceIndex <
                                                                        _surfaces
                                                                            .length &&
                                                                    _surfaces[_activeSurfaceIndex]
                                                                        .isStacked,
                                                              ),
                                                              _calcInfoRow(
                                                                'Gac/Spanset 4m',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.gacSpanset4m}'
                                                                    : '0',
                                                                greyedOut:
                                                                    _surfaces
                                                                        .isNotEmpty &&
                                                                    _activeSurfaceIndex <
                                                                        _surfaces
                                                                            .length &&
                                                                    _surfaces[_activeSurfaceIndex]
                                                                        .isStacked,
                                                              ),
                                                              _calcInfoRow(
                                                                '3.25t Shackle',
                                                                _activeCalculation !=
                                                                        null
                                                                    ? '${_activeCalculation!.shackle25t}'
                                                                    : '0',
                                                                greyedOut:
                                                                    _surfaces
                                                                        .isNotEmpty &&
                                                                    _activeSurfaceIndex <
                                                                        _surfaces
                                                                            .length &&
                                                                    _surfaces[_activeSurfaceIndex]
                                                                        .isStacked,
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
                                    ],
                                  ),
                                ),
                              ),

                              // LED Search Suggestions - positioned below the combined surface box
                              if (_showSuggestions)
                                Positioned(
                                  top: isMobile
                                      ? 280 + 20
                                      : 280 +
                                            20 +
                                            20, // Position below the combined box (adjusted for new height)
                                  left: 20,
                                  child: Container(
                                    width: isMobile
                                        ? 90.w
                                        : 340, // Match the new width of the surface box
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: _isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: buttonBackgroundColor,
                                        width: 2.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    constraints: BoxConstraints(
                                      maxHeight: isMobile ? 200 : 200,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      elevation: 0,
                                      child: ListView.builder(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: _searchResults.length,
                                        itemBuilder: (context, index) {
                                          final led = _searchResults[index];
                                          return InkWell(
                                            onTap: () => _selectLED(led),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8.0,
                                                    horizontal: 16.0,
                                                  ),
                                              child: Text(
                                                led.name,
                                                style: TextStyle(
                                                  color: _isDarkMode
                                                      ? Colors.white
                                                      : textColorPrimary,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: isMobile
                                                      ? 14
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),

                              // Mobile-specific content overlay
                              if (isMobile)
                                Positioned(
                                  top:
                                      320, // Start below the combined surface box
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    color: _isDarkMode
                                        ? Colors.grey[900]
                                        : const Color(
                                            0xFFF7F6F3,
                                          ), // Very light warm gray
                                    child: SingleChildScrollView(
                                      padding: EdgeInsets.all(4.w),
                                      child: Column(
                                        children: [
                                          // Surface Summary section for mobile
                                          if (_surfaces.isNotEmpty)
                                            Card(
                                              color: _isDarkMode
                                                  ? Colors.grey[850]
                                                  : Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                side: BorderSide(
                                                  color: _isDarkMode
                                                      ? Colors.grey[700]!
                                                      : Colors.grey[300]!,
                                                ),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Surface: ${_surfaces[_activeSurfaceIndex].name}',
                                                      style: TextStyle(
                                                        fontSize: 18.sp,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: _isDarkMode
                                                            ? Colors.white
                                                            : textColorPrimary,
                                                      ),
                                                    ),
                                                    SizedBox(height: 2.h),
                                                    if (_activeCalculation !=
                                                        null) ...[
                                                      _mobileSummaryRow(
                                                        'LED',
                                                        _activeCalculation!
                                                            .ledName,
                                                      ),
                                                      _mobileSummaryRow(
                                                        'Size',
                                                        '${_activeCalculation!.metersWidth}m × ${_activeCalculation!.metersHeight}m',
                                                      ),
                                                      _mobileSummaryRow(
                                                        'SQM',
                                                        '${_activeCalculation!.sqm.toInt()}',
                                                      ),
                                                      _mobileSummaryRow(
                                                        'Panels',
                                                        '${_activeCalculation!.totalFullPanels} full, ${_activeCalculation!.totalHalfPanels} half',
                                                      ),
                                                      _mobileSummaryRow(
                                                        'Resolution',
                                                        '${_activeCalculation!.pixelsWidth} × ${_activeCalculation!.pixelsHeight} px',
                                                      ),
                                                      _mobileSummaryRow(
                                                        'Weight',
                                                        '${_activeCalculation!.totalWeight.toInt()} kg',
                                                      ),
                                                      _mobileSummaryRow(
                                                        'Power',
                                                        '${_activeCalculation!.totalKW.toStringAsFixed(2)} kW',
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          SizedBox(height: 2.h),
                                          // Surface tabs for mobile
                                          if (_surfaces.isNotEmpty)
                                            Card(
                                              color: _isDarkMode
                                                  ? Colors.grey[850]
                                                  : Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                side: BorderSide(
                                                  color: _isDarkMode
                                                      ? Colors.grey[700]!
                                                      : Colors.grey[300]!,
                                                ),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      'Surfaces (${_surfaces.length})',
                                                      style: TextStyle(
                                                        fontSize: 16.sp,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: _isDarkMode
                                                            ? Colors.white
                                                            : textColorPrimary,
                                                      ),
                                                    ),
                                                    SizedBox(height: 2.h),
                                                    Wrap(
                                                      spacing: 2.w,
                                                      runSpacing: 1.h,
                                                      children: [
                                                        for (
                                                          int i = 0;
                                                          i < _surfaces.length;
                                                          i++
                                                        )
                                                          GestureDetector(
                                                            onTap: () {
                                                              setState(() {
                                                                _activeSurfaceIndex =
                                                                    i;
                                                                _updateControllersFromActiveSurface();
                                                              });
                                                            },
                                                            child: Container(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        4.w,
                                                                    vertical:
                                                                        2.w,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    _activeSurfaceIndex ==
                                                                        i
                                                                    ? (_isDarkMode
                                                                          ? Colors.blue[700]
                                                                          : Colors.blue)
                                                                    : (_isDarkMode
                                                                          ? Colors.grey[700]
                                                                          : Colors.grey[300]),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                              ),
                                                              child: Text(
                                                                _surfaces[i]
                                                                        .name
                                                                        .isEmpty
                                                                    ? 'Surface ${i + 1}'
                                                                    : _surfaces[i]
                                                                          .name,
                                                                style: TextStyle(
                                                                  fontSize:
                                                                      14.sp,
                                                                  color:
                                                                      _activeSurfaceIndex ==
                                                                          i
                                                                      ? Colors
                                                                            .white
                                                                      : (_isDarkMode
                                                                            ? Colors.white
                                                                            : Colors.black),
                                                                  fontWeight:
                                                                      _activeSurfaceIndex ==
                                                                          i
                                                                      ? FontWeight
                                                                            .bold
                                                                      : FontWeight
                                                                            .normal,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          SizedBox(
                                            height: 10.h,
                                          ), // Extra space at bottom
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                              // LED Management buttons - positioned in the right area of the content
                              if (!isMobile)
                                Positioned(
                                  top: 5, // Position at the very top
                                  right:
                                      20, // Position 20px from the right edge of content
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () async {
                                          final hasAccess =
                                              await _showPasswordDialog();
                                          if (hasAccess) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return const LEDListDialog();
                                              },
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _isDarkMode
                                              ? const Color(0xFF23272F)
                                              : buttonBackgroundColor,
                                          foregroundColor: _isDarkMode
                                              ? Colors.white
                                              : buttonTextColor,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'LED EDIT',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _isDarkMode
                                                ? Colors.white
                                                : buttonTextColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final hasAccess =
                                              await _showPasswordDialog();
                                          if (hasAccess) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return const AddLEDDialogNew();
                                              },
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _isDarkMode
                                              ? const Color(0xFF23272F)
                                              : buttonBackgroundColor,
                                          foregroundColor: _isDarkMode
                                              ? Colors.white
                                              : buttonTextColor,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'ADD NEW',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _isDarkMode
                                                ? Colors.white
                                                : buttonTextColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      ElevatedButton(
                                        onPressed: () =>
                                            _importLEDDataWithPassword(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _isDarkMode
                                              ? const Color(0xFF23272F)
                                              : buttonBackgroundColor,
                                          foregroundColor: _isDarkMode
                                              ? Colors.white
                                              : buttonTextColor,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'IMPORT CSV',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _isDarkMode
                                                ? Colors.white
                                                : buttonTextColor,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectDataDialog() {
    final TextEditingController projectNumberController = TextEditingController(
      text: _projectData.projectNumber,
    );
    final TextEditingController projectNameController = TextEditingController(
      text: _projectData.projectName,
    );
    final TextEditingController projectManagerController =
        TextEditingController(text: _projectData.projectManager);
    final TextEditingController projectEngineerController =
        TextEditingController(text: _projectData.projectEngineer);
    final TextEditingController clientNameController = TextEditingController(
      text: _projectData.clientName,
    );
    final TextEditingController locationController = TextEditingController(
      text: _projectData.location,
    );
    final TextEditingController descriptionController = TextEditingController(
      text: _projectData.description,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _isDarkMode ? Colors.white : Colors.blue[600],
                  ),
                  const SizedBox(width: 10),
                  const Text('Project Information'),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: projectNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Project Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: projectNameController,
                        decoration: const InputDecoration(
                          labelText: 'Project Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: projectManagerController,
                        decoration: const InputDecoration(
                          labelText: 'Project Manager',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: projectEngineerController,
                        decoration: const InputDecoration(
                          labelText: 'Project Engineer',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: clientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Client Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Logo import section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _isDarkMode
                                ? Colors.grey[600]!
                                : Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Project Logo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isDarkMode
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_logoBase64 != null && _logoBase64!.isNotEmpty)
                              Column(
                                children: [
                                  Container(
                                    height: 60,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.memory(
                                        base64Decode(
                                          _logoBase64!.split(',')[1],
                                        ),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _logoFileName ?? 'Logo imported',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _isDarkMode
                                          ? Colors.grey[300]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      final bytes =
                                          await FileService.pickImageFile();
                                      if (bytes != null) {
                                        setState(() {
                                          _logoBase64 =
                                              FileService.bytesToBase64DataUrl(
                                                bytes,
                                                'image/png',
                                              );
                                          _logoFileName = 'imported_logo.png';
                                        });

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Logo imported successfully',
                                            ),
                                            backgroundColor: Colors.green,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error importing logo: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.image, size: 16),
                                  label: Text(
                                    _logoBase64 != null &&
                                            _logoBase64!.isNotEmpty
                                        ? 'Change Logo'
                                        : 'Import Logo',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isDarkMode
                                        ? const Color(0xFF23272F)
                                        : buttonBackgroundColor,
                                    foregroundColor: _isDarkMode
                                        ? Colors.white
                                        : buttonTextColor,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                                if (_logoBase64 != null &&
                                    _logoBase64!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _logoBase64 = null;
                                        _logoFileName = null;
                                      });
                                    },
                                    child: Text(
                                      'Remove',
                                      style: TextStyle(color: Colors.red[600]),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(foregroundColor: buttonTextColor),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    this.setState(() {
                      _projectData.projectNumber = projectNumberController.text;
                      _projectData.projectName = projectNameController.text;
                      _projectData.projectManager =
                          projectManagerController.text;
                      _projectData.projectEngineer =
                          projectEngineerController.text;
                      _projectData.clientName = clientNameController.text;
                      _projectData.location = locationController.text;
                      _projectData.description = descriptionController.text;
                    });
                    Navigator.of(context).pop();
                    // Success message removed - no more banner popup for project data saving
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDarkMode
                        ? const Color(
                            0xFF23272F,
                          ) // Gunmetal/slate gray panel background
                        : buttonBackgroundColor,
                    foregroundColor: _isDarkMode
                        ? Colors.white
                        : buttonTextColor,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
