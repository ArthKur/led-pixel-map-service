import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[900],
      ),
      themeMode: ThemeMode.system,
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
  // Controllers
  final _searchController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _nameController = TextEditingController();

  // Chat messages list
  List<Map<String, String>> messages = [];

  // Dark mode toggle
  bool _isDarkMode = false;

  // Search functionality
  List<LEDModel> _searchResults = [];
  bool _showSuggestions = false;

  void _searchLEDs(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSuggestions = false;
      });
      print("Empty query, hiding suggestions");
      return;
    }

    // Fetch results from service
    final results = await LEDService.searchLEDs(query.toLowerCase());

    // Debug: If no results, add some sample data to verify dropdown works
    if (results.isEmpty) {
      print("No search results found, adding sample data for testing");

      // Create a sample LED with all required parameters
      final DateTime now = DateTime.now();
      setState(() {
        // Add sample LEDs for testing the dropdown visibility
        _searchResults = [
          LEDModel(
            name: "Sample LED 1",
            manufacturer: "Test",
            model: "Test1",
            pitch: 2.0,
            fullHeight: 500.0,
            halfHeight: 250.0,
            width: 500.0,
            depth: 80.0,
            fullPanelWeight: 10.0,
            halfPanelWeight: 5.0,
            hPixel: 64,
            wPixel: 64,
            halfHPixel: 32,
            halfWPixel: 64,
            halfWidth: 250.0,
            fullPanelMaxW: 100.0,
            halfPanelMaxW: 50.0,
            fullPanelAvgW: 80.0,
            halfPanelAvgW: 40.0,
            processing: "16 bit",
            brightness: 1000,
            viewingAngle: "140/140",
            refreshRate: 3840,
            ledConfiguration: "SMD",
            ipRating: "IP65",
            curveCapability: "Yes",
            verification: "CE",
            dataConnection: "RJ45",
            powerConnection: "PowerCON",
            touringFrame: "Yes",
            supplier: "Test Supplier",
            operatingVoltage: "100-240V",
            operatingTemp: "-10°C to 40°C",
            dateAdded: now,
            panelsPerPort: 5,
            panelsPer16A: 10,
          ),
          LEDModel(
            name: "Sample LED 2",
            manufacturer: "Demo",
            model: "Demo1",
            pitch: 3.0,
            fullHeight: 500.0,
            halfHeight: 250.0,
            width: 500.0,
            depth: 80.0,
            fullPanelWeight: 12.0,
            halfPanelWeight: 6.0,
            hPixel: 32,
            wPixel: 32,
            halfHPixel: 16,
            halfWPixel: 32,
            halfWidth: 250.0,
            fullPanelMaxW: 120.0,
            halfPanelMaxW: 60.0,
            fullPanelAvgW: 100.0,
            halfPanelAvgW: 50.0,
            processing: "18 bit",
            brightness: 1500,
            viewingAngle: "160/160",
            refreshRate: 1920,
            ledConfiguration: "COB",
            ipRating: "IP54",
            curveCapability: "No",
            verification: "UL",
            dataConnection: "Neutrik",
            powerConnection: "PowerCON TRUE1",
            touringFrame: "Yes",
            supplier: "Demo Supplier",
            operatingVoltage: "100-240V",
            operatingTemp: "0°C to 45°C",
            dateAdded: now,
            panelsPerPort: 3,
            panelsPer16A: 8,
          ),
        ];
        _showSuggestions = true;
        print("Set _showSuggestions to true with 2 sample results");
      });
    } else {
      setState(() {
        _searchResults = results;
        _showSuggestions = results.isNotEmpty;
        print(
          "Set _showSuggestions to ${results.isNotEmpty} with ${results.length} results",
        );
      });
    }

    // Debug: Print current state to console
    print("Search results: ${_searchResults.length}");
    print("Show suggestions: $_showSuggestions");
  }

  void _selectLED(LEDModel led) {
    setState(() {
      if (_surfaces.isNotEmpty && _activeSurfaceIndex < _surfaces.length) {
        _surfaces[_activeSurfaceIndex].selectedLED = led;
        _searchController.text = led.name;
        _showSuggestions = false;
        _updateActiveSurfaceFromControllers();
      }
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
    LEDService.addAbsenProducts();
    _addSurface();

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

  @override
  void dispose() {
    _searchController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _nameController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: _isDarkMode ? Colors.grey[900] : Colors.grey[300],
          child: Stack(
            children: [
              // Dark mode toggle button
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: Icon(
                    _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                  onPressed: _toggleDarkMode,
                ),
              ),

              // Width and Height search boxes
              Positioned(
                top: 80,
                left: 20,
                child: Row(
                  children: [
                    Container(
                      width: 140,
                      decoration: BoxDecoration(
                        color: _isDarkMode ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[400]!,
                        ),
                      ),
                      child: TextField(
                        controller: _widthController,
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _updateActiveSurfaceFromControllers();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Width (m)',
                          hintStyle: TextStyle(
                            color: _isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      width: 140,
                      decoration: BoxDecoration(
                        color: _isDarkMode ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isDarkMode
                              ? Colors.grey[700]!
                              : Colors.grey[400]!,
                        ),
                      ),
                      child: TextField(
                        controller: _heightController,
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _updateActiveSurfaceFromControllers();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Height (m)',
                          hintStyle: TextStyle(
                            color: _isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Example: Surface name input
              Positioned(
                top: 20,
                left: 340,
                child: Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isDarkMode
                          ? Colors.grey[700]!
                          : Colors.grey[400]!,
                    ),
                  ),
                  child: TextField(
                    controller: _nameController,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                    onChanged: (value) {
                      setState(() {
                        _updateActiveSurfaceFromControllers();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Surface name...',
                      hintStyle: TextStyle(
                        color: _isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ),

              // Stacked and Rigged checkboxes
              Positioned(
                top: 88,
                left: 340,
                child: SizedBox(
                  width: 300,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Transform.scale(
                            scale: 0.7,
                            child: Checkbox(
                              value: _isStacked,
                              fillColor:
                                  WidgetStateProperty.resolveWith<Color>((
                                    Set<WidgetState> states,
                                  ) {
                                    if (_isDarkMode) {
                                      return Colors.grey[700]!;
                                    }
                                    return Colors.blue;
                                  }),
                              checkColor: _isDarkMode
                                  ? Colors.white
                                  : Colors.white,
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
                          Text(
                            'Stacked',
                            style: TextStyle(
                              fontSize: 14,
                              color: _isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          Transform.scale(
                            scale: 0.7,
                            child: Checkbox(
                              value: _isRigged,
                              fillColor:
                                  WidgetStateProperty.resolveWith<Color>((
                                    Set<WidgetState> states,
                                  ) {
                                    if (_isDarkMode) {
                                      return Colors.grey[700]!;
                                    }
                                    return Colors.blue;
                                  }),
                              checkColor: _isDarkMode
                                  ? Colors.white
                                  : Colors.white,
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
                          Text(
                            'Rigged',
                            style: TextStyle(
                              fontSize: 14,
                              color: _isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Add Surface button
              Positioned(
                top: 20,
                left: 660,
                child: ElevatedButton.icon(
                  onPressed: _addSurface,
                  icon: Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text(
                    'Add Surface',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDarkMode
                        ? Colors.grey[800]
                        : Colors.green,
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
                        backgroundColor: _isDarkMode
                            ? Colors.grey[800]
                            : Colors.amber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Generate PixelMaps',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                        backgroundColor: _isDarkMode
                            ? Colors.grey[800]
                            : Colors.amber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Generate Obj',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                        backgroundColor: _isDarkMode
                            ? Colors.grey[800]
                            : Colors.amber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Generate Paperwork',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                        backgroundColor: _isDarkMode
                            ? Colors.grey[800]
                            : Colors.amber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'LED EDIT',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                        backgroundColor: _isDarkMode
                            ? Colors.grey[800]
                            : Colors.amber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'ADD NEW LED',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main search box - Positioned last to appear on top of all other elements
              Positioned(
                top: 20,
                left: 20,
                child: Material(
                  elevation: 10, // Higher elevation to ensure it appears on top
                  color: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search input field
                      Container(
                        width: 300,
                        decoration: BoxDecoration(
                          color: _isDarkMode ? Colors.grey[800] : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isDarkMode
                                ? Colors.grey[700]!
                                : Colors.grey[400]!,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(
                            color: _isDarkMode ? Colors.white : Colors.black,
                          ),
                          onChanged: (value) {
                            _searchLEDs(value);
                          },
                          decoration: InputDecoration(
                            hintText: 'Search LED Product',
                            hintStyle: TextStyle(
                              color: _isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                            suffixIcon: Icon(
                              Icons.search,
                              color: _isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),

                      // Dropdown suggestions
                      if (_showSuggestions)
                        Container(
                          width: 300,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: _isDarkMode
                                ? Colors.grey[800]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue, width: 2.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(maxHeight: 200),
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                      horizontal: 16.0,
                                    ),
                                    child: Text(
                                      led.name,
                                      style: TextStyle(
                                        color: _isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              },
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
    );
  }
}
