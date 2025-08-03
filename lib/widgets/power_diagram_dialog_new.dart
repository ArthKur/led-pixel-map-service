import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../models/surface_model.dart';

// Border colors as per style guide
const Color borderColorLight = Color(0xFFE7DCCC); // Lighter border #E7DCCC
const Color borderColorDark = Color(0xFFD4C7B7); // Darker border #D4C7B7

// Text colors as per style guide
const Color textColorPrimary = Color(0xFF383838); // Deep neutral gray for most text
const Color textColorSecondary = Color(0xFFA2A09A); // Light gray for secondary/disabled text

// Header/accent colors as per style guide
const Color headerBackgroundColor = Color(0xFFEADFC9); // Warm tan/sand/cream #EADFC9
const Color headerTextColor = Color(0xFFC7B299); // Slightly deeper sand #C7B299

// Define the new button background color as per style guide
const Color buttonBackgroundColor = Color.fromRGBO(247, 238, 221, 1.0);

// Define the new button text color as per style guide (30% darker)
const Color buttonTextColor = Color.fromRGBO(125, 117, 103, 1.0);

class PowerLine {
  List<Offset> points;
  String powerNumber;
  Color color;
  List<int> connectedPanels; // Track which panels this line connects

  PowerLine({
    required this.points,
    required this.powerNumber,
    this.color = Colors.blue,
    this.connectedPanels = const [],
  });
}

class PowerDiagramDialog extends StatefulWidget {
  final List<Surface> surfaces;
  final bool isDarkMode;

  const PowerDiagramDialog({
    super.key,
    required this.surfaces,
    required this.isDarkMode,
  });

  @override
  State<PowerDiagramDialog> createState() => _PowerDiagramDialogState();
}

class _PowerDiagramDialogState extends State<PowerDiagramDialog> {
  int _currentSurfaceIndex = 0;
  final List<PowerLine> _powerLines = [];
  bool _isDrawing = false;
  List<Offset> _currentLine = [];
  final TextEditingController _powerNumberController = TextEditingController();
  String _currentPowerNumber = "1";
  List<List<Offset>> _panelCenters = []; // Store panel center points for snapping

  @override
  void initState() {
    super.initState();
    _powerNumberController.text = _currentPowerNumber;
  }

  @override
  void dispose() {
    _powerNumberController.dispose();
    super.dispose();
  }

  void _onPanelCentersCalculated(List<List<Offset>> centers) {
    _panelCenters = centers;
  }

  void _startDrawing(Offset point) {
    // Find the nearest panel center for snapping
    final snappedPoint = _snapToNearestPanel(point);
    setState(() {
      _isDrawing = true;
      _currentLine = [snappedPoint];
    });
  }

  void _continueDrawing(Offset point) {
    if (_isDrawing) {
      setState(() {
        // For drawing preview, just store the raw points
        if (_currentLine.length == 1) {
          _currentLine.add(point);
        } else {
          _currentLine[1] = point; // Update the end point while drawing
        }
      });
    }
  }

