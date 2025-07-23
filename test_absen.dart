import 'lib/services/led_service.dart';

void main() async {
  print("=== Testing Absen LED Products Addition ===");

  // Initialize LED Service
  await LEDService.init();

  // Add Absen products
  await LEDService.addAbsenProducts();

  // Get all LEDs to verify addition
  final allLEDs = await LEDService.getAllLEDs();

  print("Total LED products: ${allLEDs.length}");
  print("\n=== Absen Products ===");

  for (final led in allLEDs) {
    if (led.manufacturer.toLowerCase() == 'absen') {
      print("\n📱 ${led.name}");
      print("   Manufacturer: ${led.manufacturer}");
      print("   Model: ${led.model}");
      print("   Pitch: ${led.pitch}mm");
      print("   LED Configuration: ${led.ledConfiguration}");
      print("   IP Rating: ${led.ipRating}");
      print("   Curve Capability: ${led.curveCapability}");
      print("   Verification: ${led.verification}");
      print("   Data Connection: ${led.dataConnection}");
      print("   Power Connection: ${led.powerConnection}");
      print("   Operating Voltage: ${led.operatingVoltage}");
      print("   Operating Temperature: ${led.operatingTemp}");
      print("   Supplier: ${led.supplier}");
      print("   ✅ Product added successfully!");
    }
  }

  print("\n=== Test Complete ===");
}
