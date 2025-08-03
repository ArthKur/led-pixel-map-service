import '../models/led_model.dart';
import '../services/led_calculation_service.dart';

// Project data class
class ProjectData {
  String projectNumber;
  String projectName;
  String projectManager;
  String projectEngineer;
  String clientName;
  String location;
  String description;
  String? logoBase64; // Add logo data persistence
  String? logoFileName; // Add logo filename persistence

  ProjectData({
    this.projectNumber = '',
    this.projectName = '',
    this.projectManager = '',
    this.projectEngineer = '',
    this.clientName = '',
    this.location = '',
    this.description = '',
    this.logoBase64,
    this.logoFileName,
  });

  // Convert to JSON for saving
  Map<String, dynamic> toJson() {
    return {
      'projectNumber': projectNumber,
      'projectName': projectName,
      'projectManager': projectManager,
      'projectEngineer': projectEngineer,
      'clientName': clientName,
      'location': location,
      'description': description,
      'logoBase64': logoBase64,
      'logoFileName': logoFileName,
    };
  }

  // Create from JSON for loading
  factory ProjectData.fromJson(Map<String, dynamic> json) {
    return ProjectData(
      projectNumber: json['projectNumber'] ?? '',
      projectName: json['projectName'] ?? '',
      projectManager: json['projectManager'] ?? '',
      projectEngineer: json['projectEngineer'] ?? '',
      clientName: json['clientName'] ?? '',
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      logoBase64: json['logoBase64'],
      logoFileName: json['logoFileName'],
    );
  }
}

class Surface {
  final String id;
  String name;
  LEDModel? selectedLED;
  double? width;
  double? height;
  LEDCalculationResult? calculation;
  bool isStacked;
  bool isRigged;
  String notes;
  List<Map<String, dynamic>>? powerLines; // Store power lines data

  Surface({
    required this.id,
    required this.name,
    this.selectedLED,
    this.width,
    this.height,
    this.calculation,
    this.isStacked = false,
    this.isRigged = false,
    this.notes = '',
    this.powerLines,
  });

  bool get isComplete =>
      selectedLED != null && width != null && height != null && name.isNotEmpty;

  // Convenience getters for calculated values
  double? get area => width != null && height != null ? width! * height! : null;

  // Panel calculations
  int? get totalPanels => calculation != null
      ? calculation!.totalFullPanels + calculation!.totalHalfPanels
      : null;

  int? get fullPanels => calculation?.totalFullPanels;

  int? get halfPanels => calculation?.totalHalfPanels;

  // Power calculations
  double? get totalPowerAvg => calculation?.avgPower;

  double? get totalPowerMax => calculation?.maxPower;

  double? get totalWeight => calculation?.totalWeight;

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
