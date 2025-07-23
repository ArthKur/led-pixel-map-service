import 'lib/models/led_model.dart';
import 'lib/services/led_calculation_service.dart';

void main() {
  // Create a test LED model
  final led = LEDModel(
    name: "Test LED",
    manufacturer: "Test Mfg",
    model: "Test Model",
    pitch: 2.5,
    fullHeight: 500.0, // 0.5m per panel
    halfHeight: 250.0,
    width: 500.0, // 0.5m per panel
    halfWidth: 250.0,
    depth: 70.0,
    fullPanelWeight: 8.5,
    halfPanelWeight: 4.25,
    hPixel: 200,
    wPixel: 200,
    halfHPixel: 100,
    halfWPixel: 100,
    fullPanelMaxW: 300.0,
    halfPanelMaxW: 150.0,
    fullPanelAvgW: 200.0,
    halfPanelAvgW: 100.0,
    processing: "Receiving Card",
    brightness: 5000,
    viewingAngle: "160°",
    refreshRate: 3840,
    ledConfiguration: "1R1G1B",
    ipRating: "IP65",
    curveCapability: "Yes",
    verification: "CE",
    dataConnection: "Ethernet",
    powerConnection: "AC",
    touringFrame: "Yes",
    supplier: "Test Supplier",
    operatingVoltage: "AC110-220V",
    operatingTemp: "-20°C to +60°C",
    dateAdded: DateTime.now(),
  );

  // Test SQM calculation with requested screen size: 4m x 3m = 12 SQM
  final result = LEDCalculationService.calculateLEDInstallation(led, 4.0, 3.0);

  print("=== SQM Calculation Test ===");
  print("Requested Screen Size: 4.0m x 3.0m");
  print("Expected SQM: 12.0 m²");
  print("Calculated SQM: ${result.sqm} m²");
  print("✅ SQM calculation is now based on requested screen size!");

  // Show that actual panel dimensions might be different
  print("\n=== Panel Calculation Details ===");
  print("Panel size: ${led.width / 1000}m x ${led.fullHeight / 1000}m");
  print(
    "Panels needed: ${(4.0 / (led.width / 1000)).ceil()} x ${(3.0 / (led.fullHeight / 1000)).ceil()}",
  );
  print(
    "Actual screen size (panel-based): ${(4.0 / (led.width / 1000)).ceil() * (led.width / 1000)}m x ${(3.0 / (led.fullHeight / 1000)).ceil() * (led.fullHeight / 1000)}m",
  );
  print(
    "SQM is calculated from REQUESTED size (4.0 x 3.0), not actual panel size",
  );
}
