import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import '../models/surface_model.dart';
import '../services/file_service.dart';

// Border colors as per style guide
const Color borderColorLight = Color(0xFFE7DCCC); // Lighter border #E7DCCC
const Color borderColorDark = Color(0xFFD4C7B7); // Darker border #D4C7B7

// Text colors as per style guide
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

// Define the new button background color as per style guide
const Color buttonBackgroundColor = Color.fromRGBO(247, 238, 221, 1.0);

// Define the new button text color as per style guide (30% darker)
const Color buttonTextColor = Color.fromRGBO(125, 117, 103, 1.0);

class LEDSummaryDialog extends StatefulWidget {
  final List<Surface> surfaces;
  final bool isDarkMode;
  final ProjectData? projectData;
  final String? logoBase64;
  final String? logoFileName;
  final Function(ProjectData)? onProjectDataChanged; // Add callback

  const LEDSummaryDialog({
    super.key,
    required this.surfaces,
    required this.isDarkMode,
    this.projectData,
    this.logoBase64,
    this.logoFileName,
    this.onProjectDataChanged, // Add callback parameter
  });

  @override
  State<LEDSummaryDialog> createState() => _LEDSummaryDialogState();
}

class _LEDSummaryDialogState extends State<LEDSummaryDialog> {
  String _selectedFormat = 'PDF';
  final List<String> _formats = ['PDF', 'Excel'];
  bool _isExporting = false;
  String _exportProgress = 'Preparing...';

