import 'dart:io';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Extracts the pill from a snapped photo entirely on-device.
///
/// Strategy: ML Kit's on-device Object Detector (`DetectionMode.single`,
/// no cloud fallback) returns a bounding box for the most prominent
/// object in frame. We crop to that box with the pure-Dart `image`
/// package. This satisfies "extract the pill object" with a light
/// dependency footprint and zero network calls.
///
/// To upgrade to pixel-perfect background removal later, swap the body
/// of [extractPill] for a call into a bundled TFLite segmentation model
/// via a custom `LocalModel` passed to `ObjectDetector` — the public
/// method signature does not need to change.
class VisionService {
  final ObjectDetector _detector = ObjectDetector(
    options: ObjectDetectorOptions(
      mode: DetectionMode.single,
      classifyObjects: false,
      multipleObjects: false,
    ),
  );

  /// Returns the local file path of the cropped pill image, or the
  /// original photo path if no distinct object could be isolated.
  Future<String> extractPill(String sourceImagePath) async {
    final inputImage = InputImage.fromFilePath(sourceImagePath);
    final objects = await _detector.processImage(inputImage);

    final bytes = await File(sourceImagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null || objects.isEmpty) {
      return sourceImagePath; // fall back to the uncropped photo
    }

    final box = objects.first.boundingBox;
    final cropped = img.copyCrop(
      decoded,
      x: box.left.clamp(0, decoded.width - 1).toInt(),
      y: box.top.clamp(0, decoded.height - 1).toInt(),
      width: box.width.clamp(1, decoded.width).toInt(),
      height: box.height.clamp(1, decoded.height).toInt(),
    );

    final dir = await getApplicationDocumentsDirectory();
    final outPath = '${dir.path}/pill_${const Uuid().v4()}.png';
    await File(outPath).writeAsBytes(img.encodePng(cropped));
    return outPath;
  }

  void dispose() => _detector.close();
}
