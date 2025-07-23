import '../models/led_model.dart';
import '../services/led_calculation_service.dart';

class Surface {
  final String id;
  String name;
  LEDModel? selectedLED;
  double? width;
  double? height;
  LEDCalculationResult? calculation;
  bool isStacked;
  bool isRigged;

  Surface({
    required this.id,
    required this.name,
    this.selectedLED,
    this.width,
    this.height,
    this.calculation,
    this.isStacked = false,
    this.isRigged = false,
  });

  bool get isComplete =>
      selectedLED != null && width != null && height != null && name.isNotEmpty;

  void updateCalculation() {
    if (selectedLED != null &&
        width != null &&
        height != null &&
        width! > 0 &&
        height! > 0) {
      calculation = LEDCalculationService.calculateLEDInstallation(
        selectedLED!,
        width!,
        height!,
      );
    } else {
      calculation = null;
    }
  }
}