  // Add controllers for editable project data
  late TextEditingController _projectNumberController;
  late TextEditingController _projectNameController;
  late TextEditingController _projectManagerController;
  late TextEditingController _clientNameController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing project data
    _projectNumberController = TextEditingController(
      text: widget.projectData?.projectNumber ?? '',
    );
    _projectNameController = TextEditingController(
      text: widget.projectData?.projectName ?? '',
    );
    _projectManagerController = TextEditingController(
      text: widget.projectData?.projectManager ?? '',
    );
    _clientNameController = TextEditingController(
      text: widget.projectData?.clientName ?? '',
    );
    _locationController = TextEditingController(
      text: widget.projectData?.location ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.projectData?.description ?? '',
    );
  }

  @override
  void dispose() {
    _projectNumberController.dispose();
    _projectNameController.dispose();
    _projectManagerController.dispose();
    _clientNameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateProjectData() {
    if (widget.onProjectDataChanged != null) {
      final updatedData = ProjectData(
        projectNumber: _projectNumberController.text,
        projectName: _projectNameController.text,
        projectManager: _projectManagerController.text,
        clientName: _clientNameController.text,
        location: _locationController.text,
        description: _descriptionController.text,
      );
      widget.onProjectDataChanged!(updatedData);
    }
  }

  // Helper method to format DateTime without seconds
  String _formatDateTimeWithoutSeconds(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  // Helper method to get progress bar width based on current stage
  double _getProgressWidth() {
    switch (_exportProgress) {
      case 'Preparing...':
        return 50.0;
      case 'Generating content...':
        return 100.0;
      case 'Building PDF...':
        return 150.0;
      case 'Finalizing...':
        return 200.0;
      default:
        return 25.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check current theme brightness
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // COMPLETELY OVERRIDE ALL THEMING - Support dark mode backgrounds
    return Theme(
      data: isDarkMode
          ? ThemeData.dark().copyWith(
              // DARK MODE THEME WITH NEW BACKGROUNDS
              primaryColor: const Color(0xFF23272F), // Gunmetal/slate gray
              scaffoldBackgroundColor: const Color(
                0xFF181A20,
              ), // Deep blue-black/charcoal
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF23272F),
                secondary: Color(0xFF23272F),
                surface: Color(0xFF23272F),
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onSurface: Colors.white,
              ),
            )
          : ThemeData.light().copyWith(
              // LIGHT MODE THEME - NO ORANGE ANYWHERE!
              primaryColor: const Color.fromRGBO(247, 238, 221, 1.0),
              scaffoldBackgroundColor: const Color.fromRGBO(247, 238, 221, 1.0),
              colorScheme: const ColorScheme.light(
                primary: Color.fromRGBO(247, 238, 221, 1.0),
                secondary: Color.fromRGBO(247, 238, 221, 1.0),
                surface: Color.fromRGBO(247, 238, 221, 1.0),
                onPrimary: Color(0xFFC7B299),
                onSecondary: Color(0xFFC7B299),
                onSurface: Color(0xFFC7B299),
                error: Colors.red,
                onError: Colors.white,
              ),
              dataTableTheme: DataTableThemeData(
                headingRowColor: WidgetStateProperty.all(
                  const Color.fromRGBO(247, 238, 221, 1.0),
                ),
                dataRowColor: WidgetStateProperty.all(Colors.white),
              ), // Disable Material 3 theming
            ),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 1400, // Increased from 900 to accommodate new columns
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? const Color(
                    0xFF23272F,
                  ) // Gunmetal/slate gray panel background
                : const Color(0xFFF7F6F3), // Very light warm gray
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: widget.isDarkMode
                  ? const Color(0x18FFFFFF)
                  : headerTextColor, // Translucent white border for dark mode
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode
                          ? const Color(
                              0xFF23272F,
                            ) // Gunmetal/slate gray panel background
                          : headerBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(13),
                        topRight: Radius.circular(13),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.summarize,
                          color: widget.isDarkMode
                              ? Colors.white
                              : headerTextColor,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'LED Summary Preview',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: widget.isDarkMode
                                ? Colors.white
                                : headerTextColor,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // A4 Preview Area
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: _buildA4PreviewContent(),
                    ),
                  ),

                  // Format Selection and Buttons
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Format Selection
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Export Format: ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.isDarkMode
                                    ? Colors.white
                                    : textColorPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: widget.isDarkMode
                                      ? Colors.white
                                      : Colors.grey,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedFormat,
                                  style: TextStyle(
                                    color: widget.isDarkMode
                                        ? Colors.white
                                        : textColorPrimary,
                                  ),
                                  dropdownColor: widget.isDarkMode
                                      ? Colors.grey[700]
                                      : Colors.white,
                                  items: _formats.map((String format) {
                                    return DropdownMenuItem<String>(
                                      value: format,
                                      child: Text(format),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedFormat = newValue!;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: buttonTextColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton(
                              onPressed: _isExporting ? null : _generateSummary,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isExporting
                                    ? Colors.grey[400]
                                    : buttonBackgroundColor,
                                foregroundColor: buttonTextColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 12,
                                ),
                              ),
                              child: _isExporting
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  widget.isDarkMode
                                                      ? Colors.white
                                                      : buttonTextColor,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _exportProgress,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: widget.isDarkMode
                                                ? Colors.white
                                                : buttonTextColor,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'Generate Report',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: buttonTextColor,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Loading overlay
              if (_isExporting)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode
                            ? const Color(0xFF2D3139).withOpacity(0.95)
                            : Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated loading spinner
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.isDarkMode
                                    ? Colors.blue[300]!
                                    : Colors.blue[600]!,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _exportProgress,
                            style: TextStyle(
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please wait while we prepare your ${_selectedFormat.toLowerCase()} file...',
                            style: TextStyle(
                              color: widget.isDarkMode
                                  ? Colors.grey[300]
                                  : Colors.grey[600],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          // Progress bar
                          Container(
                            width: 200,
                            height: 4,
                            decoration: BoxDecoration(
                              color: widget.isDarkMode
                                  ? Colors.grey[700]
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 800),
                              width: _getProgressWidth(),
                              height: 4,
                              decoration: BoxDecoration(
                                color: widget.isDarkMode
                                    ? Colors.blue[300]
                                    : Colors.blue[600],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ), // Close Stack
        ), // Close Container
      ), // Close Dialog widget
    ); // Close Theme widget
  } // Close build method

  Widget _buildA4PreviewContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Text(
                  'LED Summary',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: headerTextColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Generated on ${DateTime.now().toLocal().toString().split(' ')[0]}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 2,
                  width: double.infinity,
                  color: headerTextColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Summary Statistics Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? const Color(
                          0xFF23272F,
                        ) // Gunmetal/slate gray panel background
                      : headerBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Surfaces: ${widget.surfaces.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode
                        ? Colors.white
                        : const Color(
                            0xFF635955,
                          ), // 50% darker than headerTextColor
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? const Color(
                          0xFF23272F,
                        ) // Gunmetal/slate gray panel background
                      : headerBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'SQM: ${widget.surfaces.fold<double>(0.0, (sum, surface) => sum + (surface.area ?? 0.0)).toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode
                        ? Colors.white
                        : const Color(
                            0xFF635955,
                          ), // 50% darker than headerTextColor
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? const Color(
                          0xFF23272F,
                        ) // Gunmetal/slate gray panel background
                      : headerBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Power: ${(widget.surfaces.fold<double>(0.0, (sum, surface) => sum + ((surface.calculation?.maxPower ?? 0.0) / 1000))).toStringAsFixed(1)}kW',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode
                        ? Colors.white
                        : const Color(
                            0xFF635955,
                          ), // 50% darker than headerTextColor
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isDarkMode
                      ? const Color(
                          0xFF23272F,
                        ) // Gunmetal/slate gray panel background
                      : headerBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Pixels: ${widget.surfaces.fold<int>(0, (sum, surface) => sum + ((surface.calculation?.pixelsWidth ?? 0) * (surface.calculation?.pixelsHeight ?? 0)))}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode
                        ? Colors.white
                        : const Color(
                            0xFF635955,
                          ), // 50% darker than headerTextColor
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // LED Summary Table
          _buildSectionHeader('LED Summary'),
          const SizedBox(height: 10),
          _buildLEDSummaryTable(),

          const SizedBox(height: 30),

          // Footer removed
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? const Color(0xFF23272F) // Gunmetal/slate gray panel background
            : headerBackgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white : headerTextColor,
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: widget.isDarkMode ? Colors.white : headerTextColor,
        ),
      ),
    );
  }

  Widget _buildLEDSummaryTable() {
    if (widget.surfaces.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: borderColorLight),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'No surfaces available',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColorLight),
        borderRadius: BorderRadius.circular(6),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1600, // Fixed width to ensure horizontal scrolling
          child: Column(
            children: [
              // Header Row - COMPLETELY IMMUNE TO DARK MODE
              Theme(
                data: ThemeData.light().copyWith(
                  // Force light theme to override dark mode completely
                  brightness: Brightness.light,
                  primaryColor: const Color.fromRGBO(247, 238, 221, 1.0),
                  primaryColorLight: const Color.fromRGBO(247, 238, 221, 1.0),
                  primaryColorDark: const Color.fromRGBO(247, 238, 221, 1.0),
                  // Override ALL possible orange/amber colors
                  colorScheme: const ColorScheme.light(
                    brightness: Brightness.light,
                    primary: Color.fromRGBO(247, 238, 221, 1.0),
                    onPrimary: Color(0xFFC7B299),
                    secondary: Color.fromRGBO(247, 238, 221, 1.0),
                    onSecondary: Color(0xFFC7B299),
                    tertiary: Color.fromRGBO(247, 238, 221, 1.0),
                    surface: Color.fromRGBO(247, 238, 221, 1.0),
                    onSurface: Color(0xFFC7B299),
                    error: Colors.red,
                    onError: Colors.white,
                  ),
                ),
                child: Material(
                  color: const Color.fromRGBO(247, 238, 221, 1.0),
                  child: Container(
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(
                        247,
                        238,
                        221,
                        1.0,
                      ), // Triple force beige!
                    ),
                    child: Row(
                      children: [
                        _buildCustomHeaderCell('#', 40),
                        _buildCustomHeaderCell('Name', 100),
                        _buildCustomHeaderCell('LED Product', 120),
                        _buildCustomHeaderCell('W(m)', 60),
                        _buildCustomHeaderCell('H(m)', 60),
                        _buildCustomHeaderCell('SQM', 70),
                        _buildCustomHeaderCell('H Res', 70),
                        _buildCustomHeaderCell('V Res', 70),
                        _buildCustomHeaderCell('Proc Main', 80),
                        _buildCustomHeaderCell('BU Proc', 80),
                        _buildCustomHeaderCell('Full Panels', 80),
                        _buildCustomHeaderCell('Half Panels', 80),
                        _buildCustomHeaderCell('Power(kW)', 80),
                        _buildCustomHeaderCell('Weight(kg)', 80),
                        _buildCustomHeaderCell('Single Header', 100),
                        _buildCustomHeaderCell('GAC', 60),
                        _buildCustomHeaderCell('3.25t Shackle', 100),
                        _buildCustomHeaderCell('Volume(m³)', 80),
                        _buildCustomHeaderCell('Dollys/Cage', 80),
                        _buildCustomHeaderCell('Notes', 150),
                      ],
                    ),
                  ),
                ),
              ),
              // Data Rows
              ...widget.surfaces.asMap().entries.map((entry) {
                int index = entry.key;
                Surface surface = entry.value;
                return Container(
                  height: 35,
                  decoration: BoxDecoration(
                    color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildCustomDataCell('${index + 1}', 40),
                      _buildCustomDataCell(
                        surface.name.isEmpty
                            ? 'Surface ${index + 1}'
                            : surface.name,
                        100,
                      ),
                      _buildCustomDataCell(
                        surface.selectedLED?.name ?? '-',
                        120,
                      ),
                      _buildCustomDataCell('${surface.width ?? 0}', 60),
                      _buildCustomDataCell('${surface.height ?? 0}', 60),
                      _buildCustomDataCell(
                        surface.area?.toStringAsFixed(2) ?? '0',
                        70,
                      ),
                      _buildCustomDataCell(
                        '${surface.calculation?.pixelsWidth ?? 0}',
                        70,
                      ),
                      _buildCustomDataCell(
                        '${surface.calculation?.pixelsHeight ?? 0}',
                        70,
                      ),
                      _buildCustomDataCell(
                        '${surface.calculation?.novastarMain ?? 0}',
                        80,
                      ),
                      _buildCustomDataCell(
                        '${surface.calculation?.novastarBU ?? 0}',
                        80,
                      ),
                      _buildCustomDataCell(
                        '${surface.calculation?.totalFullPanels ?? 0}',
                        80,
                      ),
                      _buildCustomDataCell(
                        '${surface.calculation?.totalHalfPanels ?? 0}',
                        80,
                      ),
                      _buildCustomDataCell(
                        surface.calculation != null
                            ? (surface.calculation!.maxPower / 1000)
                                  .toStringAsFixed(2)
                            : '0.00',
                        80,
                      ),
                      _buildCustomDataCell(
                        surface.totalWeight?.toStringAsFixed(0) ?? '0',
                        80,
                      ),
                      _buildCustomDataCell(
                        '${surface.calculation?.singleHeader ?? 0}',
                        100,
                      ),
                      _buildCustomDataCell(
                        '${surface.calculation?.gacSpanset4m ?? 0}',
                        60,
                      ),
                      _buildCustomDataCell(
                        '${surface.calculation?.shackle25t ?? 0}',
                        100,
                      ),
                      _buildCustomDataCell(
                        surface.calculation?.shippingVolume.toStringAsFixed(
                              2,
                            ) ??
                            '0.00',
                        80,
                      ),
                      _buildCustomDataCell(
                        '${surface.calculation?.dollysPerCase ?? 0}',
                        80,
                      ),
                      _buildCustomDataCell(
                        surface.notes.isEmpty ? 'add notes...' : surface.notes,
                        150,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomHeaderCell(String text, double width) {
    return Material(
      color: const Color.fromRGBO(
        247,
        238,
        221,
        1.0,
      ), // Force beige at Material level
      child: Container(
        width: width,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: const BoxDecoration(
          color: Color.fromRGBO(
            247,
            238,
            221,
            1.0,
          ), // Force beige at Container level
          // No border to avoid any theme interference
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(
              0xFF635955,
            ), // 50% darker than C7B299 - NO THEME INHERITANCE
            backgroundColor: Color.fromRGBO(
              247,
              238,
              221,
              1.0,
            ), // Force beige even on text
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildCustomDataCell(String text, double width) {
    return Container(
      width: width,
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.grey[300]!, width: 0.5)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF2D2D2D),
        ), // 50% darker than black87
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _generateSummary() async {
    // Update project data before generating the report
    _updateProjectData();

    // Generate default file name: LED_Summary + Project number + project name
    String fileName = 'LED_Summary';

    // Use current controller values for filename
    if (_projectNumberController.text.isNotEmpty) {
      fileName += '_${_projectNumberController.text}';
    }
    if (_projectNameController.text.isNotEmpty) {
      // Clean project name for filename
      String cleanProjectName = _projectNameController.text
          .replaceAll(RegExp(r'[^\w\-_]'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .trim();

      // Limit length for filename
      if (cleanProjectName.length > 20) {
        cleanProjectName = cleanProjectName.substring(0, 20);
      }
      fileName += '_$cleanProjectName';
    }

    // Fallback with timestamp if no project data
    if (fileName == 'LED_Summary') {
      fileName = 'LED_Summary_${DateTime.now().millisecondsSinceEpoch}';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController fileNameController = TextEditingController(
          text: fileName,
        );

        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF23272F) // Gunmetal/slate gray panel background
              : const Color(0xFFF7F6F3),
          title: const Text('Save Project Report'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Export format: $_selectedFormat'),
              const SizedBox(height: 16),
              Text(
                'File name:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: fileNameController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'Enter file name',
                  suffix: Text('.${_getFileExtension()}'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'The file will be saved to your browser\'s default download location.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: buttonTextColor),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isExporting
                  ? null
                  : () async {
                      if (_isExporting) return;

                      String fileName = fileNameController.text.trim();
                      Navigator.of(context).pop(); // Close the save dialog

                      // Start loading
                      setState(() {
                        _isExporting = true;
                        _exportProgress = 'Preparing...';
                      });

                      try {
                        await _downloadFile(fileName);
                      } finally {
                        // Stop loading
                        if (mounted) {
                          setState(() {
                            _isExporting = false;
                            _exportProgress = 'Preparing...';
                          });
                        }
                      }

                      if (mounted) {
                        Navigator.of(context).pop(); // Close the main dialog
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isExporting
                    ? Colors.grey[400]
                    : buttonBackgroundColor,
                foregroundColor: buttonTextColor,
              ),
              child: _isExporting
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Saving...'),
                      ],
                    )
                  : const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _getFileExtension() {
    switch (_selectedFormat) {
      case 'PDF':
        return 'pdf';
      case 'Excel':
        return 'csv';
      default:
        return 'txt';
    }
  }

  Future<void> _downloadFile(String fileName) async {
    try {
      setState(() {
        _exportProgress = 'Preparing...';
      });

      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // Small delay for visual feedback

      String? mimeType;
      String extension = _getFileExtension();
      Uint8List bytes;

      setState(() {
        _exportProgress = 'Generating content...';
      });

      await Future.delayed(const Duration(milliseconds: 200));

      switch (_selectedFormat) {
        case 'PDF':
          setState(() {
            _exportProgress = 'Building PDF...';
          });
          bytes = await _generatePDFContent();
          mimeType = 'application/pdf';
          break;
        case 'Excel':
          setState(() {
            _exportProgress = 'Generating CSV...';
          });
          String csvContent = _generateExcelContent();
          bytes = Uint8List.fromList(csvContent.codeUnits);
          mimeType = 'text/csv';
          break;
        default:
          String content = _generateTextContent();
          bytes = Uint8List.fromList(content.codeUnits);
          mimeType = 'text/plain';
      }

      setState(() {
        _exportProgress = 'Finalizing...';
      });

      await Future.delayed(const Duration(milliseconds: 200));

      // Clean filename
      String cleanFileName = fileName.replaceAll(RegExp(r'[^\w\-_\.]'), '_');
      if (cleanFileName.isEmpty) {
        cleanFileName = 'LED_Summary_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Use cross-platform file service
      await FileService.downloadFile(
        bytes,
        '$cleanFileName.$extension',
        mimeType,
      );

      // Removed success notification - keep only error notifications
    } catch (e) {
      // Handle any errors silently or show minimal error feedback
      print('Error downloading file: $e');
    }
  }

  Future<Uint8List> _generatePDFContent() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(15), // Reduced margins for more space
        build: (pw.Context context) {
          return [
            // Header with logo in top right corner
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LED Summary',
                      style: pw.TextStyle(
                        fontSize: 21, // Reduced by 1 from 22
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    // Generated date moved under LED SUMMARY
                    pw.Text(
                      'Generated on: ${_formatDateTimeWithoutSeconds(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
                // Logo space - only show if logo exists, moved closer to right edge
                if (widget.logoBase64 != null)
                  pw.Container(
                    width: 224, // 30% smaller (320 * 0.7)
                    height: 112, // 30% smaller (160 * 0.7)
                    margin: const pw.EdgeInsets.only(
                      right: 0,
                    ), // Moved to page edge
                    child: pw.Center(child: _buildLogoFromBase64()),
                  ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Surface details table with reduced font
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Stack(
                  children: [
                    pw.Text(
                      'SURFACE DETAILS',
                      style: pw.TextStyle(
                        fontSize: 13, // Reduced by 1 from 14
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.Positioned(
                      bottom: 0,
                      left: 0,
                      child: pw.Container(
                        height: 1, // Thinner underline
                        width: 115, // Extended to cover all text
                        color: PdfColor.fromHex(
                          '#C7B299',
                        ), // headerTextColor equivalent
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            // Project Totals Section
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Total Panels',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${widget.surfaces.fold<int>(0, (sum, surface) => sum + (surface.calculation?.totalFullPanels ?? 0) + (surface.calculation?.totalHalfPanels ?? 0))}',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Total SQM',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        widget.surfaces
                            .fold<double>(
                              0.0,
                              (sum, surface) =>
                                  sum +
                                  ((surface.width ?? 0.0) *
                                      (surface.height ?? 0.0)),
                            )
                            .toStringAsFixed(1),
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Total Power (kW)',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        (widget.surfaces.fold<double>(
                          0.0,
                          (sum, surface) =>
                              sum +
                              ((surface.calculation?.maxPower ?? 0.0) / 1000),
                        )).toStringAsFixed(1),
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Total Weight (kg)',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${widget.surfaces.fold<double>(0.0, (sum, surface) => sum + (surface.calculation?.totalWeight ?? 0.0)).toInt()}',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),

            pw.TableHelper.fromTextArray(
              headers: [
                '#',
                'Name',
                'LED Product',
                'W(m)',
                'H(m)',
                'SQM',
                'H Res',
                'V Res',
                'Proc Main',
                'BU Proc',
                'Full Panels',
                'Half Panels',
                'Power(kW)',
                'Weight(kg)',
                'Single Header',
                'GAC',
                '3.25t Shackle',
                'Volume(m³)',
                'Dollys/Cage',
                'Notes',
              ],
              data: widget.surfaces.asMap().entries.map((entry) {
                int index = entry.key;
                Surface surface = entry.value;
                return [
                  '${index + 1}',
                  surface.name.isEmpty ? 'Surface ${index + 1}' : surface.name,
                  surface.selectedLED?.name ?? '-',
                  '${surface.width ?? 0}',
                  '${surface.height ?? 0}',
                  (surface.area?.toStringAsFixed(2) ?? '0'),
                  '${surface.calculation?.pixelsWidth ?? 0}',
                  '${surface.calculation?.pixelsHeight ?? 0}',
                  '${surface.calculation?.novastarMain ?? 0}',
                  '${surface.calculation?.novastarBU ?? 0}',
                  '${surface.calculation?.totalFullPanels ?? 0}',
                  '${surface.calculation?.totalHalfPanels ?? 0}',
                  surface.calculation != null
                      ? (surface.calculation!.maxPower / 1000).toStringAsFixed(
                          2,
                        )
                      : '0.00',
                  (surface.totalWeight?.toStringAsFixed(0) ?? '0'),
                  '${surface.calculation?.singleHeader ?? 0}',
                  '${surface.calculation?.gacSpanset4m ?? 0}',
                  '${surface.calculation?.shackle25t ?? 0}',
                  (surface.calculation?.shippingVolume.toStringAsFixed(2) ??
                      '0.00'),
                  '${surface.calculation?.dollysPerCase ?? 0}',
                  surface.notes.isEmpty ? 'add notes...' : surface.notes,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontSize: 4, // Reduced by 1 from 5
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black, // Changed to black text
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex(
                  '#EADFC9',
                ), // headerBackgroundColor equivalent
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 3.5,
              ), // Reduced by 1 from 4.5
              cellHeight: 14, // Slightly increased row height
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center, // Changed to center
                2: pw.Alignment.center, // Changed to center
                3: pw.Alignment.center, // Changed to center
                4: pw.Alignment.center, // Changed to center
                5: pw.Alignment.center, // Changed to center
                6: pw.Alignment.center, // Changed to center
                7: pw.Alignment.center, // Changed to center
                8: pw.Alignment.center, // Changed to center
                9: pw.Alignment.center, // Changed to center
                10: pw.Alignment.center, // Changed to center
                11: pw.Alignment.center, // Changed to center
                12: pw.Alignment.center, // Changed to center
                13: pw.Alignment.center, // Changed to center
                14: pw.Alignment.center, // Changed to center
                15: pw.Alignment.center, // Changed to center
                16: pw.Alignment.center, // Changed to center
                17: pw.Alignment.center, // Changed to center
                18: pw.Alignment.center, // Changed to center
                19: pw.Alignment.center, // Changed to center
              },
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildLogoFromBase64() {
    try {
      if (widget.logoBase64 == null) {
        return pw.Text(
          'LOGO',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        );
      }

      // Extract base64 data (remove data:image/xxx;base64, prefix)
      String base64Data = widget.logoBase64!;
      if (base64Data.contains(',')) {
        base64Data = base64Data.split(',')[1];
      }

      final bytes = base64Decode(base64Data);
      return pw.Image(
        pw.MemoryImage(bytes),
        width: 224, // 30% smaller (320 * 0.7)
        height: 112, // 30% smaller (160 * 0.7)
        fit: pw.BoxFit.contain,
      );
    } catch (e) {
      return pw.Text(
        'LOGO',
        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      );
    }
  }

  String _generateExcelContent() {
    List<List<dynamic>> csvData = [];

    // Header information
    csvData.add(['PROJECT REPORT']);
    csvData.add([
      'Generated on',
      _formatDateTimeWithoutSeconds(DateTime.now()),
    ]);
    csvData.add([]);

    // Surface details
    csvData.add(['SURFACE DETAILS']);
    csvData.add([
      'Screen Nr',
      'Screen Name',
      'LED Product',
      'H Res (px)',
      'V Res (px)',
      'Width (m)',
      'Height (m)',
      'SQM (m²)',
      'Proc Main',
      'BU Proc',
      'Full Panels',
      'Half Panels',
      'Power (kW)',
      'Weight (kg)',
      'Single Header',
      'GAC',
      '3.25t Shackle',
      'Volume (m³)',
      'Dollys/Cage',
      'Notes',
    ]);

    for (int i = 0; i < widget.surfaces.length; i++) {
      Surface surface = widget.surfaces[i];
      csvData.add([
        i + 1,
        surface.name.isEmpty ? 'Surface ${i + 1}' : surface.name,
        surface.selectedLED?.name ?? '',
        surface.calculation?.pixelsWidth ?? 0,
        surface.calculation?.pixelsHeight ?? 0,
        surface.width ?? 0,
        surface.height ?? 0,
        surface.area?.toStringAsFixed(2) ?? '0',
        surface.calculation?.novastarMain ?? 0,
        surface.calculation?.novastarBU ?? 0,
        surface.calculation?.totalFullPanels ?? 0,
        surface.calculation?.totalHalfPanels ?? 0,
        surface.calculation != null
            ? (surface.calculation!.maxPower / 1000).toStringAsFixed(2)
            : '0.00',
        surface.totalWeight?.toStringAsFixed(0) ?? '0',
        surface.calculation?.singleHeader ?? 0,
        surface.calculation?.gacSpanset4m ?? 0,
        surface.calculation?.shackle25t ?? 0,
        surface.calculation?.shippingVolume.toStringAsFixed(2) ?? '0.00',
        surface.calculation?.dollysPerCase ?? 0,
        surface.notes.replaceAll('"', '""'),
      ]);
    }

    return const ListToCsvConverter().convert(csvData);
  }

  String _generateDetailedContent(String format) {
    StringBuffer content = StringBuffer();
    content.writeln('======================================');
    content.writeln('           PROJECT REPORT');
    content.writeln('              $format');
    content.writeln('======================================');
    content.writeln('Generated on: ${DateTime.now().toLocal()}');
    content.writeln('');

    content.writeln('SURFACE DETAILS:');
    content.writeln('----------------');
    content.writeln(
      'Screen | Name | LED Product | H Res | V Res | Width | Height | SQM | Power | Weight | Volume | Notes',
    );
    content.writeln('-' * 120);

    for (int i = 0; i < widget.surfaces.length; i++) {
      Surface surface = widget.surfaces[i];
      String name = surface.name.isEmpty ? 'Surface ${i + 1}' : surface.name;
      String ledProduct = surface.selectedLED?.name ?? '-';
      String hRes = surface.calculation?.pixelsWidth.toString() ?? '0';
      String vRes = surface.calculation?.pixelsHeight.toString() ?? '0';
      String width = surface.width?.toString() ?? '0';
      String height = surface.height?.toString() ?? '0';
      String sqm = surface.area?.toStringAsFixed(2) ?? '0';
      String power = surface.calculation != null
          ? (surface.calculation!.maxPower / 1000).toStringAsFixed(2)
          : '0.00';
      String weight = surface.totalWeight?.toStringAsFixed(0) ?? '0';
      String volume =
          surface.calculation?.shippingVolume.toStringAsFixed(2) ?? '0.00';
      String notes = surface.notes.isEmpty ? '-' : surface.notes;

      content.writeln(
        '${i + 1} | $name | $ledProduct | $hRes | $vRes | $width | $height | $sqm | $power | $weight | $volume | $notes',
      );
    }

    content.writeln('');
    content.writeln('Generated by LED Calculator 2.0');
    content.writeln('Professional LED Installation Planning');

    return content.toString();
  }

  String _generateTextContent() {
    return _generateDetailedContent('Text Export');
  }
}
