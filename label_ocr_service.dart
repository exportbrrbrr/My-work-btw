import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:uuid/uuid.dart';
import '../models/medicine.dart';

/// Parses a photographed medicine label into a [Medicine] draft so the
/// user can skip the manual form entirely ("อ่านฉลากยา แล้วทำเป็นตาราง").
/// Recognition runs fully on-device via ML Kit's text recognizer;
/// nothing is uploaded anywhere.
class LabelOcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<Medicine> parseLabel(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(input);
    final rawText = result.text;
    final slots = _guessTimeSlots(rawText);

    return Medicine(
      id: const Uuid().v4(),
      name: _guessName(rawText),
      type: _guessType(rawText),
      quantityPerDose: _guessQuantity(rawText),
      timeSlots: slots,
      startDate: DateTime.now(),
      endDate: null,
      alarmTimes: _defaultAlarmsFor(slots),
    );
  }

  // --- Lightweight heuristics; swap in a proper label-grammar parser
  // or a bundled NER model as label formats grow more varied. ---

  String _guessName(String text) => text
      .split('\n')
      .firstWhere((l) => l.trim().isNotEmpty, orElse: () => 'ยาที่สแกน');

  String _guessType(String text) {
    if (text.contains('แคปซูล') || text.toLowerCase().contains('capsule')) {
      return 'แคปซูล';
    }
    if (text.contains('น้ำ') || text.toLowerCase().contains('syrup')) {
      return 'น้ำ';
    }
    return 'เม็ด';
  }

  int _guessQuantity(String text) {
    final match = RegExp(r'(\d+)\s*(เม็ด|capsule|tablet)').firstMatch(text);
    return match != null ? int.tryParse(match.group(1) ?? '1') ?? 1 : 1;
  }

  List<String> _guessTimeSlots(String text) {
    final slots = <String>[];
    if (text.contains('เช้า')) slots.add('หลังอาหารเช้า');
    if (text.contains('กลางวัน') || text.contains('เที่ยง')) slots.add('หลังอาหารกลางวัน');
    if (text.contains('เย็น')) slots.add('หลังอาหารเย็น');
    return slots.isEmpty ? ['หลังอาหารเช้า'] : slots;
  }

  List<String> _defaultAlarmsFor(List<String> slots) {
    const map = {
      'หลังอาหารเช้า': '08:00',
      'หลังอาหารกลางวัน': '12:00',
      'หลังอาหารเย็น': '18:00',
    };
    return slots.map((s) => map[s] ?? '08:00').toList();
  }

  void dispose() => _recognizer.close();
}
