import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/surface_model.dart';
import '../services/pixel_map_service.dart';
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

class LEDStudyDialog extends StatefulWidget {
  final List<Surface> surfaces;
  final bool isDarkMode;
  final ProjectData? projectData;
  final String? logoBase64;
  final String? logoFileName;
  final Function(ProjectData)? onProjectDataChanged;

  const LEDStudyDialog({
    super.key,
    required this.surfaces,
    required this.isDarkMode,
    this.projectData,
    this.logoBase64,
    this.logoFileName,
    this.onProjectDataChanged,
  });

  @override
  State<LEDStudyDialog> createState() => _LEDStudyDialogState();
}

class _LEDStudyDialogState extends State<LEDStudyDialog> {
  // Controllers for editable project data
  late TextEditingController _projectNumberController;
  late TextEditingController _projectNameController;
  late TextEditingController _projectManagerController;
  late TextEditingController _clientNameController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;

  bool _isGenerating = false;

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

    _generatePixelMapPreviews();
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

  Future<void> _generatePixelMapPreviews() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // Generate pixel map previews for display
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate processing

      setState(() {
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      print('Error generating pixel map previews: $e');
    }
  }

  ProjectData _getCurrentProjectData() {
    return ProjectData(
      projectNumber: _projectNumberController.text,
      projectName: _projectNameController.text,
      projectManager: _projectManagerController.text,
      clientName: _clientNameController.text,
      location: _locationController.text,
      description: _descriptionController.text,
    );
  }

  String _generateFileName() {
    String fileName = 'LED_Study';

    if (_projectNumberController.text.isNotEmpty) {
      fileName += '_${_projectNumberController.text}';
    }

    if (_projectNameController.text.isNotEmpty) {
      fileName += '_${_projectNameController.text}';
    }

    if (_projectNumberController.text.isEmpty &&
        _projectNameController.text.isEmpty) {
      fileName += '_${DateTime.now().millisecondsSinceEpoch}';
    }

    return fileName;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 1200,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: widget.isDarkMode
              ? Colors.grey[800]
              : const Color(0xFFF7F6F3), // Very light warm gray
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: widget.isDarkMode ? Colors.white : headerTextColor,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: headerBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(13),
                  topRight: Radius.circular(13),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.description, color: headerTextColor, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Generate Project Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: headerTextColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: headerTextColor),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Information Form
                    _buildProjectInfoForm(),

                    const SizedBox(height: 32),

                    // Surfaces Summary Preview
                    _buildSurfacesPreviewSection(),

                    const SizedBox(height: 32),

