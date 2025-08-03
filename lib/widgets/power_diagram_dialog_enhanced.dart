import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/surface_model.dart';

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

class PowerLine {
  List<Offset> points;
  String powerNumber;
  Color color;
  List<String>
  connectedPanels; // Track which panels this line connects (now using row.column format)

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
  final Function(List<Surface>)?
  onPowerLinesUpdated; // Callback to save power lines

  const PowerDiagramDialog({
    super.key,
    required this.surfaces,
    required this.isDarkMode,
    this.onPowerLinesUpdated,
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
  String _currentPowerNumber = "1.1";
  final Map<String, Offset> _panelCenters =
      {}; // Store panel centers mapped by panel ID (row.column format) for snapping
  final ScrollController _scrollController =
      ScrollController(); // Add ScrollController

  @override
  void initState() {
    super.initState();
    _powerNumberController.text = _currentPowerNumber;
    // Load existing power lines if any
    _loadPowerLines();
  }

  void _loadPowerLines() {
    // Load power lines from current surface if they exist
    final currentSurface = widget.surfaces[_currentSurfaceIndex];
    if (currentSurface.powerLines != null &&
        currentSurface.powerLines!.isNotEmpty) {
      setState(() {
        _powerLines.clear();
        for (var powerLineData in currentSurface.powerLines!) {
          final points = (powerLineData['points'] as List)
              .map((point) => Offset(point['dx'], point['dy']))
              .toList();
          final connectedPanels = (powerLineData['connectedPanels'] as List)
              .map((panel) => panel.toString())
              .toList();

          _powerLines.add(
            PowerLine(
              points: points,
              powerNumber: powerLineData['powerNumber'],
              color: Colors.blue,
              connectedPanels: connectedPanels,
            ),
          );
        }
        // Update current power number to continue from the last line
        _updateCurrentPowerNumber();
        _powerNumberController.text = _currentPowerNumber;
      });
    }
  }

  @override
  void dispose() {
    _powerNumberController.dispose();
    _scrollController.dispose(); // Dispose ScrollController
    super.dispose();
  }

  // Enhanced method to count all panels along a multi-segment path
  List<String> _getConnectedPanelsAlongPath(List<Offset> pathPoints) {
    if (pathPoints.length < 2 || _panelCenters.isEmpty) return [];

    Set<String> connectedPanels = {};

    // Process each segment in the path
    for (int i = 0; i < pathPoints.length - 1; i++) {
      final segmentStart = pathPoints[i];
      final segmentEnd = pathPoints[i + 1];

      // Get panels along this segment
      final segmentPanels = _getPanelsAlongSegment(segmentStart, segmentEnd);
      connectedPanels.addAll(segmentPanels);
    }

    return connectedPanels.toList()..sort();
  }

  // Helper method to find panels along a single line segment
  List<String> _getPanelsAlongSegment(Offset start, Offset end) {
    List<String> connectedPanels = [];
    const double tolerance = 30.0; // Increased tolerance for line detection

    // Calculate line equation coefficients (ax + by + c = 0)
    final double a = end.dy - start.dy;
    final double b = start.dx - end.dx;
    final double c = end.dx * start.dy - start.dx * end.dy;
    final double lineLength = math.sqrt(a * a + b * b);

    if (lineLength == 0) return connectedPanels;

    // Check each panel to see if it's near the line segment
    for (String panelId in _panelCenters.keys) {
      final center = _panelCenters[panelId]!;

      // Calculate distance from point to line
      final double distance =
          (a * center.dx + b * center.dy + c).abs() / lineLength;

      if (distance <= tolerance) {
        // Check if the point is within the bounds of the line segment
        final double minX = math.min(start.dx, end.dx) - tolerance;
        final double maxX = math.max(start.dx, end.dx) + tolerance;
        final double minY = math.min(start.dy, end.dy) - tolerance;
        final double maxY = math.max(start.dy, end.dy) + tolerance;

        if (center.dx >= minX &&
            center.dx <= maxX &&
            center.dy >= minY &&
            center.dy <= maxY) {
          connectedPanels.add(panelId);
        }
      }
    }

    return connectedPanels;
  }

  void _onPanelCentersCalculated(List<List<Offset>> panelCenters) {
    // Use post-frame callback to avoid setState during paint
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _panelCenters.clear();

        // Convert grid to map with row.column format (matching pixel map)
        for (int row = 0; row < panelCenters.length; row++) {
          for (int col = 0; col < panelCenters[row].length; col++) {
            final panelId =
                '${row + 1}.${col + 1}'; // Creates "1.1", "1.2", "2.1", etc.
            _panelCenters[panelId] = panelCenters[row][col];
          }
        }
      });
    });
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
        // Always snap the current drawing point to nearest panel center
        final snappedPoint = _snapToNearestPanel(point);

        if (_currentLine.length == 1) {
          // First movement - just add the snapped point
          _currentLine.add(snappedPoint);
        } else {
          // Check if we should create a waypoint based on direction change
          if (_shouldCreateWaypoint(snappedPoint)) {
            // Create a waypoint at the previous position
            _currentLine.add(snappedPoint);
          } else {
            // Simply update the end point
            _currentLine[_currentLine.length - 1] = snappedPoint;
          }
        }
      });
    }
  }

  bool _shouldCreateWaypoint(Offset newPoint) {
    if (_currentLine.length < 2) return false;

    final currentEnd = _currentLine[_currentLine.length - 1];
    final previousPoint = _currentLine[_currentLine.length - 2];

    // Calculate the previous direction vector
    final prevDirection = currentEnd - previousPoint;
    // Calculate the new direction vector
    final newDirection = newPoint - currentEnd;

    // If either vector is too small, don't create waypoint
    if (prevDirection.distance < 20 || newDirection.distance < 20) {
      return false;
    }

    // Calculate the angle between the vectors
    final dot =
        prevDirection.dx * newDirection.dx + prevDirection.dy * newDirection.dy;
    final cross =
        prevDirection.dx * newDirection.dy - prevDirection.dy * newDirection.dx;
    final angle = math.atan2(cross, dot).abs();

    // Create waypoint if direction change is significant (more than 45 degrees)
    return angle > math.pi / 4;
  }

  void _addWaypoint() {
    if (_isDrawing && _currentLine.length >= 2) {
      final currentEnd = _currentLine.last;
      final snappedPoint = _snapToNearestPanel(currentEnd);
      setState(() {
        // Replace the current end point with the snapped waypoint
        _currentLine[_currentLine.length - 1] = snappedPoint;
        // Add a new end point that will be updated as the user continues drawing
        _currentLine.add(snappedPoint);
      });
    }
  }

  void _endDrawing() {
    if (_isDrawing && _currentLine.length >= 2) {
      // Snap the end point to nearest panel center
      final lastPoint = _currentLine.last;
      final snappedEndPoint = _snapToNearestPanel(lastPoint);
      _currentLine[_currentLine.length - 1] = snappedEndPoint;

      // Count connected panels for this line (all panels along the path)
      final connectedPanels = _getConnectedPanelsAlongPath(_currentLine);

      setState(() {
        _powerLines.add(
          PowerLine(
            points: List.from(_currentLine),
            powerNumber: _currentPowerNumber,
            color: Colors.blue,
            connectedPanels: connectedPanels,
          ),
        );
        _isDrawing = false;
        _currentLine = [];

        // Auto-increment power number in row.column format
        _incrementPowerNumber();

        _powerNumberController.text = _currentPowerNumber;
      });

      // Save the updated power lines
      _savePowerLines();
    } else {
      setState(() {
        _isDrawing = false;
        _currentLine = [];
      });
    }
  }

  void _incrementPowerNumber() {
    // Parse current power number (format: row.column like "1.2", "2.5")
    final parts = _currentPowerNumber.split('.');
    if (parts.length == 2) {
      final mainChannel = int.tryParse(parts[0]);
      final subChannel = int.tryParse(parts[1]);

      if (mainChannel != null && subChannel != null) {
        // Each main channel has exactly 6 sub-channels (1.1-1.6, 2.1-2.6, etc.)
        const int maxSubChannels = 6;

        // Increment sub-channel, or move to next main channel
        if (subChannel >= maxSubChannels) {
          // If we've reached sub-channel 6, move to next main channel starting at sub-channel 1
          _currentPowerNumber = '${mainChannel + 1}.1';
        } else {
          // Otherwise, just increment the sub-channel
          _currentPowerNumber = '$mainChannel.${subChannel + 1}';
        }
      } else {
        // Fallback if parsing fails
        _currentPowerNumber = '1.1';
      }
    } else {
      // If not in main.sub format, start with 1.1
      _currentPowerNumber = '1.1';
    }
  }

  void _updateCurrentPowerNumber() {
    // Set the current power number to be the next in sequence after the last power line
    if (_powerLines.isEmpty) {
      _currentPowerNumber = '1.1';
    } else {
      final lastPowerNumber = _powerLines.last.powerNumber;
      final parts = lastPowerNumber.split('.');
      if (parts.length == 2) {
        final mainChannel = int.tryParse(parts[0]);
        final subChannel = int.tryParse(parts[1]);

        if (mainChannel != null && subChannel != null) {
          // Each main channel has exactly 6 sub-channels (1.1-1.6, 2.1-2.6, etc.)
          const int maxSubChannels = 6;

          // Increment sub-channel, or move to next main channel
          if (subChannel >= maxSubChannels) {
            // If we've reached sub-channel 6, move to next main channel starting at sub-channel 1
            _currentPowerNumber = '${mainChannel + 1}.1';
          } else {
            // Otherwise, just increment the sub-channel
            _currentPowerNumber = '$mainChannel.${subChannel + 1}';
          }
        } else {
          _currentPowerNumber = '1.1';
        }
      } else {
        _currentPowerNumber = '1.1';
      }
    }
  }

  Offset _snapToNearestPanel(Offset point) {
    if (_panelCenters.isEmpty) return point;

    double minDistance = double.infinity;
    Offset nearestCenter = point;

    for (Offset center in _panelCenters.values) {
      final distance = (point - center).distance;
      if (distance < minDistance) {
        minDistance = distance;
        nearestCenter = center;
      }
    }

    // Increased snap distance for better responsiveness during drawing
    return minDistance < 80.0 ? nearestCenter : point;
  }

  void _savePowerLines() {
    // Save power lines to current surface
    final currentSurface = widget.surfaces[_currentSurfaceIndex];

    // Convert power lines to serializable format
    final powerLinesData = _powerLines.map((powerLine) {
      return {
        'points': powerLine.points
            .map((point) => {'dx': point.dx, 'dy': point.dy})
            .toList(),
        'powerNumber': powerLine.powerNumber,
        'connectedPanels': powerLine.connectedPanels,
      };
    }).toList();

    // Update the surface with power lines data
    currentSurface.powerLines = powerLinesData;

    // Notify parent widget about the update
    if (widget.onPowerLinesUpdated != null) {
      widget.onPowerLinesUpdated!(widget.surfaces);
    }
  }

  void _clearPowerLines() {
    setState(() {
      _powerLines.clear();
      _currentPowerNumber = "1.1"; // Reset to starting number
      _powerNumberController.text = _currentPowerNumber;
    });
    _savePowerLines();
  }

  void _nextSurface() {
    if (_currentSurfaceIndex < widget.surfaces.length - 1) {
      // Save current surface power lines before switching
      _savePowerLines();

      setState(() {
        _currentSurfaceIndex++;
        // Clear current power lines and load new surface
        _powerLines.clear();
        _panelCenters.clear();
        _loadPowerLines();
      });
    }
  }

  void _previousSurface() {
    if (_currentSurfaceIndex > 0) {
      // Save current surface power lines before switching
      _savePowerLines();

      setState(() {
        _currentSurfaceIndex--;
        // Clear current power lines and load new surface
        _powerLines.clear();
        _panelCenters.clear();
        _loadPowerLines();
      });
    }
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
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
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.surfaces.isEmpty) {
      return AlertDialog(
        backgroundColor: widget.isDarkMode
            ? const Color(0xFF23272F) // Gunmetal/slate gray panel background
            : const Color(0xFFF7F6F3), // Very light warm gray
        title: Text(
          'Power Diagram',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : textColorPrimary,
          ),
        ),
        content: const Text('No surfaces available to create power diagrams.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : buttonTextColor,
              ),
            ),
          ),
        ],
      );
    }

    final currentSurface = widget.surfaces[_currentSurfaceIndex];

    return Dialog(
      backgroundColor: widget.isDarkMode
          ? const Color(0xFF23272F) // Gunmetal/slate gray panel background
          : const Color(0xFFF7F6F3), // Very light warm gray
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.electrical_services,
                  color: widget.isDarkMode ? Colors.white : Colors.blue[600],
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'Power Diagram - ${currentSurface.name}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? Colors.white : textColorPrimary,
                  ),
                ),
                const Spacer(),
                if (widget.surfaces.length > 1) ...[
                  IconButton(
                    onPressed: _currentSurfaceIndex > 0
                        ? _previousSurface
                        : null,
                    icon: const Icon(Icons.arrow_back_ios),
                    color: widget.isDarkMode ? Colors.white : buttonTextColor,
                  ),
                  Text(
                    '${_currentSurfaceIndex + 1} / ${widget.surfaces.length}',
                    style: TextStyle(
                      color: widget.isDarkMode
                          ? Colors.white
                          : textColorPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: _currentSurfaceIndex < widget.surfaces.length - 1
                        ? _nextSurface
                        : null,
                    icon: const Icon(Icons.arrow_forward_ios),
                    color: widget.isDarkMode ? Colors.white : buttonTextColor,
                  ),
                ],
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: widget.isDarkMode ? Colors.white : buttonTextColor,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Main content area
            Expanded(
              child: Row(
                children: [
                  // Drawing area
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColorLight),
                      ),
                      child: GestureDetector(
                        onPanStart: (details) {
                          _startDrawing(details.localPosition);
                        },
                        onPanUpdate: (details) {
                          _continueDrawing(details.localPosition);
                        },
                        onPanEnd: (details) {
                          _endDrawing();
                        },
                        onDoubleTap: () {
                          // Double tap to force 90-degree waypoint when drawing
                          if (_isDrawing) {
                            _addWaypoint();
                          }
                        },
                        onTap: () {
                          // Single tap while drawing adds a 90-degree waypoint
                          if (_isDrawing) {
                            _addWaypoint();
                          }
                        },
                        child: CustomPaint(
                          painter: PowerDiagramPainter(
                            surface: currentSurface,
                            powerLines: _powerLines,
                            currentLine: _currentLine,
                            isDrawing: _isDrawing,
                            onPanelCentersCalculated: _onPanelCentersCalculated,
                          ),
                          size: Size.infinite,
                          child: Container(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Control panel
                  Container(
                    width: 280,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: headerBackgroundColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: borderColorLight.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Power number input
                        Row(
                          children: [
                            Icon(
                              Icons.label,
                              size: 16,
                              color: widget.isDarkMode
                                  ? Colors.white
                                  : textColorPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Power Line #:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: widget.isDarkMode
                                    ? Colors.white
                                    : textColorPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _powerNumberController,
                          style: TextStyle(
                            color: widget.isDarkMode
                                ? Colors.white
                                : textColorPrimary,
                          ),
                          onChanged: (value) {
                            _currentPowerNumber = value;
                          },
                          decoration: InputDecoration(
                            hintText: 'Enter power line number',
                            hintStyle: TextStyle(
                              color: widget.isDarkMode
                                  ? Colors.grey[400]
                                  : textColorSecondary,
                            ),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Control Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _clearPowerLines,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[400],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text(
                                  'Clear Lines',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_powerLines.isNotEmpty) {
                                    setState(() {
                                      _powerLines.removeLast();
                                      // Update current power number to the last one + 1
                                      _updateCurrentPowerNumber();
                                      _powerNumberController.text =
                                          _currentPowerNumber;
                                    });
                                    _savePowerLines();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[400],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text(
                                  'Undo Last',
                                  style: TextStyle(fontSize: 12),
                                ),
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
                            border: Border.all(
                              color: borderColorLight.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.electrical_services,
                                    size: 16,
                                    color: widget.isDarkMode
                                        ? Colors.white
                                        : textColorPrimary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Power Summary',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: widget.isDarkMode
                                          ? Colors.white
                                          : textColorPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildSummaryRow(
                                'Total Lines:',
                                '${_powerLines.length}',
                                Colors.blue[700]!,
                              ),

                              if (widget.surfaces.isNotEmpty &&
                                  _currentSurfaceIndex <
                                      widget.surfaces.length) ...[
                                const Divider(height: 16, thickness: 1),
                                _buildSummaryRow(
                                  'Surface:',
                                  widget.surfaces[_currentSurfaceIndex].name,
                                  textColorPrimary,
                                ),
                                if (widget
                                        .surfaces[_currentSurfaceIndex]
                                        .calculation !=
                                    null) ...[
                                  _buildSummaryRow(
                                    'Panels:',
                                    '${widget.surfaces[_currentSurfaceIndex].calculation!.totalFullPanels + widget.surfaces[_currentSurfaceIndex].calculation!.totalHalfPanels}',
                                    textColorSecondary,
                                  ),
                                  _buildSummaryRow(
                                    'Max Power:',
                                    '${widget.surfaces[_currentSurfaceIndex].calculation!.maxPower.toStringAsFixed(1)}kW',
                                    textColorSecondary,
                                  ),
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
                                    color: widget.isDarkMode
                                        ? Colors.white
                                        : textColorPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height:
                                      200, // Fixed height for better scrolling
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.3),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Scrollbar(
                                    controller:
                                        _scrollController, // Use the ScrollController
                                    thumbVisibility: true,
                                    child: ListView.builder(
                                      controller:
                                          _scrollController, // Use the ScrollController
                                      itemCount: _powerLines.length,
                                      itemBuilder: (context, index) {
                                        final line = _powerLines[index];
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: index.isEven
                                                ? Colors.grey.withOpacity(0.05)
                                                : Colors.transparent,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Line ${line.powerNumber}:',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: widget.isDarkMode
                                                        ? Colors.grey[300]
                                                        : textColorSecondary,
                                                  ),
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
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Ready button
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              // Save power lines before showing summary
                              _savePowerLines();

                              // Show summary dialog or proceed
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  final surface =
                                      widget.surfaces[_currentSurfaceIndex];
                                  return AlertDialog(
                                    backgroundColor: widget.isDarkMode
                                        ? const Color(0xFF23272F)
                                        : const Color(0xFFF7F6F3),
                                    title: Row(
                                      children: [
                                        Icon(
                                          Icons.electrical_services,
                                          color: widget.isDarkMode
                                              ? Colors.white
                                              : Colors.blue[600],
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Power Diagram Complete',
                                          style: TextStyle(
                                            color: widget.isDarkMode
                                                ? Colors.white
                                                : textColorPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSummaryRow(
                                          'Total Power Lines:',
                                          '${_powerLines.length}',
                                          Colors.blue[700]!,
                                        ),

                                        if (surface.calculation != null) ...[
                                          const Divider(height: 16),
                                          Text(
                                            'Surface Details:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: widget.isDarkMode
                                                  ? Colors.white
                                                  : textColorPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          _buildSummaryRow(
                                            'Total Panels:',
                                            '${surface.calculation!.totalFullPanels + surface.calculation!.totalHalfPanels}',
                                            textColorSecondary,
                                          ),
                                          _buildSummaryRow(
                                            'Full Panels:',
                                            '${surface.calculation!.totalFullPanels}',
                                            textColorSecondary,
                                          ),
                                          _buildSummaryRow(
                                            'Half Panels:',
                                            '${surface.calculation!.totalHalfPanels}',
                                            textColorSecondary,
                                          ),
                                          _buildSummaryRow(
                                            'Max Power:',
                                            '${surface.calculation!.maxPower.toStringAsFixed(1)} kW',
                                            textColorSecondary,
                                          ),
                                          _buildSummaryRow(
                                            'Avg Power:',
                                            '${surface.calculation!.avgPower.toStringAsFixed(1)} kW',
                                            textColorSecondary,
                                          ),
                                        ],

                                        if (_powerLines.isNotEmpty) ...[
                                          const Divider(height: 16),
                                          Text(
                                            'Power Lines with Panel Count:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: widget.isDarkMode
                                                  ? Colors.white
                                                  : textColorPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          ...(_powerLines
                                              .take(8)
                                              .map(
                                                (line) => Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 1,
                                                      ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        'Line ${line.powerNumber}:',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              widget.isDarkMode
                                                              ? Colors.grey[300]
                                                              : textColorSecondary,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${line.connectedPanels.length} panels',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Colors.blue[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )),
                                          if (_powerLines.length > 8)
                                            Text(
                                              '... and ${_powerLines.length - 8} more lines',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                color: widget.isDarkMode
                                                    ? Colors.grey[400]
                                                    : textColorSecondary,
                                              ),
                                            ),
                                        ],
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: Text(
                                          'Back to Diagram',
                                          style: TextStyle(
                                            color: widget.isDarkMode
                                                ? Colors.white
                                                : buttonTextColor,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(
                                            context,
                                          ).pop(); // Close summary
                                          Navigator.of(
                                            context,
                                          ).pop(); // Close power diagram
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green[600],
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Finish'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.isDarkMode
                                  ? const Color(0xFF23272F)
                                  : buttonBackgroundColor,
                              foregroundColor: widget.isDarkMode
                                  ? Colors.white
                                  : buttonTextColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Ready',
                              style: TextStyle(fontSize: 16),
                            ),
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
    // Enable anti-aliasing for better quality
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    final linePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
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
      final double totalHeightUnits =
          (calc.fullPanelsHeight * fullPanelRatio) +
          (calc.halfPanelsHeight * halfPanelRatio);

      final double cellWidth = availableWidth / calc.panelsWidth;
      final double fullPanelCellHeight =
          availableHeight / (totalHeightUnits > 0 ? totalHeightUnits : 1);

      final double cellSize = math.min(cellWidth, fullPanelCellHeight);
      final double adjustedFullPanelHeight = cellSize;
      final double adjustedHalfPanelHeight = cellSize * halfPanelRatio;

      final double gridWidth = calc.panelsWidth * cellSize;
      final double gridHeight =
          (calc.fullPanelsHeight * adjustedFullPanelHeight) +
          (calc.halfPanelsHeight * adjustedHalfPanelHeight);
      final double gridStartX = (size.width - gridWidth) / 2;
      final double gridStartY = (size.height - gridHeight) / 2;

      // Enhanced panel paints with gradients and better quality
      final panelPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[50]!, Colors.grey[100]!],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      final panelBorderPaint = Paint()
        ..color = Colors.grey[350]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..isAntiAlias = true;

      final panelShadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.08)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
        ..isAntiAlias = true;

      // Draw panels and collect centers
      double currentY = gridStartY;
      int globalRow = 0;

      // Draw full panel rows
      for (int fullRow = 0; fullRow < calc.fullPanelsHeight; fullRow++) {
        List<Offset> rowCenters = [];
        for (int col = 0; col < calc.panelsWidth; col++) {
          final left = gridStartX + col * cellSize;
          final top = currentY;
          final rect = Rect.fromLTWH(
            left,
            top,
            cellSize,
            adjustedFullPanelHeight,
          );

          // Draw subtle shadow for depth
          final shadowRect = Rect.fromLTWH(
            left + 1,
            top + 1,
            cellSize,
            adjustedFullPanelHeight,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(shadowRect, const Radius.circular(2)),
            panelShadowPaint,
          );

          // Draw main panel with rounded corners and gradient
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)),
            panelPaint,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)),
            panelBorderPaint,
          );

          // Store panel center for snapping
          final center = Offset(rect.center.dx, rect.center.dy);
          rowCenters.add(center);

          // Enhanced panel number text with better typography
          final panelText =
              '${globalRow + 1}.${col + 1}'; // Row.Column format like "1.1", "1.2"
          textPainter.text = TextSpan(
            text: panelText,
            style: TextStyle(
              color: Colors.grey[600]!.withOpacity(0.7),
              fontSize: math.max(
                math.min(cellSize * 0.15, 14),
                8,
              ), // Reduced font size
              fontWeight: FontWeight.w500, // Slightly lighter weight
              letterSpacing: 0.3,
            ),
          );
          textPainter.layout();

          // Position text in top-left corner of panel
          final textX = left + 4; // Small margin from left edge
          final textY = top + 3; // Small margin from top edge

          // Add subtle text shadow for better readability
          textPainter.text = TextSpan(
            text: panelText,
            style: TextStyle(
              color: Colors.black.withOpacity(0.08),
              fontSize: math.max(math.min(cellSize * 0.15, 14), 8),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(textX + 0.5, textY + 0.5));

          // Draw main text
          textPainter.text = TextSpan(
            text: panelText,
            style: TextStyle(
              color: Colors.grey[600]!.withOpacity(0.7),
              fontSize: math.max(math.min(cellSize * 0.15, 14), 8),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          );
          textPainter.layout();
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
          final rect = Rect.fromLTWH(
            left,
            top,
            cellSize,
            adjustedHalfPanelHeight,
          );

          // Draw subtle shadow for depth
          final shadowRect = Rect.fromLTWH(
            left + 1,
            top + 1,
            cellSize,
            adjustedHalfPanelHeight,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(shadowRect, const Radius.circular(2)),
            panelShadowPaint,
          );

          // Draw main half panel with rounded corners and gradient
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)),
            panelPaint,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)),
            panelBorderPaint,
          );

          // Store panel center for snapping
          final center = Offset(rect.center.dx, rect.center.dy);
          rowCenters.add(center);

          // Enhanced panel number text for half panels
          final panelText =
              '${globalRow + 1}.${col + 1}'; // Row.Column format like "1.1", "1.2"
          textPainter.text = TextSpan(
            text: panelText,
            style: TextStyle(
              color: Colors.grey[600]!.withOpacity(0.7),
              fontSize: math.max(
                math.min(cellSize * 0.14, 12),
                7,
              ), // Reduced font size for half panels
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          );
          textPainter.layout();

          // Position text in top-left corner of half panel
          final textX = left + 4; // Small margin from left edge
          final textY = top + 2; // Small margin from top edge

          // Add subtle text shadow for better readability
          textPainter.text = TextSpan(
            text: panelText,
            style: TextStyle(
              color: Colors.black.withOpacity(0.08),
              fontSize: math.max(math.min(cellSize * 0.14, 12), 7),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(textX + 0.5, textY + 0.5));

          // Draw main text
          textPainter.text = TextSpan(
            text: panelText,
            style: TextStyle(
              color: Colors.grey[600]!.withOpacity(0.7),
              fontSize: math.max(math.min(cellSize * 0.14, 12), 7),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(textX, textY));
        }
        panelCenters.add(rowCenters);
        currentY += adjustedHalfPanelHeight;
        globalRow++;
      }
    } else {
      // Enhanced fallback grid with better quality
      const rows = 4;
      const cols = 6;
      final cellWidth = (size.width - 100) / cols;
      final cellHeight = (size.height - 100) / rows;
      final startX = (size.width - (cols * cellWidth)) / 2;
      final startY = (size.height - (rows * cellHeight)) / 2;

      final panelPaint = Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey[50]!, Colors.grey[100]!],
            ).createShader(
              Rect.fromLTWH(
                startX,
                startY,
                cols * cellWidth,
                rows * cellHeight,
              ),
            )
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      final panelBorderPaint = Paint()
        ..color = Colors.grey[350]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..isAntiAlias = true;

      final panelShadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.08)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
        ..isAntiAlias = true;

      for (int row = 0; row < rows; row++) {
        List<Offset> rowCenters = [];
        for (int col = 0; col < cols; col++) {
          final rect = Rect.fromLTWH(
            startX + col * cellWidth,
            startY + row * cellHeight,
            cellWidth,
            cellHeight,
          );

          // Draw subtle shadow for depth
          final shadowRect = Rect.fromLTWH(
            startX + col * cellWidth + 1,
            startY + row * cellHeight + 1,
            cellWidth,
            cellHeight,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(shadowRect, const Radius.circular(3)),
            panelShadowPaint,
          );

          // Draw main panel with rounded corners
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(3)),
            panelPaint,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(3)),
            panelBorderPaint,
          );

          final center = Offset(rect.center.dx, rect.center.dy);
          rowCenters.add(center);

          // Enhanced panel number text
          final panelText =
              '${row + 1}.${col + 1}'; // Row.Column format like "1.1", "1.2"
          textPainter.text = TextSpan(
            text: panelText,
            style: TextStyle(
              color: Colors.grey[600]!.withOpacity(0.7),
              fontSize: math.max(
                math.min(cellWidth * 0.15, 14),
                8,
              ), // Reduced font size
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          );
          textPainter.layout();

          // Position text in top-left corner of panel
          final textX =
              startX + col * cellWidth + 4; // Small margin from left edge
          final textY =
              startY + row * cellHeight + 3; // Small margin from top edge

          // Add subtle text shadow
          textPainter.text = TextSpan(
            text: panelText,
            style: TextStyle(
              color: Colors.black.withOpacity(0.08),
              fontSize: math.max(math.min(cellWidth * 0.15, 14), 8),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(textX + 0.5, textY + 0.5));

          // Draw main text
          textPainter.text = TextSpan(
            text: panelText,
            style: TextStyle(
              color: Colors.grey[600]!.withOpacity(0.7),
              fontSize: math.max(math.min(cellWidth * 0.15, 14), 8),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(textX, textY));
        }
        panelCenters.add(rowCenters);
      }
    }

    // Notify about panel centers for snapping
    onPanelCentersCalculated(panelCenters);

    // Draw completed power lines
    for (final powerLine in powerLines) {
      _drawPowerLine(
        canvas,
        powerLine.points,
        powerLine.powerNumber,
        linePaint,
        textPainter,
      );
    }

    // Draw current line being drawn
    if (isDrawing && currentLine.length >= 2) {
      _drawCurrentLine(canvas, currentLine, linePaint);
    }
  }

  void _drawPowerLine(
    Canvas canvas,
    List<Offset> points,
    String powerNumber,
    Paint linePaint,
    TextPainter textPainter,
  ) {
    if (points.length < 2) return;

    // Enhanced power line with better quality and gradient
    final mainLinePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.blue[600]!, Colors.blue[400]!],
      ).createShader(Rect.fromPoints(points.first, points.last))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Draw subtle shadow under the power line
    final shadowLinePaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0)
      ..isAntiAlias = true;

    // Draw shadow first
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(
        Offset(points[i].dx + 1, points[i].dy + 1),
        Offset(points[i + 1].dx + 1, points[i + 1].dy + 1),
        shadowLinePaint,
      );
    }

    // Draw main power line over the shadow
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], mainLinePaint);
    }

    // Draw enhanced vector arrow at the final end point
    final lastSegmentStart = points[points.length - 2];
    final end = points.last;
    _drawVectorArrow(canvas, lastSegmentStart, end, mainLinePaint);

    // Enhanced power number label with better styling (reduced size)
    textPainter.text = TextSpan(
      text: powerNumber,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11, // Reduced from 15 to 11
        fontWeight: FontWeight.w600, // Slightly lighter weight
        letterSpacing: 0.3, // Reduced letter spacing
      ),
    );
    textPainter.layout();

    // Position label at center of starting panel
    final start = points.first;
    final labelOffset = Offset(
      start.dx - textPainter.width / 2,
      start.dy - textPainter.height / 2,
    );

    // Enhanced background with gradient and shadow (smaller padding)
    final bgRect = Rect.fromLTWH(
      labelOffset.dx - 4, // Reduced padding
      labelOffset.dy - 3, // Reduced padding
      textPainter.width + 8, // Reduced padding
      textPainter.height + 6, // Reduced padding
    );

    // Draw shadow for label (adjusted to match smaller background)
    final shadowRect = Rect.fromLTWH(
      labelOffset.dx - 3,
      labelOffset.dy - 2,
      textPainter.width + 8,
      textPainter.height + 6,
    );
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.fill
      ..maskFilter =
          const MaskFilter.blur(BlurStyle.normal, 1.5) // Reduced blur
      ..isAntiAlias = true;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        shadowRect,
        const Radius.circular(4),
      ), // Smaller radius
      shadowPaint,
    );

    // Draw gradient background
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.blue[500]!, Colors.blue[700]!],
      ).createShader(bgRect)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final borderPaint = Paint()
      ..color = Colors.blue[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bgRect,
        const Radius.circular(4),
      ), // Smaller radius to match shadow
      bgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bgRect,
        const Radius.circular(4),
      ), // Smaller radius to match shadow
      borderPaint,
    );

    textPainter.paint(canvas, labelOffset);
  }

  void _drawCurrentLine(Canvas canvas, List<Offset> points, Paint linePaint) {
    if (points.length < 2) return;

    // Enhanced shadow guide lines with gradient
    final shadowLinePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.5)],
      ).createShader(Rect.fromPoints(points.first, points.last))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Draw enhanced shadow guide for all segments
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], shadowLinePaint);
    }

    // Enhanced snap indicators with better styling
    final snapIndicatorPaint = Paint()
      ..color = Colors.grey.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;

    final snapFillPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Show enhanced circles at each snapped point
    for (final point in points) {
      canvas.drawCircle(point, 4, snapFillPaint);
      canvas.drawCircle(point, 4, snapIndicatorPaint);
    }

    // Enhanced waypoints with gradient styling
    final waypointPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.blue.withOpacity(0.8), Colors.blue.withOpacity(0.4)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 6))
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final waypointBorderPaint = Paint()
      ..color = Colors.blue.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..isAntiAlias = true;

    for (int i = 1; i < points.length - 1; i++) {
      canvas.drawCircle(points[i], 6, waypointPaint);
      canvas.drawCircle(points[i], 6, waypointBorderPaint);
    }

    // Enhanced start point indicator
    if (points.isNotEmpty) {
      final startPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.green.withOpacity(0.9),
            Colors.green.withOpacity(0.5),
          ],
        ).createShader(Rect.fromCircle(center: points.first, radius: 7))
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      final startBorderPaint = Paint()
        ..color = Colors.green[700]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..isAntiAlias = true;

      canvas.drawCircle(points.first, 7, startPaint);
      canvas.drawCircle(points.first, 7, startBorderPaint);
    }

    // Enhanced current end point indicator
    if (points.length >= 2) {
      final endPaint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.red.withOpacity(0.9), Colors.red.withOpacity(0.5)],
        ).createShader(Rect.fromCircle(center: points.last, radius: 6))
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      final endBorderPaint = Paint()
        ..color = Colors.red[700]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..isAntiAlias = true;

      canvas.drawCircle(points.last, 6, endPaint);
      canvas.drawCircle(points.last, 6, endBorderPaint);
    }
  }

  void _drawVectorArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    const arrowLength = 22.0;
    const arrowAngle = 0.35; // radians (about 20 degrees for sharper arrow)

    final direction = (end - start);
    final length = direction.distance;
    if (length == 0) return;

    final unitVector = direction / length;

    // Calculate enhanced arrow head points
    final arrowPoint1 =
        end -
        Offset(
          unitVector.dx * arrowLength * math.cos(arrowAngle) -
              unitVector.dy * arrowLength * math.sin(arrowAngle),
          unitVector.dx * arrowLength * math.sin(arrowAngle) +
              unitVector.dy * arrowLength * math.cos(arrowAngle),
        );

    final arrowPoint2 =
        end -
        Offset(
          unitVector.dx * arrowLength * math.cos(-arrowAngle) -
              unitVector.dy * arrowLength * math.sin(-arrowAngle),
          unitVector.dx * arrowLength * math.sin(-arrowAngle) +
              unitVector.dy * arrowLength * math.cos(-arrowAngle),
        );

    // Enhanced arrow with gradient and shadow
    final arrowPath = Path();
    arrowPath.moveTo(end.dx, end.dy);
    arrowPath.lineTo(arrowPoint1.dx, arrowPoint1.dy);
    arrowPath.lineTo(arrowPoint2.dx, arrowPoint2.dy);
    arrowPath.close();

    // Draw arrow shadow
    final shadowPath = Path();
    shadowPath.moveTo(end.dx + 1, end.dy + 1);
    shadowPath.lineTo(arrowPoint1.dx + 1, arrowPoint1.dy + 1);
    shadowPath.lineTo(arrowPoint2.dx + 1, arrowPoint2.dy + 1);
    shadowPath.close();

    final arrowShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5)
      ..isAntiAlias = true;

    canvas.drawPath(shadowPath, arrowShadowPaint);

    // Draw filled arrow with gradient
    final arrowRect = arrowPath.getBounds();
    final arrowFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.blue[400]!, Colors.blue[700]!],
      ).createShader(arrowRect)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(arrowPath, arrowFillPaint);

    // Draw enhanced arrow outline
    final arrowOutlinePaint = Paint()
      ..color = Colors.blue[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(arrowPath, arrowOutlinePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
