import 'package:hive_flutter/hive_flutter.dart';
import '../models/led_model.dart';
import 'led_data_importer.dart';

class LEDService {
  static const String _boxName = 'led_products';
  static Box<LEDModel>? _box;

  // Initialize Hive and open the box
  static Future<void> init() async {
    await Hive.initFlutter();

    // Check if adapter is already registered to avoid duplicate registration
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LEDModelAdapter());
    }

    _box = await Hive.openBox<LEDModel>(_boxName);
  }

  // Get all LED products
  static Future<List<LEDModel>> getAllLEDs() async {
    return _box?.values.toList() ?? [];
  }

  // Add a new LED product
  static Future<void> addLED(LEDModel led) async {
    await _box?.add(led);
  }

  // Update an existing LED product by key
  static Future<void> updateLED(dynamic key, LEDModel led) async {
    await _box?.put(key, led);
  }

  // Delete an LED product by key
  static Future<void> deleteLED(dynamic key) async {
    await _box?.delete(key);
  }

  // Search LEDs by name, manufacturer, or model
  static Future<List<LEDModel>> searchLEDs(String query) async {
    final allLEDs = await getAllLEDs();
    if (query.isEmpty) return allLEDs;

    return allLEDs.where((led) {
      return led.name.toLowerCase().contains(query.toLowerCase()) ||
          led.manufacturer.toLowerCase().contains(query.toLowerCase()) ||
          led.model.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Get LED by exact name match
  static Future<LEDModel?> getLEDByName(String name) async {
    final allLEDs = await getAllLEDs();
    try {
      return allLEDs.firstWhere(
        (led) => led.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null; // Return null if not found
    }
  }

  // Get LED by index
  static LEDModel? getLEDAt(int index) {
    return _box?.getAt(index);
  }

  // Add Absen LED products
  static Future<void> addAbsenProducts() async {
    // Check if products already exist to avoid duplicates
    final existingLEDs = await getAllLEDs();
    final existingNames = existingLEDs
        .map((led) => led.name.toLowerCase())
        .toSet();

    if (!existingNames.contains('absen pl2.5 lite')) {
      await addLED(
        LEDModel(
          name: 'Absen PL2.5 Lite',
          manufacturer: 'Absen',
          model: 'PL2.5 Lite',
          pitch: 2.5,
          fullHeight: 500.0, // mm - typical for this type
          halfHeight: 250.0, // mm
          width: 500.0, // mm - typical for this type
          halfWidth: 250.0, // mm
          depth: 75.0, // mm - estimated
          fullPanelWeight: 8.0, // kg - estimated
          halfPanelWeight: 4.0, // kg
          hPixel: 200, // estimated based on 2.5mm pitch and 500mm panel
          wPixel: 200, // estimated
          halfHPixel: 100, // half of full panel
          halfWPixel: 100, // half of full panel
          fullPanelMaxW: 300.0, // W - estimated
          halfPanelMaxW: 150.0, // W
          fullPanelAvgW: 200.0, // W - estimated
          halfPanelAvgW: 100.0, // W
          processing: 'Receiving Card',
          brightness: 5000, // nit - typical for this type
          viewingAngle: '160°',
          refreshRate: 3840, // Hz
          ledConfiguration: 'Black SMD 3 in 1',
          ipRating: 'IP40 Front / IP21 Rear',
          curveCapability: '7.5° ×10',
          verification: 'CE, ETL, FCC, RoHS',
          dataConnection: 'Seetronic EtherCON',
          powerConnection: 'Seetronic PowerCON',
          touringFrame: 'No',
          supplier: 'CT',
          operatingVoltage: 'AC110/240V - 50/60Hz',
          operatingTemp: '-10°C - +40°C',
          dateAdded: DateTime.now(),
        ),
      );
    }

    if (!existingNames.contains('absen pl3.9 lite')) {
      await addLED(
        LEDModel(
          name: 'Absen PL3.9 Lite',
          manufacturer: 'Absen',
          model: 'PL3.9 Lite',
          pitch: 3.9,
          fullHeight: 500.0, // mm - typical for this type
          halfHeight: 250.0, // mm
          width: 500.0, // mm - typical for this type
          halfWidth: 250.0, // mm
          depth: 80.0, // mm - estimated
          fullPanelWeight: 9.0, // kg - estimated
          halfPanelWeight: 4.5, // kg
          hPixel: 128, // estimated based on 3.9mm pitch and 500mm panel
          wPixel: 128, // estimated
          halfHPixel: 64, // half of full panel
          halfWPixel: 64, // half of full panel
          fullPanelMaxW: 350.0, // W - estimated
          halfPanelMaxW: 175.0, // W
          fullPanelAvgW: 250.0, // W - estimated
          halfPanelAvgW: 125.0, // W
          processing: 'Receiving Card',
          brightness: 4500, // nit - typical for this type
          viewingAngle: '160°',
          refreshRate: 3840, // Hz
          ledConfiguration: '3 in 1 SMD',
          ipRating: 'IP65 Front / IP54 Rear',
          curveCapability: '+10°',
          verification: 'CE, ETL, FCC, RoHS',
          dataConnection: 'Seetronic EtherCON',
          powerConnection: 'Seetronic True1',
          touringFrame: 'No',
          supplier: 'CT',
          operatingVoltage: 'AC110/240V - 50/60Hz',
          operatingTemp: '-20°C - +50°C',
          dateAdded: DateTime.now(),
        ),
      );
    }
  }

  // Add new LED products from attached specifications
  static Future<void> addNewLEDProducts() async {
    final existingLEDs = await getAllLEDs();
    final existingNames = existingLEDs
        .map((led) => led.name.toLowerCase())
        .toSet();

    // Add Unilumin Uslim2
    if (!existingNames.contains('unilumin uslim2')) {
      await addLED(
        LEDModel(
          name: 'Unilumin Uslim2',
          manufacturer: 'Unilumin',
          model: 'Uslim2',
          pitch: 2.6, // Estimated based on similar products
          fullHeight: 500.0, // mm - typical panel size
          halfHeight: 250.0, // mm
          width: 500.0, // mm - typical panel size
          halfWidth: 250.0, // mm
          depth: 70.0, // mm - estimated
          fullPanelWeight: 7.5, // kg - estimated
          halfPanelWeight: 3.75, // kg
          hPixel: 192, // estimated based on pitch and panel size
          wPixel: 192, // estimated
          halfHPixel: 96, // half of full panel
          halfWPixel: 96, // half of full panel
          fullPanelMaxW: 280.0, // W - estimated
          halfPanelMaxW: 140.0, // W
          fullPanelAvgW: 190.0, // W - estimated
          halfPanelAvgW: 95.0, // W
          processing: 'Receiving Card',
          brightness: 5500, // nit - estimated
          viewingAngle: '140° / 120°',
          refreshRate: 1920, // Hz - from attachment
          ledConfiguration: '1R 1G 1B',
          ipRating: 'IP30',
          curveCapability: 'No',
          verification: 'CE, ETL, FCC, RoHS',
          dataConnection: 'Neutrik EtherCON',
          powerConnection: 'Neutrik PowerCON',
          touringFrame: 'No',
          supplier: 'CT',
          operatingVoltage: 'AC110/240V - 50/60Hz',
          operatingTemp: '-10°C - +45°C',
          dateAdded: DateTime.now(),
        ),
      );
    }

    // Add Absen A3 Pro
    if (!existingNames.contains('absen a3 pro')) {
      await addLED(
        LEDModel(
          name: 'Absen A3 Pro',
          manufacturer: 'Absen',
          model: 'A3 Pro',
          pitch: 2.97, // Estimated based on similar products
          fullHeight: 500.0, // mm - typical panel size
          halfHeight: 250.0, // mm
          width: 500.0, // mm - typical panel size
          halfWidth: 250.0, // mm
          depth: 75.0, // mm - estimated
          fullPanelWeight: 8.2, // kg - estimated
          halfPanelWeight: 4.1, // kg
          hPixel: 168, // estimated based on pitch and panel size
          wPixel: 168, // estimated
          halfHPixel: 84, // half of full panel
          halfWPixel: 84, // half of full panel
          fullPanelMaxW: 320.0, // W - estimated
          halfPanelMaxW: 160.0, // W
          fullPanelAvgW: 220.0, // W - estimated
          halfPanelAvgW: 110.0, // W
          processing: 'Receiving Card',
          brightness: 5000, // nit - estimated
          viewingAngle: '140° / 140°',
          refreshRate: 1200, // Hz - from attachment
          ledConfiguration: '3 in 1 SMD',
          ipRating: 'IP40',
          curveCapability: 'No',
          verification: 'CE, ETL, FCC, RoHS',
          dataConnection: 'Neutrik EtherCON',
          powerConnection: 'Neutrik PowerCON',
          touringFrame: 'No',
          supplier: 'CT',
          operatingVoltage: 'AC110/240V - 50/60Hz',
          operatingTemp: '-20°C - +50°C',
          dateAdded: DateTime.now(),
        ),
      );
    }

    // Add InfiLED ART4.6
    if (!existingNames.contains('infiled art4.6')) {
      await addLED(
        LEDModel(
          name: 'InfiLED ART4.6',
          manufacturer: 'InfiLED',
          model: 'ART4.6',
          pitch: 4.6, // From model name
          fullHeight: 1000.0, // mm - corrected: 1000mm high
          halfHeight: 500.0, // mm - half panel is 500mm x 500mm
          width: 500.0, // mm - corrected: 500mm wide
          halfWidth: 500.0, // mm - half panel width stays 500mm
          depth: 85.0, // mm - estimated
          fullPanelWeight: 28.0, // kg - from image specifications
          halfPanelWeight: 14.0, // kg - half of full panel
          hPixel:
              217, // pixels - corrected (1000mm height / 4.6mm pitch = ~217)
          wPixel: 108, // pixels - corrected (500mm width / 4.6mm pitch = ~108)
          halfHPixel: 108, // half panel height pixels (500mm / 4.6mm = ~108)
          halfWPixel: 108, // half panel width pixels (500mm / 4.6mm = ~108)
          fullPanelMaxW: 1150.0, // W - from image specifications
          halfPanelMaxW: 575.0, // W - half of full panel
          fullPanelAvgW: 800.0, // W - estimated average (about 70% of max)
          halfPanelAvgW: 400.0, // W - half of full panel
          processing: 'Receiving Card',
          brightness: 4500, // nit - estimated
          viewingAngle: '160° / 135°',
          refreshRate: 3840, // Hz - from attachment
          ledConfiguration: '3 in 1 SMD',
          ipRating: 'IP65',
          curveCapability: '+/- 5°, 10° left side',
          verification: 'CE, ETL, FCC, RoHS',
          dataConnection: 'Neutrik EtherCON',
          powerConnection: 'Neutrik True1',
          touringFrame: 'Yes',
          supplier: 'CT',
          operatingVoltage: 'AC110/240V - 50/60Hz',
          operatingTemp: '-10°C - +45°C',
          dateAdded: DateTime.now(),
        ),
      );
    }
  }

  // Import LED data from CSV
  static Future<void> importLEDDataFromCSV() async {
    await LEDDataImporter.importFromCSV();
  }

  // Import LED data from CSV content (from file upload)
  static Future<void> importLEDDataFromCSVContent(String csvContent) async {
    await LEDDataImporter.importFromCSVContent(csvContent);
  }

  // Clear all LED data
  static Future<void> clearAllLEDs() async {
    await LEDDataImporter.clearAllLEDs();
  }
}