                    // Pixel Maps Preview
                    _buildPixelMapsPreviewSection(),
                  ],
                ),
              ),
            ),

            // Footer buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
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
                    child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _isGenerating ? null : _generatePDF,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonBackgroundColor,
                      foregroundColor: buttonTextColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                    ),
                    child: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          )
                        : const Text(
                            'Generate PDF',
                            style: TextStyle(
                              fontSize: 16,
                              color: buttonTextColor,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectInfoForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: borderColorLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _projectNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Project Number',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _projectNameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _projectManagerController,
                  decoration: const InputDecoration(
                    labelText: 'Project Manager',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _clientNameController,
                  decoration: const InputDecoration(
                    labelText: 'Client Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSurfacesPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: borderColorLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Surfaces Summary Preview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (widget.surfaces.isEmpty)
            const Text('No surfaces available')
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('LED Product')),
                  DataColumn(label: Text('W(m)')),
                  DataColumn(label: Text('H(m)')),
                  DataColumn(label: Text('SQM')),
                  DataColumn(label: Text('H Res')),
                  DataColumn(label: Text('V Res')),
                  DataColumn(label: Text('Proc Main')),
                  DataColumn(label: Text('BU Proc')),
                  DataColumn(label: Text('Full Panels')),
                  DataColumn(label: Text('Half Panels')),
                  DataColumn(label: Text('Power(kW)')),
                  DataColumn(label: Text('Weight(kg)')),
                  DataColumn(label: Text('Single Header')),
                  DataColumn(label: Text('GAC')),
                  DataColumn(label: Text('3.25t Shackle')),
                  DataColumn(label: Text('Volume(m³)')),
                  DataColumn(label: Text('Dollys/Cage')),
                  DataColumn(label: Text('Notes')),
                ],
                rows: widget.surfaces.asMap().entries.map((entry) {
                  int index = entry.key;
                  Surface surface = entry.value;

                  return DataRow(
                    cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(
                        Text(
                          surface.name.isEmpty
                              ? 'Surface ${index + 1}'
                              : surface.name,
                        ),
                      ),
                      DataCell(Text(surface.selectedLED?.name ?? '-')),
                      DataCell(Text('${surface.width ?? 0}')),
                      DataCell(Text('${surface.height ?? 0}')),
                      DataCell(Text(surface.area?.toStringAsFixed(2) ?? '0')),
                      DataCell(
                        Text('${surface.calculation?.pixelsWidth ?? 0}'),
                      ),
                      DataCell(
                        Text('${surface.calculation?.pixelsHeight ?? 0}'),
                      ),
                      DataCell(
                        Text('${surface.calculation?.novastarMain ?? 0}'),
                      ),
                      DataCell(Text('${surface.calculation?.novastarBU ?? 0}')),
                      DataCell(
                        Text('${surface.calculation?.totalFullPanels ?? 0}'),
                      ),
                      DataCell(
                        Text('${surface.calculation?.totalHalfPanels ?? 0}'),
                      ),
                      DataCell(
                        Text(
                          surface.calculation != null
                              ? (surface.calculation!.maxPower / 1000)
                                    .toStringAsFixed(2)
                              : '0.00',
                        ),
                      ),
                      DataCell(
                        Text(surface.totalWeight?.toStringAsFixed(0) ?? '0'),
                      ),
                      DataCell(
                        Text('${surface.calculation?.singleHeader ?? 0}'),
                      ),
                      DataCell(
                        Text('${surface.calculation?.gacSpanset4m ?? 0}'),
                      ),
                      DataCell(Text('${surface.calculation?.shackle25t ?? 0}')),
                      DataCell(
                        Text(
                          surface.calculation?.shippingVolume.toStringAsFixed(
                                2,
                              ) ??
                              '0.00',
                        ),
                      ),
                      DataCell(
                        Text('${surface.calculation?.dollysPerCase ?? 0}'),
                      ),
                      DataCell(
                        Container(
                          alignment: Alignment.center,
                          child: Text(
                            surface.notes.isEmpty
                                ? 'add notes...'
                                : surface.notes,
                            style: TextStyle(
                              fontSize: 10,
                              color: surface.notes.isEmpty
                                  ? Colors.grey[500]
                                  : textColorPrimary,
                              fontStyle: surface.notes.isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPixelMapsPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: borderColorLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pixel Maps Preview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (widget.surfaces.isEmpty)
            const Text('No surfaces available for pixel maps')
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: widget.surfaces.asMap().entries.map((entry) {
                int index = entry.key;
                Surface surface = entry.value;

                return _buildPixelMapPreview(surface, index);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPixelMapPreview(Surface surface, int index) {
    if (surface.calculation == null) {
      return Container(
        width: 250,
        height: 180,
        decoration: BoxDecoration(
          border: Border.all(color: borderColorLight),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Text(
                'Surface ${index + 1}: ${surface.name.isEmpty ? 'Unnamed' : surface.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // No calculation message
            const Expanded(
              child: Center(
                child: Text(
                  'No calculation available',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Use the shared pixel map service for accurate rendering
    return Column(
      children: [
        // Header
        Container(
          width: 250,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Text(
            'Surface ${index + 1}: ${surface.name.isEmpty ? 'Unnamed' : surface.name}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),

        // Clickable pixel map preview using shared service
        GestureDetector(
          onTap: () => _showEnlargedPixelMap(surface, index),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: PixelMapService.createPixelMapPreview(
              surface,
              index,
              width: 250,
              height: 150,
            ),
          ),
        ),
      ],
    );
  }

  void _showEnlargedPixelMap(Surface surface, int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _EnlargedPixelMapOverlay(
            surface: surface,
            index: index,
            animation: animation,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _generatePDF() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // Update project data callback
      if (widget.onProjectDataChanged != null) {
        widget.onProjectDataChanged!(_getCurrentProjectData());
      }

      final pdf = pw.Document();

      // Add main page with project info
      await _addMainPage(pdf);

      // Add pixel map pages
      await _addPixelMapPages(pdf);

      // Generate and download PDF
      final pdfBytes = await pdf.save();
      await FileService.downloadFile(
        pdfBytes,
        '${_generateFileName()}.pdf',
        'application/pdf',
      );

      Navigator.of(context).pop();
    } catch (e) {
      print('Error generating PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _addMainPage(pw.Document pdf) async {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.all(10), // Minimal margins
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title - moved to left corner and removed underline
              pw.Container(
                width: double.infinity,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LED Study',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Generated date - show date only
              pw.Text(
                'Generated on: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
              ),

              pw.SizedBox(height: 30),

              // Project information
              _buildProjectInfoSection(),

              pw.Spacer(),

              // Logo if available
              if (widget.logoBase64 != null)
                pw.Container(
                  alignment: pw.Alignment.bottomRight,
                  child: pw.Container(
                    width: 100,
                    height: 100,
                    child: pw.Text(
                      'Logo',
                    ), // Placeholder - implement logo loading
                  ),
                ),
            ],
          );
        },
      ),
    );

    // Add surfaces summary page with minimal margins
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.all(10), // Minimal margins
        build: (pw.Context context) {
          return _buildSurfacesSummaryPage();
        },
      ),
    );
  }

  pw.Widget _buildProjectInfoSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (_projectNumberController.text.isNotEmpty)
          _buildInfoRow('Project Number:', _projectNumberController.text),
        if (_projectNameController.text.isNotEmpty)
          _buildInfoRow('Project Name:', _projectNameController.text),
        if (_clientNameController.text.isNotEmpty)
          _buildInfoRow('Client:', _clientNameController.text),
        if (_locationController.text.isNotEmpty)
          _buildInfoRow('Location:', _locationController.text),
        if (_projectManagerController.text.isNotEmpty)
          _buildInfoRow('Project Manager:', _projectManagerController.text),
        if (_descriptionController.text.isNotEmpty)
          _buildInfoRow('Description:', _descriptionController.text),
      ],
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  pw.Widget _buildSurfacesSummaryPage() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Surfaces Summary',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ), // Reduced by 50% from 18
        ),
        pw.SizedBox(height: 10), // Reduced spacing
        // Surfaces table with all comprehensive columns
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            // Header with beige background - NO ORANGE!
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex(
                  '#EADFC9',
                ), // headerBackgroundColor equivalent
              ), // Changed to beige - NO ORANGE!
              children: [
                _buildTableCell('#', isHeader: true),
                _buildTableCell('Name', isHeader: true),
                _buildTableCell('LED Product', isHeader: true),
                _buildTableCell('W(m)', isHeader: true),
                _buildTableCell('H(m)', isHeader: true),
                _buildTableCell('SQM', isHeader: true),
                _buildTableCell('H Res', isHeader: true),
                _buildTableCell('V Res', isHeader: true),
                _buildTableCell('Proc Main', isHeader: true),
                _buildTableCell('BU Proc', isHeader: true),
                _buildTableCell('Full Panels', isHeader: true),
                _buildTableCell('Half Panels', isHeader: true),
                _buildTableCell('Power(kW)', isHeader: true),
                _buildTableCell('Weight(kg)', isHeader: true),
                _buildTableCell('Single Header', isHeader: true),
                _buildTableCell('GAC', isHeader: true),
                _buildTableCell('3.25t Shackle', isHeader: true),
                _buildTableCell('Volume(m³)', isHeader: true),
                _buildTableCell('Dollys/Cage', isHeader: true),
                _buildTableCell('Notes', isHeader: true),
              ],
            ),

            // Data rows - surface numbering will pull from LED summary
            ...widget.surfaces.asMap().entries.map((entry) {
              int index = entry.key;
              Surface surface = entry.value;

              return pw.TableRow(
                children: [
                  _buildTableCell(
                    '${index + 1}',
                  ), // This will match LED summary numbering
                  _buildTableCell(
                    surface.name.isEmpty
                        ? 'Surface ${index + 1}'
                        : surface.name,
                  ),
                  _buildTableCell(surface.selectedLED?.name ?? '-'),
                  _buildTableCell('${surface.width ?? 0}'),
                  _buildTableCell('${surface.height ?? 0}'),
                  _buildTableCell(surface.area?.toStringAsFixed(2) ?? '0'),
                  _buildTableCell('${surface.calculation?.pixelsWidth ?? 0}'),
                  _buildTableCell('${surface.calculation?.pixelsHeight ?? 0}'),
                  _buildTableCell('${surface.calculation?.novastarMain ?? 0}'),
                  _buildTableCell('${surface.calculation?.novastarBU ?? 0}'),
                  _buildTableCell(
                    '${surface.calculation?.totalFullPanels ?? 0}',
                  ),
                  _buildTableCell(
                    '${surface.calculation?.totalHalfPanels ?? 0}',
                  ),
                  _buildTableCell(
                    surface.calculation != null
                        ? (surface.calculation!.maxPower / 1000)
                              .toStringAsFixed(2)
                        : '0.00',
                  ),
                  _buildTableCell(
                    surface.totalWeight?.toStringAsFixed(0) ?? '0',
                  ),
                  _buildTableCell('${surface.calculation?.singleHeader ?? 0}'),
                  _buildTableCell('${surface.calculation?.gacSpanset4m ?? 0}'),
                  _buildTableCell('${surface.calculation?.shackle25t ?? 0}'),
                  _buildTableCell(
                    surface.calculation?.shippingVolume.toStringAsFixed(2) ??
                        '0.00',
                  ),
                  _buildTableCell('${surface.calculation?.dollysPerCase ?? 0}'),
                  _buildTableCell(
                    surface.notes.isEmpty ? 'add notes...' : surface.notes,
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4), // Reduced padding for more space
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 6 : 5, // Reduced by 50% from 12/10 to 6/5
          color: isHeader
              ? PdfColor.fromHex(
                  '#C7B299',
                ) // Dark sand header text - NO WHITE ON ORANGE!
              : PdfColors.black, // Dark sand text on beige header
        ),
      ),
    );
  }

  Future<void> _addPixelMapPages(pw.Document pdf) async {
    for (int i = 0; i < widget.surfaces.length; i++) {
      final surface = widget.surfaces[i];
      if (surface.calculation != null) {
        // Generate the pixel map image using the smart service with cloud support
        final pixelMapBytes = await PixelMapService.createPixelMapImageSmart(
          surface,
          i,
          showGrid: true,
          showPanelNumbers: true,
        );

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: pw.EdgeInsets.all(10), // Minimal margins
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Page title - matching LED summary numbering
                  pw.Text(
                    'Pixel Map - Surface ${i + 1}: ${surface.name.isEmpty ? 'Surface ${i + 1}' : surface.name}',
                    style: pw.TextStyle(
                      fontSize: 9, // Reduced font size (50% of 18)
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),

                  pw.SizedBox(height: 5), // Reduced spacing
                  // Surface info in compact format
                  pw.Text(
                    'LED: ${surface.selectedLED?.name ?? 'Not selected'} | Size: ${surface.width ?? 0}×${surface.height ?? 0}mm | Resolution: ${surface.calculation!.pixelsWidth}×${surface.calculation!.pixelsHeight}px | Panels: ${surface.calculation!.panelsWidth}×${surface.calculation!.panelsHeight}',
                    style: const pw.TextStyle(fontSize: 6), // Reduced font size
                  ),

                  pw.SizedBox(height: 10), // Minimal spacing
                  // Pixel map placed directly under surface details, no frame
                  pw.Expanded(
                    child: pw.Container(
                      width: double.infinity,
                      child: pw.Image(
                        pw.MemoryImage(pixelMapBytes),
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }
    }
  }
}

// Enlarged pixel map overlay widget
class _EnlargedPixelMapOverlay extends StatelessWidget {
  final Surface surface;
  final int index;
  final Animation<double> animation;

  const _EnlargedPixelMapOverlay({
    required this.surface,
    required this.index,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.8),
            child: Center(
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
                child: Container(
                  margin: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: headerBackgroundColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Surface ${index + 1}: ${surface.name.isEmpty ? 'Unnamed' : surface.name}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: headerTextColor,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(Icons.close, color: headerTextColor),
                            ),
                          ],
                        ),
                      ),

                      // Surface info
                      if (surface.calculation != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.grey[100]),
                          child: Text(
                            'LED: ${surface.selectedLED?.name ?? 'Not selected'} | Size: ${surface.width ?? 0}×${surface.height ?? 0}mm | Resolution: ${surface.calculation!.pixelsWidth}×${surface.calculation!.pixelsHeight}px | Panels: ${surface.calculation!.panelsWidth}×${surface.calculation!.panelsHeight}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Enlarged pixel map
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                            maxHeight: MediaQuery.of(context).size.height * 0.6,
                          ),
                          padding: const EdgeInsets.all(20),
                          child: PixelMapService.createPixelMapPreview(
                            surface,
                            index,
                            width: MediaQuery.of(context).size.width * 0.7,
                            height: MediaQuery.of(context).size.height * 0.5,
                          ),
                        ),
                      ),

                      // Instructions
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Press ESC key or click anywhere to close',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
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
    );
  }
}
