import 'package:hive_flutter/hive_flutter.dart';
import '../models/led_model.dart';

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
}
