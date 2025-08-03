import 'lib/services/led_service.dart';
import 'lib/services/led_data_importer.dart';

void main() async {
  print("=== Testing CSV LED Data Import ===");

  try {
    // Initialize LED Service
    await LEDService.init();

    // Get initial LED count
    final initialLEDs = await LEDService.getAllLEDs();
    print("LEDs before import: ${initialLEDs.length}");

    // Import LED data from CSV
    await LEDDataImporter.importFromCSV();

    // Get final LED count
    final finalLEDs = await LEDService.getAllLEDs();
    print("LEDs after import: ${finalLEDs.length}");

    print("\n=== Imported LED Products ===");
    for (final led in finalLEDs) {
      print("\n📱 ${led.name}");
      print("   Manufacturer: ${led.manufacturer}");
      print("   Model: ${led.model}");
      print("   Pitch: ${led.pitch}mm");
      print("   Full Height: ${led.fullHeight}mm");
      print("   Width: ${led.width}mm");
      print("   H Pixels: ${led.hPixel}");
      print("   W Pixels: ${led.wPixel}");
      print("   Max Power: ${led.fullPanelMaxW}W");
      print("   Brightness: ${led.brightness} nit");
      print("   IP Rating: ${led.ipRating}");
      print("   Case Volume: ${led.caseVolume}");
      print("   Panels per Case: ${led.panelsPerCase}");
    }

    print("\n✅ CSV import test completed successfully!");
  } catch (e) {
    print("❌ Error during CSV import test: $e");
  }
}
