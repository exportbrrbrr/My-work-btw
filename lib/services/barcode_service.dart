import 'package:mobile_scanner/mobile_scanner.dart';

/// Wraps the on-device barcode/QR scanner used both to (a) register a
/// bottle's code when a medicine is created, and (b) verify physical
/// possession of the bottle before an alarm can be dismissed.
class BarcodeService {
  /// Returns the first decoded payload from a live camera scan, or null
  /// if nothing readable was in frame.
  static String? extractFirstCode(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  /// Physical-proof check: the scanned code must exactly match the code
  /// stored locally against this medicine. No server round-trip.
  static bool verify({required String scanned, required String? expected}) {
    if (expected == null || expected.isEmpty) return false;
    return scanned.trim() == expected.trim();
  }
}
