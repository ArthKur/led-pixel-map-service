import 'package:flutter/services.dart';
import '../services/led_service.dart';
import '../models/led_model.dart';

class LEDDataImporter {
  static Future<void> importFromCSV() async {
    try {
      // Clear existing data
      await clearAllLEDs();

      // Load CSV data from assets
      final csvData = await rootBundle.loadString('assets/led_specs.csv');

      // Parse CSV and create LED models
      final List<LEDModel> leds = _parseCSV(csvData);

      // Add LEDs to database
      for (final led in leds) {
        await LEDService.addLED(led);
      }

      print('Successfully imported ${leds.length} LED products from CSV');
    } catch (e) {
      print('Error importing LED data: $e');
      rethrow;
    }
  }

  static Future<void> importFromCSVContent(String csvContent) async {
    try {
      // Clear existing data
      await clearAllLEDs();

      // Parse CSV and create LED models
      final List<LEDModel> leds = _parseCSV(csvContent);

      // Add LEDs to database
      for (final led in leds) {
        await LEDService.addLED(led);
      }

      print(
        'Successfully imported ${leds.length} LED products from uploaded CSV',
      );
    } catch (e) {
      print('Error importing LED data from content: $e');
      rethrow;
    }
  }

  static Future<void> clearAllLEDs() async {
    final allLEDs = await LEDService.getAllLEDs();
    for (int i = allLEDs.length - 1; i >= 0; i--) {
      await LEDService.deleteLED(i);
    }
  }

  static List<LEDModel> _parseCSV(String csvData) {
    final List<LEDModel> leds = [];
    final lines = csvData.split('\n');

    if (lines.isEmpty) return leds;

    // Skip header row (index 0)
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty ||
          line.split(',').every((cell) => cell.trim().isEmpty)) {
        continue; // Skip empty lines
      }

      try {
        final led = _parseCSVLine(line);
        if (led != null) {
          leds.add(led);
        }
      } catch (e) {
        print('Error parsing line $i: $e');
        print('Line content: $line');
      }
    }

    return leds;
  }

  static LEDModel? _parseCSVLine(String line) {
    final List<String> fields = _parseCSVFields(line);

    if (fields.length < 32) {
      print('Insufficient fields: ${fields.length}');
      return null;
    }

    try {
      // Helper function to parse numeric values safely
      double? parseDouble(String value) {
        if (value.isEmpty) return null;
        // Remove any non-numeric characters except dots and commas
        final cleanValue = value.replaceAll(RegExp(r'[^\d.,]'), '');
        if (cleanValue.isEmpty) return null;
        return double.tryParse(cleanValue.replaceAll(',', '.'));
      }

      int? parseInt(String value) {
        if (value.isEmpty) return null;
        final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
        if (cleanValue.isEmpty) return null;
        return int.tryParse(cleanValue);
      }

      return LEDModel(
        name: fields[0].trim(),
        manufacturer: fields[1].trim(),
        model: fields[2].trim(),
        pitch: parseDouble(fields[3]) ?? 0.0,
        fullHeight: parseDouble(fields[4]) ?? 0.0,
        halfHeight: parseDouble(fields[5]) ?? 0.0,
        width: parseDouble(fields[6]) ?? 0.0,
        halfWidth: parseDouble(fields[6]) ?? 0.0, // Use same as width for now
        depth: parseDouble(fields[7]) ?? 0.0,
        fullPanelWeight: parseDouble(fields[8]) ?? 0.0,
        halfPanelWeight: parseDouble(fields[9]) ?? 0.0,
        hPixel: parseInt(fields[10]) ?? 0,
        wPixel: parseInt(fields[11]) ?? 0,
        halfHPixel: parseInt(fields[10]) != null
            ? (parseInt(fields[10])! / 2).round()
            : 0,
        halfWPixel: parseInt(fields[11]) != null
            ? (parseInt(fields[11])! / 2).round()
            : 0,
        fullPanelMaxW: parseDouble(fields[12]) ?? 0.0,
        halfPanelMaxW: parseDouble(fields[13]) ?? 0.0,
        fullPanelAvgW: parseDouble(fields[14]) ?? 0.0,
        halfPanelAvgW: parseDouble(fields[15]) ?? 0.0,
        processing: fields[16].trim(),
        brightness: parseInt(fields[17]) ?? 0,
        viewingAngle: fields[18].trim(),
        refreshRate: parseInt(fields[19]) ?? 0,
        ledConfiguration: fields[20].trim(),
        ipRating: fields[21].trim(),
        curveCapability: fields[22].trim(),
        verification: fields[23].trim(),
        dataConnection: fields[24].trim(),
        powerConnection: fields[25].trim(),
        touringFrame: fields[26].trim(),
        operatingVoltage: fields[27].trim(),
        operatingTemp: fields[28].trim(),
        caseVolume: parseDouble(fields[29]) ?? 0.0,
        panelsPerCase: parseInt(fields[30]) ?? 0,
        panelsPerPort: parseInt(fields[31]) ?? 0,
        panelsPer16A: parseInt(fields[32]) ?? 0,
        supplier: 'CSV Import',
        dateAdded: DateTime.now(),
      );
    } catch (e) {
      print('Error creating LED model: $e');
      return null;
    }
  }

  static List<String> _parseCSVFields(String line) {
    final List<String> fields = [];
    bool inQuotes = false;
    String currentField = '';

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(currentField);
        currentField = '';
      } else {
        currentField += char;
      }
    }

    // Add the last field
    fields.add(currentField);

    return fields;
  }
}
