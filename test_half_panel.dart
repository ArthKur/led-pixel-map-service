import 'lib/models/led_model.dart';

void main() {
  // Test that LED model can be created with half panel data
  final led = LEDModel(
    name: "Test LED",
    manufacturer: "Test Mfg",
    model: "Test Model",
    pitch: 2.5,
    fullHeight: 500.0,
    halfHeight: 250.0,
    width: 500.0,
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

  print("LED Model created successfully!");
  print(
    "Full Panel: ${led.fullHeight}mm x ${led.width}mm, ${led.hPixel}x${led.wPixel} pixels",
  );
  print(
    "Half Panel: ${led.halfHeight}mm x ${led.halfWidth}mm, ${led.halfHPixel}x${led.halfWPixel} pixels",
  );
  print(
    "Full Panel Weight: ${led.fullPanelWeight}kg, Half Panel Weight: ${led.halfPanelWeight}kg",
  );
  print(
    "Full Panel Power: Max ${led.fullPanelMaxW}W, Avg ${led.fullPanelAvgW}W",
  );
  print(
    "Half Panel Power: Max ${led.halfPanelMaxW}W, Avg ${led.halfPanelAvgW}W",
  );
}
