import 'package:flutter/material.dart';
import '../services/led_calculation_service.dart';

class LEDSummaryWidget extends StatelessWidget {
  final LEDCalculationResult calculation;
  final bool isStacked;
  final bool isRigged;

  const LEDSummaryWidget({
    super.key,
    required this.calculation,
    this.isStacked = false,
    this.isRigged = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 7,
          ), // Reduced gap from 12px to 7px (moved 5px higher)
          // Three Summary columns - larger columns with smaller gaps
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
            ), // Minimal margins for maximum column width
            child: Row(
              mainAxisAlignment: MainAxisAlignment
                  .spaceBetween, // Equal spacing between columns and edges
              children: [
                // First Summary Column
                SizedBox(
                  width: 280, // Increased width to fill more space (240 -> 280)
                  child: SelectionArea(
                    child: Column(
                      children: [
                        _buildSection('Summary', [
                          _buildDataRow('LED Screen', calculation.ledName),
                          _buildDataRow(
                            'Screen Size',
                            '${calculation.requestedWidth}m(W) x ${calculation.requestedHeight}m(H)',
                          ),
                          _buildDataRow(
                            'Screen SQM',
                            '${calculation.sqm.toStringAsFixed(2)}m²',
                          ),
                          _buildDataRow(
                            'Panels',
                            calculation.totalHalfPanels > 0
                                ? '${calculation.panelsWidth}W x ${calculation.panelsHeight}H = ${calculation.totalFullPanels} Full / ${calculation.totalHalfPanels} Half'
                                : '${calculation.panelsWidth}W x ${calculation.panelsHeight}H = ${calculation.totalFullPanels}',
                          ),
                          _buildDataRow(
                            'Pixel Space',
                            '${calculation.pixelsWidth}(W) x ${calculation.pixelsHeight}(H)',
                          ),
                          _buildDataRow(
                            'Aspect Ratio',
                            calculation.aspectRatio,
                          ),
                          _buildDataRow(
                            'Max power @3Phase',
                            '${calculation.maxPower.toStringAsFixed(0)}A',
                          ),
                          _buildDataRow(
                            'Avg Power @3Phase',
                            '${calculation.avgPower.toStringAsFixed(0)}A',
                          ),
                          _buildDataRow(
                            'Approx. Weight',
                            '${calculation.totalCalculatedWeight.toStringAsFixed(1)}kg',
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
                // Second Column - Electrical Data
                SizedBox(
                  width: 280, // Increased width to fill more space (240 -> 280)
                  child: SelectionArea(
                    child: Column(
                      children: [
                        _buildSection('Electrical', [
                          _buildDataRow(
                            'Max Amps @1Phase',
                            (calculation.maxPower * 3).toStringAsFixed(0),
                          ),
                          _buildDataRow(
                            'Max Amps @3Phase',
                            calculation.maxPower.toStringAsFixed(0),
                          ),
                          _buildDataRow(
                            'Avg Amps @1Phase',
                            (calculation.avgPower * 3).toStringAsFixed(0),
                          ),
                          _buildDataRow(
                            'Avg Amps @3Phase',
                            calculation.avgPower.toStringAsFixed(0),
                          ),
                          _buildDataRow(
                            'Total kW',
                            ((calculation.maxPower * 3) * 230 / 1000).toStringAsFixed(2),
                          ),
                          _buildDataRow(
                            'kW/hr',
                            ((230 * (calculation.maxPower * 3) / 0.85) / 1000).toStringAsFixed(1),
                          ),
                          _buildDataRow(
                            'Distro',
                            _getDistroType(calculation.maxPower * 3),
                          ),
                          _buildDataRow(
                            '',
                            '',
                          ), // Empty row to match Summary height
                          _buildDataRow(
                            '',
                            '',
                          ), // Empty row to match Summary height
                        ]),
                      ],
                    ),
                  ),
                ),
                // Third Column - Totals
                SizedBox(
                  width: 280, // Increased width to fill more space (240 -> 280)
                  child: SelectionArea(
                    child: Column(
                      children: [
                        _buildSection('Shipping', [
                          _buildDataRow('Dolly / Case', '63'),
                          _buildDataRow('Shipping Weight - kg', '5,796'),
                          _buildDataRow('Shipping Volume - m³', '25'),
                          _buildDataRow(
                            '',
                            '',
                          ), // Empty row to match Summary height
                          _buildDataRow(
                            '',
                            '',
                          ), // Empty row to match Summary height
                          _buildDataRow(
                            '',
                            '',
                          ), // Empty row to match Summary height
                          _buildDataRow(
                            '',
                            '',
                          ), // Empty row to match Summary height
                          _buildDataRow(
                            '',
                            '',
                          ), // Empty row to match Summary height
                          _buildDataRow(
                            '',
                            '',
                          ), // Empty row to match Summary height
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Second row with duplicated Electrical under Summary
          const SizedBox(height: 12), // Gap between rows
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Physical section moved to second row first position
                SizedBox(
                  width: 280,
                  child: SelectionArea(
                    child: Column(
                      children: [
                        _buildSection('Physical', [
                          _buildDataRow(
                            'Meters (W)',
                            '${calculation.metersWidth}',
                          ),
                          _buildDataRow(
                            'Meters (H)',
                            '${calculation.metersHeight}',
                          ),
                          _buildDataRow(
                            'Panels (W)',
                            '${calculation.panelsWidth}',
                          ),
                          _buildDataRow(
                            'Panels (H)',
                            '${calculation.panelsHeight}',
                          ),
                          _buildDataRow(
                            'Pixels (W)',
                            '${calculation.pixelsWidth}',
                          ),
                          _buildDataRow(
                            'Pixels (H)',
                            '${calculation.pixelsHeight}',
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
                // Totals section moved to second row second position
                SizedBox(
                  width: 280,
                  child: SelectionArea(
                    child: Column(
                      children: [
                        _buildSection('Totals', [
                          _buildDataRow(
                            'SQM - m²',
                            calculation.sqm.toStringAsFixed(1),
                          ),
                          _buildDataRow(
                            'Weight - kg',
                            calculation.totalWeight.toStringAsFixed(0),
                          ),
                          _buildDataRow(
                            'Total Full Panels',
                            '${calculation.totalFullPanels}',
                          ),
                          _buildDataRow(
                            'Total Half Panels',
                            '${calculation.totalHalfPanels}',
                          ),
                          _buildDataRow(
                            'Total pix',
                            calculation.totalPx.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                          ),
                          _buildDataRow(
                            '',
                            '',
                          ), // Empty row to match Physical column size
                        ]),
                      ],
                    ),
                  ),
                ),
                // Fourth Electrical section under Totals
                SizedBox(
                  width: 280,
                  child: SelectionArea(
                    child: Column(
                      children: [
                        _buildSection('Stacked Rigging', [
                          _buildDataRow('Truss Upright', isRigged ? '0' : '9'),
                          _buildDataRow(
                            'Truss Baseplate',
                            isRigged ? '0' : '9',
                          ),
                          _buildDataRow(
                            'Horizontal Pipe',
                            isRigged ? '0' : '5',
                          ),
                          _buildDataRow('Half Couplers', isRigged ? '0' : '60'),
                          _buildDataRow('Bracing Arms', isRigged ? '0' : '45'),
                          _buildDataRow(
                            '',
                            '',
                          ), // Empty row to match Physical column size
                        ], isGreyedOut: isRigged),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Third row with Electrical 3 under first Electrical
          const SizedBox(height: 12), // Gap between rows
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Third Electrical section under first Electrical
                SizedBox(
                  width: 280,
                  child: SelectionArea(
                    child: Column(
                      children: [
                        _buildSection('Cables & Processing', [
                          _buildDataRow('Fast Data Backup', '26'),
                          _buildDataRow('Fast Power', '24'),
                          _buildDataRow('Socapex', '4'),
                          _buildDataRow('Novastar MCTRL 4K Main', '1'),
                          _buildDataRow('Novastar MCTRL 4K BU', '1'),
                        ]),
                      ],
                    ),
                  ),
                ),
                // Fifth Electrical section under Electrical 2
                SizedBox(
                  width: 280,
                  child: SelectionArea(
                    child: Column(
                      children: [
                        _buildSection('Weights', [
                          _buildDataRow(
                            'Screen Weight',
                            calculation.screenWeight.toStringAsFixed(0),
                          ),
                          _buildDataRow(
                            'Cable Weight (10%)',
                            calculation.cableWeight.toStringAsFixed(0),
                          ),
                          _buildDataRow(
                            'Rigging Allowance (20%)',
                            calculation.riggingAllowance.toStringAsFixed(0),
                          ),
                          _buildDataRow(
                            'Total',
                            calculation.totalCalculatedWeight.toStringAsFixed(0),
                          ),
                          _buildDataRow(
                            '',
                            '',
                          ), // Empty row to match Electrical 6 size
                        ]),
                      ],
                    ),
                  ),
                ),
                // Sixth Electrical section under Electrical 4
                SizedBox(
                  width: 280,
                  child: SelectionArea(
                    child: Column(
                      children: [
                        _buildSection('Flown Rigging', [
                          _buildDataRow(
                            'Single Header',
                            isStacked ? '0' : '36',
                          ),
                          _buildDataRow(
                            'Gac/Spacer1.4m',
                            isStacked ? '0' : '36',
                          ),
                          _buildDataRow(
                            '3 251 Shackle',
                            isStacked ? '0' : '36',
                          ),
                          _buildDataRow(
                            '',
                            '',
                          ), // Empty row to maintain column size
                          _buildDataRow(
                            '',
                            '',
                          ), // Empty row to maintain column size
                        ], isGreyedOut: isStacked),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<Widget> children, {
    bool isGreyedOut = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isGreyedOut ? Colors.grey : Colors.orange,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isGreyedOut
                  ? Colors.grey
                  : Colors.orange, // Changed to standard orange color
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isGreyedOut ? Colors.grey[400] : Colors.white,
              ),
            ),
          ),
          // Section content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isGreyedOut ? Colors.grey[100] : Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              border: Border.all(
                color: isGreyedOut ? Colors.grey : Colors.orange,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value, {bool isGreyedOut = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: isGreyedOut ? Colors.grey[400] : Colors.black,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isGreyedOut ? Colors.grey[400] : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  String _getDistroType(double maxAmps1Phase) {
    if (maxAmps1Phase <= 32) {
      return "32A - Type 4";
    } else if (maxAmps1Phase <= 63) {
      return "63A - Type 3";
    } else if (maxAmps1Phase <= 125) {
      return "125A - Type 2";
    } else if (maxAmps1Phase <= 4500) {
      return "400A - Type 1";
    } else {
      return "400A - Type 1"; // Default for values above 4500
    }
  }
}
