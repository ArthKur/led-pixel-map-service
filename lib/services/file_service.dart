import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;

class FileService {
  // Cross-platform file picking for JSON files
  static Future<String?> pickJsonFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        // For web and mobile/desktop with bytes available
        final bytes = result.files.single.bytes!;
        return utf8.decode(bytes);
      } else if (result != null && result.files.single.path != null) {
        // For desktop platforms with file path
        // This case is handled by FilePicker internally
        return null; // FilePicker will handle this
      }
    } catch (e) {
      print('Error picking JSON file: $e');
    }
    return null;
  }

  // Cross-platform file picking for CSV files
  static Future<String?> pickCsvFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        return utf8.decode(bytes);
      }
    } catch (e) {
      print('Error picking CSV file: $e');
    }
    return null;
  }

  // Cross-platform image picking
  static Future<Uint8List?> pickImageFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        return result.files.single.bytes!;
      }
    } catch (e) {
      print('Error picking image file: $e');
    }
    return null;
  }

  // Cross-platform file download/save
  static Future<void> downloadFile(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) async {
    try {
      if (kIsWeb) {
        // Web implementation using universal_html
        final blob = html.Blob([bytes], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement()
          ..href = url
          ..style.display = 'none'
          ..download = fileName;

        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } else {
        // Mobile and Desktop implementation
        final xFile = XFile.fromData(bytes, name: fileName, mimeType: mimeType);
        await Share.shareXFiles([xFile], text: 'Sharing $fileName');
      }
    } catch (e) {
      print('Error downloading file: $e');
      rethrow;
    }
  }

  // Convert base64 string to bytes (cross-platform)
  static Uint8List base64ToBytes(String base64String) {
    try {
      // Remove data URL prefix if present
      String cleanBase64 = base64String;
      if (base64String.contains(',')) {
        cleanBase64 = base64String.split(',').last;
      }

      if (kIsWeb) {
        // Web implementation
        final decodedString = html.window.atob(cleanBase64);
        return Uint8List.fromList(decodedString.codeUnits);
      } else {
        // Mobile/Desktop implementation
        return base64Decode(cleanBase64);
      }
    } catch (e) {
      print('Error converting base64 to bytes: $e');
      return Uint8List(0);
    }
  }

  // Convert bytes to base64 data URL
  static String bytesToBase64DataUrl(Uint8List bytes, String mimeType) {
    final base64String = base64Encode(bytes);
    return 'data:$mimeType;base64,$base64String';
  }
}