  void _endDrawing() {
    if (_isDrawing && _currentLine.length >= 2) {
      // Snap the end point to nearest panel center
      final lastPoint = _currentLine.last;
      final snappedEndPoint = snapToNearestPanel(lastPoint);
      
      // Create perfectly straight line between start and end points
      final startPoint = _currentLine.first;
      final straightLine = createStraightLine(startPoint, snappedEndPoint);
      
  void endDrawing() {
    if (_isDrawing && _currentLine.length >= 2) {
      // Snap the end point to nearest panel center
      final lastPoint = _currentLine.last;
      final snappedEndPoint = snapToNearestPanel(lastPoint);
      
      // Create perfectly straight line between start and end points
      final startPoint = _currentLine.first;
      final straightLine = createStraightLine(startPoint, snappedEndPoint);
      
      // Count connected panels for this line
      final connectedPanels = getConnectedPanels(straightLine);
      
      setState(() {
        _powerLines.add(PowerLine(
          points: straightLine,
          powerNumber: _currentPowerNumber,
          color: Colors.blue,
          connectedPanels: connectedPanels,
        ));
        _isDrawing = false;
        _currentLine = [];
        
        // Auto-increment power number intelligently
        if (RegExp(r'^\d+$').hasMatch(_currentPowerNumber)) {
          // Pure number - increment it
          int currentNum = int.parse(_currentPowerNumber);
          _currentPowerNumber = (currentNum + 1).toString();
        } else {
          // Other cases - just increment any number found
          RegExp regExp = RegExp(r'(\d+)');
          Match? match = regExp.firstMatch(_currentPowerNumber);
          if (match != null) {
            int currentNum = int.parse(match.group(1)!);
            _currentPowerNumber = _currentPowerNumber.replaceFirst(RegExp(r'\d+'), (currentNum + 1).toString());
          } else {
            // No number found, append a number
            _currentPowerNumber = '$_currentPowerNumber 2';
          }
        }
        
        _powerNumberController.text = _currentPowerNumber;
      });
    } else {
      setState(() {
        _isDrawing = false;
        _currentLine = [];
      });
    }
  }

  // Create a perfectly straight line with optional guide points for complex routing
  List<Offset> createStraightLine(Offset start, Offset end) {
    // For now, create a simple straight line
    // In the future, this could include smart routing around obstacles
    return [start, end];
  }

  Offset snapToNearestPanel(Offset point) {
    if (_panelCenters.isEmpty) return point;
    
    double minDistance = double.infinity;
    Offset nearestCenter = point;
    
    for (final centers in _panelCenters) {
      for (final center in centers) {
        final distance = (center - point).distance;
        if (distance < minDistance && distance < 50) { // Snap within 50 pixels
          minDistance = distance;
          nearestCenter = center;
        }
      }
    }
    
    return nearestCenter;
  }

  List<int> getConnectedPanels(List<Offset> linePoints) {
    final connectedPanels = <int>[];
    
    for (int i = 0; i < _panelCenters.length; i++) {
      for (int j = 0; j < _panelCenters[i].length; j++) {
        final panelCenter = _panelCenters[i][j];
        // Check if any point in the line is close to this panel center
        for (final point in linePoints) {
          if ((point - panelCenter).distance < 30) { // Within 30 pixels
            final panelNumber = i * (_panelCenters[i].length) + j + 1;
            if (!connectedPanels.contains(panelNumber)) {
              connectedPanels.add(panelNumber);
            }
          }
        }
      }
    }
    
    return connectedPanels;
  }

  void clearPowerLines() {
    setState(() {
      _powerLines.clear();
    });
  }

  void nextSurface() {
    if (_currentSurfaceIndex < widget.surfaces.length - 1) {
      setState(() {
        _currentSurfaceIndex++;
        _powerLines.clear();
      });
    }
  }

  void previousSurface() {
    if (_currentSurfaceIndex > 0) {
      setState(() {
        _currentSurfaceIndex--;
        _powerLines.clear();
      });
    }
  }

  Widget buildSurfaceDrawing() {
    if (widget.surfaces.isEmpty) {
      return const Center(
        child: Text(
          'No surfaces available',
          style: TextStyle(fontSize: 16, color: textColorSecondary),
        ),
      );
    }

    final surface = widget.surfaces[_currentSurfaceIndex];
    
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColorLight, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: GestureDetector(
        onPanStart: (details) {
          _startDrawing(details.localPosition);
        },
        onPanUpdate: (details) {
          _continueDrawing(details.localPosition);
        },
        onPanEnd: (details) {
          endDrawing();
        },
        child: CustomPaint(
          painter: PowerDiagramPainter(
            surface: surface,
            powerLines: _powerLines,
            currentLine: _currentLine,
            isDrawing: _isDrawing,
            onPanelCentersCalculated: _onPanelCentersCalculated,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  Widget buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.grey[800] : const Color(0xFFF7F6F3),
        border: Border.all(color: borderColorLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Power Line Controls',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : textColorPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Power Number Input
          Row(
            children: [
              Text(
                'Power Line #:',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isDarkMode ? Colors.white : textColorPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: borderColorLight),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: _powerNumberController,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (value) {
                      _currentPowerNumber = value;
                    },
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Control Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: clearPowerLines,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Clear Lines', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_powerLines.isNotEmpty) {
                      setState(() {
                        _powerLines.removeLast();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Undo Last', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Power Summary with panels connected per line
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: headerBackgroundColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColorLight.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.electrical_services,
                      size: 16,
                      color: widget.isDarkMode ? Colors.white : textColorPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Power Summary',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode ? Colors.white : textColorPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                buildSummaryRow('Total Lines:', '${_powerLines.length}', Colors.blue[700]!),
                
                if (widget.surfaces.isNotEmpty && _currentSurfaceIndex < widget.surfaces.length) ...[
                  const Divider(height: 16, thickness: 1),
                  buildSummaryRow('Surface:', widget.surfaces[_currentSurfaceIndex].name, textColorPrimary),
                  if (widget.surfaces[_currentSurfaceIndex].calculation != null) ...[
                    buildSummaryRow('Panels:', '${widget.surfaces[_currentSurfaceIndex].calculation!.totalFullPanels + widget.surfaces[_currentSurfaceIndex].calculation!.totalHalfPanels}', textColorSecondary),
                    buildSummaryRow('Max Power:', '${widget.surfaces[_currentSurfaceIndex].calculation!.maxPower.toStringAsFixed(1)}kW', textColorSecondary),
                  ],
                ],
                
                // Show panels connected per power line
                if (_powerLines.isNotEmpty) ...[
                  const Divider(height: 16, thickness: 1),
                  Text(
                    'Panels per Line:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: Column(
                        children: _powerLines.map((line) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Line ${line.powerNumber}:',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.isDarkMode ? Colors.grey[300] : textColorSecondary,
                                ),
                              ),
                              Text(
                                '${line.connectedPanels.length} panels',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSummaryRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: widget.isDarkMode ? Colors.grey[300] : textColorSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: widget.isDarkMode ? Colors.grey[900] : const Color(0xFFF7F6F3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isDarkMode ? Colors.grey[700]! : borderColorLight,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.grey[800] : headerBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Power Diagram Generator',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : textColorPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (widget.surfaces.length > 1) ...[
                    IconButton(
                      onPressed: _currentSurfaceIndex > 0 ? previousSurface : null,
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: widget.isDarkMode ? Colors.white : textColorPrimary,
                      ),
                    ),
                    Text(
                      '${_currentSurfaceIndex + 1} / ${widget.surfaces.length}',
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.isDarkMode ? Colors.white : textColorPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: _currentSurfaceIndex < widget.surfaces.length - 1 
                          ? nextSurface 
                          : null,
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: widget.isDarkMode ? Colors.white : textColorPrimary,
                      ),
                    ),
                  ],
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: widget.isDarkMode ? Colors.white : textColorPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Surface Name
                    if (widget.surfaces.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode ? Colors.grey[700] : Colors.white,
                          border: Border.all(color: borderColorLight),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Surface: ${widget.surfaces[_currentSurfaceIndex].name}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.isDarkMode ? Colors.white : textColorPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Main content row
                    Expanded(
                      child: Row(
                        children: [
                          // Drawing area
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.touch_app,
                                      size: 16,
                                      color: widget.isDarkMode ? Colors.grey[400] : textColorSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Draw power lines from panel centers. Lines snap automatically.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: widget.isDarkMode ? Colors.grey[400] : textColorSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Blue lines with arrows will be created automatically.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.isDarkMode ? Colors.grey[500] : textColorSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                Expanded(child: buildSurfaceDrawing()),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 20),
                          
                          // Control panel
                          Expanded(
                            flex: 1,
                            child: buildControlPanel(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.grey[800] : const Color(0xFFF7F6F3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: widget.isDarkMode ? Colors.white : buttonTextColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Show comprehensive summary and close
                      final surface = widget.surfaces[_currentSurfaceIndex];
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: widget.isDarkMode ? Colors.grey[800] : Colors.white,
                          title: Row(
                            children: [
                              Icon(
                                Icons.electrical_services,
                                color: Colors.blue[600],
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Power Diagram Complete',
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white : textColorPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          content: SizedBox(
                            width: 300,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: headerBackgroundColor.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderColorLight),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Surface: ${surface.name}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: widget.isDarkMode ? Colors.white : textColorPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      buildSummaryRow('Total Power Lines:', '${_powerLines.length}', Colors.blue[700]!),
                                      
                                      if (surface.calculation != null) ...[
                                        const Divider(height: 16),
                                        Text(
                                          'Surface Details:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: widget.isDarkMode ? Colors.white : textColorPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        buildSummaryRow('Total Panels:', '${surface.calculation!.totalFullPanels + surface.calculation!.totalHalfPanels}', textColorSecondary),
                                        buildSummaryRow('Full Panels:', '${surface.calculation!.totalFullPanels}', textColorSecondary),
                                        buildSummaryRow('Half Panels:', '${surface.calculation!.totalHalfPanels}', textColorSecondary),
                                        buildSummaryRow('Max Power:', '${surface.calculation!.maxPower.toStringAsFixed(1)} kW', textColorSecondary),
                                        buildSummaryRow('Avg Power:', '${surface.calculation!.avgPower.toStringAsFixed(1)} kW', textColorSecondary),
                                      ],
                                      
                                      if (_powerLines.isNotEmpty) ...[
                                        const Divider(height: 16),
                                        Text(
                                          'Power Lines with Panel Count:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: widget.isDarkMode ? Colors.white : textColorPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        ...(_powerLines.take(8).map((line) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 1),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Line ${line.powerNumber}:',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: widget.isDarkMode ? Colors.grey[300] : textColorSecondary,
                                                ),
                                              ),
                                              Text(
                                                '${line.connectedPanels.length} panels',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ))),
                                        if (_powerLines.length > 8)
                                          Text(
                                            '... and ${_powerLines.length - 8} more lines',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                              color: widget.isDarkMode ? Colors.grey[400] : textColorSecondary,
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Back to Diagram',
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white : buttonTextColor,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close summary
                                Navigator.of(context).pop(); // Close power diagram
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Finish'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isDarkMode ? const Color(0xFF23272F) : buttonBackgroundColor,
                      foregroundColor: widget.isDarkMode ? Colors.white : buttonTextColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Ready', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PowerDiagramPainter extends CustomPainter {
  final Surface surface;
  final List<PowerLine> powerLines;
  final List<Offset> currentLine;
  final bool isDrawing;
  final Function(List<List<Offset>>) onPanelCentersCalculated;

  PowerDiagramPainter({
    required this.surface,
    required this.powerLines,
    required this.currentLine,
    required this.isDrawing,
    required this.onPanelCentersCalculated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create white background
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    final linePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    List<List<Offset>> panelCenters = [];

    // Draw LED panels using pixel map style but all white with faded numbers
    if (surface.calculation != null) {
      final calc = surface.calculation!;
      
      // Calculate grid dimensions similar to pixel map service
      const double gridMargin = 50;
      final double availableWidth = size.width - (gridMargin * 2);
      final double availableHeight = size.height - (gridMargin * 2);

      final double fullPanelRatio = 1.0;
      final double halfPanelRatio = 0.5;
      final double totalHeightUnits = (calc.fullPanelsHeight * fullPanelRatio) + (calc.halfPanelsHeight * halfPanelRatio);
      
      final double cellWidth = availableWidth / calc.panelsWidth;
      final double fullPanelCellHeight = availableHeight / (totalHeightUnits > 0 ? totalHeightUnits : 1);
      
      final double cellSize = math.min(cellWidth, fullPanelCellHeight);
      final double adjustedFullPanelHeight = cellSize;
      final double adjustedHalfPanelHeight = cellSize * halfPanelRatio;

      final double gridWidth = calc.panelsWidth * cellSize;
      final double gridHeight = (calc.fullPanelsHeight * adjustedFullPanelHeight) + (calc.halfPanelsHeight * adjustedHalfPanelHeight);
      final double gridStartX = (size.width - gridWidth) / 2;
      final double gridStartY = (size.height - gridHeight) / 2;

      // Panel paints
      final panelPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final panelBorderPaint = Paint()
        ..color = Colors.grey[400]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      // Draw panels and collect centers
      double currentY = gridStartY;
      int globalRow = 0;

      // Draw full panel rows
      for (int fullRow = 0; fullRow < calc.fullPanelsHeight; fullRow++) {
        List<Offset> rowCenters = [];
        for (int col = 0; col < calc.panelsWidth; col++) {
          final left = gridStartX + col * cellSize;
          final top = currentY;
          final rect = Rect.fromLTWH(left, top, cellSize, adjustedFullPanelHeight);

          // Draw white panel with gray border
          canvas.drawRect(rect, panelPaint);
          canvas.drawRect(rect, panelBorderPaint);

          // Store panel center for snapping
          final center = Offset(rect.center.dx, rect.center.dy);
          rowCenters.add(center);

          // Draw panel number in center of panel (grey at 50% transparency)
          final panelNumber = (globalRow * calc.panelsWidth) + col + 1;
          final panelText = '$panelNumber';
          textPainter.text = TextSpan(
            text: panelText,
            style: TextStyle(
              color: Colors.grey[500]!.withOpacity(0.5),
              fontSize: math.min(cellSize * 0.15, 16),
              fontWeight: FontWeight.w500,
            ),
          );
          textPainter.layout();

          final textX = center.dx - (textPainter.width / 2);
          final textY = center.dy - (textPainter.height / 2);
          textPainter.paint(canvas, Offset(textX, textY));
        }
        panelCenters.add(rowCenters);
        currentY += adjustedFullPanelHeight;
        globalRow++;
      }

      // Draw half panel rows
      for (int halfRow = 0; halfRow < calc.halfPanelsHeight; halfRow++) {
        List<Offset> rowCenters = [];
        for (int col = 0; col < calc.panelsWidth; col++) {
          final left = gridStartX + col * cellSize;
          final top = currentY;
          final rect = Rect.fromLTWH(left, top, cellSize, adjustedHalfPanelHeight);

          // Draw white half panel with gray border
          canvas.drawRect(rect, panelPaint);
          canvas.drawRect(rect, panelBorderPaint);

          // Store panel center for snapping
          final center = Offset(rect.center.dx, rect.center.dy);
          rowCenters.add(center);

          // Draw panel number in center of panel (grey at 50% transparency)
          final panelNumber = (globalRow * calc.panelsWidth) + col + 1;
          final panelText = '$panelNumber';
          textPainter.text = TextSpan(
            text: panelText,
            style: TextStyle(
              color: Colors.grey[500]!.withOpacity(0.5),
              fontSize: math.min(cellSize * 0.12, 14),
              fontWeight: FontWeight.w500,
            ),
          );
          textPainter.layout();

          final textX = center.dx - (textPainter.width / 2);
          final textY = center.dy - (textPainter.height / 2);
          textPainter.paint(canvas, Offset(textX, textY));
        }
        panelCenters.add(rowCenters);
        currentY += adjustedHalfPanelHeight;
        globalRow++;
      }
    } else {
      // Fallback simple grid
      const rows = 4;
      const cols = 6;
      final cellWidth = (size.width - 100) / cols;
      final cellHeight = (size.height - 100) / rows;
      final startX = (size.width - (cols * cellWidth)) / 2;
      final startY = (size.height - (rows * cellHeight)) / 2;

      final panelPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final panelBorderPaint = Paint()
        ..color = Colors.grey[400]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      for (int row = 0; row < rows; row++) {
        List<Offset> rowCenters = [];
        for (int col = 0; col < cols; col++) {
          final rect = Rect.fromLTWH(
            startX + col * cellWidth,
            startY + row * cellHeight,
            cellWidth,
            cellHeight,
          );

          canvas.drawRect(rect, panelPaint);
          canvas.drawRect(rect, panelBorderPaint);

          final center = Offset(rect.center.dx, rect.center.dy);
          rowCenters.add(center);

          // Panel number in center (grey at 50% transparency)
          final panelNumber = (row * cols) + col + 1;
          textPainter.text = TextSpan(
            text: '$panelNumber',
            style: TextStyle(
              color: Colors.grey[500]!.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          );
          textPainter.layout();
          
          final textX = center.dx - (textPainter.width / 2);
          final textY = center.dy - (textPainter.height / 2);
          textPainter.paint(canvas, Offset(textX, textY));
        }
        panelCenters.add(rowCenters);
      }
    }

    // Notify about panel centers for snapping
    onPanelCentersCalculated(panelCenters);

    // Draw completed power lines
    for (final powerLine in powerLines) {
      drawPowerLine(canvas, powerLine.points, powerLine.powerNumber, linePaint, textPainter);
    }

    // Draw current line being drawn
    if (isDrawing && currentLine.length >= 2) {
      drawCurrentLine(canvas, currentLine, linePaint);
    }
  }

  void drawPowerLine(Canvas canvas, List<Offset> points, String powerNumber, 
                     Paint linePaint, TextPainter textPainter) {
    if (points.length < 2) return;

    // Draw perfectly straight line between start and end points
    final start = points.first;
    final end = points.last;
    canvas.drawLine(start, end, linePaint);

    // Draw professional vector arrow at the end
    drawVectorArrow(canvas, start, end, linePaint);

    // Draw power number label near the start
    textPainter.text = TextSpan(
      text: powerNumber,
      style: const TextStyle(
        color: Colors.blue,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.white,
      ),
    );
    textPainter.layout();
    
    final labelOffset = Offset(
      start.dx + 8,
      start.dy - 18,
    );
    
    // Draw background box for text
    final bgRect = Rect.fromLTWH(
      labelOffset.dx - 3,
      labelOffset.dy - 2,
      textPainter.width + 6,
      textPainter.height + 4,
    );
    final bgPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(3)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(bgRect, const Radius.circular(3)), borderPaint);
    
    textPainter.paint(canvas, labelOffset);
  }

  void drawCurrentLine(Canvas canvas, List<Offset> points, Paint linePaint) {
    if (points.length < 2) return;

    // Draw perfectly straight line during drawing preview
    final currentLinePaint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    // Draw straight line from start to current end point
    canvas.drawLine(points.first, points.last, currentLinePaint);
  }

  void drawVectorArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    const arrowLength = 20.0;
    const arrowAngle = 0.4; // radians (about 23 degrees)

    final direction = (end - start);
    final length = direction.distance;
    if (length == 0) return;

    final unitVector = direction / length;
    
    // Calculate professional arrow head points
    final arrowPoint1 = end - 
        Offset(
          unitVector.dx * arrowLength * math.cos(arrowAngle) - 
          unitVector.dy * arrowLength * math.sin(arrowAngle),
          unitVector.dx * arrowLength * math.sin(arrowAngle) + 
          unitVector.dy * arrowLength * math.cos(arrowAngle),
        );
    
    final arrowPoint2 = end - 
        Offset(
          unitVector.dx * arrowLength * math.cos(-arrowAngle) - 
          unitVector.dy * arrowLength * math.sin(-arrowAngle),
          unitVector.dx * arrowLength * math.sin(-arrowAngle) + 
          unitVector.dy * arrowLength * math.cos(-arrowAngle),
        );

    // Draw filled arrow head for professional look
    final arrowPath = Path();
    arrowPath.moveTo(end.dx, end.dy);
    arrowPath.lineTo(arrowPoint1.dx, arrowPoint1.dy);
    arrowPath.lineTo(arrowPoint2.dx, arrowPoint2.dy);
    arrowPath.close();
    
    final arrowFillPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(arrowPath, arrowFillPaint);
    
    // Draw arrow outline for crisp edges
    final arrowOutlinePaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawPath(arrowPath, arrowOutlinePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
